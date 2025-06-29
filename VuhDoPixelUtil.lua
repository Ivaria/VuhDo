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
local tScale;
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
function tPixelUtil.ApplySettings(aTexture, anIsEnabled)

	if not aTexture then
		return;
	end

	if anIsEnabled then
		aTexture:SetTexelSnappingBias(0);
		aTexture:SetSnapToPixelGrid(false);
	else
		aTexture:SetTexelSnappingBias(0);
		aTexture:SetSnapToPixelGrid(false);
	end

	return;

end



--
local tBackdrop;
function tPixelUtil.ApplyBackdrop(aFrame, aBackdropInfo)

	if not aFrame or not aFrame.SetBackdrop then
		return;
	end

	if aBackdropInfo then
		tBackdrop = { };

		-- Copy backdrop info
		for tKey, tValue in pairs(aBackdropInfo) do
			if tKey == "edgeSize" then
				tBackdrop[tKey] = VUHDO_roundToPixel(tValue);
			elseif tKey == "insets" and type(tValue) == "table" then
				tBackdrop[tKey] = {
					left = VUHDO_roundToPixel(tValue.left or 0),
					right = VUHDO_roundToPixel(tValue.right or 0),
					top = VUHDO_roundToPixel(tValue.top or 0),
					bottom = VUHDO_roundToPixel(tValue.bottom or 0),
				};
			else
				tBackdrop[tKey] = tValue;
			end
		end

		aFrame:SetBackdrop(tBackdrop);
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
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			tile = true,
			tileSize = 8,
			edgeSize = 2,
			insets = { left = 0, right = 0, top = 0, bottom = 0 }
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
local tNonIntegerValues;
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
			VUHDO_Msg("    Row Spacing: " .. tRowSpacing .. " (rounded: " .. VUHDO_roundToPixel(tRowSpacing) .. ")");
			VUHDO_Msg("    Column Spacing: " .. tColumnSpacing .. " (rounded: " .. VUHDO_roundToPixel(tColumnSpacing) .. ")");
			VUHDO_Msg("    Border Gap X: " .. tBorderGapX .. " (rounded: " .. VUHDO_roundToPixel(tBorderGapX) .. ")");
			VUHDO_Msg("    Border Gap Y: " .. tBorderGapY .. " (rounded: " .. VUHDO_roundToPixel(tBorderGapY) .. ")");
			VUHDO_Msg("    Header Spacing: " .. tHeaderSpacing .. " (rounded: " .. VUHDO_roundToPixel(tHeaderSpacing) .. ")");

			VUHDO_Msg("  |cffB0E0E6Border Values:|r");
			VUHDO_Msg("    Edge Size: " .. (tBorder["edgeSize"] or 0) .. " (rounded: " .. VUHDO_roundToPixel(tBorder["edgeSize"] or 0) .. ")");
			VUHDO_Msg("    Insets: " .. (tBorder["insets"] or 0) .. " (rounded: " .. VUHDO_roundToPixel(tBorder["insets"] or 0) .. ")");
			VUHDO_Msg("    Color: R=" .. (tBorder["R"] or 0) .. " G=" .. (tBorder["G"] or 0) .. " B=" .. (tBorder["B"] or 0) .. " A=" .. (tBorder["O"] or 0));

			tNonIntegerValues = {};
			if tRowSpacing ~= math.floor(tRowSpacing) then tinsert(tNonIntegerValues, "rowSpacing"); end
			if tColumnSpacing ~= math.floor(tColumnSpacing) then tinsert(tNonIntegerValues, "columnSpacing"); end
			if tBorderGapX ~= math.floor(tBorderGapX) then tinsert(tNonIntegerValues, "borderGapX"); end
			if tBorderGapY ~= math.floor(tBorderGapY) then tinsert(tNonIntegerValues, "borderGapY"); end
			if tHeaderSpacing ~= math.floor(tHeaderSpacing) then tinsert(tNonIntegerValues, "headerSpacing"); end

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
local tChangedPanels;
local tScaling;
local tBorder;
local tPanelChanged;
local tOldRowSpacing;
local tNewRowSpacing;
local tOldColumnSpacing;
local tNewColumnSpacing;
local tOldBorderGapX;
local tNewBorderGapX;
local tOldBorderGapY;
local tNewBorderGapY;
local tOldHeaderSpacing;
local tNewHeaderSpacing;
local tOldEdgeSize;
local tNewEdgeSize;
local tOldInsets;
local tNewInsets;
function VUHDO_enforceIntegerSpacing()

	VUHDO_Msg("|cffFFD100--- Enforcing Integer Spacing ---|r");

	if not VUHDO_PANEL_SETUP then
		VUHDO_Msg("|cffFF4444Error:|r Panel setup not loaded.");
		return;
	end

	tChangedPanels = 0;

	for tPanelNum = 1, VUHDO_MAX_PANELS do
		if VUHDO_PANEL_SETUP[tPanelNum] then
			tScaling = VUHDO_PANEL_SETUP[tPanelNum]["SCALING"];
			tBorder = VUHDO_PANEL_SETUP[tPanelNum]["PANEL_COLOR"]["BORDER"];
			tPanelChanged = false;

			tOldRowSpacing = tScaling["rowSpacing"];
			tNewRowSpacing = math.floor(tOldRowSpacing + 0.5);
			if tOldRowSpacing ~= tNewRowSpacing then
				tScaling["rowSpacing"] = tNewRowSpacing;
				tPanelChanged = true;
			end

			tOldColumnSpacing = tScaling["columnSpacing"];
			tNewColumnSpacing = math.floor(tOldColumnSpacing + 0.5);
			if tOldColumnSpacing ~= tNewColumnSpacing then
				tScaling["columnSpacing"] = tNewColumnSpacing;
				tPanelChanged = true;
			end

			tOldBorderGapX = tScaling["borderGapX"];
			tNewBorderGapX = math.floor(tOldBorderGapX + 0.5);
			if tOldBorderGapX ~= tNewBorderGapX then
				tScaling["borderGapX"] = tNewBorderGapX;
				tPanelChanged = true;
			end

			tOldBorderGapY = tScaling["borderGapY"];
			tNewBorderGapY = math.floor(tOldBorderGapY + 0.5);
			if tOldBorderGapY ~= tNewBorderGapY then
				tScaling["borderGapY"] = tNewBorderGapY;
				tPanelChanged = true;
			end

			tOldHeaderSpacing = tScaling["headerSpacing"];
			tNewHeaderSpacing = math.floor(tOldHeaderSpacing + 0.5);
			if tOldHeaderSpacing ~= tNewHeaderSpacing then
				tScaling["headerSpacing"] = tNewHeaderSpacing;
				tPanelChanged = true;
			end

			tOldEdgeSize = tBorder["edgeSize"];
			tNewEdgeSize = math.floor(tOldEdgeSize + 0.5);
			if tOldEdgeSize ~= tNewEdgeSize then
				tBorder["edgeSize"] = tNewEdgeSize;
				tPanelChanged = true;
			end

			tOldInsets = tBorder["insets"];
			tNewInsets = math.floor(tOldInsets + 0.5);
			if tOldInsets ~= tNewInsets then
				tBorder["insets"] = tNewInsets;
				tPanelChanged = true;
			end

			if tPanelChanged then
				tChangedPanels = tChangedPanels + 1;
				VUHDO_Msg("  Panel " .. tPanelNum .. " spacing values rounded to integers.");
			end
		end
	end

	if tChangedPanels > 0 then
		VUHDO_Msg("|cff44FF44[OK]|r " .. tChangedPanels .. " panel(s) updated with integer spacing values.");
	else
		VUHDO_Msg("|cff44FF44[OK]|r All spacing values are already integers.");
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

	VUHDO_Msg("[OK] Scale change task enqueued successfully");
	VUHDO_Msg("|cffFFD100--- End of Scale Change Test ---|r");

	return;

end



VUHDO_PixelUtil = tPixelUtil;
