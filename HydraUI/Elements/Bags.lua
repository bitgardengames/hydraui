local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local Bags = HydraUI:NewModule("Bags")

Defaults["bags-enable"] = true
Defaults["bags-columns"] = 12
Defaults["bags-slot-size"] = 34
Defaults["bags-slot-spacing"] = 4
Defaults["bags-scale"] = 100
Defaults["bags-search"] = true
Defaults["bags-reverse-order"] = false
Defaults["bags-quality-borders"] = true

local Container = C_Container or _G
local GetContainerNumSlots = Container.GetContainerNumSlots
local GetContainerItemInfo = Container.GetContainerItemInfo
local GetContainerItemLink = Container.GetContainerItemLink
local GetContainerItemCooldown = Container.GetContainerItemCooldown
local PickupContainerItem = Container.PickupContainerItem
local SplitContainerItem = Container.SplitContainerItem
local UseContainerItem = Container.UseContainerItem
local SortBags = Container.SortBags
local NUM_BAGS = NUM_BAG_SLOTS or 4

local function GetItemInfo(bag, slot)
	local Info, Count, Locked, Quality, _, _, _, Filtered, _, ItemID, NoValue = GetContainerItemInfo(bag, slot)

	if (type(Info) == "table") then
		return Info.iconFileID, Info.stackCount, Info.isLocked, Info.quality, Info.isFiltered, Info.hasNoValue, Info.itemID
	end

	return Info, Count, Locked, Quality, Filtered, NoValue, ItemID
end

local function SetButtonBorder(button, quality)
	if (Settings["bags-quality-borders"] and quality and quality > 1) then
		local Color = ITEM_QUALITY_COLORS[quality]
		button:SetBackdropBorderColor(Color.r, Color.g, Color.b)
	else
		button:SetBackdropBorderColor(0, 0, 0)
	end
end

local function ButtonOnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetBagItem(self.Bag, self.Slot)
	GameTooltip:Show()
end

local function ButtonOnLeave()
	GameTooltip:Hide()
end

local function ButtonOnClick(self, mouseButton)
	local Link = GetContainerItemLink(self.Bag, self.Slot)

	if (Link and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink(Link)) then
		return
	elseif (Link and HandleModifiedItemClick(Link)) then
		return
	elseif (mouseButton == "LeftButton" and IsModifiedClick("SPLITSTACK") and self.CountValue > 1) then
		OpenStackSplitFrame(self.CountValue, self, "BOTTOMLEFT", "TOPLEFT")
		return
	end

	if (mouseButton == "LeftButton") then
		PickupContainerItem(self.Bag, self.Slot)
	else
		UseContainerItem(self.Bag, self.Slot)
	end
end

local function ButtonOnDrag(self)
	PickupContainerItem(self.Bag, self.Slot)
end

local function ButtonSplitStack(self, amount)
	SplitContainerItem(self.Bag, self.Slot, amount)
end

function Bags:AcquireButton(index)
	local Button = self.Buttons[index]

	if Button then
		return Button
	end

	Button = CreateFrame("Button", "HydraUIBagItem" .. index, self.Frame, "BackdropTemplate")
	Button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	Button:RegisterForDrag("LeftButton")
	Button:SetBackdrop(HydraUI.BackdropAndBorder)
	Button:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
	Button:SetScript("OnEnter", ButtonOnEnter)
	Button:SetScript("OnLeave", ButtonOnLeave)
	Button:SetScript("OnClick", ButtonOnClick)
	Button:SetScript("OnDragStart", ButtonOnDrag)
	Button:SetScript("OnReceiveDrag", ButtonOnDrag)
	Button.SplitStack = ButtonSplitStack

	Button.Icon = Button:CreateTexture(nil, "ARTWORK")
	Button.Icon:SetPoint("TOPLEFT", 2, -2)
	Button.Icon:SetPoint("BOTTOMRIGHT", -2, 2)
	Button.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	Button.Cooldown = CreateFrame("Cooldown", nil, Button, "CooldownFrameTemplate")
	Button.Cooldown:SetAllPoints(Button.Icon)

	Button.Count = Button:CreateFontString(nil, "OVERLAY")
	Button.Count:SetPoint("BOTTOMRIGHT", -2, 2)
	HydraUI:SetFontInfo(Button.Count, Settings["ui-widget-font"], Settings["ui-font-size"], "OUTLINE")

	Button.Junk = Button:CreateTexture(nil, "OVERLAY")
	Button.Junk:SetTexture("Interface\\Buttons\\UI-GroupLoot-Coin-Up")
	Button.Junk:SetSize(14, 14)
	Button.Junk:SetPoint("TOPLEFT", 1, -1)

	Button.Highlight = Button:CreateTexture(nil, "HIGHLIGHT")
	Button.Highlight:SetAllPoints(Button.Icon)
	Button.Highlight:SetColorTexture(1, 1, 1, 0.2)

	self.Buttons[index] = Button

	return Button
end

function Bags:UpdateLayout()
	if (not self.Frame) then
		return
	end

	local Size = Settings["bags-slot-size"]
	local Spacing = Settings["bags-slot-spacing"]
	local Columns = Settings["bags-columns"]
	local Count = #self.Items
	local Rows = math.max(1, math.ceil(Count / Columns))
	local Width = (Columns * Size) + ((Columns - 1) * Spacing) + 16
	local Height = (Rows * Size) + ((Rows - 1) * Spacing) + 58
	local LayoutKey = format("%d:%d:%d:%d:%s", Count, Columns, Size, Spacing, tostring(Settings["bags-reverse-order"]))

	self.Frame:SetScale(Settings["bags-scale"] / 100)

	if (self.LayoutKey == LayoutKey) then
		return
	end

	self.LayoutKey = LayoutKey
	self.Frame:SetSize(Width, Height)

	for i = 1, Count do
		local Button = self.Buttons[i]
		local Position = Settings["bags-reverse-order"] and (Count - i) or (i - 1)
		local Column = Position % Columns
		local Row = math.floor(Position / Columns)

		Button:ClearAllPoints()
		Button:SetSize(Size, Size)
		Button:SetPoint("TOPLEFT", self.Frame, "TOPLEFT", 8 + (Column * (Size + Spacing)), -50 - (Row * (Size + Spacing)))
	end
end

function Bags:Update()
	if (not self.Frame) then
		return
	end

	wipe(self.Items)
	local Free = 0

	for Bag = 0, NUM_BAGS do
		for Slot = 1, GetContainerNumSlots(Bag) do
			self.Items[#self.Items + 1] = { Bag, Slot }
		end
	end

	for i = 1, #self.Items do
		local Button = self:AcquireButton(i)
		local Bag = self.Items[i][1]
		local Slot = self.Items[i][2]
		local Texture, Count, Locked, Quality, Filtered, NoValue = GetItemInfo(Bag, Slot)

		Button.Bag = Bag
		Button.Slot = Slot
		Button.CountValue = Count or 0
		Button.Icon:SetTexture(Texture)
		Button.Icon:SetDesaturated(Locked or false)
		Button:SetAlpha(Filtered and 0.25 or 1)
		Button.Count:SetText((Count and Count > 1) and Count or "")
		Button.Junk:SetShown(Texture and Quality == 0 and not NoValue)
		SetButtonBorder(Button, Quality)

		if (not Texture) then
			Free = Free + 1
		end

		if GetContainerItemCooldown then
			local Start, Duration, Enable = GetContainerItemCooldown(Bag, Slot)
			CooldownFrame_Set(Button.Cooldown, Start or 0, Duration or 0, Enable or 0)
		end

		Button:Show()
	end

	for i = #self.Items + 1, #self.Buttons do
		self.Buttons[i]:Hide()
	end

	self.Title:SetText(format("%s  |cFFFFC44D%d|r/%d", Language["Bags"], Free, #self.Items))
	self:UpdateLayout()
end

function Bags:HideBlizzardBags()
	if ContainerFrameCombinedBags then
		ContainerFrameCombinedBags:Hide()
	end

	for i = 1, (NUM_CONTAINER_FRAMES or 13) do
		local Frame = _G["ContainerFrame" .. i]

		if Frame then
			Frame:Hide()
		end
	end
end

function Bags:Open()
	self:Update()
	self.Frame:Show()
	self:HideBlizzardBags()

	if C_Timer then
		C_Timer.After(0, function() Bags:HideBlizzardBags() end)
	end
end

function Bags:Close()
	self.Frame:Hide()

	if self.Search then
		self.Search:SetText("")
	end
end

function Bags:OnEvent(event)
	if (event == "BAG_OPEN") then
		self:Open()
	elseif (event == "BAG_CLOSED") then
		self:Close()
	elseif self.Frame:IsShown() then
		self:Update()
	end
end

local function SearchChanged(editBox)
	local Text = editBox:GetText() or ""

	if SetItemSearch then
		SetItemSearch(Text)
	elseif C_Container and C_Container.SetItemSearch then
		C_Container.SetItemSearch(Text)
	end

	Bags:Update()
end

function Bags:CreateFrame()
	self.Frame = CreateFrame("Frame", "HydraUIBags", HydraUI.UIParent, "BackdropTemplate")
	self.Frame:SetPoint("RIGHT", UIParent, "RIGHT", -40, 0)
	self.Frame:SetFrameStrata("HIGH")
	self.Frame:SetClampedToScreen(true)
	self.Frame:SetBackdrop(HydraUI.BackdropAndBorder)
	self.Frame:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-main-color"]))
	self.Frame:SetBackdropBorderColor(0, 0, 0)
	self.Frame:EnableMouse(true)
	self.Frame:SetMovable(true)
	self.Frame:Hide()
	HydraUI:CreateMover(self.Frame)
	tinsert(UISpecialFrames, self.Frame:GetName())

	self.Title = self.Frame:CreateFontString(nil, "OVERLAY")
	self.Title:SetPoint("TOPLEFT", 10, -10)
	HydraUI:SetFontInfo(self.Title, Settings["ui-header-font"], Settings["ui-header-font-size"])

	self.CloseButton = CreateFrame("Button", nil, self.Frame)
	self.CloseButton:SetSize(18, 18)
	self.CloseButton:SetPoint("TOPRIGHT", -8, -8)
	self.CloseButton:SetNormalTexture(Assets:GetTexture("Close"))
	self.CloseButton:SetScript("OnClick", function() CloseAllBags() end)

	if Settings["bags-search"] then
		self.Search = CreateFrame("EditBox", nil, self.Frame, "InputBoxTemplate")
		self.Search:SetSize(130, 20)
		self.Search:SetPoint("TOPLEFT", 10, -28)
		self.Search:SetAutoFocus(false)
		self.Search:SetMaxLetters(40)
		self.Search:SetScript("OnTextChanged", SearchChanged)
		self.Search:SetScript("OnEscapePressed", self.Search.ClearFocus)
	end

	self.SortButton = CreateFrame("Button", nil, self.Frame, "BackdropTemplate")
	self.SortButton:SetSize(54, 20)
	self.SortButton:SetPoint("TOPRIGHT", -30, -28)
	self.SortButton:SetBackdrop(HydraUI.BackdropAndBorder)
	self.SortButton:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-button-texture-color"]))
	self.SortButton:SetBackdropBorderColor(0, 0, 0)
	self.SortButton:SetScript("OnClick", function() if SortBags then SortBags() end end)
	self.SortButton.Text = self.SortButton:CreateFontString(nil, "OVERLAY")
	self.SortButton.Text:SetPoint("CENTER")
	self.SortButton.Text:SetText(Language["Sort"])
	HydraUI:SetFontInfo(self.SortButton.Text, Settings["ui-button-font"], Settings["ui-font-size"])
end

function Bags:Load()
	if (not Settings["bags-enable"]) then
		return
	end

	self.Buttons = {}
	self.Items = {}
	self:CreateFrame()
	self:RegisterEvent("BAG_UPDATE_DELAYED")
	self:RegisterEvent("BAG_UPDATE_COOLDOWN")
	self:SetScript("OnEvent", self.OnEvent)

	if OpenAllBags then
		hooksecurefunc("OpenAllBags", function() Bags:Open() end)
	end

	if CloseAllBags then
		hooksecurefunc("CloseAllBags", function() Bags:Close() end)
	end

	if OpenBackpack then
		hooksecurefunc("OpenBackpack", function() Bags:Open() end)
	end

	if CloseBackpack then
		hooksecurefunc("CloseBackpack", function() Bags:Close() end)
	end
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Bags"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("bags-enable", Settings["bags-enable"], Language["Enable Bags"], Language["Use one frame for all carried bags"], ReloadUI):RequiresReload(true)
	left:CreateSwitch("bags-search", Settings["bags-search"], Language["Show Search"], Language["Show the item search box"], ReloadUI):RequiresReload(true)
	left:CreateSwitch("bags-reverse-order", Settings["bags-reverse-order"], Language["Reverse Slot Order"], Language["Fill bag slots from the bottom right"], ReloadUI):RequiresReload(true)
	left:CreateSwitch("bags-quality-borders", Settings["bags-quality-borders"], Language["Quality Borders"], Language["Color item borders by quality"], ReloadUI):RequiresReload(true)

	right:CreateHeader(Language["Layout"])
	right:CreateSlider("bags-columns", Settings["bags-columns"], 6, 20, 1, Language["Columns"], Language["Set the number of bag columns"], ReloadUI):RequiresReload(true)
	right:CreateSlider("bags-slot-size", Settings["bags-slot-size"], 24, 48, 1, Language["Slot Size"], Language["Set the size of bag slots"], ReloadUI):RequiresReload(true)
	right:CreateSlider("bags-slot-spacing", Settings["bags-slot-spacing"], 1, 10, 1, Language["Slot Spacing"], Language["Set the space between bag slots"], ReloadUI):RequiresReload(true)
	right:CreateSlider("bags-scale", Settings["bags-scale"], 60, 140, 5, Language["Scale"], Language["Set the scale of the bag frame"], ReloadUI, nil, "%"):RequiresReload(true)
end)
