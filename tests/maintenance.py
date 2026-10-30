#!/usr/bin/env python3
"""在临时目录验证配置链接迁移，不接触真实 /etc。"""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

script = Path(sys.argv.pop(1)).read_text()

class LinkTests(unittest.TestCase):
    def execute(self, root):
        adapted = script.replace('config_link=/etc/nixos', f'config_link={root}/nixos')
        adapted = adapted.replace('config_target=/home/muchstarlight/nixos-config', f'config_target={root}/work')
        adapted = adapted.replace('config_backup=/etc/nixos.before-symlink-20261030', f'config_backup={root}/backup')
        return subprocess.run(['bash', '-euc', adapted], capture_output=True, text=True)

    def test_backup_and_idempotence(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'nixos').mkdir()
            (root / 'nixos/original').write_text('原配置')
            self.assertEqual(self.execute(root).returncode, 0)
            self.assertEqual((root / 'nixos').readlink(), root / 'work')
            self.assertEqual((root / 'backup/original').read_text(), '原配置')
            self.assertEqual(self.execute(root).returncode, 0)

    def test_existing_backup_not_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'nixos').mkdir()
            (root / 'backup').mkdir()
            self.assertNotEqual(self.execute(root).returncode, 0)
            self.assertFalse((root / 'nixos').is_symlink())

    def test_foreign_link_not_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'nixos').symlink_to(root / 'unexpected')
            self.assertNotEqual(self.execute(root).returncode, 0)
            self.assertEqual((root / 'nixos').readlink(), root / 'unexpected')

if __name__ == '__main__':
    unittest.main(verbosity=2)
