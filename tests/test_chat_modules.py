"""Static architecture tests for the WoW-only chat modules."""
from pathlib import Path

ROOT = Path(__file__).parents[1] / "HydraUI" / "Elements"


def source(name):
    return (ROOT / "Chat" / name).read_text()


def test_formatter_pipeline_order_and_existing_link_protection():
    links = source("Links.lua")
    stages = [
        links.index("chat-enable-discord-links"),
        links.index("chat-enable-url-links"),
        links.index("chat-enable-email-links"),
        links.index("chat-enable-friend-links"),
    ]
    assert stages == sorted(stages)
    assert "protectedLinks = {}" in links
    assert "return protectedLinks[tonumber(index)]" in links


def test_history_is_a_bounded_circular_buffer_per_frame():
    history = source("History.lua")
    assert "MaxMessagesPerFrame = 25" in history
    assert "History.Count < MaxMessagesPerFrame" in history
    assert "History.Start = (History.Start % MaxMessagesPerFrame) + 1" in history
    assert "History.Frames[FrameName]" in history
    assert 'FrameName == "ChatFrame2"' in history


def test_global_history_is_migrated_into_per_frame_buffers():
    history = source("History.lua")
    assert "LegacyMaxHistoryMessages = 50" in history
    assert "local MigrateHistory" in history
    assert "AddToFrameHistory(FrameHistory, Entry)" in history
    assert "HydraUIData.ChatHistory[ProfileKey] = History" in history


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


def test_data_text_module_is_cached_when_chat_frames_are_initialized():
    frames = source("Frames.lua")
    load_time_lookup = 'DT = HydraUI:GetModule("DataText")'

    assert "local DT\n" in frames
    assert frames.count(load_time_lookup) == 1
    assert frames.index(load_time_lookup) > frames.index("function Chat:StyleChatFrames()")

    focus_hooks = frames[frames.index("local OnEditFocusLost"):frames.index("local CheckForBottom")]
    assert "HydraUI:GetModule" not in focus_hooks


def test_chat_mouse_wheel_is_explicitly_enabled_and_restored_during_layout():
    frames = source("Frames.lua")
    helper = frames[
        frames.index("local EnableMouseWheel"):frames.index("local UpdateHeader")
    ]
    layout = frames[
        frames.index("function Chat:MoveChatFrames()"):frames.index(
            "function Chat:StyleChatFrames()"
        )
    ]

    assert "frame:EnableMouseWheel(true)" in helper
    assert 'frame:SetScript("OnMouseWheel", OnMouseWheel)' in helper
    assert "EnableMouseWheel(Frame)" in layout


def test_chat_message_customization_does_not_replace_blizzard_add_message():
    frames = source("Frames.lua")

    assert 'ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ShortenChannelNames)' in frames
    assert 'hooksecurefunc(frame, "AddMessage", SaveMessage)' in frames
    assert "frame.AddMessage =" not in frames
    assert "frame.OldAddMessage" not in frames


def test_channel_shortening_prefers_localized_zone_name_over_decorated_event_name():
    frames = source("Frames.lua")
    channel_filter = frames[
        frames.index("local ShortenChannelNames"):frames.index(
            'ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL"'
        )
    ]

    assert "channelIndex, channelBaseName" in channel_filter
    assert "local baseName = ZoneChannelBaseNames[zoneChannelID] or channelBaseName" in channel_filter
    assert 'format("%s. %s", channelIndex, baseName)' in channel_filter
    assert "gsub" not in channel_filter


def test_channel_shortening_has_localized_legacy_client_fallbacks():
    frames = source("Frames.lua")
    fallbacks = frames[
        frames.index("local ZoneChannelBaseNames"):frames.index("Chat.StyledFrames")
    ]

    for zone_id, localized_global in {
        1: "GENERAL",
        2: "TRADE",
        22: "LOCAL_DEFENSE",
        23: "WORLD_DEFENSE",
        25: "GUILD_RECRUITMENT",
        26: "LOOKING_FOR_GROUP",
        42: "SERVICES",
    }.items():
        assert f"[{zone_id}] = {localized_global}" in fallbacks


def test_right_window_uses_one_background_opacity_setting():
    window = source("Window.lua")
    coordinator = (ROOT / "Chat.lua").read_text()

    assert window.count('CreateSlider("right-window-fill"') == 1
    assert "right-window-left-fill" not in window
    assert "right-window-right-fill" not in window
    assert "right-window-left-fill" not in coordinator
    assert "right-window-right-fill" not in coordinator
    assert "Window.Middle.Outside:SetBackdropColor" in window
    assert "Window.Left.Outside:SetBackdropColor" in window
    assert "Window.Right.Outside:SetBackdropColor" in window


def test_chat_install_uses_compatible_channel_api():
    coordinator = (ROOT / "Chat.lua").read_text()
    adapter = coordinator[coordinator.index("local AddChannelToFrame"):coordinator.index("function Chat:Install()")]
    install = coordinator[coordinator.index("function Chat:Install()"):coordinator.index("local MoveChatFrames")]

    assert "ChatFrame_AddChannel or function" in adapter
    assert "C_ChatInfo.AddChannelToWindow" in adapter
    assert "AddChatWindowChannel" in adapter
    assert "AddChannelToFrame(Trade, TRADE)" in install
    assert "AddChannelToFrame(Trade, GENERAL)" in install
