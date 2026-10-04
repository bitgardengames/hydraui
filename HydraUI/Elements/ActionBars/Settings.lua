local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local AB = HydraUI:GetModule("Action Bars")
local GUI = HydraUI:GetModule("GUI")

local NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS
local ActionBarDescriptors = AB.ActionBarDescriptors
local BarOnEnter = AB.BarOnEnter
local BarOnLeave = AB.BarOnLeave

local UpdateBar = {}
local UpdateEnableBar = {}

local function CreateBarLayoutCallback(descriptor)
	local index, field = descriptor.index, descriptor.field
	local key = "ab-bar" .. index
	return function()
		local bar = AB[field]
		if bar then
			AB:PositionButtons(bar, descriptor.hasButtonMax and Settings[key .. "-button-max"] or #bar, Settings[key .. "-per-row"], Settings[key .. "-button-size"], Settings[key .. "-button-gap"])
		end
	end
end

local function CreateBarEnableCallback(descriptor)
	local field = descriptor.field
	return function(value)
		local bar = AB[field]
		if value then
			AB:EnableBar(bar)
		else
			AB:DisableBar(bar)
		end
	end
end

for _, descriptor in ipairs(ActionBarDescriptors) do
	UpdateBar[descriptor.index] = CreateBarLayoutCallback(descriptor)
	UpdateEnableBar[descriptor.index] = CreateBarEnableCallback(descriptor)
end

local UpdatePetBar = function()
	AB:PositionButtons(AB.PetBar, NUM_PET_ACTION_SLOTS, Settings["ab-pet-per-row"], Settings["ab-pet-button-size"], Settings["ab-pet-button-gap"])

	for i = 1, #AB.PetBar do
		local Name = AB.PetBar[i]:GetName()

		if _G[Name .. "AutoCastable"] then
			_G[Name .. "AutoCastable"]:SetSize(Settings["ab-pet-button-size"] * 2 - 4, Settings["ab-pet-button-size"] * 2 - 4)
		end
	end
end

local UpdateStanceBar = function()
	AB:PositionButtons(AB.StanceBar, #AB.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])
end

local UpdateEnablePetBar = function(value)
	if value then
		AB:EnableBar(AB.PetBar)
	else
		AB:DisableBar(AB.PetBar)
	end
end

local UpdateEnableStanceBar = function(value)
	if value then
		AB:EnableBar(AB.StanceBar)
	else
		AB:DisableBar(AB.StanceBar)
	end
end

local UpdateEnableTotemBar = function(value)
	if value then
		AB:EnableBar(AB.TotemBar)
	else
		AB:DisableBar(AB.TotemBar)
	end
end

function AB:SetButtonRegionAlpha(regionName, alpha, includeAuxiliaryBars)
	for _, bar in ipairs(self.Bars or {}) do
		for i = 1, #bar do
			local region = bar[i][regionName]
			if region then
				region:SetAlpha(alpha)
			end
		end
	end

	if includeAuxiliaryBars then
		local function updateAuxiliaryBar(bar)
			if not bar then
				return
			end
			for i = 1, #bar do
				local region = bar[i][regionName]
				if region then
					region:SetAlpha(alpha)
				end
			end
		end

		updateAuxiliaryBar(self.PetBar)
		updateAuxiliaryBar(self.StanceBar)
		if ExtraActionButton1 and ExtraActionButton1[regionName] then
			ExtraActionButton1[regionName]:SetAlpha(alpha)
		end
	end
end

local UpdateShowHotKey = function(value)
	AB:SetButtonRegionAlpha("HotKey", value and 1 or 0, true)
end
local UpdateShowMacroName = function(value)
	AB:SetButtonRegionAlpha("Name", value and 1 or 0, false)
end
local UpdateShowCount = function(value)
	AB:SetButtonRegionAlpha("Count", value and 1 or 0, false)
end

function AB:UpdateButtonFont(button)
	if button.HotKey then
		HydraUI:SetFontInfo(button.HotKey, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
	end

	if button.Name then
		HydraUI:SetFontInfo(button.Name, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
	end

	if button.Count then
		HydraUI:SetFontInfo(button.Count, Settings["ab-font"], Settings["ab-font-size"], Settings["ab-font-flags"])
	end

	if button.cooldown then
		local Cooldown = button.cooldown:GetRegions()

		if Cooldown then
			HydraUI:SetFontInfo(Cooldown, Settings["ab-font"], Settings["ab-cd-size"], Settings["ab-font-flags"])
		end
	end
end

local UpdateActionBarFont = function()
	for _, bar in ipairs(AB.Bars or {}) do
		for i = 1, #bar do
			AB:UpdateButtonFont(bar[i])
		end
	end

	local auxiliaryBars = { "PetBar", "StanceBar" }
	for _, field in ipairs(auxiliaryBars) do
		local bar = AB[field]
		if bar then
			for i = 1, #bar do
				AB:UpdateButtonFont(bar[i])
			end
		end
	end
end

local function SetBarHover(bar, enabled)
	if not bar then
		return
	end

	bar.ShouldFade = enabled
	bar:SetScript("OnEnter", enabled and BarOnEnter or nil)
	bar:SetScript("OnLeave", enabled and BarOnLeave or nil)
	bar:SetAlpha(enabled and 0 or (bar.MaxAlpha / 100))

	for i = 1, #bar do
		bar[i].cooldown:SetDrawBling(not enabled)
	end
end

local function SetBarAlpha(bar, percent)
	if not bar then
		return
	end

	bar.MaxAlpha = percent
	bar:SetAlpha(bar.ShouldFade and 0 or (percent / 100))
end

local UpdateHoverBar = {}
local UpdateAlphaBar = {}

local function CreateBarHoverCallback(descriptor)
	return function(value)
		SetBarHover(AB[descriptor.field], value)
	end
end

local function CreateBarAlphaCallback(descriptor)
	return function(value)
		SetBarAlpha(AB[descriptor.field], value)
	end
end

for _, descriptor in ipairs(ActionBarDescriptors) do
	UpdateHoverBar[descriptor.index] = CreateBarHoverCallback(descriptor)
	UpdateAlphaBar[descriptor.index] = CreateBarAlphaCallback(descriptor)
end

local UpdatePetHover = function(value)
	SetBarHover(AB.PetBar, value)
end
local UpdateStanceHover = function(value)
	SetBarHover(AB.StanceBar, value)
end
local UpdatePetBarAlpha = function(value)
	SetBarAlpha(AB.PetBar, value)
end
local UpdateStanceBarAlpha = function(value)
	SetBarAlpha(AB.StanceBar, value)
end

GUI:AddWidgets(Language["General"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-enable", Settings["ab-enable"], Language["Enable Action Bar"], Language["Enable action bars module"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-show-hotkey", Settings["ab-show-hotkey"], Language["Show Hotkeys"], Language["Display hotkey text on action buttons"], UpdateShowHotKey)
	left:CreateSwitch("ab-show-macro", Settings["ab-show-macro"], Language["Show Macro Names"], Language["Display macro name text on action buttons"], UpdateShowMacroName)
	left:CreateSwitch("ab-show-count", Settings["ab-show-count"], Language["Show Count Text"], Language["Display count text on action buttons"], UpdateShowCount)

	left:CreateHeader(Language["Font"])
	left:CreateDropdown("ab-font", Settings["ab-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the action bar buttons"], UpdateActionBarFont, "Font")
	left:CreateSlider("ab-font-size", Settings["ab-font-size"], 8, 42, 1, Language["Font Size"], Language["Set the font size of the action bar buttons"], UpdateActionBarFont)
	left:CreateSlider("ab-cd-size", Settings["ab-cd-size"], 8, 42, 1, Language["Cooldown Font Size"], Language["Set the font size of the action bar cooldowns"], UpdateActionBarFont)
	left:CreateDropdown("ab-font-flags", Settings["ab-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the action bar buttons"], UpdateActionBarFont)
end)

local function AddActionBarWidgets(descriptor)
	if not descriptor.available() then
		return
	end

	local index = descriptor.index
	local key = "ab-bar" .. index
	GUI:AddWidgets(Language["General"], Language[descriptor.label], Language["Action Bars"], function(left, right)
		left:CreateHeader(Language["Enable"])
		left:CreateSwitch(key .. "-enable", Settings[key .. "-enable"], Language["Enable Bar"], Language["Enable action bar " .. index], UpdateEnableBar[index])

		left:CreateHeader(Language["Styling"])
		left:CreateSwitch(key .. "-hover", Settings[key .. "-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateHoverBar[index])
		left:CreateSlider(key .. "-alpha", Settings[key .. "-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateAlphaBar[index])

		right:CreateHeader(Language["Buttons"])
		right:CreateSlider(key .. "-per-row", Settings[key .. "-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar[index])
		if descriptor.hasButtonMax then
			right:CreateSlider(key .. "-button-max", Settings[key .. "-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar[index])
		end
		right:CreateSlider(key .. "-button-size", Settings[key .. "-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar[index])
		right:CreateSlider(key .. "-button-gap", Settings[key .. "-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar[index])
	end)
end

for _, descriptor in ipairs(ActionBarDescriptors) do
	AddActionBarWidgets(descriptor)
end

GUI:AddWidgets(Language["General"], Language["Pet Bar"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-pet-enable", Settings["ab-pet-enable"], Language["Enable Bar"], Language["Enable the pet action bar"], UpdateEnablePetBar)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-pet-hover", Settings["ab-pet-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdatePetHover)
	left:CreateSlider("ab-pet-alpha", Settings["ab-pet-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdatePetBarAlpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-pet-per-row", Settings["ab-pet-per-row"], 1, NUM_PET_ACTION_SLOTS, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdatePetBar)
	right:CreateSlider("ab-pet-button-size", Settings["ab-pet-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdatePetBar)
	right:CreateSlider("ab-pet-button-gap", Settings["ab-pet-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdatePetBar)
end)

GUI:AddWidgets(Language["General"], Language["Stance Bar"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-stance-enable", Settings["ab-stance-enable"], Language["Enable Bar"], Language["Enable the stance bar"], UpdateEnableStanceBar)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-stance-hover", Settings["ab-stance-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateStanceHover)
	left:CreateSlider("ab-stance-alpha", Settings["ab-stance-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateStanceBarAlpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-stance-per-row", Settings["ab-stance-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateStanceBar)
	right:CreateSlider("ab-stance-button-size", Settings["ab-stance-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateStanceBar)
	right:CreateSlider("ab-stance-button-gap", Settings["ab-stance-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateStanceBar)
end)

GUI:AddWidgets(Language["General"], Language["Totem Bar"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-totem-enable", Settings["ab-totem-enable"], Language["Enable Bar"], Language["Enable the totem bar"], UpdateEnableTotemBar)
end)
