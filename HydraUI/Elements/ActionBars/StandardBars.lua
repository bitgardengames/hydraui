local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()
local AB = HydraUI:GetModule("Action Bars")

-- The descriptor table is allocated once; settings callbacks close over these
-- entries instead of rebuilding bar metadata every time a setting changes.
local ActionBarDescriptors = {
	{ index = 1, field = "Bar1", parent = nil, prefix = "ActionButton", anchor = { "BOTTOM", "UIParent", "BOTTOM", 0, 13 }, available = function() return ActionButton1 ~= nil end, securePaging = true },
	{ index = 2, field = "Bar2", parent = "MultiBarBottomLeft", prefix = "MultiBarBottomLeftButton", anchor = { "BOTTOM", "Bar1", "TOP", 0, "gap" }, available = function() return MultiBarBottomLeft ~= nil end },
	{ index = 3, field = "Bar3", parent = "MultiBarBottomRight", prefix = "MultiBarBottomRightButton", anchor = { "BOTTOM", "Bar2", "TOP", 0, "gap" }, available = function() return MultiBarBottomRight ~= nil end },
	{ index = 4, field = "Bar4", parent = "MultiBarRight", prefix = "MultiBarRightButton", anchor = { "RIGHT", "UIParent", "RIGHT", -12, 0 }, available = function() return MultiBarRight ~= nil end },
	{ index = 5, field = "Bar5", parent = "MultiBarLeft", prefix = "MultiBarLeftButton", anchor = { "RIGHT", "Bar4", "LEFT", "negativeGap", 0 }, available = function() return MultiBarLeft ~= nil end },
	{ index = 6, field = "Bar6", parent = "MultiBar5", prefix = "MultiBar5Button", anchor = { "RIGHT", "Bar5", "LEFT", "negativeGap", 0 }, available = function() return MultiBar5 ~= nil end },
	{ index = 7, field = "Bar7", parent = "MultiBar6", prefix = "MultiBar6Button", anchor = { "RIGHT", "Bar6", "LEFT", "negativeGap", 0 }, available = function() return MultiBar6 ~= nil end },
	{ index = 8, field = "Bar8", parent = "MultiBar7", prefix = "MultiBar7Button", anchor = { "RIGHT", "Bar7", "LEFT", "negativeGap", 0 }, available = function() return MultiBar7 ~= nil end },
}

AB.ActionBarDescriptors = ActionBarDescriptors

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
		button:HookScript("OnEnter", AB.BarButtonOnEnter)
		button:HookScript("OnLeave", AB.BarButtonOnLeave)
		bar[i] = button
	end

	if Settings[key .. "-hover"] then
		bar:SetAlpha(0)
		bar:SetScript("OnEnter", AB.BarOnEnter)
		bar:SetScript("OnLeave", AB.BarOnLeave)
		for i = 1, #bar do
			bar[i].cooldown:SetDrawBling(false)
		end
	end

	self:PositionButtons(bar, Settings[key .. "-button-max"], Settings[key .. "-per-row"], Settings[key .. "-button-size"], gap)
	if Settings[key .. "-enable"] then self:EnableBar(bar) else self:DisableBar(bar) end
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
			if GetOverrideBarIndex and HasOverrideActionBar() then newstate = GetOverrideBarIndex() or newstate
			elseif HasTempShapeshiftActionBar() then newstate = GetTempShapeshiftBarIndex() or newstate
			elseif HasBonusActionBar() and GetActionBarPage() == 1 then newstate = GetBonusBarIndex() or newstate
			else newstate = GetActionBarPage() or newstate end
			for i = 1, 12 do Buttons[i]:SetAttribute("actionpage", newstate) end
		]])
		RegisterAttributeDriver(bar, "state-page", "[overridebar] 14; [shapeshift] 13; [possessbar] 16; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; [bonusbar:5] 11; [form] 1; 1")
	else
		bar:SetAttribute("_onstate-page", [[
			if GetVehicleBarIndex and HasVehicleActionBar() then newstate = GetVehicleBarIndex()
			elseif HasOverrideActionBar and HasOverrideActionBar() then newstate = GetOverrideBarIndex()
			elseif HasTempShapeshiftActionBar() then newstate = GetTempShapeshiftBarIndex()
			elseif HasBonusActionBar() then newstate = GetBonusBarIndex() end
			for i = 1, 12 do Buttons[i]:SetAttribute("actionpage", newstate) end
		]])
		RegisterAttributeDriver(bar, "state-page", "[overridebar] 14; [shapeshift] 13; [possessbar] 16; [vehicleui] 12; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; [bonusbar:5] 11; [form] 1; 1")
	end

	if OverrideActionBar then self:Disable(OverrideActionBar) end
end

function AB:CreateBars()
	self.Bars = {}
	for _, descriptor in ipairs(ActionBarDescriptors) do
		local bar = self:CreateActionBar(descriptor)
		if bar and descriptor.securePaging then
			self:ConfigureBar1Paging(bar)
		end
	end

end

function AB:ShowActionBars()
	-- SetActionBarToggles is a legacy wrapper which only knew about the
	-- original four multi-bars. Set the current CVars directly so bars added
	-- through Edit Mode are enabled as well.
	for i = 1, 7 do
		C_CVar.SetCVar("showMultiActionBar" .. i, "1")
	end
end

local Standard = {}
function Standard:IsAvailable() return ActionButton1 ~= nil end
function Standard:Load()
	AB:ShowActionBars()
	AB:CreateBars()
	if ActionButton_UpdateRangeIndicator then
		hooksecurefunc("ActionButton_UpdateRangeIndicator", AB.UpdateButtonStatus)
	end
	if ActionButton_Update then
		hooksecurefunc("ActionButton_Update", AB.UpdateButtonStatus)
	end
end
AB:RegisterSubsystem(Standard)
