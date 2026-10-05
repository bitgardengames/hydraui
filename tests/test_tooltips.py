"""Static regression tests for tooltip client-version behavior."""
from pathlib import Path


TOOLTIPS_SOURCE = (
    Path(__file__).parents[1] / "HydraUI" / "Elements" / "Tooltips.lua"
).read_text()


def test_vendor_price_is_not_added_on_clients_that_supply_it():
    assert (
        'if not (HydraUI.IsMainline or HydraUI.IsMists) and Settings["tooltips-show-price"] then'
        in TOOLTIPS_SOURCE
    )


def test_guild_name_is_only_added_on_vanilla():
    assert "if HydraUI.IsVanilla and Guild then" in TOOLTIPS_SOURCE


def test_vanilla_guild_line_is_appended_with_guild_formatting():
    assert "self:AddLine(FormatGuild(Guild, Rank))" in TOOLTIPS_SOURCE
    assert "AddVanillaGuildLine" not in TOOLTIPS_SOURCE
