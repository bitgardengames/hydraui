"""Exercise aura access restrictions before any protected query is attempted."""
from pathlib import Path
import shutil
import subprocess

import pytest


ROOT = Path(__file__).resolve().parents[1]


def test_mainline_aura_restrictions_and_cleanup():
    lua = shutil.which("lua5.1") or shutil.which("lua") or shutil.which("texlua")
    if not lua:
        pytest.skip("A Lua interpreter is needed for the aura access checks")
    result = subprocess.run(
        [lua, "tests/aura_enumeration_runtime.lua"], cwd=ROOT,
        capture_output=True, text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
