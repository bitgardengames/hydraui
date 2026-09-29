local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local Cooldowns = HydraUI:NewModule("Cooldowns")

-- Default settings values
Defaults["cooldowns-enable"] = true
Defaults["cooldowns-size"] = 60
Defaults["cooldowns-hold"] = 1.4
Defaults["cooldowns-text"] = false

local GetItemCooldown = GetItemCooldown
local GetSpellCooldown = GetSpellCooldown
local GetSpellTexture = GetSpellTexture
local GetItemInfo = GetItemInfo
local GetTime = GetTime

local ActiveCount = 0
local MinTreshold = 14
local ActiveSpells = {}
local ActiveItems = {}
local ItemTables = {}
local Spells = {}
local ContainerItemID
local CooldownTimer
local CooldownDeadline

if C_Container then
	ContainerItemID = C_Container.GetContainerItemID
	GetItemCooldown = C_Container.GetItemCooldown
else
	ContainerItemID = GetContainerItemID
end

local GetSpellCooldown = C_Spell and C_Spell.GetSpellCooldown or GetSpellCooldown

local function GetSpellCooldownValues(id)
	local Start, Duration = GetSpellCooldown(id)

	if (type(Start) == "table") then
		return Start.startTime, Start.duration
	end

	return Start, Duration
end

Cooldowns.Blacklist = {
	item = {
		[6948] = true, -- Hearthstone
		[140192] = true, -- Dalaran Hearthstone
		[110560] = true, -- Garrison Hearthstone
	},

	player = {
		[125439] = true, -- Revive Battle Pets
	},
}

Cooldowns.TextureFilter = {
	[136235] = true
}

function Cooldowns:GetTexture(cd, id)
	local Texture

	if (cd == "item") then
		Texture = select(10, GetItemInfo(id))
	else
		Texture = GetSpellTexture(id)
	end

	if (not self.TextureFilter[Texture]) then
		return Texture
	end
end

function Cooldowns:ShowReady(kind, id)
	local Texture = self:GetTexture(kind, id)

	if Texture then
		if self.AnimIn:IsPlaying() then
			self.AnimIn:Stop()
		end

		self.Icon:SetTexture(Texture)
		self.AnimIn:Play()

		if Settings["cooldowns-text"] then
			local Name

			if (kind == "item") then
				Name = GetItemInfo(id)
			else
				Name = GetSpellInfo(id)
			end

			if Name then
				self.Text:SetText(format(Language["|cff%s%s|r is ready!"], Settings["ui-widget-color"], Name))
			end
		else
			self.Text:SetText("")
		end
	end
end

local function ReleaseRecord(records, id)
	local Record = records[id]

	if Record then
		records[id] = nil
		ActiveCount = ActiveCount - 1

		if (Record.Kind == "item") then
			Record.ID = nil
			Record.Deadline = nil
			ItemTables[#ItemTables + 1] = Record
		end
	end
end

local function GetCooldown(kind, id)
	if (kind == "item") then
		return GetItemCooldown(id)
	end

	return GetSpellCooldownValues(id)
end

local function IsTrackedCooldown(kind, duration)
	return duration and (duration > MinTreshold or (kind == "spell" and duration == MinTreshold))
end

local function FindEarliestDeadline(records, deadline)
	for _, Record in pairs(records) do
		if (Record.Deadline and (not deadline or Record.Deadline < deadline)) then
			deadline = Record.Deadline
		end
	end

	return deadline
end

function Cooldowns:ScheduleNext()
	local Deadline = FindEarliestDeadline(ActiveSpells)
	Deadline = FindEarliestDeadline(ActiveItems, Deadline)

	if (Deadline == CooldownDeadline) then
		return
	end

	if CooldownTimer then
		CooldownTimer:Cancel()
		CooldownTimer = nil
	end

	CooldownDeadline = Deadline

	if Deadline then
		CooldownTimer = C_Timer.NewTimer(math.max(0, Deadline - GetTime()), function()
			CooldownTimer = nil
			CooldownDeadline = nil
			Cooldowns:OnUpdate()
		end)
	end
end

local function UpdateRecord(records, kind, id, start, duration)
	local Record = records[id]

	if (start and IsTrackedCooldown(kind, duration)) then
		if not Record then
			Record = (kind == "item" and table.remove(ItemTables, #ItemTables)) or {}
			Record.ID = id
			Record.Kind = kind
			records[id] = Record
			ActiveCount = ActiveCount + 1
		end

		Record.Deadline = start + duration
	elseif Record then
		-- An update before the known deadline is a cancellation, not completion.
		if (Record.Deadline <= GetTime()) then
			Cooldowns:ShowReady(kind, id)
		end

		ReleaseRecord(records, id)
	end
end

local function UpdateExpiredRecords(records, kind, now)
	for ID, Record in pairs(records) do
		if (Record.Deadline <= now) then
			local Start, Duration = GetCooldown(kind, ID)

			if (Start and IsTrackedCooldown(kind, Duration) and Start + Duration > now) then
				Record.Deadline = Start + Duration
			else
				Cooldowns:ShowReady(kind, ID)
				ReleaseRecord(records, ID)
			end
		end
	end
end

-- Called by the one-shot deadline timer, rather than once per frame.
function Cooldowns:OnUpdate()
	if (ActiveCount == 0) then
		return
	end

	local Now = GetTime()

	UpdateExpiredRecords(ActiveSpells, "spell", Now)
	UpdateExpiredRecords(ActiveItems, "item", Now)

	self:ScheduleNext()
end

-- UNIT_SPELLCAST_SUCCEEDED fetches casts, and then SPELL_UPDATE_COOLDOWN checks them after the GCD is done (Otherwise GetSpellCooldown detects GCD)
function Cooldowns:SPELL_UPDATE_COOLDOWN()
	for ID in pairs(ActiveSpells) do
		local Start, Duration = GetSpellCooldownValues(ID)
		UpdateRecord(ActiveSpells, "spell", ID, Start, Duration)
	end

	for ID in pairs(Spells) do
		local Start, Duration = GetSpellCooldownValues(ID)
		UpdateRecord(ActiveSpells, "spell", ID, Start, Duration)
		Spells[ID] = nil
	end

	self:ScheduleNext()
end

function Cooldowns:BAG_UPDATE_COOLDOWN()
	for ID in pairs(ActiveItems) do
		local Start, Duration = GetItemCooldown(ID)
		UpdateRecord(ActiveItems, "item", ID, Start, Duration)
	end

	self:ScheduleNext()
end

function Cooldowns:UNIT_SPELLCAST_SUCCEEDED(unit, guid, id)
	if (unit == "player") then
		if self.Blacklist["player"][id] then
			return
		end

		Spells[id] = true
	end
end

local StartItem = function(id)
	if Cooldowns.Blacklist["item"][id] then
		return
	end

	local Start, Duration = GetItemCooldown(id)
	UpdateRecord(ActiveItems, "item", id, Start, Duration)
	Cooldowns:ScheduleNext()
end

local UseAction = function(slot)
	local ActionType, ItemID = GetActionInfo(slot)

	if (ActionType == "item") then
		StartItem(ItemID)
	end
end

local UseInventoryItem = function(slot)
	local ItemID = GetInventoryItemID("player", slot)

	if ItemID then
		StartItem(ItemID)
	end
end

local UseContainerItem = function(bag, slot)
	local ItemID = ContainerItemID(bag, slot)

	if ItemID then
		StartItem(ItemID)
	end
end

local OnFinished = function(self)
	self.Parent.AnimOut:Play()
end

function Cooldowns:OnEvent(event, ...)
	self[event](self, ...)
end

function Cooldowns:Load()
	if (not Settings["cooldowns-enable"]) then
		return
	end

	self.Anchor = CreateFrame("Frame", "HydraUI Cooldown Flash", HydraUI.UIParent)
	self.Anchor:SetSize(Settings["cooldowns-size"], Settings["cooldowns-size"])
	self.Anchor:SetPoint("CENTER", HydraUI.UIParent, "CENTER", 0, 100)

	self:SetSize(Settings["cooldowns-size"], Settings["cooldowns-size"])
	self:SetPoint("CENTER", self.Anchor, "CENTER", 0, 0)
	self:SetBackdrop(HydraUI.Backdrop)
	self:SetFrameStrata("HIGH")
	self:SetBackdropColor(0, 0, 0)
	self:SetAlpha(0)

	self.Icon = self:CreateTexture(nil, "OVERLAY")
	self.Icon:SetPoint("TOPLEFT", self, 1, -1)
	self.Icon:SetPoint("BOTTOMRIGHT", self, -1, 1)
	self.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	self.Text = self:CreateFontString(nil, "OVERLAY")
	self.Text:SetPoint("TOP", self, "BOTTOM", 0, -5)
	HydraUI:SetFontInfo(self.Text, Settings["ui-widget-font"], 16)
	self.Text:SetWidth(Settings["cooldowns-size"] * 2.5)
	self.Text:SetJustifyH("CENTER")

	self.AnimIn = LibMotion:CreateAnimation(self, "Fade")
	self.AnimIn:SetChange(1)
	self.AnimIn:SetDuration(0.2)
	self.AnimIn:SetEndDelay(Settings["cooldowns-hold"] + 0.2)
	self.AnimIn:SetEasing("in")
	self.AnimIn:SetScript("OnFinished", OnFinished)

	self.AnimOut = LibMotion:CreateAnimation(self, "Fade")
	self.AnimOut:SetChange(0)
	self.AnimOut:SetDuration(0.6)
	self.AnimOut:SetEasing("out")

	HydraUI:CreateMover(self.Anchor)

	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self:RegisterEvent("BAG_UPDATE_COOLDOWN")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:SetScript("OnEvent", self.OnEvent)

	hooksecurefunc("UseAction", UseAction)
	hooksecurefunc("UseInventoryItem", UseInventoryItem)

	if (C_Container and C_Container.UseContainerItem) then
		hooksecurefunc(C_Container, "UseContainerItem", UseContainerItem)
	elseif (UseContainerItem and type(UseContainerItem) == "function") then
		hooksecurefunc("UseContainerItem", UseContainerItem)
	end
end

local UpdateEnableCooldownFlash = function(value)
	if value then
		Cooldowns:RegisterEvent("SPELL_UPDATE_COOLDOWN")
		Cooldowns:RegisterEvent("BAG_UPDATE_COOLDOWN")
		Cooldowns:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	else
		Cooldowns:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
		Cooldowns:UnregisterEvent("BAG_UPDATE_COOLDOWN")
		Cooldowns:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	end
end

local UpdateCooldownSize = function(value)
	Cooldowns:SetSize(value, value)
	Cooldowns.Anchor:SetSize(value, value)
end

local UpdateCooldownHold = function(value)
	Cooldowns.AnimIn:SetEndDelay(value + 0.2)
end

local TestCooldown = function()
	if Settings["cooldowns-text"] then
		Cooldowns.Text:SetText(format(Language["|cff%s%s|r is ready!"], Settings["ui-widget-color"], GetItemInfo(6948)))
	else
		Cooldowns.Text:SetText("")
	end

	Cooldowns.Icon:SetTexture(select(10, GetItemInfo(6948)))
	Cooldowns.AnimIn:Play()
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["General"], function(left, right)
	right:CreateHeader(Language["Cooldown Alert"])
	right:CreateSwitch("cooldowns-enable", Settings["cooldowns-enable"], Language["Enable Cooldown Alert"], Language["Flash an icon when an ability comes off cooldown"], UpdateEnableCooldownFlash)
	right:CreateSwitch("cooldowns-text", Settings["cooldowns-text"], Language["Enable Cooldown Text"], Language["Display text on the cooldown alert"])
	right:CreateSlider("cooldowns-size", Settings["cooldowns-size"], 18, 100, 2, Language["Set Size"], Language["Set the size of the cooldown alert"], UpdateCooldownSize)
	right:CreateSlider("cooldowns-hold", Settings["cooldowns-hold"], 0.2, 3, 0.1, Language["Set Hold Time"], Language["Set how long the alert remains visible before fading"], UpdateCooldownHold, nil, "s")
	right:CreateButton("", Language["Test"], Language["Test Cooldown"], Language["Test the cooldown alert"], TestCooldown)
end)
