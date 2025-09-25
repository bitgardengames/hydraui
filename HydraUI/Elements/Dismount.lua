local HydraUI, Language, Assets, Settings = select(2, ...):get()

local select = select
local CancelShapeshiftForm = CancelShapeshiftForm
local CancelUnitBuff = CancelUnitBuff
local DoEmote = DoEmote
local DismountPlayer = Dismount
local InCombatLockdown = InCombatLockdown
local UnitBuff = UnitBuff

local AutoDismount = HydraUI:NewModule("Dismount")

local MAX_PLAYER_BUFFS = 40
local GHOST_WOLF_ID = 2645
local STAND_EMOTE = "STAND"

local function ClearErrors()
        UIErrorsFrame:Clear()
end

AutoDismount.Mount = {
        [SPELL_FAILED_NOT_MOUNTED] = true,
        [ERR_ATTACK_MOUNTED] = true,
        [ERR_NOT_WHILE_MOUNTED] = true,
        [ERR_TAXIPLAYERALREADYMOUNTED] = true,
}

AutoDismount.Shapeshift = {
        [ERR_CANT_INTERACT_SHAPESHIFTED] = true,
        [ERR_EMBLEMERROR_NOTABARDGEOSET] = true,
        [ERR_MOUNT_SHAPESHIFTED] = true,
        [ERR_NO_ITEMS_WHILE_SHAPESHIFTED] = true,
        [ERR_NOT_WHILE_SHAPESHIFTED] = true,
        [ERR_TAXIPLAYERSHAPESHIFTED] = true,
        [SPELL_FAILED_NO_ITEMS_WHILE_SHAPESHIFTED] = true,
        [SPELL_FAILED_NOT_SHAPESHIFT] = true,
        [SPELL_NOT_SHAPESHIFTED] = true,
        [SPELL_NOT_SHAPESHIFTED_NOSPACE] = true,
}

AutoDismount.Stand = {
        [SPELL_FAILED_NOT_STANDING] = true,
}

function AutoDismount:CancelShapeshift()
        if InCombatLockdown() then
                return false
        end

        if CancelShapeshiftForm then
                CancelShapeshiftForm()
                ClearErrors()

                return true
        end

        for index = 1, MAX_PLAYER_BUFFS do
                local spellID = select(10, UnitBuff("player", index))

                if not spellID then
                        break
                end

                if spellID == GHOST_WOLF_ID then
                        CancelUnitBuff("player", index)
                        ClearErrors()

                        return true
                end
        end

        return false
end

function AutoDismount:UI_ERROR_MESSAGE(_, message)
        if self.Mount[message] then
                DismountPlayer()
                ClearErrors()

                return
        end

        if self.Shapeshift[message] then
                if self:CancelShapeshift() then
                        return
                end
        elseif self.Stand[message] then
                DoEmote(STAND_EMOTE)
                ClearErrors()
        end
end

function AutoDismount:TAXIMAP_OPENED()
        DismountPlayer()
end

function AutoDismount:OnEvent(event, ...)
        if self[event] then
                self[event](self, ...)
        end
end

function AutoDismount:UpdateRegistration(enabled)
        if enabled then
                self:RegisterEvent("UI_ERROR_MESSAGE")
                self:RegisterEvent("TAXIMAP_OPENED")
                self:SetScript("OnEvent", self.OnEvent)
        else
                self:UnregisterEvent("UI_ERROR_MESSAGE")
                self:UnregisterEvent("TAXIMAP_OPENED")
                self:SetScript("OnEvent", nil)
        end
end

function AutoDismount:Load()
        self:UpdateRegistration(Settings["dismount-enable"])
end

local UpdateEnableDismount = function(value)
        AutoDismount:UpdateRegistration(value)
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["General"], function(left, right)
        right:CreateHeader(Language["Auto Dismount"])
        right:CreateSwitch("dismount-enable", Settings["dismount-enable"], Language["Enable Auto Dismount"], Language["Automatically dismount during actions that can't be performed while mounted"], UpdateEnableDismount)
end)
