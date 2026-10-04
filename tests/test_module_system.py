from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
INITIALIZE_SOURCE = REPOSITORY_ROOT / "HydraUI" / "Elements" / "Initialize.lua"


def initialize_source():
    return INITIALIZE_SOURCE.read_text()


def test_module_and_plugin_lookups_return_registry_entries_directly():
    source = initialize_source()

    assert "function HydraUI:GetModule(name)\n\treturn Modules[name]\nend" in source
    assert "function HydraUI:GetPlugin(name)\n\treturn Plugins[name]\nend" in source


def test_registration_avoids_reentering_public_lookup_methods():
    source = initialize_source()

    assert "function HydraUI:NewModule(name)\n\tlocal Module = Modules[name]" in source
    assert "function HydraUI:NewPlugin(name)\n\tlocal Plugin = Plugins[name]" in source


def test_load_loops_cache_each_queue_entry():
    source = initialize_source()

    assert "for i = 1, #ModuleQueue do\n\t\tlocal Module = ModuleQueue[i]" in source
    assert "for i = 1, #PluginQueue do\n\t\tlocal Plugin = PluginQueue[i]" in source
