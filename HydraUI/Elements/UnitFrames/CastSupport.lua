local addon, ns = ...
local HydraUI, Language, Assets, Settings, Defaults = ns:get()

local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local Class, Colors

local function Install(UF, Hider)
local CastImplementation = ns.UnitFrameOUFBridge.elements.Castbar
local ActiveCastbars = setmetatable({}, {__mode = "k"})
local CastUpdater = CreateFrame("Frame")

-- All HydraUI castbars are advanced by this one driver.  The selected oUF
-- implementation still owns client-specific event handling and field setup.
CastUpdater:SetScript("OnUpdate", function(_, elapsed)
	for castbar, update in pairs(ActiveCastbars) do
		update(castbar, elapsed)
	end
end)

local function ClearCastbar(frame)
	local castbar = frame.Castbar
	if not castbar then
		return
	end
	castbar.casting = nil
	castbar.channeling = nil
	castbar.empowering = nil
	castbar.castID = nil
	castbar.spellID = nil
	castbar.holdTime = 0
	castbar:Hide()
end

if CastImplementation then
	ns.UnitFrameCastComponent = {
		update = CastImplementation.update,
		enable = function(frame, unit)
			if not CastImplementation.enable(frame, unit) then
				return false
			end
			local castbar = frame.Castbar
			local update = castbar:GetScript("OnUpdate")
			if update then
				castbar:SetScript("OnUpdate", nil)
				ActiveCastbars[castbar] = update
			end
			return true
		end,
		disable = function(frame)
			if frame.Castbar then
				ActiveCastbars[frame.Castbar] = nil
			end
			CastImplementation.disable(frame)
			ClearCastbar(frame)
		end,
		clear = ClearCastbar,
	}
end

UF.PostCastStart = function(self, unit)
	if self.notInterruptible then
		self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-uninterruptible"]))
		self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-uninterruptible"]))
	elseif self.ClassColor and UnitIsPlayer(unit) then
		_, Class = UnitClass(unit)

		if Class then
			Colors = HydraUI.ClassColors[Class]

			self:SetStatusBarColor(Colors[1], Colors[2], Colors[3])
			self.bg:SetVertexColor(Colors[1], Colors[2], Colors[3])
		else
			self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
			self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
		end
	else
		self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
		self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
	end
end

UF.PostCastInterruptible = function(self, unit)
	if self.notInterruptible then
		self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-uninterruptible"]))
		self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-uninterruptible"]))
	elseif self.ClassColor and UnitIsPlayer(unit) then
		_, Class = UnitClass(unit)

		if Class then
			Colors = HydraUI.ClassColors[Class]

			self:SetStatusBarColor(Colors[1], Colors[2], Colors[3])
			self.bg:SetVertexColor(Colors[1], Colors[2], Colors[3])
		else
			self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
			self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
		end
	else
		self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
		self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-start"]))
	end
end

UF.PostCastStop = function(self)
	self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-stopped"]))
	self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-stopped"]))
end

UF.PostCastFail = function(self)
	self:SetStatusBarColor(HydraUI:HexToRGB(Settings["color-casting-interrupted"]))
	self.bg:SetVertexColor(HydraUI:HexToRGB(Settings["color-casting-interrupted"]))
end

end

ns.UnitFrameCastSupport = Install
