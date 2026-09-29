local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["party-enable"] = true
Defaults["party-width"] = 78
Defaults["party-show-debuffs"] = true
Defaults["party-show-role"] = true
Defaults["party-show-aurawatch"] = true
Defaults["party-in-range"] = 100
Defaults["party-out-of-range"] = 50
Defaults["party-health-height"] = 42 -- 40
Defaults["party-health-reverse"] = false
Defaults["party-health-color"] = "CLASS"
Defaults["party-health-orientation"] = "HORIZONTAL"
Defaults["party-health-top"] = "[Name(10)]"
Defaults["party-health-bottom"] = "[HealthDeficit:Short]"
Defaults["party-health-smooth"] = true
Defaults["party-power-enable"] = true
Defaults["party-power-height"] = 6
Defaults["party-power-reverse"] = false
Defaults["party-power-color"] = "POWER"
Defaults["party-power-smooth"] = true
Defaults["party-point"] = "LEFT"
Defaults["party-spacing"] = 2
Defaults["party-show-solo"] = false
Defaults["party-font"] = "Roboto"
Defaults["party-font-size"] = 12
Defaults["party-font-flags"] = ""
Defaults.PartyHealthTexture = "HydraUI 4"
Defaults.PartyPowerTexture = "HydraUI 4"
Defaults.PartyEnableMouseover = true

local UF = HydraUI:GetModule("Unit Frames")

local PartyDebuffFilter = function(self, unit, icon, name, texture, count, dtype, duration, timeLeft, caster, stealable, nameplateshow, id)
	local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(id, "RAID_INCOMBAT")
	return not hasCustom or showForMySpec or (alwaysShowMine and (caster == "player" or caster == "pet" or caster == "vehicle"))
end

local function CreatePartyDebuffs(frame, health, filter)
	local horizontal = Settings["party-point"] == "LEFT" or Settings["party-point"] == "RIGHT"
	return UF:CreateAuraContainer(frame, {
		name = frame:GetName().."Debuffs",
		parent = health,
		iconSize = 24,
		spacing = 1,
		num = horizontal and 3 or 6,
		initialAnchor = horizontal and "BOTTOMLEFT" or "TOPLEFT",
		tooltipAnchor = "ANCHOR_TOP",
		growthX = "RIGHT",
		growthY = horizontal and nil or "DOWN",
		size = {
			width = 24*3+4,
			height = horizontal and 24 or 50,
		},
		anchor = {
			point = horizontal and "BOTTOMLEFT" or "TOPLEFT",
			relativeTo = frame,
			relativePoint = horizontal and "TOPLEFT" or "TOPRIGHT",
			x = horizontal and 0 or 2,
			y = horizontal and 2 or 0,
		},
		callbacks = {
			postCreateIcon = UF.PostCreateIcon,
			postUpdateIcon = UF.PostUpdateIcon,
			customFilter = filter,
		},
	})
end

local PartyGroup = {
	prefix = "party", header = "party", petHeader = "party-pets",
	healthTextureKey = "PartyHealthTexture", powerTextureKey = "PartyPowerTexture", mouseoverKey = "PartyEnableMouseover",
	debuffFilter = PartyDebuffFilter, createDebuffs = CreatePartyDebuffs, dispelSize = 20, dispelAboveDebuffs = true,
	indicators = { auraWatch = true, role = Settings["party-show-role"], leaderX = 0, phasePoint = "TOPRIGHT" }, testStart = -4,
}
HydraUI.StyleFuncs["party"] = function(frame, unit) UF:BuildGroupFrame(frame, unit, PartyGroup) end

local function Update(operation, value) UF:UpdateGroupFrames(PartyGroup, operation, value) end
local function UpdatePartyWidth(value) Update("width",value) end
local function UpdatePartyHealthHeight(value) Update("healthHeight",value) end
local function UpdatePartyHealthColor(value) Update("healthColor",value) end
local function UpdatePartyHealthReverseFill(value) Update("healthReverse",value) end
local function UpdateEnablePartyPower(value) Update("powerEnabled",value) end
local function UpdatePartyPowerHeight(value) Update("powerHeight",value) end
local function UpdatePartyPowerReverseFill(value) Update("powerReverse",value) end
local function UpdatePartyPowerColor(value) Update("powerColor",value) end
local function UpdatePartyShowDebuffs(value) Update("debuffs",value) end
local function UpdatePartyShowHighlight(value) Update("highlight",value) end
local function UpdatePartyShowRole(value) Update("role",value) end
local function UpdateHealthTexture(value) Update("healthTexture",value) end
local function UpdatePowerTexture(value) Update("powerTexture",value) end
local function TestParty() UF:ToggleGroupTest(PartyGroup) end
local function UpdateShowSolo(value) _G["HydraUI Party"]:SetAttribute("showSolo",value) end
local function SetSpacing(header, value, point)
	local x, y = 0, 0
	if point == "LEFT" then x=value elseif point == "RIGHT" then x=-value elseif point == "TOP" then y=-value else y=value end
	header:SetAttribute("xOffset",x); header:SetAttribute("yOffset",y)
end
local function UpdatePartySpacing(value)
	local header=HydraUI.UnitFrames["party"]
	if header then local point=header:GetAttribute("point"); SetSpacing(header,value,point); if HydraUI.UnitFrames["party-pets"] then SetSpacing(HydraUI.UnitFrames["party-pets"],value,point) end end
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Party"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("party-enable", Settings["party-enable"], Language["Enable Party Module"], Language["Enable the party frames module"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Party Size"])
	left:CreateSlider("party-width", Settings["party-width"], 40, 200, 1, Language["Width"], Language["Set the width of the party frames"], UpdatePartyWidth)

	left:CreateHeader(Language["Font"])
	left:CreateDropdown("party-font", Settings["party-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the party frames"], nil, "Font")
	left:CreateSlider("party-font-size", Settings["party-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the party frames"])
	left:CreateDropdown("party-font-flags", Settings["party-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the party frames"])

	right:CreateHeader(Language["Test Party Frames"])
	right:CreateButton("", Language["Test"], Language["Test Party"], Language["Test the party frames"], TestParty)

	right:CreateHeader(Language["Health"])
	right:CreateSlider("party-health-height", Settings["party-health-height"], 12, 60, 1, Language["Health Height"], Language["Set the height of party health bars"], UpdatePartyHealthHeight)
	right:CreateDropdown("party-health-color", Settings["party-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdatePartyHealthColor)
	right:CreateSwitch("party-health-reverse", Settings["party-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdatePartyHealthReverseFill)
	right:CreateDropdown("PartyHealthTexture", Settings.PartyHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("party-power-enable", Settings["party-power-enable"], Language["Enable Power Bar"], Language["Enable the power bar"], UpdateEnablePartyPower)
	right:CreateSwitch("party-power-reverse", Settings["party-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdatePartyPowerReverseFill)
	right:CreateSlider("party-power-height", Settings["party-power-height"], 2, 30, 1, Language["Power Height"], Language["Set the height of party power bars"], UpdatePartyPowerHeight)
	right:CreateDropdown("party-power-color", Settings["party-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdatePartyPowerColor)
	right:CreateDropdown("PartyPowerTexture", Settings.PartyPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Text"])
	right:CreateInput("party-health-top", Settings["party-health-top"], Language["Top Text"], Language["Set the text on the top of the party frame"], ReloadUI):RequiresReload(true)
	right:CreateInput("party-health-bottom", Settings["party-health-bottom"], Language["Bottom Text"], Language["Set the text on the bottom of the party frame"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Styling"])
	left:CreateSwitch("party-show-debuffs", Settings["party-show-debuffs"], Language["Enable Debuffs"], Language["Display debuffs on party members"], UpdatePartyShowDebuffs)
	--left:CreateSwitch("party-show-role", Settings["party-show-role"], Language["Enable Role Icons"], Language["Display role icons on party members"], UpdatePartyShowRole)
	left:CreateSwitch("party-show-role", Settings["party-show-role"], Language["Enable Role Icons"], Language["Display role icons on party members"], ReloadUI):RequiresReload(true)
	left:CreateSwitch("PartyEnableMouseover", Settings.PartyEnableMouseover, Language["Enable Mouseover"], Language["Enable a mouseover highlight on party members"], UpdatePartyShowHighlight)

	left:CreateHeader(Language["Range Opacity"])
	left:CreateSlider("party-in-range", Settings["party-in-range"], 0, 100, 5, Language["In Range"], Language["Set the opacity of party members within range of you"])
	left:CreateSlider("party-out-of-range", Settings["party-out-of-range"], 0, 100, 5, Language["Out of Range"], Language["Set the opacity of party members out of your range"])

	left:CreateHeader(Language["Attributes"])
	left:CreateSwitch("party-show-solo", Settings["party-show-solo"], Language["Show Solo"], Language["Display the frames while not in a group"], UpdateShowSolo)
	left:CreateDropdown("party-point", Settings["party-point"], {[Language["Left"]] = "LEFT", [Language["Right"]] = "RIGHT", [Language["Top"]] = "TOP", [Language["Bottom"]] = "BOTTOM"}, Language["Anchor Point"], Language["Set the anchor point for the party frames"], ReloadUI):RequiresReload(true)
	left:CreateSlider("party-spacing", Settings["party-spacing"], -10, 10, 1, Language["Set Spacing"], Language["Set the spacing of party units from eachother"], UpdatePartySpacing)
end)