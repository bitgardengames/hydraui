local _, ns = ...
local HydraUI, _, Assets, Settings = ns:get()

local UF = HydraUI:GetModule("Unit Frames")

function UF:SetFrameWidth(unit, value)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	frame:SetWidth(value)
end

function UF:SetHealthHeight(unit, value, powerHeight)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	frame.Health:SetHeight(value)
	frame:SetHeight(value + powerHeight + 3)
end

function UF:SetPowerHeight(unit, value, healthHeight)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	frame.Power:SetHeight(value)
	frame:SetHeight(healthHeight + value + 3)
end

function UF:ApplyHealthAttributes(unit, value)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	self:SetHealthAttributes(frame.Health, value)
	frame.Health:ForceUpdate()
end

function UF:ApplyPowerAttributes(unit, value)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	self:SetPowerAttributes(frame.Power, value)
	frame.Power:ForceUpdate()
end

function UF:SetHealthReverseFill(unit, value)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	local health = frame.Health
	local healBar = frame.HealBar
	local absorbsBar = frame.AbsorbsBar
	local point = value and "RIGHT" or "LEFT"
	local relativePoint = value and "LEFT" or "RIGHT"

	health:SetReverseFill(value)

	if healBar then
		healBar:SetReverseFill(value)
		healBar:ClearAllPoints()
		healBar:SetPoint(point, health:GetStatusBarTexture(), relativePoint, 0, 0)
	end

	if absorbsBar then
		absorbsBar:SetReverseFill(value)
		absorbsBar:ClearAllPoints()
		absorbsBar:SetPoint(point, health:GetStatusBarTexture(), relativePoint, 0, 0)
	end
end

function UF:SetPowerReverseFill(unit, value)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	frame.Power:SetReverseFill(value)
end

function UF:SetElementEnabled(unit, value, element)
	local frame = HydraUI.UnitFrames[unit]

	if not frame or not frame[element] then
		return
	end

	if value then
		frame:EnableElement(element)
	else
		frame:DisableElement(element)
	end
end

function UF:SetHealthTexture(unit, value)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	local texture = Assets:GetTexture(value)

	frame.Health:SetStatusBarTexture(texture)
	frame.Health.bg:SetTexture(texture)

	if frame.HealBar then
		frame.HealBar:SetStatusBarTexture(texture)
	end

	if frame.AbsorbsBar then
		frame.AbsorbsBar:SetStatusBarTexture(texture)
	end
end

function UF:SetPowerTexture(unit, value)
	local frame = HydraUI.UnitFrames[unit]

	if not frame then
		return
	end

	local texture = Assets:GetTexture(value)

	frame.Power:SetStatusBarTexture(texture)
	frame.Power.bg:SetTexture(texture)
end

function UF:SetAuraSize(unit, value, element, width)
	local frame = HydraUI.UnitFrames[unit]

	if not frame or not frame[element] then
		return
	end

	local auras = frame[element]

	auras.size = value
	auras:SetSize(width, value)
	auras:ForceUpdate()
end

function UF:SetAuraPosition(unit, value, element, growthX, companion, companionPosition)
	local frame = HydraUI.UnitFrames[unit]

	if not frame or not frame[element] then
		return
	end

	local auras = frame[element]
	local relativeTo = frame

	if companion and companionPosition == value and frame[companion] then
		relativeTo = frame[companion]
	end

	auras:ClearAllPoints()

	if value == "TOP" then
		auras:SetPoint("BOTTOM", relativeTo, "TOP", 0, 2)
		auras["growth-y"] = "UP"
	else
		auras:SetPoint("TOP", relativeTo, "BOTTOM", 0, -2)
		auras["growth-y"] = "DOWN"
	end

	auras["growth-x"] = growthX
end

-- Setting callbacks are declared once, next to the widgets that use them. The
-- operation receives an already resolved frame because a slider can fire many
-- times while it is being dragged.
local UnitOperations = {}

function UnitOperations.Width(UF, frame, value, options)
	frame:SetWidth(value)
	if options and options.widthElements then
		for i = 1, #options.widthElements do
			local element = frame[options.widthElements[i]]
			if element then
				element:SetWidth(value)
			end
		end
	end
end

function UnitOperations.HealthHeight(UF, frame, value, options)
	frame.Health:SetHeight(value)
	frame:SetHeight(value + Settings[options.powerHeight] + 3)
end

function UnitOperations.PowerHeight(UF, frame, value, options)
	frame.Power:SetHeight(value)
	frame:SetHeight(Settings[options.healthHeight] + value + 3)
end

function UnitOperations.HealthColor(UF, frame, value)
	UF:SetHealthAttributes(frame.Health, value)
	frame.Health:ForceUpdate()
end

function UnitOperations.PowerColor(UF, frame, value)
	UF:SetPowerAttributes(frame.Power, value)
	frame.Power:ForceUpdate()
end

function UnitOperations.HealthReverse(UF, frame, value)
	local health = frame.Health
	local point, relativePoint = value and "RIGHT" or "LEFT", value and "LEFT" or "RIGHT"
	health:SetReverseFill(value)
	local healBar = frame.HealBar
	if healBar then
		healBar:SetReverseFill(value)
		healBar:ClearAllPoints()
		healBar:SetPoint(point, health:GetStatusBarTexture(), relativePoint, 0, 0)
	end
	local absorbsBar = frame.AbsorbsBar
	if absorbsBar then
		absorbsBar:SetReverseFill(value)
		absorbsBar:ClearAllPoints()
		absorbsBar:SetPoint(point, health:GetStatusBarTexture(), relativePoint, 0, 0)
	end
end

function UnitOperations.PowerReverse(UF, frame, value)
	frame.Power:SetReverseFill(value)
end

function UnitOperations.HealthTexture(UF, frame, value)
	local texture = Assets:GetTexture(value)
	frame.Health:SetStatusBarTexture(texture)
	frame.Health.bg:SetTexture(texture)
	if frame.HealBar then
		frame.HealBar:SetStatusBarTexture(texture)
	end
	if frame.AbsorbsBar then
		frame.AbsorbsBar:SetStatusBarTexture(texture)
	end
end

function UnitOperations.PowerTexture(UF, frame, value)
	local texture = Assets:GetTexture(value)
	frame.Power:SetStatusBarTexture(texture)
	frame.Power.bg:SetTexture(texture)
end

function UnitOperations.AuraSize(UF, frame, value, options)
	local auras = frame[options.element]
	if not auras then
		return
	end
	auras.size = value
	auras:SetSize(Settings[options.width], value)
	auras:ForceUpdate()
end

function UnitOperations.AuraSpacing(UF, frame, value, options)
	local auras = frame[options.element]
	if not auras then
		return
	end
	auras.spacing = value
	auras:ForceUpdate()
end

function UnitOperations.ElementEnabled(UF, frame, value, options)
	if not frame[options.component or options.element] then
		return
	end
	if value then
		frame:EnableElement(options.element)
	else
		frame:DisableElement(options.element)
	end
	if options.forceUpdate then
		frame:UpdateAllElements("ForceUpdate")
	end
end

function UnitOperations.AuraPosition(UF, frame, value, options)
	local auras = frame[options.element]
	if not auras then
		return
	end
	local relativeTo = frame
	if options.companion and Settings[options.companionPosition] == value and frame[options.companion] then
		relativeTo = frame[options.companion]
	end
	auras:ClearAllPoints()
	if value == "TOP" then
		auras:SetPoint("BOTTOM", relativeTo, "TOP", 0, 2)
		auras["growth-y"] = "UP"
	else
		auras:SetPoint("TOP", relativeTo, "BOTTOM", 0, -2)
		auras["growth-y"] = "DOWN"
	end
	auras["growth-x"] = options.growthX
end

UF.UnitOperations = UnitOperations

function UF:CreateUnitUpdater(unit, operation, options)
	local update = assert(UnitOperations[operation], "unknown unit-frame update operation: " .. tostring(operation))
	if options and options.count then
		return function(value)
			for i = 1, options.count do
				local frame = HydraUI.UnitFrames[unit .. i]
				if frame then
					update(self, frame, value, options)
				end
			end
		end
	end
	return function(value)
		local frame = HydraUI.UnitFrames[unit]
		if frame then
			update(self, frame, value, options)
		end
	end
end
