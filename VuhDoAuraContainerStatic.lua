local _;

local format = string.format;
local pairs = pairs;
local twipe = table.wipe;
local InCombatLockdown = InCombatLockdown;
local GetTime = GetTime;
local issecretvalue = issecretvalue;
local UnitCanAttack = UnitCanAttack;

local VUHDO_RAID;
local VUHDO_PANEL_SETUP;
local VUHDO_UNIT_AURA_LIST_SLOTS;
local VUHDO_AURA_FRAMES;
local VUHDO_AURA_CONTAINERS;
local VUHDO_AURA_GROWTH_OFFSETS;

local VUHDO_PixelUtil;
local VUHDO_getHealthBar;
local VUHDO_getUnitButtonsPanel;
local VUHDO_displayAuraInSlot;
local VUHDO_hideAuraSlot;
local VUHDO_copyColorTo;
local VUHDO_evaluateBouquetItemForStaticSlot;
local VUHDO_applyAuraContainerSlotFilters;

local sRelPointManaFactor = {
	["TOPLEFT"] = 0,
	["TOP"] = 0,
	["TOPRIGHT"] = 0,
	["LEFT"] = 0,
	["CENTER"] = 0,
	["RIGHT"] = 0,
	["BOTTOMLEFT"] = 1,
	["BOTTOM"] = 1,
	["BOTTOMRIGHT"] = 1,
};

local sStaticSlotAuraScratch = {
	["color"] = { },
};



--
function VUHDO_auraContainerStaticInitLocalOverrides()

	VUHDO_RAID = _G["VUHDO_RAID"];
	VUHDO_PANEL_SETUP = _G["VUHDO_PANEL_SETUP"];
	VUHDO_UNIT_AURA_LIST_SLOTS = _G["VUHDO_UNIT_AURA_LIST_SLOTS"];
	VUHDO_AURA_FRAMES = _G["VUHDO_AURA_FRAMES"];
	VUHDO_AURA_CONTAINERS = _G["VUHDO_AURA_CONTAINERS"];
	VUHDO_AURA_GROWTH_OFFSETS = _G["VUHDO_AURA_GROWTH_OFFSETS"];

	VUHDO_PixelUtil = _G["VUHDO_PixelUtil"];
	VUHDO_getHealthBar = _G["VUHDO_getHealthBar"];
	VUHDO_getUnitButtonsPanel = _G["VUHDO_getUnitButtonsPanel"];
	VUHDO_displayAuraInSlot = _G["VUHDO_displayAuraInSlot"];
	VUHDO_hideAuraSlot = _G["VUHDO_hideAuraSlot"];
	VUHDO_copyColorTo = _G["VUHDO_copyColorTo"];
	VUHDO_evaluateBouquetItemForStaticSlot = _G["VUHDO_evaluateBouquetItemForStaticSlot"];
	VUHDO_applyAuraContainerSlotFilters = _G["VUHDO_applyAuraContainerSlotFilters"];

	return;

end



do
	--
	local tContainerLayout;
	local tAnchorPoint;
	local tAnchor;
	local tPoint;
	local tRelFrame;
	local tRelPoint;
	local tXOff;
	local tYOff;
	local tManaFactor;
	local tSlotAnchor;
	local tSlotRelPoint;
	local function VUHDO_resolveStaticSlotAnchor(aButton, aContainerTemplate, aStaticSlot, aListSlots)

		tContainerLayout = aContainerTemplate and aContainerTemplate["containerLayout"];
		tAnchorPoint = (tContainerLayout and tContainerLayout["anchorPoint"]) or "TOPLEFT";
		tAnchor = aContainerTemplate and aContainerTemplate["anchor"];
		tPoint = tAnchor and tAnchor["points"] and tAnchor["points"][1];

		tSlotAnchor = aStaticSlot["anchor"];

		if tSlotAnchor then
			tRelFrame = VUHDO_getHealthBar(aButton, 3);

			if not tRelFrame then
				tRelFrame = aButton;
			end

			tSlotRelPoint = aStaticSlot["relPoint"] or tSlotAnchor;

			return tSlotAnchor, tRelFrame, tSlotRelPoint, aStaticSlot["x"] or 0, aStaticSlot["y"] or 0;
		end

		if tPoint then
			if tPoint["relFrame"] == "HealthBar" then
				tRelFrame = VUHDO_getHealthBar(aButton, 3);
			else
				tRelFrame = aButton;
			end

			if not tRelFrame then
				tRelFrame = aButton;
			end

			tRelPoint = tPoint["relativePoint"] or tPoint["point"] or tAnchorPoint;
			tXOff = (tPoint["x"] or 0) + (aStaticSlot["x"] or 0);
			tYOff = (tPoint["y"] or 0) + (aStaticSlot["y"] or 0);

			if tPoint["relFrame"] == "HealthBar" then
				tManaFactor = sRelPointManaFactor[tRelPoint] or 0;

				tYOff = tYOff + (aButton["manaBarLayoutHeight"] or 0) * tManaFactor;
			end

			return tPoint["point"] or tAnchorPoint, tRelFrame, tRelPoint, tXOff, tYOff;
		end

		return tAnchorPoint, aButton, tAnchorPoint, aStaticSlot["x"] or 0, aStaticSlot["y"] or 0;

	end



	--
	local tAnchorPoint;
	local tRelFrame;
	local tRelPoint;
	local tXOff;
	local tYOff;
	local tFrameLevelOffset;
	local tGeometryKey;
	local tRelFrameKey;
	local tChild;
	local tTexture;
	local function VUHDO_applyStaticBouquetSlotGeometry(aFrame, aButton, aContainerTemplate, aStaticSlot, aListSlots)

		if not aFrame or not aButton or not aContainerTemplate or not aStaticSlot then
			return;
		end

		aFrame["isStaticSlotFrame"] = true;

		tAnchorPoint, tRelFrame, tRelPoint, tXOff, tYOff = VUHDO_resolveStaticSlotAnchor(aButton, aContainerTemplate, aStaticSlot, aListSlots);
		tFrameLevelOffset = ((aContainerTemplate["anchor"] and aContainerTemplate["anchor"]["frameLevelOffset"]) or aFrame["addLevel"] or 10) + (aStaticSlot["frameLevelOffset"] or 0);

		tRelFrameKey = (tRelFrame == aButton) and "button" or "healthBar";
		tGeometryKey = format("%s:%s:%s:%d:%d:%d:%d:%d", tAnchorPoint or "", tRelPoint or "", tRelFrameKey, tXOff or 0, tYOff or 0, aStaticSlot["width"] or 0, aStaticSlot["height"] or 0, tFrameLevelOffset or 0);

		if aFrame["staticSlotGeometryKey"] == tGeometryKey and aFrame:GetParent() == aButton then
			return;
		end

		if not InCombatLockdown() then
			if aFrame:GetParent() ~= aButton then
				aFrame:SetParent(aButton);
			end

			aFrame:ClearAllPoints();
			VUHDO_PixelUtil.SetPoint(aFrame, tAnchorPoint, tRelFrame, tRelPoint, tXOff, tYOff);
			VUHDO_PixelUtil.SetSize(aFrame, aStaticSlot["width"] or 20, aStaticSlot["height"] or 20);

			VUHDO_PixelUtil.SetFrameStrata(aFrame, aButton:GetFrameStrata());
			VUHDO_PixelUtil.SetFrameLevel(aFrame, aButton:GetFrameLevel() + tFrameLevelOffset);

			tChild = aFrame["childB"];

			if tChild then
				tChild:ClearAllPoints();
				tChild:SetAllPoints(aFrame);

				tTexture = tChild["textureI"];

				if tTexture then
					tTexture:SetAllPoints(tChild);
				end

				tChild:SetAlpha(1);
			end

			aFrame["staticSlotGeometryKey"] = tGeometryKey;
		end

		return;

	end



	--
	local tInfo;
	local tEvalResults;
	local tIsActive;
	local tIcon;
	local tTimer;
	local tCounter;
	local tDuration;
	local tColor;
	local tBuffName;
	local tClipL;
	local tClipR;
	local tClipT;
	local tClipB;
	local tSecretBool;
	local tSlotDataAsAura;
	local tButtonName;
	local tAuraFrame;
	local function VUHDO_paintMixedStaticBouquetItem(aButton, aUnit, aPanelNum, anAnchorIndex, aContainerData, anAnchorConfig, aStaticSlot, aSlotIndex)

		tInfo = VUHDO_RAID[aUnit];

		if not tInfo then
			VUHDO_hideAuraSlot(aButton, anAnchorIndex, aSlotIndex, anAnchorConfig["style"] == "bars");

			return;
		end

		tEvalResults = { VUHDO_evaluateBouquetItemForStaticSlot(aStaticSlot["bouquetName"], aStaticSlot["itemIndex"], tInfo) };

		tIsActive = tEvalResults[1];
		tIcon = tEvalResults[2];
		tTimer = tEvalResults[3];
		tCounter = tEvalResults[4];
		tDuration = tEvalResults[5];
		tColor = tEvalResults[6];
		tBuffName = tEvalResults[7];
		tClipL = tEvalResults[8];
		tClipR = tEvalResults[9];
		tClipT = tEvalResults[10];
		tClipB = tEvalResults[11];
		tSecretBool = tEvalResults[12];

		if issecretvalue(tSecretBool) then
			tSlotDataAsAura = sStaticSlotAuraScratch;

			tSlotDataAsAura["icon"] = tIcon or "Interface\\Icons\\INV_Misc_QuestionMark";
			tSlotDataAsAura["expirationTime"] = 0;
			tSlotDataAsAura["duration"] = 0;
			tSlotDataAsAura["applications"] = 0;
			tSlotDataAsAura["name"] = tBuffName;
			tSlotDataAsAura["auraInstanceID"] = -1;
			tSlotDataAsAura["clipL"] = tClipL;
			tSlotDataAsAura["clipR"] = tClipR;
			tSlotDataAsAura["clipT"] = tClipT;
			tSlotDataAsAura["clipB"] = tClipB;

			if tColor then
				VUHDO_copyColorTo(tColor, sStaticSlotAuraScratch["color"]);
			else
				twipe(sStaticSlotAuraScratch["color"]);
			end

			tSlotDataAsAura["groupId"] = anAnchorConfig["groupId"];
			tSlotDataAsAura["entryIndex"] = aStaticSlot["entryIndex"];

			VUHDO_displayAuraInSlot(aButton, aPanelNum, anAnchorIndex, aSlotIndex, tSlotDataAsAura, anAnchorConfig);

			tButtonName = aButton:GetName();
			tAuraFrame = tButtonName and VUHDO_AURA_FRAMES[tButtonName] and VUHDO_AURA_FRAMES[tButtonName][anAnchorIndex] and VUHDO_AURA_FRAMES[tButtonName][anAnchorIndex][aSlotIndex];

			if tAuraFrame then
				VUHDO_applyStaticBouquetSlotGeometry(tAuraFrame, aButton, aContainerData["containerTemplate"], aStaticSlot, tListSlots);

				tAuraFrame:SetAlphaFromBoolean(tSecretBool, 1, 0);
			end

			return;
		end

		if tIsActive and tInfo["connected"] and not tInfo["dead"] then
			tSlotDataAsAura = sStaticSlotAuraScratch;

			tSlotDataAsAura["icon"] = tIcon;
			tSlotDataAsAura["applications"] = tCounter or 0;
			tSlotDataAsAura["duration"] = tDuration or 0;
			tSlotDataAsAura["name"] = tBuffName;
			tSlotDataAsAura["auraInstanceID"] = -1;
			tSlotDataAsAura["clipL"] = tClipL;
			tSlotDataAsAura["clipR"] = tClipR;
			tSlotDataAsAura["clipT"] = tClipT;
			tSlotDataAsAura["clipB"] = tClipB;

			if tColor then
				VUHDO_copyColorTo(tColor, sStaticSlotAuraScratch["color"]);
			else
				twipe(sStaticSlotAuraScratch["color"]);
			end

			if tDuration then
				if issecretvalue(tDuration) or issecretvalue(tTimer) then
					tSlotDataAsAura["expirationTime"] = tTimer;
				elseif tDuration > 0 and tTimer then
					tSlotDataAsAura["expirationTime"] = GetTime() + tTimer;
				else
					tSlotDataAsAura["expirationTime"] = 0;
				end
			else
				tSlotDataAsAura["expirationTime"] = 0;
			end

			tSlotDataAsAura["groupId"] = anAnchorConfig["groupId"];
			tSlotDataAsAura["entryIndex"] = aStaticSlot["entryIndex"];

			VUHDO_displayAuraInSlot(aButton, aPanelNum, anAnchorIndex, aSlotIndex, tSlotDataAsAura, anAnchorConfig);

			tButtonName = aButton:GetName();
			tAuraFrame = tButtonName and VUHDO_AURA_FRAMES[tButtonName] and VUHDO_AURA_FRAMES[tButtonName][anAnchorIndex] and VUHDO_AURA_FRAMES[tButtonName][anAnchorIndex][aSlotIndex];

			if tAuraFrame then
				VUHDO_applyStaticBouquetSlotGeometry(tAuraFrame, aButton, aContainerData["containerTemplate"], aStaticSlot, tListSlots);

				tAuraFrame:SetAlpha(1);
				tAuraFrame:Show();
			end
		else
			VUHDO_hideAuraSlot(aButton, anAnchorIndex, aSlotIndex, anAnchorConfig["style"] == "bars");
		end

		return;

	end



	--
	local tStaticSlots;
	local tPanelNum;
	local tAnchorIndex;
	local tAnchorConfig;
	local tContainerTemplate;
	local tIsBar;
	local tListSlots;
	local tButtonName;
	local tSlotIndex;
	local tSlotData;
	local tSlotDataAsAura;
	local tAuraFrame;
	local tInfo;
	local tMixedPriorityCutoffs;
	local tEvalResults;
	local tIsActive;
	local tSecretBool;
	local tEntryIndex;
	local tItemIndex;
	local tPriorityCutoff;
	local tContainer;
	local tCanAttack;
	function VUHDO_paintStaticBouquetSlotsForButton(aButton, aUnit, aContainerData)

		if not aButton or not aUnit or not aContainerData then
			return;
		end

		tStaticSlots = aContainerData["staticSlots"];

		if not tStaticSlots or not next(tStaticSlots) then
			return;
		end

		tPanelNum = aContainerData["panelNum"];
		tAnchorIndex = aContainerData["anchorIndex"];

		if not tPanelNum or not tAnchorIndex then
			return;
		end

		tAnchorConfig = VUHDO_PANEL_SETUP[tPanelNum] and VUHDO_PANEL_SETUP[tPanelNum]["AURA_ANCHORS"] and VUHDO_PANEL_SETUP[tPanelNum]["AURA_ANCHORS"][tAnchorIndex];

		if not tAnchorConfig or tAnchorConfig["enabled"] == false then
			return;
		end

		tContainerTemplate = aContainerData["containerTemplate"];
		tIsBar = tAnchorConfig["style"] == "bars";
		tListSlots = VUHDO_UNIT_AURA_LIST_SLOTS[aUnit] and VUHDO_UNIT_AURA_LIST_SLOTS[aUnit][tPanelNum] and VUHDO_UNIT_AURA_LIST_SLOTS[aUnit][tPanelNum][tAnchorIndex];
		tButtonName = aButton:GetName();

		tMixedPriorityCutoffs = aContainerData["mixedPriorityCutoffs"];

		if not tMixedPriorityCutoffs then
			tMixedPriorityCutoffs = { };
			aContainerData["mixedPriorityCutoffs"] = tMixedPriorityCutoffs;
		else
			twipe(tMixedPriorityCutoffs);
		end

		tInfo = VUHDO_RAID[aUnit];

		if tInfo and tInfo["connected"] and not tInfo["dead"] then
			for _, tStaticSlot in pairs(tStaticSlots) do
				if tStaticSlot["isMixedBouquetItem"] then
					tEvalResults = { VUHDO_evaluateBouquetItemForStaticSlot(tStaticSlot["bouquetName"], tStaticSlot["itemIndex"], tInfo) };

					tIsActive = tEvalResults[1];
					tSecretBool = tEvalResults[12];

					if tIsActive and not issecretvalue(tSecretBool) then
						tEntryIndex = tStaticSlot["entryIndex"];
						tItemIndex = tStaticSlot["itemIndex"];

						if tEntryIndex and tItemIndex then
							if not tMixedPriorityCutoffs[tEntryIndex] or tItemIndex < tMixedPriorityCutoffs[tEntryIndex] then
								tMixedPriorityCutoffs[tEntryIndex] = tItemIndex;
							end
						end
					end
				end
			end
		end

		for tSlotEntryIndex, tStaticSlot in pairs(tStaticSlots) do
			tSlotIndex = tStaticSlot["slotIndex"] or tSlotEntryIndex;

			if tStaticSlot["isMixedBouquetItem"] then
				tEntryIndex = tStaticSlot["entryIndex"];
				tItemIndex = tStaticSlot["itemIndex"];
				tPriorityCutoff = tEntryIndex and tMixedPriorityCutoffs[tEntryIndex];

				if tPriorityCutoff and tItemIndex and tItemIndex > tPriorityCutoff then
					VUHDO_hideAuraSlot(aButton, tAnchorIndex, tSlotIndex, tIsBar);
				else
					VUHDO_paintMixedStaticBouquetItem(aButton, aUnit, tPanelNum, tAnchorIndex, aContainerData, tAnchorConfig, tStaticSlot, tSlotIndex);
				end
			else
				tSlotData = tListSlots and tListSlots[tStaticSlot["entryIndex"]];

				if tSlotData and tSlotData["isActive"] then
					tSlotDataAsAura = sStaticSlotAuraScratch;

					tSlotDataAsAura["icon"] = tSlotData["icon"];
					tSlotDataAsAura["expirationTime"] = tSlotData["expirationTime"] or 0;
					tSlotDataAsAura["duration"] = tSlotData["duration"] or 0;
					tSlotDataAsAura["applications"] = tSlotData["stacks"] or 0;
					tSlotDataAsAura["name"] = tSlotData["name"];
					tSlotDataAsAura["auraInstanceID"] = tSlotData["auraInstanceID"] or -1;
					tSlotDataAsAura["clipL"] = tSlotData["clipL"];
					tSlotDataAsAura["clipR"] = tSlotData["clipR"];
					tSlotDataAsAura["clipT"] = tSlotData["clipT"];
					tSlotDataAsAura["clipB"] = tSlotData["clipB"];
					tSlotDataAsAura["color"] = tSlotData["color"];
					tSlotDataAsAura["isAliveTime"] = tSlotData["isAliveTime"];
					tSlotDataAsAura["groupId"] = tSlotData["groupId"];
					tSlotDataAsAura["entryIndex"] = tSlotData["entryIndex"];

					VUHDO_displayAuraInSlot(aButton, tPanelNum, tAnchorIndex, tSlotIndex, tSlotDataAsAura, tAnchorConfig);

					tAuraFrame = tButtonName and VUHDO_AURA_FRAMES[tButtonName] and VUHDO_AURA_FRAMES[tButtonName][tAnchorIndex] and VUHDO_AURA_FRAMES[tButtonName][tAnchorIndex][tSlotIndex];

					if tAuraFrame and tContainerTemplate then
						VUHDO_applyStaticBouquetSlotGeometry(tAuraFrame, aButton, tContainerTemplate, tStaticSlot, tListSlots);

						tAuraFrame:SetAlpha(1);
						tAuraFrame:Show();
					end
				else
					VUHDO_hideAuraSlot(aButton, tAnchorIndex, tSlotIndex, tIsBar);
				end
			end
		end

		tContainer = aContainerData["container"];

		if tContainer then
			tCanAttack = UnitCanAttack("player", aUnit);
			VUHDO_applyAuraContainerSlotFilters(tContainer, aContainerData, tCanAttack);
		end

		return;

	end



	--
	local tStaticSlots;
	local tAnchorIndex;
	local tPanelNum;
	local tAnchorConfig;
	local tIsBar;
	local tSlotIndex;
	function VUHDO_hideStaticBouquetSlotsForButton(aButton, aContainerData)

		if not aButton or not aContainerData then
			return;
		end

		tStaticSlots = aContainerData["staticSlots"];

		if not tStaticSlots or not next(tStaticSlots) then
			return;
		end

		tAnchorIndex = aContainerData["anchorIndex"];
		tPanelNum = aContainerData["panelNum"];

		if not tAnchorIndex or not tPanelNum then
			return;
		end

		tAnchorConfig = VUHDO_PANEL_SETUP[tPanelNum] and VUHDO_PANEL_SETUP[tPanelNum]["AURA_ANCHORS"] and VUHDO_PANEL_SETUP[tPanelNum]["AURA_ANCHORS"][tAnchorIndex];
		tIsBar = tAnchorConfig and tAnchorConfig["style"] == "bars";

		for tSlotEntryIndex, tStaticSlot in pairs(tStaticSlots) do
			tSlotIndex = tStaticSlot["slotIndex"] or tSlotEntryIndex;

			VUHDO_hideAuraSlot(aButton, tAnchorIndex, tSlotIndex, tIsBar);
		end

		return;

	end



	--
	local tAnchorConfig;
	local tPanelUnitButtons;
	local tButtonName;
	local tContainerData;
	function VUHDO_updateStaticBouquetSlotsForUnit(aUnit, aPanelNum, anAnchorIndex)

		if not aUnit or not aPanelNum or not anAnchorIndex then
			return;
		end

		tAnchorConfig = VUHDO_PANEL_SETUP[aPanelNum] and VUHDO_PANEL_SETUP[aPanelNum]["AURA_ANCHORS"] and VUHDO_PANEL_SETUP[aPanelNum]["AURA_ANCHORS"][anAnchorIndex];

		if not tAnchorConfig or tAnchorConfig["enabled"] == false then
			return;
		end

		tPanelUnitButtons = VUHDO_getUnitButtonsPanel(aUnit, aPanelNum);

		if not tPanelUnitButtons or next(tPanelUnitButtons) == nil then
			return;
		end

		for _, tButton in pairs(tPanelUnitButtons) do
			tButtonName = tButton:GetName();

			if tButtonName and VUHDO_AURA_CONTAINERS[tButtonName] then
				tContainerData = VUHDO_AURA_CONTAINERS[tButtonName][anAnchorIndex];

				if tContainerData and tContainerData["staticSlots"] and next(tContainerData["staticSlots"]) then
					VUHDO_paintStaticBouquetSlotsForButton(tButton, aUnit, tContainerData);
				end
			end
		end

		return;

	end

end