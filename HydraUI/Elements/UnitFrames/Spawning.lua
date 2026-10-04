local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()

local floor = math.floor

local function Install(UF, Hider)
local UpdateRaidSortingMethod = function(value)
	if value == "CLASS" then
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "DEATHKNIGHT,DEMONHUNTER,DRUID,HUNTER,MAGE,MONK,PALADIN,PRIEST,SHAMAN,WARLOCK,WARRIOR")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", "CLASS")
	elseif value == "ROLE" then
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "TANK,HEALER,DAMAGER,NONE")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", "ASSIGNEDROLE")
	elseif value == "NAME" then
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", nil)
	elseif value == "MTMA" then
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "MAINTANK,MAINASSIST,NONE")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "NAME")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", "ROLE")
	else -- GROUP
		HydraUI.UnitFrames["raid"]:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		HydraUI.UnitFrames["raid"]:SetAttribute("sortMethod", "INDEX")
		HydraUI.UnitFrames["raid"]:SetAttribute("groupBy", "GROUP")
	end
end

local SingletonUnits = {
	{unit = "player", globalName = "HydraUI Player", enabled = "player-enable", dimensions = {width = "unitframes-player-width", health = "unitframes-player-health-height", power = "unitframes-player-power-height"}, defaultAnchor = {"TOPRIGHT", "CENTER", -68, -281}, postSpawn = "ConfigurePlayer"},
	{unit = "target", globalName = "HydraUI Target", enabled = "target-enable", dimensions = {width = "unitframes-target-width", health = "unitframes-target-health-height", power = "unitframes-target-power-height"}, defaultAnchor = {"TOPLEFT", "CENTER", 68, -281}, postSpawn = "ConfigureTarget"},
	{unit = "targettarget", globalName = "HydraUI Target Target", enabled = "tot-enable", dimensions = {width = "unitframes-targettarget-width", health = "unitframes-targettarget-health-height", power = "unitframes-targettarget-power-height"}, defaultAnchor = {"TOPRIGHT", "CENTER", 68, -341}, postSpawn = "ConfigureTargetTarget"},
	{unit = "pet", globalName = "HydraUI Pet", enabled = "pet-enable", dimensions = {width = "unitframes-pet-width", health = "unitframes-pet-health-height", power = "unitframes-pet-power-height"}, defaultAnchor = {"TOPLEFT", "CENTER", -68, -341}, postSpawn = "ConfigurePet"},
	{unit = "focus", globalName = "HydraUI Focus", enabled = "focus-enable", dimensions = {width = "unitframes-focus-width", health = "unitframes-focus-health-height", power = "unitframes-focus-power-height"}, defaultAnchor = {"RIGHT", "CENTER", -68, 304}, postSpawn = "ConfigureFocus"},
}
UF.SingletonUnits = SingletonUnits

function UF:SpawnSingletonFrames()
	for _, descriptor in ipairs(SingletonUnits) do
		if Settings[descriptor.enabled] then
			local dimensions = descriptor.dimensions
			local frame = HydraUI.UnitFrames:CreateUnitButton(descriptor.unit, descriptor.globalName, HydraUI.StyleFuncs[descriptor.unit])
			frame:SetSize(Settings[dimensions.width], Settings[dimensions.health] + Settings[dimensions.power] + 3)
			frame:SetPoint(descriptor.defaultAnchor[1], HydraUI.UIParent, descriptor.defaultAnchor[2], descriptor.defaultAnchor[3], descriptor.defaultAnchor[4])
			frame:SetParent(HydraUI.UIParent)
			HydraUI.UnitFrames[descriptor.unit] = frame
		end
	end

	if Settings["player-enable"] then
		local Player = HydraUI.UnitFrames["player"]

		if Settings["unitframes-player-enable-power"] and (not Settings["player-move-power"]) then
			Player:SetSize(Settings["unitframes-player-width"], Settings["unitframes-player-health-height"] + Settings["unitframes-player-power-height"] + 3)
		else
			Player:SetSize(Settings["unitframes-player-width"], Settings["unitframes-player-health-height"] + 2)
		end

		Player:SetPoint("TOPRIGHT", HydraUI.UIParent, "CENTER", -68, -281)
		Player:SetParent(HydraUI.UIParent)

		if Settings["player-enable-portrait"] then
			Player:EnableElement("Portrait")
		else
			Player:DisableElement("Portrait")
		end

		if not Settings["player-enable-pvp"] then
			Player:DisableElement("PvPIndicator")
			Player.PvPIndicator:Hide()
		end

		if Settings["unitframes-show-player-buffs"] then
			Player.Buffs:Show()
		else
			Player.Buffs:Hide()
		end

		if Settings["unitframes-show-player-debuffs"] then
			Player.Debuffs:Show()
		else
			Player.Debuffs:Hide()
		end

		if Settings["unitframes-player-enable-castbar"] then
			Player.CastAnchor:SetPoint("BOTTOM", HydraUI.UIParent, 0, 118)
			HydraUI:CreateMover(Player.CastAnchor, 2)
		end

		HydraUI.UnitFrames["player"] = Player
		HydraUI:CreateMover(Player)

		Player:UpdateAllElements("ForceUpdate")
	end

	if Settings["target-enable"] then
		local Target = HydraUI.UnitFrames["target"]
		Target:SetSize(Settings["unitframes-target-width"], Settings["unitframes-target-health-height"] + Settings["unitframes-target-power-height"] + 3)
		Target:SetPoint("TOPLEFT", HydraUI.UIParent, "CENTER", 68, -281)
		Target:SetParent(HydraUI.UIParent)

		if Settings["target-enable-portrait"] then
			Target:EnableElement("Portrait")
		else
			Target:DisableElement("Portrait")
		end

		if Settings["unitframes-show-target-buffs"] then
			Target.Buffs:Show()
		else
			Target.Buffs:Hide()
		end

		if Settings["unitframes-show-target-debuffs"] then
			Target.Debuffs:Show()
		else
			Target.Debuffs:Hide()
		end

		if Settings["unitframes-target-enable-castbar"] then
			Target.CastAnchor:SetPoint("BOTTOM", HydraUI.UIParent, 0, 146)
			HydraUI:CreateMover(Target.CastAnchor, 2)
		end

		HydraUI.UnitFrames["target"] = Target
		HydraUI:CreateMover(Target)

		Target:UpdateAllElements("ForceUpdate")
	end

	if Settings["tot-enable"] then
		local TargetTarget = HydraUI.UnitFrames["targettarget"]
		TargetTarget:SetSize(Settings["unitframes-targettarget-width"], Settings["unitframes-targettarget-health-height"] + Settings["unitframes-targettarget-power-height"] + 3)
		TargetTarget:SetParent(HydraUI.UIParent)

		if Settings["target-enable"] then
			TargetTarget:SetPoint("TOPRIGHT", HydraUI.UnitFrames["target"], "BOTTOMRIGHT", 0, -2)
		else
			TargetTarget:SetPoint("TOPRIGHT", HydraUI.UIParent, "CENTER", 68, -341)
		end

		HydraUI.UnitFrames["targettarget"] = TargetTarget
		HydraUI:CreateMover(TargetTarget)
	end

	if Settings["pet-enable"] then
		local Pet = HydraUI.UnitFrames["pet"]
		Pet:SetSize(Settings["unitframes-pet-width"], Settings["unitframes-pet-health-height"] + Settings["unitframes-pet-power-height"] + 3)
		Pet:SetParent(HydraUI.UIParent)

		if Settings["player-enable"] then
			Pet:SetPoint("TOPLEFT", HydraUI.UnitFrames["player"], "BOTTOMLEFT", 0, -2)
		else
			Pet:SetPoint("TOPLEFT", HydraUI.UIParent, "CENTER", -68, -341)
		end

		HydraUI.UnitFrames["pet"] = Pet
		HydraUI:CreateMover(Pet)
	end

	if Settings["focus-enable"] then
		local Focus = HydraUI.UnitFrames["focus"]
		Focus:SetSize(Settings["unitframes-focus-width"], Settings["unitframes-focus-health-height"] + Settings["unitframes-focus-power-height"] + 3)
		Focus:SetPoint("RIGHT", HydraUI.UIParent, "CENTER", -68, 304)
		Focus:SetParent(HydraUI.UIParent)

		if Settings["focus-enable-buffs"] then
			Focus:EnableElement("Auras")
		else
			Focus:DisableElement("Auras")
		end

		HydraUI.UnitFrames["focus"] = Focus
		HydraUI:CreateMover(Focus)
	end

end

function UF:SpawnBossFrames()
	if Settings["unitframes-boss-enable"] then
		for i = 1, 8 do
			local Boss = HydraUI.UnitFrames:CreateUnitButton("boss" .. i, "HydraUI Boss " .. i, HydraUI.StyleFuncs["boss"])
			Boss:SetSize(Settings["unitframes-boss-width"], Settings["unitframes-boss-health-height"] + Settings["unitframes-boss-power-height"] + 3)
			Boss:SetParent(HydraUI.UIParent)

			if i == 1 then
				Boss:SetPoint("LEFT", HydraUI.UIParent, 300, 200)
			else
				Boss:SetPoint("TOP", HydraUI.UnitFrames["boss" .. (i-1)], "BOTTOM", 0, -28) -- -2
			end

			HydraUI:CreateMover(Boss)

			HydraUI.UnitFrames["boss" .. i] = Boss
		end
	end

end

function UF:GetGrowthOffsets(point, spacing)
	if point == "LEFT" then
		return spacing, 0
	end
	if point == "RIGHT" then
		return -spacing, 0
	end
	if point == "TOP" then
		return 0, -spacing
	end
	if point == "BOTTOM" then
		return 0, spacing
	end
	return 0, 0
end

function UF:BuildHeaderAttributes(options)
	assert(options.width and options.height, "header attributes require width and height")
	return {
		"initial-width", options.width, "initial-height", options.height,
		"showSolo", options.showSolo, "showPlayer", options.showPlayer,
		"showParty", options.showParty, "showRaid", options.showRaid,
		"point", options.point, "xOffset", options.xOffset or 0,
		"yOffset", options.yOffset or 0,
	}
end

local HEADER_INITIAL_CONFIG = [[
	local Header = self:GetParent()
	self:SetWidth(Header:GetAttribute("initial-width"))
	self:SetHeight(Header:GetAttribute("initial-height"))
	self:SetAttribute("*type1", "target")
	self:SetAttribute("*type2", "togglemenu")
	Header:CallMethod("InitializeChild", self:GetName())
]]

function UF:CreateGroupHeader(name, petHeader, visibility, attributes)
	assert(not InCombatLockdown(), "secure group headers cannot be created during combat")
	local template = petHeader and "SecureGroupPetHeaderTemplate" or "SecureGroupHeaderTemplate"
	local header = CreateFrame("Frame", name, HydraUI.UIParent, template)
	header:SetAttribute("template", "SecureUnitButtonTemplate")
	header:SetAttribute("initialConfigFunction", HEADER_INITIAL_CONFIG)
	for index = 1, #attributes, 2 do
		header:SetAttribute(attributes[index], attributes[index + 1])
	end
	header.InitializeChild = function(_, childName)
		local child = _G[childName]
		if not child or child.__hydraInitialized then
			return
		end
		local unit = child:GetAttribute("unit")
		if not unit then
			return
		end
		local style = petHeader and (visibility == "party" and "partypet" or "raidpet") or visibility
		HydraUI.UnitFrames:InitializeHeaderChild(child, unit, HydraUI.StyleFuncs[style])
	end
	local condition
	if visibility == "party" then
		condition = attributes[attributes.showSoloIndex + 1] and "[group:raid] hide; [group:party] show; [nogroup] show; hide" or "[group:party] show; hide"
	else
		condition = attributes[attributes.showSoloIndex + 1] and "[group:raid] show; [nogroup] show; hide" or "[group:raid] show; hide"
	end
	RegisterStateDriver(header, "visibility", condition)
	return header
end

local function HeaderAttributes(values)
	local attributes = {}
	for index = 1, #values do
		attributes[index] = values[index]
	end
	attributes.showSoloIndex = #attributes + 1
	attributes[attributes.showSoloIndex] = "showSolo"
	attributes[attributes.showSoloIndex + 1] = values.showSolo
	return attributes
end

function UF:SpawnPartyHeaders()
	if not Settings["party-enable"] then
		return
	end
	local xOffset, yOffset = self:GetGrowthOffsets(Settings["party-point"], Settings["party-spacing"])
	local base = {"initial-width", Settings["party-width"], "initial-height", Settings["party-health-height"] + Settings["party-power-height"] + 3,
		"isTesting", false, "showPlayer", true, "showParty", true, "showRaid", false,
		"xOffset", xOffset, "yOffset", yOffset, "point", Settings["party-point"]}
	base.showSolo = Settings["party-show-solo"]
	local Party = self:CreateGroupHeader("HydraUI Party", false, "party", HeaderAttributes(base))
	self.PartyAnchor = CreateFrame("Frame", "HydraUI Party Anchor", HydraUI.UIParent)
	self.PartyAnchor:SetSize(5 * Settings["party-width"] + 4 * Settings["party-spacing"], Settings["party-health-height"] + Settings["party-power-height"] + 3)
	self.PartyAnchor:SetPoint("BOTTOMLEFT", HydraUIChatFrameTop, "TOPLEFT", -3, 5)
	Party:SetPoint("BOTTOMLEFT", self.PartyAnchor)
	HydraUI.UnitFrames["party"] = Party
	HydraUI:CreateMover(self.PartyAnchor)

	if Settings["party-pets-enable"] then
		local petXOffset, petYOffset = self:GetGrowthOffsets(Settings["party-point"], Settings["party-spacing"])
		local pet = {"initial-width", Settings["party-pets-width"], "initial-height", Settings["party-pets-health-height"] + 2,
			"isTesting", false, "showPlayer", false, "showParty", true, "showRaid", false,
			"xOffset", petXOffset, "yOffset", petYOffset, "point", Settings["party-point"]}
		pet.showSolo = Settings["party-show-solo"]
		local PartyPet = self:CreateGroupHeader("HydraUI Party Pets", true, "party", HeaderAttributes(pet))
		self.PartyPetAnchor = CreateFrame("Frame", "HydraUI Party Pet Anchor", HydraUI.UIParent)
		self.PartyPetAnchor:SetSize(5 * Settings["party-width"] + 4 * Settings["party-spacing"], Settings["party-pets-health-height"] + 2)
		self.PartyPetAnchor:SetPoint("TOPLEFT", self.PartyAnchor, "BOTTOMLEFT", 0, -2)
		PartyPet:SetPoint("TOPLEFT", self.PartyPetAnchor)
		HydraUI:CreateMover(self.PartyPetAnchor)
		HydraUI.UnitFrames["party-pets"] = PartyPet
	end
end

function UF:SpawnRaidHeaders()
	if not Settings["raid-enable"] then
		return
	end
	local common = {"initial-width", Settings["raid-width"], "initial-height", Settings["raid-health-height"] + Settings["raid-power-height"] + 3,
		"isTesting", false, "showPlayer", true, "showParty", false, "showRaid", true,
		"point", Settings["raid-point"], "xOffset", Settings["raid-x-offset"], "yOffset", Settings["raid-y-offset"],
		"maxColumns", Settings["raid-max-columns"], "unitsPerColumn", Settings["raid-units-per-column"],
		"columnSpacing", Settings["raid-column-spacing"], "columnAnchorPoint", Settings["raid-column-anchor"]}
	common.showSolo = Settings["raid-show-solo"]
	local Raid = self:CreateGroupHeader("HydraUI Raid", false, "raid", HeaderAttributes(common))
	local unitHeight, maxSize = Settings["raid-health-height"] + Settings["raid-power-height"] + 1, floor(40 / Settings["raid-max-columns"])
	self.RaidAnchor = CreateFrame("Frame", "HydraUI Raid Anchor", HydraUI.UIParent)
	self.RaidAnchor:SetSize(maxSize * Settings["raid-width"] + maxSize * Settings["raid-x-offset"] - 2,
		unitHeight * (Settings["raid-max-columns"] + 1) + Settings["raid-y-offset"] * (Settings["raid-max-columns"] - 1))
	self.RaidAnchor:SetPoint("BOTTOMLEFT", HydraUIChatFrameTop, "TOPLEFT", -3, 10)
	if CompactRaidFrameContainer then
		CompactRaidFrameContainer:UnregisterAllEvents(); CompactRaidFrameContainer:SetParent(Hider)
		CompactRaidFrameManager:UnregisterAllEvents(); CompactRaidFrameManager:SetParent(Hider)
	end
	Raid:SetPoint("BOTTOMLEFT", self.RaidAnchor)
	HydraUI:CreateMover(self.RaidAnchor)
	HydraUI.UnitFrames["raid"] = Raid
	UpdateRaidSortingMethod(Settings["raid-sorting-method"])

	if Settings["raid-pets-enable"] then
		local pet = {"initial-width", Settings["raid-pets-width"], "initial-height", Settings["raid-pets-health-height"] + 2,
			"isTesting", false, "showPlayer", true, "showParty", false, "showRaid", true,
			"point", Settings["raid-point"], "xOffset", Settings["raid-x-offset"], "yOffset", Settings["raid-y-offset"],
			"maxColumns", Settings["raid-max-columns"], "unitsPerColumn", Settings["raid-units-per-column"],
			"columnSpacing", Settings["raid-column-spacing"], "columnAnchorPoint", Settings["raid-column-anchor"]}
		pet.showSolo = Settings["raid-show-solo"]
		local RaidPet = self:CreateGroupHeader("HydraUI Raid Pets", true, "raid", HeaderAttributes(pet))
		self.RaidPetAnchor = CreateFrame("Frame", "HydraUI Raid Pet Anchor", HydraUI.UIParent)
		self.RaidPetAnchor:SetSize(maxSize * Settings["raid-width"] + maxSize * Settings["raid-x-offset"] - 2,
			Settings["raid-pets-health-height"] * (Settings["raid-max-columns"] + Settings["raid-y-offset"]) - 1)
		self.RaidPetAnchor:SetPoint("BOTTOMLEFT", self.RaidAnchor, "TOPLEFT")
		HydraUI:CreateMover(self.RaidPetAnchor)
		RaidPet:SetPoint("TOPLEFT", self.RaidPetAnchor)
		HydraUI.UnitFrames["raid-pets"] = RaidPet
	end
end

function UF:SpawnNameplates()
	if not Settings["nameplates-enable"] then
		return
	end
	UF.NamePlateCVars.nameplateSelectedAlpha = Settings["nameplates-selected-alpha"] / 100
	UF.NamePlateCVars.nameplateMinAlpha = Settings["nameplates-unselected-alpha"] / 100
	UF.NamePlateCVars.nameplateMaxAlpha = Settings["nameplates-unselected-alpha"] / 100
	UF:CreateNamePlateDriver()
end

--/run HydraUIFakeBosses()
HydraUIFakeBosses = function()
	local Boss

	for i = 1, 8 do
		Boss = HydraUI.UnitFrames["boss"..i]

		if not Boss:IsShown() then
			Boss.unit = "player"
			UnregisterUnitWatch(Boss)
			RegisterUnitWatch(Boss, true)
			Boss:Show()
		else
			Boss.unit = nil
			UnregisterUnitWatch(Boss)
			Boss:Hide()
		end
	end
end
end

ns.UnitFrameSpawning = Install
