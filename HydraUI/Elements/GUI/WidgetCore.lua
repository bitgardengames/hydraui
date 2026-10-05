local HydraUI, Language, Assets, Settings = select(2, ...):get()
local GUI = HydraUI:GetModule("GUI")

local Core = {
	SPACING = 3,
	HEADER_HEIGHT = 20,
	HEADER_SPACING = 5,
	GROUP_HEIGHT = 80,
	WIDGET_HEIGHT = 20,
	LABEL_SPACING = 3,
	SELECTED_HIGHLIGHT_ALPHA = 0.25,
	MOUSEOVER_HIGHLIGHT_ALPHA = 0.1,
	Controllers = {
		Dropdown = { Active = nil },
		Input = { Active = nil },
		Color = { Active = nil },
	},
}
Core.GROUP_WIDTH = 279 - (Core.SPACING * 2)
GUI.WidgetCore = Core

function Core.RegisterWidget(owner, anchor, id)
	table.insert(owner.Widgets, anchor)
	if id and id ~= "" then
		GUI.WidgetID[id] = anchor
	end

	return anchor
end

-- Constructors receive defaults, but a saved setting always takes priority.
function Core.GetInitialValue(id, default)
	if Settings[id] ~= nil then
		return Settings[id]
	end

	return default
end

function Core.SetRequiresReload(self, flag)
	self.ReloadFlag = flag

	return self
end

function Core.DisableSaving(self)
	self.IsSavingDisabled = true

	return self
end

local PersistenceOptOut = {
	["ui-profile"] = true,
	["profile-copy"] = true,
}

function Core.ShouldPersist(id, widget)
	return not PersistenceOptOut[id] and not (widget and widget.IsSavingDisabled)
end

function Core.SetVariable(id, value, widget)
	if not Core.ShouldPersist(id, widget) then
		return false
	end

	local name = HydraUI:GetActiveProfileName()

	if name then
		HydraUI:SetProfileValue(name, id, value)
	end

	Settings[id] = value

	return true
end

function Core.NotifyValueChanged(widget, value)
	if widget.ReloadFlag then
		HydraUI:DisplayPopup(Language["Attention"], Language["You have changed a setting that requires a UI reload. Would you like to reload the UI now?"], ACCEPT, widget.Hook, CANCEL, nil, value, widget.ID)
	elseif widget.Hook then
		widget.Hook(value, widget.ID)
	end
end

-- Every value control finishes an interaction the same way: save once, then
-- notify once. SetVariable handles controls which explicitly opt out of saving.
function Core.CommitValue(widget, value)
	Core.SetVariable(widget.ID, value, widget)
	Core.NotifyValueChanged(widget, value)
end

function Core.Round(num, dec)
	local mult = 10 ^ (dec or 0)

	return math.floor(num * mult + 0.5) / mult
end

function Core.TrimHex(s)
	return string.match(s, "|c%x%x%x%x%x%x%x%x(.-)|r") or s
end

function Core.NormalizeDropdownOffset(offset, count, shown)
	local requestedOffset = Core.Round(tonumber(offset) or 1)
	local maximumOffset = math.max((count or 0) - (shown or 0) + 1, 1)

	return math.min(math.max(requestedOffset, 1), maximumOffset)
end

function Core.NormalizeSliderValue(value, minimum, maximum, step)
	value = tonumber(value) or minimum

	if step >= 1 then
		value = math.floor(value)
	else
		value = Core.Round(value, step <= 0.01 and 2 or 1)
	end

	return math.min(math.max(value, minimum), maximum)
end

function Core.NormalizeColor(value)
	local hex = tostring(value or ""):gsub("#", ""):upper()

	if #hex == 8 then
		hex = hex:sub(3)
	end

	if #hex ~= 6 or hex:find("[^0-9A-F]") then
		return "FFFFFF"
	end

	return hex
end

function Core.AnchorOnEnter(self)
	if self.Tooltip and string.match(self.Tooltip, "%S") then
		local red, green, blue = HydraUI:HexToRGB(Settings["ui-widget-font-color"])

		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:AddLine(self.Tooltip, red, green, blue, true)
		GameTooltip:Show()
	end
end

function Core.AnchorOnLeave()
	GameTooltip:Hide()
end

function Core.FadeOnFinished(self)
	self.Parent:Hide()
end
