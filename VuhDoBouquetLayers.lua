local _;

local pairs = pairs;
local ipairs = ipairs;
local tinsert = table.insert;
local twipe = table.wipe;

local CreateFrame = CreateFrame;

local VUHDO_META_NEW_ARRAY = VUHDO_META_NEW_ARRAY;
local VUHDO_BOUQUET_BUFFS_SPECIAL;
local VUHDO_BOUQUETS;
local VUHDO_INDICATOR_CONFIG;
local VUHDO_SECRET_TYPE_NONE;
local VUHDO_SECRET_TYPE_BOOLEAN;

local VUHDO_INDICATOR_BAR_MAP = {
	["BACKGROUND_BAR"] = 3,
	["HEALTH_BAR"] = 1,
	["MANA_BAR"] = 2,
	["AGGRO_BAR"] = 4,
	["THREAT_BAR"] = 7,
	["SIDE_LEFT"] = 17,
	["SIDE_RIGHT"] = 18,
	["MOUSEOVER_HIGHLIGHT"] = 8,
};

local VUHDO_INDICATOR_FRAME_GETTERS = {
	["BAR_BORDER"] = "VUHDO_getPlayerTargetFrame",
	["CLUSTER_BORDER"] = "VUHDO_getClusterBorderFrame",
};

local VUHDO_setStatusBarVuhDoColor;
local VUHDO_getHealthBar;
local VUHDO_getBarText;

local sSecretsEnabled = VUHDO_SECRETS_ENABLED;

local sBooleanOverlayLayers = { };
setmetatable(sBooleanOverlayLayers, VUHDO_META_NEW_ARRAY);

local sGlobalAlphaChains = { };
setmetatable(sGlobalAlphaChains, VUHDO_META_NEW_ARRAY);

local sWrapperNameCounter = 0;



--
function VUHDO_bouquetLayersInitLocalOverrides()

	VUHDO_META_NEW_ARRAY = _G["VUHDO_META_NEW_ARRAY"];
	VUHDO_BOUQUET_BUFFS_SPECIAL = _G["VUHDO_BOUQUET_BUFFS_SPECIAL"];
	VUHDO_BOUQUETS = _G["VUHDO_BOUQUETS"];
	VUHDO_INDICATOR_CONFIG = _G["VUHDO_INDICATOR_CONFIG"];
	VUHDO_SECRET_TYPE_NONE = _G["VUHDO_SECRET_TYPE_NONE"];
	VUHDO_SECRET_TYPE_BOOLEAN = _G["VUHDO_SECRET_TYPE_BOOLEAN"];

	VUHDO_setStatusBarVuhDoColor = _G["VUHDO_setStatusBarVuhDoColor"];
	VUHDO_getHealthBar = _G["VUHDO_getHealthBar"];
	VUHDO_getBarText = _G["VUHDO_getBarText"];

	return;

end



--
local tOverlay;
local tOverlayText;
local tBarText;
function VUHDO_getOrCreateBooleanOverlay(aButton, aValidatorName, aHealthBar)

	if sBooleanOverlayLayers[aButton][aValidatorName] then
		return sBooleanOverlayLayers[aButton][aValidatorName];
	end

	tOverlay = aButton:CreateTexture(nil, "OVERLAY");

	tOverlay:SetAllPoints(aHealthBar);
	tOverlay:SetTexture("Interface\\Buttons\\WHITE8X8");
	tOverlay:SetAlpha(0);

	tBarText = VUHDO_getBarText(aHealthBar);

	if tBarText then
		tOverlayText = aButton:CreateFontString(nil, "OVERLAY");

		tOverlayText:SetAllPoints(tBarText);
		tOverlayText:SetFontObject(tBarText:GetFontObject());
		tOverlayText:SetAlpha(0);
	else
		tOverlayText = nil;
	end

	sBooleanOverlayLayers[aButton][aValidatorName] = {
		["texture"] = tOverlay,
		["fontString"] = tOverlayText,
	};

	return sBooleanOverlayLayers[aButton][aValidatorName];

end



--
local tTexture;
local tFontString;
function VUHDO_applyBooleanOverlay(aOverlay, aSecretBool, aConfig, aTrueColor, aFalseColor)

	tTexture = aOverlay["texture"];
	tFontString = aOverlay["fontString"];

	if aConfig["useBackground"] then
		tTexture:SetVertexColorFromBoolean(aSecretBool, aTrueColor, aFalseColor);
	end

	if aConfig["useOpacity"] then
		tTexture:SetAlphaFromBoolean(aSecretBool, aConfig["O"] or 1, 0);
	else
		tTexture:SetAlphaFromBoolean(aSecretBool, 1, 0);
	end

	if aConfig["useText"] and tFontString then
		tFontString:SetVertexColorFromBoolean(aSecretBool, aTrueColor, aFalseColor);
		tFontString:SetAlphaFromBoolean(aSecretBool, aConfig["TO"] or 1, 0);
	end

	return;

end



--
function VUHDO_clearBooleanOverlays(aButton)

	for _, tOverlay in pairs(sBooleanOverlayLayers[aButton]) do
		tOverlay["texture"]:SetAlpha(0);
		if tOverlay["fontString"] then
			tOverlay["fontString"]:SetAlpha(0);
		end
	end

	return;

end



--
local tBouquet;
local tItem;
local tSpecial;
local tWrapper;
local tChain;
local tParent;
local tSecretType;
local tIndicatorBar;
local tOriginalParent;
local tBarIndex;
local tFrameGetter;
local tIndicatorAddLevel;
function VUHDO_buildGlobalAlphaChainsForIndicator(aButton, anIndicatorName, aBouquet, aPanelNum)

	if not aBouquet or not sSecretsEnabled then
		return;
	end

	tBarIndex = VUHDO_INDICATOR_BAR_MAP[anIndicatorName];
	if tBarIndex then
		tIndicatorBar = VUHDO_getHealthBar(aButton, tBarIndex);
	else
		tFrameGetter = VUHDO_INDICATOR_FRAME_GETTERS[anIndicatorName];
		if tFrameGetter then
			tIndicatorBar = _G[tFrameGetter](aButton);
		end
	end

	if not tIndicatorBar then
		return;
	end

	tIndicatorAddLevel = tIndicatorBar["addLevel"] or 0;

	if sGlobalAlphaChains[aButton] and sGlobalAlphaChains[aButton][anIndicatorName] then
		tChain = sGlobalAlphaChains[aButton][anIndicatorName];

		tOriginalParent = tChain["originalParent"];

		if tOriginalParent then
			tIndicatorBar:SetParent(tOriginalParent);

			tIndicatorBar["vuhdo_parent"] = nil;
		end

		for _, tStep in ipairs(tChain["steps"] or { }) do
			if tStep["frame"] then
				tStep["frame"]:Hide();
				tStep["frame"]:ClearAllPoints();
				tStep["frame"]:SetParent(nil);
			end
		end
	else
		tOriginalParent = tIndicatorBar:GetParent();
	end

	if not sGlobalAlphaChains[aButton] then
		sGlobalAlphaChains[aButton] = { };
	end

	sGlobalAlphaChains[aButton][anIndicatorName] = {
		["steps"] = { },
		["nonSecretSteps"] = { },
		["head"] = nil,
		["tail"] = nil,
		["originalParent"] = tOriginalParent,
		["barIndex"] = tBarIndex,
	};

	tChain = sGlobalAlphaChains[aButton][anIndicatorName];

	for tCnt = 1, #aBouquet do
		tItem = aBouquet[tCnt];
		tSpecial = VUHDO_BOUQUET_BUFFS_SPECIAL[tItem["name"]];

		if tSpecial and tSpecial["isGlobal"] and
		   tItem["color"] and tItem["color"]["useOpacity"] then

			tSecretType = tSpecial["secretType"] or VUHDO_SECRET_TYPE_NONE;

			if tSecretType == VUHDO_SECRET_TYPE_BOOLEAN then
				sWrapperNameCounter = sWrapperNameCounter + 1;

				tWrapper = CreateFrame("Frame", tOriginalParent:GetName() .. "AlpWr" .. sWrapperNameCounter, tOriginalParent);

tWrapper:SetAllPoints(tOriginalParent);
				tWrapper["addLevel"] = tIndicatorAddLevel;
				tWrapper:SetFrameLevel(tOriginalParent:GetFrameLevel());
				tWrapper:SetAlpha(1);
				tWrapper:Show();

				tinsert(tChain["steps"], {
					["frame"] = tWrapper,
					["item"] = tItem,
					["special"] = tSpecial,
					["trueAlpha"] = tSpecial["isInverted"] and 1 or (tItem["color"]["O"] or 1),
					["falseAlpha"] = tSpecial["isInverted"] and (tItem["color"]["O"] or 1) or 1,
				});
			else
				tinsert(tChain["nonSecretSteps"], {
					["item"] = tItem,
					["special"] = tSpecial,
					["alpha"] = tItem["color"]["O"] or 1,
				});
			end
		end
	end

	if #tChain["steps"] > 0 then
		tChain["head"] = tChain["steps"][1]["frame"];

		tParent = tOriginalParent;

		for tIdx = 1, #tChain["steps"] do
			tWrapper = tChain["steps"][tIdx]["frame"];

			tWrapper:SetParent(tParent);
			tWrapper:ClearAllPoints();
			tWrapper:SetAllPoints(tParent);
			tWrapper:SetFrameLevel(tParent:GetFrameLevel());

			tParent = tWrapper;
		end

		tChain["tail"] = tChain["steps"][#tChain["steps"]]["frame"];

		tIndicatorBar:SetParent(tChain["tail"]);

		tIndicatorBar["vuhdo_parent"] = tOriginalParent;
	else
		tChain["tail"] = tOriginalParent;
	end

	return;

end



--
function VUHDO_getAlphaChainTail(aButton, anIndicatorName)

	if not sGlobalAlphaChains[aButton] or not sGlobalAlphaChains[aButton][anIndicatorName] then
		return nil;
	end

	return sGlobalAlphaChains[aButton][anIndicatorName]["tail"];

end



--
local tBouquetName;
local tBouquet;
local tIndicatorConfig;
function VUHDO_buildAllIndicatorAlphaChains(aButton, aPanelNum)

	if not sSecretsEnabled then
		return;
	end

	tIndicatorConfig = VUHDO_INDICATOR_CONFIG[aPanelNum];
	if not tIndicatorConfig then
		return;
	end

	for tIndicatorName, _ in pairs(VUHDO_INDICATOR_BAR_MAP) do
		tBouquetName = tIndicatorConfig["BOUQUETS"][tIndicatorName];
		tBouquet = tBouquetName and tBouquetName ~= "" and VUHDO_BOUQUETS["STORED"][tBouquetName];

		if tBouquet then
			VUHDO_buildGlobalAlphaChainsForIndicator(aButton, tIndicatorName, tBouquet, aPanelNum);
		end
	end

	for tIndicatorName, _ in pairs(VUHDO_INDICATOR_FRAME_GETTERS) do
		tBouquetName = tIndicatorConfig["BOUQUETS"][tIndicatorName];
		tBouquet = tBouquetName and tBouquetName ~= "" and VUHDO_BOUQUETS["STORED"][tBouquetName];

		if tBouquet then
			VUHDO_buildGlobalAlphaChainsForIndicator(aButton, tIndicatorName, tBouquet, aPanelNum);
		end
	end

	return;

end



--
local tChain;
local tStep;
local tSecretBool;
local tNonSecretAlpha;
local tIsActive;
local tIndicatorBar;
local tFrameGetter;
function VUHDO_updateIndicatorAlphaChain(aButton, anIndicatorName, anInfo)

	if not anInfo then
		return;
	end

	if not sGlobalAlphaChains[aButton] then
		return;
	end

	tChain = sGlobalAlphaChains[aButton][anIndicatorName];

	if not tChain then
		return;
	end

	if tChain["barIndex"] then
		tIndicatorBar = VUHDO_getHealthBar(aButton, tChain["barIndex"]);
	else
		tFrameGetter = VUHDO_INDICATOR_FRAME_GETTERS[anIndicatorName];

		if tFrameGetter then
			tIndicatorBar = _G[tFrameGetter](aButton);
		end
	end

	if not tIndicatorBar then
		return;
	end

	tNonSecretAlpha = 1.0;
	for tIdx = 1, #tChain["nonSecretSteps"] do
		tStep = tChain["nonSecretSteps"][tIdx];

		tIsActive = tStep["special"]["validator"](anInfo, tStep["item"]);

		if tIsActive then
			tNonSecretAlpha = tNonSecretAlpha * tStep["alpha"];
		end
	end

	tIndicatorBar:SetAlpha(tNonSecretAlpha);

	for tIdx = 1, #tChain["steps"] do
		tStep = tChain["steps"][tIdx];

		tIsActive, _, _, _, _, _, _, _, _, _, _, tSecretBool = tStep["special"]["validator"](anInfo, tStep["item"]);

		if tSecretBool ~= nil then
			tStep["frame"]:SetAlphaFromBoolean(tSecretBool, tStep["trueAlpha"], tStep["falseAlpha"]);
		else
			tStep["frame"]:SetAlpha(tIsActive and tStep["falseAlpha"] or tStep["trueAlpha"]);
		end
	end

	return;

end



--
local tValidatorResult;
function VUHDO_evaluateValidatorActive(aSpecial, anInfo, aItem)

	if not aSpecial or not aSpecial["validator"] then
		return false;
	end

	tValidatorResult = aSpecial["validator"](anInfo, aItem);

	return tValidatorResult == true;

end



--
local tDebuffInfo;
function VUHDO_getChosenDebuffAuraInstanceId(aUnit)

	tDebuffInfo = VUHDO_getChosenDebuffInfo(aUnit);

	if tDebuffInfo and tDebuffInfo[8] then
		return tDebuffInfo[8];
	end

	return nil;

end



--
function VUHDO_rebuildAllAlphaChains()

	for tButton, tIndicatorChains in pairs(sGlobalAlphaChains) do
		for tIndicatorName, tChain in pairs(tIndicatorChains) do
			if tChain["steps"] then
				for _, tStep in ipairs(tChain["steps"]) do
					if tStep["frame"] then
						tStep["frame"]:Hide();
						tStep["frame"]:SetParent(nil);
					end
				end
			end
		end
	end

	twipe(sGlobalAlphaChains);

	return;

end



--
local tResultSlot;
local tR;
local tG;
local tB;
local tA;
local tOverlay;
local function VUHDO_applyCurveColorToBar(aBar, aLayerTemplate)

	if not aLayerTemplate["hasCurves"] or #aLayerTemplate["curveResults"] == 0 then
		aBar["secretCurveColor"] = nil;

		return;
	end

	tResultSlot = nil;

	for tIdx = 1, #aLayerTemplate["curveResults"] do
		if aLayerTemplate["curveResults"][tIdx]["isActive"] then
			tResultSlot = aLayerTemplate["curveResults"][tIdx];

			break;
		end
	end

	if not tResultSlot then
		aBar["secretCurveColor"] = nil;

		return;
	end

	if tResultSlot["r"] then
		tR, tG, tB, tA = tResultSlot["r"], tResultSlot["g"], tResultSlot["b"], tResultSlot["a"];

		if sSecretsEnabled then
			aBar["secretCurveColor"] = aBar["secretCurveColor"] or { };

			aBar["secretCurveColor"]["R"] = tR;
			aBar["secretCurveColor"]["G"] = tG;
			aBar["secretCurveColor"]["B"] = tB;
			aBar["secretCurveColor"]["O"] = tA;
		else
			aBar["secretCurveColor"] = nil;
		end

		if aLayerTemplate["useBackground"] then
			aBar:GetStatusBarTexture():SetVertexColor(tR, tG, tB,
				aLayerTemplate["useOpacity"] and tA or 1);
		end

		if aLayerTemplate["useOpacity"] and not aLayerTemplate["useBackground"] then
			aBar:SetAlpha(tA);
		end
	else
		aBar["secretCurveColor"] = nil;
	end

	return;

end



--
local function VUHDO_applyCurveColorToTexture(aTexture, aLayerTemplate)

	if not aLayerTemplate["hasCurves"] or #aLayerTemplate["curveResults"] == 0 then
		return;
	end

	tResultSlot = nil;

	for tIdx = 1, #aLayerTemplate["curveResults"] do
		if aLayerTemplate["curveResults"][tIdx]["isActive"] then
			tResultSlot = aLayerTemplate["curveResults"][tIdx];

			break;
		end
	end

	if tResultSlot and tResultSlot["r"] then
		tR, tG, tB, tA = tResultSlot["r"], tResultSlot["g"], tResultSlot["b"], tResultSlot["a"];

		aTexture:SetVertexColor(tR, tG, tB, tA);
	end

	return;

end



--
local function VUHDO_applyCurveColorToBorder(aBorder, aLayerTemplate)

	if not aLayerTemplate["hasCurves"] or #aLayerTemplate["curveResults"] == 0 then
		return;
	end

	tResultSlot = nil;

	for tIdx = 1, #aLayerTemplate["curveResults"] do
		if aLayerTemplate["curveResults"][tIdx]["isActive"] then
			tResultSlot = aLayerTemplate["curveResults"][tIdx];

			break;
		end
	end

	if tResultSlot and tResultSlot["r"] then
		tR, tG, tB, tA = tResultSlot["r"], tResultSlot["g"], tResultSlot["b"], tResultSlot["a"];

		aBorder:SetBackdropBorderColor(tR, tG, tB, tA);
	end

	return;

end



--
local function VUHDO_applyBooleanLayers(aButton, aTarget, aLayerTemplate)

	if not aLayerTemplate["hasBools"] then
		return;
	end

	for tIdx = 1, #aLayerTemplate["booleanResults"] do
		tResultSlot = aLayerTemplate["booleanResults"][tIdx];

		if tResultSlot["color"] and
		   (tResultSlot["color"]["useBackground"] or tResultSlot["color"]["useText"]) then
			tOverlay = VUHDO_getOrCreateBooleanOverlay(aButton,
				aLayerTemplate["booleanValidators"][tIdx]["item"]["name"], aTarget);

			if tOverlay and tResultSlot["trueColorMixin"] then
				VUHDO_applyBooleanOverlay(tOverlay, tResultSlot["secretBool"],
					tResultSlot["color"], tResultSlot["trueColorMixin"], tResultSlot["falseColorMixin"]);
			end
		end
	end

	return;

end



--
local function VUHDO_applyDispelColorToBar(aBar, aLayerTemplate)

	if not aLayerTemplate["hasDispels"] then
		return;
	end

	for tIdx = 1, #aLayerTemplate["dispelResults"] do
		tResultSlot = aLayerTemplate["dispelResults"][tIdx];

		if tResultSlot["isActive"] and tResultSlot["r"] then
			tR, tG, tB, tA = tResultSlot["r"], tResultSlot["g"], tResultSlot["b"], tResultSlot["a"];

			aBar:GetStatusBarTexture():SetVertexColor(tR, tG, tB, tA);
		end
	end

	return;

end



--
local function VUHDO_applyDispelColorToTexture(aTexture, aLayerTemplate)

	if not aLayerTemplate["hasDispels"] then
		return;
	end

	for tIdx = 1, #aLayerTemplate["dispelResults"] do
		tResultSlot = aLayerTemplate["dispelResults"][tIdx];

		if tResultSlot["r"] then
			tR, tG, tB, tA = tResultSlot["r"], tResultSlot["g"], tResultSlot["b"], tResultSlot["a"];

			aTexture:SetVertexColor(tR, tG, tB, tA);
		end
	end

	return;

end



--
local function VUHDO_applyDispelColorToBorder(aBorder, aLayerTemplate)

	if not aLayerTemplate["hasDispels"] then
		return;
	end

	for tIdx = 1, #aLayerTemplate["dispelResults"] do
		tResultSlot = aLayerTemplate["dispelResults"][tIdx];

		if tResultSlot["r"] then
			tR, tG, tB, tA = tResultSlot["r"], tResultSlot["g"], tResultSlot["b"], tResultSlot["a"];

			aBorder:SetBackdropBorderColor(tR, tG, tB, tA);
		end
	end

	return;

end



--
local tResultSlot;
local tNonSecretColor;
local tNonSecretMaxColor;
function VUHDO_applyNonSecretColorsToBar(aBar, aLayerTemplate)

	if not aBar or not aLayerTemplate then
		return;
	end

	if not aLayerTemplate["hasNonSecrets"] and not aLayerTemplate["hasAuras"] then
		return;
	end

	tNonSecretColor = nil;
	tNonSecretMaxColor = nil;

	for tIdx = #aLayerTemplate["nonSecretResults"], 1, -1 do
		tResultSlot = aLayerTemplate["nonSecretResults"][tIdx];

		if tResultSlot["isActive"] and tResultSlot["color"] then
			tNonSecretColor = tResultSlot["color"];
			tNonSecretMaxColor = tResultSlot["maxColor"];

			break;
		end
	end

	if not tNonSecretColor then
		for tIdx = #aLayerTemplate["auraResults"], 1, -1 do
			tResultSlot = aLayerTemplate["auraResults"][tIdx];

			if tResultSlot["isActive"] and tResultSlot["color"] then
				tNonSecretColor = tResultSlot["color"];

				break;
			end
		end
	end

	if tNonSecretColor then
		VUHDO_setStatusBarVuhDoColor(aBar, tNonSecretColor, tNonSecretMaxColor);
	end

	return;

end



--
function VUHDO_applyAllLayersToBar(aButton, aBar, aLayerTemplate)

	if not aButton or not aBar or not aLayerTemplate then
		return;
	end

	VUHDO_applyNonSecretColorsToBar(aBar, aLayerTemplate);

	VUHDO_applyCurveColorToBar(aBar, aLayerTemplate);
	VUHDO_applyBooleanLayers(aButton, aBar, aLayerTemplate);
	VUHDO_applyDispelColorToBar(aBar, aLayerTemplate);

	return;

end



--
function VUHDO_applyAllLayersToTexture(aButton, aTexture, aLayerTemplate)

	if not aButton or not aTexture or not aLayerTemplate then
		return;
	end

	VUHDO_applyCurveColorToTexture(aTexture, aLayerTemplate);
	VUHDO_applyBooleanLayers(aButton, aTexture, aLayerTemplate);
	VUHDO_applyDispelColorToTexture(aTexture, aLayerTemplate);

	return;

end



--
function VUHDO_applyAllLayersToBorder(aButton, aBorder, aLayerTemplate)

	if not aButton or not aBorder or not aLayerTemplate then
		return;
	end

	VUHDO_applyCurveColorToBorder(aBorder, aLayerTemplate);
	VUHDO_applyBooleanLayers(aButton, aBorder, aLayerTemplate);
	VUHDO_applyDispelColorToBorder(aBorder, aLayerTemplate);

	return;

end