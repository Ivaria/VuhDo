-- BURST CACHE ---------------------------------------------------
local VUHDO_PANEL_SETUP;
local VUHDO_getHeaderWidthHor;
local VUHDO_getHeaderWidthVer;
local VUHDO_getHeaderHeightHor;
local VUHDO_getHeaderHeightVer;
local VUHDO_getHeaderPosHor;
local VUHDO_getHeaderPosVer;
local VUHDO_getHealButtonPosHor;
local VUHDO_getHealButtonPosVer;
local VUHDO_strempty;
local VUHDO_roundToPixel;

function VUHDO_sizeCalculatorInitLocalOverrides()
	VUHDO_PANEL_SETUP = _G["VUHDO_PANEL_SETUP"];
	VUHDO_sizeCalculatorInitLocalOverridesHor();
	VUHDO_sizeCalculatorInitLocalOverridesVer();

	VUHDO_getHeaderWidthHor = _G["VUHDO_getHeaderWidthHor"];
	VUHDO_getHeaderWidthVer = _G["VUHDO_getHeaderWidthVer"];
	VUHDO_getHeaderHeightHor = _G["VUHDO_getHeaderHeightHor"];
	VUHDO_getHeaderHeightVer = _G["VUHDO_getHeaderHeightVer"];
	VUHDO_getHeaderPosHor = _G["VUHDO_getHeaderPosHor"];
	VUHDO_getHeaderPosVer = _G["VUHDO_getHeaderPosVer"];
	VUHDO_getHealButtonPosHor = _G["VUHDO_getHealButtonPosHor"];
	VUHDO_getHealButtonPosVer = _G["VUHDO_getHealButtonPosVer"];
	VUHDO_strempty = _G["VUHDO_strempty"];
	VUHDO_roundToPixel = _G["VUHDO_roundToPixel"];
end

-- BURST CACHE ---------------------------------------------------


local sHealButtonWidthCache = { };
local sTopHeightCache = { };
local sBottomHeightCache = { };


function VUHDO_resetSizeCalcCaches()
	table.wipe(sHealButtonWidthCache);
	table.wipe(sTopHeightCache);
	table.wipe(sBottomHeightCache);
	VUHDO_resetSizeCalcCachesHor();
	VUHDO_resetSizeCalcCachesVer();
end



--
local tBarScaling;
local tValue;
function VUHDO_getPixelPerfectSpacing(aPanelNum, aSpacingType)

	tBarScaling = VUHDO_PANEL_SETUP[aPanelNum]["SCALING"];
	tValue = tBarScaling[aSpacingType] or 0;

	return math.floor(tValue + 0.5);

end



--
local tBarScaling;
local tValue;
function VUHDO_getPixelPerfectGap(aPanelNum, aGapType)

	tBarScaling = VUHDO_PANEL_SETUP[aPanelNum]["SCALING"];
	tValue = tBarScaling[aGapType] or 0;

	return math.floor(tValue + 0.5);

end



--
local tBorder;
local tValue;
function VUHDO_getPixelPerfectBorderEdgeSize(aPanelNum)

	tBorder = VUHDO_PANEL_SETUP[aPanelNum]["PANEL_COLOR"]["BORDER"];
	tValue = tBorder["edgeSize"] or 0;

	return math.floor(tValue + 0.5);

end



--
local tBorder;
local tValue;
function VUHDO_getPixelPerfectBorderInsets(aPanelNum)

	tBorder = VUHDO_PANEL_SETUP[aPanelNum]["PANEL_COLOR"]["BORDER"];
	tValue = tBorder["insets"] or 0;

	return math.floor(tValue + 0.5);

end



-- Returns the total height of optional threat bars
local tTopSpace;
local tNamePos;
local tNameHeight;
function VUHDO_getAdditionalTopHeight(aPanelNum)

	if not sTopHeightCache[aPanelNum] then
		tTopSpace = 0;

		if VUHDO_INDICATOR_CONFIG[aPanelNum]["BOUQUETS"]["THREAT_BAR"] ~= "" then
			tTopSpace = VUHDO_INDICATOR_CONFIG[aPanelNum]["CUSTOM"]["THREAT_BAR"]["HEIGHT"];
		end

		tNamePos = VUHDO_splitString(VUHDO_PANEL_SETUP[aPanelNum]["ID_TEXT"]["position"], "+");

		if strfind(tNamePos[1], "BOTTOM", 1, true) and strfind(tNamePos[2], "TOP", 1, true) then
			tNameHeight = VUHDO_PANEL_SETUP[aPanelNum]["ID_TEXT"]["_spacing"];

			if tNameHeight and tNameHeight > tTopSpace then
				tTopSpace = tNameHeight;
			end
		end
		sTopHeightCache[aPanelNum] = tTopSpace;
	end

	return sTopHeightCache[aPanelNum];

end



--
local tHotCfg;
local tBottomSpace;
local tNamePos;
local tNameHeight;
function VUHDO_getAdditionalBottomHeight(aPanelNum)

	if not sBottomHeightCache[aPanelNum] then
		-- HoT icons
		tHotCfg = VUHDO_PANEL_SETUP[aPanelNum]["HOTS"];
		tBottomSpace = 0;

		if tHotCfg["radioValue"] == 7 or tHotCfg["radioValue"] == 8 then
			tBottomSpace = VUHDO_PANEL_SETUP[aPanelNum]["SCALING"]["barHeight"] * VUHDO_PANEL_SETUP[aPanelNum]["HOTS"]["size"] * 0.01;
		end

		tNamePos = VUHDO_splitString(VUHDO_PANEL_SETUP[aPanelNum]["ID_TEXT"]["position"], "+");
		if strfind(tNamePos[1], "TOP", 1, true) and strfind(tNamePos[2], "BOTTOM", 1, true) then
			tNameHeight = VUHDO_PANEL_SETUP[aPanelNum]["ID_TEXT"]["_spacing"];
			if tNameHeight and tNameHeight > tBottomSpace then
				tBottomSpace = tNameHeight;
			end
		end

		sBottomHeightCache[aPanelNum] = tBottomSpace;
	end

	return sBottomHeightCache[aPanelNum];

end



--
local tBarScaling;
local tTargetWidth;
local function VUHDO_getTargetBarWidth(aPanelNum)

	tBarScaling = VUHDO_PANEL_SETUP[aPanelNum]["SCALING"];

	tTargetWidth = 0;
	if tBarScaling["showTarget"] then
		tTargetWidth = tTargetWidth + tBarScaling["targetSpacing"] + tBarScaling["targetWidth"];
	end

	if tBarScaling["showTot"] then
		tTargetWidth = tTargetWidth + tBarScaling["totSpacing"] + tBarScaling["totWidth"];
	end

	return tTargetWidth;

end



--
local tCnt;
function VUHDO_getNumHotSlots(aPanelNum)

	if not VUHDO_strempty(VUHDO_PANEL_SETUP[aPanelNum]["HOTS"]["SLOTS"][12]) then
		return 9;
	elseif not VUHDO_strempty(VUHDO_PANEL_SETUP[aPanelNum]["HOTS"]["SLOTS"][11]) then
		return 8;
	elseif not VUHDO_strempty(VUHDO_PANEL_SETUP[aPanelNum]["HOTS"]["SLOTS"][10]) then
		return 7;
	elseif not VUHDO_strempty(VUHDO_PANEL_SETUP[aPanelNum]["HOTS"]["SLOTS"][9]) then
		return 6;
	else
		for tCnt = 5, 1, -1 do
			if not VUHDO_strempty(VUHDO_PANEL_SETUP[aPanelNum]["HOTS"]["SLOTS"][tCnt]) then
				return tCnt;
			end
		end

		return 0;
	end

end
local VUHDO_getNumHotSlots = VUHDO_getNumHotSlots;



--
local tHotCfg;
local function VUHDO_getHotIconWidth(aPanelNum)

	tHotCfg = VUHDO_PANEL_SETUP[aPanelNum]["HOTS"];

	if tHotCfg["radioValue"] == 1 or tHotCfg["radioValue"] == 4 then
		return VUHDO_PANEL_SETUP[aPanelNum]["SCALING"]["barHeight"]
			* VUHDO_PANEL_SETUP[aPanelNum]["HOTS"]["size"]
			* VUHDO_getNumHotSlots(aPanelNum) * 0.01;
	else
		return 0;
	end

end



--
function VUHDO_getHealButtonWidth(aPanelNum)
	if not sHealButtonWidthCache[aPanelNum] then
		sHealButtonWidthCache[aPanelNum] =
			VUHDO_PANEL_SETUP[aPanelNum]["SCALING"]["barWidth"]
			+ VUHDO_getTargetBarWidth(aPanelNum)
			+ VUHDO_getHotIconWidth(aPanelNum);
	end
	return sHealButtonWidthCache[aPanelNum];
end



--
local function VUHDO_isPanelHorizontal(aPanelNum)
	return VUHDO_PANEL_SETUP[aPanelNum]["SCALING"]["arrangeHorizontal"]
		and (not VUHDO_IS_PANEL_CONFIG or VUHDO_CONFIG_SHOW_RAID);
end



-- Returns total header width
function VUHDO_getHeaderWidth(aPanelNum)
	return VUHDO_isPanelHorizontal(aPanelNum)
		and VUHDO_getHeaderWidthHor(aPanelNum) or VUHDO_getHeaderWidthVer(aPanelNum);
end



-- Returns total header height
function VUHDO_getHeaderHeight(aPanelNum)
	return VUHDO_isPanelHorizontal(aPanelNum)
		and VUHDO_getHeaderHeightHor(aPanelNum) or VUHDO_getHeaderHeightVer(aPanelNum);
end



--
function VUHDO_getHeaderPos(aHeaderPlace, aPanelNum)
	if VUHDO_isPanelHorizontal(aPanelNum) then
		return VUHDO_getHeaderPosHor(aHeaderPlace, aPanelNum);
	else
		return VUHDO_getHeaderPosVer(aHeaderPlace, aPanelNum);
	end
end



--
function VUHDO_getHealButtonPos(aPlaceNum, aRowNo, aPanelNum)
	-- Achtung: Positionen nicht cachen, da z.T. von dynamischen Models abh�ngig
	if VUHDO_isPanelHorizontal(aPanelNum) then
		return VUHDO_getHealButtonPosHor(aPlaceNum, aRowNo, aPanelNum);
	else
		return VUHDO_getHealButtonPosVer(aPlaceNum, aRowNo, aPanelNum);
	end
end



--
function VUHDO_getHealPanelWidth(aPanelNum)
	return VUHDO_isPanelHorizontal(aPanelNum)
		and VUHDO_getHealPanelWidthHor(aPanelNum) or VUHDO_getHealPanelWidthVer(aPanelNum);
end



--
local tHeight;
function VUHDO_getHealPanelHeight(aPanelNum)
	tHeight = VUHDO_isPanelHorizontal(aPanelNum)
		and VUHDO_getHealPanelHeightHor(aPanelNum) or VUHDO_getHealPanelHeightVer(aPanelNum);
	return tHeight >= 20 and tHeight or 20;
end
