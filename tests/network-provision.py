#!/usr/bin/env python3
"""私密文件部署前检查的回归测试，不需要 root，也不读真实秘密。"""
import importlib.util
from pathlib import Path
import os
import sys
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('provision', Path(sys.argv.pop(1)))
provision = importlib.util.module_from_spec(spec)
spec.loader.exec_module(provision)

class SafetyTests(unittest.TestCase):
    def test_public_parents_traversable_under_private_umask(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            old = os.umask(0o077)
            try:
                directories = [root / relative for relative in ('etc', 'var', 'var/lib', 'etc/NetworkManager')]
                provision.create_public_directories(directories)
            finally:
                os.umask(old)
            for path in directories:
                self.assertEqual(path.stat().st_mode & 0o777, 0o755)

    def test_normal_empty_target(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            provision.validate_targets(root, [root / 'var/lib/nixos-private/config'],
                                       [root / 'etc/home-network-switch'],
                                       root / 'etc/home-network-switch/enabled')
            self.assertEqual(list(root.iterdir()), [])

    def test_marker_parent_link_rejected_before_writes(self):
        with tempfile.TemporaryDirectory() as directory, tempfile.TemporaryDirectory() as outside:
            root = Path(directory)
            (root / 'etc').mkdir()
            (root / 'etc/home-network-switch').symlink_to(outside, target_is_directory=True)
            with self.assertRaises(ValueError):
                provision.validate_targets(root, [], [root / 'etc/home-network-switch'],
                                           root / 'etc/home-network-switch/enabled')
            self.assertEqual(list(Path(outside).iterdir()), [])

    def test_empty_nm_directory_link_rejected(self):
        with tempfile.TemporaryDirectory() as directory, tempfile.TemporaryDirectory() as outside:
            root = Path(directory)
            (root / 'etc/NetworkManager').mkdir(parents=True)
            (root / 'etc/NetworkManager/system-connections').symlink_to(outside, target_is_directory=True)
            with self.assertRaises(ValueError):
                provision.validate_targets(root, [], [root / 'etc/NetworkManager/system-connections'],
                                           root / 'etc/home-network-switch/enabled')
            self.assertEqual(list(Path(outside).iterdir()), [])

    def test_secret_parent_link_rejected(self):
        with tempfile.TemporaryDirectory() as directory, tempfile.TemporaryDirectory() as outside:
            root = Path(directory)
            (root / 'var').symlink_to(outside, target_is_directory=True)
            with self.assertRaises(ValueError):
                provision.validate_targets(root, [root / 'var/lib/nixos-private/config'], [], root / 'marker')

    def test_existing_file_not_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / 'config'
            target.write_text('测试占位内容')
            with self.assertRaises(ValueError):
                provision.validate_targets(root, [target], [], root / 'marker')
            self.assertEqual(target.read_text(), '测试占位内容')

if __name__ == '__main__':
    unittest.main(verbosity=2)
