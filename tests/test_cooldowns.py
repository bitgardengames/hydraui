"""Guard secret cooldown times before tracking or announcing completion."""
from pathlib import Path


SOURCE = (Path(__file__).parents[1] / "HydraUI/Elements/Cooldowns.lua").read_text()


def test_cooldown_access_guard_covers_all_mainline_clients_and_both_times():
    guard = SOURCE.split("local function IsInaccessibleCooldown", 1)[1].split("\nend", 1)[0]
    assert "HydraUI.IsMainline and" in guard
    assert "issecretvalue(start) and not canaccessvalue(start)" in guard
    assert "issecretvalue(duration) and not canaccessvalue(duration)" in guard
    assert "IsMidnight" not in guard
    assert "IsForever" not in guard


def test_updates_discard_restricted_records_before_comparing_or_adding_times():
    update = SOURCE.split("local function UpdateRecord", 1)[1].split("local function UpdateExpiredRecords", 1)[0]
    guard = update.index("if IsInaccessibleCooldown(start, duration) then")
    comparison = update.index("if start and IsTrackedCooldown")
    assert guard < comparison
    assert "ReleaseRecord(records, id)\n\t\treturn" in update[guard:comparison]
    assert "ShowReady" not in update[guard:comparison]


def test_expiry_checks_access_before_rescheduling_or_announcing():
    expiry = SOURCE.split("local function UpdateExpiredRecords", 1)[1].split("function Cooldowns:OnUpdate", 1)[0]
    assert "if IsInaccessibleCooldown(Start, Duration) then\n\t\t\t\tReleaseRecord(records, ID)\n\t\t\telseif Start and IsTrackedCooldown" in expiry
