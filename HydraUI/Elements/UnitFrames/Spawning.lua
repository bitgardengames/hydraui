local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()

local oUF = ns.oUF or oUF
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

function UF:SpawnPartyHeaders()
	if Settings["party-enable"] then
		local XOffset, YOffset = self:GetGrowthOffsets(Settings["party-point"], Settings["party-spacing"])

		local Party = oUF:SpawnHeader("HydraUI Party", nil, "party,solo",
			"initial-width", Settings["party-width"],
			"initial-height", (Settings["party-health-height"] + Settings["party-power-height"] + 3),
			"isTesting", false,
			"showSolo", Settings["party-show-solo"],
			"showPlayer", true,
			"showParty", true,
			"showRaid", false,
			"xOffset", XOffset,
			"yOffset", YOffset,
			"point", Settings["party-point"],
			"oUF-initialConfigFunction", [[
				local Header = self:GetParent()

				self:SetWidth(Header:GetAttribute("initial-width"))
				self:SetHeight(Header:GetAttribute("initial-height"))
			]]
		)

		self.PartyAnchor = CreateFrame("Frame", "HydraUI Party Anchor", HydraUI.UIParent)
		self.PartyAnchor:SetSize((5 * Settings["party-width"] + (4 * Settings["party-spacing"])), (Settings["party-health-height"] + Settings["party-power-height"]) + 3)
		self.PartyAnchor:SetPoint("BOTTOMLEFT", HydraUIChatFrameTop, "TOPLEFT", -3, 5)

		Party:SetPoint("BOTTOMLEFT", self.PartyAnchor, 0, 0)
		Party:SetParent(HydraUI.UIParent)

		HydraUI.UnitFrames["party"] = Party

		--UpdatePartyShowRole(Settings["party-show-role"])

		HydraUI:CreateMover(self.PartyAnchor)

		if Settings["party-pets-enable"] then
			local XOffset, YOffset = self:GetGrowthOffsets(Settings["party-point"], Settings["party-spacing"])

			local PartyPet = oUF:SpawnHeader("HydraUI Party Pets", "SecureGroupPetHeaderTemplate", "party,solo",
				"initial-width", Settings["party-pets-width"],
				"initial-height", (Settings["party-pets-health-height"] + 2),
				"showSolo", Settings["party-show-solo"],
				"showPlayer", false,
				"showParty", true,
				"showRaid", false,
				"xOffset", XOffset,
				"yOffset", YOffset,
				"point", Settings["party-point"],
				"oUF-initialConfigFunction", [[
					local Header = self:GetParent()

					self:SetWidth(Header:GetAttribute("initial-width"))
					self:SetHeight(Header:GetAttribute("initial-height"))
				]]
			)

			self.PartyPetAnchor = CreateFrame("Frame", "HydraUI Party Pet Anchor", HydraUI.UIParent)
			self.PartyPetAnchor:SetSize((5 * Settings["party-width"] + (4 * Settings["party-spacing"])), Settings["party-pets-health-height"] + 2)
			self.PartyPetAnchor:SetPoint("TOPLEFT", self.PartyAnchor, "BOTTOMLEFT", 0, -2)

			PartyPet:SetPoint("TOPLEFT", self.PartyPetAnchor, 0, 0)
			PartyPet:SetParent(HydraUI.UIParent)

			HydraUI:CreateMover(self.PartyPetAnchor)

			HydraUI.UnitFrames["party-pets"] = PartyPet
		end
	end

end

function UF:SpawnRaidHeaders()
	if Settings["raid-enable"] then
		local Raid = oUF:SpawnHeader("HydraUI Raid", nil, "raid,solo",
			"initial-width", Settings["raid-width"],
			"initial-height", (Settings["raid-health-height"] + Settings["raid-power-height"] + 3),
			"isTesting", false,
			"showSolo", Settings["raid-show-solo"],
			"showPlayer", true,
			"showParty", false,
			"showRaid", true,
			"point", Settings["raid-point"],
			"xoffset", Settings["raid-x-offset"],
			"yOffset", Settings["raid-y-offset"],
			"maxColumns", Settings["raid-max-columns"],
			"unitsPerColumn", Settings["raid-units-per-column"],
			"columnSpacing", Settings["raid-column-spacing"],
			"columnAnchorPoint", Settings["raid-column-anchor"],
			"oUF-initialConfigFunction", [[
				local Header = self:GetParent()

				self:SetWidth(Header:GetAttribute("initial-width"))
				self:SetHeight(Header:GetAttribute("initial-height"))
			]]
		)

		local UnitHeight = (Settings["raid-health-height"] + Settings["raid-power-height"]) + 1
		local MaxSize = floor(40 / Settings["raid-max-columns"])

		self.RaidAnchor = CreateFrame("Frame", "HydraUI Raid Anchor", HydraUI.UIParent)
		self.RaidAnchor:SetWidth((MaxSize * Settings["raid-width"] + (MaxSize * Settings["raid-x-offset"] - 2)))
		self.RaidAnchor:SetHeight(UnitHeight * (Settings["raid-max-columns"] + 1) + (Settings["raid-y-offset"] * (Settings["raid-max-columns"] - 1)))
		self.RaidAnchor:SetPoint("BOTTOMLEFT", HydraUIChatFrameTop, "TOPLEFT", -3, 10)

		if CompactRaidFrameContainer then
			CompactRaidFrameContainer:UnregisterAllEvents()
			CompactRaidFrameContainer:SetParent(Hider)

			CompactRaidFrameManager:UnregisterAllEvents()
			CompactRaidFrameManager:SetParent(Hider)
		end

		Raid:SetPoint("BOTTOMLEFT", self.RaidAnchor, 0, 0)
		Raid:SetParent(HydraUI.UIParent)

		HydraUI:CreateMover(self.RaidAnchor)

		HydraUI.UnitFrames["raid"] = Raid

		UpdateRaidSortingMethod(Settings["raid-sorting-method"])

		if Settings["raid-pets-enable"] then
			local RaidPet = oUF:SpawnHeader("HydraUI Raid Pets", "SecureGroupPetHeaderTemplate", "raid,solo",
			"initial-width", Settings["raid-pets-width"],
			"initial-height", (Settings["raid-pets-health-height"] + 2),
			"isTesting", false,
			"showSolo", Settings["raid-show-solo"],
			"showPlayer", true,
			"showParty", false,
			"showRaid", true,
			"point", Settings["raid-point"],
			"xoffset", Settings["raid-x-offset"],
			"yOffset", Settings["raid-y-offset"],
			"maxColumns", Settings["raid-max-columns"],
			"unitsPerColumn", Settings["raid-units-per-column"],
			"columnSpacing", Settings["raid-column-spacing"],
			"columnAnchorPoint", Settings["raid-column-anchor"],
			"oUF-initialConfigFunction", [[
				local Header = self:GetParent()

				self:SetWidth(Header:GetAttribute("initial-width"))
				self:SetHeight(Header:GetAttribute("initial-height"))
			]]
			)

			self.RaidPetAnchor = CreateFrame("Frame", "HydraUI Raid Pet Anchor", HydraUI.UIParent)
			self.RaidPetAnchor:SetWidth((floor(40 / Settings["raid-max-columns"]) * Settings["raid-width"] + (floor(40 / Settings["raid-max-columns"]) * Settings["raid-x-offset"] - 2)))
			self.RaidPetAnchor:SetHeight(Settings["raid-pets-health-height"] * (Settings["raid-max-columns"] + (Settings["raid-y-offset"])) - 1)
			self.RaidPetAnchor:SetPoint("BOTTOMLEFT", self.RaidAnchor, "TOPLEFT", 0, 0)

			HydraUI:CreateMover(self.RaidPetAnchor)

			RaidPet:SetPoint("TOPLEFT", self.RaidPetAnchor, 0, 0)
			RaidPet:SetParent(HydraUI.UIParent)

			HydraUI.UnitFrames["raid-pets"] = RaidPet
		end
	end

end

function UF:SpawnNameplates()
	if Settings["nameplates-enable"] then
		UF.NamePlateCVars.nameplateSelectedAlpha = (Settings["nameplates-selected-alpha"] / 100)
		UF.NamePlateCVars.nameplateMinAlpha = (Settings["nameplates-unselected-alpha"] / 100)
		UF.NamePlateCVars.nameplateMaxAlpha = (Settings["nameplates-unselected-alpha"] / 100)

		oUF:SpawnNamePlates(nil, UF.NamePlateCallback, UF.NamePlateCVars)
	end
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
