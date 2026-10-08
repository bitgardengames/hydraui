"""Exercise native settings paths without touching protected action buttons."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ActionBarVisibilityTests(unittest.TestCase):
    def test_empty_button_defaults(self):
        lua = shutil.which("lua5.1") or shutil.which("lua") or shutil.which("texlua")
        if not lua:
            self.skipTest("A Lua interpreter is needed")
        result = subprocess.run(
            [lua, "tests/action_bar_visibility.lua"], cwd=ROOT,
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
