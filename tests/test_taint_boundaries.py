"""Guard Blizzard-owned data read by secure stance and chat update paths."""
from pathlib import Path
import re

ROOT = Path(__file__).parents[1] / "HydraUI/Elements"


def test_button_styling_preserves_blizzard_methods_and_icon_fields():
    source = (ROOT / "ActionBars/Buttons.lua").read_text()
    assert not re.search(r"button\.(?:HotKey|Name|Count)\.(?:SetText|SetTextColor)\s*=", source)
    assert not re.search(r"button\.icon\s*=", source)
    assert 'hooksecurefunc(button, "Update", AB.UpdateHotKeyText)' in source


def test_chat_does_not_write_blizzard_chat_type_registry():
    source = (ROOT / "Chat.lua").read_text()
    assert "ChatTypeInfo[" not in source
    assert "CHAT_URL_SEND" not in source
    assert "CHAT_DISCORD_SEND" not in source


def test_link_copying_uses_its_own_edit_box():
    source = (ROOT / "Chat/Links.lua").read_text()
    assert 'CreateFrame("EditBox", nil, CopyDialog, "InputBoxTemplate")' in source
    assert 'SetAttribute("chatType"' not in source
    for offset in (5, 7, 8, 9):
        assert f"ShowCopyDialog(sub(link, {offset}))" in source
    assert "PreviousSetHyperlink(self, link, text, button, chatFrame)" in source
    assert 'SetScript("OnEscapePressed"' in source
