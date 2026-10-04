local _, ns = ...
local Handlers = ns.UnitFrameComponentHandlers

local function SetMissing(watch, icon)
	if icon.onlyShowPresent then
		icon:Hide()
		return
	end
	if icon.cd then
		icon.cd:Hide()
	end
	if icon.count then
		icon.count:SetText("")
	end
	icon:SetAlpha(watch.missingAlpha or .75)
	icon:Show()
end

local function SetPresent(watch, icon, count, duration, expiration)
	if icon.onlyShowMissing then
		icon:Hide()
		return
	end
	if icon.cd then
		if duration and duration > 0 then
			icon.cd:SetCooldown(expiration - duration, duration)
			icon.cd:Show()
		else
			icon.cd:Hide()
		end
	end
	if icon.count then
		icon.count:SetText(count and count > 1 and count or "")
	end
	icon:SetAlpha(watch.presentAlpha or 1)
	icon:Show()
end

local function Update(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end
	local watch, found = frame.AuraWatch, {}
	for spellID, icon in pairs(watch.icons) do
		SetMissing(watch, icon)
		found[spellID] = false
	end
	for _, filter in ipairs({"HELPFUL", "HARMFUL"}) do
		for index = 1, 40 do
			local name, _, count, _, duration, expiration, caster, _, _, spellID = UnitAura(frame.unit, index, filter)
			if not name then
				break
			end
			local icon = watch.icons[spellID]
			if icon and (icon.anyUnit or caster == "player" or caster == "vehicle" or caster == "pet") then
				SetPresent(watch, icon, count, duration, expiration)
				found[spellID] = true
			end
		end
	end
end

local function Enable(frame)
	local watch = frame.AuraWatch
	if not watch then
		return
	end
	watch.__owner = frame
	watch.ForceUpdate = function()
		Update(frame, "ForceUpdate", frame.unit)
	end
	frame:RegisterEvent("UNIT_AURA", Update)
	return true
end

local function Disable(frame)
	frame:UnregisterEvent("UNIT_AURA", Update)
	frame.AuraWatch:Hide()
end

Handlers.AuraWatch = {update=Update, enable=Enable, disable=Disable}
