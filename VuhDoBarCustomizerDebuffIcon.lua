VUHDO_MAY_DEBUFF_ANIM = true;

local VUHDO_DEBUFF_ICONS = { };
local VUHDO_DEBUFF_ICONS_MAP = { };
local sIsName;

-- BURST CACHE ---------------------------------------------------

local _;

local floor = floor;
local GetTime = GetTime;
local pairs = pairs;
local twipe = table.wipe;
local huge = math.huge;

local _G = getfenv();

local VUHDO_getUnitButtons;
local VUHDO_getUnitButtonsSafe;
local VUHDO_getBarIconTimer
local VUHDO_getBarIconCounter;
local VUHDO_getBarIconFrame;
local VUHDO_getBarIcon;
local VUHDO_getBarIconName;
local VUHDO_getShieldPerc;
local VUHDO_backColor;
local VUHDO_updateHealthBarsFor;
local VUHDO_getBarIconFrameBackground;
local VUHDO_getBarIconButton;

local VUHDO_PANEL_SETUP;
local VUHDO_CONFIG;
local VUHDO_RAID;
local sCuDeStoredSettings;
local sMaxIcons;
local sStaticConfig;
local VUHDO_DEBUFF_COLORS;

local sEmpty = { };

function VUHDO_customDebuffIconsInitLocalOverrides()

	-- functions
	VUHDO_getUnitButtons = _G["VUHDO_getUnitButtons"];
	VUHDO_getBarIconTimer = _G["VUHDO_getBarIconTimer"];
	VUHDO_getBarIconCounter = _G["VUHDO_getBarIconCounter"];
	VUHDO_getBarIconFrame = _G["VUHDO_getBarIconFrame"];
	VUHDO_getBarIcon = _G["VUHDO_getBarIcon"];
	VUHDO_getBarIconName = _G["VUHDO_getBarIconName"];
	VUHDO_getShieldPerc = _G["VUHDO_getShieldPerc"];
	VUHDO_getUnitButtonsSafe = _G["VUHDO_getUnitButtonsSafe"];
	VUHDO_backColor = _G["VUHDO_backColor"];
	VUHDO_updateHealthBarsFor = _G["VUHDO_updateHealthBarsFor"];
	VUHDO_getBarIconFrameBackground = _G["VUHDO_getBarIconFrameBackground"];
	VUHDO_getBarIconButton = _G["VUHDO_getBarIconButton"];

	VUHDO_updateHealthBarsFor = _G["VUHDO_deferUpdateHealthBarsFor"];

	VUHDO_PANEL_SETUP = _G["VUHDO_PANEL_SETUP"];
	VUHDO_CONFIG = _G["VUHDO_CONFIG"];
	VUHDO_RAID = _G["VUHDO_RAID"];
	sCuDeStoredSettings = VUHDO_CONFIG["CUSTOM_DEBUFF"]["STORED_SETTINGS"];
	sMaxIcons = VUHDO_CONFIG["CUSTOM_DEBUFF"]["max_num"];
	if (sMaxIcons < 1) then -- Damit das Bouquet item "Letzter Debuff" funktioniert
		sMaxIcons = 1;
	end
	sIsName = VUHDO_CONFIG["CUSTOM_DEBUFF"]["isName"];

	sStaticConfig = {
		["isStaticConfig"] = true,
		["animate"] = VUHDO_CONFIG["CUSTOM_DEBUFF"]["animate"],
		["timer"] = VUHDO_CONFIG["CUSTOM_DEBUFF"]["timer"],
		["isStacks"] = VUHDO_CONFIG["CUSTOM_DEBUFF"]["isStacks"],
		["isAliveTime"] = false,
		["isFullDuration"] = false,
		["isMine"] = true,
		["isOthers"] = true,
		["isBarGlow"] = false,
		["isIconGlow"] = false,
	};

	VUHDO_DEBUFF_COLORS = {
		[1] = VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF1"],
		[2] = VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF2"],
		[3] = VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF3"],
		[4] = VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF4"],
		[6] = VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF6"],
		[8] = VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF8"],
		[9] = VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF9"],
	};

	return;

end

----------------------------------------------------



--
local function VUHDO_areBlacklistModifiersPressed()

	if not VUHDO_CONFIG or not VUHDO_CONFIG["CUSTOM_DEBUFF"] then
		return IsAltKeyDown() and IsControlKeyDown() and IsShiftKeyDown();
	end

	local tBlacklistModi = VUHDO_CONFIG["CUSTOM_DEBUFF"]["blacklistModi"] or "ALT-CTRL-SHIFT";

	if tBlacklistModi == "OFF" then
		return false;
	elseif tBlacklistModi == "ALT-CTRL-SHIFT" then
		return IsAltKeyDown() and IsControlKeyDown() and IsShiftKeyDown();
	elseif tBlacklistModi == "ALT-SHIFT" then
		return IsAltKeyDown() and IsShiftKeyDown() and not IsControlKeyDown();
	elseif tBlacklistModi == "ALT-CTRL" then
		return IsAltKeyDown() and IsControlKeyDown() and not IsShiftKeyDown();
	elseif tBlacklistModi == "CTRL-SHIFT" then
		return IsControlKeyDown() and IsShiftKeyDown() and not IsAltKeyDown();
	elseif tBlacklistModi == "SHIFT" then
		return IsShiftKeyDown() and not IsAltKeyDown() and not IsControlKeyDown();
	elseif tBlacklistModi == "CTRL" then
		return IsControlKeyDown() and not IsAltKeyDown() and not IsShiftKeyDown();
	elseif tBlacklistModi == "ALT" then
		return IsAltKeyDown() and not IsControlKeyDown() and not IsShiftKeyDown();
	end

	return false;

end



--
local VUHDO_DEBUFF_GLOBAL_HANDLER_FRAME = CreateFrame("Frame");
VUHDO_DEBUFF_GLOBAL_HANDLER_FRAME:RegisterEvent("GLOBAL_MOUSE_DOWN");
VUHDO_DEBUFF_GLOBAL_HANDLER_FRAME:SetScript("OnEvent", function(self, anEvent, aButton)

	if anEvent == "GLOBAL_MOUSE_DOWN" and aButton == "RightButton" and VUHDO_areBlacklistModifiersPressed() then
		local tFrame;

		for tUnit, _ in pairs(VUHDO_RAID) do
			local tButtons = VUHDO_getUnitButtonsSafe(tUnit);

			for _, tButton in pairs(tButtons) do
				for tSlot = 40, 40 + sMaxIcons - 1 do
					tFrame = VUHDO_getBarIconFrame(tButton, tSlot);

					if tFrame and tFrame["debuffInfo"] and tFrame["debuffSpellId"] and tFrame["debuffInstanceId"] and tFrame:IsMouseOver() then
						VUHDO_addDebuffToBlacklist(tFrame);

						return;
					end
				end
			end
		end
	end

end);



--
local tCuDeStoConfig;
local tIsAnim;
local tIsBarGlow;
local tIsIconGlow;
local tTimeStamp;
local tAliveTime;
local tName;
local tRemain;
local tShieldPerc;
local tStacks;
local tNameLabel;
local tAuraInstanceId;
local tCurChosenInfo;
local tType;
local tButton;
local tBackdropFrame;
local tBaseScale;
local tScaleFactor;
local tFinalScale;
local tBackdropInfo = {
	["edgeFile"] = "Interface\\Buttons\\WHITE8X8",
	["edgeSize"] = 4,
	["insets"] = {
		["left"] = 0,
		["right"] = 0,
		["top"] = 0,
		["bottom"] = 0,
	},
};
local function VUHDO_animateDebuffIcon(aButton, anIconInfo, aNow, anIconIndex, anIsInit, aUnit)

	tCuDeStoConfig = sCuDeStoredSettings[anIconInfo[3]] or sCuDeStoredSettings[tostring(anIconInfo[7])] or sStaticConfig;

	if tCuDeStoConfig["isStaticConfig"] and 
		(VUHDO_DEBUFF_BLACKLIST[anIconInfo[3]] or VUHDO_DEBUFF_BLACKLIST[tostring(anIconInfo[7])]) then
		VUHDO_removeDebuffIcon(aUnit, anIconInfo[8]);

		return;
	end

	tIsAnim = tCuDeStoConfig["animate"] and VUHDO_MAY_DEBUFF_ANIM;
	tIsBarGlow = tCuDeStoConfig["isBarGlow"];
	tIsIconGlow = tCuDeStoConfig["isIconGlow"];
	tTimeStamp = anIconInfo[2];
	tAliveTime = anIsInit and 0 or aNow - tTimeStamp;
	tName = anIconInfo[3];

	if tCuDeStoConfig["timer"] then
		if tCuDeStoConfig["isAliveTime"] then
			VUHDO_getBarIconTimer(aButton, anIconIndex):SetText(tAliveTime < 99.5 and floor(tAliveTime + 0.5) or ">>");
		else
			if anIsInit and anIconInfo[2] == -1 then
				VUHDO_getBarIconTimer(aButton, anIconIndex):SetText("");
			else
				tRemain = (anIconInfo[4] or aNow - 1) - aNow;

				if tRemain >= 0 and (tRemain < 10 or tCuDeStoConfig["isFullDuration"]) then
					VUHDO_getBarIconTimer(aButton, anIconIndex):SetText(tRemain > 100 and ">>" or floor(tRemain));
				else
					VUHDO_getBarIconTimer(aButton, anIconIndex):SetText("");
				end
			end
		end
	end

	tShieldPerc = VUHDO_getShieldPerc(aUnit, tName);
	tStacks = tShieldPerc ~= 0 and tShieldPerc or anIconInfo[5] or 0;

	VUHDO_getBarIconCounter(aButton, anIconIndex):SetText((tCuDeStoConfig["isStacks"] and tStacks > 1) and tStacks or "");

	if anIsInit then
		VUHDO_getBarIcon(aButton, anIconIndex):SetTexture(anIconInfo[1]);
		VUHDO_PixelUtil.ApplySettings(VUHDO_getBarIcon(aButton, anIconIndex));

		if sIsName then
			tNameLabel = VUHDO_getBarIconName(aButton, anIconIndex);
			tNameLabel:SetText(tName);
			tNameLabel:SetAlpha(1);
		end

		VUHDO_getBarIconFrame(aButton, anIconIndex):SetAlpha(1);

		if tIsAnim then
			VUHDO_setDebuffAnimation(1.2);
		end

		if tIsBarGlow then
			VUHDO_LibCustomGlow.PixelGlow_Start(
				aButton, 
				tCuDeStoConfig["barGlowColor"] and { 
					tCuDeStoConfig["barGlowColor"]["R"],
					tCuDeStoConfig["barGlowColor"]["G"],
					tCuDeStoConfig["barGlowColor"]["B"],
					tCuDeStoConfig["barGlowColor"]["O"]
				} or { 
					VUHDO_PANEL_SETUP.BAR_COLORS["DEBUFF_BAR_GLOW"]["R"],
					VUHDO_PANEL_SETUP.BAR_COLORS["DEBUFF_BAR_GLOW"]["G"],
					VUHDO_PANEL_SETUP.BAR_COLORS["DEBUFF_BAR_GLOW"]["B"],
					VUHDO_PANEL_SETUP.BAR_COLORS["DEBUFF_BAR_GLOW"]["O"]
				}, 
				14,                             -- number of particles
				0.3,                            -- frequency
				8,                              -- length
				2,                              -- thickness
				0,                              -- x offset
				0,                              -- y offset
				false,                          -- border
				VUHDO_CUSTOM_GLOW_CUDE_FRAME_KEY
			);
		end

		if tIsIconGlow then
			VUHDO_LibCustomGlow.PixelGlow_Start(
				VUHDO_getBarIconButton(aButton, anIconIndex),
				tCuDeStoConfig["iconGlowColor"] and { 
					tCuDeStoConfig["iconGlowColor"]["R"],
					tCuDeStoConfig["iconGlowColor"]["G"],
					tCuDeStoConfig["iconGlowColor"]["B"],
					tCuDeStoConfig["iconGlowColor"]["O"]
				} or { 
					VUHDO_PANEL_SETUP.BAR_COLORS["DEBUFF_ICON_GLOW"]["R"],
					VUHDO_PANEL_SETUP.BAR_COLORS["DEBUFF_ICON_GLOW"]["G"],
					VUHDO_PANEL_SETUP.BAR_COLORS["DEBUFF_ICON_GLOW"]["B"],
					VUHDO_PANEL_SETUP.BAR_COLORS["DEBUFF_ICON_GLOW"]["O"]
				}, 
				8,                                           -- number of particles
				0.3,                                         -- frequency
				6,                                           -- length
				2,                                           -- thickness
				0,                                           -- x offset
				0,                                           -- y offset
				false,                                       -- border
				VUHDO_CUSTOM_GLOW_CUDE_ICON_KEY
			);
		end
	elseif VUHDO_getBarIcon(aButton, anIconIndex):GetTexture() ~= anIconInfo[1] then
		VUHDO_getBarIcon(aButton, anIconIndex):SetTexture(anIconInfo[1]);
		VUHDO_PixelUtil.ApplySettings(VUHDO_getBarIcon(aButton, anIconIndex));

		VUHDO_getBarIconFrame(aButton, anIconIndex):SetAlpha(1);

		VUHDO_updateHealthBarsFor(aUnit, VUHDO_UPDATE_RANGE);
	end

	tAuraInstanceId = VUHDO_getBarIconFrame(aButton, anIconIndex)["debuffInstanceId"];

	tCurChosenInfo = VUHDO_getDebuffCurChosenInfo()[aUnit] and VUHDO_getDebuffCurChosenInfo()[aUnit][tAuraInstanceId];
	tType = tCurChosenInfo and tCurChosenInfo[1];

	if tType and tType > 0 and VUHDO_DEBUFF_COLORS[tType] and VUHDO_DEBUFF_COLORS[tType]["useBorder"] then
		-- offset for backdrop border
		VUHDO_getBarIcon(aButton, anIconIndex):SetTexCoord(.08, .92, .08, .92);

		tBackdropFrame = VUHDO_getBarIconFrameBackground(aButton, anIconIndex);

		if tBackdropFrame then
			if not tBackdropFrame:GetBackdrop() then
				VUHDO_PixelUtil.ApplyBackdrop(tBackdropFrame, tBackdropInfo);
			end

			tBackdropFrame:SetBackdropBorderColor(VUHDO_backColor(VUHDO_DEBUFF_COLORS[tType]));
			tBackdropFrame:SetAlpha(1);
			tBackdropFrame:Show();
		end
	else
		-- default border no offset
		VUHDO_getBarIcon(aButton, anIconIndex):SetTexCoord(0, 1, 0, 1);

		tBackdropFrame = VUHDO_getBarIconFrameBackground(aButton, anIconIndex);

		if tBackdropFrame then
			if tBackdropFrame:GetBackdrop() then
				tBackdropFrame:SetBackdrop(nil);
			end
		end
	end

	if tIsAnim then
		tButton = VUHDO_getBarIconButton(aButton, anIconIndex);
		tBaseScale = VUHDO_CONFIG["CUSTOM_DEBUFF"]["scale"] * 0.7;

		if tAliveTime <= 0.5 then
			tScaleFactor = 1 + tAliveTime * 2;
		elseif tAliveTime <= 1.0 then
			tScaleFactor = 3 - tAliveTime * 2;
		else
			tScaleFactor = 1;
		end

		tFinalScale = tBaseScale * tScaleFactor;
		VUHDO_PixelUtil.SetScale(tButton, tFinalScale);
	else -- Falls Custom Debuff vorher Animation hatte und dieser nicht
		tButton = VUHDO_getBarIconButton(aButton, anIconIndex);
		tBaseScale = VUHDO_CONFIG["CUSTOM_DEBUFF"]["scale"] * 0.7;
		VUHDO_PixelUtil.SetScale(tButton, tBaseScale);
	end

	if sIsName and tAliveTime > 2 then
		VUHDO_getBarIconName(aButton, anIconIndex):SetAlpha(0);
	end

	return;

end



--
local tNow;
function VUHDO_updateAllDebuffIcons(anIsFrequent)

	tNow = GetTime();

	for tUnit, tAllDebuffInfos in pairs(VUHDO_DEBUFF_ICONS) do
		for tIndex, tDebuffInfo in pairs(tAllDebuffInfos) do
			if not anIsFrequent or tDebuffInfo[2] + 1.21 >= tNow then
				for _, tButton in pairs(VUHDO_getUnitButtonsSafe(tUnit)) do
					VUHDO_animateDebuffIcon(tButton, tDebuffInfo, tNow, tIndex + 39, false, tUnit);
				end
			end
		end
	end

	return;

end



--
local tNow;
local tUnitDebuffInfos;
function VUHDO_updateUnitDebuffIcons(aUnit, anIsFrequent)

	if not aUnit or not VUHDO_DEBUFF_ICONS then
		return;
	end

	tNow = GetTime();

	tUnitDebuffInfos = VUHDO_DEBUFF_ICONS[aUnit];

	if tUnitDebuffInfos then
		for tIndex, tDebuffInfo in pairs(tUnitDebuffInfos) do
			if not anIsFrequent or tDebuffInfo[2] + 1.21 >= tNow then
				for _, tButton in pairs(VUHDO_getUnitButtonsSafe(aUnit)) do
					VUHDO_animateDebuffIcon(tButton, tDebuffInfo, tNow, tIndex + 39, false, aUnit);
				end
			end
		end
	end

	return;

end



--
function VUHDO_deferUpdateAllDebuffIcons(anIsFrequent, aPriority)

	if not VUHDO_DEBUFF_ICONS then
		return;
	end

	for tUnit, _ in pairs(VUHDO_DEBUFF_ICONS) do
		VUHDO_deferTask(VUHDO_DEFER_UPDATE_UNIT_DEBUFF_ICONS, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_HIGH, tUnit, anIsFrequent);
	end

	return;

end



--
local tExistingSlot;
local tOldest;
local tSlot;
local tTimestamp;
local tIconInfoOld;
local tIconInfoNew;
local tFrame;
function VUHDO_addDebuffIcon(aUnit, anIcon, aName, anExpiry, aStacks, aDuration, anIsBuff, aSpellId, anAuraInstanceId, aCnt)

	if not VUHDO_DEBUFF_ICONS[aUnit] then
		VUHDO_DEBUFF_ICONS[aUnit] = { };
	end

	if not VUHDO_DEBUFF_ICONS_MAP[aUnit] then
		VUHDO_DEBUFF_ICONS_MAP[aUnit] = { };
	end

	tExistingSlot = VUHDO_DEBUFF_ICONS_MAP[aUnit][anAuraInstanceId];

	if tExistingSlot then
		VUHDO_updateDebuffIcon(aUnit, anIcon, aName, anExpiry, aStacks, aDuration, anIsBuff, aSpellId, anAuraInstanceId);

		return;
	end

	tOldest = huge;
	tSlot = 1;

	for tCnt = 1, sMaxIcons do
		if not VUHDO_DEBUFF_ICONS[aUnit][tCnt] then
			tSlot = tCnt;

			break;
		else
			tTimestamp = VUHDO_DEBUFF_ICONS[aUnit][tCnt][2];

			if tTimestamp > 0 and tTimestamp < tOldest then
				tOldest = tTimestamp;
				tSlot = tCnt;
			end
		end
	end

	tIconInfoOld = VUHDO_DEBUFF_ICONS[aUnit][tSlot];

	if tIconInfoOld then
		VUHDO_DEBUFF_ICONS_MAP[aUnit][tIconInfoOld[8]] = nil;

		VUHDO_releasePooledIconArray(tIconInfoOld);
	end

	tIconInfoNew = VUHDO_getPooledIconArray();

	-- 1 = icon, 2 = timestamp, 3 = name, 4 = expiration time, 5 = stacks, 6 = duration, 7 = spell ID, 8 = aura instance ID
	tIconInfoNew[1], tIconInfoNew[2], tIconInfoNew[3], tIconInfoNew[4], tIconInfoNew[5],
	tIconInfoNew[6], tIconInfoNew[7], tIconInfoNew[8] =
		anIcon, -1, aName, anExpiry, aStacks,
		aDuration, aSpellId, anAuraInstanceId;

	VUHDO_DEBUFF_ICONS[aUnit][tSlot] = tIconInfoNew;
	VUHDO_DEBUFF_ICONS_MAP[aUnit][anAuraInstanceId] = tSlot;

	for _, tButton in pairs(VUHDO_getUnitButtonsSafe(aUnit)) do
		tFrame = VUHDO_getBarIconFrame(tButton, tSlot + 39);

		if tFrame then
			tFrame["debuffInfo"], tFrame["debuffSpellId"], tFrame["isBuff"], tFrame["debuffInstanceId"], tFrame["debuffCnt"] = aName, aSpellId, anIsBuff, anAuraInstanceId, aCnt;

			VUHDO_animateDebuffIcon(tButton, tIconInfoNew, GetTime(), tSlot + 39, true, aUnit);
	        end
	end

	tIconInfoNew[2] = GetTime();

	VUHDO_updateHealthBarsFor(aUnit, VUHDO_UPDATE_RANGE);

	return;

end



--
local tSlot;
local tIconInfo;
local tFrame;
function VUHDO_updateDebuffIcon(aUnit, anIcon, aName, anExpiry, aStacks, aDuration, anIsBuff, aSpellId, anAuraInstanceId, aCnt)

	if not VUHDO_DEBUFF_ICONS[aUnit] then
		VUHDO_DEBUFF_ICONS[aUnit] = { };
	end

	if not VUHDO_DEBUFF_ICONS_MAP[aUnit] then
		VUHDO_DEBUFF_ICONS_MAP[aUnit] = { };
	end

	tSlot = VUHDO_DEBUFF_ICONS_MAP[aUnit][anAuraInstanceId];

	if tSlot then
		tIconInfo = VUHDO_DEBUFF_ICONS[aUnit][tSlot];

		tIconInfo[1], tIconInfo[3], tIconInfo[4], tIconInfo[5], tIconInfo[6], tIconInfo[7], tIconInfo[8] =
			anIcon, aName, anExpiry, aStacks, aDuration, aSpellId, anAuraInstanceId;

		for _, tButton in pairs(VUHDO_getUnitButtonsSafe(aUnit)) do
			tFrame = VUHDO_getBarIconFrame(tButton, tSlot + 39);

			tFrame["debuffInfo"], tFrame["debuffSpellId"], tFrame["isBuff"], tFrame["debuffInstanceId"], tFrame["debuffCnt"] = aName, aSpellId, anIsBuff, anAuraInstanceId, aCnt;
		end
	else
		VUHDO_addDebuffIcon(aUnit, anIcon, aName, anExpiry, aStacks, aDuration, anIsBuff, aSpellId, anAuraInstanceId, aCnt);
	end

	return;

end



--
local tSlot;
local tIconArray;
local tAllButtons2;
local tFrame;
function VUHDO_removeDebuffIcon(aUnit, anAuraInstanceId)

	if not VUHDO_DEBUFF_ICONS[aUnit] then
		return;
	end

	tSlot = VUHDO_DEBUFF_ICONS_MAP[aUnit] and VUHDO_DEBUFF_ICONS_MAP[aUnit][anAuraInstanceId];

	if not tSlot then
		return;
	end

	tIconArray = VUHDO_DEBUFF_ICONS[aUnit][tSlot];

	if not tIconArray then
		return;
	end

	tAllButtons2 = VUHDO_getUnitButtons(aUnit);

	if tAllButtons2 then
		for _, tButton2 in pairs(tAllButtons2) do
			VUHDO_LibCustomGlow.PixelGlow_Stop(tButton2, VUHDO_CUSTOM_GLOW_CUDE_FRAME_KEY);

			tFrame = VUHDO_getBarIconFrame(tButton2, tSlot + 39);

			if tFrame then
				VUHDO_LibCustomGlow.PixelGlow_Stop(tFrame, VUHDO_CUSTOM_GLOW_CUDE_ICON_KEY);

				tFrame:SetAlpha(0);

				tFrame["debuffInfo"] = nil;
				tFrame["debuffSpellId"] = nil;
				tFrame["isBuff"] = nil;
				tFrame["debuffInstanceId"] = nil;
			end
		end
	end

	VUHDO_DEBUFF_ICONS[aUnit][tSlot] = nil;
	VUHDO_DEBUFF_ICONS_MAP[aUnit][anAuraInstanceId] = nil;

	VUHDO_releasePooledIconArray(tIconArray);

	return;

end



--
local tFrame;
function VUHDO_removeAllDebuffIcons(aUnit)

	tAllButtons3 = VUHDO_getUnitButtons(aUnit);

	if not tAllButtons3 then
		return;
	end

	for _, tButton3 in pairs(tAllButtons3) do
		VUHDO_LibCustomGlow.PixelGlow_Stop(tButton3, VUHDO_CUSTOM_GLOW_CUDE_FRAME_KEY);

		for tCnt3 = 40, 39 + sMaxIcons do
			tFrame = VUHDO_getBarIconFrame(tButton3, tCnt3);

			if tFrame then
				VUHDO_LibCustomGlow.PixelGlow_Stop(tFrame, VUHDO_CUSTOM_GLOW_CUDE_ICON_KEY);

				tFrame:SetAlpha(0);
				
				tFrame["debuffInfo"] = nil;
				tFrame["debuffSpellId"] = nil;
				tFrame["isBuff"] = nil;
				tFrame["debuffInstanceId"] = nil;
			end
		end
	end

	if VUHDO_DEBUFF_ICONS[aUnit] then
		for tCnt, tIconArray in pairs(VUHDO_DEBUFF_ICONS[aUnit]) do
			VUHDO_releasePooledIconArray(tIconArray);

			VUHDO_DEBUFF_ICONS[aUnit][tCnt] = nil;
	        end
	end

	if VUHDO_DEBUFF_ICONS_MAP[aUnit] then
		twipe(VUHDO_DEBUFF_ICONS_MAP[aUnit]);
	end

	VUHDO_updateBouquetsForEvent(aUnit, 29);

	return;

end



--
local tDebuffInfo;
local tCurrInfo;
function VUHDO_getLatestCustomDebuff(aUnit)

	tDebuffInfo = sEmpty;

	for tCnt = 1, sMaxIcons do
		tCurrInfo = (VUHDO_DEBUFF_ICONS[aUnit] or sEmpty)[tCnt];

		if tCurrInfo and tCurrInfo[2] > (tDebuffInfo[2] or 0) then
			tDebuffInfo = tCurrInfo;
		end
	end

	return tDebuffInfo[1], tDebuffInfo[4], tDebuffInfo[5], tDebuffInfo[6];

end



--
function VUHDO_getDebuffIcons()

	return VUHDO_DEBUFF_ICONS;

end
