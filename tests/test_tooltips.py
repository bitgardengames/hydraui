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
