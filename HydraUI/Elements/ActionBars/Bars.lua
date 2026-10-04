local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local AB = HydraUI:GetModule("Action Bars")
local GUI = HydraUI:GetModule("GUI")

local NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS
local ActionBarDescriptors = AB.ActionBarDescriptors

local BarButtonOnEnter = function(self)
	if self.ParentBar.Fader:IsPlaying() then
		self.ParentBar.Fader:Stop()
	end

	for i = 1, #self.ParentBar do
		self.ParentBar[i].cooldown:SetDrawBling(true)
	end

	self.ParentBar.Fader:SetChange(self.ParentBar.MaxAlpha / 100)
	self.ParentBar.Fader:Play()
end

local BarButtonOnLeave = function(self)
	if self.ParentBar.Fader:IsPlaying() then
		self.ParentBar.Fader:Stop()
	end

	for i = 1, #self.ParentBar do
		self.ParentBar[i].cooldown:SetDrawBling(false)
	end

	self.ParentBar.Fader:SetChange(self.ParentBar.ShouldFade and 0 or (self.ParentBar.MaxAlpha / 100))
	self.ParentBar.Fader:Play()
end

local BarOnEnter = function(self)
	if self.Fader:IsPlaying() then
		self.Fader:Stop()
	end

	for i = 1, #self do
		self[i].cooldown:SetDrawBling(true)
	end

	self.Fader:SetChange(self.MaxAlpha / 100)
	self.Fader:Play()
end

local BarOnLeave = function(self)
	if self.Fader:IsPlaying() then
		self.Fader:Stop()
	end

	for i = 1, #self do
		self[i].cooldown:SetDrawBling(false)
	end

	self.Fader:SetChange(self.ShouldFade and 0 or (self.MaxAlpha / 100))
	self.Fader:Play()
end

AB.BarOnEnter = BarOnEnter
AB.BarOnLeave = BarOnLeave

local function ResolveAnchorValue(owner, value, gap)
	if value == "UIParent" then
		return HydraUI.UIParent
	elseif value == "gap" then
		return gap
	elseif value == "negativeGap" then
		return -gap
	elseif type(value) == "string" then
		return owner[value]
	end

	return value
end

function AB:CreateActionBar(descriptor)
	if not descriptor.available() then
		return
	end

	local index = descriptor.index
	local key = "ab-bar" .. index
	local anchor = descriptor.anchor
	local gap = Settings[key .. "-button-gap"]
	local bar = CreateFrame("Frame", "HydraUI Action Bar " .. index, HydraUI.UIParent, "SecureHandlerStateTemplate")
	self[descriptor.field] = bar
	self.Bars[#self.Bars + 1] = bar
	bar.Descriptor = descriptor
	bar:SetPoint(anchor[1], ResolveAnchorValue(self, anchor[2], gap), anchor[3], ResolveAnchorValue(self, anchor[4], gap), ResolveAnchorValue(self, anchor[5], gap))
	bar:SetAlpha(Settings[key .. "-alpha"] / 100)
	bar.ShouldFade = Settings[key .. "-hover"]
	bar.MaxAlpha = Settings[key .. "-alpha"]

	local blizzardParent = descriptor.parent and _G[descriptor.parent]
	bar.ButtonParent = blizzardParent
	if blizzardParent then
		blizzardParent:SetParent(bar)
	end

	bar.Fader = LibMotion:CreateAnimation(bar, "Fade")
	bar.Fader:SetDuration(0.15)
	bar.Fader:SetEasing("inout")

	for i = 1, 12 do
		local button = _G[descriptor.prefix .. i]
		self:StyleActionButton(button)
		if descriptor.securePaging then
			button:SetParent(bar)
			bar:SetFrameRef("Button" .. i, button)
		end
		button.ParentBar = bar
		button:HookScript("OnEnter", BarButtonOnEnter)
		button:HookScript("OnLeave", BarButtonOnLeave)
		bar[i] = button
	end

	if Settings[key .. "-hover"] then
		bar:SetAlpha(0)
		bar:SetScript("OnEnter", BarOnEnter)
		bar:SetScript("OnLeave", BarOnLeave)
		for i = 1, #bar do
			bar[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(bar, Settings[key .. "-button-max"], Settings[key .. "-per-row"], Settings[key .. "-button-size"], gap)
	if Settings[key .. "-enable"] then
		self:EnableBar(bar)
	else
		self:DisableBar(bar)
	end
	return bar
end

function AB:ConfigureBar1Paging(bar)
	bar.GetSpellFlyoutDirection = function() return "UP" end -- Temp
	bar:Execute([[
		Buttons = table.new()
		for i = 1, 12 do
			table.insert(Buttons, self:GetFrameRef("Button" .. i))
		end
	]])

	if HydraUI.IsVanilla then
		bar:SetAttribute("_onstate-page", [[
			if GetOverrideBarIndex and HasOverrideActionBar() then
				newstate = GetOverrideBarIndex() or newstate
			elseif HasTempShapeshiftActionBar() then
				newstate = GetTempShapeshiftBarIndex() or newstate
			elseif HasBonusActionBar() and GetActionBarPage() == 1 then
				newstate = GetBonusBarIndex() or newstate
			else
				newstate = GetActionBarPage() or newstate
			end
			for i = 1, 12 do
				Buttons[i]:SetAttribute("actionpage", newstate)
			end
		]])
		RegisterAttributeDriver(bar, "state-page", "[overridebar] 14; [shapeshift] 13; [possessbar] 16; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; [bonusbar:5] 11; [form] 1; 1")
	else
		bar:SetAttribute("_onstate-page", [[
			if GetVehicleBarIndex and HasVehicleActionBar() then
				newstate = GetVehicleBarIndex()
			elseif HasOverrideActionBar and HasOverrideActionBar() then
				newstate = GetOverrideBarIndex()
			elseif HasTempShapeshiftActionBar() then
				newstate = GetTempShapeshiftBarIndex()
			elseif HasBonusActionBar() then
				newstate = GetBonusBarIndex()
			end
			for i = 1, 12 do
				Buttons[i]:SetAttribute("actionpage", newstate)
			end
		]])
		RegisterAttributeDriver(bar, "state-page", "[overridebar] 14; [shapeshift] 13; [possessbar] 16; [vehicleui] 12; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; [bonusbar:5] 11; [form] 1; 1")
	end

	if OverrideActionBar then
		self:Disable(OverrideActionBar)
	end
end

local PetBarUpdateGridLayout = function()
	if not AB.PetBar:IsShown() or InCombatLockdown() then
		return
	end

	AB:PositionButtons(AB.PetBar, NUM_PET_ACTION_SLOTS, Settings["ab-pet-per-row"], Settings["ab-pet-button-size"], Settings["ab-pet-button-gap"])
end

-- Pet
function AB:CreatePetBar()
	self.PetBar = CreateFrame("Frame", "HydraUI Pet Bar", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.PetBar:SetPoint("RIGHT", self.Bar5, "LEFT", -Settings["ab-pet-button-gap"], 0)
	self.PetBar:SetAlpha(Settings["ab-pet-alpha"] / 100)
	self.PetBar.ButtonParent = PetActionBar or PetActionBarFrame
	self.PetBar.ShouldFade = Settings["ab-pet-hover"]
	self.PetBar.MaxAlpha = Settings["ab-pet-alpha"]

	self.PetBar.Fader = LibMotion:CreateAnimation(self.PetBar, "Fade")
	self.PetBar.Fader:SetDuration(0.15)
	self.PetBar.Fader:SetEasing("inout")

	if PetActionBar then
		PetActionBar:SetParent(self.PetBar)
		PetActionBar:SetAllPoints(self.PetBar)
		PetActionBar:EnableMouse(false)

		hooksecurefunc(PetActionBar, "UpdateGridLayout", PetBarUpdateGridLayout)
	else
		PetActionBarFrame:SetParent(self.PetBar)

		for i = 1, PetActionBarFrame:GetNumRegions() do
			local Region = select(i, PetActionBarFrame:GetRegions())

			if Region.SetTexture then
				Region:SetTexture(nil)
			end
		end
	end

	for i = 1, NUM_PET_ACTION_SLOTS do
		local Button = _G["PetActionButton" .. i]

		self:StylePetActionButton(Button)

		Button.ParentBar = self.PetBar

		Button:HookScript("OnEnter", BarButtonOnEnter)
		Button:HookScript("OnLeave", BarButtonOnLeave)

		self.PetBar[i] = Button
	end

	if Settings["ab-pet-hover"] then
		self.PetBar:SetAlpha(0)
		self.PetBar:SetScript("OnEnter", BarOnEnter)
		self.PetBar:SetScript("OnLeave", BarOnLeave)

		for i = 1, #self.PetBar do
			self.PetBar[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(self.PetBar, NUM_PET_ACTION_SLOTS, Settings["ab-pet-per-row"], Settings["ab-pet-button-size"], Settings["ab-pet-button-gap"])

	if PetActionBar_Update then
		hooksecurefunc("PetActionBar_Update", AB.PetActionBar_Update)
	end

	if Settings["ab-pet-enable"] then
		self:EnableBar(self.PetBar)
	else
		self:DisableBar(self.PetBar)
	end
end

-- Stance
local StanceBarUpdateGridLayout = function()
	if InCombatLockdown() then
		return
	end

	AB:PositionButtons(AB.StanceBar, #AB.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])
end

function AB:CreateStanceBar()
	self.StanceBar = CreateFrame("Frame", "HydraUI Stance Bar", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.StanceBar:SetPoint("TOPLEFT", HydraUI.UIParent, 10, -10)
	self.StanceBar:SetAlpha(Settings["ab-stance-alpha"] / 100)
	self.StanceBar.ButtonParent = StanceBar or StanceBarFrame
	self.StanceBar.ShouldFade = Settings["ab-stance-hover"]
	self.StanceBar.MaxAlpha = Settings["ab-stance-alpha"]

	self.StanceBar.Fader = LibMotion:CreateAnimation(self.StanceBar, "Fade")
	self.StanceBar.Fader:SetDuration(0.15)
	self.StanceBar.Fader:SetEasing("inout")

	if StanceBar then
		StanceBar:SetParent(self.StanceBar)
	else
		StanceBarFrame:SetParent(self.StanceBar)
	end

	if StanceBar then
		if StanceBar.UpdateGridLayout then
			hooksecurefunc(StanceBar, "UpdateGridLayout", StanceBarUpdateGridLayout)
		end

		for i, button in next, StanceBar.actionButtons do
			self:StyleActionButton(button)

			button.ParentBar = self.StanceBar

			button:HookScript("OnEnter", BarButtonOnEnter)
			button:HookScript("OnLeave", BarButtonOnLeave)

			self.StanceBar[i] = button
		end

		self:PositionButtons(self.StanceBar, #self.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])

		--hooksecurefunc("StanceBar_UpdateState", self.StanceBar_UpdateState)

		if Settings["ab-stance-hover"] then
			self.StanceBar:SetAlpha(0)
			self.StanceBar:SetScript("OnEnter", BarOnEnter)
			self.StanceBar:SetScript("OnLeave", BarOnLeave)

			for i = 1, #self.StanceBar do
				self.StanceBar[i].cooldown:SetDrawBling(false)
			end
		end
	end

	if StanceBarFrame and StanceBarFrame.StanceButtons then
		StanceBarLeft:SetAlpha(0)
		StanceBarRight:SetAlpha(0)

		for i = 1, NUM_STANCE_SLOTS do
			local Button = StanceBarFrame.StanceButtons[i]

			self:StyleActionButton(Button)

			Button.ParentBar = self.StanceBar

			Button:HookScript("OnEnter", BarButtonOnEnter)
			Button:HookScript("OnLeave", BarButtonOnLeave)

			self.StanceBar[i] = Button
		end

		self:PositionButtons(self.StanceBar, #self.StanceBar, Settings["ab-stance-per-row"], Settings["ab-stance-button-size"], Settings["ab-stance-button-gap"])

		hooksecurefunc("StanceBar_UpdateState", self.StanceBar_UpdateState)

		if Settings["ab-stance-hover"] then
			self.StanceBar:SetAlpha(0)
			self.StanceBar:SetScript("OnEnter", BarOnEnter)
			self.StanceBar:SetScript("OnLeave", BarOnLeave)

			for i = 1, #self.StanceBar do
				self.StanceBar[i].cooldown:SetDrawBling(false)
			end
		end
	end

	if Settings["ab-stance-enable"] then
		self:EnableBar(self.StanceBar)
	else
		self:DisableBar(self.StanceBar)
	end
end

local UpdateZoneAbilityPosition = function(self, anchor, parent)
	--if (not InCombatLockdown()) and (parent and parent ~= AB.ExtraBar) then
	if parent and parent ~= AB.ExtraBar then
		self:ClearAllPoints()
		self:SetPoint("CENTER", AB.ExtraBar)
	end
end

local SkinZoneAbilityButtons = function()
	for Button in ZoneAbilityFrame.SpellButtonContainer:EnumerateActive() do
		if not Button.Styled then
			Button.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			Button.NormalTexture:SetAlpha(0)

			Button.Backdrop = CreateFrame("Frame", nil, Button, "BackdropTemplate")
			Button.Backdrop:SetPoint("TOPLEFT", Button, -1, 1)
			Button.Backdrop:SetPoint("BOTTOMRIGHT", Button, 1, -1)
			Button.Backdrop:SetBackdrop(HydraUI.Backdrop)
			Button.Backdrop:SetBackdropColor(0, 0, 0)
			Button.Backdrop:SetFrameLevel(Button:GetFrameLevel() - 1)

			Button.Styled = true
		end
	end
end

local UpdateExtraActionParent = function(self, parent)
	if InCombatLockdown() then
		AB.NeedsCombatFix = true

		AB:RegisterEvent("PLAYER_REGEN_ENABLED")
		AB:SetScript("OnEvent", AB.OnEvent)

		return
	end

	if parent and parent ~= AB.ExtraBar then
		self:SetParent(AB.ExtraBar)
	end
end

-- Extra Bar
function AB:CreateExtraBar()
	self.ExtraBar = CreateFrame("Frame", "HydraUI Extra Action", HydraUI.UIParent, "SecureHandlerStateTemplate")
	self.ExtraBar:SetSize(Settings["ab-extra-button-size"], Settings["ab-extra-button-size"])
	self.ExtraBar:SetPoint("CENTER", HydraUI.UIParent, 0, -220)

	ExtraActionBarFrame:SetParent(HydraUIParent)
	ExtraActionBarFrame:ClearAllPoints()
	ExtraActionBarFrame:SetAllPoints(self.ExtraBar)
	ExtraActionButton1.style:SetAlpha(0)
	ExtraActionBarFrame.ignoreInLayout = true

	--hooksecurefunc(ExtraActionBarFrame, "SetPoint", UpdateExtraActionPosition)
	hooksecurefunc(ExtraActionBarFrame, "SetParent", UpdateExtraActionParent)

	self:StyleActionButton(ExtraActionButton1)

	if HydraUI.IsMists then
		--ExtraActionButton1:SetParent(ExtraActionBarFrame)
		ExtraActionButton1:ClearAllPoints()
		ExtraActionButton1:SetPoint("CENTER", ExtraActionBarFrame)
	end

	if ZoneAbilityFrame then
		ZoneAbilityFrame:ClearAllPoints()
		ZoneAbilityFrame:SetPoint("CENTER", self.ExtraBar)
		ZoneAbilityFrame.Style:SetAlpha(0)
		--ZoneAbilityFrame.ignoreInLayout = true

		hooksecurefunc(ZoneAbilityFrame, "SetPoint", UpdateZoneAbilityPosition)
		hooksecurefunc(ZoneAbilityFrame, "UpdateDisplayedZoneAbilities", SkinZoneAbilityButtons)
	end
end

function AB:OnEvent(event, ...)
	if self[event] then
		self[event](self, ...)
	end
end

function AB:PLAYER_REGEN_ENABLED()
	if self.NeedsCombatFix then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:SetScript("OnEvent", nil)

		ExtraActionBarFrame:SetParent(AB.ExtraBar)

		self.NeedsCombatFix = nil
	end
end

function AB:CreateBars()
	self.Bars = {}
	for _, descriptor in ipairs(ActionBarDescriptors) do
		local bar = self:CreateActionBar(descriptor)
		if bar and descriptor.securePaging then
			self:ConfigureBar1Paging(bar)
		end
	end

	if PetActionBar or PetActionBarFrame then
		self:CreatePetBar()
	end
	if StanceBar or StanceBarFrame then
		self:CreateStanceBar()
	end
	if ExtraActionButton1 then
		self:CreateExtraBar()
	end
	if MultiCastActionBarFrame and MultiCastActionBarFrame.numActiveSlots and MultiCastActionBarFrame.numActiveSlots > 0 then
		self:StyleTotemBar()
	end
end

-- Black magic, the movers won't budge if a secure frame is positioned on it
local Bar1PreMove = function(self)
	local A1, P, A2, X, Y = self:GetPoint()

	AB.Bar1:Hide()
	AB.Bar1:ClearAllPoints() -- Clear the bar from the mover
	AB.Bar1:SetPoint(A1, HydraUI.UIParent, A2, X, Y)
end

local Bar1PostMove = function(self)
	local A1, P, A2, X, Y = self:GetPoint()

	self:ClearAllPoints()

	AB.Bar1:ClearAllPoints()
	AB.Bar1:SetPoint("CENTER", self, 0, 0) -- Position the frame to the mover again
	AB.Bar1:Show()

	self:SetPoint(A1, HydraUI.UIParent, A2, X, Y)
end

function AB:CreateMovers()
	for _, bar in ipairs(self.Bars) do
		local mover = HydraUI:CreateMover(bar)
		if bar == self.Bar1 then
			self.Bar1Mover = mover
		end
	end

	if self.StanceBar then
		HydraUI:CreateMover(self.StanceBar)
	end

	if self.PetBar then
		HydraUI:CreateMover(self.PetBar)
	end

	if self.TotemBar then
		HydraUI:CreateMover(self.TotemBar)
	end

	if HydraUI.IsMists then -- Temporarily disabling the mover on Mists, causing issues
	--if ExtraActionButton1 then
		self.ExtraBarMover = HydraUI:CreateMover(self.ExtraBar)
	end

	self.Bar1Mover.PreMove = Bar1PreMove
	self.Bar1Mover.PostMove = Bar1PostMove
end

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
