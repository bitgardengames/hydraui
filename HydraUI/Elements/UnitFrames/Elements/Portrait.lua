local _, ns = ...
local HydraUI = ns:get()
local UF = HydraUI:GetModule("Unit Frames")
local Handlers = UF.ElementHandlers

local function Force(element, update)
	return function()
		return update(element.__owner, "ForceUpdate", element.__owner.unit)
	end
end

local function Unregister(frame, handler, ...)
	for i = 1, select("#", ...) do
		frame:UnregisterEvent(select(i, ...), handler)
	end
end

local function UpdatePortrait(frame,event,unit)
	if not unit or not UnitIsUnit(frame.unit, unit) then
		return
	end

	local portrait=frame.Portrait
	if portrait.PreUpdate then
		portrait:PreUpdate(frame.unit)
	end

	local guid = UnitGUID(unit)
	local isAvailable = UnitIsConnected(unit) and UnitIsVisible(unit)
	local hasStateChanged = event ~= "OnUpdate" or portrait.guid ~= guid or portrait.state ~= isAvailable

	if hasStateChanged then
		if portrait:IsObjectType("PlayerModel") then
			if not isAvailable then
				portrait:SetCamDistanceScale(0.25)
				portrait:SetPortraitZoom(0)
				portrait:SetPosition(0, 0, 0.25)
				portrait:ClearModel()
				portrait:SetModel([[Interface\Buttons\TalkToMeQuestionMark.m2]])
			else
				portrait:SetCamDistanceScale(1)
				portrait:SetPortraitZoom(1)
				portrait:SetPosition(0, 0, 0)
				portrait:ClearModel()
				portrait:SetUnit(unit)
			end
		else
			local class = portrait.showClass and UnitClassBase(unit)

			if class then
				portrait:SetAtlas("classicon-" .. class)
			else
				SetPortraitTexture(portrait, unit)
			end
		end

		portrait.guid, portrait.state = guid, isAvailable
	end

	if portrait.PostUpdate then
		portrait:PostUpdate(unit, hasStateChanged)
	end
end

local function EnablePortrait(frame)
	local p=frame.Portrait

	if not p then
		return
	end

	p.__owner,p.ForceUpdate=frame,Force(p,UpdatePortrait)
	frame:RegisterEvent("UNIT_MODEL_CHANGED",UpdatePortrait)
	frame:RegisterEvent("UNIT_PORTRAIT_UPDATE",UpdatePortrait)
	frame:RegisterEvent("PORTRAITS_UPDATED",UpdatePortrait,true)
	frame:RegisterEvent("UNIT_CONNECTION",UpdatePortrait)

	if frame.unit == "party" then
		frame:RegisterEvent("PARTY_MEMBER_ENABLE",UpdatePortrait)
	end

	p:Show()

	return true
end

local function DisablePortrait(frame)
	frame.Portrait:Hide()
	Unregister(frame, UpdatePortrait, "UNIT_MODEL_CHANGED", "UNIT_PORTRAIT_UPDATE", "PORTRAITS_UPDATED", "PARTY_MEMBER_ENABLE", "UNIT_CONNECTION")
end

Handlers.Portrait={update=UpdatePortrait,enable=EnablePortrait,disable=DisablePortrait}