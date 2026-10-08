-- Run the real driver against Blizzard-owned visibility and pooled unit frames.
local file = assert(io.open('HydraUI/Elements/UnitFrames/Frames/NamePlates.lua'))
local source = file:read('*a')
file:close()
local driverSource = assert(source:match('(function UF:CreateNamePlateDriver%(%).-)\nUF.NamePlateCallback ='))
local compile = loadstring or load
local install = assert(compile('return function(UF, HydraUI)\n' .. driverSource .. '\nend'))()

local function Frame(parent)
    local frame = {shown = true, alpha = 1, events = {}, hooks = {}, parent = parent}
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:UnregisterEvent(event) self.events[event] = nil end
    function frame:UnregisterAllEvents() error('Blizzard events must stay registered') end
    function frame:SetScript(_, handler) self.event = handler end
    function frame:HookScript(script, handler)
        self.hooks[script] = self.hooks[script] or {}
        table.insert(self.hooks[script], handler)
    end
    function frame:SetShown(shown)
        if self.shown == shown then return end
        self.shown = shown
        for _, handler in ipairs(self.hooks[shown and 'OnShow' or 'OnHide'] or {}) do
            handler(self)
        end
    end
    function frame:Show() self:SetShown(true) end
    function frame:Hide() self:SetShown(false) end
    function frame:IsShown() return self.shown end
    function frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function frame:IsForbidden() return self.forbidden or false end
    function frame:GetParent() return self.parent end
    function frame:SetAlpha(alpha) self.alpha = alpha end
    function frame:Refresh() self.refreshes = (self.refreshes or 0) + 1 end
    return frame
end

-- Any independent visibility policy is an error: Blizzard alone decides.
UnitIsFriend = function() error('Do not classify nameplate visibility') end
UnitIsUnit = UnitIsFriend
C_CVar = {SetCVar = function() end, GetCVarBool = function() error('Do not read visibility CVars') end}
IsLoggedIn = function() return true end
CreateFrame = function() return Frame() end
hooksecurefunc = function(object, method, callback)
    local original = object[method]
    object[method] = function(self, ...)
        original(self, ...)
        callback(self, ...)
    end
end

for _, mainline in ipairs({true, false}) do
    for _, useDriverHook in ipairs({true, false}) do
        local UF = {NamePlateCVars = {}, NamePlateCallback = function() end}
        local HydraUI = {IsMainline = mainline, StyleFuncs = {}}
        local bases = {}
        C_NamePlate = {GetNamePlateForUnit = function(unit) return bases[unit] end}
        HydraUI.UnitFrames = {
            CreateNamePlateButton = function(_, base) return Frame(base) end,
            SetNamePlateUnit = function(_, plate, unit)
                plate.unit = unit
                plate:SetShown(unit ~= nil)
            end}
        NamePlateDriverFrame = useDriverHook and {OnNamePlateAdded = function(_, unit)
            local base = bases[unit]
            base.UnitFrame = base.acquired
        end} or nil
        install(UF, HydraUI)
        UF:CreateNamePlateDriver()
        local driver = UF.NamePlateDriver
        local function Event(event, unit) driver.event(driver, event, unit) end
        local function Added(unit)
            if useDriverHook then
                NamePlateDriverFrame:OnNamePlateAdded(unit)
            else
                bases[unit].UnitFrame = bases[unit].acquired
                Event('NAME_PLATE_UNIT_ADDED', unit)
            end
        end
        assert(not driver.events.CVAR_UPDATE and not driver.events.UNIT_FACTION)
        assert((driver.events.NAME_PLATE_UNIT_ADDED == true) == not useDriverHook)
        -- Friendly, hostile, and personal plates all follow the same rule.
        for _, unit in ipairs({'nameplate1', 'nameplate2', 'nameplate3'}) do
            local base = Frame()
            bases[unit] = base
            local blizzard = Frame(base)
            base.acquired = blizzard
            blizzard.events.CVAR_UPDATE = true
            blizzard:Hide()
            Added(unit)
            local plate = base._unitFrame
            assert(not plate.shown and not blizzard.shown)
            assert(blizzard.alpha == 0 and plate.alpha == 1)
            assert(plate:GetParent() == base and blizzard.events.CVAR_UPDATE)
            blizzard:Show()
            assert(plate.shown)
            local refreshes = plate.refreshes
            blizzard:Hide()
            assert(not plate.shown)
            blizzard:SetShown(true)
            assert(plate.shown and plate.refreshes > refreshes)
            base:Hide()
            assert(not plate:IsVisible())
            base:Show()
            assert(plate:IsVisible())
            Event('NAME_PLATE_UNIT_REMOVED', unit)
            blizzard:Hide()
            blizzard:Show()
            assert(not plate.shown and not plate.unit and not UF.NamePlatesByUnit[unit])
            Added(unit)
            assert(base._unitFrame == plate and plate.shown)
            assert(#blizzard.hooks.OnShow == 1 and #blizzard.hooks.OnHide == 1)
        end
        -- A pooled Blizzard frame can move to a different world-space base.
        local oldBase, newBase = bases.nameplate1, bases.nameplate2
        local pooled, stale = oldBase.UnitFrame, newBase.UnitFrame
        Event('NAME_PLATE_UNIT_REMOVED', 'nameplate1')
        Event('NAME_PLATE_UNIT_REMOVED', 'nameplate2')
        pooled.parent = newBase
        newBase.acquired = pooled
        Added('nameplate2')
        pooled:Hide()
        assert(not newBase._unitFrame.shown)
        stale:Hide()
        stale:Show()
        assert(not newBase._unitFrame.shown)
        pooled:Show()
        assert(newBase._unitFrame.shown and not oldBase._unitFrame.shown)
        -- Forbidden nameplates stay entirely under Blizzard's control.
        local forbidden = Frame()
        forbidden.forbidden = true
        bases.nameplate4 = forbidden
        forbidden.acquired = Frame(forbidden)
        Added('nameplate4')
        assert(not forbidden._unitFrame and forbidden.UnitFrame.alpha == 1)
        local forbiddenChild = Frame()
        forbiddenChild.acquired = Frame(forbiddenChild)
        forbiddenChild.acquired.forbidden = true
        bases.nameplate5 = forbiddenChild
        Added('nameplate5')
        assert(not forbiddenChild._unitFrame and forbiddenChild.UnitFrame.alpha == 1)
    end
end
print('Blizzard nameplate visibility checks passed')
