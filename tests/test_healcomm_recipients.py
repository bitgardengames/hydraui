"""Run the library's cast-start handler with stubbed game APIs."""
from pathlib import Path
import shutil
import subprocess
import pytest


def test_healcomm_resolves_visible_recipients_by_guid(tmp_path):
    runtime = shutil.which("texlua")
    if not runtime:
        pytest.skip("requires texlua")
    source = (Path(__file__).parents[1] / "HydraUI/Elements/Libraries/LibHealComm-4.0.lua").read_text()
    handler = source[source.index("local PlayerTargetSpells"):source.index("HealComm.UNIT_SPELLCAST_CHANNEL_START")]
    script = tmp_path / "healcomm.lua"
    script.write_text('''
local HealComm = {}
local units = {player = "self", party1 = "party"}
local guidToUnit = {self = "player", party = "party1"}
local castGUIDs = {[123] = "solo"}
local spellData = {["123"] = true}
local glyphCache = {}
local DIRECT_HEALS = 1
local playerGUID = "self"
local predicted, recipient
function UnitGUID(unit) return units[unit] end
function GetSpellInfo(id) return tostring(id) end
function UnitIsCharmed() return false end
function UnitPlayerControlled() return true end
function CalculateHealing(guid, _, unit)
    assert(UnitGUID(unit) == guid)
    recipient = unit
    return DIRECT_HEALS, 200
end
function GetHealTargets(_, guid) return guid end
function CastingInfo() return nil, nil, nil, 0, 2000 end
function parseDirectHeal(_, _, amount, _, guid) predicted = guid; assert(amount == 200) end
function sendMessage() end
local format = string.format
local function strsplit(_, value) return value end
''' + handler + '''
for _, candidate in ipairs({"target", "mouseover", "focus", "targettarget", "focustarget"}) do
    units[candidate] = "solo"
    predicted, recipient = nil, nil
    HealComm:UNIT_SPELLCAST_START("player", "cast", 123)
    assert(predicted == "solo" and recipient == candidate)
    units[candidate] = nil
end
castGUIDs[123] = "party"
HealComm:UNIT_SPELLCAST_START("player", "cast", 123)
assert(predicted == "party" and recipient == "party1")
castGUIDs[123] = "solo"
units.target = "new-target"
predicted = nil
HealComm:UNIT_SPELLCAST_START("player", "cast", 123)
assert(predicted == nil, "target change redirected the prediction")
castGUIDs[123] = nil
HealComm:UNIT_SPELLCAST_START("player", "cast", 123)
assert(predicted == nil)
''')
    result = subprocess.run([runtime, str(script)], capture_output=True, text=True)
    assert result.returncode == 0, result.stdout + result.stderr


def test_sent_cast_records_target_of_target_guid():
    source = (Path(__file__).parents[1] / "HydraUI/Elements/Libraries/LibHealComm-4.0.lua").read_text()
    assert 'UnitName("targettarget") == castTarget and UnitGUID("targettarget")' in source
