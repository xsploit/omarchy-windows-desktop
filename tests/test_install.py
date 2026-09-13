"""Exercise real staged install and rollback, without touching the live desktop."""
import pathlib,subprocess,tempfile,unittest,json
ROOT=pathlib.Path(__file__).resolve().parents[1]
class InstallTest(unittest.TestCase):
 def test_install_and_rollback(self):
  with tempfile.TemporaryDirectory(prefix='desktop-stage-') as td:
   home=pathlib.Path(td); cfg=home/'.config/hypr';cfg.mkdir(parents=True)
   (cfg/'monitors.lua').write_text('-- my existing monitor\n')
   (cfg/'input.lua').write_text('-- my old input\n')
   subprocess.run(['python3',str(ROOT/'install.py'),'--apply','--home',td],check=True)
   self.assertEqual((cfg/'monitors.lua').read_text(),'-- my existing monitor\n')
   self.assertIn('kb_options = ""',(cfg/'input.lua').read_text())
   self.assertNotIn('@HOME@',(cfg/'bindings.lua').read_text())
   self.assertNotIn('hl.plugin.load(', (cfg/'titlebars.lua').read_text())
   c=json.loads((home/'.config/omarchy/shell.json').read_text())
   self.assertEqual(c['bar']['layout']['center'][0]['id'],'undercover.win11-taskbar')
   backup=next((home/'.local/state/omarchy-windows-desktop/backups').iterdir())
   subprocess.run(['python3',str(ROOT/'restore.py'),str(backup)],check=True)
   self.assertEqual((cfg/'input.lua').read_text(),'-- my old input\n')
   self.assertFalse((home/'.local/bin/desktop-windows').exists())
if __name__=='__main__':unittest.main()
