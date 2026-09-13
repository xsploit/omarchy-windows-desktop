#!/usr/bin/env python3
"""Restore only files listed in one install backup; does not restart your session."""
import json,os,pathlib,shutil,sys
backup=pathlib.Path(sys.argv[1]).resolve()
# Backup resides at HOME/.local/state/omarchy-windows-desktop/backups/TIMESTAMP.
home=backup.parents[4]
for entry in reversed(json.loads((backup/'manifest.json').read_text())):
    rel=pathlib.PurePosixPath(entry['path'])
    if rel.is_absolute() or '..' in rel.parts:raise SystemExit('Unsafe backup path')
    dest=home/rel
    if any(p.is_symlink() for p in dest.parents if p != home):raise SystemExit('Symlinked parent: '+str(dest))
    if dest.is_symlink():dest.unlink()
    elif dest.exists() and not entry['existed']:dest.unlink()
    if 'symlink' in entry:dest.symlink_to(entry['symlink'])
    elif entry['existed']:
        temp=dest.with_name(dest.name+'.desktop-restore-tmp')
        shutil.copy2(backup/'files'/rel,temp);temp.replace(dest)
print('Files restored. Run systemctl --user daemon-reload; then log out/in or reload Hyprland and restart the shell.')
