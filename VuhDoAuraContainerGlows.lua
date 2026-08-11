local _;

local min = math.min;
local max = math.max;

local GetAtlasInfo = C_Texture.GetAtlasInfo;

local VUHDO_PANEL_SETUP;
local VUHDO_AURA_GROUP_COLOR_DISPEL;
local VUHDO_AURA_GROUP_COLOR_ALL_DISPEL;
local VUHDO_CUSTOM_GLOW_AURA_GROUP_KEY;
local VUHDO_AURA_GROUP_GLOW_ACTIVE_KEY;
local VUHDO_DEFAULT_AURA_GLOW_STYLE;

local VUHDO_LibOrbitGlow;
local VUHDO_PixelUtil;

local VUHDO_getAuraBarColor;
local VUHDO_getDispellableAuraId;
local VUHDO_getDispelCurveForUnit;
local VUHDO_getDispelTypeColorMapOpaque;

local sResolvedGlowVisuals = { };
local sDefaultGlowVisual;

local sDefaultFlipbookScale = 1.4;
local sAuraGlowStylesInitialized = false;
local sGlowPackRoot = "Interface\\AddOns\\VuhDo\\Images\\Glows\\";
local sGlowScaleInner = 1.0;
local sGlowScaleBlizzard = 1.4;
local sGlowBarDesignSize = 36;
local sGlowBarMaxScale = 1.55;

local sGlowBarScaleOverrides = {
	["vuhdoants"] = 0.98,
};

local sAuraGroupBarGlowDispelOptions = {
	["style"] = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
	["showWhenHarmful"] = true,
	["showWhenHelpful"] = true,
};

local sGlowPackStyleDefs = {
	{
		["name"] = "vuhdopixel",
		["rows"] = 6,
		["cols"] = 5,
		["frames"] = 30,
		["duration"] = 1.2,
	},
	{
		["name"] = "vuhdospark",
		["rows"] = 6,
		["cols"] = 5,
		["frames"] = 30,
		["duration"] = 2.0,
	},
	{
		["name"] = "vuhdoants",
		["rows"] = 6,
		["cols"] = 5,
		["frames"] = 30,
		["duration"] = 0.8,
	},
	{
		["name"] = "vuhdocomet",
		["rows"] = 6,
		["cols"] = 5,
		["frames"] = 30,
		["duration"] = 2.2,
	},
	{
		["name"] = "vuhdopulse",
		["rows"] = 6,
		["cols"] = 5,
		["frames"] = 30,
		["duration"] = 1.8,
	},
	{
		["name"] = "vuhdowave",
		["rows"] = 6,
		["cols"] = 5,
		["frames"] = 30,
		["duration"] = 1.6,
	},
	{
		["name"] = "vuhdoswirl",
		["rows"] = 6,
		["cols"] = 5,
		["frames"] = 30,
		["duration"] = 1.6,
	},
	{
		["name"] = "vuhdorays",
		["rows"] = 6,
		["cols"] = 5,
		["frames"] = 30,
		["duration"] = 1.6,
	},
	{
		["name"] = "vuhdoripple",
		["rows"] = 6,
		["cols"] = 5,
		["frames"] = 30,
		["duration"] = 2.0,
	},
	{
		["name"] = "vuhdoreticle",
		["rows"] = 6,
		["cols"] = 5,
		["frames"] = 30,
		["duration"] = 1.4,
	},
	{
		["name"] = "vuhdoembers",
		["rows"] = 6,
		["cols"] = 5,
		["frames"] = 30,
		["duration"] = 1.6,
	},
};

local sUnitButtonGlowProcOptions = { };
local sUnitGlowColorArray = { 0.95, 0.95, 0.32, 1 };



--
local tGlowDef;
function VUHDO_initAuraGlowStyles()

	if sAuraGlowStylesInitialized then
		return;
	end

	for _, tStyleDef in ipairs(sGlowPackStyleDefs) do
		VUHDO_LibOrbitGlow:RegisterGlow(tStyleDef["name"], {
			["path"] = sGlowPackRoot .. tStyleDef["name"],
			["loopOnly"] = true,
			["shaped"] = false,
			["blendMode"] = "BLEND",
			["scale"] = sGlowScaleInner,
			["source"] = "VuhDo",
			["rows"] = tStyleDef["rows"],
			["cols"] = tStyleDef["cols"],
			["frames"] = tStyleDef["frames"],
			["duration"] = tStyleDef["duration"],
		});
	end

	VUHDO_LibOrbitGlow:RegisterGlow("vuhdohalo", {
		["path"] = sGlowPackRoot .. "vuhdohalo",
		["loopOnly"] = true,
		["shaped"] = false,
		["layered"] = true,
		["scale"] = sGlowScaleInner,
		["source"] = "VuhDo",
		["rows"] = 6,
		["cols"] = 5,
		["frames"] = 30,
		["duration"] = 1.8,
	});

	tGlowDef = VUHDO_LibOrbitGlow:GetGlowInfo("blizzard");

	if tGlowDef then
		tGlowDef["scale"] = sGlowScaleBlizzard;
		tGlowDef["blendMode"] = "ADD";
	else
		VUHDO_LibOrbitGlow:RegisterGlow("blizzard", {
			["atlas"] = "UI-HUD-ActionBar-Proc-Loop-Flipbook",
			["layered"] = false,
			["blendMode"] = "ADD",
			["scale"] = sGlowScaleBlizzard,
			["source"] = "VuhDo",
		});
	end

	tGlowDef = VUHDO_LibOrbitGlow:GetGlowInfo("blizzardants");

	if tGlowDef then
		tGlowDef["scale"] = sGlowScaleBlizzard;
		tGlowDef["blendMode"] = "BLEND";
	else
		VUHDO_LibOrbitGlow:RegisterGlow("blizzardants", {
			["atlas"] = "RotationHelper_Ants_Flipbook_2x",
			["layered"] = false,
			["blendMode"] = "BLEND",
			["scale"] = sGlowScaleBlizzard,
			["source"] = "VuhDo",
		});
	end

	tGlowDef = VUHDO_LibOrbitGlow:GetGlowInfo("blizzardblue");

	if tGlowDef then
		tGlowDef["scale"] = sGlowScaleBlizzard;
		tGlowDef["blendMode"] = "ADD";
	else
		VUHDO_LibOrbitGlow:RegisterGlow("blizzardblue", {
			["atlas"] = "RotationHelper-ProcLoopBlue-Flipbook-2x",
			["layered"] = false,
			["blendMode"] = "ADD",
			["scale"] = sGlowScaleBlizzard,
			["source"] = "VuhDo",
		});
	end

	sAuraGlowStylesInitialized = true;

	return;

end



--
function VUHDO_auraContainerGlowInitLocalOverrides()

	VUHDO_PANEL_SETUP = _G["VUHDO_PANEL_SETUP"];
	VUHDO_AURA_GROUP_COLOR_DISPEL = _G["VUHDO_AURA_GROUP_COLOR_DISPEL"];
	VUHDO_AURA_GROUP_COLOR_ALL_DISPEL = _G["VUHDO_AURA_GROUP_COLOR_ALL_DISPEL"];
	VUHDO_CUSTOM_GLOW_AURA_GROUP_KEY = _G["VUHDO_CUSTOM_GLOW_AURA_GROUP_KEY"];
	VUHDO_AURA_GROUP_GLOW_ACTIVE_KEY = _G["VUHDO_AURA_GROUP_GLOW_ACTIVE_KEY"];
	VUHDO_DEFAULT_AURA_GLOW_STYLE = _G["VUHDO_DEFAULT_AURA_GLOW_STYLE"];

	VUHDO_LibOrbitGlow = _G["VUHDO_LibOrbitGlow"];
	VUHDO_PixelUtil = _G["VUHDO_PixelUtil"];

	VUHDO_getAuraBarColor = _G["VUHDO_getAuraBarColor"];
	VUHDO_getDispellableAuraId = _G["VUHDO_getDispellableAuraId"];
	VUHDO_getDispelCurveForUnit = _G["VUHDO_getDispelCurveForUnit"];
	VUHDO_getDispelTypeColorMapOpaque = _G["VUHDO_getDispelTypeColorMapOpaque"];

	VUHDO_initAuraGlowStyles();

	return;

end



--
local tAtlasInfo;
local tGlowRows;
local tGlowCols;
local tGlowFrames;
local function VUHDO_getDefaultGlowVisual()

	if sDefaultGlowVisual then
		return sDefaultGlowVisual;
	end

	tGlowRows = 6;
	tGlowCols = 5;
	tGlowFrames = 30;

	tAtlasInfo = GetAtlasInfo("UI-HUD-ActionBar-Proc-Loop-Flipbook");

	if tAtlasInfo then
		tGlowRows = tAtlasInfo["flipBookRows"] or tGlowRows;
		tGlowCols = tAtlasInfo["flipBookColumns"] or tGlowCols;
		tGlowFrames = tAtlasInfo["flipBookFrames"] or tGlowFrames;
	end

	sDefaultGlowVisual = {
		["mode"] = "atlas",
		["atlas"] = "UI-HUD-ActionBar-Proc-Loop-Flipbook",
		["rows"] = tGlowRows,
		["cols"] = tGlowCols,
		["frames"] = tGlowFrames,
		["blendMode"] = "ADD",
		["desaturated"] = true,
		["scale"] = sDefaultFlipbookScale,
		["padding"] = 0,
		["offsetScale"] = 0,
		["duration"] = 1.0,
	};

	return sDefaultGlowVisual;

end



--
local function VUHDO_mergeGlowDefLayoutParams(aVisual, aGlowDef)

	aVisual["scale"] = aGlowDef["scale"] or sDefaultFlipbookScale;
	aVisual["padding"] = aGlowDef["padding"] or 0;
	aVisual["offsetScale"] = aGlowDef["offsetScale"] or 0;
	aVisual["duration"] = aGlowDef["duration"] or 1.0;

	return;

end



--
local tBarGlowRef;
local tBarGlowBoost;
local tBarGlowScale;
local tBarGlowBaseScaleVal;
local tBarGlowOverrideScale;
local function VUHDO_getAuraBarGlowScale(aBaseScale, aWidth, aHeight, aStyleName)

	tBarGlowOverrideScale = aStyleName and sGlowBarScaleOverrides[aStyleName];

	if tBarGlowOverrideScale then
		return tBarGlowOverrideScale;
	end

	tBarGlowBaseScaleVal = aBaseScale or sDefaultFlipbookScale;

	if tBarGlowBaseScaleVal <= 1.15 then
		return 1.0;
	end

	tBarGlowRef = min(aWidth or sGlowBarDesignSize, aHeight or aWidth or sGlowBarDesignSize);

	if tBarGlowRef <= 0 then
		tBarGlowRef = sGlowBarDesignSize;
	end

	tBarGlowBoost = max(0, (tBarGlowRef / sGlowBarDesignSize) - 1);

	tBarGlowScale = min(sGlowBarMaxScale, tBarGlowBaseScaleVal * (1 + 0.25 * tBarGlowBoost));

	return tBarGlowScale;

end



--
local tGlowWidth;
local tGlowHeight;
local tScale;
local tPadX;
local tPadY;
local function VUHDO_anchorInPlaceGlowTexture(aTexture, aGlowFrame, aGlowVisual, aWidth, aHeight, aScale)

	if aWidth and aHeight then
		tGlowWidth = aWidth;
		tGlowHeight = aHeight;
	else
		tGlowWidth = aGlowFrame:GetWidth() or 20;
		tGlowHeight = aGlowFrame:GetHeight() or tGlowWidth;
	end

	tScale = aScale or aGlowVisual["scale"] or sDefaultFlipbookScale;

	tPadX = (aGlowVisual["padding"] or 0) + (aGlowVisual["offsetScale"] or 0) + (tGlowWidth * (tScale - 1) / 2);
	tPadY = (aGlowVisual["padding"] or 0) + (aGlowVisual["offsetScale"] or 0) + (tGlowHeight * (tScale - 1) / 2);

	VUHDO_PixelUtil.SetPoint(aTexture, "TOPLEFT", aGlowFrame, "TOPLEFT", -tPadX, tPadY);
	VUHDO_PixelUtil.SetPoint(aTexture, "BOTTOMRIGHT", aGlowFrame, "BOTTOMRIGHT", tPadX, -tPadY);

	return;

end



--
local tAnimGroup;
local tAnim;
local function VUHDO_playInPlaceFlipbookGlow(aTexture, aGlowVisual, anExistingAnimGroup)

	if anExistingAnimGroup then
		tAnimGroup = anExistingAnimGroup;

		tAnimGroup:Stop();
	else
		tAnimGroup = aTexture:CreateAnimationGroup();

		tAnimGroup:SetLooping("REPEAT");

		tAnim = tAnimGroup:CreateAnimation("FlipBook");

		tAnim:SetDuration(aGlowVisual["duration"] or 1.0);
		tAnim:SetFlipBookRows(aGlowVisual["rows"]);
		tAnim:SetFlipBookColumns(aGlowVisual["cols"]);
		tAnim:SetFlipBookFrames(aGlowVisual["frames"]);
	end

	tAnimGroup:Play();

	return tAnimGroup;

end



--
local tGlowShapes;
local function VUHDO_resolveGlowShape(aGlowDef)

	tGlowShapes = aGlowDef["shapes"];

	if tGlowShapes then
		if tGlowShapes["square"] then
			return "square";
		end

		for tShapeName in pairs(tGlowShapes) do
			return tShapeName;
		end
	end

	return "square";

end



--
local tGlowStyleName;
local tGlowVisual;
local tGlowDef;
local tAtlasInfo;
local tGlowRows;
local tGlowCols;
local tGlowFrames;
local tGlowExt;
local tGlowBodyPath;
local tGlowCorePath;
local tGlowShapeKey;
function VUHDO_resolveGlowVisual(aStyleName)

	tGlowStyleName = aStyleName or VUHDO_DEFAULT_AURA_GLOW_STYLE;
	tGlowVisual = sResolvedGlowVisuals[tGlowStyleName];

	if tGlowVisual then
		return tGlowVisual;
	end

	tGlowDef = VUHDO_LibOrbitGlow:GetGlowInfo(tGlowStyleName);

	if tGlowDef and tGlowDef["engine"] then
		if tGlowStyleName ~= VUHDO_DEFAULT_AURA_GLOW_STYLE then
			tGlowVisual = VUHDO_resolveGlowVisual(VUHDO_DEFAULT_AURA_GLOW_STYLE);
		else
			tGlowVisual = VUHDO_getDefaultGlowVisual();
		end

		sResolvedGlowVisuals[tGlowStyleName] = tGlowVisual;

		return tGlowVisual;
	end

	if tGlowDef and (tGlowDef["atlas"] or tGlowDef["path"]) then
		tGlowRows = tGlowDef["rows"] or 6;
		tGlowCols = tGlowDef["cols"] or 5;
		tGlowFrames = tGlowDef["frames"] or 30;

		if tGlowDef["atlas"] then
			tAtlasInfo = GetAtlasInfo(tGlowDef["atlas"]);

			if tAtlasInfo then
				tGlowRows = tAtlasInfo["flipBookRows"] or tGlowRows;
				tGlowCols = tAtlasInfo["flipBookColumns"] or tGlowCols;
				tGlowFrames = tAtlasInfo["flipBookFrames"] or tGlowFrames;
			end

			tGlowVisual = {
				["mode"] = "atlas",
				["atlas"] = tGlowDef["atlas"],
				["rows"] = tGlowRows,
				["cols"] = tGlowCols,
				["frames"] = tGlowFrames,
				["blendMode"] = tGlowDef["blendMode"] or "ADD",
				["desaturated"] = tGlowDef["desaturated"] ~= false,
			};

			VUHDO_mergeGlowDefLayoutParams(tGlowVisual, tGlowDef);
		else
			tGlowExt = tGlowDef["ext"] or ".tga";
			tGlowBodyPath = tGlowDef["path"] .. "-loop" .. tGlowExt;

			if tGlowDef["layered"] and tGlowDef["core"] ~= false then
				tGlowCorePath = tGlowDef["path"] .. "-loop-core" .. tGlowExt;
			else
				tGlowCorePath = nil;
			end

			tGlowVisual = {
				["mode"] = "path",
				["bodyPath"] = tGlowBodyPath,
				["corePath"] = tGlowCorePath,
				["rows"] = tGlowRows,
				["cols"] = tGlowCols,
				["frames"] = tGlowFrames,
				["bodyBlend"] = tGlowDef["layered"] and (tGlowDef["bodyBlend"] or "BLEND") or (tGlowDef["blendMode"] or "ADD"),
				["coreBlend"] = tGlowDef["coreBlend"] or "ADD",
			};

			VUHDO_mergeGlowDefLayoutParams(tGlowVisual, tGlowDef);
		end
	elseif tGlowDef and tGlowDef["resolve"] then
		tGlowRows = tGlowDef["rows"] or 6;
		tGlowCols = tGlowDef["cols"] or 5;
		tGlowFrames = tGlowDef["frames"] or 30;

		tGlowShapeKey = VUHDO_resolveGlowShape(tGlowDef);
		tGlowBodyPath = tGlowDef["resolve"]("loop", tGlowShapeKey, "");

		if tGlowDef["layered"] and tGlowDef["core"] ~= false then
			tGlowCorePath = tGlowDef["resolve"]("loop", tGlowShapeKey, "-core");
		else
			tGlowCorePath = nil;
		end

		if tGlowBodyPath then
			tGlowVisual = {
				["mode"] = "path",
				["bodyPath"] = tGlowBodyPath,
				["corePath"] = tGlowCorePath,
				["rows"] = tGlowRows,
				["cols"] = tGlowCols,
				["frames"] = tGlowFrames,
				["bodyBlend"] = tGlowDef["layered"] and (tGlowDef["bodyBlend"] or "BLEND") or (tGlowDef["blendMode"] or "ADD"),
				["coreBlend"] = tGlowDef["coreBlend"] or "ADD",
			};

			VUHDO_mergeGlowDefLayoutParams(tGlowVisual, tGlowDef);
		end
	end

	if not tGlowVisual then
		tGlowVisual = VUHDO_getDefaultGlowVisual();
	end

	sResolvedGlowVisuals[tGlowStyleName] = tGlowVisual;

	return tGlowVisual;

end



--
local tGlowColor;
local tGlowFrame;
local tGlowR;
local tGlowG;
local tGlowB;
local tGlowO;
local tGlowStyleName;
local tGlowVisual;
local tTexture;
local tCoreTexture;
function VUHDO_startAuraButtonGlow(aAuraButton, anButtonSetup)

	if aAuraButton["vuhdoGlow"] then
		return;
	end

	tGlowFrame = aAuraButton["IconFrame"] or aAuraButton;
	tGlowColor = anButtonSetup["glowColor"];

	if tGlowColor then
		tGlowR = tGlowColor["R"] or 1;
		tGlowG = tGlowColor["G"] or 1;
		tGlowB = tGlowColor["B"] or 0;
		tGlowO = tGlowColor["O"] or 1;
	else
		tGlowColor = VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF_ICON_GLOW"];

		tGlowR = tGlowColor["R"];
		tGlowG = tGlowColor["G"];
		tGlowB = tGlowColor["B"];
		tGlowO = tGlowColor["O"];
	end

	tGlowStyleName = anButtonSetup["glowStyle"] or VUHDO_DEFAULT_AURA_GLOW_STYLE;

	tGlowVisual = VUHDO_resolveGlowVisual(tGlowStyleName);

	tTexture = tGlowFrame:CreateTexture(nil, "OVERLAY", nil, 1);

	VUHDO_anchorInPlaceGlowTexture(tTexture, tGlowFrame, tGlowVisual);

	if "atlas" == tGlowVisual["mode"] then
		tTexture:SetAtlas(tGlowVisual["atlas"]);
		tTexture:SetDesaturated(tGlowVisual["desaturated"] ~= false);
		tTexture:SetBlendMode(tGlowVisual["blendMode"] or "ADD");
		tTexture:SetVertexColor(tGlowR, tGlowG, tGlowB, tGlowO);
	else
		tTexture:SetTexture(tGlowVisual["bodyPath"]);
		tTexture:SetBlendMode(tGlowVisual["bodyBlend"] or "ADD");
		tTexture:SetVertexColor(tGlowR, tGlowG, tGlowB, tGlowO);
	end

	VUHDO_playInPlaceFlipbookGlow(tTexture, tGlowVisual);

	tCoreTexture = nil;

	if "path" == tGlowVisual["mode"] and tGlowVisual["corePath"] then
		tCoreTexture = tGlowFrame:CreateTexture(nil, "OVERLAY", nil, 2);

		VUHDO_PixelUtil.SetPoint(tCoreTexture, "TOPLEFT", tTexture, "TOPLEFT", 0, 0);
		VUHDO_PixelUtil.SetPoint(tCoreTexture, "BOTTOMRIGHT", tTexture, "BOTTOMRIGHT", 0, 0);

		tCoreTexture:SetTexture(tGlowVisual["corePath"]);
		tCoreTexture:SetBlendMode(tGlowVisual["coreBlend"] or "ADD");
		tCoreTexture:SetVertexColor(0.6 + 0.4 * tGlowR, 0.6 + 0.4 * tGlowG, 0.6 + 0.4 * tGlowB, tGlowO);

		VUHDO_playInPlaceFlipbookGlow(tCoreTexture, tGlowVisual);
	end

	aAuraButton["vuhdoGlow"] = {
		["body"] = tTexture,
		["core"] = tCoreTexture,
	};

	return;

end



--
local tBarGlowEntry;
local tBarGlowBodyAnim;
local tBarGlowCoreAnim;
local tBarGlowClipFrame;
local tBarGlowHolderFrame;
local tTexture;
local tCoreTexture;
local function VUHDO_stopAuraButtonAuraGroupBarGlow(aAuraButton)

	tBarGlowEntry = aAuraButton["vuhdoAuraGroupBarGlow"];

	if not tBarGlowEntry then
		return;
	end

	tBarGlowBodyAnim = tBarGlowEntry["bodyAnim"];

	if tBarGlowBodyAnim then
		tBarGlowBodyAnim:Stop();
	end

	tTexture = tBarGlowEntry["body"];

	if tTexture then
		tTexture:Hide();
	end

	tBarGlowCoreAnim = tBarGlowEntry["coreAnim"];

	if tBarGlowCoreAnim then
		tBarGlowCoreAnim:Stop();
	end

	tCoreTexture = tBarGlowEntry["core"];

	if tCoreTexture then
		tCoreTexture:Hide();
	end

	tBarGlowHolderFrame = tBarGlowEntry["holder"];

	if tBarGlowHolderFrame then
		tBarGlowHolderFrame:Hide();
	end

	tBarGlowClipFrame = tBarGlowEntry["clip"];

	if tBarGlowClipFrame then
		tBarGlowClipFrame:Hide();
		tBarGlowClipFrame:SetParent(nil);
	end

	aAuraButton["vuhdoAuraGroupBarGlow"] = nil;

	return;

end



--
local tBarGlowStyle;
local tBarGlowWidth;
local tBarGlowHeight;
local tBarGlowBaseScale;
local tBarGlowEntry;
local tBarGlowBodyAnim;
local tBarGlowCoreAnim;
local tBarGlowClipFrame;
local tBarGlowHolderFrame;
local tGlowVisual;
local tTexture;
local tCoreTexture;
local tBarGlowScale;
local function VUHDO_startAuraButtonAuraGroupBarGlow(aAuraButton, anButtonSetup, aStyle, aColorR, aColorG, aColorB, aColorO)

	tBarGlowEntry = aAuraButton["vuhdoAuraGroupBarGlow"];
	tBarGlowStyle = aStyle or VUHDO_DEFAULT_AURA_GLOW_STYLE;

	if tBarGlowEntry and tBarGlowEntry["style"] == tBarGlowStyle then
		return;
	end

	if tBarGlowEntry then
		VUHDO_stopAuraButtonAuraGroupBarGlow(aAuraButton);
	end

	tGlowVisual = VUHDO_resolveGlowVisual(tBarGlowStyle);

	tBarGlowWidth = anButtonSetup["width"] or 20;
	tBarGlowHeight = anButtonSetup["height"] or tBarGlowWidth;

	tBarGlowBaseScale = tGlowVisual["scale"] or sDefaultFlipbookScale;
	tBarGlowScale = VUHDO_getAuraBarGlowScale(tBarGlowBaseScale, tBarGlowWidth, tBarGlowHeight, tBarGlowStyle);

	tBarGlowClipFrame = CreateFrame("Frame", nil, aAuraButton);

	tBarGlowClipFrame:SetAllPoints(aAuraButton);
	tBarGlowClipFrame:SetClipsChildren(true);
	tBarGlowClipFrame:SetFrameLevel(aAuraButton:GetFrameLevel() + 1);

	tBarGlowHolderFrame = CreateFrame("Frame", nil, tBarGlowClipFrame);

	VUHDO_anchorInPlaceGlowTexture(tBarGlowHolderFrame, tBarGlowClipFrame, tGlowVisual, tBarGlowWidth, tBarGlowHeight, tBarGlowScale);

	tTexture = tBarGlowHolderFrame:CreateTexture(nil, "OVERLAY", nil, 1);

	tTexture:SetAllPoints(tBarGlowHolderFrame);

	tCoreTexture = nil;

	if "path" == tGlowVisual["mode"] and tGlowVisual["corePath"] then
		tCoreTexture = tBarGlowHolderFrame:CreateTexture(nil, "OVERLAY", nil, 2);

		tCoreTexture:SetAllPoints(tBarGlowHolderFrame);
	end

	if "atlas" == tGlowVisual["mode"] then
		tTexture:SetAtlas(tGlowVisual["atlas"]);
		tTexture:SetDesaturated(tGlowVisual["desaturated"] ~= false);
		tTexture:SetBlendMode(tGlowVisual["blendMode"] or "ADD");
	else
		tTexture:SetTexture(tGlowVisual["bodyPath"]);
		tTexture:SetBlendMode(tGlowVisual["bodyBlend"] or "ADD");
	end

	tTexture:SetVertexColor(aColorR, aColorG, aColorB, aColorO);
	tTexture:Show();

	tBarGlowBodyAnim = VUHDO_playInPlaceFlipbookGlow(tTexture, tGlowVisual);

	if tCoreTexture then
		tCoreTexture:SetTexture(tGlowVisual["corePath"]);
		tCoreTexture:SetBlendMode(tGlowVisual["coreBlend"] or "ADD");
		tCoreTexture:SetVertexColor(0.6 + 0.4 * aColorR, 0.6 + 0.4 * aColorG, 0.6 + 0.4 * aColorB, aColorO);
		tCoreTexture:Show();

		tBarGlowCoreAnim = VUHDO_playInPlaceFlipbookGlow(tCoreTexture, tGlowVisual);
	else
		tBarGlowCoreAnim = nil;
	end

	tBarGlowEntry = {
		["style"] = tBarGlowStyle,
		["clip"] = tBarGlowClipFrame,
		["holder"] = tBarGlowHolderFrame,
		["body"] = tTexture,
		["core"] = tCoreTexture,
		["bodyAnim"] = tBarGlowBodyAnim,
		["coreAnim"] = tBarGlowCoreAnim,
	};

	aAuraButton["vuhdoAuraGroupBarGlow"] = tBarGlowEntry;

	return;

end



--
function VUHDO_stopUnitButtonAuraGroupGlow(aButton, aGlowKey)

	if not aButton or not aButton["hasAuraGroupBarGlow"] then
		return;
	end

	sUnitButtonGlowProcOptions["glow"] = aButton["auraGroupBarGlowStyle"];
	sUnitButtonGlowProcOptions["key"] = aGlowKey;

	VUHDO_LibOrbitGlow.Proc:Clear(aButton, sUnitButtonGlowProcOptions);

	aButton["hasAuraGroupBarGlow"] = nil;
	aButton["auraGroupBarGlowStyle"] = nil;
	aButton["auraGroupBarGlowKey"] = nil;

	return;

end



--
local tUnitGlowDef;
function VUHDO_startUnitButtonAuraGroupGlow(aButton, aStyle, aColorArray, aGlowKey)

	if aButton["hasAuraGroupBarGlow"] and (aButton["auraGroupBarGlowStyle"] ~= aStyle or aButton["auraGroupBarGlowKey"] ~= aGlowKey) then
		VUHDO_stopUnitButtonAuraGroupGlow(aButton, aGlowKey);
	end

	sUnitButtonGlowProcOptions["glow"] = aStyle;
	sUnitButtonGlowProcOptions["key"] = aGlowKey;
	sUnitButtonGlowProcOptions["color"] = aColorArray;
	sUnitButtonGlowProcOptions["frameLevel"] = 8;

	tUnitGlowDef = VUHDO_LibOrbitGlow:GetGlowInfo(aStyle);
	sUnitButtonGlowProcOptions["loopDuration"] = (tUnitGlowDef and tUnitGlowDef["duration"]) or 1.0;

	VUHDO_LibOrbitGlow.Proc:Loop(aButton, sUnitButtonGlowProcOptions);

	aButton["hasAuraGroupBarGlow"] = true;
	aButton["auraGroupBarGlowStyle"] = aStyle;
	aButton["auraGroupBarGlowKey"] = aGlowKey;

	return;

end



--
local tUnitGlowColor;
local tUnitDefaultGlow;
local tUnitDispelCurve;
local tUnitDispelColorMixin;
local tUnitBarColor;
local tUnitDispelAuraId;
function VUHDO_resolveAuraGroupBarGlowColorArray(aUnit, aGlowMeta)

	if (aGlowMeta["glowColorType"] == VUHDO_AURA_GROUP_COLOR_DISPEL or aGlowMeta["glowColorType"] == VUHDO_AURA_GROUP_COLOR_ALL_DISPEL) then
		tUnitBarColor = VUHDO_getAuraBarColor(aUnit);

		if tUnitBarColor and tUnitBarColor["R"] then
			sUnitGlowColorArray[1] = tUnitBarColor["R"];
			sUnitGlowColorArray[2] = tUnitBarColor["G"];
			sUnitGlowColorArray[3] = tUnitBarColor["B"];
			sUnitGlowColorArray[4] = tUnitBarColor["O"] or 1;

			return sUnitGlowColorArray;
		end

		tUnitDispelAuraId = VUHDO_getDispellableAuraId(aUnit);

		if tUnitDispelAuraId and tUnitDispelAuraId > 0 then
			tUnitDispelCurve = VUHDO_getDispelCurveForUnit(aUnit, true);

			if tUnitDispelCurve then
				tUnitDispelColorMixin = GetAuraDispelTypeColor(aUnit, tUnitDispelAuraId, tUnitDispelCurve);

				if tUnitDispelColorMixin then
					sUnitGlowColorArray[1] = tUnitDispelColorMixin.r;
					sUnitGlowColorArray[2] = tUnitDispelColorMixin.g;
					sUnitGlowColorArray[3] = tUnitDispelColorMixin.b;
					sUnitGlowColorArray[4] = tUnitDispelColorMixin.a or 1;

					return sUnitGlowColorArray;
				end
			end
		end

		tUnitDefaultGlow = VUHDO_PANEL_SETUP and VUHDO_PANEL_SETUP["BAR_COLORS"] and VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF_BAR_GLOW"];

		if tUnitDefaultGlow then
			sUnitGlowColorArray[1] = tUnitDefaultGlow["R"];
			sUnitGlowColorArray[2] = tUnitDefaultGlow["G"];
			sUnitGlowColorArray[3] = tUnitDefaultGlow["B"];
			sUnitGlowColorArray[4] = tUnitDefaultGlow["O"] or 1;

			return sUnitGlowColorArray;
		end

		return nil;
	end

	tUnitGlowColor = aGlowMeta["glowColor"];

	if tUnitGlowColor and tUnitGlowColor["R"] then
		sUnitGlowColorArray[1] = tUnitGlowColor["R"];
		sUnitGlowColorArray[2] = tUnitGlowColor["G"];
		sUnitGlowColorArray[3] = tUnitGlowColor["B"];
		sUnitGlowColorArray[4] = tUnitGlowColor["O"] or 1;
	else
		tUnitDefaultGlow = VUHDO_PANEL_SETUP and VUHDO_PANEL_SETUP["BAR_COLORS"] and VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF_BAR_GLOW"];

		if tUnitDefaultGlow then
			sUnitGlowColorArray[1] = tUnitDefaultGlow["R"];
			sUnitGlowColorArray[2] = tUnitDefaultGlow["G"];
			sUnitGlowColorArray[3] = tUnitDefaultGlow["B"];
			sUnitGlowColorArray[4] = tUnitDefaultGlow["O"] or 1;
		else
			sUnitGlowColorArray[1] = 0.95;
			sUnitGlowColorArray[2] = 0.95;
			sUnitGlowColorArray[3] = 0.32;
			sUnitGlowColorArray[4] = 1;
		end
	end

	return sUnitGlowColorArray;

end



--
local tBarGlowEntry;
local tTexture;
local tCoreTexture;
local function VUHDO_applyDispelTintToAuraGroupBarGlowTextures(aAuraButton)

	tBarGlowEntry = aAuraButton["vuhdoAuraGroupBarGlow"];

	if not tBarGlowEntry or tBarGlowEntry["dispelTinted"] then
		return;
	end

	aAuraButton:ClearDispelTypeTextures();

	sAuraGroupBarGlowDispelOptions["customDispelColorCurve"] = nil;
	sAuraGroupBarGlowDispelOptions["customDispelColorMap"] = VUHDO_getDispelTypeColorMapOpaque(nil);

	tTexture = tBarGlowEntry["body"];

	if tTexture then
		aAuraButton:AddDispelTypeTexture(tTexture, sAuraGroupBarGlowDispelOptions);
	end

	tCoreTexture = tBarGlowEntry["core"];

	if tCoreTexture then
		aAuraButton:AddDispelTypeTexture(tCoreTexture, sAuraGroupBarGlowDispelOptions);
	end

	tBarGlowEntry["dispelTinted"] = true;

	return;

end



--
local tUnitButton;
local tUnitGlowStyle;
local tUnitGlowColorType;
local tUnitGlowMetaColor;
local tUnitDefaultGlow;
local tBarGlowEntry;
function VUHDO_applyAuraGroupBarGlowFromAuraButton(aAuraButton, anButtonSetup)

	if not aAuraButton or not anButtonSetup or not anButtonSetup["auraGroupBarGlow"] then
		return;
	end

	tUnitButton = anButtonSetup["unitButton"];

	if not tUnitButton then
		return;
	end

	tUnitGlowStyle = anButtonSetup["glowStyle"] or VUHDO_DEFAULT_AURA_GLOW_STYLE;
	tUnitGlowColorType = anButtonSetup["glowColorType"];

	if tUnitGlowColorType == VUHDO_AURA_GROUP_COLOR_DISPEL or tUnitGlowColorType == VUHDO_AURA_GROUP_COLOR_ALL_DISPEL then
		if tUnitButton["hasAuraGroupBarGlow"] then
			VUHDO_stopUnitButtonAuraGroupGlow(tUnitButton, VUHDO_CUSTOM_GLOW_AURA_GROUP_KEY);
		end

		tBarGlowEntry = aAuraButton["vuhdoAuraGroupBarGlow"];

		if tBarGlowEntry and tBarGlowEntry["style"] == tUnitGlowStyle then
			if not tBarGlowEntry["dispelTinted"] or aAuraButton:GetDispelTypeTextureCount() == 0 then
				tBarGlowEntry["dispelTinted"] = false;

				VUHDO_applyDispelTintToAuraGroupBarGlowTextures(aAuraButton);
			end

			tUnitButton[VUHDO_AURA_GROUP_GLOW_ACTIVE_KEY] = true;
			aAuraButton["vuhdoAuraGroupBarGlowActive"] = true;

			return;
		end

		VUHDO_startAuraButtonAuraGroupBarGlow(aAuraButton, anButtonSetup, tUnitGlowStyle, 1, 1, 1, 1);

		VUHDO_applyDispelTintToAuraGroupBarGlowTextures(aAuraButton);
	else
		if tUnitButton["hasAuraGroupBarGlow"] then
			VUHDO_stopUnitButtonAuraGroupGlow(tUnitButton, VUHDO_CUSTOM_GLOW_AURA_GROUP_KEY);
		end

		tBarGlowEntry = aAuraButton["vuhdoAuraGroupBarGlow"];

		if tBarGlowEntry and tBarGlowEntry["style"] == tUnitGlowStyle then
			tUnitButton[VUHDO_AURA_GROUP_GLOW_ACTIVE_KEY] = true;
			aAuraButton["vuhdoAuraGroupBarGlowActive"] = true;

			return;
		end

		tUnitGlowMetaColor = anButtonSetup["glowColor"];

		if tUnitGlowMetaColor and tUnitGlowMetaColor["R"] then
			sUnitGlowColorArray[1] = tUnitGlowMetaColor["R"];
			sUnitGlowColorArray[2] = tUnitGlowMetaColor["G"];
			sUnitGlowColorArray[3] = tUnitGlowMetaColor["B"];
			sUnitGlowColorArray[4] = tUnitGlowMetaColor["O"] or 1;
		else
			tUnitDefaultGlow = VUHDO_PANEL_SETUP and VUHDO_PANEL_SETUP["BAR_COLORS"] and VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF_BAR_GLOW"];

			if tUnitDefaultGlow then
				sUnitGlowColorArray[1] = tUnitDefaultGlow["R"];
				sUnitGlowColorArray[2] = tUnitDefaultGlow["G"];
				sUnitGlowColorArray[3] = tUnitDefaultGlow["B"];
				sUnitGlowColorArray[4] = tUnitDefaultGlow["O"] or 1;
			else
				sUnitGlowColorArray[1] = 0.95;
				sUnitGlowColorArray[2] = 0.95;
				sUnitGlowColorArray[3] = 0.32;
				sUnitGlowColorArray[4] = 1;
			end
		end

		VUHDO_startAuraButtonAuraGroupBarGlow(aAuraButton, anButtonSetup, tUnitGlowStyle, sUnitGlowColorArray[1], sUnitGlowColorArray[2], sUnitGlowColorArray[3], sUnitGlowColorArray[4]);
	end

	tUnitButton[VUHDO_AURA_GROUP_GLOW_ACTIVE_KEY] = true;
	aAuraButton["vuhdoAuraGroupBarGlowActive"] = true;

	return;

end



--
local tUnitButton;
function VUHDO_clearAuraGroupBarGlowFromAuraButton(aAuraButton, anButtonSetup)

	if not anButtonSetup or not anButtonSetup["auraGroupBarGlow"] then
		return;
	end

	tUnitButton = anButtonSetup["unitButton"];

	if not tUnitButton then
		return;
	end

	if tUnitButton["hasAuraGroupBarGlow"] then
		VUHDO_stopUnitButtonAuraGroupGlow(tUnitButton, VUHDO_CUSTOM_GLOW_AURA_GROUP_KEY);
	end

	if aAuraButton then
		aAuraButton["vuhdoAuraGroupBarGlowActive"] = nil;
	end

	return;

end