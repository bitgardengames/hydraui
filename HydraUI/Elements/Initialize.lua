local AddOn, Namespace = ... -- HydraUI was created on May 22, 2019

-- Data storage
local Assets = {}
local Settings = {}
local Defaults = {}
local Modules = {}
local Plugins = {}
local ModuleQueue = {}
local PluginQueue = {}
local ModuleQueueIndex = 0

-- Core functions and data
local HydraUI = CreateFrame("Frame", nil, UIParent)
HydraUI.Modules = Modules
HydraUI.Plugins = Plugins

HydraUI.UIParent = CreateFrame("Frame", "HydraUIParent", UIParent, "SecureHandlerStateTemplate")
HydraUI.UIParent:SetAllPoints(UIParent)
HydraUI.UIParent:SetFrameLevel(UIParent:GetFrameLevel())

-- Constants
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local GetAddOnInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo

HydraUI.UIVersion = GetAddOnMetadata("HydraUI", "Version")
HydraUI.UserName = UnitName("player")
HydraUI.UserClass = select(2, UnitClass("player"))
HydraUI.UserRace = UnitRace("player")
HydraUI.UserRealm = GetRealmName()
HydraUI.ClientLocale = GetLocale()
HydraUI.UserProfileKey = format("%s:%s", HydraUI.UserName, HydraUI.UserRealm)
HydraUI.ClientVersion = select(4, GetBuildInfo())

local IsMainlineProject = (WOW_PROJECT_ID and WOW_PROJECT_MAINLINE and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) or false

HydraUI.IsForever = IsMainlineProject and HydraUI.ClientVersion >= 16000 and HydraUI.ClientVersion < 20000
HydraUI.IsMidnight = IsMainlineProject and HydraUI.ClientVersion >= 120000 and HydraUI.ClientVersion < 130000
HydraUI.IsVanilla = (not HydraUI.IsForever) and HydraUI.ClientVersion > 10000 and HydraUI.ClientVersion < 20000
HydraUI.IsTBC = HydraUI.ClientVersion > 20000 and HydraUI.ClientVersion < 30000
HydraUI.IsWrath = HydraUI.ClientVersion > 30000 and HydraUI.ClientVersion < 40000
HydraUI.IsCata = HydraUI.ClientVersion > 40000 and HydraUI.ClientVersion < 50000
HydraUI.IsMists = HydraUI.ClientVersion > 50000 and HydraUI.ClientVersion < 60000
HydraUI.IsMainline = IsMainlineProject

if HydraUI.ClientLocale == "enGB" then
	HydraUI.ClientLocale = "enUS"
end

-- Language
local Language = {}

local Index = function(self, key)
	return key
end

setmetatable(Language, {__index = Index})

HydraUI.Languages = {
	["enUS"] = "English",
	["deDE"] = "Deutsch",
	["esES"] = "Espa\195\177ol (Espa\195\177a)",
	["esMX"] = "Espa\195\177ol (Latinoam\195\169rica)",
	["frFR"] = "Fran\195\167ais",
	["itIT"] = "Italiano",
	["koKR"] = "\237\149\156\234\181\173\236\150\180",
	["ptBR"] = "Portugu\195\170s (Brasil)",
	["ruRU"] = "\208\160\209\131\209\129\209\129\208\186\208\184\208\185",
	["zhCN"] = "\231\174\128\228\189\147\228\184\173\230\150\135",
	["zhTW"] = "\231\185\129\233\171\148\228\184\173\230\150\135",
}

HydraUI.UserLocale = HydraUI.ClientLocale

if type(HydraUIProfileData) == "table" and type(HydraUIProfiles) == "table" then
	local ProfileName = HydraUIProfileData[HydraUI.UserProfileKey]
	local Profile = ProfileName and HydraUIProfiles[ProfileName]
	local Locale = Profile and Profile["ui-language"]

	if HydraUI.Languages[Locale] then
		HydraUI.UserLocale = Locale
	end
end

function HydraUI:GetLanguageList()
	local Languages = {}

	for Locale, Name in pairs(self.Languages) do
		Languages[Name] = Locale
	end

	return Languages
end

-- Modules and plugins
function HydraUI:NewModule(name)
	local Module = Modules[name]

	--print("NewModule:", name)

	if Module then
		return Module
	end

	Module = CreateFrame("Frame", "HydraUI " .. name, self.UIParent, "BackdropTemplate")
	Module.Name = name

	Modules[name] = Module

	ModuleQueueIndex = ModuleQueueIndex + 1
	ModuleQueue[ModuleQueueIndex] = Module

	return Module
end

function HydraUI:GetModule(name)
	return Modules[name]
end

function HydraUI:LoadModules()
	for i = 1, #ModuleQueue do
		local Module = ModuleQueue[i]

		if Module.Load and not Module.Loaded then
			Module:Load()
			Module.Loaded = true
		end
	end
end

function HydraUI:NewPlugin(name)
	local Plugin = Plugins[name]

	if Plugin then
		return
	end

	local Name, Title, Notes = GetAddOnInfo(name)
	local Author = GetAddOnMetadata(name, "Author")
	local Version = GetAddOnMetadata(name, "Version")

	Plugin = CreateFrame("Frame", name, self.UIParent, "BackdropTemplate")
	Plugin.Name = Name
	Plugin.Title = Title
	Plugin.Notes = Notes
	Plugin.Author = Author
	Plugin.Version = Version

	Plugins[name] = Plugin
	PluginQueue[#PluginQueue + 1] = Plugin

	return Plugin
end

function HydraUI:GetPlugin(name)
	return Plugins[name]
end

function HydraUI:LoadPlugins()
	if #PluginQueue == 0 then
		return
	end

	for i = 1, #PluginQueue do
		local Plugin = PluginQueue[i]

		if Plugin.Load then
			Plugin:Load()
		end
	end

	self:GetModule("GUI"):AddWidgets(Language["Info"], Language["Plugins"], function(left, right)
		local Anchor

		for i = 1, #PluginQueue do
			local Plugin = PluginQueue[i]

			if (i % 2) == 0 then
				Anchor = right
			else
				Anchor = left
			end

			Anchor:CreateHeader(Plugin.Title)
			Anchor:CreateDoubleLine("", Language["Author"], Plugin.Author)
			Anchor:CreateDoubleLine("", Language["Version"], Plugin.Version)
			Anchor:CreateMessage("", Plugin.Notes)
		end
	end)
end

-- Events
function HydraUI:OnEvent(event)
	--[[if (HydraUI.ClientVersion >= 20000) then
		print(Language["HydraUI is not supported for this version of World of Warcraft"])

		return
	end]]

	-- Import profile data and load a profile
	self:CreateProfileData()
	self:UpdateProfileList()
	self:ApplyProfile(self:GetActiveProfileName())

	self:UpdateColors()
	self:UpdateUnitFrameColors()

	self:WelcomeMessage()

	self:LoadSharedAssets()

	self:LoadModules()
	self:LoadPlugins()

	self:UnregisterEvent(event)
end

HydraUI:RegisterEvent("PLAYER_ENTERING_WORLD")
HydraUI:SetScript("OnEvent", HydraUI.OnEvent)

-- Access data tables
function Namespace:get()
	return HydraUI, Language, Assets, Settings, Defaults
end

-- Global access
_G.HydraUIGlobal = Namespace
