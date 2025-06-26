local _;

local floor = math.floor;
local pairs = pairs;
local type = type;
local string = string;
local format = string.format;
local ipairs = ipairs;


local tPixelUtil = { };
local tPixelScale;
local tUIScale;


--
local tScale;
function VUHDO_getPixelScale()

	if not tPixelScale then
		tPixelScale = UIParent:GetEffectiveScale();
	end

	return tPixelScale;

end



--
function VUHDO_getUIScale()

	if not tUIScale then
		tUIScale = UIParent:GetScale();
	end

	return tUIScale;

end



--
function VUHDO_roundToPixel(aValue)

	tScale = VUHDO_getPixelScale();

	return floor(aValue * tScale + 0.5) / tScale;

end



--
local tScale;
function VUHDO_roundToPixelOffset(aValue)

	tScale = VUHDO_getPixelScale();

	return floor(aValue * tScale + 0.5) / tScale;

end



--
function VUHDO_refreshPixelScale()

	tPixelScale = nil;
	tUIScale = nil;

	return;

end



--
local tX;
local tY;
function tPixelUtil.SetPoint(aFrame, aPoint, aRelativeFrame, aRelativePoint, aXOffset, aYOffset)

	if not aFrame then
		return;
	end

	tX = aXOffset and VUHDO_roundToPixelOffset(aXOffset) or 0;
	tY = aYOffset and VUHDO_roundToPixelOffset(aYOffset) or 0;

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
function tPixelUtil.SetTexelSnappingBias(aTexture, aBias)

	if not aTexture then
		return;
	end

	aTexture:SetTexelSnappingBias(aBias or 0);

	return;

end



--
function tPixelUtil.SetSnapToPixelGrid(aTexture, anIsEnabled)

	if not aTexture then
		return;
	end

	aTexture:SetSnapToPixelGrid(anIsEnabled or false);

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
function tPixelUtil.SetBackdropEdgeSize(aFrame, anEdgeSize)

	if not aFrame or not aFrame.SetBackdrop then
		return;
	end

	tBackdrop = aFrame:GetBackdrop();

	if tBackdrop then
		tBackdrop.edgeSize = VUHDO_roundToPixel(anEdgeSize or 1);

		aFrame:SetBackdrop(tBackdrop);
	end

	return;

end



--
local tBackdrop;
function tPixelUtil.SetBackdropInsets(aFrame, aLeft, aRight, aTop, aBottom)

	if not aFrame or not aFrame.SetBackdrop then
		return;
	end

	tBackdrop = aFrame:GetBackdrop();

	if tBackdrop and tBackdrop.insets then
		tBackdrop.insets.left = VUHDO_roundToPixel(aLeft or 0);
		tBackdrop.insets.right = VUHDO_roundToPixel(aRight or 0);
		tBackdrop.insets.top = VUHDO_roundToPixel(aTop or 0);
		tBackdrop.insets.bottom = VUHDO_roundToPixel(aBottom or 0);

		aFrame:SetBackdrop(tBackdrop);
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
function VUHDO_testPixelPerfect()

	VUHDO_Msg("|cffFFD100--- Pixel-Perfect Testing ---|r");

	VUHDO_Msg("|cffFFA500** Current Settings:|r");
	VUHDO_Msg("  |cffB0E0E6UI Scale:|r " .. (UIParent:GetScale() or 1));
	VUHDO_Msg("  |cffB0E0E6Pixel Scale:|r " .. VUHDO_getPixelScale());

	VUHDO_Msg("|cffFFA500** Refresh Test:|r");
	VUHDO_Msg("  Refreshing pixel scale...");
	VUHDO_refreshPixelScale();
	VUHDO_Msg("  |cffB0E0E6New Pixel Scale:|r " .. VUHDO_getPixelScale());

	VUHDO_Msg("|cffFFD100--- End of Pixel-Perfect Testing ---|r");

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



VUHDO_PixelUtil = tPixelUtil;
