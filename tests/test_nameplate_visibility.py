"""Verify friendly nameplate hotkeys against the native Lua driver."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class NameplateVisibilityTests(unittest.TestCase):
    def test_nameplate_visibility_lifecycle(self):
        lua = shutil.which("lua5.1") or shutil.which("lua") or shutil.which("texlua")
        if not lua:
            self.skipTest("A Lua interpreter is needed for nameplate visibility checks")
        result = subprocess.run(
            [lua, "tests/nameplate_visibility.lua"], cwd=ROOT,
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
