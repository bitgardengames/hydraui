-- HydraUI's unit-frame component boundary.
--
-- The style files in this directory are the source of truth for this list.  In
-- particular, do not turn this into a public AddElement-style API: keeping the
-- list closed prevents an unrelated oUF element from being enabled merely
-- because another addon registered it.
local _, ns = ...
local HydraUI = ns:get()

local loaded = ns.UnitFrameOUFBridge.elements

-- Event documentation lives beside the component selection.  `unit = true`
-- means RegisterUnitEvent is used; false means the event is shared.  Some
-- components conditionally subscribe to a subset (for example color options,
-- empowered casts, or an absorb bar), but an event never changes category.
local U, S = true, false
local eventSets = {
	Health = {UNIT_HEALTH = U, UNIT_HEALTH_FREQUENT = U, UNIT_MAXHEALTH = U, UNIT_CONNECTION = U, PARTY_MEMBER_ENABLE = U, PARTY_MEMBER_DISABLE = U, UNIT_FLAGS = U, UNIT_FACTION = U, UNIT_THREAT_LIST_UPDATE = U},
	Power = {UNIT_POWER_UPDATE = U, UNIT_POWER_FREQUENT = U, UNIT_MAXPOWER = U, UNIT_DISPLAYPOWER = U, UNIT_POWER_BAR_SHOW = U, UNIT_POWER_BAR_HIDE = U, UNIT_CONNECTION = U, UNIT_FLAGS = U, UNIT_FACTION = U, UNIT_THREAT_LIST_UPDATE = U},
	HealPrediction = {UNIT_HEAL_PREDICTION = U, UNIT_MAXHEALTH = U, UNIT_HEALTH = U, UNIT_ABSORB_AMOUNT_CHANGED = U, UNIT_HEAL_ABSORB_AMOUNT_CHANGED = U},
	Portrait = {UNIT_MODEL_CHANGED = U, UNIT_PORTRAIT_UPDATE = U, UNIT_CONNECTION = U, PARTY_MEMBER_ENABLE = U, PORTRAITS_UPDATED = S},
	Auras = {UNIT_AURA = U}, AuraWatch = {UNIT_AURA = U}, Dispel = {UNIT_AURA = U},
	Castbar = {UNIT_SPELLCAST_START = U, UNIT_SPELLCAST_CHANNEL_START = U, UNIT_SPELLCAST_STOP = U, UNIT_SPELLCAST_CHANNEL_STOP = U, UNIT_SPELLCAST_DELAYED = U, UNIT_SPELLCAST_CHANNEL_UPDATE = U, UNIT_SPELLCAST_FAILED = U, UNIT_SPELLCAST_INTERRUPTED = U, UNIT_SPELLCAST_INTERRUPTIBLE = U, UNIT_SPELLCAST_NOT_INTERRUPTIBLE = U, UNIT_SPELLCAST_EMPOWER_START = U, UNIT_SPELLCAST_EMPOWER_STOP = U, UNIT_SPELLCAST_EMPOWER_UPDATE = U},
	ThreatIndicator = {UNIT_THREAT_SITUATION_UPDATE = U, UNIT_THREAT_LIST_UPDATE = U},
	RaidTargetIndicator = {RAID_TARGET_UPDATE = S}, TargetIndicator = {PLAYER_TARGET_CHANGED = S},
	CombatIndicator = {PLAYER_REGEN_DISABLED = S, PLAYER_REGEN_ENABLED = S},
	LeaderIndicator = {PARTY_LEADER_CHANGED = S, GROUP_ROSTER_UPDATE = S}, AssistantIndicator = {GROUP_ROSTER_UPDATE = S},
	ReadyCheckIndicator = {READY_CHECK = S, READY_CHECK_CONFIRM = S, READY_CHECK_FINISHED = S},
	ResurrectIndicator = {INCOMING_RESURRECT_CHANGED = U}, PhaseIndicator = {UNIT_PHASE = U},
	GroupRoleIndicator = {PLAYER_ROLES_ASSIGNED = S, GROUP_ROSTER_UPDATE = S},
	PvPIndicator = {UNIT_FACTION = U, HONOR_LEVEL_UPDATE = S}, Range = {},
	PowerPrediction = {UNIT_SPELLCAST_START = U, UNIT_SPELLCAST_STOP = U, UNIT_SPELLCAST_FAILED = U, UNIT_SPELLCAST_SUCCEEDED = U, UNIT_DISPLAYPOWER = U},
	ManaRegen = {UNIT_POWER_FREQUENT = U}, EnergyTick = {},
	ComboPoints = {PLAYER_ENTERING_WORLD = S, UNIT_POWER_UPDATE = S, UNIT_TARGET = U, UPDATE_SHAPESHIFT_FORM = S, SPELLS_CHANGED = S, UNIT_POWER_POINT_CHARGE = U},
	Runes = {RUNE_POWER_UPDATE = S, RUNE_TYPE_UPDATE = S, PLAYER_SPECIALIZATION_CHANGED = S},
	ClassPower = {UNIT_MAXPOWER = U, UNIT_POWER_FREQUENT = U, UNIT_POWER_POINT_CHARGE = U, UNIT_DISPLAYPOWER = U, SPELLS_CHANGED = S, PLAYER_TALENT_UPDATE = S},
	Stagger = {UNIT_AURA = U, UNIT_DISPLAYPOWER = U, PLAYER_TALENT_UPDATE = S},
	Totems = {PLAYER_TOTEM_UPDATE = S}, Smooth = {},
}

-- oUF has already selected the client-specific source files by this point in
-- the TOC.  Snapshotting the implementations here selects Retail/Classic once
-- at load, rather than probing incompatible APIs in each update.
local names = {
	"Health", "Power", "HealPrediction", "Portrait", "Auras", "AuraWatch", "Dispel",
	"Castbar", "ThreatIndicator", "RaidTargetIndicator", "TargetIndicator",
	"CombatIndicator", "LeaderIndicator", "AssistantIndicator", "ReadyCheckIndicator",
	"ResurrectIndicator", "PhaseIndicator", "GroupRoleIndicator", "PvPIndicator", "Range",
	"PowerPrediction", "ManaRegen", "EnergyTick", "ComboPoints", "Runes", "ClassPower",
	"Stagger", "Totems", "Smooth",
}

local components = {}
for _, name in ipairs(names) do
	local implementation = loaded[name]
	if name == "Auras" then
		implementation = ns.UnitFrameAuraComponent or implementation
	elseif name == "AuraWatch" then
		implementation = ns.UnitFrameAuraWatchComponent or implementation
	elseif name == "Castbar" then
		implementation = ns.UnitFrameCastComponent or implementation
	end
	if implementation then
		components[name] = {
			name = name,
			events = eventSets[name],
			update = implementation.update,
			enable = implementation.enable,
			disable = implementation.disable,
			clear = implementation.clear,
		}
	end
end

-- These are HydraUI's live color tables, not copies of oUF defaults.  Existing
-- health/power PostUpdateColor callbacks consequently receive HydraUI colors.
function components.ApplyColors(frame)
	frame.colors.class = HydraUI.ClassColors
	frame.colors.reaction = HydraUI.ReactionColors
	frame.colors.power = HydraUI.PowerColors
	frame.colors.tapped = HydraUI.TappedColor or frame.colors.tapped
	frame.colors.disconnected = HydraUI.DisconnectedColor or frame.colors.disconnected
end

components.order = names
ns.UnitFrameComponents = components
