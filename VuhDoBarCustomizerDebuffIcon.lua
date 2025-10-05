VUHDO_MAY_DEBUFF_ANIM = true;

local VUHDO_DEBUFF_ICONS = { };
local VUHDO_DEBUFF_ICONS_MAP = { };
local VUHDO_MAX_ANIMATION_SCALE = 1.3;

-- BURST CACHE ---------------------------------------------------

local _;

local floor = floor;
local max = max;
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
local VUHDO_getBarIconClockOrStub;
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
local sIsName;
local sStaticConfig;
local VUHDO_DEBUFF_COLORS;
local sOriginalFrameLevels = { };
local sAnimatedDebuffs = { };
local sAnimationGroups = { };
local sAuraFrames = { };

local sEmpty = { };

function VUHDO_customDebuffIconsInitLocalOverrides()

	-- functions
	VUHDO_getUnitButtons = _G["VUHDO_getUnitButtons"];
	VUHDO_getBarIconTimer = _G["VUHDO_getBarIconTimer"];
	VUHDO_getBarIconCounter = _G["VUHDO_getBarIconCounter"];
	VUHDO_getBarIconFrame = _G["VUHDO_getBarIconFrame"];
	VUHDO_getBarIcon = _G["VUHDO_getBarIcon"];
	VUHDO_getBarIconName = _G["VUHDO_getBarIconName"];
	VUHDO_getBarIconClockOrStub = _G["VUHDO_getBarIconClockOrStub"];
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
		["isFullDuration"] = VUHDO_CONFIG["CUSTOM_DEBUFF"]["isFullDuration"],
		["isMine"] = true,
		["isOthers"] = true,
		["isBarGlow"] = false,
		["isIconGlow"] = false,
		["isClock"] = VUHDO_CONFIG["CUSTOM_DEBUFF"]["isClock"],
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
local tBlacklistModi;
local function VUHDO_areBlacklistModifiersPressed()

	if not VUHDO_CONFIG or not VUHDO_CONFIG["CUSTOM_DEBUFF"] then
		return IsAltKeyDown() and IsControlKeyDown() and IsShiftKeyDown();
	end

	tBlacklistModi = VUHDO_CONFIG["CUSTOM_DEBUFF"]["blacklistModi"] or "ALT-CTRL-SHIFT";

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
local tBarIcon;
local tBarIconTimer;
local tBarIconFrame;
local tBarIconCounter;
local tBarIconButton;
local tBarIconName;
local tBarIconFrameBackground;
local tIsAnim;
local tIsBarGlow;
local tIsIconGlow;
local tTimeStamp;
local tActualAliveTime;
local tAliveTime;
local tName;
local tRemain;
local tShieldPerc;
local tStacks;
local tAuraInstanceId;
local tCurChosenInfo;
local tType;
local tIsPlaying;
local tClock;
local tStarted;
local tClockDuration;
local tMinDuration;
local tShouldAnimate;
local tExistingAnimGroup;
local tButtonName;
local tR;
local tG;
local tB;
local tA;
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
local tAnimGroup;
local tAnimationKey;
local tLookedUpAnimGroup;
local function VUHDO_animateDebuffIcon(aButton, anIconInfo, aNow, anIconIndex, anIsInit, aUnit)

	tTimeStamp = anIconInfo[2];
	tName = anIconInfo[3];
	tStacks = anIconInfo[5];
	tMinDuration = anIconInfo[6];
	tAuraInstanceId = anIconInfo[8];

	tCuDeStoConfig = sCuDeStoredSettings[tName] or sCuDeStoredSettings[tostring(anIconInfo[7])] or sStaticConfig;

	if tCuDeStoConfig["isStaticConfig"] and
		(VUHDO_DEBUFF_BLACKLIST[tName] or VUHDO_DEBUFF_BLACKLIST[tostring(anIconInfo[7])]) then
		VUHDO_removeDebuffIcon(aUnit, tAuraInstanceId);

		return;
	end

	tBarIcon = VUHDO_getBarIcon(aButton, anIconIndex);
	tBarIconTimer = VUHDO_getBarIconTimer(aButton, anIconIndex);
	tBarIconFrame = VUHDO_getBarIconFrame(aButton, anIconIndex);
	tBarIconCounter = VUHDO_getBarIconCounter(aButton, anIconIndex);
	tBarIconButton = VUHDO_getBarIconButton(aButton, anIconIndex);
	tBarIconName = VUHDO_getBarIconName(aButton, anIconIndex);
	tBarIconFrameBackground = VUHDO_getBarIconFrameBackground(aButton, anIconIndex);

	tIsAnim = tCuDeStoConfig["animate"] and VUHDO_MAY_DEBUFF_ANIM;
	tIsBarGlow = tCuDeStoConfig["isBarGlow"];
	tIsIconGlow = tCuDeStoConfig["isIconGlow"];
	tActualAliveTime = (tTimeStamp and tTimeStamp > 0) and (aNow - tTimeStamp) or 0;
	tAliveTime = anIsInit and 0 or tActualAliveTime;

	if not (anIsInit and tTimeStamp == -1) then
		tRemain = (anIconInfo[4] or aNow - 1) - aNow;
	else
		tRemain = 0;
	end

	if tCuDeStoConfig["timer"] then
		if tCuDeStoConfig["isAliveTime"] then
			tBarIconTimer:SetText(tAliveTime < 99.5 and floor(tAliveTime + 0.5) or ">>");
		else
			if anIsInit and tTimeStamp == -1 then
				tBarIconTimer:SetText("");
			else
				if tRemain >= 0 and (tRemain < 10 or tCuDeStoConfig["isFullDuration"]) then
					tBarIconTimer:SetText(tRemain > 100 and ">>" or floor(tRemain));
				else
					tBarIconTimer:SetText("");
				end
			end
		end
	end

	if tCuDeStoConfig["isClock"] then
		tClock = VUHDO_getBarIconClockOrStub(aButton, anIconIndex, tCuDeStoConfig["isClock"]);

		if tRemain and tRemain > 0 and tMinDuration and tMinDuration > 0 then
			tStarted = floor(10 * (aNow - tMinDuration + tRemain) + 0.5) * 0.1;
			tClockDuration = tClock:GetCooldownDuration() * 0.001;
			tMinDuration = max(tMinDuration, 0.1);

			if tMinDuration > 0 and
				(tClock:GetAlpha() == 0 or (tClock:GetAttribute("started") or tStarted) ~= tStarted or
				(tClock:IsVisible() and (tMinDuration > tClockDuration or tMinDuration < 0.1))) then
				tClock:SetCooldown(tStarted, tMinDuration);
				tClock:SetAttribute("started", tStarted);

				tClock:SetAlpha(1);
			end
		else
			tClock:SetAlpha(0);
		end
	else
		tClock = VUHDO_getBarIconClockOrStub(aButton, anIconIndex, false);

		tClock:SetAlpha(0);
	end

	tShieldPerc = VUHDO_getShieldPerc(aUnit, tName);
	tStacks = tShieldPerc ~= 0 and tShieldPerc or tStacks or 0;

	tBarIconCounter:SetText((tCuDeStoConfig["isStacks"] and tStacks > 1) and tStacks or "");

	if anIsInit then
		tBarIcon:SetTexture(anIconInfo[1]);
		VUHDO_PixelUtil.ApplySettings(tBarIcon);

		if sIsName then
			tBarIconName:SetText(tName);
			tBarIconName:SetAlpha(1);
		end

		tBarIconFrame:SetAlpha(1);

		tShouldAnimate = false;
		tAnimGroup = nil;

		if tIsAnim then
			tButtonName = aButton:GetName();
			tAnimationKey = tButtonName .. "_" .. anIconIndex;

			if not sAuraFrames[tAuraInstanceId] then
				sAuraFrames[tAuraInstanceId] = { };
			end

			for tFrameKey, _ in pairs(sAuraFrames[tAuraInstanceId]) do
				if tFrameKey ~= tAnimationKey then
					tExistingAnimGroup = sAnimationGroups[tFrameKey];

					if tExistingAnimGroup and tExistingAnimGroup:IsPlaying() then
						tShouldAnimate = true;

						break;
					end
				end
			end

			if not tShouldAnimate and not sAnimatedDebuffs[tAuraInstanceId] then
				if not tTimeStamp or tTimeStamp <= 0 or (tTimeStamp > 0 and tActualAliveTime < 0.05) then
					tShouldAnimate = true;
				end
			end

			if tShouldAnimate then
				if not sAnimatedDebuffs[tAuraInstanceId] then
					sAnimatedDebuffs[tAuraInstanceId] = true;
				end

				for tOtherAuraId, tFrameKeys in pairs(sAuraFrames) do
					if tOtherAuraId ~= tAuraInstanceId and tFrameKeys[tAnimationKey] then
						tFrameKeys[tAnimationKey] = nil;
					end
				end

				sAuraFrames[tAuraInstanceId][tAnimationKey] = true;

				tAnimGroup = VUHDO_createDebuffIconAnimation(aButton, anIconIndex, tAuraInstanceId);
			else
				tAnimGroup = nil;
			end
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
			if tIsAnim and tShouldAnimate and tAnimGroup then
				if not tAnimGroup["iconGlowSettings"] then
					tAnimGroup["iconGlowSettings"] = {
						["button"] = tBarIconButton,
						["color"] = tCuDeStoConfig["iconGlowColor"] and {
							tCuDeStoConfig["iconGlowColor"]["R"],
							tCuDeStoConfig["iconGlowColor"]["G"],
							tCuDeStoConfig["iconGlowColor"]["B"],
							tCuDeStoConfig["iconGlowColor"]["O"]
						} or {
							VUHDO_PANEL_SETUP.BAR_COLORS["DEBUFF_ICON_GLOW"]["R"],
							VUHDO_PANEL_SETUP.BAR_COLORS["DEBUFF_ICON_GLOW"]["G"],
							VUHDO_PANEL_SETUP.BAR_COLORS["DEBUFF_ICON_GLOW"]["B"],
							VUHDO_PANEL_SETUP.BAR_COLORS["DEBUFF_ICON_GLOW"]["O"]
						}
					};
				end
			else
				VUHDO_LibCustomGlow.PixelGlow_Start(
					tBarIconButton,
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
		end

		if tIsAnim and tShouldAnimate and tAnimGroup and not tAnimGroup:IsPlaying() then
			tAnimGroup:Play();
		end
	elseif tBarIcon:GetTexture() ~= anIconInfo[1] then
		tBarIcon:SetTexture(anIconInfo[1]);
		VUHDO_PixelUtil.ApplySettings(tBarIcon);

		tBarIconFrame:SetAlpha(1);

		VUHDO_updateHealthBarsFor(aUnit, VUHDO_UPDATE_RANGE);
	end

	if tBarIconFrame and tBarIconFrame:GetAlpha() == 0 and tBarIconFrame["debuffInfo"] == tName and tBarIconFrame["debuffInstanceId"] == tAuraInstanceId then
		tBarIconFrame:SetAlpha(1);
	end

	tAuraInstanceId = tBarIconFrame["debuffInstanceId"];

	tCurChosenInfo = VUHDO_getDebuffCurChosenInfo()[aUnit] and VUHDO_getDebuffCurChosenInfo()[aUnit][tAuraInstanceId];
	tType = tCurChosenInfo and tCurChosenInfo[1];

	if not tAnimGroup and tIsAnim then
		tButtonName = aButton:GetName();
		tAnimationKey = tButtonName .. "_" .. anIconIndex;
		tLookedUpAnimGroup = sAnimationGroups[tAnimationKey];

		if tLookedUpAnimGroup and tLookedUpAnimGroup:IsPlaying() then
			tAnimGroup = tLookedUpAnimGroup;
		end
	end

	if tType and tType > 0 and VUHDO_DEBUFF_COLORS[tType] and VUHDO_DEBUFF_COLORS[tType]["useBorder"] then
		tIsPlaying = tAnimGroup and tAnimGroup:IsPlaying();

		if tIsAnim and tAnimGroup and tIsPlaying then
			tBarIcon:SetTexCoord(0, 1, 0, 1);

			if tBarIconFrameBackground then
				tBarIconFrameBackground:SetBackdropBorderColor(0, 0, 0, 0);
			end
		else
			tBarIcon:SetTexCoord(.08, .92, .08, .92);

			if tBarIconFrameBackground then
				if not tBarIconFrameBackground:GetBackdrop() then
					VUHDO_PixelUtil.ApplyBackdrop(tBarIconFrameBackground, tBackdropInfo);
				end

				tR, tG, tB, tA = VUHDO_backColor(VUHDO_DEBUFF_COLORS[tType]);
				tBarIconFrameBackground:SetBackdropBorderColor(tR, tG, tB, tA);

				tBarIconFrameBackground["originalBorderColor"] = {tR, tG, tB, tA};

				tBarIconFrameBackground:SetAlpha(1);
				tBarIconFrameBackground:Show();
			end
		end
	else
		tBarIcon:SetTexCoord(0, 1, 0, 1);

		if tBarIconFrameBackground then
			if tBarIconFrameBackground:GetBackdrop() then
				tBarIconFrameBackground:SetBackdrop(nil);
			end
		end
	end

	if sIsName and tAliveTime > 2 then
		tBarIconName:SetAlpha(0);
	end

	return;

end



--
local tIconButton;
local tAnimKey;
local function VUHDO_onAnimationPlay(self)

	tAnimKey = self["animKey"];

	if not tAnimKey then
		return;
	end

	tIconButton = self:GetParent();

	if tIconButton then
		sOriginalFrameLevels[tAnimKey] = tIconButton:GetFrameLevel();

		VUHDO_PixelUtil.SetFrameLevel(tIconButton, sOriginalFrameLevels[tAnimKey] + 10);
	end

	return;

end



--
local tIconButton;
local tBarIconFrameBackground;
local tAnimKey;
local tGlowSettings;
local tButton;
local tSuccess;
local tIconTexture;
local function VUHDO_onAnimationFinished(self)

	tAnimKey = self["animKey"];

	if not tAnimKey then
		return;
	end

	tIconButton = self:GetParent();

	if tIconButton then
		VUHDO_PixelUtil.SetScale(tIconButton, 1);

		if self["iconGlowSettings"] then
			tGlowSettings = self["iconGlowSettings"];

			if tGlowSettings["button"] and tGlowSettings["color"] then
				VUHDO_LibCustomGlow.PixelGlow_Start(
					tGlowSettings["button"],
					tGlowSettings["color"],
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
			self["iconGlowSettings"] = nil;
		end

		if sOriginalFrameLevels[tAnimKey] then
			VUHDO_PixelUtil.SetFrameLevel(tIconButton, sOriginalFrameLevels[tAnimKey]);
		end

		tBarIconFrameBackground = tIconButton;

		if tBarIconFrameBackground and tBarIconFrameBackground:GetBackdrop() then
			if tBarIconFrameBackground["originalBorderColor"] then
				tBarIconFrameBackground:SetBackdropBorderColor(tBarIconFrameBackground["originalBorderColor"][1], tBarIconFrameBackground["originalBorderColor"][2], tBarIconFrameBackground["originalBorderColor"][3], tBarIconFrameBackground["originalBorderColor"][4]);
			end

			if self["iconIndex"] then
				tButton = tIconButton:GetParent():GetParent();

				if tButton then
					tSuccess, tIconTexture = pcall(VUHDO_getBarIcon, tButton, self["iconIndex"]);

					if tSuccess and tIconTexture and tIconTexture.SetTexCoord then
						tIconTexture:SetTexCoord(.08, .92, .08, .92);
					end
				end
			end
		end
	end

	return;

end



--
local tBarIconButton;
local tAnimationKey;
local tAnimGroup;
local tScaleAnimOut;
local tScaleAnimIn;
function VUHDO_createDebuffIconAnimation(aButton, anIconIndex, anAuraInstanceId)

	tBarIconButton = VUHDO_getBarIconButton(aButton, anIconIndex);

	if not tBarIconButton then
		return;
	end

	tAnimationKey = aButton:GetName() .. "_" .. anIconIndex;
	tAnimGroup = sAnimationGroups[tAnimationKey];

	if not tAnimGroup then
		tAnimGroup = tBarIconButton:CreateAnimationGroup();

		tAnimGroup:SetLooping("NONE");

		tScaleAnimOut = tAnimGroup:CreateAnimation("Scale");

		tScaleAnimOut:SetOrigin("CENTER", 0, 0);
		tScaleAnimOut:SetScaleFrom(1, 1);
		tScaleAnimOut:SetScaleTo(VUHDO_MAX_ANIMATION_SCALE, VUHDO_MAX_ANIMATION_SCALE);
		tScaleAnimOut:SetDuration(0.5);
		tScaleAnimOut:SetSmoothing("NONE");
		tScaleAnimOut:SetOrder(1);

		tScaleAnimIn = tAnimGroup:CreateAnimation("Scale");

		tScaleAnimIn:SetOrigin("CENTER", 0, 0);
		tScaleAnimIn:SetScaleFrom(VUHDO_MAX_ANIMATION_SCALE, VUHDO_MAX_ANIMATION_SCALE);
		tScaleAnimIn:SetScaleTo(1, 1);
		tScaleAnimIn:SetDuration(0.5);
		tScaleAnimIn:SetSmoothing("NONE");
		tScaleAnimIn:SetOrder(2);

		tAnimGroup:SetScript("OnPlay", VUHDO_onAnimationPlay);
		tAnimGroup:SetScript("OnFinished", VUHDO_onAnimationFinished);

		tAnimGroup["iconIndex"] = anIconIndex;
		tAnimGroup["animKey"] = tAnimationKey;

		sAnimationGroups[tAnimationKey] = tAnimGroup;
	end

	return tAnimGroup;

end



--
local tAnimationKey;
local tAnimGroup;
local tBarIconButton;
function VUHDO_cleanupDebuffIconAnimation(aButton, anIconIndex)

	tAnimationKey = aButton:GetName() .. "_" .. anIconIndex;
	tAnimGroup = sAnimationGroups[tAnimationKey];

	if tAnimGroup then
		tAnimGroup:Stop();

		tBarIconButton = VUHDO_getBarIconButton(aButton, anIconIndex);

		if tBarIconButton then
			VUHDO_PixelUtil.SetScale(tBarIconButton, 1);

			if sOriginalFrameLevels[tAnimationKey] then
				VUHDO_PixelUtil.SetFrameLevel(tBarIconButton, sOriginalFrameLevels[tAnimationKey]);
			end
		end

		sAnimationGroups[tAnimationKey] = nil;
		sOriginalFrameLevels[tAnimationKey] = nil;
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
function VUHDO_addDebuffIcon(aUnit, anIcon, aName, anExpiry, aStacks, aDuration, anIsBuff, aSpellId, anAuraInstanceId)

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
			tFrame["debuffInfo"], tFrame["debuffSpellId"], tFrame["isBuff"], tFrame["debuffInstanceId"] = aName, aSpellId, anIsBuff, anAuraInstanceId;

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
function VUHDO_updateDebuffIcon(aUnit, anIcon, aName, anExpiry, aStacks, aDuration, anIsBuff, aSpellId, anAuraInstanceId)

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

			tFrame["debuffInfo"], tFrame["debuffSpellId"], tFrame["isBuff"], tFrame["debuffInstanceId"] = aName, aSpellId, anIsBuff, anAuraInstanceId;
		end
	else
		VUHDO_addDebuffIcon(aUnit, anIcon, aName, anExpiry, aStacks, aDuration, anIsBuff, aSpellId, anAuraInstanceId);
	end

	return;

end



--
local tSlot;
local tIconArray;
local tAllButtons;
local tFrame;
local tAnimKey;
local tAnimGroup;
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

	tAllButtons = VUHDO_getUnitButtons(aUnit);

	if tAllButtons then
		for _, tButton in pairs(tAllButtons) do
			VUHDO_LibCustomGlow.PixelGlow_Stop(tButton, VUHDO_CUSTOM_GLOW_CUDE_FRAME_KEY);

			VUHDO_cleanupDebuffIconAnimation(tButton, tSlot + 39);

			tFrame = VUHDO_getBarIconFrame(tButton, tSlot + 39);

			if tFrame then
				tAnimKey = tButton:GetName() .. "_" .. (tSlot + 39);
				tAnimGroup = sAnimationGroups[tAnimKey];

				if not (tAnimGroup and tAnimGroup:IsPlaying()) then
					VUHDO_LibCustomGlow.PixelGlow_Stop(VUHDO_getBarIconButton(tButton, tSlot + 39), VUHDO_CUSTOM_GLOW_CUDE_ICON_KEY);
				end

				if sAuraFrames[anAuraInstanceId] then
					sAuraFrames[anAuraInstanceId][tAnimKey] = nil;
				end

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
	sAnimatedDebuffs[anAuraInstanceId] = nil;
	sAuraFrames[anAuraInstanceId] = nil;

	VUHDO_releasePooledIconArray(tIconArray);

	return;

end



--
local tFrame;
local tAllButtons;
local tAnimKey;
local tAnimGroup;
function VUHDO_removeAllDebuffIcons(aUnit)

	tAllButtons = VUHDO_getUnitButtons(aUnit);

	if not tAllButtons then
		return;
	end

	for _, tButton in pairs(tAllButtons) do
		VUHDO_LibCustomGlow.PixelGlow_Stop(tButton, VUHDO_CUSTOM_GLOW_CUDE_FRAME_KEY);

		for tCnt = 40, 39 + sMaxIcons do
			tFrame = VUHDO_getBarIconFrame(tButton, tCnt);

			if tFrame then
				tAnimKey = tButton:GetName() .. "_" .. tCnt;
				tAnimGroup = sAnimationGroups[tAnimKey];

				if not (tAnimGroup and tAnimGroup:IsPlaying()) then
					VUHDO_LibCustomGlow.PixelGlow_Stop(VUHDO_getBarIconButton(tButton, tCnt), VUHDO_CUSTOM_GLOW_CUDE_ICON_KEY);
				end

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



--
function VUHDO_getDebuffIconsMap()

	return VUHDO_DEBUFF_ICONS_MAP;

end