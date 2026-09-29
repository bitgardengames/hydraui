local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()
local AB = HydraUI:GetModule("Action Bars")
local GUI = HydraUI:GetModule("GUI")

local UpdateBar = {}
local UpdateEnableBar = {}

local function CreateBarLayoutCallback(descriptor)
	local index, field = descriptor.index, descriptor.field
	local key = "ab-bar" .. index
	return function()
		local bar = AB[field]
		if bar then
			AB:PositionButtons(bar, Settings[key .. "-button-max"], Settings[key .. "-per-row"], Settings[key .. "-button-size"], Settings[key .. "-button-gap"])
		end
	end
end

local function CreateBarEnableCallback(descriptor)
	local field = descriptor.field
	return function(value)
		local bar = AB[field]
		if value then AB:EnableBar(bar) else AB:DisableBar(bar) end
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
			if region then region:SetAlpha(alpha) end
		end
	end

	if includeAuxiliaryBars then
		local function updateAuxiliaryBar(bar)
			if not bar then return end
			for i = 1, #bar do
				local region = bar[i][regionName]
				if region then region:SetAlpha(alpha) end
			end
		end

		updateAuxiliaryBar(self.PetBar)
		updateAuxiliaryBar(self.StanceBar)
		if ExtraActionButton1 and ExtraActionButton1[regionName] then
			ExtraActionButton1[regionName]:SetAlpha(alpha)
		end
	end
end

local UpdateShowHotKey = function(value) AB:SetButtonRegionAlpha("HotKey", value and 1 or 0, true) end
local UpdateShowMacroName = function(value) AB:SetButtonRegionAlpha("Name", value and 1 or 0, false) end
local UpdateShowCount = function(value) AB:SetButtonRegionAlpha("Count", value and 1 or 0, false) end

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
	for i = 1, 12 do
		AB:UpdateButtonFont(AB.Bar1[i])
		AB:UpdateButtonFont(AB.Bar2[i])
		AB:UpdateButtonFont(AB.Bar3[i])
		AB:UpdateButtonFont(AB.Bar4[i])
		AB:UpdateButtonFont(AB.Bar5[i])

		if AB.Bar6 then
			AB:UpdateButtonFont(AB.Bar6[i])
			AB:UpdateButtonFont(AB.Bar7[i])
			AB:UpdateButtonFont(AB.Bar8[i])
		end

		if AB.PetBar[i] then
			AB:UpdateButtonFont(AB.PetBar[i])
		end

		if AB.StanceBar[i] then
			AB:UpdateButtonFont(AB.StanceBar[i])
		end
	end
end

local UpdateBar1Hover = function(value)
	AB.Bar1.ShouldFade = value

	if value then
		AB.Bar1:SetAlpha(0)
		AB.Bar1:SetScript("OnEnter", AB.BarOnEnter)
		AB.Bar1:SetScript("OnLeave", AB.BarOnLeave)

		for i = 1, #AB.Bar1 do
			AB.Bar1[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar1:SetAlpha(1)
		AB.Bar1:SetScript("OnEnter", nil)
		AB.Bar1:SetScript("OnLeave", nil)

		for i = 1, #AB.Bar1 do
			AB.Bar1[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar2Hover = function(value)
	AB.Bar2.ShouldFade = value

	if value then
		AB.Bar2:SetAlpha(0)
		AB.Bar2:SetScript("OnEnter", AB.BarOnEnter)
		AB.Bar2:SetScript("OnLeave", AB.BarOnLeave)

		for i = 1, #AB.Bar2 do
			AB.Bar2[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar2:SetAlpha(1)
		AB.Bar2:SetScript("OnEnter", nil)
		AB.Bar2:SetScript("OnLeave", nil)

		for i = 1, #AB.Bar2 do
			AB.Bar2[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar3Hover = function(value)
	AB.Bar3.ShouldFade = value

	if value then
		AB.Bar3:SetAlpha(0)
		AB.Bar3:SetScript("OnEnter", AB.BarOnEnter)
		AB.Bar3:SetScript("OnLeave", AB.BarOnLeave)

		for i = 1, #AB.Bar3 do
			AB.Bar3[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar3:SetAlpha(1)
		AB.Bar3:SetScript("OnEnter", nil)
		AB.Bar3:SetScript("OnLeave", nil)

		for i = 1, #AB.Bar3 do
			AB.Bar3[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar4Hover = function(value)
	AB.Bar4.ShouldFade = value

	if value then
		AB.Bar4:SetAlpha(0)
		AB.Bar4:SetScript("OnEnter", AB.BarOnEnter)
		AB.Bar4:SetScript("OnLeave", AB.BarOnLeave)

		for i = 1, #AB.Bar4 do
			AB.Bar4[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar4:SetAlpha(1)
		AB.Bar4:SetScript("OnEnter", nil)

		for i = 1, #AB.Bar4 do
			AB.Bar4[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar5Hover = function(value)
	AB.Bar5.ShouldFade = value

	if value then
		AB.Bar5:SetAlpha(0)
		AB.Bar5:SetScript("OnEnter", AB.BarOnEnter)
		AB.Bar5:SetScript("OnLeave", AB.BarOnLeave)

		for i = 1, #AB.Bar5 do
			AB.Bar5[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar5:SetAlpha(1)
		AB.Bar5:SetScript("OnEnter", nil)
		AB.Bar5:SetScript("OnLeave", nil)

		for i = 1, #AB.Bar5 do
			AB.Bar5[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar6Hover = function(value)
	AB.Bar6.ShouldFade = value

	if value then
		AB.Bar6:SetAlpha(0)
		AB.Bar6:SetScript("OnEnter", AB.BarOnEnter)
		AB.Bar6:SetScript("OnLeave", AB.BarOnLeave)

		for i = 1, #AB.Bar6 do
			AB.Bar6[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar6:SetAlpha(1)
		AB.Bar6:SetScript("OnEnter", nil)
		AB.Bar6:SetScript("OnLeave", nil)

		for i = 1, #AB.Bar6 do
			AB.Bar6[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar7Hover = function(value)
	AB.Bar7.ShouldFade = value

	if value then
		AB.Bar7:SetAlpha(0)
		AB.Bar7:SetScript("OnEnter", AB.BarOnEnter)
		AB.Bar7:SetScript("OnLeave", AB.BarOnLeave)

		for i = 1, #AB.Bar7 do
			AB.Bar7[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar7:SetAlpha(1)
		AB.Bar7:SetScript("OnEnter", nil)
		AB.Bar7:SetScript("OnLeave", nil)

		for i = 1, #AB.Bar7 do
			AB.Bar7[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar8Hover = function(value)
	AB.Bar8.ShouldFade = value

	if value then
		AB.Bar8:SetAlpha(0)
		AB.Bar8:SetScript("OnEnter", AB.BarOnEnter)
		AB.Bar8:SetScript("OnLeave", AB.BarOnLeave)

		for i = 1, #AB.Bar8 do
			AB.Bar8[i].cooldown:SetDrawBling(false)
		end
	else
		AB.Bar8:SetAlpha(1)
		AB.Bar8:SetScript("OnEnter", nil)
		AB.Bar8:SetScript("OnLeave", nil)

		for i = 1, #AB.Bar8 do
			AB.Bar8[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdatePetHover = function(value)
	AB.PetBar.ShouldFade = value

	if value then
		AB.PetBar:SetAlpha(0)
		AB.PetBar:SetScript("OnEnter", AB.BarOnEnter)
		AB.PetBar:SetScript("OnLeave", AB.BarOnLeave)

		for i = 1, #AB.PetBar do
			AB.PetBar[i].cooldown:SetDrawBling(false)
		end
	else
		AB.PetBar:SetAlpha(1)
		AB.PetBar:SetScript("OnEnter", nil)
		AB.PetBar:SetScript("OnLeave", nil)

		for i = 1, #AB.PetBar do
			AB.PetBar[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateStanceHover = function(value)
	AB.StanceBar.ShouldFade = value

	if value then
		AB.StanceBar:SetAlpha(0)
		AB.StanceBar:SetScript("OnEnter", AB.BarOnEnter)
		AB.StanceBar:SetScript("OnLeave", AB.BarOnLeave)

		for i = 1, #AB.StanceBar do
			AB.StanceBar[i].cooldown:SetDrawBling(false)
		end
	else
		AB.StanceBar:SetAlpha(1)
		AB.StanceBar:SetScript("OnEnter", nil)
		AB.StanceBar:SetScript("OnLeave", nil)

		for i = 1, #AB.StanceBar do
			AB.StanceBar[i].cooldown:SetDrawBling(true)
		end
	end
end

local UpdateBar1Alpha = function(value)
	AB.Bar1.MaxAlpha = value
	AB.Bar1:SetAlpha(value / 100)
end

local UpdateBar2Alpha = function(value)
	AB.Bar2.MaxAlpha = value
	AB.Bar2:SetAlpha(value / 100)
end

local UpdateBar3Alpha = function(value)
	AB.Bar3.MaxAlpha = value
	AB.Bar3:SetAlpha(value / 100)
end

local UpdateBar4Alpha = function(value)
	AB.Bar4.MaxAlpha = value
	AB.Bar4:SetAlpha(value / 100)
end

local UpdateBar5Alpha = function(value)
	AB.Bar5.MaxAlpha = value
	AB.Bar5:SetAlpha(value / 100)
end

local UpdateBar6Alpha = function(value)
	AB.Bar6.MaxAlpha = value
	AB.Bar6:SetAlpha(value / 100)
end

local UpdateBar7Alpha = function(value)
	AB.Bar7.MaxAlpha = value
	AB.Bar7:SetAlpha(value / 100)
end

local UpdateBar8Alpha = function(value)
	AB.Bar8.MaxAlpha = value
	AB.Bar8:SetAlpha(value / 100)
end

local UpdatePetBarAlpha = function(value)
	AB.PetBar.MaxAlpha = value
	AB.PetBar:SetAlpha(value / 100)
end

local UpdateStanceBarAlpha = function(value)
	AB.StanceBar.MaxAlpha = value
	AB.StanceBar:SetAlpha(value / 100)
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

GUI:AddWidgets(Language["General"], Language["Bar 1"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-bar1-enable", Settings["ab-bar1-enable"], Language["Enable Bar"], Language["Enable action bar 1"], UpdateEnableBar[1])

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-bar1-hover", Settings["ab-bar1-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar1Hover)
	left:CreateSlider("ab-bar1-alpha", Settings["ab-bar1-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar1Alpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-bar1-per-row", Settings["ab-bar1-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar[1])
	right:CreateSlider("ab-bar1-button-max", Settings["ab-bar1-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar[1])
	right:CreateSlider("ab-bar1-button-size", Settings["ab-bar1-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar[1])
	right:CreateSlider("ab-bar1-button-gap", Settings["ab-bar1-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar[1])
end)

GUI:AddWidgets(Language["General"], Language["Bar 2"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-bar2-enable", Settings["ab-bar2-enable"], Language["Enable Bar"], Language["Enable action bar 2"], UpdateEnableBar[2])

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-bar2-hover", Settings["ab-bar2-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar2Hover)
	left:CreateSlider("ab-bar2-alpha", Settings["ab-bar2-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar2Alpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-bar2-per-row", Settings["ab-bar2-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar[2])
	right:CreateSlider("ab-bar2-button-max", Settings["ab-bar2-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar[2])
	right:CreateSlider("ab-bar2-button-size", Settings["ab-bar2-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar[2])
	right:CreateSlider("ab-bar2-button-gap", Settings["ab-bar2-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar[2])
end)

GUI:AddWidgets(Language["General"], Language["Bar 3"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-bar3-enable", Settings["ab-bar3-enable"], Language["Enable Bar"], Language["Enable action bar 3"], UpdateEnableBar[3])

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-bar3-hover", Settings["ab-bar3-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar3Hover)
	left:CreateSlider("ab-bar3-alpha", Settings["ab-bar3-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar3Alpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-bar3-per-row", Settings["ab-bar3-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar[3])
	right:CreateSlider("ab-bar3-button-max", Settings["ab-bar3-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar[3])
	right:CreateSlider("ab-bar3-button-size", Settings["ab-bar3-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar[3])
	right:CreateSlider("ab-bar3-button-gap", Settings["ab-bar3-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar[3])
end)

GUI:AddWidgets(Language["General"], Language["Bar 4"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-bar4-enable", Settings["ab-bar4-enable"], Language["Enable Bar"], Language["Enable action bar 4"], UpdateEnableBar[4])

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-bar4-hover", Settings["ab-bar4-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar4Hover)
	left:CreateSlider("ab-bar4-alpha", Settings["ab-bar4-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar4Alpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-bar4-per-row", Settings["ab-bar4-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar[4])
	right:CreateSlider("ab-bar4-button-max", Settings["ab-bar4-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar[4])
	right:CreateSlider("ab-bar4-button-size", Settings["ab-bar4-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar[4])
	right:CreateSlider("ab-bar4-button-gap", Settings["ab-bar4-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar[4])
end)

GUI:AddWidgets(Language["General"], Language["Bar 5"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-bar5-enable", Settings["ab-bar5-enable"], Language["Enable Bar"], Language["Enable action bar 5"], UpdateEnableBar[5])

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-bar5-hover", Settings["ab-bar5-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar5Hover)
	left:CreateSlider("ab-bar5-alpha", Settings["ab-bar5-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar5Alpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-bar5-per-row", Settings["ab-bar5-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar[5])
	right:CreateSlider("ab-bar5-button-max", Settings["ab-bar5-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar[5])
	right:CreateSlider("ab-bar5-button-size", Settings["ab-bar5-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar[5])
	right:CreateSlider("ab-bar5-button-gap", Settings["ab-bar5-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar[5])
end)


GUI:AddWidgets(Language["General"], Language["Bar 6"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-bar6-enable", Settings["ab-bar6-enable"], Language["Enable Bar"], Language["Enable action bar 6"], UpdateEnableBar[6])

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-bar6-hover", Settings["ab-bar6-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar6Hover)
	left:CreateSlider("ab-bar6-alpha", Settings["ab-bar6-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar6Alpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-bar6-per-row", Settings["ab-bar6-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar[6])
	right:CreateSlider("ab-bar6-button-max", Settings["ab-bar6-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar[6])
	right:CreateSlider("ab-bar6-button-size", Settings["ab-bar6-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar[6])
	right:CreateSlider("ab-bar6-button-gap", Settings["ab-bar6-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar[6])
end)

GUI:AddWidgets(Language["General"], Language["Bar 7"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-bar7-enable", Settings["ab-bar7-enable"], Language["Enable Bar"], Language["Enable action bar 7"], UpdateEnableBar[7])

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-bar7-hover", Settings["ab-bar7-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar7Hover)
	left:CreateSlider("ab-bar7-alpha", Settings["ab-bar7-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar7Alpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-bar7-per-row", Settings["ab-bar7-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar[7])
	right:CreateSlider("ab-bar7-button-max", Settings["ab-bar7-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar[7])
	right:CreateSlider("ab-bar7-button-size", Settings["ab-bar7-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar[7])
	right:CreateSlider("ab-bar7-button-gap", Settings["ab-bar7-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar[7])
end)

GUI:AddWidgets(Language["General"], Language["Bar 8"], Language["Action Bars"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("ab-bar8-enable", Settings["ab-bar8-enable"], Language["Enable Bar"], Language["Enable action bar 8"], UpdateEnableBar[8])

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("ab-bar8-hover", Settings["ab-bar8-hover"], Language["Set Mouseover"], Language["Only display the bar while hovering over it"], UpdateBar8Hover)
	left:CreateSlider("ab-bar8-alpha", Settings["ab-bar8-alpha"], 0, 100, 5, Language["Bar Opacity"], Language["Set the opacity of the action bar"], UpdateBar8Alpha)

	right:CreateHeader(Language["Buttons"])
	right:CreateSlider("ab-bar8-per-row", Settings["ab-bar8-per-row"], 1, 12, 1, Language["Buttons Per Row"], Language["Set the number of buttons per row"], UpdateBar[8])
	right:CreateSlider("ab-bar8-button-max", Settings["ab-bar8-button-max"], 1, 12, 1, Language["Max Buttons"], Language["Set the number of buttons displayed on the action bar"], UpdateBar[8])
	right:CreateSlider("ab-bar8-button-size", Settings["ab-bar8-button-size"], 20, 50, 1, Language["Button Size"], Language["Set the action button size"], UpdateBar[8])
	right:CreateSlider("ab-bar8-button-gap", Settings["ab-bar8-button-gap"], -1, 8, 1, Language["Button Spacing"], Language["Set the spacing between action buttons"], UpdateBar[8])
end)

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
