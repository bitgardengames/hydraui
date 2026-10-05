local _, ns = ...
local HydraUI = ns:get()
local UF = HydraUI:GetModule("Unit Frames")

local function Install(name, update, enable, events)
	local function Path(frame, ...)
		local element = frame[name]

		return (element.Override or update)(frame, ...)
	end

	UF:RegisterElement(name, {
		update = Path,
		enable = function(frame, unit)
			local element = frame[name]

			if not element or (enable and not enable(frame, element, unit)) then
				return
			end

			element.__owner = frame
			element.ForceUpdate = UF:CreateForceUpdate(element, Path)

			for i = 1, #events do
				frame:RegisterEvent(events[i][1], Path, events[i][2])
			end

			return true
		end,
		disable = function(frame)
			local element = frame[name]
			element:Hide()

			for i = 1, #events do
				frame:UnregisterEvent(events[i][1], Path)
			end
		end,
	})
end

Install("CombatIndicator", function(frame)
	local element = frame.CombatIndicator
	element:SetShown(UnitAffectingCombat("player"))
end, function(frame, element, unit)
	if not UnitIsUnit(unit, "player") then
		return false
	end
	if element:IsObjectType("Texture") and not element:GetTexture() then
		element:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
		element:SetTexCoord(.5, 1, 0, .49)
	end
	return true
end, {{"PLAYER_REGEN_DISABLED", true}, {"PLAYER_REGEN_ENABLED", true}})

Install("LeaderIndicator", function(frame)
	local unit, element = frame.unit, frame.LeaderIndicator
	element:SetShown((UnitInParty(unit) or UnitInRaid(unit)) and UnitIsGroupLeader(unit))
end, function(_, element)
	if element:IsObjectType("Texture") and not element:GetTexture() then
		element:SetTexture([[Interface\GroupFrame\UI-Group-LeaderIcon]])
	end
	return true
end, {{"PARTY_LEADER_CHANGED", true}, {"GROUP_ROSTER_UPDATE", true}})

Install("AssistantIndicator", function(frame)
	local unit, element = frame.unit, frame.AssistantIndicator
	element:SetShown(UnitInRaid(unit) and UnitIsGroupAssistant(unit) and not UnitIsGroupLeader(unit))
end, function(_, element)
	if element:IsObjectType("Texture") and not element:GetTexture() then
		element:SetTexture([[Interface\GroupFrame\UI-Group-AssistantIcon]])
	end
	return true
end, {{"GROUP_ROSTER_UPDATE", true}})

Install("ResurrectIndicator", function(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end
	frame.ResurrectIndicator:SetShown(UnitHasIncomingResurrection(frame.unit))
end, function(_, element)
	if element:IsObjectType("Texture") and not element:GetTexture() then
		element:SetTexture([[Interface\RaidFrame\Raid-Icon-Rez]])
	end
	return true
end, {{"INCOMING_RESURRECT_CHANGED"}})

Install("TargetIndicator", function(frame)
	frame.TargetIndicator:SetShown(UnitIsUnit("target", frame.unit))
end, nil, {{"PLAYER_TARGET_CHANGED", true}})

Install("GroupRoleIndicator", function(frame)
	local element = frame.GroupRoleIndicator
	local role = UnitGroupRolesAssigned(frame.unit)
	if role == "TANK" or role == "HEALER" or role == "DAMAGER" then
		element:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
		element:Show()
	else
		element:Hide()
	end
end, function(_, element)
	if element:IsObjectType("Texture") and not element:GetTexture() then
		element:SetTexture([[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]])
	end
	return true
end, {{"PLAYER_ROLES_ASSIGNED", true}, {"GROUP_ROSTER_UPDATE", true}})

Install("PhaseIndicator", function(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end
	local element = frame.PhaseIndicator
	local reason = UnitIsPlayer(frame.unit) and UnitIsConnected(frame.unit) and UnitPhaseReason(frame.unit) or nil
	element.reason = reason
	element:SetShown(reason ~= nil)
end, function(_, element)
	if not UnitPhaseReason then
		return false
	end
	local icon = element.Icon or element
	if icon:IsObjectType("Texture") and not icon:GetTexture() then
		icon:SetTexture([[Interface\TargetingFrame\UI-PhasingIcon]])
	end
	return true
end, {{"UNIT_PHASE"}})

local function UpdatePvP(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end

	local element, faction = frame.PvPIndicator, UnitFactionGroup(frame.unit)
	local status = UnitIsPVPFreeForAll(frame.unit) and "FFA" or (faction and UnitIsPVP(frame.unit) and faction)

	if status then
		element:SetTexture([[Interface\TargetingFrame\UI-PVP-]] .. status)
		element:SetTexCoord(0, .65625, 0, .65625)
		element:Show()
	else
		element:Hide()
	end

	if element.Badge then
		element.Badge:Hide()
	end
end

local PvPIndicatorEvents = {{"UNIT_FACTION"}}

if HydraUI.IsMainline and not HydraUI.IsForever then
	PvPIndicatorEvents[#PvPIndicatorEvents + 1] = {"HONOR_LEVEL_UPDATE", true}
end

Install("PvPIndicator", UpdatePvP, function()
	return true
end, PvPIndicatorEvents)

local function ReadyFinished(animation)
	animation:GetParent():Hide()
end

Install("ReadyCheckIndicator", function(frame, event)
	local element = frame.ReadyCheckIndicator
	local status = GetReadyCheckStatus(frame.unit)

	if status then
		element:SetTexture(status == "ready" and element.readyTexture or status == "notready" and element.notReadyTexture or element.waitingTexture)
		element.status = status
		element:Show()
	elseif event ~= "READY_CHECK_FINISHED" then
		element.status = nil
		element:Hide()
	end

	if event == "READY_CHECK_FINISHED" then
		if element.status == "waiting" then
			element:SetTexture(element.notReadyTexture)
		end
		element.Animation:Play()
	end
end, function(_, element, unit)
	unit = unit and unit:match("(%a+)%d*$")

	if unit ~= "party" and unit ~= "raid" then
		return false
	end

	element.readyTexture = element.readyTexture or READY_CHECK_READY_TEXTURE
	element.notReadyTexture = element.notReadyTexture or READY_CHECK_NOT_READY_TEXTURE
	element.waitingTexture = element.waitingTexture or READY_CHECK_WAITING_TEXTURE

	local group = element:CreateAnimationGroup()
	group:HookScript("OnFinished", ReadyFinished)
	element.Animation = group

	local fade = group:CreateAnimation("Alpha")
	fade:SetFromAlpha(1)
	fade:SetToAlpha(0)
	fade:SetDuration(element.fadeTime or 1.5)
	fade:SetStartDelay(element.finishedTime or 10)

	return true
end, {{"READY_CHECK", true}, {"READY_CHECK_CONFIRM", true}, {"READY_CHECK_FINISHED", true}})
