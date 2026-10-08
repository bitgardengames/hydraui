"""Execute public setters and callbacks against recording widgets."""
from pathlib import Path
import shutil
import subprocess

import pytest

ROOT = Path(__file__).parents[1]
LUA = shutil.which("texlua")


def test_public_setters_and_callbacks_update_the_same_widgets(tmp_path):
    if not LUA:
        pytest.skip("texlua is required for Lua execution")
    source = ROOT / "HydraUI/Elements/UnitFrames/Elements/Updates.lua"
    script = tmp_path / "updates.lua"
    script.write_text(r'''
local UF, frames, calls = {}, {}, {}
local HydraUI = {UnitFrames = frames, GetModule = function() return UF end}
local Assets = {GetTexture = function(_, value) return "texture:" .. tostring(value) end}
local ns = {get = function() return HydraUI, nil, Assets, {} end}
assert(loadfile(arg[1]))("HydraUI", ns)
local function record(name, ...)
    local args = {...}
    for i = 1, #args do args[i] = tostring(args[i]) end
    calls[#calls + 1] = name .. ":" .. table.concat(args, ",")
end
local function widget(name)
    local w = {bg = {SetTexture = function(_, value) record(name .. ".bg", value) end}}
    for _, method in ipairs({"ForceUpdate", "SetReverseFill", "ClearAllPoints", "SetPoint", "SetStatusBarTexture"}) do
        w[method] = function(_, ...) record(name .. "." .. method, ...) end
    end
    w.GetStatusBarTexture = function() return "health-texture" end
    return w
end
UF.SetHealthAttributes = function(_, _, value) record("health-color", value) end
UF.SetPowerAttributes = function(_, _, value) record("power-color", value) end
local cases = {
    {"ApplyHealthAttributes", "HealthColor"}, {"ApplyPowerAttributes", "PowerColor"},
    {"SetHealthReverseFill", "HealthReverse"}, {"SetPowerReverseFill", "PowerReverse"},
    {"SetHealthTexture", "HealthTexture"}, {"SetPowerTexture", "PowerTexture"},
}
for _, predictions in ipairs({false, true}) do
    local frame = {Health = widget("health"), Power = widget("power")}
    if predictions then frame.HealBar, frame.AbsorbsBar = widget("heal"), widget("absorb") end
    frames.player = frame
    for _, case in ipairs(cases) do
        for _, value in ipairs({false, true, "custom"}) do
            calls = {}
            UF[case[1]](UF, "player", value)
            local expected = table.concat(calls, "\n")
            calls = {}
            UF:CreateUnitUpdater("player", case[2])(value)
            assert(table.concat(calls, "\n") == expected, case[1])
            calls = {}
            UF[case[1]](UF, "missing", value)
            UF:CreateUnitUpdater("missing", case[2])(value)
            assert(#calls == 0)
            frames.boss1, frames.boss3 = frame, frame
            UF:CreateUnitUpdater("boss", case[2], {count = 3})(value)
            assert(table.concat(calls, "\n") == expected .. "\n" .. expected)
        end
    end
end
''')
    subprocess.run([LUA, str(script), str(source)], check=True, capture_output=True, text=True)
