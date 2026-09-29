local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

Defaults["raid-enable"] = true
Defaults["raid-width"] = 78
Defaults["raid-in-range"] = 100
Defaults["raid-out-of-range"] = 50
Defaults["raid-health-height"] = 42
Defaults["raid-health-reverse"] = false
Defaults["raid-health-color"] = "CLASS"
Defaults["raid-health-orientation"] = "HORIZONTAL"
Defaults["raid-health-top"] = "[Name(10)]"
Defaults["raid-health-bottom"] = "[HealthDeficit:Short]"
Defaults["raid-health-smooth"] = true
Defaults["raid-power-enable"] = false
Defaults["raid-power-height"] = 2
Defaults["raid-power-reverse"] = false
Defaults["raid-power-color"] = "POWER"
Defaults["raid-power-smooth"] = true
Defaults["raid-x-offset"] = 2
Defaults["raid-y-offset"] = -2
Defaults["raid-units-per-column"] = 5
Defaults["raid-max-columns"] = 8
Defaults["raid-column-spacing"] = 2
Defaults["raid-point"] = "LEFT"
Defaults["raid-column-anchor"] = "TOP"
Defaults["raid-sorting-method"] = "GROUP"
Defaults["raid-show-solo"] = false
Defaults["raid-font"] = "Roboto"
Defaults["raid-font-size"] = 12
Defaults["raid-font-flags"] = ""
Defaults.RaidHealthTexture = "HydraUI 4"
Defaults.RaidPowerTexture = "HydraUI 4"
Defaults.RaidEnableMouseover = true

local UF = HydraUI:GetModule("Unit Frames")

local Ignore = {}
if HydraUI.IsWrath then Ignore[GetSpellInfo(69127)] = true end
local RaidDebuffFilter = function(self, unit, icon, name, texture, count, dtype, duration, timeLeft, caster, stealable, nameplateshow, id, canapply, boss, player)
	if Ignore[name] then return false end
	return boss or (count and count > 0) or (duration > 0 and timeLeft and not player and not canapply)
end
local function CreateRaidDebuffs(frame, health, filter)
	return UF:CreateAuraContainer(frame,frame:GetName().."Debuffs",health,24,24,"CENTER",health,"CENTER",nil,nil,24,0,1,"TOPLEFT","ANCHOR_TOP","RIGHT","DOWN",UF.PostCreateIcon,UF.PostUpdateIcon,filter)
end
local function UpdateRaidAnchorSize()
	if not UF.RaidAnchor then return end
	UF.RaidAnchor:SetWidth(floor(40/Settings["raid-max-columns"])*Settings["raid-width"]+(floor(40/Settings["raid-max-columns"])*Settings["raid-x-offset"]-2))
	UF.RaidAnchor:SetHeight((Settings["raid-health-height"]+Settings["raid-power-height"])*(Settings["raid-max-columns"]+Settings["raid-y-offset"])-1)
end
local RaidGroup = {
	prefix="raid", header="raid", petHeader="raid-pets", healthTextureKey="RaidHealthTexture", powerTextureKey="RaidPowerTexture", mouseoverKey="RaidEnableMouseover",
	debuffFilter=RaidDebuffFilter, createDebuffs=CreateRaidDebuffs, dispelSize=22,
	indicators={ auraWatch=true, role=true, leaderX=3, phasePoint="LEFT" }, testStart=-24,
	afterUpdate=function(operation) if operation=="width" or operation=="healthHeight" or operation=="powerHeight" then UpdateRaidAnchorSize() end end,
}
HydraUI.StyleFuncs["raid"] = function(frame, unit) UF:BuildGroupFrame(frame, unit, RaidGroup) end
local function Update(operation,value) UF:UpdateGroupFrames(RaidGroup,operation,value) end
local function UpdateRaidWidth(v) Update("width",v) end
local function UpdateRaidHealthHeight(v) Update("healthHeight",v) end
local function UpdateRaidHealthColor(v) Update("healthColor",v) end
local function UpdateRaidHealthOrientation(v) Update("healthOrientation",v) end
local function UpdateRaidHealthReverseFill(v) Update("healthReverse",v) end
local function UpdateEnableRaidPower(v) Update("powerEnabled",v) end
local function UpdateRaidPowerHeight(v) Update("powerHeight",v) end
local function UpdateRaidPowerReverseFill(v) Update("powerReverse",v) end
local function UpdateRaidPowerColor(v) Update("powerColor",v) end
local function UpdateRaidShowHighlight(v) Update("highlight",v) end
local function UpdateHealthTexture(v) Update("healthTexture",v) end
local function UpdatePowerTexture(v) Update("powerTexture",v) end
local function TestRaid() UF:ToggleGroupTest(RaidGroup) end
local function UpdateShowSolo(v) _G["HydraUI Raid"]:SetAttribute("showSolo",v) end
local function SetRaidAttribute(attribute,value) HydraUI.UnitFrames["raid"]:SetAttribute(attribute,value); UpdateRaidAnchorSize() end
local function UpdateRaidXOffset(v) SetRaidAttribute("xoffset",v) end
local function UpdateRaidYOffset(v) SetRaidAttribute("yoffset",v) end
local function UpdateRaidUnitsPerColumn(v) SetRaidAttribute("unitsPerColumn",v) end
local function UpdateRaidMaxColumns(v) SetRaidAttribute("maxColumns",v) end
local function UpdateRaidColumnSpacing(v) SetRaidAttribute("columnSpacing",v) end
local function UpdateRaidColumnAnchor(v) SetRaidAttribute("columnAnchorPoint",v) end
local function UpdateRaidPoint(v) SetRaidAttribute("point",v) end
local function UpdateRaidSortingMethod(value)
	local header = HydraUI.UnitFrames["raid"]
	if value == "CLASS" then
		header:SetAttribute("groupingOrder", "DEATHKNIGHT,DEMONHUNTER,DRUID,HUNTER,MAGE,MONK,PALADIN,PRIEST,SHAMAN,WARLOCK,WARRIOR"); header:SetAttribute("sortMethod", "NAME"); header:SetAttribute("groupBy", "CLASS")
	elseif value == "ROLE" then
		header:SetAttribute("groupingOrder", "TANK,HEALER,DAMAGER,NONE"); header:SetAttribute("sortMethod", "NAME"); header:SetAttribute("groupBy", "ASSIGNEDROLE")
	elseif value == "NAME" then
		header:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8"); header:SetAttribute("sortMethod", "NAME"); header:SetAttribute("groupBy", nil)
	elseif value == "MTMA" then
		header:SetAttribute("groupingOrder", "MAINTANK,MAINASSIST,NONE"); header:SetAttribute("sortMethod", "NAME"); header:SetAttribute("groupBy", "ROLE")
	else
		header:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8"); header:SetAttribute("sortMethod", "INDEX"); header:SetAttribute("groupBy", "GROUP")
	end
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Raid"], Language["Unit Frames"], function(left, right)
	left:CreateHeader(Language["Enable"])
	left:CreateSwitch("raid-enable", Settings["raid-enable"], Language["Enable Raid Module"], Language["Enable the raid frames module"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Raid Size"])
	left:CreateSlider("raid-width", Settings["raid-width"], 40, 200, 1, Language["Width"], Language["Set the width of the raid frames"], UpdateRaidWidth, nil)

	left:CreateHeader(Language["Font"])
	left:CreateDropdown("raid-font", Settings["raid-font"], Assets:GetFontList(), Language["Font"], Language["Set the font of the raid frames"], nil, "Font")
	left:CreateSlider("raid-font-size", Settings["raid-font-size"], 8, 32, 1, Language["Font Size"], Language["Set the font size of the raid frames"])
	left:CreateDropdown("raid-font-flags", Settings["raid-font-flags"], Assets:GetFlagsList(), Language["Font Flags"], Language["Set the font flags of the raid frames"])

	right:CreateHeader(Language["Test Raid Frames"])
	right:CreateButton("", Language["Test"], Language["Test Raid"], Language["Test the raid frames"], TestRaid)

	right:CreateHeader(Language["Health"])
	right:CreateSlider("raid-health-height", Settings["raid-health-height"], 12, 60, 1, Language["Health Height"], Language["Set the height of raid health bars"], UpdateRaidHealthHeight)
	right:CreateDropdown("raid-health-color", Settings["raid-health-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Custom"]] = "CUSTOM"}, Language["Health Bar Color"], Language["Set the color of the health bar"], UpdateRaidHealthColor)
	right:CreateDropdown("raid-health-orientation", Settings["raid-health-orientation"], {[Language["Horizontal"]] = "HORIZONTAL", [Language["Vertical"]] = "VERTICAL"}, Language["Fill Orientation"], Language["Set the fill orientation of the health bar"], UpdateRaidHealthOrientation)
	right:CreateSwitch("raid-health-reverse", Settings["raid-health-reverse"], Language["Reverse Health Fill"], Language["Reverse the fill of the health bar"], UpdateRaidHealthReverseFill)
	right:CreateDropdown("RaidHealthTexture", Settings.RaidHealthTexture, Assets:GetTextureList(), Language["Health Texture"], "", UpdateHealthTexture, "Texture")

	right:CreateHeader(Language["Power"])
	right:CreateSwitch("raid-power-enable", Settings["raid-power-enable"], Language["Enable Power Bar"], Language["Enable the power bar"], UpdateEnableRaidPower)
	right:CreateSwitch("raid-power-reverse", Settings["raid-power-reverse"], Language["Reverse Power Fill"], Language["Reverse the fill of the power bar"], UpdateRaidPowerReverseFill)
	right:CreateSlider("raid-power-height", Settings["raid-power-height"], 2, 30, 1, Language["Power Height"], Language["Set the height of raid power bars"], UpdateRaidPowerHeight)
	right:CreateDropdown("raid-power-color", Settings["raid-power-color"], {[Language["Class"]] = "CLASS", [Language["Reaction"]] = "REACTION", [Language["Power Type"]] = "POWER"}, Language["Power Bar Color"], Language["Set the color of the power bar"], UpdateRaidPowerColor)
	right:CreateDropdown("RaidPowerTexture", Settings.RaidPowerTexture, Assets:GetTextureList(), Language["Power Texture"], "", UpdatePowerTexture, "Texture")

	right:CreateHeader(Language["Text"])
	right:CreateInput("raid-health-top", Settings["raid-health-top"], Language["Top Text"], Language["Set the text on the top of the raid frame"], ReloadUI):RequiresReload(true)
	right:CreateInput("raid-health-bottom", Settings["raid-health-bottom"], Language["Bottom Text"], Language["Set the text on the bottom of the raid frame"], ReloadUI):RequiresReload(true)

	left:CreateHeader(Language["Range Opacity"])
	left:CreateSlider("raid-in-range", Settings["raid-in-range"], 0, 100, 5, Language["In Range"], Language["Set the opacity of raid members within range of you"])
	left:CreateSlider("raid-out-of-range", Settings["raid-out-of-range"], 0, 100, 5, Language["Out of Range"], Language["Set the opacity of raid members out of your range"])

	left:CreateHeader(Language["Attributes"])
	left:CreateSwitch("raid-show-solo", Settings["raid-show-solo"], Language["Show Solo"], Language["Display the raid frames while not in a group"], UpdateShowSolo)
	left:CreateSlider("raid-x-offset", Settings["raid-x-offset"], -10, 10, 1, Language["X Offset"], Language["Set the x offset of raid units from eachother"], UpdateRaidXOffset)
	left:CreateSlider("raid-y-offset", Settings["raid-y-offset"], -10, 10, 1, Language["Y Offset"], Language["Set the y offset of raid units from eachother"], UpdateRaidYOffset)
	left:CreateSlider("raid-units-per-column", Settings["raid-units-per-column"], 1, 40, 1, Language["Units Per Column"], Language["Set the maximum number of units per column"], UpdateRaidUnitsPerColumn)
	left:CreateSlider("raid-max-columns", Settings["raid-max-columns"], 1, 40, 1, Language["Max Columns"], Language["Set the maximum number of visible columns of raid units"], UpdateRaidMaxColumns)
	left:CreateSlider("raid-column-spacing", Settings["raid-column-spacing"], -10, 10, 1, Language["Column Spacing"], Language["Set the spacing between columns of raid units"], UpdateRaidColumnSpacing)
	left:CreateDropdown("raid-sorting-method", Settings["raid-sorting-method"], {[Language["Group"]] = "GROUP", [Language["Name"]] = "NAME", [Language["Class"]] = "CLASS", [Language["Role"]] = "ROLE", [Language["Main Tank"]] = "MTMA"}, Language["Sorting Method"], Language["Set how the raid units are sorted"], UpdateRaidSortingMethod)
	left:CreateDropdown("raid-point", Settings["raid-point"], {[Language["Left"]] = "LEFT", [Language["Right"]] = "RIGHT", [Language["Top"]] = "TOP", [Language["Bottom"]] = "BOTTOM"}, Language["Anchor Point"], Language["Set where new raid frames will connect to previous ones"], UpdateRaidPoint)
	left:CreateDropdown("raid-column-anchor", Settings["raid-column-anchor"], {[Language["Left"]] = "LEFT", [Language["Right"]] = "RIGHT", [Language["Top"]] = "TOP", [Language["Bottom"]] = "BOTTOM"}, Language["New Column Anchor"], Language["Set where new columns should anchor to"], ReloadUI):RequiresReload(true)
	left:CreateSwitch("RaidEnableMouseover", Settings.RaidEnableMouseover, Language["Enable Mouseover"], Language["Enable a mouseover highlight on raid members"], UpdateRaidShowHighlight)
end)
