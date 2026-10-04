local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local AB = HydraUI:NewModule("Action Bars")
local NumPad = KEY_NUMPAD1:gsub("%s%S$", "")
local WheelUp = KEY_MOUSEWHEELUP
local WheelDown = KEY_MOUSEWHEELDOWN
local MouseButton = KEY_BUTTON4:gsub("%s%S$", "")
local MiddleButton = KEY_BUTTON3

-- The descriptor table is the single source of truth for standard action bars.
-- Optional bars report their availability so creation and configuration can skip them.
local ActionBarDescriptors = {
	{ index = 1, field = "Bar1", label = "Bar 1", parent = nil, prefix = "ActionButton", anchor = { "BOTTOM", "UIParent", "BOTTOM", 0, 13 }, defaultPerRow = 12, hasButtonMax = true, available = function() return ActionButton1 ~= nil end, securePaging = true },
	{ index = 2, field = "Bar2", label = "Bar 2", parent = "MultiBarBottomLeft", prefix = "MultiBarBottomLeftButton", anchor = { "BOTTOM", "Bar1", "TOP", 0, "gap" }, defaultPerRow = 12, hasButtonMax = true, available = function() return MultiBarBottomLeft ~= nil end },
	{ index = 3, field = "Bar3", label = "Bar 3", parent = "MultiBarBottomRight", prefix = "MultiBarBottomRightButton", anchor = { "BOTTOM", "Bar2", "TOP", 0, "gap" }, defaultPerRow = 12, hasButtonMax = true, available = function() return MultiBarBottomRight ~= nil end },
	{ index = 4, field = "Bar4", label = "Bar 4", parent = "MultiBarRight", prefix = "MultiBarRightButton", anchor = { "RIGHT", "UIParent", "RIGHT", -12, 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBarRight ~= nil end },
	{ index = 5, field = "Bar5", label = "Bar 5", parent = "MultiBarLeft", prefix = "MultiBarLeftButton", anchor = { "RIGHT", "Bar4", "LEFT", "negativeGap", 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBarLeft ~= nil end },
	{ index = 6, field = "Bar6", label = "Bar 6", parent = "MultiBar5", prefix = "MultiBar5Button", anchor = { "RIGHT", "Bar5", "LEFT", "negativeGap", 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBar5 ~= nil end },
	{ index = 7, field = "Bar7", label = "Bar 7", parent = "MultiBar6", prefix = "MultiBar6Button", anchor = { "RIGHT", "Bar6", "LEFT", "negativeGap", 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBar6 ~= nil end },
	{ index = 8, field = "Bar8", label = "Bar 8", parent = "MultiBar7", prefix = "MultiBar7Button", anchor = { "RIGHT", "Bar7", "LEFT", "negativeGap", 0 }, defaultPerRow = 1, hasButtonMax = true, available = function() return MultiBar7 ~= nil end },
}

AB.ActionBarDescriptors = ActionBarDescriptors

-- Defaults
Defaults["ab-enable"] = true

Defaults["ab-show-hotkey"] = true
Defaults["ab-show-count"] = true
Defaults["ab-show-macro"] = true

Defaults["ab-font"] = "PT Sans"
Defaults["ab-font-size"] = 12
Defaults["ab-cd-size"] = 18
Defaults["ab-font-flags"] = ""

for _, descriptor in ipairs(ActionBarDescriptors) do
	local key = "ab-bar" .. descriptor.index
	Defaults[key .. "-enable"] = true
	Defaults[key .. "-hover"] = false
	Defaults[key .. "-button-size"] = 32
	Defaults[key .. "-button-gap"] = 2
	Defaults[key .. "-per-row"] = descriptor.defaultPerRow
	Defaults[key .. "-alpha"] = 100

	if descriptor.hasButtonMax then
		Defaults[key .. "-button-max"] = 12
	end
end

Defaults["ab-pet-enable"] = true
Defaults["ab-pet-hover"] = false
Defaults["ab-pet-button-size"] = 32
Defaults["ab-pet-button-gap"] = 2
Defaults["ab-pet-per-row"] = 1
Defaults["ab-pet-alpha"] = 100

Defaults["ab-stance-enable"] = true
Defaults["ab-stance-hover"] = false
Defaults["ab-stance-button-size"] = 32
Defaults["ab-stance-button-gap"] = 2
Defaults["ab-stance-per-row"] = 12
Defaults["ab-stance-alpha"] = 100

Defaults["ab-totem-enable"] = true
Defaults["ab-extra-button-size"] = 60

function AB:Disable(object)
	if not object then
		return
	end

	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
	end

	object:SetParent(self.Hide)
end

function AB:EnableBar(bar)
	if not bar then
		return
	end

	RegisterAttributeDriver(bar, "state-visibility", "[nopetbattle] show; hide")
	bar:Show()
end

function AB:DisableBar(bar)
	if not bar then
		return
	end

	UnregisterAttributeDriver(bar, "state-visibility")
	bar:Hide()
end

function AB:UpdateHotKeyText()
	local Text = self.HotKey:GetText()

	if Text then
		Text = Text:gsub(NumPad, "N")
		Text = Text:gsub(WheelUp, "MWU")
		Text = Text:gsub(WheelDown, "MWD")
		Text = Text:gsub(MouseButton, "MB")
		Text = Text:gsub(MiddleButton, "MMB")
		Text = Text:gsub(CTRL_KEY_TEXT, "c")
		Text = Text:gsub(SHIFT_KEY_TEXT, "s")
		Text = Text:gsub(ALT_KEY_TEXT, "a")

		self.HotKey:SetText("|cFFFFFFFF" .. Text .. "|r")
	end
end

function AB:PositionButtons(bar, numbuttons, perrow, size, spacing)
	if numbuttons < perrow then
		perrow = numbuttons
	end

	local Columns = ceil(numbuttons / perrow)

	if Columns < 1 then
		Columns = 1
	end

	-- Bar sizing
	bar:SetWidth((size * perrow) + (spacing * (perrow - 1)))
	bar:SetHeight((size * Columns) + (spacing * (Columns - 1)))

	-- Actual moving
	for i = 1, #bar do
		local Button = bar[i]

		Button:ClearAllPoints()
		Button:SetSize(size, size)

		if i == 1 then
			Button:SetPoint("TOPLEFT", bar, 0, 0)
		elseif (i - 1) % perrow == 0 then
			Button:SetPoint("TOP", bar[i - perrow], "BOTTOM", 0, -spacing)
		else
			Button:SetPoint("LEFT", bar[i - 1], "RIGHT", spacing, 0)
		end

		if i > numbuttons then
			Button:SetParent(self.Hide)
		else
			Button:SetParent(bar.ButtonParent or bar)
		end
	end
end

function AB:Load()
	if not Settings["ab-enable"] then
		return
	end

	self.Hide = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
	self.Hide:Hide()

	self:ShowActionBars()
	self:Disable(MainMenuBar)
	self:CreateBars()
	self:CreateMovers()

	if MainActionBar then
		MainActionBar:SetAlpha(0)
		MainActionBar:EnableMouse(false)
	end

	hooksecurefunc("ActionButton_UpdateRangeIndicator", AB.UpdateButtonStatus)

	if ActionButton_UpdateFlyout then
		hooksecurefunc("ActionButton_UpdateFlyout", AB.UpdateFlyout)
	end

	if ActionButton_Update then
		hooksecurefunc("ActionButton_Update", AB.UpdateButtonStatus)
	end
end
