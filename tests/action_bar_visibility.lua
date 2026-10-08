local AB = {}
local GUI = { AddWidgets = function() end }
local HydraUI = { messages = {} }
function HydraUI:GetModule(name)
	return name == "GUI" and GUI or AB
end
function HydraUI:print(message)
	table.insert(self.messages, message)
end
local addon = {}
function addon:get()
	return HydraUI, {}, {}, {}, {}
end
assert(loadfile("HydraUI/Elements/ActionBars/TotemBar.lua"))("HydraUI", addon)

function CopyTable(value)
	local copy = {}
	for key, entry in pairs(value) do
		copy[key] = type(entry) == "table" and CopyTable(entry) or entry
	end
	return copy
end

local combat, pending, writes, saved, added, activated, state, presets, saving
function InCombatLockdown()
	return combat
end
function CreateFrame()
	pending = { events = {} }
	function pending:RegisterEvent(event)
		self.events[event] = true
	end
	function pending:UnregisterAllEvents()
		self.events = {}
	end
	function pending:SetScript(_, callback)
		self.callback = callback
	end
	return pending
end

Enum = {
	EditModeSystem = { ActionBar = 1 },
	EditModeActionBarSetting = { AlwaysShowButtons = 2 },
	EditModeLayoutType = { Preset = 0, Account = 1, Character = 2 },
}
Constants = { EditModeConsts = { EditModeMaxLayoutsPerType = 5 } }

local function layout(value, layoutType)
	return {
		layoutName = "Original", layoutType = layoutType,
		systems = {
			{ system = 1, settings = { { setting = 2, value = value }, { setting = 3, value = 7 } } },
			{ system = 1, settings = { { setting = 2, value = value } } },
			{ system = 4, settings = { { setting = 2, value = 0 } } },
		},
	}
end

local function reset(modern)
	combat, saving = false, false
	writes, saved, added, activated = {}, nil, nil, nil
	presets = { layout(0, 0), layout(0, 0) }
	state = { activeLayout = 3, layouts = { layout(0, 1) } }
	C_CVar = {
		GetCVar = function() return "0" end,
		SetCVar = function(name, value) writes[name] = value end,
	}
	C_EditMode = nil
	EditModePresetLayoutManager = nil
	if modern then
		EditModePresetLayoutManager = {
			GetCopyOfPresetLayouts = function() return CopyTable(presets) end,
		}
		C_EditMode = {
			GetLayouts = function() return CopyTable(state) end,
			SaveLayouts = function(info)
				assert(not saving, "Recursive save")
				saving = true
				saved = CopyTable(info)
				-- The API may synchronously emit its update event.
				pending.callback(pending, "EDIT_MODE_LAYOUTS_UPDATED")
				saving = false
			end,
			OnLayoutAdded = function(index, activate, imported)
				assert(activate and not imported)
				added = index
			end,
			SetActiveLayout = function(index) activated = index end,
		}
	end
end

-- Legacy clients use the CVar only, with no project-ID assumptions.
reset(false)
AB:ShowActionBars()
assert(writes.alwaysShowActionBars == "1")
assert(writes.showMultiActionBar7 == "1")
assert(pending.callback == nil)

-- Modern clients prefer Edit Mode even if a legacy CVar still exists.
reset(true)
AB:ShowActionBars()
assert(writes.alwaysShowActionBars == nil)
assert(activated == 3 and saved.activeLayout == 3)
assert(saved.layouts[3].systems[1].settings[1].value == 1)
assert(saved.layouts[3].systems[2].settings[1].value == 1)
assert(saved.layouts[3].systems[1].settings[2].value == 7)
assert(saved.layouts[3].systems[3].settings[1].value == 0)
assert(state.layouts[1].systems[1].settings[1].value == 0)
assert(presets[1].systems[1].settings[1].value == 0)
assert(pending.callback == nil)

-- Already-enabled layouts do not save or switch layouts.
reset(true)
state.layouts[1] = layout(1, 1)
AB:ShowActionBars()
assert(saved == nil and activated == nil)

-- Presets get an editable character copy; neither preset is modified.
reset(true)
state.activeLayout = 1
AB:ShowActionBars()
assert(added == 4 and activated == nil)
assert(saved.layouts[4].layoutType == 2)
assert(saved.layouts[4].systems[1].settings[1].value == 1)
assert(saved.layouts[1].systems[1].settings[1].value == 0)
assert(saved.layouts[3].layoutName == "Original")

-- No settings writes in combat, and initialization resumes after combat.
reset(true)
combat = true
AB:EnableAlwaysShowButtons()
assert(saved == nil and pending.events.PLAYER_REGEN_ENABLED)
combat = false
pending.callback(pending, "PLAYER_REGEN_ENABLED")
assert(saved and pending.callback == nil)

-- A full preset-copy destination does not overwrite an existing layout.
reset(true)
state.activeLayout = 1
state.layouts = {}
for i = 1, 5 do
	state.layouts[i] = layout(0, 2)
end
AB:EnableAlwaysShowButtons()
assert(saved == nil and #HydraUI.messages == 1)

print("Action bar empty-button defaults passed")
