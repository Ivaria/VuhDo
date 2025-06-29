local _;

local floor = math.floor;
local pairs = pairs;
local type = type;
local string = string;
local format = string.format;
local ipairs = ipairs;
local tinsert = table.insert;


local tPixelUtil = { };
local sPixelScale;
local sUIScale;
local sLastKnownScale = nil;



--
function VUHDO_getPixelScale()

	if not sPixelScale then
		sPixelScale = UIParent:GetEffectiveScale();
	end

	return sPixelScale;

end



--
function VUHDO_getUIScale()

	if not sUIScale then
		sUIScale = UIParent:GetScale();
	end

	return sUIScale;

end



--
local tScale;
function VUHDO_roundToPixel(aValue)

	tScale = VUHDO_getPixelScale();

	return floor(aValue * tScale + 0.5) / tScale;

end



--
function VUHDO_refreshPixelScale()

	sPixelScale = nil;
	sUIScale = nil;

	return;

end



--
function VUHDO_initScaleMonitoring()

	if VUHDO_CONFIG and VUHDO_CONFIG["PIXEL_PERFECT"] and VUHDO_CONFIG["PIXEL_PERFECT"]["enabled"] then
		sLastKnownScale = UIParent:GetEffectiveScale();

		if VUHDO_CONFIG["PIXEL_PERFECT"]["logScaleChanges"] then
			VUHDO_Msg("Pixel-perfect scale monitoring initialized. Current scale: " .. sLastKnownScale);
		end
	end

	return;

end



--
local tCurrentScale;
local tOldScale;
local tDelay;
function VUHDO_handleScaleChange()

	tCurrentScale = UIParent:GetEffectiveScale();
	tOldScale = sLastKnownScale;

	VUHDO_refreshPixelScale();

	if VUHDO_CONFIG and VUHDO_CONFIG["PIXEL_PERFECT"] and VUHDO_CONFIG["PIXEL_PERFECT"]["redrawOnScaleChange"] then
		if not InCombatLockdown() then
			tDelay = VUHDO_CONFIG["PIXEL_PERFECT"]["scaleChangeDelay"] or 0.1;
			for tPanelNum = 1, 10 do
				VUHDO_timeRedrawPanel(tPanelNum, tDelay);
			end
		end
	end

	sLastKnownScale = tCurrentScale;

	return;

end



--
local tX;
local tY;
function tPixelUtil.SetPoint(aFrame, aPoint, aRelativeFrame, aRelativePoint, aXOffset, aYOffset)

	if not aFrame then
		return;
	end

	tX = aXOffset and VUHDO_roundToPixel(aXOffset) or 0;
	tY = aYOffset and VUHDO_roundToPixel(aYOffset) or 0;

	aFrame:SetPoint(aPoint, aRelativeFrame, aRelativePoint, tX, tY);

	return;

end



--
local tWidth;
local tHeight;
function tPixelUtil.SetSize(aFrame, aWidth, aHeight)

	if not aFrame then
		return;
	end

	tWidth = aWidth and VUHDO_roundToPixel(aWidth) or aFrame:GetWidth();
	tHeight = aHeight and VUHDO_roundToPixel(aHeight) or aFrame:GetHeight();

	aFrame:SetSize(tWidth, tHeight);

	return;

end



--
local tWidth;
function tPixelUtil.SetWidth(aFrame, aWidth)

	if not aFrame then
		return;
	end

	tWidth = aWidth and VUHDO_roundToPixel(aWidth) or aFrame:GetWidth();

	aFrame:SetWidth(tWidth);

	return;

end



--
local tHeight;
function tPixelUtil.SetHeight(aFrame, aHeight)

	if not aFrame then
		return;
	end

	tHeight = aHeight and VUHDO_roundToPixel(aHeight) or aFrame:GetHeight();

	aFrame:SetHeight(tHeight);

	return;

end



--
function tPixelUtil.ApplySettings(aTexture)

	if not aTexture then
		return;
	end

	aTexture:SetTexelSnappingBias(0);
	aTexture:SetSnapToPixelGrid(false);

	return;

end



--
local tBackdropCache = { };
local tInsetsCache = { };
local tValueLeft, tValueRight, tValueTop, tValueBottom;
local tLeftFloor, tRightFloor, tTopFloor, tBottomFloor;
function tPixelUtil.ApplyBackdrop(aFrame, aBackdropInfo)

	if not aFrame or not aFrame.SetBackdrop then
		return;
	end

	if aBackdropInfo then
		for tKey in pairs(tBackdropCache) do
			tBackdropCache[tKey] = nil;
		end

		for tKey, tValue in pairs(aBackdropInfo) do
			if tKey == "edgeSize" then
				if tValue == floor(tValue) then
					tBackdropCache[tKey] = tValue;
				else
					tBackdropCache[tKey] = VUHDO_roundToPixel(tValue);
				end
			elseif tKey == "insets" and type(tValue) == "table" then
				for tKey in pairs(tInsetsCache) do
					tInsetsCache[tKey] = nil;
				end

				tValueLeft = tValue["left"] or 0;
				tValueRight = tValue["right"] or 0;
				tValueTop = tValue["top"] or 0;
				tValueBottom = tValue["bottom"] or 0;

				tLeftFloor = floor(tValueLeft);
				tRightFloor = floor(tValueRight);
				tTopFloor = floor(tValueTop);
				tBottomFloor = floor(tValueBottom);

				tInsetsCache["left"] = tValueLeft == tLeftFloor and tValueLeft or VUHDO_roundToPixel(tValueLeft);
				tInsetsCache["right"] = tValueRight == tRightFloor and tValueRight or VUHDO_roundToPixel(tValueRight);
				tInsetsCache["top"] = tValueTop == tTopFloor and tValueTop or VUHDO_roundToPixel(tValueTop);
				tInsetsCache["bottom"] = tValueBottom == tBottomFloor and tValueBottom or VUHDO_roundToPixel(tValueBottom);

				tBackdropCache[tKey] = tInsetsCache;
			else
				tBackdropCache[tKey] = tValue;
			end
		end

		aFrame:SetBackdrop(tBackdropCache);
	end

	return;

end



--
local tNumFrames;
local tFrameSize;
local tSpacing;
local tTestFrames = { };
local tXOffset;
function VUHDO_testPixelPerfect()

	VUHDO_Msg("|cffFFD100--- Pixel-Perfect Testing ---|r");

	VUHDO_Msg("|cffFFA500** Current Settings:|r");
	VUHDO_Msg("  |cffB0E0E6UI Scale:|r " .. (UIParent:GetScale() or 1));
	VUHDO_Msg("  |cffB0E0E6Pixel Scale:|r " .. VUHDO_getPixelScale());

	VUHDO_Msg("|cffFFA500** Refresh Test:|r");
	VUHDO_Msg("  Refreshing pixel scale...");
	VUHDO_refreshPixelScale();
	VUHDO_Msg("  |cffB0E0E6New Pixel Scale:|r " .. VUHDO_getPixelScale());

	VUHDO_Msg("|cffFFA500** Visual Test Frames:|r");
	VUHDO_Msg("  Creating pixel-perfect test frames...");

	tNumFrames = 5;
	tFrameSize = 96;
	tSpacing = 2;

	for tIndex = 1, tNumFrames do
		if not tTestFrames[tIndex] then
			tTestFrames[tIndex] = CreateFrame("Frame", "VuhDoPixelTestFrame" .. tIndex, UIParent, "BackdropTemplate");

			tTestFrames[tIndex]:SetFrameStrata("HIGH");
			tTestFrames[tIndex]:SetMovable(true);
			tTestFrames[tIndex]:EnableMouse(true);
			tTestFrames[tIndex]:RegisterForDrag("LeftButton");

			tTestFrames[tIndex]:SetScript("OnDragStart", tTestFrames[tIndex].StartMoving);
			tTestFrames[tIndex]:SetScript("OnDragStop", tTestFrames[tIndex].StopMovingOrSizing);
		end

		tXOffset = (tIndex - 1) * (tFrameSize + tSpacing);

		VUHDO_PixelUtil.SetPoint(tTestFrames[tIndex], "CENTER", UIParent, "CENTER", tXOffset - ((tNumFrames - 1) * (tFrameSize + tSpacing)) / 2, 0);
		VUHDO_PixelUtil.SetSize(tTestFrames[tIndex], tFrameSize, tFrameSize);

		VUHDO_PixelUtil.ApplyBackdrop(tTestFrames[tIndex], {
			["bgFile"] = "Interface\\Buttons\\WHITE8x8",
			["edgeFile"] = "Interface\\Buttons\\WHITE8x8",
			["tile"] = true,
			["tileSize"] = 8,
			["edgeSize"] = 2,
			["insets"] = { ["left"] = 0, ["right"] = 0, ["top"] = 0, ["bottom"] = 0 }
		});

		tTestFrames[tIndex]:SetBackdropColor(0, 0, 0, 1); -- black background
		tTestFrames[tIndex]:SetBackdropBorderColor(0.5, 0.5, 0.5, 1); -- grey border

		tTestFrames[tIndex]:Show();
	end

	VUHDO_Msg("  Test frames created. Check for consistent spacing and pixel alignment.");
	VUHDO_Msg("  Use '/vd pixel hide' to remove test frames.");

	return;

end



--
local tScaling;
local tBorder;
local tRowSpacing;
local tColumnSpacing;
local tBorderGapX;
local tBorderGapY;
local tHeaderSpacing;
local tNonIntegerValues = { };
function VUHDO_testPixelPerfectSpacing()

	VUHDO_Msg("|cffFFD100--- Pixel-Perfect Spacing Test ---|r");

	if not VUHDO_PANEL_SETUP then
		VUHDO_Msg("|cffFF4444Error:|r Panel setup not loaded.");

		return;
	end

	for tPanelNum = 1, VUHDO_MAX_PANELS do
		if VUHDO_PANEL_SETUP[tPanelNum] then
			tScaling = VUHDO_PANEL_SETUP[tPanelNum]["SCALING"];
			tBorder = VUHDO_PANEL_SETUP[tPanelNum]["PANEL_COLOR"]["BORDER"];

			VUHDO_Msg("|cffFFA500** Panel " .. tPanelNum .. ":**|r");

			tRowSpacing = tScaling["rowSpacing"] or 0;
			tColumnSpacing = tScaling["columnSpacing"] or 0;
			tBorderGapX = tScaling["borderGapX"] or 0;
			tBorderGapY = tScaling["borderGapY"] or 0;
			tHeaderSpacing = tScaling["headerSpacing"] or 0;

			VUHDO_Msg("  |cffB0E0E6Spacing Values:|r");
			VUHDO_Msg("    Row Spacing: " .. tRowSpacing .. " (used: " .. VUHDO_getPixelPerfectSpacing(tPanelNum, "rowSpacing") .. ")");
			VUHDO_Msg("    Column Spacing: " .. tColumnSpacing .. " (used: " .. VUHDO_getPixelPerfectSpacing(tPanelNum, "columnSpacing") .. ")");
			VUHDO_Msg("    Border Gap X: " .. tBorderGapX .. " (used: " .. VUHDO_getPixelPerfectGap(tPanelNum, "borderGapX") .. ")");
			VUHDO_Msg("    Border Gap Y: " .. tBorderGapY .. " (used: " .. VUHDO_getPixelPerfectGap(tPanelNum, "borderGapY") .. ")");
			VUHDO_Msg("    Header Spacing: " .. tHeaderSpacing .. " (used: " .. VUHDO_getPixelPerfectSpacing(tPanelNum, "headerSpacing") .. ")");

			VUHDO_Msg("  |cffB0E0E6Border Values:|r");
			VUHDO_Msg("    Edge Size: " .. (tBorder["edgeSize"] or 0) .. " (used: " .. VUHDO_getPixelPerfectBorderEdgeSize(tPanelNum) .. ")");
			VUHDO_Msg("    Insets: " .. (tBorder["insets"] or 0) .. " (used: " .. VUHDO_getPixelPerfectBorderInsets(tPanelNum) .. ")");
			VUHDO_Msg("    Color: R=" .. (tBorder["R"] or 0) .. " G=" .. (tBorder["G"] or 0) .. " B=" .. (tBorder["B"] or 0) .. " A=" .. (tBorder["O"] or 0));

			for tKey, _ in pairs(tNonIntegerValues) do
				tNonIntegerValues[tKey] = nil;
			end

			if tRowSpacing ~= floor(tRowSpacing) then
				tinsert(tNonIntegerValues, "rowSpacing");
			end
			if tColumnSpacing ~= floor(tColumnSpacing) then
				tinsert(tNonIntegerValues, "columnSpacing");
			end
			if tBorderGapX ~= floor(tBorderGapX) then
				tinsert(tNonIntegerValues, "borderGapX");
			end
			if tBorderGapY ~= floor(tBorderGapY) then
				tinsert(tNonIntegerValues, "borderGapY");
			end
			if tHeaderSpacing ~= floor(tHeaderSpacing) then
				tinsert(tNonIntegerValues, "headerSpacing");
			end

			if #tNonIntegerValues > 0 then
				VUHDO_Msg("  |cffFF4444[!] Warning:|r Non-integer values found: " .. table.concat(tNonIntegerValues, ", "));
			else
				VUHDO_Msg("  |cff44FF44[OK]|r All spacing values are integers.");
			end
		end
	end

	return;

end



--
local tVisibleCount;
function VUHDO_hidePixelTestFrame()

	tVisibleCount = 0;

	for _, tFrame in pairs(tTestFrames) do
		if tFrame and tFrame:IsShown() then
			tFrame:Hide();

			tVisibleCount = tVisibleCount + 1;
		end
	end

	if tVisibleCount > 0 then
		VUHDO_Msg("|cffFFD100--- Pixel Test Frames Hidden ---|r");
		VUHDO_Msg("  |cffB0E0E6Action:|r " .. tVisibleCount .. " test frames have been hidden");
		VUHDO_Msg("  |cffB0E0E6Note:|r Use '/vd pixel test' to show them again");
		VUHDO_Msg("|cffFFD100--- End of Pixel Test Frames ---|r");
	else
		VUHDO_Msg("|cffFFD100--- Pixel Test Frames ---|r");
		VUHDO_Msg("  |cffB0E0E6Status:|r No test frames are currently visible");
		VUHDO_Msg("|cffFFD100--- End of Pixel Test Frames ---|r");
	end

	return;

end



--
local tTestValues;
local tRounded;
function VUHDO_testPixelPerfectValues()

	VUHDO_Msg("|cffFFD100--- Pixel-Perfect Value Test ---|r");

	VUHDO_Msg("|cffFFA500** Rounding Test Values:|r");
	VUHDO_Msg("  |cffB0E0E6Format:|r Original -> Rounded");

	tTestValues = {0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0};

	for _, tValue in ipairs(tTestValues) do
		tRounded = VUHDO_roundToPixel(tValue);

		VUHDO_Msg(format("  %.2f -> %.2f", tValue, tRounded));
	end

	VUHDO_Msg("|cffFFD100--- End of Pixel-Perfect Value Test ---|r");

	return;

end



--
local tInitialScale;
function VUHDO_testScaleChangeHandling()

	VUHDO_Msg("|cffFFD100--- Scale Change Handling Test ---|r");

	tInitialScale = VUHDO_getPixelScale();

	VUHDO_Msg("Initial scale: " .. tInitialScale);

	VUHDO_Msg("Testing scale change handler...");

	VUHDO_handleScaleChange();

	VUHDO_Msg("|cff44FF44[OK]|r Scale change task enqueued successfully");
	VUHDO_Msg("|cffFFD100--- End of Scale Change Test ---|r");

	return;

end



VUHDO_PixelUtil = tPixelUtil;
