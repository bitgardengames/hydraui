"""Static architecture tests for the WoW-only chat modules."""
from pathlib import Path

ROOT = Path(__file__).parents[1] / "HydraUI" / "Elements"


def source(name):
    return (ROOT / "Chat" / name).read_text()


def test_formatter_pipeline_order_and_existing_link_protection():
    links = source("Links.lua")
    stages = [links.index('chat-enable-discord-links'), links.index('chat-enable-url-links'),
              links.index('chat-enable-email-links'), links.index('chat-enable-friend-links')]
    assert stages == sorted(stages)
    assert 'protected = {}' in links
    assert 'return protected[tonumber(index)]' in links


def test_history_is_a_bounded_circular_buffer():
    history = source("History.lua")
    assert "MaxHistoryMessages = 50" in history
    assert "History.Count < MaxHistoryMessages" in history
    assert "History.Start = (History.Start % MaxHistoryMessages) + 1" in history


def test_settings_callbacks_use_explicit_styled_frame_registry():
    frames = source("Frames.lua")
    coordinator = (ROOT / "Chat.lua").read_text()
    assert "Chat.StyledFrames" in frames
    assert "self.StyledFrames[frame] = true" in frames
    assert "Chat:ForEachStyledFrame" in coordinator
    callback_area = coordinator[coordinator.index("local UpdateChatFont"):]
    assert 'for i = 1, NUM_CHAT_WINDOWS' not in callback_area


def test_temporary_hooks_are_registered_explicitly():
    frames = source("Frames.lua")
    assert "Chat.TemporaryWindowHooks" in frames
    assert "hooks.FCF_OpenTemporaryWindow" in frames


def test_edit_box_resolves_data_text_module_after_addon_files_load():
    frames = source("Frames.lua")
    declarations = frames[:frames.index("local OnEditFocusLost")]
    focus_lost = frames[frames.index("local OnEditFocusLost"):frames.index("local OnEditFocusGained")]
    focus_gained = frames[frames.index("local OnEditFocusGained"):frames.index("local CheckForBottom")]

    assert 'local DT = HydraUI:GetModule("DataText")' not in declarations
    assert 'DT = DT or HydraUI:GetModule("DataText")' in focus_lost
    assert 'DT = DT or HydraUI:GetModule("DataText")' in focus_gained
    assert "if not DT then" in focus_lost
    assert "if not DT then" in focus_gained
