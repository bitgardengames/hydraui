local _, ns = ...
local oUF = ns.oUF or oUF

if (not oUF) then
	return
end

local ActiveCount = 0
local Running = false
local smoothing = {}
local Frame = CreateFrame("Frame")
local min, max, abs, pairs = math.min, math.max, math.abs, pairs
local GetFramerate = GetFramerate
local _

local function Smooth(self, value)
	local _, Max = self:GetMinMaxValues()
	
	if (self.Max_ and self.Max_ ~= Max) then -- Fix target switches
		self:SetValue_(value)
		smoothing[self] = nil
		self.Max_ = Max
		return
	end
	
	if (value ~= self:GetValue() or value == 0) then
		smoothing[self] = value
	else
		smoothing[self] = nil
	end
	
	self.Max_ = Max
end

-- Unit health and power can be secret on mainline. Secret values may be passed
-- back to a StatusBar, but Lua cannot inspect or perform arithmetic on them.
-- Keep this as a separate implementation so classic clients retain the plain
-- smoothing path without paying for an issecretvalue check on every update.
if (select(4, GetBuildInfo()) > 90000) then
	Smooth = function(self, value)
		if (issecretvalue(value)) then
			self:SetValue_(value)
			smoothing[self] = nil
			self.Max_ = nil
			return
		end

		local _, Max = self:GetMinMaxValues()

		if (issecretvalue(Max)) then
			self:SetValue_(value)
			smoothing[self] = nil
			self.Max_ = nil
			return
		end

		if (self.Max_ and self.Max_ ~= Max) then -- Fix target switches
			self:SetValue_(value)
			smoothing[self] = nil
			self.Max_ = Max
			return
		end

		local Current = self:GetValue()

		if (issecretvalue(Current)) then
			self:SetValue_(value)
			smoothing[self] = nil
		elseif (value ~= Current or value == 0) then
			smoothing[self] = value
		else
			smoothing[self] = nil
		end

		self.Max_ = Max
	end
end

local SmoothBar = function(self, bar)
	bar.SetValue_ = bar.SetValue
	bar.SetValue = Smooth
end

local function OnUpdate()
	for bar, value in pairs(smoothing) do
		local Current = bar:GetValue()
		local New = Current + min((value - Current) / 3, max(value - Current, 30 / GetFramerate()))
		
		if (New ~= New) then
			New = value
		end
		
		bar:SetValue_(New)
		
		if (Current == value or abs(New - value) < 2) then
			bar:SetValue_(value)
			smoothing[bar] = nil
		end
	end
end

if (select(4, GetBuildInfo()) > 90000) then
	OnUpdate = function()
		for bar, value in pairs(smoothing) do
			local Current = bar:GetValue()

			-- A bar can become secret after it was queued (for example, when combat
			-- starts). Drop that animation rather than doing forbidden arithmetic.
			if (issecretvalue(Current) or issecretvalue(value)) then
				bar:SetValue_(value)
				smoothing[bar] = nil
			else
				local New = Current + min((value - Current) / 3, max(value - Current, 30 / GetFramerate()))

				if (New ~= New) then
					New = value
				end

				bar:SetValue_(New)

				if (Current == value or abs(New - value) < 2) then
					bar:SetValue_(value)
					smoothing[bar] = nil
				end
			end
		end
	end
end

local Update = function(self)
	
end

local Enable = function(self)
	self.SmoothBar = SmoothBar
	
	if (self.Health and self.Health.Smooth) then
		self:SmoothBar(self.Health)
	end
	
	if (self.Power and self.Power.Smooth) then
		self:SmoothBar(self.Power)
	end
	
	ActiveCount = ActiveCount + 1
	
	if (ActiveCount > 0 and not Running) then
		Frame:SetScript("OnUpdate", OnUpdate)
		Running = true
	end
	
	return true
end

local Disable = function(self)
	if self.Health then
		self.Health.SetValue = self.Health.SetValue_
		
		for bar in pairs(smoothing) do
			if (bar == self.Health) then
				smoothing[bar] = nil
				break
			end
		end
	end
	
	if self.Power then
		self.Power.SetValue = self.Power.SetValue_
		
		for bar in pairs(smoothing) do
			if (bar == self.Power) then
				smoothing[bar] = nil
				break
			end
		end
	end
	
	ActiveCount = ActiveCount - 1
	
	if (ActiveCount <= 0 and Running) then
		Frame:SetScript("OnUpdate", nil)
		Running = false
	end
end

oUF:AddElement("Smooth", Update, Enable, Disable)
