from pathlib import Path


TAGS = Path(__file__).parents[1] / "HydraUI/Elements/UnitFrames/Tags.lua"


def test_native_tags_pass_secret_values_to_the_font_string_without_inspection():
    source = TAGS.read_text()
    formatter = source[
        source.index("local function FormatTagString"):
        source.index("local function TagEvent")
    ]

    secret_guard = "HydraUI.IsMainline and issecretvalue(value) and not canaccessvalue(value)"
    assert secret_guard in formatter
    assert "if secret or (value ~= nil and value ~= \"\") then" in formatter
    assert "binding.fontString:SetFormattedText(output, unpack(values))" in formatter
    assert "part.prefix .. tostring(value) .. part.suffix" not in formatter


def test_native_tag_literals_escape_format_placeholders():
    source = TAGS.read_text()
    formatter = source[
        source.index("local function FormatTagString"):
        source.index("local function UpdateBinding")
    ]

    assert 'gsub(part, "%%", "%%%%")' in formatter
    assert 'gsub(part.prefix, "%%", "%%%%") .. "%s"' in formatter
