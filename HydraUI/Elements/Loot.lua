local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["fast-loot"] = true

local Loot = HydraUI:NewModule("Loot")

local GetCVar = GetCVar
local IsModifiedClick = IsModifiedClick
local GetLootMethod = GetLootMethod
local GetNumLootItems = GetNumLootItems
local GetLootThreshold = GetLootThreshold
local GetLootSlotInfo = GetLootSlotInfo
local LootSlot = LootSlot

local Icon, Name, Quantity, CurrencyID, Quality, Locked, QuestItem, QuestID, IsActive
local Quality, Locked, Threshold, _

Loot.LootSlots = {}
Loot.Grouped = false

if C_PartyInfo and C_PartyInfo.GetLootMethod then
	GetLootMethod = C_PartyInfo.GetLootMethod
end

function Loot:ResetQueue()
	self:SetScript("OnUpdate", nil)
	wipe(self.LootSlots)
	self.Grouped = false
end

function Loot:LOOT_READY()
	self:ResetQueue()

	if (GetCVar("autoLootDefault") == "1" and not IsModifiedClick("AUTOLOOTTOGGLE")) or (GetCVar("autoLootDefault") ~= "1" and IsModifiedClick("AUTOLOOTTOGGLE")) then
		if IsInGroup() and GetLootMethod() == "master" then
			self.Grouped = true
		end

		Threshold = GetLootThreshold()

		for i = GetNumLootItems(), 1, -1 do
			_, _, _, _, Quality, Locked = GetLootSlotInfo(i)

			if Locked ~= nil and not Locked then
				if not self.Grouped or Quality < Threshold then
					self.LootSlots[#self.LootSlots + 1] = i
				end
			end
		end

		if #self.LootSlots > 0 then
			self:SetScript("OnUpdate", self.OnUpdate)
		end
	end
end

function Loot:OnUpdate()
	if #self.LootSlots == 0 then
		self:ResetQueue()
		return
	end

	for i = 1, #self.LootSlots do
		LootSlot(self.LootSlots[i])
	end

	if GetNumLootItems() == 0 then
		self:ResetQueue()
		CloseLoot()
	end
end

function Loot:OnEvent(event, ...)
	self[event](self)
end

function Loot:Load()
	if not Settings["fast-loot"] then
		return
	end

	self:RegisterEvent("LOOT_READY")
	self:SetScript("OnEvent", self.OnEvent)
end

local UpdateFastLoot = function(value)
	if value then
		Loot:RegisterEvent("LOOT_READY")
		Loot:SetScript("OnEvent", Loot.OnEvent)
	else
		Loot:UnregisterEvent("LOOT_READY")
		Loot:SetScript("OnEvent", nil)
		Loot:ResetQueue()
	end
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["General"], function(left, right)
	right:CreateHeader(Language["Loot"])
	right:CreateSwitch("fast-loot", Settings["fast-loot"], Language["Enable Fast Loot"], Language["Speed up auto looting"], UpdateFastLoot)
end)
