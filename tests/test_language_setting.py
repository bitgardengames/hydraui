from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
INITIALIZE = (REPOSITORY_ROOT / "HydraUI/Elements/Initialize.lua").read_text()
DEFAULTS = (REPOSITORY_ROOT / "HydraUI/Elements/Defaults.lua").read_text()
GENERAL = (REPOSITORY_ROOT / "HydraUI/Elements/General.lua").read_text()
DROPDOWNS = (REPOSITORY_ROOT / "HydraUI/Elements/GUI/Dropdowns.lua").read_text()


def test_language_uses_the_client_locale_as_its_default_setting():
    assert 'Defaults["ui-language"] = HydraUI.ClientLocale' in DEFAULTS
    assert 'local Languages = {}' in INITIALIZE
    assert '"AUTO"' not in INITIALIZE


def test_language_uses_the_standard_dropdown_persistence_path():
    assert (
        'CreateDropdown("ui-language", Settings["ui-language"], '
        'HydraUI:GetLanguageList()' in GENERAL
    )
    assert 'SetLanguage' not in INITIALIZE
    assert 'SelectedLanguage' not in INITIALIZE
    assert '"Language"' not in DROPDOWNS


def test_saved_profile_language_is_available_before_translations_load():
    assert 'HydraUIProfileData[HydraUI.UserProfileKey]' in INITIALIZE
    assert 'Profile["ui-language"]' in INITIALIZE
