-- Visibility is inherited through native parenting; no addon show/hide policy.
local function Read(path)
    local file = assert(io.open(path))
    local source = file:read('*a')
    file:close()
    return source
end
local root = 'HydraUI/Elements/UnitFrames/'
local driverSource = assert(Read(root .. 'Frames/NamePlates.lua'):match('(function UF:CreateNamePlateDriver%(%).-)\nUF.NamePlateCallback ='))
local bindingSource = assert(Read(root .. 'Core.lua'):match('(function UnitFrames:SetNamePlateUnit[%s%S]*)'))
local compile, unpackValues = loadstring or load, unpack or table.unpack
local install = assert(compile('return function(UF, HydraUI)\nlocal UnitFrames = HydraUI.UnitFrames\n' .. bindingSource .. '\n' .. driverSource .. '\nend'))()

local function Frame(parent)
    local frame = {shown = true, alpha = 1, events = {}, children = {}, regions = {}, _unitEvents = {}, showCalls = 0, hideCalls = 0}
    function frame:SetParent(newParent)
        if self.parent then
            for i, child in ipairs(self.parent.children) do
                if child == self then table.remove(self.parent.children, i); break end
            end
        end
        self.parent = newParent
        if newParent then table.insert(newParent.children, self) end
    end
    function frame:GetParent() return self.parent end
    function frame:GetChildren() return unpackValues(self.children) end
    function frame:GetRegions() return unpackValues(self.regions) end
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:UnregisterEvent(event) self.events[event] = nil end
    frame._unregisterEvent = frame.UnregisterEvent
    function frame:_registerUnitEvent(event, unit) self.events[event] = unit end
    function frame:UnregisterAllEvents() error('Do not disable native events') end
    function frame:SetScript(_, handler) self.event = handler end
    function frame:HookScript() error('Do not mirror native visibility with hooks') end
    function frame:SetShown(shown) self.shown = shown end
    function frame:Show() self.showCalls = self.showCalls + 1; self.shown = true end
    function frame:Hide() self.hideCalls = self.hideCalls + 1; self.shown = false end
    function frame:IsShown() return self.shown end
    function frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function frame:IsForbidden() return self.forbidden or false end
    function frame:SetAlpha(alpha) self.alpha = alpha end
    function frame:GetEffectiveAlpha() return self.alpha * (self.parent and self.parent:GetEffectiveAlpha() or 1) end
    function frame:Refresh() self.refreshes = (self.refreshes or 0) + 1 end
    frame:SetParent(parent)
    return frame
end
local function Region()
    return {alpha = 1, SetAlpha = function(self, alpha) self.alpha = alpha end}
end
UnitIsFriend = function() error('Do not classify visibility') end
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

for _, layout in ipairs({'modern', 'legacy', 'lowercase', 'outer'}) do
    for _, useDriverHook in ipairs({true, false}) do
        local hider = Frame()
        hider:Hide()
        local UF = {Hider = hider, NamePlateCVars = {}, NamePlateCallback = function() end}
        local HydraUI = {StyleFuncs = {}, UnitFrames = {}}
        local bases = {}
        C_NamePlate = {GetNamePlateForUnit = function(unit) return bases[unit] end}
        HydraUI.UnitFrames.CreateNamePlateButton = function(_, parent) return Frame(parent) end
        NamePlateDriverFrame = useDriverHook and {OnNamePlateAdded = function(_, unit)
            bases[unit].UnitFrame = bases[unit].acquired
        end} or nil
        install(UF, HydraUI)
        UF:CreateNamePlateDriver()
        local driver = UF.NamePlateDriver
        local function Event(event, unit) driver.event(driver, event, unit) end
        local function Added(unit)
            if useDriverHook then NamePlateDriverFrame:OnNamePlateAdded(unit)
            else bases[unit].UnitFrame = bases[unit].acquired; Event('NAME_PLATE_UNIT_ADDED', unit) end
        end
        assert(not driver.events.CVAR_UPDATE and not driver.events.UNIT_FACTION)
        -- NPC, friendly player and enemy all obey the same parent chain.
        for _, unit in ipairs({'nameplate1', 'nameplate2', 'nameplate3'}) do
            local base = Frame()
            bases[unit] = base
            local blizzard = Frame(base)
            local health = Frame(blizzard)
            if layout == 'modern' then blizzard.HealthBarsContainer = {healthBar = health}
            elseif layout == 'legacy' then blizzard.healthBar = health
            elseif layout == 'lowercase' then blizzard.healthbar = health
            else health = blizzard end
            blizzard.name = Region()
            blizzard.regions = {Region(), blizzard.name}
            health.regions[#health.regions + 1] = Region()
            blizzard.WidgetContainer = Frame(blizzard)
            blizzard.WidgetContainer.regions = {Region()}
            blizzard.events.CVAR_UPDATE = true
            base.acquired = blizzard
            health:Hide()
            Added(unit)
            local plate = base._unitFrame
            assert(plate:GetParent() == health)
            assert(plate:IsShown() and not plate:IsVisible())
            assert(blizzard.alpha == 1 and health.alpha == 1)
            assert(blizzard.name.alpha == 1 and blizzard.WidgetContainer.regions[1].alpha == 1)
            assert(health.regions[#health.regions].alpha == 0)
            assert(blizzard.events.CVAR_UPDATE)
            health:Show()
            assert(plate:IsVisible())
            for _, ancestor in ipairs({health, blizzard, base}) do
                ancestor:Hide()
                assert(not plate:IsVisible() and plate:IsShown())
                ancestor:Show()
                assert(plate:IsVisible())
                ancestor:SetAlpha(0)
                assert(plate:GetEffectiveAlpha() == 0)
                ancestor:SetAlpha(0.4)
                assert(plate:GetEffectiveAlpha() == 0.4)
                ancestor:SetAlpha(1)
            end
            -- Initial native name-only state survives re-binding untouched.
            health:Hide()
            Event('NAME_PLATE_UNIT_REMOVED', unit)
            assert(not plate.unit and plate:GetParent() == hider and not plate:IsVisible())
            Added(unit)
            assert(not plate:IsVisible() and plate:IsShown())
            assert(blizzard.name.alpha == 1)
            health:Show()
            assert(plate:IsVisible())
            assert(plate.showCalls == 0 and plate.hideCalls == 0)
            -- Custom children must never be included in artwork suppression.
            plate.regions = {Region()}
            Added(unit)
            assert(plate.regions[1].alpha == 1)
        end
        -- Pooled Blizzard frames can move independently of cached HydraUI plates.
        local oldBase, newBase = bases.nameplate1, bases.nameplate2
        Event('NAME_PLATE_UNIT_REMOVED', 'nameplate1')
        Event('NAME_PLATE_UNIT_REMOVED', 'nameplate2')
        local pooled = oldBase.UnitFrame
        pooled:SetParent(newBase)
        newBase.acquired = pooled
        Added('nameplate2')
        assert(newBase._unitFrame:IsVisible() and not oldBase._unitFrame:IsVisible())
        pooled:Hide()
        assert(not newBase._unitFrame:IsVisible())
        pooled:Show()
        assert(newBase._unitFrame:IsVisible())
        local forbidden = Frame()
        forbidden.forbidden = true
        forbidden.acquired = Frame(forbidden)
        bases.nameplate4 = forbidden
        Added('nameplate4')
        assert(not forbidden._unitFrame)
    end
end
print('Native nameplate parenting checks passed')
