local _;

local pairs = pairs;
local twipe = table.wipe;
local floor = math.floor;
local format = string.format;

local InCombatLockdown = InCombatLockdown;
local CreateFrame = CreateFrame;
local CreateFramePool = CreateFramePool;
local GetAuraDuration = C_UnitAuras and C_UnitAuras.GetAuraDuration;
local GetAuraApplicationDisplayCount = C_UnitAuras and C_UnitAuras.GetAuraApplicationDisplayCount;
local GetAuraDispelTypeColor = C_UnitAuras and C_UnitAuras.GetAuraDispelTypeColor;
local issecretvalue = issecretvalue;
local AbbreviateNumbers = AbbreviateNumbers;
local CreateCurve = C_CurveUtil and C_CurveUtil.CreateCurve;
local CreateColorCurve = C_CurveUtil and C_CurveUtil.CreateColorCurve;
local CreateColor = CreateColor;

local VUHDO_CONFIG;
local VUHDO_PANEL_SETUP;
local VUHDO_RAID;
local VUHDO_BUTTON_CACHE;
local VUHDO_UNIT_AURA_CACHE;
local VUHDO_UNIT_AURA_SLOTS;
local VUHDO_STATUSBAR_LEFT_TO_RIGHT;
local VUHDO_STATUSBAR_RIGHT_TO_LEFT;
local VUHDO_STATUSBAR_BOTTOM_TO_TOP;
local VUHDO_STATUSBAR_TOP_TO_BOTTOM;

local VUHDO_PixelUtil;
local VUHDO_UIFrameFlash;
local VUHDO_UIFrameFlashStop;

local VUHDO_safeSetAttribute;
local VUHDO_safeWrapScript;
local VUHDO_findButtonFromChild;
local VUHDO_getUnitButtonsPanel;
local VUHDO_getHealthBar;
local VUHDO_getHealthBarWidth;
local VUHDO_getHealthBarHeight;
local VUHDO_customizeIconText;
local VUHDO_textColor;
local VUHDO_setLlcStatusBarTexture;
local VUHDO_setStatusBarOrientation;
local VUHDO_getClassColor;
local VUHDO_safeColorFromTable;
local VUHDO_resolveAuraTriState;
local VUHDO_getAnchorTriStateBool;
local VUHDO_getAuraGroup;
local VUHDO_getDispelCurveForUnit;

VUHDO_AURA_FRAMES = VUHDO_AURA_FRAMES or { };
local VUHDO_AURA_FRAMES = VUHDO_AURA_FRAMES;

VUHDO_FIXED_AURA_OVERFLOW_STATE = VUHDO_FIXED_AURA_OVERFLOW_STATE or { };
local VUHDO_FIXED_AURA_OVERFLOW_STATE = VUHDO_FIXED_AURA_OVERFLOW_STATE;

VUHDO_AURA_RADIOVALUE_POSITIONS = VUHDO_AURA_RADIOVALUE_POSITIONS or {
	[1] = {
		["anchor"] = "RIGHT",
		["relPoint"] = "LEFT",
		["relFrame"] = "Button",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[2] = {
		["anchor"] = "LEFT",
		["relPoint"] = "LEFT",
		["relFrame"] = "HealthBar",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[3] = {
		["anchor"] = "RIGHT",
		["relPoint"] = "RIGHT",
		["relFrame"] = "HealthBar",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[4] = {
		["anchor"] = "LEFT",
		["relPoint"] = "RIGHT",
		["relFrame"] = "Button",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[5] = {
		["anchor"] = "TOPLEFT",
		["relPoint"] = "BOTTOMLEFT",
		["relFrame"] = "HealthBar",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[6] = {
		["anchor"] = "TOPRIGHT",
		["relPoint"] = "BOTTOMRIGHT",
		["relFrame"] = "HealthBar",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[7] = {
		["anchor"] = "TOPLEFT",
		["relPoint"] = "BOTTOMLEFT",
		["relFrame"] = "Button",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[8] = {
		["anchor"] = "TOPRIGHT",
		["relPoint"] = "BOTTOMRIGHT",
		["relFrame"] = "Button",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[9] = {
		["anchor"] = "TOPLEFT",
		["relPoint"] = "TOPLEFT",
		["relFrame"] = "HealthBar",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[10] = {
		["anchor"] = "TOPLEFT",
		["relPoint"] = "TOPLEFT",
		["relFrame"] = "HealthBar",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[11] = {
		["anchor"] = "BOTTOMRIGHT",
		["relPoint"] = "BOTTOMRIGHT",
		["relFrame"] = "HealthBar",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[12] = {
		["anchor"] = "BOTTOMLEFT",
		["relPoint"] = "BOTTOMLEFT",
		["relFrame"] = "HealthBar",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[13] = {
		["anchor"] = "BOTTOMLEFT",
		["relPoint"] = "BOTTOMLEFT",
		["relFrame"] = "Button",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[14] = {
		["anchor"] = "BOTTOMRIGHT",
		["relPoint"] = "BOTTOMRIGHT",
		["relFrame"] = "Button",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[15] = {
		["anchor"] = "TOP",
		["relPoint"] = "TOP",
		["relFrame"] = "HealthBar",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[16] = {
		["anchor"] = "CENTER",
		["relPoint"] = "CENTER",
		["relFrame"] = "HealthBar",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
	[17] = {
		["anchor"] = "TOPRIGHT",
		["relPoint"] = "TOPRIGHT",
		["relFrame"] = "Button",
		["xOffset"] = 0,
		["yOffset"] = 0,
	},
};
local VUHDO_AURA_RADIOVALUE_POSITIONS = VUHDO_AURA_RADIOVALUE_POSITIONS;

VUHDO_AURA_FIXED_STRAIGHT_POSITIONS = VUHDO_AURA_FIXED_STRAIGHT_POSITIONS or {
	[1] = {
		["anchor"] = "LEFT",
		["relPoint"] = "LEFT",
		["xPercent"] = 0,
		["yPercent"] = 0,
	},
	[2] = {
		["anchor"] = "TOP",
		["relPoint"] = "TOP",
		["xPercent"] = -0.2,
		["yPercent"] = 0,
	},
	[3] = {
		["anchor"] = "RIGHT",
		["relPoint"] = "RIGHT",
		["xPercent"] = 0,
		["yPercent"] = 0,
	},
	[4] = {
		["anchor"] = "BOTTOM",
		["relPoint"] = "BOTTOM",
		["xPercent"] = 0.2,
		["yPercent"] = 0,
	},
	[5] = {
		["anchor"] = "BOTTOM",
		["relPoint"] = "BOTTOM",
		["xPercent"] = -0.2,
		["yPercent"] = 0,
	},
	[6] = {
		["anchor"] = "TOP",
		["relPoint"] = "TOP",
		["xPercent"] = 0.2,
		["yPercent"] = 0,
	},
	[7] = {
		["anchor"] = "CENTER",
		["relPoint"] = "CENTER",
		["xPercent"] = 0,
		["yPercent"] = 0,
	},
	[8] = {
		["anchor"] = "CENTER",
		["relPoint"] = "CENTER",
		["xPercent"] = -0.2,
		["yPercent"] = 0,
	},
	[9] = {
		["anchor"] = "CENTER",
		["relPoint"] = "CENTER",
		["xPercent"] = 0.2,
		["yPercent"] = 0,
	},
};
local VUHDO_AURA_FIXED_STRAIGHT_POSITIONS = VUHDO_AURA_FIXED_STRAIGHT_POSITIONS;

VUHDO_AURA_FIXED_DIAGONAL_POSITIONS = VUHDO_AURA_FIXED_DIAGONAL_POSITIONS or {
	[1] = {
		["anchor"] = "TOPLEFT",
		["relPoint"] = "TOPLEFT",
		["xPercent"] = 0,
		["yPercent"] = 0,
	},
	[2] = {
		["anchor"] = "TOPRIGHT",
		["relPoint"] = "TOPRIGHT",
		["xPercent"] = 0,
		["yPercent"] = 0,
	},
	[3] = {
		["anchor"] = "BOTTOMLEFT",
		["relPoint"] = "BOTTOMLEFT",
		["xPercent"] = 0,
		["yPercent"] = 0,
	},
	[4] = {
		["anchor"] = "BOTTOMRIGHT",
		["relPoint"] = "BOTTOMRIGHT",
		["xPercent"] = 0,
		["yPercent"] = 0,
	},
	[5] = {
		["anchor"] = "BOTTOM",
		["relPoint"] = "BOTTOM",
		["xPercent"] = 0,
		["yPercent"] = 0,
	},
	[6] = {
		["anchor"] = "TOP",
		["relPoint"] = "TOP",
		["xPercent"] = 0,
		["yPercent"] = 0,
	},
	[7] = {
		["anchor"] = "CENTER",
		["relPoint"] = "CENTER",
		["xPercent"] = 0,
		["yPercent"] = 0,
	},
	[8] = {
		["anchor"] = "CENTER",
		["relPoint"] = "CENTER",
		["xPercent"] = -0.2,
		["yPercent"] = 0,
	},
	[9] = {
		["anchor"] = "CENTER",
		["relPoint"] = "CENTER",
		["xPercent"] = 0.2,
		["yPercent"] = 0,
	},
};
local VUHDO_AURA_FIXED_DIAGONAL_POSITIONS = VUHDO_AURA_FIXED_DIAGONAL_POSITIONS;

local sAnchorPoints = {
	["TOPLEFT"] = { "TOPLEFT", 1, -1 },
	["TOP"] = { "TOP", 0, -1 },
	["TOPRIGHT"] = { "TOPRIGHT", -1, -1 },
	["LEFT"] = { "LEFT", 1, 0 },
	["CENTER"] = { "CENTER", 0, 0 },
	["RIGHT"] = { "RIGHT", -1, 0 },
	["BOTTOMLEFT"] = { "BOTTOMLEFT", 1, 1 },
	["BOTTOM"] = { "BOTTOM", 0, 1 },
	["BOTTOMRIGHT"] = { "BOTTOMRIGHT", -1, 1 },
};

local sGrowthOffsets = {
	["LEFT"] = { -1, 0 },
	["RIGHT"] = { 1, 0 },
	["UP"] = { 0, 1 },
	["DOWN"] = { 0, -1 },
};

local sTimeAbbrevData = {
	["breakpointData"] = {
		{
			["breakpoint"] = 3600,
			["abbreviation"] = "h",
			["significandDivisor"] = 60,
			["fractionDivisor"] = 60,
		},
		{
			["breakpoint"] = 60,
			["abbreviation"] = "m",
			["significandDivisor"] = 60,
			["fractionDivisor"] = 1,
		},
		{
			["breakpoint"] = 0,
			["abbreviation"] = "s",
			["significandDivisor"] = 1,
			["fractionDivisor"] = 1,
		},
	},
};

local sCurveTimerVisible;
local sCurveFlashZone;
local sCurveFadeAlpha;
local sCurveTimerColor;
local sAuraDispelCurve;
local sBarColors;

local sAuraTimerData = { };
local sAuraTimerFrame;
local sAuraTimerAnimGroup;
local sAuraTimerAnimation;
local sAuraTimerCount = 0;

local sAuraIconPool;
local sAuraBarPool;

local sAuraBackdropInfo = {
	["edgeFile"] = "Interface\\Buttons\\WHITE8X8",
	["edgeSize"] = 2,
	["insets"] = {
		["left"] = 0,
		["right"] = 0,
		["top"] = 0,
		["bottom"] = 0,
	},
};



--
function VUHDO_barCustomizerAurasInitLocalOverrides()

	VUHDO_CONFIG = _G["VUHDO_CONFIG"];
	VUHDO_PANEL_SETUP = _G["VUHDO_PANEL_SETUP"];
	VUHDO_RAID = _G["VUHDO_RAID"];
	VUHDO_BUTTON_CACHE = _G["VUHDO_BUTTON_CACHE"];
	VUHDO_UNIT_AURA_CACHE = _G["VUHDO_UNIT_AURA_CACHE"];
	VUHDO_UNIT_AURA_SLOTS = _G["VUHDO_UNIT_AURA_SLOTS"];
	VUHDO_STATUSBAR_LEFT_TO_RIGHT = _G["VUHDO_STATUSBAR_LEFT_TO_RIGHT"];
	VUHDO_STATUSBAR_RIGHT_TO_LEFT = _G["VUHDO_STATUSBAR_RIGHT_TO_LEFT"];
	VUHDO_STATUSBAR_BOTTOM_TO_TOP = _G["VUHDO_STATUSBAR_BOTTOM_TO_TOP"];
	VUHDO_STATUSBAR_TOP_TO_BOTTOM = _G["VUHDO_STATUSBAR_TOP_TO_BOTTOM"];

	VUHDO_PixelUtil = _G["VUHDO_PixelUtil"];
	VUHDO_UIFrameFlash = _G["VUHDO_UIFrameFlash"];
	VUHDO_UIFrameFlashStop = _G["VUHDO_UIFrameFlashStop"];

	VUHDO_safeSetAttribute = _G["VUHDO_safeSetAttribute"];
	VUHDO_safeWrapScript = _G["VUHDO_safeWrapScript"];
	VUHDO_findButtonFromChild = _G["VUHDO_findButtonFromChild"];
	VUHDO_getUnitButtonsPanel = _G["VUHDO_getUnitButtonsPanel"];
	VUHDO_getHealthBar = _G["VUHDO_getHealthBar"];
	VUHDO_getHealthBarWidth = _G["VUHDO_getHealthBarWidth"];
	VUHDO_getHealthBarHeight = _G["VUHDO_getHealthBarHeight"];
	VUHDO_customizeIconText = _G["VUHDO_customizeIconText"];
	VUHDO_textColor = _G["VUHDO_textColor"];
	VUHDO_setLlcStatusBarTexture = _G["VUHDO_setLlcStatusBarTexture"];
	VUHDO_setStatusBarOrientation = _G["VUHDO_setStatusBarOrientation"];
	VUHDO_getClassColor = _G["VUHDO_getClassColor"];
	VUHDO_safeColorFromTable = _G["VUHDO_safeColorFromTable"];
	VUHDO_getAnchorSlotAuraId = _G["VUHDO_getAnchorSlotAuraId"];
	VUHDO_setAnchorSlotAuraId = _G["VUHDO_setAnchorSlotAuraId"];
	VUHDO_resolveAuraTriState = _G["VUHDO_resolveAuraTriState"];
	VUHDO_getAnchorTriStateBool = _G["VUHDO_getAnchorTriStateBool"];
	VUHDO_getAuraGroup = _G["VUHDO_getAuraGroup"];
	VUHDO_getDispelCurveForUnit = _G["VUHDO_getDispelCurveForUnit"];

	VUHDO_initAuraDurationCurves();
	VUHDO_initAuraTimer();

	sBarColors = VUHDO_PANEL_SETUP and VUHDO_PANEL_SETUP["BAR_COLORS"];

	return;

end



--
local tChild;
local function VUHDO_getAuraIconBackdrop(aFrame)

	tChild = aFrame:GetChildren();

	return tChild;

end



--
local tRegion;
local function VUHDO_getAuraIconTexture(aBackdropFrame)

	tRegion = aBackdropFrame:GetRegions();

	return tRegion;

end



--
local tTimer;
local function VUHDO_getAuraIconTimer(aBackdropFrame)

	_, tTimer = aBackdropFrame:GetRegions();

	return tTimer;

end



--
local tCounter;
local function VUHDO_getAuraIconCounter(aBackdropFrame)

	_, _, tCounter = aBackdropFrame:GetRegions();

	return tCounter;

end



--
local tCooldown;
local function VUHDO_getAuraIconCooldown(aBackdropFrame)

	tCooldown = aBackdropFrame:GetChildren();

	return tCooldown;

end



--
local tChargeFrame;
local function VUHDO_getAuraIconChargeFrame(aBackdropFrame)

	_, tChargeFrame = aBackdropFrame:GetChildren();

	return tChargeFrame;

end



--
local tRegion;
local function VUHDO_getAuraIconChargeTexture(aChargeFrame)

	_, tRegion = aChargeFrame:GetRegions();

	return tRegion;
end



--
local tBar;
local function VUHDO_getAuraBarStatusBar(aFrame)

	_, tBar = aFrame:GetChildren();

	return tBar;

end



--
local tIcon;
local function VUHDO_getAuraBarIconTexture(aFrame)

	tIcon = aFrame:GetRegions();

	return tIcon;

end



--
local tTimer;
local function VUHDO_getAuraBarTimer(aFrame)

	_, tTimer = aFrame:GetRegions();

	return tTimer;

end



--
local tCounter;
local function VUHDO_getAuraBarCounter(aFrame)

	_, _, tCounter = aFrame:GetRegions();

	return tCounter;

end



--
local tCooldown;
local function VUHDO_getAuraBarCooldown(aFrame)

	tCooldown = aFrame:GetChildren();

	return tCooldown;

end



--
local tColors;
local tTransparent;
local tDispelAbilities;
local tPurgeAbilities;
local tBlizzType;
local tColorKey;
function VUHDO_initAuraDurationCurves()

	if not CreateCurve then
		return;
	end

	sCurveTimerVisible = CreateCurve();
	sCurveTimerVisible:SetType(Enum.LuaCurveType.Step);
	sCurveTimerVisible:AddPoint(0, 0);
	sCurveTimerVisible:AddPoint(0.1, 1);
	sCurveTimerVisible:AddPoint(9.8, 0);

	sCurveFlashZone = CreateCurve();
	sCurveFlashZone:SetType(Enum.LuaCurveType.Step);
	sCurveFlashZone:AddPoint(0, 0);
	sCurveFlashZone:AddPoint(0.1, 1);
	sCurveFlashZone:AddPoint(4.9, 0);

	sCurveFadeAlpha = CreateCurve();
	sCurveFadeAlpha:SetType(Enum.LuaCurveType.Linear);
	sCurveFadeAlpha:AddPoint(0, 0);
	sCurveFadeAlpha:AddPoint(10, 1);

	if CreateColorCurve and CreateColor then
		sCurveTimerColor = CreateColorCurve();
		sCurveTimerColor:SetType(Enum.LuaCurveType.Step);
		sCurveTimerColor:AddPoint(0, CreateColor(1, 1, 1, 1));
		sCurveTimerColor:AddPoint(0.1, CreateColor(1, 0.2, 0.2, 1));
		sCurveTimerColor:AddPoint(4.9, CreateColor(1, 1, 1, 1));
	end

	if CreateColorCurve and VUHDO_safeColorFromTable then
		tColors = VUHDO_PANEL_SETUP and VUHDO_PANEL_SETUP["BAR_COLORS"];
		tTransparent = CreateColor(0, 0, 0, 0);
		sAuraDispelCurve = CreateColorCurve();
		sAuraDispelCurve:SetType(Enum.LuaCurveType.Step);
		sAuraDispelCurve:AddPoint(0, tTransparent);

		if tColors and tColors["DEBUFF3"] and tColors["DEBUFF3"]["useBorder"] then
			sAuraDispelCurve:AddPoint(1, VUHDO_safeColorFromTable(tColors["DEBUFF3"], tTransparent));
		else
			sAuraDispelCurve:AddPoint(1, tTransparent);
		end

		if tColors and tColors["DEBUFF4"] and tColors["DEBUFF4"]["useBorder"] then
			sAuraDispelCurve:AddPoint(2, VUHDO_safeColorFromTable(tColors["DEBUFF4"], tTransparent));
		else
			sAuraDispelCurve:AddPoint(2, tTransparent);
		end

		if tColors and tColors["DEBUFF2"] and tColors["DEBUFF2"]["useBorder"] then
			sAuraDispelCurve:AddPoint(3, VUHDO_safeColorFromTable(tColors["DEBUFF2"], tTransparent));
		else
			sAuraDispelCurve:AddPoint(3, tTransparent);
		end

		if tColors and tColors["DEBUFF1"] and tColors["DEBUFF1"]["useBorder"] then
			sAuraDispelCurve:AddPoint(4, VUHDO_safeColorFromTable(tColors["DEBUFF1"], tTransparent));
		else
			sAuraDispelCurve:AddPoint(4, tTransparent);
		end

		if tColors and tColors["DEBUFF9"] and tColors["DEBUFF9"]["useBorder"] then
			sAuraDispelCurve:AddPoint(9, VUHDO_safeColorFromTable(tColors["DEBUFF9"], tTransparent));
		else
			sAuraDispelCurve:AddPoint(9, tTransparent);
		end

		if tColors and tColors["DEBUFF8"] and tColors["DEBUFF8"]["useBorder"] then
			sAuraDispelCurve:AddPoint(11, VUHDO_safeColorFromTable(tColors["DEBUFF8"], tTransparent));
		else
			sAuraDispelCurve:AddPoint(11, tTransparent);
		end
	end

	return;

end



--
local tGroup;
function VUHDO_getDispelCurveForContext(aUnit, anAnchorConfig)

	if not aUnit or not anAnchorConfig then
		return nil;
	end

	tGroup = VUHDO_getAuraGroup(anAnchorConfig["groupId"]);

	if not tGroup then
		return nil;
	end

	return VUHDO_getDispelCurveForUnit(aUnit, tGroup["isHarmful"]);

end



--
local tRemainingSeconds;
local tDurationText;
local tTimerVisibility;
local tTimerColorMixin;
local function VUHDO_auraTimerOnLoop()

	for tFontString, tDurationObj in pairs(sAuraTimerData) do
		if tDurationObj and sCurveTimerVisible then
			tRemainingSeconds = tDurationObj:GetRemainingDuration();

			if AbbreviateNumbers then
				tDurationText = AbbreviateNumbers(tRemainingSeconds, sTimeAbbrevData);
				tFontString:SetText(tDurationText or "");
			elseif tDurationObj.HasSecretValues and not tDurationObj:HasSecretValues() then
				tDurationText = format("%.0f", tRemainingSeconds);
				tFontString:SetText(tDurationText);
			else
				tFontString:SetText("");
			end

			tTimerVisibility = tDurationObj:EvaluateRemainingDuration(sCurveTimerVisible);
			tFontString:SetAlpha(tTimerVisibility);

			if sCurveTimerColor then
				tTimerColorMixin = tDurationObj:EvaluateRemainingDuration(sCurveTimerColor);
				tFontString:SetTextColor(tTimerColorMixin:GetRGBA());
			end
		end
	end

	return;

end



--
function VUHDO_initAuraTimer()

	if sAuraTimerFrame then
		return;
	end

	sAuraTimerFrame = CreateFrame("Frame");
	sAuraTimerFrame:Hide();

	sAuraTimerAnimGroup = sAuraTimerFrame:CreateAnimationGroup();
	sAuraTimerAnimGroup:SetLooping("REPEAT");
	sAuraTimerAnimation = sAuraTimerAnimGroup:CreateAnimation();
	sAuraTimerAnimation:SetDuration(0.1);
	sAuraTimerAnimGroup:SetScript("OnLoop", VUHDO_auraTimerOnLoop);

	return;

end



--
function VUHDO_registerAuraTimerText(aFontString, aDurationObj)

	if not aFontString or not aDurationObj then
		return;
	end

	if not sAuraTimerData[aFontString] then
		sAuraTimerCount = sAuraTimerCount + 1;
	end

	sAuraTimerData[aFontString] = aDurationObj;

	if sAuraTimerCount == 1 and sAuraTimerAnimGroup then
		sAuraTimerAnimGroup:Play();
	end

	return;

end



--
function VUHDO_unregisterAuraTimerText(aFontString)

	if not aFontString then
		return;
	end

	if not sAuraTimerData[aFontString] then
		return;
	end

	sAuraTimerData[aFontString] = nil;
	sAuraTimerCount = sAuraTimerCount - 1;

	if sAuraTimerCount == 0 and sAuraTimerAnimGroup then
		sAuraTimerAnimGroup:Stop();
	end

	return;

end



--
local function VUHDO_auraFramePoolReset(aPool, aFrame)

	if aFrame.childB and aFrame.childB.chargeTexture then
		aFrame.childB.chargeTexture:Hide();
	end

	aFrame:Hide();
	aFrame:ClearAllPoints();
	aFrame:SetParent(UIParent);

	return;

end



--
function VUHDO_initAuraFramePools()

	if sAuraIconPool then
		return;
	end

	sAuraIconPool = CreateFramePool("Frame", nil, "VuhDoAuraAnchorIconTemplate", VUHDO_auraFramePoolReset);
	sAuraBarPool = CreateFramePool("Frame", nil, "VuhDoAuraAnchorBarTemplate", VUHDO_auraFramePoolReset);

	return;

end



--
local sAuraOnEnterSnippet = [[
	tFrame = self:GetAttribute("vuhdo_button");

	if not tFrame then
		tFrame = self:GetParent();

		while tFrame do
			if tFrame:GetAttribute("vuhdo_button_marker") then
				break;
			end

			tFrame = tFrame:GetParent();
		end
	end

	if tFrame then
		if sHealButton and sHealButton ~= tFrame then
			sHealButton:ClearBindings();
		end

		sHealButton = tFrame;
		tBody = tFrame:GetAttribute("vuhdo_onenter");

		if tBody then
			owner:RunFor(tFrame, tBody);

			if sCliqueHeader then
				tCliqueEnter = sCliqueHeader:GetAttribute("_onenter");

				if tCliqueEnter then
					sCliqueHeader:RunFor(tFrame, tCliqueEnter);
				end
			end
		end
	end
]];

local sAuraOnLeaveSnippet = [[
	tFrame = self:GetAttribute("vuhdo_button");

	if not tFrame then
		tFrame = self:GetParent();

		while tFrame do
			if tFrame:GetAttribute("vuhdo_button_marker") then
				break;
			end

			tFrame = tFrame:GetParent();
		end
	end

	if tFrame then
		tFrame:ClearBindings();
		sHealButton = nil;
		tBody = tFrame:GetAttribute("vuhdo_onleave");

		if tBody then
			owner:RunFor(tFrame, tBody);
		end

		if sCliqueHeader then
			tCliqueLeave = sCliqueHeader:GetAttribute("_onleave");

			if tCliqueLeave then
				sCliqueHeader:RunFor(tFrame, tCliqueLeave);
			end
		end
	end
]];



--
local tHeaderFrame;
local function VUHDO_initAuraFrameSecureHandlers(aFrame, aButton)

	if not aFrame or not aButton then
		return;
	end

	if aFrame:GetAttribute("vuhdo_aura_secure_init") then
		return;
	end

	VUHDO_safeSetAttribute(aFrame, "vuhdo_button", aButton);

	if not aFrame:GetAttribute("vd_tt_hook") then
		aFrame:SetScript("OnEnter", function(self)
			VUHDO_showAuraTooltip(self);

			VuhDoActionOnEnter(VUHDO_findButtonFromChild(self));
		end);

		aFrame:SetScript("OnLeave", function(self)
			VUHDO_hideAuraTooltip();

			VuhDoActionOnLeave(VUHDO_findButtonFromChild(self));
		end);

		VUHDO_safeSetAttribute(aFrame, "vd_tt_hook", true);
	end

	if not aFrame:GetAttribute("vuhdo_secureheader_wrap") then
		tHeaderFrame = _G["VuhDoHealButtonSecureHeaderFrame"];

		if tHeaderFrame then
			VUHDO_safeWrapScript(tHeaderFrame, aFrame, "OnEnter", sAuraOnEnterSnippet);
			VUHDO_safeWrapScript(tHeaderFrame, aFrame, "OnLeave", sAuraOnLeaveSnippet);

			VUHDO_safeSetAttribute(aFrame, "vuhdo_secureheader_wrap", true);
		end
	end

	aFrame:EnableMouse(false);
	aFrame:SetMouseMotionEnabled(true);
	aFrame:EnableKeyboard(false);
	aFrame:SetPropagateKeyboardInput(true);

	VUHDO_safeSetAttribute(aFrame, "vuhdo_aura_secure_init", true);

	return;

end



--
local tFrame;
local tFrameName;
local tParent;
local tChargeFrame;
function VUHDO_acquireAuraIconFrame(aButton, anAnchorIndex, aSlotIndex)

	if not aButton or not anAnchorIndex or not aSlotIndex then
		return nil;
	end

	VUHDO_initAuraFramePools();

	tFrameName = aButton:GetName();

	if not VUHDO_AURA_FRAMES[tFrameName] then
		VUHDO_AURA_FRAMES[tFrameName] = { };
	end

	if not VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex] then
		VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex] = { };
	end

	tFrame = VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex][aSlotIndex];

	if tFrame then
		return tFrame;
	end

	tFrame = sAuraIconPool:Acquire();

	if not tFrame then
		return nil;
	end

	tFrame.childB = VUHDO_getAuraIconBackdrop(tFrame);

	if tFrame.childB then
		if tFrame.childB.SetBackdrop then
			tFrame.childB:SetBackdrop(sAuraBackdropInfo);
			tFrame.childB:SetBackdropBorderColor(0, 0, 0, 0);
		end

		tFrame.childB.textureI = VUHDO_getAuraIconTexture(tFrame.childB);

		tChargeFrame = VUHDO_getAuraIconChargeFrame(tFrame.childB);

		if tChargeFrame then
			tFrame.childB.chargeTexture = VUHDO_getAuraIconChargeTexture(tChargeFrame);
		end

		tFrame.childB.timerText = VUHDO_getAuraIconTimer(tFrame.childB);
		tFrame.childB.countText = VUHDO_getAuraIconCounter(tFrame.childB);

		tFrame.childB.cooldownFrame = VUHDO_getAuraIconCooldown(tFrame.childB);

		if tFrame.childB.cooldownFrame then
			tFrame.childB.cooldownFrame:SetHideCountdownNumbers(true);
			tFrame.childB.cooldownFrame:SetReverse(true);
			tFrame.childB.cooldownFrame:SetDrawSwipe(true);
			tFrame.childB.cooldownFrame:SetDrawEdge(true);
			tFrame.childB.cooldownFrame:SetDrawBling(false);
		end
	end

	tParent = _G[aButton:GetName() .. "BgBarHlBar"];

	if tParent then
		tFrame:SetParent(tParent);
	end

	VUHDO_initAuraFrameSecureHandlers(tFrame, aButton);

	VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex][aSlotIndex] = tFrame;

	return tFrame;

end



--
local tFrame;
local tFrameName;
local tParent;
function VUHDO_acquireAuraBarFrame(aButton, anAnchorIndex, aSlotIndex)

	if not aButton or not anAnchorIndex or not aSlotIndex then
		return nil;
	end

	VUHDO_initAuraFramePools();

	tFrameName = aButton:GetName();

	if not VUHDO_AURA_FRAMES[tFrameName] then
		VUHDO_AURA_FRAMES[tFrameName] = { };
	end

	if not VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex] then
		VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex] = { };
	end

	tFrame = VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex][aSlotIndex];

	if tFrame then
		return tFrame;
	end

	tFrame = sAuraBarPool:Acquire();

	if not tFrame then
		return nil;
	end

	tFrame.cooldownFrame = VUHDO_getAuraBarCooldown(tFrame);
	tFrame.childBar = VUHDO_getAuraBarStatusBar(tFrame);

	if tFrame.childBar then
		tFrame.childBar:SetFrameLevel(tFrame:GetFrameLevel() - 1);
	end

	tFrame.childIcon = VUHDO_getAuraBarIconTexture(tFrame);
	tFrame.timerText = VUHDO_getAuraBarTimer(tFrame);
	tFrame.countText = VUHDO_getAuraBarCounter(tFrame);

	tParent = _G[aButton:GetName() .. "BgBarHlBar"];

	if tParent then
		tFrame:SetParent(tParent);
	end

	VUHDO_initAuraFrameSecureHandlers(tFrame, aButton);

	VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex][aSlotIndex] = tFrame;

	return tFrame;

end



--
local tFrame;
local tFrameName;
function VUHDO_releaseAuraFrame(aButton, anAnchorIndex, aSlotIndex, anIsBar)

	if not aButton or not anAnchorIndex or not aSlotIndex then
		return;
	end

	tFrameName = aButton:GetName();

	if not VUHDO_AURA_FRAMES[tFrameName] then
		return;
	end

	if not VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex] then
		return;
	end

	tFrame = VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex][aSlotIndex];

	if not tFrame then
		return;
	end

	if tFrame.childB and tFrame.childB["timerText"] then
		VUHDO_unregisterAuraTimerText(tFrame.childB["timerText"]);
	end

	if anIsBar then
		sAuraBarPool:Release(tFrame);
	else
		sAuraIconPool:Release(tFrame);
	end

	VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex][aSlotIndex] = nil;

	return;

end



--
local tFrameName;
local tButtonFrames;
function VUHDO_releaseAllAuraFramesForButton(aButton)

	if not aButton then
		return;
	end

	tFrameName = aButton:GetName();
	tButtonFrames = VUHDO_AURA_FRAMES[tFrameName];

	if not tButtonFrames then
		return;
	end

	if not sAuraIconPool or not sAuraBarPool then
		VUHDO_AURA_FRAMES[tFrameName] = nil;

		return;
	end

	for tAnchorIndex, tAnchorFrames in pairs(tButtonFrames) do
		for tSlotIndex, tFrame in pairs(tAnchorFrames) do
			if tFrame then
				if tFrame.childBar then
					sAuraBarPool:Release(tFrame);
				elseif tFrame.childB then
					sAuraIconPool:Release(tFrame);
				end
			end
		end
	end

	VUHDO_AURA_FRAMES[tFrameName] = nil;

	return;

end



--
function VUHDO_releaseAllAuraFrames()

	if sAuraTimerAnimGroup then
		sAuraTimerAnimGroup:Stop();
	end

	twipe(sAuraTimerData);
	sAuraTimerCount = 0;

	if sAuraIconPool then
		sAuraIconPool:ReleaseAll();
	end

	if sAuraBarPool then
		sAuraBarPool:ReleaseAll();
	end

	twipe(VUHDO_AURA_FRAMES);

	return;

end



do
	--
	local tButtonName;
	function VUHDO_resetFixedAuraOverflowState(aButton, anAnchorIndex)

		if not aButton then
			return;
		end

		tButtonName = aButton:GetName();

		if not tButtonName then
			return;
		end

		if not VUHDO_FIXED_AURA_OVERFLOW_STATE[tButtonName] then
			VUHDO_FIXED_AURA_OVERFLOW_STATE[tButtonName] = { };
		end

		VUHDO_FIXED_AURA_OVERFLOW_STATE[tButtonName][anAnchorIndex] = {
			["anchorCounts"] = { },
			["slotAssignments"] = { },
		};

		return;

	end



	--
	local tState;
	local tAnchorCounts;
	local tMaxCols;
	local tMaxRows;
	local tAnchorCapacity;
	local tBaseAnchor;
	local tLayerIndex;
	local tNumBasePositions;
	local tStartAnchor;
	local tCheckedCount;
	function VUHDO_assignFixedOverflowSlot(aButton, anAnchorIndex, aSlotIndex, anAnchorConfig)

		if not aButton or not anAnchorIndex or not aSlotIndex or not anAnchorConfig then
			return nil, nil;
		end

		tButtonName = aButton:GetName();

		if not tButtonName then
			return nil, nil;
		end

		tState = VUHDO_FIXED_AURA_OVERFLOW_STATE[tButtonName] and VUHDO_FIXED_AURA_OVERFLOW_STATE[tButtonName][anAnchorIndex];

		if not tState then
			return nil, nil;
		end

		tNumBasePositions = 9;

		if aSlotIndex <= tNumBasePositions then
			tAnchorCounts = tState["anchorCounts"];
			tAnchorCounts[aSlotIndex] = (tAnchorCounts[aSlotIndex] or 0) + 1;

			tState["slotAssignments"][aSlotIndex] = {
				["baseAnchor"] = aSlotIndex,
				["layerIndex"] = 0,
			};

			return aSlotIndex, 0;
		end

		tMaxCols = anAnchorConfig["maxColumns"] or 5;
		tMaxRows = anAnchorConfig["maxRows"] or 1;
		tAnchorCapacity = tMaxCols * tMaxRows;

		tAnchorCounts = tState["anchorCounts"];
		tStartAnchor = ((aSlotIndex - 1) % tNumBasePositions) + 1;
		tCheckedCount = 0;
		tBaseAnchor = tStartAnchor;

		while tCheckedCount < tNumBasePositions do
			if (tAnchorCounts[tBaseAnchor] or 0) < tAnchorCapacity then
				tLayerIndex = tAnchorCounts[tBaseAnchor] or 0;
				tAnchorCounts[tBaseAnchor] = tLayerIndex + 1;

				tState["slotAssignments"][aSlotIndex] = {
					["baseAnchor"] = tBaseAnchor,
					["layerIndex"] = tLayerIndex,
				};

				return tBaseAnchor, tLayerIndex;
			end

			tBaseAnchor = (tBaseAnchor % tNumBasePositions) + 1;
			tCheckedCount = tCheckedCount + 1;
		end

		return nil, nil;

	end



	--
	local tAssignment;
	function VUHDO_getFixedOverflowAssignment(aButton, anAnchorIndex, aSlotIndex, anAnchorConfig)

		if not aButton or not anAnchorIndex or not aSlotIndex then
			return nil, nil;
		end

		tButtonName = aButton:GetName();

		if not tButtonName then
			return nil, nil;
		end

		tState = VUHDO_FIXED_AURA_OVERFLOW_STATE[tButtonName] and VUHDO_FIXED_AURA_OVERFLOW_STATE[tButtonName][anAnchorIndex];

		if not tState then
			return nil, nil;
		end

		tAssignment = tState["slotAssignments"][aSlotIndex];

		if tAssignment then
			return tAssignment["baseAnchor"], tAssignment["layerIndex"];
		end

		return VUHDO_assignFixedOverflowSlot(aButton, anAnchorIndex, aSlotIndex, anAnchorConfig);

	end
end



do
	--
	local tPos;
	local tRelFrame;
	local tBaseX;
	local tBaseY;
	local tGrowthDir;
	local tWrapDir;
	local tSize;
	local tSpacing;
	local tMaxCols;
	local tCol;
	local tRow;
	local tGrowX;
	local tGrowY;
	local tWrapX;
	local tWrapY;
	local tXOff;
	local tYOff;
	local tBarWidth;
	local tBarHeight;
	local tIconSize;
	local tTotalWidth;
	local tAuraDefaults;
	function VUHDO_positionAuraFrameDynamic(aFrame, aSlotIndex, anAnchorConfig, aButton, aRadioValue)

		tPos = VUHDO_AURA_RADIOVALUE_POSITIONS[aRadioValue];

		if not tPos then
			return;
		end

		if "HealthBar" == tPos["relFrame"] and VUHDO_getHealthBar then
			tRelFrame = VUHDO_getHealthBar(aButton, 1);
		else
			tRelFrame = aButton;
		end

		if not tRelFrame then
			return;
		end

		tBaseX = anAnchorConfig["offsetX"] or 0;
		tBaseY = anAnchorConfig["offsetY"] or 0;

		if aRadioValue == 17 then
			tBaseX = anAnchorConfig["offsetX"] or 0;
			tBaseY = anAnchorConfig["offsetY"] or 0;
		else
			tBaseX = (tPos["xOffset"] or 0) + tBaseX;
			tBaseY = (tPos["yOffset"] or 0) + tBaseY;
		end

		tGrowthDir = sGrowthOffsets[anAnchorConfig["growthDir"]] or sGrowthOffsets["RIGHT"];
		tWrapDir = sGrowthOffsets[anAnchorConfig["wrapDir"]] or sGrowthOffsets["DOWN"];
		tSize = anAnchorConfig["size"] or 16;
		tSpacing = anAnchorConfig["spacing"] or 2;
		tMaxCols = anAnchorConfig["maxColumns"] or 5;

		if aFrame.childBar then
			tAuraDefaults = VUHDO_PANEL_SETUP and VUHDO_PANEL_SETUP["AURA_DEFAULTS"];

			tBarWidth = anAnchorConfig["barWidth"] or (tAuraDefaults and tAuraDefaults["barWidth"]) or 100;
			tBarHeight = anAnchorConfig["barHeight"] or (tAuraDefaults and tAuraDefaults["barHeight"]) or 12;

			tIconSize = tBarHeight;
			tTotalWidth = tIconSize + tBarWidth;
		else
			tBarWidth = tSize;
			tBarHeight = tSize;

			tIconSize = 0;
			tTotalWidth = tSize;
		end

		tCol = (aSlotIndex - 1) % tMaxCols;
		tRow = floor((aSlotIndex - 1) / tMaxCols);
		tGrowX = tGrowthDir[1];
		tGrowY = tGrowthDir[2];
		tWrapX = tWrapDir[1];
		tWrapY = tWrapDir[2];

		tXOff = tBaseX + (tCol * (tTotalWidth + tSpacing) * tGrowX) + (tRow * (tTotalWidth + tSpacing) * tWrapX);
		tYOff = tBaseY + (tCol * (tBarHeight + tSpacing) * tGrowY) + (tRow * (tBarHeight + tSpacing) * tWrapY);

		aFrame:ClearAllPoints();
		VUHDO_PixelUtil.SetPoint(aFrame, tPos["anchor"], tRelFrame, tPos["relPoint"], tXOff, tYOff);
		VUHDO_PixelUtil.SetSize(aFrame, tTotalWidth, tBarHeight);

		if aFrame.childIcon and aFrame.childBar then
			aFrame.childIcon:ClearAllPoints();
			VUHDO_PixelUtil.SetPoint(aFrame.childIcon, "LEFT", aFrame, "LEFT", 0, 0);
			VUHDO_PixelUtil.SetSize(aFrame.childIcon, tIconSize, tIconSize);
			aFrame.childIcon:Show();

			if aFrame.cooldownFrame and aFrame.childIcon then
				aFrame.cooldownFrame:ClearAllPoints();
				aFrame.cooldownFrame:SetAllPoints(aFrame.childIcon);
			end

			aFrame.childBar:ClearAllPoints();
			VUHDO_PixelUtil.SetPoint(aFrame.childBar, "LEFT", aFrame.childIcon, "RIGHT", 0, 0);
			VUHDO_PixelUtil.SetSize(aFrame.childBar, tBarWidth, tBarHeight);
		end

		return;

	end



	--
	local tSlotPos;
	local tRelFrame;
	local tBarWidth;
	local tBarHeight;
	local tXOff;
	local tYOff;
	local tPanelNum;
	local tSize;
	local tNumBasePositions;
	local tBaseAnchor;
	local tLayerIndex;
	local tGrowthDir;
	local tWrapDir;
	local tSpacing;
	local tMaxCols;
	local tCol;
	local tRow;
	local tGrowX;
	local tGrowY;
	local tWrapX;
	local tWrapY;
	local tGrowthXOff;
	local tGrowthYOff;
	function VUHDO_positionAuraFrameFixed(aFrame, aSlotIndex, aPositionTable, aButton, anAnchorConfig, anAnchorIndex)

		tNumBasePositions = 9;

		if aSlotIndex <= tNumBasePositions then
			tSlotPos = aPositionTable[aSlotIndex];
			tLayerIndex = 0;

			VUHDO_assignFixedOverflowSlot(aButton, anAnchorIndex, aSlotIndex, anAnchorConfig);
		else
			tBaseAnchor, tLayerIndex = VUHDO_getFixedOverflowAssignment(aButton, anAnchorIndex, aSlotIndex, anAnchorConfig);

			if not tBaseAnchor then
				aFrame:Hide();
				return;
			end

			tSlotPos = aPositionTable[tBaseAnchor];
		end

		if not tSlotPos then
			return;
		end

		if not VUHDO_getHealthBar or not VUHDO_BUTTON_CACHE then
			return;
		end

		tRelFrame = VUHDO_getHealthBar(aButton, 1);

		if not tRelFrame then
			return;
		end

		tPanelNum = VUHDO_BUTTON_CACHE[aButton];

		if not tPanelNum or not VUHDO_getHealthBarWidth or not VUHDO_getHealthBarHeight then
			tBarWidth = 0;
			tBarHeight = 0;
		else
			tBarWidth = VUHDO_getHealthBarWidth(tPanelNum);
			tBarHeight = VUHDO_getHealthBarHeight(tPanelNum);
		end

		tXOff = (tSlotPos["xPercent"] or 0) * tBarWidth;
		tYOff = (tSlotPos["yPercent"] or 0) * tBarHeight;

		tSize = anAnchorConfig["size"] or 16;

		if tLayerIndex and tLayerIndex > 0 then
			tGrowthDir = sGrowthOffsets[anAnchorConfig["growthDir"]] or sGrowthOffsets["RIGHT"];
			tWrapDir = sGrowthOffsets[anAnchorConfig["wrapDir"]] or sGrowthOffsets["DOWN"];
			tSpacing = anAnchorConfig["spacing"] or 2;
			tMaxCols = anAnchorConfig["maxColumns"] or 5;

			tCol = tLayerIndex % tMaxCols;
			tRow = floor(tLayerIndex / tMaxCols);

			tGrowX = tGrowthDir[1];
			tGrowY = tGrowthDir[2];
			tWrapX = tWrapDir[1];
			tWrapY = tWrapDir[2];

			tGrowthXOff = (tCol * (tSize + tSpacing) * tGrowX) + (tRow * (tSize + tSpacing) * tWrapX);
			tGrowthYOff = (tCol * (tSize + tSpacing) * tGrowY) + (tRow * (tSize + tSpacing) * tWrapY);

			tXOff = tXOff + tGrowthXOff;
			tYOff = tYOff + tGrowthYOff;
		end

		aFrame:ClearAllPoints();
		VUHDO_PixelUtil.SetPoint(aFrame, tSlotPos["anchor"], tRelFrame, tSlotPos["relPoint"], tXOff, tYOff);
		VUHDO_PixelUtil.SetSize(aFrame, tSize, tSize);

		return;

	end
end



do
	--
	local tRadioValue;
	local tAnchorPoint;
	local tGrowthDir;
	local tWrapDir;
	local tSize;
	local tSpacing;
	local tMaxCols;
	local tCol;
	local tRow;
	local tXOff;
	local tYOff;
	local tGrowX;
	local tGrowY;
	local tWrapX;
	local tWrapY;
	local tParent;
	local tChild;
	local tTexture;
	local tBarWidth;
	local tBarHeight;
	local tAuraDefaults;
	local tIconSize;
	local tTotalWidth;
	function VUHDO_positionAuraFrame(aFrame, aButton, anAnchorConfig, aSlotIndex, anAnchorIndex)

		if not aFrame or not aButton or not anAnchorConfig then
			return;
		end

		tRadioValue = anAnchorConfig["radioValue"];

		tSize = anAnchorConfig["size"] or 16;
		tAuraDefaults = VUHDO_PANEL_SETUP and VUHDO_PANEL_SETUP["AURA_DEFAULTS"];
		tBarWidth = anAnchorConfig["barWidth"] or (tAuraDefaults and tAuraDefaults["barWidth"]) or 100;
		tBarHeight = anAnchorConfig["barHeight"] or (tAuraDefaults and tAuraDefaults["barHeight"]) or 12;
		tIconSize = tBarHeight;

		if tRadioValue and tRadioValue <= 17 then
			VUHDO_positionAuraFrameDynamic(aFrame, aSlotIndex, anAnchorConfig, aButton, tRadioValue);
		elseif tRadioValue and 30 == tRadioValue then
			VUHDO_positionAuraFrameFixed(aFrame, aSlotIndex, VUHDO_AURA_FIXED_STRAIGHT_POSITIONS, aButton, anAnchorConfig, anAnchorIndex);
		elseif tRadioValue and 31 == tRadioValue then
			VUHDO_positionAuraFrameFixed(aFrame, aSlotIndex, VUHDO_AURA_FIXED_DIAGONAL_POSITIONS, aButton, anAnchorConfig, anAnchorIndex);
		else
			tAnchorPoint = sAnchorPoints[anAnchorConfig["position"]] or sAnchorPoints["TOPRIGHT"];
			tGrowthDir = sGrowthOffsets[anAnchorConfig["growthDir"]] or sGrowthOffsets["LEFT"];
			tWrapDir = sGrowthOffsets[anAnchorConfig["wrapDir"]] or sGrowthOffsets["DOWN"];

			tSize = anAnchorConfig["size"] or 16;
			tSpacing = anAnchorConfig["spacing"] or 2;
			tMaxCols = anAnchorConfig["maxColumns"] or 5;

			if aFrame.childBar then
				tAuraDefaults = VUHDO_PANEL_SETUP and VUHDO_PANEL_SETUP["AURA_DEFAULTS"];

				tBarWidth = anAnchorConfig["barWidth"] or (tAuraDefaults and tAuraDefaults["barWidth"]) or 100;
				tBarHeight = anAnchorConfig["barHeight"] or (tAuraDefaults and tAuraDefaults["barHeight"]) or 12;

				tIconSize = tBarHeight;
				tTotalWidth = tIconSize + tBarWidth;
			else
				tBarWidth = tSize;
				tBarHeight = tSize;

				tIconSize = 0;
				tTotalWidth = tBarWidth;
			end

			tCol = (aSlotIndex - 1) % tMaxCols;
			tRow = floor((aSlotIndex - 1) / tMaxCols);

			tGrowX = tGrowthDir[1];
			tGrowY = tGrowthDir[2];
			tWrapX = tWrapDir[1];
			tWrapY = tWrapDir[2];

			tXOff = (anAnchorConfig["offsetX"] or 0) + (tCol * (tTotalWidth + tSpacing) * tGrowX) + (tRow * (tTotalWidth + tSpacing) * tWrapX);
			tYOff = (anAnchorConfig["offsetY"] or 0) + (tCol * (tBarHeight + tSpacing) * tGrowY) + (tRow * (tBarHeight + tSpacing) * tWrapY);

			aFrame:ClearAllPoints();
			VUHDO_PixelUtil.SetPoint(aFrame, tAnchorPoint[1], aButton, tAnchorPoint[1], tXOff, tYOff);
			VUHDO_PixelUtil.SetSize(aFrame, tTotalWidth, tBarHeight);
		end

		tChild = aFrame.childB or aFrame.childBar or VUHDO_getAuraIconBackdrop(aFrame) or VUHDO_getAuraBarStatusBar(aFrame);

		if tChild then
			tChild:ClearAllPoints();

			if aFrame.childIcon and aFrame.childBar then
				aFrame.childIcon:ClearAllPoints();
				VUHDO_PixelUtil.SetPoint(aFrame.childIcon, "LEFT", aFrame, "LEFT", 0, 0);
				VUHDO_PixelUtil.SetSize(aFrame.childIcon, tIconSize, tIconSize);
				aFrame.childIcon:Show();

				if aFrame.cooldownFrame and aFrame.childIcon then
					aFrame.cooldownFrame:ClearAllPoints();
					aFrame.cooldownFrame:SetAllPoints(aFrame.childIcon);
				end

				tChild:ClearAllPoints();
				VUHDO_PixelUtil.SetPoint(tChild, "LEFT", aFrame.childIcon, "RIGHT", 0, 0);
				VUHDO_PixelUtil.SetSize(tChild, tBarWidth, tBarHeight);

				tSize = anAnchorConfig["size"] or 16;

				if aFrame.timerText and anAnchorConfig["TIMER_TEXT"] and VUHDO_customizeIconText then
					VUHDO_customizeIconText(aFrame.childIcon, tSize, aFrame.timerText, anAnchorConfig["TIMER_TEXT"]);
				end

				if aFrame.countText and anAnchorConfig["COUNTER_TEXT"] and VUHDO_customizeIconText then
					VUHDO_customizeIconText(aFrame.childIcon, tSize, aFrame.countText, anAnchorConfig["COUNTER_TEXT"]);
				end
			else
				tChild:SetAllPoints(aFrame);

				tTexture = tChild.textureI or VUHDO_getAuraIconTexture(tChild);

				if tTexture and tTexture.SetAllPoints then
					tTexture:SetAllPoints(tChild);
				end
			end

			tChild:SetAlpha(1);

			tSize = anAnchorConfig["size"] or 16;

			if tChild.timerText and anAnchorConfig["TIMER_TEXT"] and VUHDO_customizeIconText then
				VUHDO_customizeIconText(tChild, tSize, tChild.timerText, anAnchorConfig["TIMER_TEXT"]);
			end

			if tChild.countText and anAnchorConfig["COUNTER_TEXT"] and VUHDO_customizeIconText then
				VUHDO_customizeIconText(tChild, tSize, tChild.countText, anAnchorConfig["COUNTER_TEXT"]);
			end
		end

		tParent = aFrame:GetParent();

		if tParent then
			VUHDO_PixelUtil.SetFrameStrata(aFrame, tParent:GetFrameStrata());
			VUHDO_PixelUtil.SetFrameLevel(aFrame, tParent:GetFrameLevel() + (aFrame.addLevel or 10));
		end

		return;

	end
end



--
local tPanelAnchors;
function VUHDO_initAuraAnchorsForButton(aButton, aPanelNum)

	if not aButton or not aPanelNum then
		return;
	end

	if InCombatLockdown() then
		return;
	end

	VUHDO_releaseAllAuraFramesForButton(aButton);

	tPanelAnchors = VUHDO_PANEL_SETUP[aPanelNum] and VUHDO_PANEL_SETUP[aPanelNum]["AURA_ANCHORS"];

	if not tPanelAnchors then
		return;
	end

	for tAnchorIndex, tAnchorConfig in pairs(tPanelAnchors) do
		VUHDO_initAuraAnchorFrames(aButton, aPanelNum, tAnchorIndex, tAnchorConfig);
	end

	return;

end



--
local tFrame;
local tMaxSlots;
function VUHDO_initAuraAnchorFrames(aButton, aPanelNum, anAnchorIndex, anAnchorConfig)

	if not aButton or not anAnchorConfig then
		return;
	end

	tMaxSlots = anAnchorConfig["maxDisplay"] or 5;

	VUHDO_resetFixedAuraOverflowState(aButton, anAnchorIndex);

	for tSlotIndex = 1, tMaxSlots do
		if anAnchorConfig["style"] == "bars" then
			tFrame = VUHDO_acquireAuraBarFrame(aButton, anAnchorIndex, tSlotIndex);
		else
			tFrame = VUHDO_acquireAuraIconFrame(aButton, anAnchorIndex, tSlotIndex);
		end

		if tFrame then
			VUHDO_positionAuraFrame(tFrame, aButton, anAnchorConfig, tSlotIndex, anAnchorIndex);

			tFrame:SetAlpha(0);
			tFrame:Show();
		end
	end

	return;

end



--
local tButton;
local tPanelNum;
local tAnchorConfig;
local tShowTooltip;
function VUHDO_showAuraTooltip(aAuraFrame)

	if not aAuraFrame then
		return;
	end

	tPanelNum = aAuraFrame["panelNum"];
	tAnchorConfig = nil;

	if tPanelNum and aAuraFrame["anchorIndex"] then
		tAnchorConfig = VUHDO_PANEL_SETUP[tPanelNum] and VUHDO_PANEL_SETUP[tPanelNum]["AURA_ANCHORS"] and VUHDO_PANEL_SETUP[tPanelNum]["AURA_ANCHORS"][aAuraFrame["anchorIndex"]];
	end

	tShowTooltip = VUHDO_getAnchorTriStateBool(tAnchorConfig, "showTooltip", VUHDO_CONFIG and VUHDO_CONFIG["DEBUFF_TOOLTIP"]);

	if not tShowTooltip then
		return;
	end

	tButton = VUHDO_findButtonFromChild(aAuraFrame);

	if not tButton then
		return;
	end

	if GameTooltip:IsForbidden() then
		return;
	end

	GameTooltip:SetOwner(aAuraFrame, "ANCHOR_RIGHT", 0, 0);

	if aAuraFrame["auraInstanceId"] and tButton["raidid"] then
		GameTooltip:SetUnitAuraByAuraInstanceID(tButton["raidid"], aAuraFrame["auraInstanceId"]);
	end

	return;

end



--
function VUHDO_hideAuraTooltip()

	if not GameTooltip:IsForbidden() then
		GameTooltip:Hide();
	end

	return;

end



--
local tAnchorSlots;
local tMaxSlots;
local tAnchorConfig;
function VUHDO_updateAurasForAnchors(aUnit, aPanelNum)

	if not aUnit or not aPanelNum then
		return;
	end

	tAnchorSlots = VUHDO_UNIT_AURA_SLOTS[aUnit] and VUHDO_UNIT_AURA_SLOTS[aUnit][aPanelNum];

	if not tAnchorSlots then
		return;
	end

	for tAnchorIndex, tSlots in pairs(tAnchorSlots) do
		tAnchorConfig = VUHDO_PANEL_SETUP[aPanelNum] and VUHDO_PANEL_SETUP[aPanelNum]["AURA_ANCHORS"] and VUHDO_PANEL_SETUP[aPanelNum]["AURA_ANCHORS"][tAnchorIndex];

		if tAnchorConfig then
			tMaxSlots = tAnchorConfig["maxDisplay"] or 5;
			VUHDO_displayAurasAtAnchorFromCache(aUnit, aPanelNum, tAnchorIndex, tAnchorConfig, tSlots, tMaxSlots);
		end
	end

	return;

end



--
local tPanelUnitButtons;
local tMaxSlots;
function VUHDO_clearAurasForAnchor(aUnit, aPanelNum, anAnchorIndex, anAnchorConfig)

	if not aUnit or not aPanelNum or not anAnchorIndex or not anAnchorConfig then
		return;
	end

	tPanelUnitButtons = VUHDO_getUnitButtonsPanel(aUnit, aPanelNum);

	if not tPanelUnitButtons then
		return;
	end

	tMaxSlots = anAnchorConfig["maxDisplay"] or 5;

	for _, tButton in pairs(tPanelUnitButtons) do
		for tSlotIndex = 1, tMaxSlots do
			VUHDO_hideAuraSlot(tButton, anAnchorIndex, tSlotIndex, anAnchorConfig["style"] == "bars");
		end
	end

	for tSlotIndex = 1, tMaxSlots do
		VUHDO_setAnchorSlotAuraId(aUnit, aPanelNum, anAnchorIndex, tSlotIndex, nil);
	end

	return;

end



--
local tPanelUnitButtons;
local tAuraInstanceId;
local tAuraData;
function VUHDO_displayAurasAtAnchorFromCache(aUnit, aPanelNum, anAnchorIndex, anAnchorConfig, anAnchorSlots, aMaxSlots)

	if not aUnit or not aPanelNum or not anAnchorIndex or not anAnchorConfig then
		return;
	end

	tPanelUnitButtons = VUHDO_getUnitButtonsPanel(aUnit, aPanelNum);

	if not tPanelUnitButtons then
		return;
	end

	for _, tButton in pairs(tPanelUnitButtons) do
		for tSlotIndex = 1, aMaxSlots do
			tAuraInstanceId = anAnchorSlots and anAnchorSlots[tSlotIndex];

			if tAuraInstanceId then
				tAuraData = VUHDO_UNIT_AURA_CACHE[aUnit] and VUHDO_UNIT_AURA_CACHE[aUnit][tAuraInstanceId];

				if tAuraData then
					VUHDO_displayAuraInSlot(tButton, aPanelNum, anAnchorIndex, tSlotIndex, tAuraData, anAnchorConfig);
				else
					VUHDO_hideAuraSlot(tButton, anAnchorIndex, tSlotIndex, anAnchorConfig["style"] == "bars");
				end
			else
				VUHDO_hideAuraSlot(tButton, anAnchorIndex, tSlotIndex, anAnchorConfig["style"] == "bars");
			end
		end
	end

	return;

end



--
function VUHDO_displayAuraInSlot(aButton, aPanelNum, anAnchorIndex, aSlotIndex, anAuraData, anAnchorConfig)

	if not aButton or not anAnchorIndex or not aSlotIndex or not anAuraData or not anAnchorConfig then
		return;
	end

	if anAnchorConfig["style"] == "bars" then
		VUHDO_displayAuraAsBar(aButton, aPanelNum, anAnchorIndex, aSlotIndex, anAuraData, anAnchorConfig);
	else
		VUHDO_displayAuraAsIcon(aButton, aPanelNum, anAnchorIndex, aSlotIndex, anAuraData, anAnchorConfig);
	end

	return;

end



do
	--
	local tIconType;
	local tShowClock;
	local tFadeOnLow;
	local tFadeAlpha;
	local tDispelBorder;
	local tColorMixin;
	local tDispelR;
	local tDispelG;
	local tDispelB;
	local tDispelA;
	local tDispelCurve;
	local tColorMode;
	local tClassColor;
	local tIconColor;
	function VUHDO_updateAuraIconDisplay(aIconTexture, aCooldownFrame, aBackdropFrame, anAnchorConfig, anAuraData, aDurationObj, aUnit)

		tIconType = anAnchorConfig["iconType"] or 1;

		if aIconTexture then
			if tIconType == 4 then
				aIconTexture:Hide();
			elseif tIconType == 3 then
				aIconTexture:SetTexture("Interface\\AddOns\\VuhDo\\Images\\hot_flat_16_16");

				tColorMode = anAnchorConfig["colorMode"] or "default";

				if "debuff" == tColorMode then
					tDispelCurve = VUHDO_getDispelCurveForContext(aUnit, anAnchorConfig);

					if tDispelCurve then
						tColorMixin = GetAuraDispelTypeColor(aUnit, anAuraData["auraInstanceID"], tDispelCurve);

						if tColorMixin then
							aIconTexture:SetVertexColor(tColorMixin:GetRGBA());
						else
							aIconTexture:SetVertexColor(1, 1, 1);
						end
					else
						aIconTexture:SetVertexColor(1, 1, 1);
					end
				elseif "class" == tColorMode then
					tClassColor = VUHDO_getClassColor(VUHDO_RAID[aUnit]);

					if tClassColor then
						aIconTexture:SetVertexColor(tClassColor["R"], tClassColor["G"], tClassColor["B"], 1);
					else
						aIconTexture:SetVertexColor(1, 1, 1);
					end
				else
					tIconColor = sBarColors and sBarColors["AURA_BAR_DEFAULT"];

					if tIconColor then
						aIconTexture:SetVertexColor(tIconColor["R"], tIconColor["G"], tIconColor["B"], tIconColor["O"] or 1);
					else
						aIconTexture:SetVertexColor(1, 1, 1);
					end
				end

				aIconTexture:Show();
			elseif tIconType == 2 then
				aIconTexture:SetTexture("Interface\\AddOns\\VuhDo\\Images\\icon_white_square");

				tColorMode = anAnchorConfig["colorMode"] or "default";

				if "debuff" == tColorMode then
					tDispelCurve = VUHDO_getDispelCurveForContext(aUnit, anAnchorConfig);

					if tDispelCurve then
						tColorMixin = GetAuraDispelTypeColor(aUnit, anAuraData["auraInstanceID"], tDispelCurve);

						if tColorMixin then
							aIconTexture:SetVertexColor(tColorMixin:GetRGBA());
						else
							aIconTexture:SetVertexColor(1, 1, 1);
						end
					else
						aIconTexture:SetVertexColor(1, 1, 1);
					end
				elseif "class" == tColorMode then
					tClassColor = VUHDO_getClassColor(VUHDO_RAID[aUnit]);

					if tClassColor then
						aIconTexture:SetVertexColor(tClassColor["R"], tClassColor["G"], tClassColor["B"], 1);
					else
						aIconTexture:SetVertexColor(1, 1, 1);
					end
				else
					tIconColor = sBarColors and sBarColors["AURA_BAR_DEFAULT"];

					if tIconColor then
						aIconTexture:SetVertexColor(tIconColor["R"], tIconColor["G"], tIconColor["B"], tIconColor["O"] or 1);
					else
						aIconTexture:SetVertexColor(1, 1, 1);
					end
				end

				aIconTexture:Show();
			else
				aIconTexture:SetTexture(anAuraData["icon"]);
				aIconTexture:SetVertexColor(1, 1, 1);
				aIconTexture:Show();
			end
		end

		tShowClock = VUHDO_resolveAuraTriState(anAnchorConfig["showClock"], "showClock");

		if aCooldownFrame then
			if tShowClock and aDurationObj then
				aCooldownFrame:SetCooldownFromDurationObject(aDurationObj);
				aCooldownFrame:SetAlpha(1);
			else
				aCooldownFrame:SetAlpha(0);
			end
		end

		tFadeOnLow = VUHDO_resolveAuraTriState(anAnchorConfig["fadeOnLow"], "fadeOnLow");

		if aIconTexture then
			if tFadeOnLow and aDurationObj and sCurveFadeAlpha then
				tFadeAlpha = aDurationObj:EvaluateRemainingDuration(sCurveFadeAlpha);
				aIconTexture:SetAlpha(tFadeAlpha);
			else
				aIconTexture:SetAlpha(1);
			end
		end

		tDispelBorder = VUHDO_resolveAuraTriState(anAnchorConfig["dispelBorder"], "dispelBorder");

		if aBackdropFrame and aBackdropFrame.SetBackdropBorderColor then
			tDispelCurve = VUHDO_getDispelCurveForContext(aUnit, anAnchorConfig);

			if tDispelBorder and aUnit and tDispelCurve then
				tColorMixin = GetAuraDispelTypeColor(aUnit, anAuraData["auraInstanceID"], tDispelCurve);

				if tColorMixin then
					tDispelR, tDispelG, tDispelB, tDispelA = tColorMixin:GetRGBA();
					aBackdropFrame:SetBackdropBorderColor(tDispelR, tDispelG, tDispelB, tDispelA);
				else
					aBackdropFrame:SetBackdropBorderColor(0, 0, 0, 0);
				end
			else
				aBackdropFrame:SetBackdropBorderColor(0, 0, 0, 0);
			end
		end

		return;

	end
end



do
	--
	local tShowTimer;
	local tShowStacks;
	local tStackType;
	local tRemainingSeconds;
	local tDurationText;
	local tTimerVisibility;
	local tTimerColorMixin;
	local tApplications;
	local tCountStr;
	local tTriangleColor;
	function VUHDO_updateAuraTimerAndStacks(aTimerText, aCountText, aChargeTexture, anAnchorConfig, anAuraData, aDurationObj, aUnit)

		if aTimerText then
			tShowTimer = VUHDO_resolveAuraTriState(anAnchorConfig["showTimer"], "showTimer");

			if tShowTimer and aDurationObj and sCurveTimerVisible then
				tRemainingSeconds = aDurationObj:GetRemainingDuration();

				if AbbreviateNumbers then
					tDurationText = AbbreviateNumbers(tRemainingSeconds, sTimeAbbrevData);
					aTimerText:SetText(tDurationText or "");
				elseif aDurationObj.HasSecretValues and not aDurationObj:HasSecretValues() then
					tDurationText = format("%.0f", tRemainingSeconds);
					aTimerText:SetText(tDurationText);
				else
					aTimerText:SetText("");
				end

				tTimerVisibility = aDurationObj:EvaluateRemainingDuration(sCurveTimerVisible);
				aTimerText:SetAlpha(tTimerVisibility);

				if sCurveTimerColor then
					tTimerColorMixin = aDurationObj:EvaluateRemainingDuration(sCurveTimerColor);
					aTimerText:SetTextColor(tTimerColorMixin:GetRGBA());
				elseif anAnchorConfig["TIMER_TEXT"] and anAnchorConfig["TIMER_TEXT"]["COLOR"] and VUHDO_textColor then
					aTimerText:SetTextColor(VUHDO_textColor(anAnchorConfig["TIMER_TEXT"]["COLOR"]));
				else
					aTimerText:SetTextColor(1, 1, 1, 1);
				end

				VUHDO_registerAuraTimerText(aTimerText, aDurationObj);
			else
				VUHDO_unregisterAuraTimerText(aTimerText);
				aTimerText:SetText("");
				aTimerText:SetTextColor(1, 1, 1, 1);
				aTimerText:SetAlpha(1);
			end
		end

		if aCountText then
			tShowStacks = VUHDO_resolveAuraTriState(anAnchorConfig["showStacks"], "showStacks");
			tStackType = anAnchorConfig["stackType"] or 1;

			if tShowStacks and tStackType == 2 and aChargeTexture then
				tApplications = anAuraData["applications"];

				if tApplications and not issecretvalue(tApplications) and tApplications > 0 then
					aChargeTexture:SetTexture("Interface\\AddOns\\VuhDo\\Images\\aura_stacks_spritesheet");
					aChargeTexture:SetSpriteSheetCell(tApplications, 1, 8);

					tTriangleColor = sBarColors and sBarColors["AURA_STACK_TRIANGLE"];

					if tTriangleColor then
						aChargeTexture:SetVertexColor(tTriangleColor["R"] or 1, tTriangleColor["G"] or 1, tTriangleColor["B"] or 1, tTriangleColor["O"] or 1);
					else
						aChargeTexture:SetVertexColor(1, 1, 1, 1);
					end

					aChargeTexture:Show();
				else
					aChargeTexture:Hide();
				end

				aCountText:SetText("");
			else
				if aChargeTexture then
					aChargeTexture:Hide();
				end

				if tShowStacks and GetAuraApplicationDisplayCount and aUnit then
					tCountStr = GetAuraApplicationDisplayCount(aUnit, anAuraData["auraInstanceID"], 2, 999);
					aCountText:SetText(tCountStr or "");

					if anAnchorConfig["COUNTER_TEXT"] and anAnchorConfig["COUNTER_TEXT"]["COLOR"] and VUHDO_textColor then
						aCountText:SetTextColor(VUHDO_textColor(anAnchorConfig["COUNTER_TEXT"]["COLOR"]));
					end
				else
					aCountText:SetText("");
				end
			end
		end

		return;

	end
end



do
	--
	local tIconFrame;
	local tChild;
	local tTexture;
	local tUnit;
	local tFlashOnLow;
	local tTimerText;
	local tCountText;
	local tDurationObj;
	local tFlashZone;
	function VUHDO_displayAuraAsIcon(aButton, aPanelNum, anAnchorIndex, aSlotIndex, anAuraData, anAnchorConfig)

		if not aButton or not anAnchorIndex or not aSlotIndex or not anAuraData or not anAnchorConfig then
			return;
		end

		tIconFrame = VUHDO_acquireAuraIconFrame(aButton, anAnchorIndex, aSlotIndex);

		if not tIconFrame then
			return;
		end

		tIconFrame["panelNum"] = aPanelNum;
		tIconFrame["anchorIndex"] = anAnchorIndex;
		tIconFrame["auraInstanceId"] = anAuraData["auraInstanceID"];

		tUnit = aButton:GetAttribute("unit");

		tDurationObj = nil;

		if tUnit and GetAuraDuration then
			tDurationObj = GetAuraDuration(tUnit, anAuraData["auraInstanceID"]);
		end

		tChild = tIconFrame.childB or VUHDO_getAuraIconBackdrop(tIconFrame);

		if tChild then
			tTexture = tChild.textureI or VUHDO_getAuraIconTexture(tChild);

			VUHDO_updateAuraIconDisplay(tTexture, tChild.cooldownFrame, tChild, anAnchorConfig, anAuraData, tDurationObj, tUnit);

			tTimerText = tChild.timerText;
			tCountText = tChild.countText;

			VUHDO_updateAuraTimerAndStacks(tTimerText, tCountText, tChild.chargeTexture, anAnchorConfig, anAuraData, tDurationObj, tUnit);

			tChild:SetAlpha(1);

			tFlashOnLow = VUHDO_resolveAuraTriState(anAnchorConfig["flashOnLow"], "flashOnLow");

			if VUHDO_UIFrameFlashStop and VUHDO_UIFrameFlash then
				if tFlashOnLow and tDurationObj and sCurveFlashZone and not tDurationObj:HasSecretValues() then
					tFlashZone = tDurationObj:EvaluateRemainingDuration(sCurveFlashZone);

					if tFlashZone > 0.5 then
						VUHDO_UIFrameFlash(tIconFrame, 0.2, 0.1, 5, true, 0, 0.1);
					else
						VUHDO_UIFrameFlashStop(tIconFrame);
					end
				else
					VUHDO_UIFrameFlashStop(tIconFrame);
				end
			end
		end

		tIconFrame:SetAlpha(1);

		return;

	end
end



do
	--
	local tBarFrame;
	local tBar;
	local tBarTexName;
	local tUnit;
	local tDurationObj;
	local tFlashOnLow;
	local tFlashZone;
	local tBarVertical;
	local tBarTurnAxis;
	local tBarInvertGrowth;
	local tBarOrientation;
	local tColorMode;
	local tColorMixin;
	local tClassColor;
	local tBarColor;
	local tDispelCurve;
	function VUHDO_displayAuraAsBar(aButton, aPanelNum, anAnchorIndex, aSlotIndex, anAuraData, anAnchorConfig)

		if not aButton or not anAnchorIndex or not aSlotIndex or not anAuraData or not anAnchorConfig then
			return;
		end

		tBarFrame = VUHDO_acquireAuraBarFrame(aButton, anAnchorIndex, aSlotIndex);

		if not tBarFrame then
			return;
		end

		tBarFrame["panelNum"] = aPanelNum;
		tBarFrame["anchorIndex"] = anAnchorIndex;
		tBarFrame["auraInstanceId"] = anAuraData["auraInstanceID"];

		tUnit = aButton:GetAttribute("unit");

		tDurationObj = nil;

		if tUnit and GetAuraDuration then
			tDurationObj = GetAuraDuration(tUnit, anAuraData["auraInstanceID"]);
		end

		tBar = tBarFrame.childBar;

		if not tBar then
			return;
		end

		tBarTexName = VUHDO_PANEL_SETUP[aPanelNum] and VUHDO_PANEL_SETUP[aPanelNum]["PANEL_COLOR"] and VUHDO_PANEL_SETUP[aPanelNum]["PANEL_COLOR"]["barTexture"];

		if tBarTexName and VUHDO_setLlcStatusBarTexture then
			VUHDO_setLlcStatusBarTexture(tBar, tBarTexName);
		end

		tColorMode = anAnchorConfig["colorMode"] or "default";

		if "debuff" == tColorMode then
			tDispelCurve = VUHDO_getDispelCurveForContext(tUnit, anAnchorConfig);

			if tDispelCurve then
				tColorMixin = GetAuraDispelTypeColor(tUnit, anAuraData["auraInstanceID"], tDispelCurve);

				if tColorMixin then
					tBar:GetStatusBarTexture():SetVertexColor(tColorMixin:GetRGBA());
				else
					tBar:GetStatusBarTexture():SetVertexColor(0.2, 0.6, 0.2, 1);
				end
			else
				tBar:GetStatusBarTexture():SetVertexColor(0.2, 0.6, 0.2, 1);
			end
		elseif "class" == tColorMode then
			tClassColor = VUHDO_getClassColor(VUHDO_RAID[tUnit]);

			if tClassColor then
				tBar:GetStatusBarTexture():SetVertexColor(tClassColor["R"], tClassColor["G"], tClassColor["B"], 1);
			else
				tBar:GetStatusBarTexture():SetVertexColor(0.2, 0.6, 0.2, 1);
			end
		else
			tBarColor = sBarColors and sBarColors["AURA_BAR_DEFAULT"];

			if tBarColor then
				tBar:GetStatusBarTexture():SetVertexColor(tBarColor["R"], tBarColor["G"], tBarColor["B"], tBarColor["O"] or 1);
			else
				tBar:GetStatusBarTexture():SetVertexColor(0.2, 0.6, 0.2, 1);
			end
		end

		tBarVertical = anAnchorConfig["barVertical"] or false;
		tBarTurnAxis = anAnchorConfig["barTurnAxis"] or false;
		tBarInvertGrowth = anAnchorConfig["barInvertGrowth"] or false;

		if tBarVertical then
			tBarOrientation = tBarTurnAxis and VUHDO_STATUSBAR_TOP_TO_BOTTOM or VUHDO_STATUSBAR_BOTTOM_TO_TOP;
		else
			tBarOrientation = tBarTurnAxis and VUHDO_STATUSBAR_RIGHT_TO_LEFT or VUHDO_STATUSBAR_LEFT_TO_RIGHT;
		end

		VUHDO_setStatusBarOrientation(tBar, tBarOrientation);
		tBar:SetReverseFill(tBarInvertGrowth);

		if tDurationObj then
			tBar:SetTimerDuration(tDurationObj, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime);
		else
			tBar:SetMinMaxValues(0, 1);
			tBar:SetValue(1);
		end

		VUHDO_updateAuraIconDisplay(tBarFrame.childIcon, tBarFrame.cooldownFrame, nil, anAnchorConfig, anAuraData, tDurationObj, tUnit);

		VUHDO_updateAuraTimerAndStacks(tBarFrame.timerText, tBarFrame.countText, nil, anAnchorConfig, anAuraData, tDurationObj, tUnit);

		tBar:SetAlpha(1);

		tFlashOnLow = VUHDO_resolveAuraTriState(anAnchorConfig["flashOnLow"], "flashOnLow");

		if VUHDO_UIFrameFlashStop and VUHDO_UIFrameFlash then
			if tFlashOnLow and tDurationObj and sCurveFlashZone and not tDurationObj:HasSecretValues() then
				tFlashZone = tDurationObj:EvaluateRemainingDuration(sCurveFlashZone);

				if tFlashZone > 0.5 then
					VUHDO_UIFrameFlash(tBarFrame, 0.2, 0.1, 5, true, 0, 0.1);
				else
					VUHDO_UIFrameFlashStop(tBarFrame);
				end
			else
				VUHDO_UIFrameFlashStop(tBarFrame);
			end
		end

		tBarFrame:SetAlpha(1);

		return;

	end
end



do
	--
	local tFrameName;
	local tFrame;
	function VUHDO_hideAuraSlot(aButton, anAnchorIndex, aSlotIndex, anIsBar)

		if not aButton or not anAnchorIndex or not aSlotIndex then
			return;
		end

		tFrameName = aButton:GetName();

		tFrame = VUHDO_AURA_FRAMES[tFrameName] and VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex] and VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex][aSlotIndex];

		if tFrame then
			if tFrame.childB and tFrame.childB["timerText"] then
				VUHDO_unregisterAuraTimerText(tFrame.childB["timerText"]);
			elseif tFrame["timerText"] then
				VUHDO_unregisterAuraTimerText(tFrame["timerText"]);
			end

			if VUHDO_UIFrameFlashStop then
				VUHDO_UIFrameFlashStop(tFrame);
			end

			if tFrame.childIcon then
				tFrame.childIcon:Hide();
			end

			tFrame:SetAlpha(0);
		end

		return;

	end
end



--
function VUHDO_updateAuraDisplaysForUnit(aUnit)

	if not aUnit then
		return;
	end

	for tPanelNum = 1, 10 do
		VUHDO_updateAurasForAnchors(aUnit, tPanelNum);
	end

	return;

end



do
	--
	local tFrameName;
	local tFrame;
	function VUHDO_hideAuraSlot(aButton, anAnchorIndex, aSlotIndex, anIsBar)

		if not aButton or not anAnchorIndex or not aSlotIndex then
			return;
		end

		tFrameName = aButton:GetName();

		tFrame = VUHDO_AURA_FRAMES[tFrameName] and VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex] and VUHDO_AURA_FRAMES[tFrameName][anAnchorIndex][aSlotIndex];

		if tFrame then
			if tFrame.childB and tFrame.childB["timerText"] then
				VUHDO_unregisterAuraTimerText(tFrame.childB["timerText"]);
			elseif tFrame["timerText"] then
				VUHDO_unregisterAuraTimerText(tFrame["timerText"]);
			end

			if VUHDO_UIFrameFlashStop then
				VUHDO_UIFrameFlashStop(tFrame);
			end

			if tFrame.childIcon then
				tFrame.childIcon:Hide();
			end

			tFrame:SetAlpha(0);
		end

		return;

	end
end



--
function VUHDO_updateAuraDisplaysForUnit(aUnit)

	if not aUnit then
		return;
	end

	for tPanelNum = 1, 10 do
		VUHDO_updateAurasForAnchors(aUnit, tPanelNum);
	end

	return;

end