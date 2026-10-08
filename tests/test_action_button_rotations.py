"""Exercise visual suppression without changing Blizzard's action methods."""
from pathlib import Path
import shutil
import subprocess
import unittest


class ActionButtonRotationsRuntime(unittest.TestCase):
    def test_rotation_lifecycle(self):
        lua = shutil.which("texlua")
        if not lua:
            self.skipTest("texlua is required")
        result = subprocess.run(
            [lua, "tests/action_button_rotations_runtime.lua"],
            cwd=Path(__file__).resolve().parents[1], capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
