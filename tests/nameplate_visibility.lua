-- Exercise the real driver with world-space bases that remain alive when hidden.
local path = 'HydraUI/Elements/UnitFrames/Frames/NamePlates.lua'
local file = assert(io.open(path))
local source = file:read('*a')
file:close()
local driverSource = source:match('(function UF:CreateNamePlateDriver%(%).-)\nUF.NamePlateCallback =')
assert(driverSource)
local UF = {NamePlateCVars = {}, NamePlateCallback = function() end}
local HydraUI = {IsMainline = true, StyleFuncs = {}}
local bases, friends, selfUnits, showFriends = {}, {}, {}, false
local function Frame()
    return {shown = true, events = {},
        RegisterEvent = function(self, event) self.events[event] = true end,
        UnregisterEvent = function(self, event) self.events[event] = nil end,
        SetScript = function(self, _, fn) self.event = fn end,
        Hide = function(self) self.shown = false end,
        Show = function(self) self.shown = true end,
        Refresh = function(self) self.refreshes = (self.refreshes or 0) + 1 end}
end
CreateFrame = Frame
IsLoggedIn = function() return true end
C_CVar = {SetCVar = function() end, GetCVarBool = function(cvar)
    assert(cvar == 'nameplateShowFriends')
    return showFriends
end}
C_NamePlate = {GetNamePlateForUnit = function(unit) return bases[unit] end}
UnitIsFriend = function(_, unit) return friends[unit] end
UnitIsUnit = function(unit) return selfUnits[unit] end
HydraUI.UnitFrames = {
    CreateNamePlateButton = function() return Frame() end,
    SetNamePlateUnit = function(_, plate, unit)
        plate.unit = unit
        if unit then plate:Show() else plate:Hide() end
    end}
local compile = loadstring or load
assert(compile('return function(UF, HydraUI)\n' .. driverSource .. '\nend'))()(UF, HydraUI)
UF:CreateNamePlateDriver()
local driver = UF.NamePlateDriver
local function Event(event, unit) driver.event(driver, event, unit) end
bases.nameplate1, bases.nameplate2, bases.nameplate3 = {}, {}, {}
friends.nameplate1, friends.nameplate3, selfUnits.nameplate3 = true, true, true
Event('NAME_PLATE_UNIT_ADDED', 'nameplate1')
Event('NAME_PLATE_UNIT_ADDED', 'nameplate2')
Event('NAME_PLATE_UNIT_ADDED', 'nameplate3')
local friendly, enemy, personal = bases.nameplate1._unitFrame, bases.nameplate2._unitFrame, bases.nameplate3._unitFrame
assert(not friendly.shown and enemy.shown and personal.shown)
assert(UF.NamePlatesByUnit.nameplate1 == friendly and friendly.unit == 'nameplate1')
showFriends = true
Event('CVAR_UPDATE', 'nameplateShowFriends')
assert(friendly.shown and enemy.shown and personal.shown)
showFriends = false
Event('CVAR_UPDATE', 'NAMEPLATESHOWFRIENDS')
assert(not friendly.shown and enemy.shown and personal.shown)
local refreshes = enemy.refreshes
Event('CVAR_UPDATE', 'unrelatedSetting')
assert(enemy.refreshes == refreshes)
friends.nameplate1 = false
Event('UNIT_FACTION', 'nameplate1')
assert(friendly.shown)
friends.nameplate1 = true
Event('UNIT_FACTION', 'nameplate1')
assert(not friendly.shown)
Event('NAME_PLATE_UNIT_REMOVED', 'nameplate1')
assert(not friendly.unit and not UF.NamePlatesByUnit.nameplate1)
showFriends = true
Event('CVAR_UPDATE', 'nameplateShowFriends')
assert(not friendly.shown)
friends.nameplate1 = false
Event('NAME_PLATE_UNIT_ADDED', 'nameplate1')
assert(bases.nameplate1._unitFrame == friendly and friendly.shown)
-- Classic retains Blizzard's normal parent visibility behavior.
UF.NamePlateDriver = nil
HydraUI.IsMainline, showFriends, friends.nameplate1 = false, false, true
UF:CreateNamePlateDriver()
driver = UF.NamePlateDriver
assert(not driver.events.CVAR_UPDATE and not driver.events.UNIT_FACTION)
Event('NAME_PLATE_UNIT_ADDED', 'nameplate1')
assert(friendly.shown)
print('Nameplate visibility checks passed')
