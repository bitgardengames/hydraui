from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
UPDATE_SOURCE = REPOSITORY_ROOT / "HydraUI" / "Elements" / "Update.lua"


def update_source():
    return UPDATE_SOURCE.read_text()


def test_update_queue_uses_a_one_shot_timer_instead_of_frame_polling():
    source = update_source()

    assert 'SetScript("OnUpdate"' not in source
    assert "C_Timer.NewTimer(SendInterval" in source


def test_update_queue_keeps_only_one_timer_active_and_drains_in_order():
    source = update_source()

    assert "if self.SendTimer or QueueTail == 0 then" in source
    assert "self.SendTimer = nil\n\t\tself:SendNext()" in source
    assert "self:ScheduleSend()" in source
