"""Exercise settings entry points with widgets that record every visible change."""
from pathlib import Path
import shutil
import subprocess

import pytest

ROOT = Path(__file__).resolve().parents[1]


def test_public_callbacks_and_group_updates_preserve_widget_behavior():
    lua = shutil.which("lua5.1") or shutil.which("lua") or shutil.which("texlua")
    if not lua:
        pytest.skip("A Lua interpreter is needed for the widget behavior checks")
    result = subprocess.run(
        [lua, "tests/unitframe_updates.lua"], cwd=ROOT,
        capture_output=True, text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
