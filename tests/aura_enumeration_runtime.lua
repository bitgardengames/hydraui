local UF = {Hider = {}}
local elements = {}
local HydraUI = {IsMainline = true, DurationText = {}}
function HydraUI:GetModule() return UF end
function UF:RegisterElement(name, handlers) elements[name] = handlers end
function HydraUI.DurationText:Unregister(button) button.unregistered = true end
local ns = {get = function() return HydraUI end}
local function Load(name)
	assert(loadfile("HydraUI/Elements/UnitFrames/Elements/" .. name .. ".lua"))(nil, ns)
end
local restricted, secretIndex, reads = false, nil, 0
C_Secrets = {
	ShouldAurasBeSecret = function() return restricted end,
	ShouldUnitAuraIndexBeSecret = function(unit, index, filter)
		assert(unit == "player" and (filter == "HELPFUL" or filter == "HARMFUL"))
		return index == secretIndex
	end,
}
local aura = {name = "Test", icon = 123, applications = 2, dispelName = "Magic",
	duration = 10, expirationTime = 20, sourceUnit = "player", isStealable = false, spellId = 456}
C_UnitAuras = {GetAuraDataByIndex = function(_, index)
	assert(not restricted and index ~= secretIndex, "Auras cannot be accessed when secret")
	reads = reads + 1
	if index <= 2 then return aura end
end}

for _, client in ipairs({"IsMidnight", "IsForever"}) do
	HydraUI.IsMidnight, HydraUI.IsForever = false, false
	HydraUI[client] = true
	Load("AuraEnumeration_Mainline")
	for _, filter in ipairs({"HELPFUL", "HARMFUL"}) do
		restricted, reads = true, 0
		UF.EnumerateAuras("player", filter, function() error("restricted visitor") end)
		assert(reads == 0)
		restricted, secretIndex, reads = false, 1, 0
		local visited = {}
		UF.EnumerateAuras("player", filter, function(index, name, icon, count, dispel, duration, expiration, caster, stealable, spellID, data)
			assert(data == aura and name == "Test" and icon == 123 and count == 2)
			assert(dispel == "Magic" and duration == 10 and expiration == 20)
			assert(caster == "player" and stealable == false and spellID == 456)
			visited[#visited + 1] = index
		end)
		assert(#visited == 1 and visited[1] == 2 and reads == 2)
		secretIndex, reads = nil, 0
		UF.EnumerateAuras("player", filter, function() return false end)
		assert(reads == 1)
	end
end

-- Older mainline clients may not expose the secrecy predicates.
C_Secrets, reads = nil, 0
UF.EnumerateAuras("player", "HARMFUL", function() end)
assert(reads == 3)
C_Secrets = {ShouldAurasBeSecret = function() return restricted end}
Load("AuraSupport")
local function Button()
	local button = {shown = true, Time = {}}
	function button:Hide() self.shown = false end
	function button:Show() self.shown = true end
	function button:SetSize() end
	function button:ClearAllPoints() end
	function button:SetPoint() end
	function button.Time:Hide() self.hidden = true end
	button.icon = {SetTexture = function(self, value) self.texture = value end}
	button.count = {SetText = function(self, value) self.text = value end}
	return button
end
local function Container()
	local container = {Button(), Button(), size = 16}
	function container:GetWidth() return 64 end
	return container
end
local frame = {unit = "player", Buffs = Container(), Debuffs = Container()}
restricted, reads = true, 0
elements.Auras.update(frame)
assert(reads == 0)
for _, container in ipairs({frame.Buffs, frame.Debuffs}) do
	for _, button in ipairs(container) do
		assert(not button.shown and button.unregistered and button.Time.hidden)
	end
end
restricted = false
elements.Auras.update(frame)
assert(reads == 6 and frame.Buffs[1].shown and frame.Debuffs[1].shown)
assert(frame.Buffs[1].icon.texture == 123 and frame.Debuffs[1].count.text == 2)
print("Mainline aura restrictions and cleanup checks passed")
