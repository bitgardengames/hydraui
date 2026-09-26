local HydraUI, Language, Assets, Settings, Defaults = select(2, ...):get()

local BagsFrame = HydraUI:NewModule("Bags Frame")

-- Default settings values
Defaults["bags-loot-from-left"] = false
Defaults["bags-frame-visiblity"] = "SHOW"
Defaults["bags-frame-opacity"] = 40
Defaults["bags-frame-max"] = 100
Defaults["bags-frame-size"] = 32

local IsClassic = HydraUI.IsClassic
local IsTBC = HydraUI.IsTBC
local HasKeyRing = IsClassic or IsTBC

if HasKeyRing then
	BagsFrame.Objects = {
		KeyRingButton,
		CharacterBag3Slot,
		CharacterBag2Slot,
		CharacterBag1Slot,
		CharacterBag0Slot,
		MainMenuBarBackpackButton,
	}
else
	BagsFrame.Objects = {
		CharacterBag3Slot,
		CharacterBag2Slot,
		CharacterBag1Slot,
		CharacterBag0Slot,
		MainMenuBarBackpackButton,
	}
end

local BagsFrameButtonOnEnter = function(self)
	if (Settings["bags-frame-visiblity"] == "MOUSEOVER") then
		BagsFrame:SetAlpha(Settings["bags-frame-max"] / 100)
	end
end

local BagsFrameOnEnter = function(self)
	BagsFrame:SetAlpha(Settings["bags-frame-max"] / 100)
end

local BagsFrameButtonOnLeave = function(self)
	if (Settings["bags-frame-visiblity"] == "MOUSEOVER") then
		BagsFrame:SetAlpha(Settings["bags-frame-opacity"] / 100)
	end
end

local BagsFrameOnLeave = function(self)
	BagsFrame:SetAlpha(Settings["bags-frame-opacity"] / 100)
end

function BagsFrame:SetAlpha(alpha)
	self.Panel:SetAlpha(alpha)

	-- KeyRingButton's Blizzard scripts call methods on its original parent.
	-- Keep it there and mirror the custom panel's alpha instead of reparenting it.
	if HasKeyRing then
		KeyRingButton:SetAlpha(alpha)
	end
end

function BagsFrame:UpdateVisibility()
	if (Settings["bags-frame-visiblity"] == "HIDE") then
		self.Panel:SetScript("OnEnter", nil)
		self.Panel:SetScript("OnLeave", nil)
		self:SetAlpha(0)
		if HasKeyRing then
			KeyRingButton:EnableMouse(false)
		end
		self.Panel:Hide()
	elseif (Settings["bags-frame-visiblity"] == "MOUSEOVER") then
		self.Panel:SetScript("OnEnter", BagsFrameOnEnter)
		self.Panel:SetScript("OnLeave", BagsFrameOnLeave)
		self:SetAlpha(Settings["bags-frame-opacity"] / 100)
		if HasKeyRing then
			KeyRingButton:EnableMouse(true)
		end
		self.Panel:Show()
	elseif (Settings["bags-frame-visiblity"] == "SHOW") then
		self.Panel:SetScript("OnEnter", nil)
		self.Panel:SetScript("OnLeave", nil)
		self:SetAlpha(Settings["bags-frame-max"] / 100)
		if HasKeyRing then
			KeyRingButton:EnableMouse(true)
		end
		self.Panel:Show()
	end
end

function BagsFrame:PositionButtons()
	if (not self.Panel or self.IsPositioning) then
		return
	end

	self.IsPositioning = true

	-- Clear every existing anchor before rebuilding the chain. The default UI
	-- anchors the bag slots to the backpack, so the backpack must be the root of
	-- our chain as well; making it depend on CharacterBag0Slot causes a circular
	-- dependency when Blizzard restores its anchors.
	for i = 1, #self.Objects do
		local Object = self.Objects[i]

		if (Object ~= KeyRingButton) then
			Object:SetParent(self.Panel)
		end
		Object:ClearAllPoints()
	end

	for i = #self.Objects, 1, -1 do
		local Object = self.Objects[i]

		if (i == #self.Objects) then
			Object:SetPoint("RIGHT", self.Panel, -4, 0)
		else
			Object:SetPoint("RIGHT", self.Objects[i+1], "LEFT", -4, 0)
		end

		if ((IsClassic or IsTBC) and i == 1) then
			Object:SetSize(Settings["bags-frame-size"] / 2, Settings["bags-frame-size"])
		else
			Object:SetSize(Settings["bags-frame-size"], Settings["bags-frame-size"])
		end
	end

	self.IsPositioning = false
end

local RestoreBagButtonPositions = function()
	BagsFrame:PositionButtons()
end

function BagsFrame:Load()
	if (not Settings["ab-enable"]) then
		return
	end

	if (HydraUI.ClientVersion >= 100000) then
		MainMenuBarBackpackButton:ClearAllPoints()
		MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", HydraUI:GetModule("Micro Buttons").Panel, "TOPRIGHT", 0, 5)
		MainMenuBarBackpackButton.SetPoint = function() end

		return
	end

	self.Panel = CreateFrame("Frame", "HydraUI Bags Window", HydraUI.UIParent, "BackdropTemplate")
	self.Panel:SetPoint("BOTTOMRIGHT", HydraUI:GetModule("Micro Buttons").Panel, "TOPRIGHT", 0, 3)
	self.Panel:SetBackdrop(HydraUI.BackdropAndBorder)
	self.Panel:SetBackdropColor(HydraUI:HexToRGB(Settings["ui-window-bg-color"]))
	self.Panel:SetBackdropBorderColor(0, 0, 0)
	self.Panel:SetFrameStrata("LOW")

	if IsClassic or IsTBC then
		self.Panel:SetSize(((Settings["bags-frame-size"] + 4) * (#self.Objects - 1)) + 8 + (Settings["bags-frame-size"] / 2), Settings["bags-frame-size"] + 8)
	else
		self.Panel:SetSize(((Settings["bags-frame-size"] + 4) * #self.Objects) + 4, Settings["bags-frame-size"] + 8)
	end

	HydraUI:CreateMover(self.Panel)

	local Object

	for i = 1, #self.Objects do
		Object = self.Objects[i]

		if (Object ~= KeyRingButton) then
			Object:SetParent(self.Panel)
		end
		Object:HookScript("OnEnter", BagsFrameButtonOnEnter)
		Object:HookScript("OnLeave", BagsFrameButtonOnLeave)

		local Name = Object:GetName()
		local Normal = _G[Name .. "NormalTexture"]
		local Count = _G[Name .. "Count"]
		local Stock = _G[Name .. "Stock"]

		if Object.IconBorder then
			Object.IconBorder:SetAlpha(0)
		end

		if Normal then
			Normal:SetTexture(nil)
		end

		if Count then
			Count:ClearAllPoints()
			Count:SetPoint("BOTTOMRIGHT", 0, 2)
			Count:SetJustifyH("RIGHT")
			HydraUI:SetFontInfo(Count, Settings["ui-widget-font"], Settings["ui-font-size"])
		end

		if Stock then
			Stock:ClearAllPoints()
			Stock:SetPoint("TOPLEFT", 0, -2)
			Stock:SetJustifyH("LEFT")
			HydraUI:SetFontInfo(Stock, Settings["ui-widget-font"], Settings["ui-font-size"])
		end

		if Object.icon then
			Object.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		end

		Object.BG = Object:CreateTexture(nil, "BACKGROUND")
		Object.BG:SetPoint("TOPLEFT", Object, -1, 1)
		Object.BG:SetPoint("BOTTOMRIGHT", Object, 1, -1)
		Object.BG:SetColorTexture(0, 0, 0)

		if HydraUI.IsMainline then
			Object.SlotHighlightTexture:SetTexture(Assets:GetTexture("Blank"))
			Object.SlotHighlightTexture:SetVertexColor(0.9, 0.9, 0.1, 0.2)
		else
			local Checked = Object:CreateTexture(nil, "ARTWORK")
			Checked:SetPoint("TOPLEFT", Object, 0, 0)
			Checked:SetPoint("BOTTOMRIGHT", Object, 0, 0)
			Checked:SetColorTexture(0.9, 0.9, 0.1, 0.2)
			Checked:SetDrawLayer("ARTWORK", 7)

			Object:SetCheckedTexture(Checked)
		end

		local Highlight = Object:CreateTexture(nil, "ARTWORK")
		Highlight:SetPoint("TOPLEFT", Object, 0, 0)
		Highlight:SetPoint("BOTTOMRIGHT", Object, 0, 0)
		Highlight:SetColorTexture(1, 1, 1, 0.25)

		Object:SetHighlightTexture(Highlight)

		if (i ~= 1) then
			local Pushed = Object:CreateTexture(nil, "ARTWORK")
			Pushed:SetPoint("TOPLEFT", Object, 0, 0)
			Pushed:SetPoint("BOTTOMRIGHT", Object, 0, 0)
			Pushed:SetColorTexture(0.2, 0.9, 0.2, 0.4)
			Pushed:SetDrawLayer("ARTWORK", 7)

			Object:SetPushedTexture(Pushed)
		end
	end

	self:PositionButtons()

	-- Blizzard can reposition these buttons from several layout paths. Hook the
	-- method all of those paths eventually call so our anchors are restored even
	-- when the caller changes between clients or patches.
	for i = 1, #self.Objects do
		hooksecurefunc(self.Objects[i], "SetPoint", RestoreBagButtonPositions)
	end

	if (C_Container and C_Container.SetInsertItemsLeftToRight) then
		C_Container.SetInsertItemsLeftToRight(Settings["bags-loot-from-left"])
	else
		SetInsertItemsLeftToRight(Settings["bags-loot-from-left"])
	end

	self:UpdateVisibility()
end

local UpdateBagVisibility = function()
	BagsFrame:UpdateVisibility()
end

local UpdateBagFrameSize = function(value)
	if (not BagsFrame.Panel) then
		return
	end

	if IsClassic then
		BagsFrame.Panel:SetSize(((value + 4) * (#BagsFrame.Objects - 1)) + 8 + (value / 2), value + 8)
	else
		BagsFrame.Panel:SetSize(((value + 4) * #BagsFrame.Objects) + 4, value + 8)
	end

	BagsFrame:PositionButtons()
end

HydraUI:GetModule("GUI"):AddWidgets(Language["General"], Language["Action Bars"], function(left, right)
	right:CreateHeader(Language["Bags Frame"])
	right:CreateDropdown("bags-frame-visiblity", Settings["bags-frame-visiblity"], {[Language["Hide"]] = "HIDE", [Language["Mouseover"]] = "MOUSEOVER", [Language["Show"]] = "SHOW"}, Language["Set Visibility"], Language["Set the visibility of the bag frame"], UpdateBagVisibility)
	right:CreateSlider("bags-frame-size", Settings["bags-frame-size"], 12, 60, 2, Language["Set Bag Size"], Language["Set the size of the bag frame slots"], UpdateBagFrameSize)
	right:CreateSlider("bags-frame-opacity", Settings["bags-frame-opacity"], 0, 100, 10, Language["Set Faded Opacity"], Language["Set the opacity of the bags frame when visiblity is set to Mouseover"], UpdateBagVisibility, nil, "%")
	right:CreateSlider("bags-frame-max", Settings["bags-frame-max"], 0, 100, 10, Language["Set Max Opacity"], Language["Set the max opacity of the bags frame when visiblity is set to Mouseover"], UpdateBagVisibility, nil, "%")
	right:CreateSwitch("bags-loot-from-left", Settings["bags-loot-from-left"], Language["Loot Left To Right"], Language["When looting, new items will be placed into the leftmost bag"], SetInsertItemsLeftToRight)
end)
