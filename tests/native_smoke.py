#!/usr/bin/env python3
"""Test built plugins in a temporary nested Hyprland, never in the host compositor."""
import json,os,pathlib,subprocess,tempfile,time
ROOT=pathlib.Path(__file__).resolve().parents[1]
instances=json.loads(subprocess.check_output(['hyprctl','instances','-j']))
if not instances:raise SystemExit('Requires an existing Wayland Hyprland session')
parent=next((i for i in instances if i['instance']==os.environ.get('HYPRLAND_INSTANCE_SIGNATURE')),instances[0])
parent_socket=str(pathlib.Path(os.environ['XDG_RUNTIME_DIR'])/parent['wl_socket'])
with tempfile.TemporaryDirectory(prefix='h-') as td:
 runtime=pathlib.Path(td);runtime.chmod(0o700)
 config=runtime/'hyprland.lua'
 config.write_text('hl.monitor({output="",mode="1280x720@60",position="0x0",scale=1})\nhl.config({misc={disable_hyprland_logo=true,disable_splash_rendering=true},animations={enabled=false}})\n')
 env=os.environ.copy();env.update(XDG_RUNTIME_DIR=td,WAYLAND_DISPLAY=parent_socket,AQ_BACKEND='wayland');env.pop('HYPRLAND_INSTANCE_SIGNATURE',None)
 with (runtime/'compositor.log').open('w') as log:
  process=subprocess.Popen(['Hyprland','--config',str(config)],env=env,stdout=log,stderr=subprocess.STDOUT)
  try:
   sockets=[]
   for _ in range(200):
    sockets=list(runtime.glob('hypr/*/.socket.sock'))
    if sockets:break
    if process.poll() is not None:raise RuntimeError('Nested compositor exited; '+(runtime/'compositor.log').read_text()[-2000:])
    time.sleep(.1)
   assert sockets,'Nested socket missing: '+(runtime/'compositor.log').read_text()[-3000:]
   env['HYPRLAND_INSTANCE_SIGNATURE']=sockets[0].parent.name
   def ctl(*args):
    p=subprocess.run(['hyprctl',*args],env=env,capture_output=True,text=True,check=True)
    assert p.stdout.strip()=='ok',p.stdout+p.stderr
   for name in ['hyprbars','native-minimize','omarchy-windows-snap']:
    path=ROOT/'build'/(name+'.so');assert path.exists(),str(path)
    for _ in range(3):
     ctl('plugin','load',str(path));time.sleep(.1)
     ctl('plugin','unload',str(path));time.sleep(.1)
    print(name+': three isolated load/unload cycles PASS')
  finally:
   log.flush()
   (ROOT/'build/native-smoke.log').write_text((runtime/'compositor.log').read_text())
   process.terminate()
   try:process.wait(timeout=5)
   except subprocess.TimeoutExpired:process.kill();process.wait()
