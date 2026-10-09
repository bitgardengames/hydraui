"""Exercise settings entry points with widgets that record every visible change."""
from pathlib import Path
import shutil
import subprocess

import pytest

ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.parametrize("script", ["unitframe_updates.lua", "unitframe_auras.lua", "unitframe_runtime.lua", "unitframe_smooth.lua", "unitframe_prediction.lua"])
def test_unitframe_widget_behavior(script):
    lua = shutil.which("lua5.1") or shutil.which("lua") or shutil.which("texlua")
    if not lua:
        pytest.skip("A Lua interpreter is needed for the widget behavior checks")
    result = subprocess.run(
        [lua, f"tests/{script}"], cwd=ROOT,
        capture_output=True, text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
