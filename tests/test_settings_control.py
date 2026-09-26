"""Unit tests for home/.local/bin/desktop-settings-control; no real commands run."""
import importlib.machinery
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

HELPER = Path(__file__).resolve().parent.parent / 'home/.local/bin/desktop-settings-control'
loader = importlib.machinery.SourceFileLoader('settings_control', str(HELPER))
spec = importlib.util.spec_from_loader(loader.name, loader)
m = importlib.util.module_from_spec(spec)
loader.exec_module(m)

FOOT = ('[main]\nfont=JetBrainsMono Nerd Font:size=11,Fallback:size=9\nworkers=0\n'
        '[key-bindings]\nclipboard-paste=Control+v\n')


class SettingsControlTest(unittest.TestCase):
    def test_only_primary_font_size_changes(self):
        changed = m.replace_terminal_size(FOOT, 12.5)
        self.assertIn('font=JetBrainsMono Nerd Font:size=12.5,Fallback:size=9', changed)
        self.assertEqual(changed.replace('size=12.5', 'size=11', 1), FOOT)

    def test_unsupported_font_lines_are_rejected(self):
        for text in ('[main]\nfont=mono\n', '[cursor]\nfont=mono:size=11\n'):
            with self.assertRaises(ValueError):
                m.replace_terminal_size(text, 12)

    def test_numbers_are_validated(self):
        for value in ('nan', 'inf', '-1', '201', '12; touch /tmp/x'):
            with self.assertRaises(ValueError):
                m.number(value, 0, 100)

    def test_unknown_actions_are_rejected(self):
        for action, args in [('reset', []), ('open', ['not-a-destination']), ('status', ['extra'])]:
            with self.assertRaises(ValueError):
                m.perform(action, args)

    def test_status_reads_without_launching(self):
        fake = lambda argv, timeout=15: '1.1818' if argv[0] == 'gsettings' else '[]'
        with patch.object(m, 'run', side_effect=fake), patch.object(m.subprocess, 'Popen') as popen:
            self.assertEqual(m.status()['textScale'], 1.1818)
            popen.assert_not_called()

    def test_text_scale_set_and_exact_restore(self):
        live = ['1.1818']
        def fake(argv, timeout=15):
            self.assertEqual(argv[0], 'gsettings')
            if argv[1] == 'set':
                live[0] = argv[-1]
                return ''
            return live[0]
        with tempfile.TemporaryDirectory() as d, patch.object(m, 'STATE', Path(d)), \
                patch.object(m, 'run', side_effect=fake), patch.object(m, 'status', return_value={'ok': True}):
            m.perform('text-size', ['1.2'])
            self.assertEqual(live[0], '1.2')
            m.perform('text-size', ['1.1818'])
            self.assertEqual(live[0], '1.1818')

    def test_foot_config_validated_before_replacement(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            foot = root / 'foot.ini'
            foot.write_text(FOOT)
            with patch.object(m, 'FOOT', foot), patch.object(m, 'STATE', root), \
                    patch.object(m, 'run', side_effect=RuntimeError('invalid config')):
                with self.assertRaises(RuntimeError):
                    m.save_terminal(12)
                self.assertEqual(foot.read_text(), FOOT)
            with patch.object(m, 'FOOT', foot), patch.object(m, 'STATE', root), \
                    patch.object(m, 'run', return_value='') as run:
                m.save_terminal(12)
                self.assertEqual(m.terminal_size(foot.read_text()), 12)
                self.assertTrue(list(root.glob('foot.ini.before-*')))
                self.assertEqual(run.call_args[0][0][:2], ['foot', '--check-config'])

    def test_hdr_only_on_explicit_whole_number(self):
        with tempfile.TemporaryDirectory() as d, patch.object(m, 'STATE', Path(d)), \
                patch.object(m, 'run', return_value='') as run, \
                patch.object(m, 'status', return_value={'ok': True}), \
                patch.object(m.os, 'access', return_value=True):
            m.perform('hdr-level', ['81'])
            self.assertEqual(run.call_args[0][0], [str(m.HOME / '.local/bin/hdr-brightness-control'), 'set', '81'])
            with self.assertRaises(ValueError):
                m.perform('hdr-level', ['81.3'])

    def test_missing_destination_is_an_error(self):
        with patch.object(m.shutil, 'which', return_value=None):
            with self.assertRaises(RuntimeError):
                m.perform('open', ['disks'])


if __name__ == '__main__':
    unittest.main(verbosity=2)
