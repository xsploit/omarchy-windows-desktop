#!/usr/bin/env python3
"""Install this explicit file allowlist; default to a read-only plan."""
import argparse, datetime, hashlib, json, os, pathlib, re, shutil, subprocess, sys
ROOT = pathlib.Path(__file__).resolve().parent

def run(*args, **kw):
    return subprocess.run(args, check=True, **kw)

def build():
    version = subprocess.check_output(['pkg-config', '--modversion', 'hyprland'], text=True).strip()
    if version != '0.56.2':
        raise SystemExit('Native sources are verified only against Hyprland 0.56.2. Rebuild/review for your version first.')
    out = ROOT / 'build'; out.mkdir(exist_ok=True)
    flags = subprocess.check_output(['pkg-config', '--cflags', 'hyprland', 'pixman-1', 'libdrm', 'libinput', 'libudev', 'wayland-server', 'xkbcommon'], text=True).split()
    jobs = {
      'hyprbars': list((ROOT/'native/hyprbars').glob('*.cpp')),
      'native-minimize': [ROOT/'home/.local/share/desktop-integration/native-minimize/main.cpp'],
      'omarchy-windows-snap': [ROOT/'native/aero-snap/main.cpp'],
    }
    result = {}
    for name, sources in jobs.items():
        temp = out / (name + '.so')
        run('g++', '-O2', '-shared', '-fPIC', '-fno-gnu-unique', '-std=c++23', '-Wno-narrowing', *flags, *map(str, sources), '-o', str(temp))
        digest = hashlib.sha256(temp.read_bytes()).hexdigest()[:16]
        result[name] = (temp, f'{name}-0.56.2-{digest}.so')
    qt = subprocess.check_output(['pkg-config','--cflags','--libs','Qt6Widgets'],text=True).split()
    run('g++','-O2','-fPIC','-std=c++17',str(ROOT/'home/.local/share/desktop-integration/hdr-brightness/panel.cpp'),'-o',str(out/'hdr-panel'),*qt)
    return result

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--apply',action='store_true',help='Write files with a dated rollback backup')
    p.add_argument('--home',type=pathlib.Path,default=pathlib.Path.home(),help='Target home (also useful for staging tests)')
    p.add_argument('--build-native',action='store_true',help='Build matching Hyprland plugins before installing')
    p.add_argument('--with-lg-hdr',action='store_true',help='Opt into HDMI-A-1 3840x2160@60 scale 1.75 HDR; LG profile only')
    p.add_argument('--activate',action='store_true',help='Reload the current desktop after installing; requires --apply')
    a=p.parse_args();home=a.home.resolve()
    if not re.fullmatch(r'/[A-Za-z0-9_./-]+',str(home)):
        raise SystemExit('Home must use letters, digits, /, _, dot or dash for these command templates.')
    if a.activate and (not a.apply or home != pathlib.Path.home()):raise SystemExit('--activate requires --apply to your real home')
    files={str(f.relative_to(ROOT/'home')):f for f in (ROOT/'home').rglob('*') if f.is_file()}
    if a.with_lg_hdr:
        for name in ['monitors.lua','hdr-brightness.lua']:
            files['.config/hypr/'+name]=ROOT/'profiles/lg-4k-hdr'/name
    # Preserve existing display setup unless the user specifically selects the TV profile.
    elif (home/'.config/hypr/monitors.lua').exists():files.pop('.config/hypr/monitors.lua')
    print(f'{"INSTALL" if a.apply else "PLAN"}: {len(files)} files into {home}')
    print('Native plugins:', 'build for Hyprland 0.56.2' if a.build_native else 'disabled in installed config until rebuilt')
    if not a.apply:
        print('No files changed. Use --apply --build-native after reading README.md.');return
    native=build() if a.build_native else {}
    backup=home/'.local/state/omarchy-windows-desktop/backups'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup.mkdir(parents=True);manifest=[]
    def write(rel,data,mode):
        dest=home/rel
        # Never follow a target symlink and write through it to unrelated files.
        if any(parent.is_symlink() for parent in dest.parents if parent != home):raise RuntimeError(f'Symlinked parent: {dest}')
        item={'path':rel,'existed':dest.exists() or dest.is_symlink()}
        if dest.is_symlink():item['symlink']=os.readlink(dest)
        elif dest.exists():
            saved=backup/'files'/rel;saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dest,saved)
        manifest.append(item);(backup/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
        dest.parent.mkdir(parents=True,exist_ok=True)
        # Content-addressed plugins must NEVER overwrite any loaded binary.
        if dest.exists() and dest.suffix=='.so':
            if dest.read_bytes()!=data:raise RuntimeError(f'Immutable plugin collision: {dest}')
            return
        if dest.is_symlink():dest.unlink()
        tmp=dest.with_name(dest.name+'.desktop-install-tmp');tmp.write_bytes(data);tmp.chmod(mode);tmp.replace(dest)
    # Native files must exist before auto-reloading config references them.
    for _,(source,filename) in native.items():write('.local/lib/hyprland/'+filename,source.read_bytes(),0o755)
    if a.with_lg_hdr:(home/'.config/hypr/shaders').mkdir(parents=True,exist_ok=True)
    for rel,src in sorted(files.items()):
        data=src.read_bytes()
        try:
            text=data.decode().replace('@HOME@',str(home))
            if rel.endswith('titlebars.lua') or rel.endswith('windows-snap-trial.lua'):
                if native:
                    for name,(_,filename) in native.items():
                        text=re.sub(re.escape(name)+r'-0\.56\.2[^"/]*\.so',filename,text)
                else:text=re.sub(r'^.*hl\.plugin\.load\(.*$', '-- Native plugin disabled: install with --build-native.',text,flags=re.M)
            # HDR binary comes from the source build, not an opaque downloaded executable.
            if rel.endswith('hdr-brightness.lua') and a.with_lg_hdr:
                text='-- Shader generated by hdr-brightness-control set LEVEL after login.\n'
            data=text.encode()
        except UnicodeDecodeError:pass
        write(rel,data,src.stat().st_mode & 0o777)
    if native:write('.local/share/desktop-integration/hdr-brightness/panel',(ROOT/'build/hdr-panel').read_bytes(),0o755)
    print('Backup:',backup)
    print('Restore with: python3 restore.py '+str(backup))
    if a.activate:
        for tool in ['omarchy-undercover-scan-apps','update-desktop-database']:
            exe=home/'.local/bin'/tool if tool.startswith('omarchy-') else shutil.which(tool)
            if exe and pathlib.Path(exe).exists():
                run(str(exe), *([str(home/'.local/share/applications')] if tool=='update-desktop-database' else []))
        run('systemctl','--user','daemon-reload')
        run('systemctl','--user','enable','desktop-windows.service')
        run('systemctl','--user','restart','desktop-windows.service')
        run('hyprctl','reload')
        errors=subprocess.check_output(['hyprctl','configerrors'],text=True).strip()
        if errors:raise SystemExit('Hyprland reported errors; restore the backup:\n'+errors)
        run('omarchy','restart','shell')
    else:print('Not activated. Log in again after enabling desktop-windows.service (see README).')
if __name__=='__main__':main()
