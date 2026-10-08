"""Exercise retail bag ownership, square sizing, and combat deferral."""
from pathlib import Path
import shutil
import subprocess
import unittest


class BagSlotsRuntime(unittest.TestCase):
    def test_bag_slots_runtime(self):
        lua = shutil.which("lua5.1") or shutil.which("lua") or shutil.which("texlua")
        if not lua:
            self.skipTest("A Lua interpreter is required")
        result = subprocess.run(
            [lua, "tests/bag_slots_runtime.lua"],
            cwd=Path(__file__).resolve().parents[1], capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
