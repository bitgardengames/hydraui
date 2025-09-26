local AddOn, Namespace = ... -- HydraUI was created on May 22, 2019

-- Data storage
local Assets = {}
local Settings = {}
local Defaults = {}
local Modules = {}
local Plugins = {}
local ModuleQueue = {}
local PluginQueue = {}

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
local ErrorHandler = geterrorhandler()
local xpcall = xpcall
local type = type
local wipe = wipe

local ReportError = function(context, err)
	ErrorHandler(format("HydraUI: %s - %s", context, err or "Unknown error"))
end

local SafeCall = function(context, func, ...)
	if (type(func) ~= "function") then
		return true
	end

	local Success = xpcall(func, function(errorMessage)
		ReportError(context, errorMessage)
		return errorMessage
	end, ...)

	return Success
end

HydraUI.UIVersion = GetAddOnMetadata("HydraUI", "Version")
HydraUI.UserName = UnitName("player")
HydraUI.UserClass = select(2, UnitClass("player"))
HydraUI.UserRace = UnitRace("player")
HydraUI.UserRealm = GetRealmName()
HydraUI.UserLocale = GetLocale()
HydraUI.UserProfileKey = format("%s:%s", HydraUI.UserName, HydraUI.UserRealm)
HydraUI.ClientVersion = select(4, GetBuildInfo())
HydraUI.IsClassic = HydraUI.ClientVersion > 10000 and HydraUI.ClientVersion < 20000
HydraUI.IsTBC = HydraUI.ClientVersion > 20000 and HydraUI.ClientVersion < 30000
HydraUI.IsWrath = HydraUI.ClientVersion > 30000 and HydraUI.ClientVersion < 40000
HydraUI.IsCata = HydraUI.ClientVersion > 40000 and HydraUI.ClientVersion < 50000
HydraUI.IsMists = HydraUI.ClientVersion > 50000 and HydraUI.ClientVersion < 60000
HydraUI.IsMainline = HydraUI.ClientVersion > 90000

if (HydraUI.UserLocale == "enGB") then
	HydraUI.UserLocale = "enUS"
end

-- Language
local Language = {}

local Index = function(self, key)
	return key
end

setmetatable(Language, {__index = Index})

-- Modules and plugins
function HydraUI:NewModule(name)
	local Module = self:GetModule(name)

	--print("NewModule:", name)

	if Module then
		return Module
	end

        Module = CreateFrame("Frame", "HydraUI " .. name, self.UIParent, "BackdropTemplate")
        Module.Name = name

        Modules[name] = Module

        ModuleQueue[#ModuleQueue + 1] = Module

        return Module
end

function HydraUI:GetModule(name)
	if Modules[name] then
		return Modules[name]
	end
end

function HydraUI:IterateModules()
	return next, Modules, nil
end

function HydraUI:HandleError(context, err)
	ReportError(context, err)
end

local BuildModuleContext = function(kind, object)
	return format("%s '%s'", kind, (object and object.Name) or "Unknown")
end

function HydraUI:LoadModules()
        local ModuleCount = #ModuleQueue

        for i = 1, ModuleCount do
                local Module = ModuleQueue[i]

                if (Module and Module.Load and not Module.Loaded) then
                        if SafeCall(BuildModuleContext("Module", Module), Module.Load, Module) then
                                Module.Loaded = true
                        end
                end
        end

        if (ModuleCount > 0) then
                wipe(ModuleQueue)
        end
end

function HydraUI:NewPlugin(name)
	local Plugin = self:GetPlugin(name)

	if Plugin then
		return
	end

	local Name, Title, Notes = GetAddOnInfo(name)
	local Author = GetAddOnMetadata(name, "Author")
	local Version = GetAddOnMetadata(name, "Version")

	Plugin = CreateFrame("Frame", name, self.UIParent, "BackdropTemplate")
	Plugin.Name = Name or name
	Plugin.Title = Title
	Plugin.Notes = Notes
	Plugin.Author = Author
	Plugin.Version = Version

	Plugins[name] = Plugin
	PluginQueue[#PluginQueue + 1] = Plugin

	return Plugin
end

function HydraUI:GetPlugin(name)
	if Plugins[name] then
		return Plugins[name]
	end
end

function HydraUI:IteratePlugins()
	return next, Plugins, nil
end

function HydraUI:LoadPlugins()
	if (#PluginQueue == 0) then
		return
	end

	for i = 1, #PluginQueue do
		local Plugin = PluginQueue[i]

		if (Plugin and Plugin.Load and not Plugin.Loaded) then
			if SafeCall(BuildModuleContext("Plugin", Plugin), Plugin.Load, Plugin) then
				Plugin.Loaded = true
			end
		end
	end

	self:GetModule("GUI"):AddWidgets(Language["Info"], Language["Plugins"], function(left, right)
		local Anchor

		for i = 1, #PluginQueue do
			if ((i % 2) == 0) then
				Anchor = right
			else
				Anchor = left
			end

			Anchor:CreateHeader(PluginQueue[i].Title)
			Anchor:CreateDoubleLine("", Language["Author"], PluginQueue[i].Author)
			Anchor:CreateDoubleLine("", Language["Version"], PluginQueue[i].Version)
			Anchor:CreateMessage("", PluginQueue[i].Notes)
		end
	end)
end

-- Events
function HydraUI:OnEvent(event)
	-- Import profile data and load a profile
	self:CreateProfileData()
	self:UpdateProfileList()
	self:ApplyProfile(self:GetActiveProfileName())

	self:UpdateColors()
	self:UpdateoUFColors()

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
