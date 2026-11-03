import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
import unittest


CONFIG = json.loads(Path(sys.argv.pop(1)).read_text())
# 仅转换 GRUB 赋值语法，其余控制流由 Bash 执行；磁盘环境块使用真实 grub-editenv。
BOOT_SCRIPT = re.sub(r"(?m)^(\s*)set (?=[a-zA-Z_]\w*=)", r"\1", CONFIG["extraConfig"])


class GrubSelectionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = self.root / "(esp)/EFI/NixOS/selection.env"
        self.env.parent.mkdir(parents=True)
        self.edit("create")

    def edit(self, *args):
        return subprocess.check_output(
            ["grub-editenv", str(self.env), *args], text=True
        ).strip()

    def boot(self, chosen="", *, boot_once=False, esp=True, arch_return=False):
        script = r'''
set -e
insmod() { :; }
search() { selection_esp="$TEST_ESP"; }
load_env() {
    test "$#" = 2
    test "$1" = "--file=$selection_env"
    test "$2" = saved_entry
    local record
    record=$(grub-editenv "$selection_env" list)
    if [ -n "$record" ]; then
        saved_entry="${record#saved_entry=}"
    fi
}
save_env() {
    test "$#" = 2
    test "$1" = "--file=$selection_env"
    test "$2" = saved_entry
    # GRUB 的 save_env 只覆写现有环境块，grub-editenv set 会创建缺失文件。
    test -s "$selection_env"
    grub-editenv "$selection_env" set "saved_entry=$saved_entry"
}
boot_once="$TEST_BOOT_ONCE"
default=one-shot-entry
saved_entry=stale-btrfs-entry
'''
        script += BOOT_SCRIPT
        if arch_return:
            arch = CONFIG["extraEntries"].split("menuentry 'Arch Linux", 1)[1]
            restore = arch.split("configfile ", 1)[1].split("\n", 1)[1].rsplit("}", 1)[0]
            script += "\nfunction savedefault { :; }\n"
            script += re.sub(r"(?m)^(\s*)set (?=[a-zA-Z_]\w*=)", r"\1", restore)
        script += '\nchosen="$TEST_CHOSEN"\nsavedefault\nprintf "%s\\n" "$default"\n'
        result = subprocess.run(
            ["bash", "-c", script],
            cwd=self.root,
            env={
                **os.environ,
                "TEST_ESP": "esp" if esp else "",
                "TEST_BOOT_ONCE": "true" if boot_once else "",
                "TEST_CHOSEN": chosen,
            },
            text=True,
            capture_output=True,
            check=True,
        )
        return result.stdout.strip()

    def test_defaults(self):
        for saved, expected in [
            (None, "nixos"),
            ("nixos", "nixos"),
            ("windows", "windows"),
            ("obsolete-generation", "nixos"),
        ]:
            with self.subTest(saved=saved):
                self.edit("create")
                if saved is not None:
                    self.edit("set", f"saved_entry={saved}")
                self.assertEqual(self.boot(), expected)

    def test_only_primary_entries_update_selection(self):
        for previous in ["nixos", "windows"]:
            for chosen in [
                "nixos",
                "windows",
                "Arch Linux（迁移回退）",
                "NixOS - Configuration 42",
                "NixOS - specialisation",
                "UEFI Firmware Settings",
                "",
            ]:
                with self.subTest(previous=previous, chosen=chosen):
                    self.edit("set", f"saved_entry={previous}")
                    self.assertEqual(self.boot(chosen), previous)
                    expected = chosen if chosen in ["nixos", "windows"] else previous
                    self.assertEqual(self.edit("list"), f"saved_entry={expected}")
                    self.assertEqual(self.boot(), expected)

    def test_arch_return_restores_selective_saving(self):
        self.edit("set", "saved_entry=nixos")
        self.assertEqual(self.boot("windows", arch_return=True), "nixos")
        self.assertEqual(self.edit("list"), "saved_entry=windows")
        self.boot("NixOS - Configuration 42", arch_return=True)
        self.assertEqual(self.edit("list"), "saved_entry=windows")

    def test_one_shot_boot_does_not_change_selection(self):
        self.edit("set", "saved_entry=windows")
        for chosen in ["nixos", "windows"]:
            self.assertEqual(self.boot(chosen, boot_once=True), "one-shot-entry")
            self.assertEqual(self.edit("list"), "saved_entry=windows")

    def test_missing_esp_falls_back_without_writing(self):
        self.edit("set", "saved_entry=windows")
        self.assertEqual(self.boot("nixos", esp=False), "nixos")
        self.assertEqual(self.edit("list"), "saved_entry=windows")

    def test_missing_file_falls_back_without_writing(self):
        self.env.unlink()
        for chosen in ["", "nixos", "windows"]:
            with self.subTest(chosen=chosen):
                self.assertEqual(self.boot(chosen), "nixos")
                self.assertFalse(self.env.exists())

    def test_empty_file_falls_back_without_writing(self):
        self.env.write_bytes(b"")
        for chosen in ["", "nixos", "windows"]:
            with self.subTest(chosen=chosen):
                self.assertEqual(self.boot(chosen), "nixos")
                self.assertEqual(self.env.read_bytes(), b"")

    def install(self, *, correct_esp=True, check=True):
        script = CONFIG["extraInstallCommands"].splitlines()
        script[0] = f"selection_env={shlex.quote(str(self.env))}"
        script = re.sub(r"/nix/store/[^/]+/bin/findmnt", "findmnt", "\n".join(script))
        script = 'findmnt() { printf "%s\\n" "$TEST_UUID"; }\n' + script
        uuid = re.search(r"--set=selection_esp (\S+)", CONFIG["extraConfig"])[1]
        return subprocess.run(
            ["bash", "-e", "-c", script],
            env={**os.environ, "TEST_UUID": uuid if correct_esp else ""},
            text=True,
            capture_output=True,
            check=check,
        )

    def test_installer_creates_once_and_preserves_selection(self):
        self.env.unlink()
        self.install()
        self.assertEqual(self.edit("list"), "")
        self.edit("set", "saved_entry=windows")
        self.install()
        self.assertEqual(self.edit("list"), "saved_entry=windows")

    def test_installer_rejects_missing_esp(self):
        self.env.unlink()
        result = self.install(correct_esp=False, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("expected ESP is not mounted", result.stderr)
        self.assertFalse(self.env.exists())

    def test_installer_rejects_corrupt_environment(self):
        for content in [b"", b"corrupt environment"]:
            with self.subTest(content=content):
                self.env.write_bytes(content)
                result = self.install(check=False)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.env.read_bytes(), content)

    def test_windows_chainloader_uses_windows_root(self):
        windows = CONFIG["extraEntries"].split("menuentry 'Arch Linux", 1)[0]
        body = windows.split("{", 1)[1].rsplit("}", 1)[0]
        body = re.sub(r"(?m)^(\s*)set (?=[a-zA-Z_]\w*=)", r"\1", body)
        script = r'''
set -e
root=linux
savedefault() { :; }
insmod() { :; }
search() {
    test "$*" = "--no-floppy --fs-uuid --set=root 4BA0-87E9"
    root=windows_esp
}
chainloader() {
    test "$root" = windows_esp
    test "$#" = 1
    test "$1" = /EFI/Microsoft/Boot/bootmgfw.efi
    printf 'windows-chainloaded\n'
}
'''
        result = subprocess.run(
            ["bash", "-c", script + body],
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(result.stdout.strip(), "windows-chainloaded")

    def test_menu_entry_wiring(self):
        self.assertEqual(CONFIG["default"], "saved")
        self.assertIn("--id nixos", CONFIG["entryOptions"])
        windows, arch = CONFIG["extraEntries"].split("menuentry 'Arch Linux", 1)
        self.assertIn("--id windows", windows)
        self.assertIn("savedefault", windows)
        self.assertIsNone(re.search(r"(?m)^\s*savedefault\s*$", arch))


if __name__ == "__main__":
    unittest.main()
