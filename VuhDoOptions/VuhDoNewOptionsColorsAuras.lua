local _;



--
function VUHDO_colorsAurasOnShow()

	if not VUHDO_PANEL_SETUP then
		return;
	end

	if not VUHDO_PANEL_SETUP["AURA_DEFAULTS"] then
		VUHDO_PANEL_SETUP["AURA_DEFAULTS"] = {
			["iconSize"] = 20,
			["iconSpacing"] = 2,
			["showTimer"] = true,
			["showStacks"] = true,
			["showClock"] = true,
			["barWidth"] = 100,
			["barHeight"] = 12,
			["showBarIcon"] = true,
			["fadeOnLow"] = true,
			["fadeThreshold"] = 3,
			["flashOnLow"] = false,
			["flashThreshold"] = 2,
			["dispelBorder"] = true,
		};
	end

	return;

end
