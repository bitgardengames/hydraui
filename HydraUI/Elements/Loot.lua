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
local CloseLoot = CloseLoot
local IsInGroup = IsInGroup

local tinsert = table.insert
local wipe = table.wipe or wipe

local AUTO_LOOT_TOGGLE = "AUTOLOOTTOGGLE"
local MASTER_LOOT = "master"

Loot.LootSlots = {}

if C_PartyInfo and C_PartyInfo.GetLootMethod then
        GetLootMethod = C_PartyInfo.GetLootMethod
end

local ShouldAutoLoot = function()
        local AutoLootDefault = GetCVar("autoLootDefault")

        if (AutoLootDefault == "1") then
                return not IsModifiedClick(AUTO_LOOT_TOGGLE)
        end

        return IsModifiedClick(AUTO_LOOT_TOGGLE)
end

function Loot:ProcessQueue()
        local Slots = self.LootSlots

        if (#Slots == 0) then
                self:SetScript("OnUpdate", nil)

                if (GetNumLootItems() == 0) then
                        CloseLoot()
                end

                return
        end

        for index = #Slots, 1, -1 do
                LootSlot(Slots[index])
                Slots[index] = nil
        end

        if (GetNumLootItems() == 0) then
                self:SetScript("OnUpdate", nil)
                CloseLoot()
        end
end

function Loot:LOOT_READY()
        if (not ShouldAutoLoot()) then
                return
        end

        local Slots = self.LootSlots

        wipe(Slots)

        local LootMethod = GetLootMethod()
        local IsMasterLoot = (LootMethod == MASTER_LOOT) and IsInGroup()
        local Threshold = GetLootThreshold() or 0

        for slot = GetNumLootItems(), 1, -1 do
                local _, _, _, _, Quality, Locked = GetLootSlotInfo(slot)

                if (Locked == nil or Locked == false) then
                        if (not IsMasterLoot) or (Quality and (Quality < Threshold)) then
                                tinsert(Slots, slot)
                        end
                end
        end

        if (#Slots > 0) then
                self:SetScript("OnUpdate", self.ProcessQueue)
        end
end

function Loot:OnEvent(event, ...)
        if self[event] then
                self[event](self, ...)
        end
end

function Loot:UpdateRegistration(enabled)
        if enabled then
                self:RegisterEvent("LOOT_READY")
                self:SetScript("OnEvent", self.OnEvent)
        else
                self:UnregisterEvent("LOOT_READY")
                self:SetScript("OnEvent", nil)
        end
end

function Loot:Load()
        self:UpdateRegistration(Settings["fast-loot"])
end

local UpdateFastLoot = function(value)
        Loot:UpdateRegistration(value)
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["General"], function(left, right)
        right:CreateHeader(Language["Loot"])
        right:CreateSwitch("fast-loot", Settings["fast-loot"], Language["Enable Fast Loot"], Language["Speed up auto looting"], UpdateFastLoot)
end)
