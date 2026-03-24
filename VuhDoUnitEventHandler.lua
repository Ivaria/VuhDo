local _;

local CreateFrame = CreateFrame;
local InCombatLockdown = InCombatLockdown;
local UnitExists = UnitExists;
local pairs = pairs;
local debugprofilestop = debugprofilestop;
local tinsert = table.insert;
local twipe = table.wipe;
local format = string.format;
local unpack = unpack;
local type = type;

local VUHDO_isBossUnit;
local VUHDO_isAltPowerActive;
local VUHDO_onUnitAura;
local VUHDO_onUnitAuraInference;
local VUHDO_determineAura;
local VUHDO_updateInferredAuraDisplaysForUnit;
local VUHDO_updateHealth;
local VUHDO_updateManaBars;
local VUHDO_updateBouquetsForEvent;
local VUHDO_updateShieldBar;
local VUHDO_updateHealAbsorbBar;
local VUHDO_updateUnitAggro;
local VUHDO_updateTargetBars;
local VUHDO_updatePanelVisibility;
local VUHDO_resetNameTextCache;
local VUHDO_updateHealthBarsFor;
local VUHDO_quickRaidReload;
local VUHDO_normalRaidReload;
local VUHDO_isAnyoneInterestedIn;
local VUHDO_updateHandlerOnEventMetrics;

local VUHDO_RAID;
local VUHDO_CONFIG;
local VUHDO_PANEL_SETUP;
local VUHDO_UNIT_BUTTONS;
local VUHDO_INTERNAL_TOGGLES;
local VUHDO_VARIABLES_LOADED;
local VUHDO_MAX_BOSS_FRAMES;

VUHDO_SPECIAL_UNIT_TOKENS = { };
local VUHDO_SPECIAL_UNIT_TOKENS = VUHDO_SPECIAL_UNIT_TOKENS;

local sSpecialUnitFrames = { };
local sSpecialUnitChunks = { };
local sAllSpecialUnits = { };

local sAllUnitEventNames = {
	"UNIT_AURA",
	"UNIT_HEALTH",
	"UNIT_MAXHEALTH",
	"UNIT_CONNECTION",
	"UNIT_NAME_UPDATE",
	"UNIT_FACTION",
	"INCOMING_RESURRECT_CHANGED",
	"INCOMING_SUMMON_CHANGED",
	"UNIT_PHASE",
	"PLAYER_FLAGS_CHANGED",
	"UNIT_PET",
	"UNIT_ENTERED_VEHICLE",
	"UNIT_EXITED_VEHICLE",
	"UNIT_EXITING_VEHICLE",
	"UNIT_THREAT_SITUATION_UPDATE",
	"UNIT_DISPLAYPOWER",
	"UNIT_MAXPOWER",
	"UNIT_POWER_UPDATE",
	"UNIT_TARGET",
	"UNIT_POWER_BAR_SHOW",
	"UNIT_POWER_BAR_HIDE",
	"UNIT_HEAL_PREDICTION",
	"UNIT_ABSORB_AMOUNT_CHANGED",
	"UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
};

local sPlayerPowerResourceBouquetModes = {
	["CHI"] = 35,
	["HOLY_POWER"] = 31,
	["COMBO_POINTS"] = 40,
	["SOUL_SHARDS"] = 41,
	["RUNES"] = 42,
	["ARCANE_CHARGES"] = 43,
};



--
function VUHDO_unitEventHandlerInitLocalOverrides()

	VUHDO_RAID = _G["VUHDO_RAID"];
	VUHDO_CONFIG = _G["VUHDO_CONFIG"];
	VUHDO_PANEL_SETUP = _G["VUHDO_PANEL_SETUP"];
	VUHDO_UNIT_BUTTONS = _G["VUHDO_UNIT_BUTTONS"];
	VUHDO_INTERNAL_TOGGLES = _G["VUHDO_INTERNAL_TOGGLES"];
	VUHDO_VARIABLES_LOADED = _G["VUHDO_VARIABLES_LOADED"];
	VUHDO_MAX_BOSS_FRAMES = _G["VUHDO_MAX_BOSS_FRAMES"];

	VUHDO_isBossUnit = _G["VUHDO_isBossUnit"];
	VUHDO_isAltPowerActive = _G["VUHDO_isAltPowerActive"];
	VUHDO_onUnitAura = _G["VUHDO_onUnitAura"];
	VUHDO_onUnitAuraInference = _G["VUHDO_onUnitAuraInference"];
	VUHDO_determineAura = _G["VUHDO_determineAura"];
	VUHDO_updateInferredAuraDisplaysForUnit = _G["VUHDO_updateInferredAuraDisplaysForUnit"];
	VUHDO_updateHealth = _G["VUHDO_updateHealth"];
	VUHDO_updateManaBars = _G["VUHDO_updateManaBars"];
	VUHDO_updateBouquetsForEvent = _G["VUHDO_updateBouquetsForEvent"];
	VUHDO_updateShieldBar = _G["VUHDO_updateShieldBar"];
	VUHDO_updateHealAbsorbBar = _G["VUHDO_updateHealAbsorbBar"];
	VUHDO_updateUnitAggro = _G["VUHDO_updateUnitAggro"];
	VUHDO_updateTargetBars = _G["VUHDO_updateTargetBars"];
	VUHDO_updatePanelVisibility = _G["VUHDO_updatePanelVisibility"];
	VUHDO_resetNameTextCache = _G["VUHDO_resetNameTextCache"];
	VUHDO_updateHealthBarsFor = _G["VUHDO_updateHealthBarsFor"];
	VUHDO_quickRaidReload = _G["VUHDO_quickRaidReload"];
	VUHDO_normalRaidReload = _G["VUHDO_normalRaidReload"];
	VUHDO_isAnyoneInterestedIn = _G["VUHDO_isAnyoneInterestedIn"];
	VUHDO_updateHandlerOnEventMetrics = _G["VUHDO_updateHandlerOnEventMetrics"];

	VUHDO_updateHealth = _G["VUHDO_deferUpdateHealth"];
	VUHDO_updateBouquetsForEvent = _G["VUHDO_deferUpdateBouquetsForEvent"];
	VUHDO_updateShieldBar = _G["VUHDO_deferUpdateShieldBar"];
	VUHDO_updateHealAbsorbBar = _G["VUHDO_deferUpdateHealAbsorbBar"];
	VUHDO_updateHealthBarsFor = _G["VUHDO_deferUpdateHealthBarsFor"];
	VUHDO_updateManaBars = _G["VUHDO_deferUpdateManaBars"];
	VUHDO_updateUnitAggro = _G["VUHDO_deferUpdateUnitAggro"];

	return;

end



--
local tUnitInfo;
local tPowerBouquetMode;
function VUHDO_dispatchUnitEvent(anEvent, anArg1, anArg2, anArg3, anArg4, anArg5)

	if "UNIT_AURA" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		tUnitInfo = VUHDO_RAID[anArg1];

		if tUnitInfo then
			VUHDO_onUnitAura(anArg1, anArg2);
			VUHDO_updateBouquetsForEvent(anArg1, 4);

			if VUHDO_VARIABLES_LOADED and VUHDO_INTERNAL_TOGGLES[VUHDO_UPDATE_AURA_INFERENCE] then
				if VUHDO_onUnitAuraInference(anArg1, anArg2) then
					VUHDO_determineAura(anArg1);

					VUHDO_updateBouquetsForEvent(anArg1, 4);

					VUHDO_updateInferredAuraDisplaysForUnit(anArg1);
				end
			end
		end

	elseif "UNIT_HEALTH" == anEvent then
		if anArg1 and ((VUHDO_RAID and VUHDO_RAID[anArg1]) or VUHDO_isBossUnit(anArg1)) then
			VUHDO_updateHealth(anArg1, 2);
		end

	elseif "UNIT_HEAL_PREDICTION" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if VUHDO_RAID[anArg1] then
			VUHDO_updateHealth(anArg1, 9);
			VUHDO_updateBouquetsForEvent(anArg1, 9);
		end

	elseif "UNIT_POWER_UPDATE" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if VUHDO_RAID[anArg1] then
			if "ALTERNATE" == anArg2 then
				VUHDO_updateBouquetsForEvent(anArg1, 30);
			else
				tPowerBouquetMode = sPlayerPowerResourceBouquetModes[anArg2];

				if tPowerBouquetMode then
					if "player" == anArg1 then
						VUHDO_updateBouquetsForEvent("player", tPowerBouquetMode);
					end
				else
					VUHDO_updateManaBars(anArg1, 1);
				end
			end
		end

	elseif "UNIT_ABSORB_AMOUNT_CHANGED" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if VUHDO_RAID[anArg1] then
			VUHDO_updateBouquetsForEvent(anArg1, 36);

			VUHDO_updateShieldBar(anArg1);
		end

	elseif "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if VUHDO_RAID[anArg1] then
			VUHDO_updateBouquetsForEvent(anArg1, 36);

			VUHDO_updateHealAbsorbBar(anArg1);
		end

	elseif "UNIT_THREAT_SITUATION_UPDATE" == anEvent then
		if VUHDO_VARIABLES_LOADED then
			VUHDO_updateUnitAggro(anArg1);
		end

	elseif "UNIT_MAXHEALTH" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if anArg1 and VUHDO_RAID[anArg1] then
			VUHDO_updateHealth(anArg1, VUHDO_UPDATE_HEALTH_MAX);
		end

	elseif "UNIT_TARGET" == anEvent then
		if VUHDO_VARIABLES_LOADED and "player" ~= anArg1 then
			VUHDO_updateTargetBars(anArg1);
			VUHDO_updateBouquetsForEvent(anArg1, 22);
			VUHDO_updatePanelVisibility();
		end

	elseif "UNIT_DISPLAYPOWER" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if VUHDO_RAID[anArg1] then
			VUHDO_updateManaBars(anArg1, 3);
		end

	elseif "UNIT_MAXPOWER" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if VUHDO_RAID[anArg1] then
			if "ALTERNATE" == anArg2 then
				VUHDO_updateBouquetsForEvent(anArg1, 30);
			else
				VUHDO_updateManaBars(anArg1, 2);
			end
		end

	elseif "UNIT_PET" == anEvent then
		if VUHDO_INTERNAL_TOGGLES[VUHDO_UPDATE_PETS] or not InCombatLockdown() then
			VUHDO_REMOVE_HOTS = false;

			if "player" == anArg1 then
				VUHDO_quickRaidReload();
			else
				VUHDO_normalRaidReload();
			end
		end

	elseif "UNIT_ENTERED_VEHICLE" == anEvent or "UNIT_EXITED_VEHICLE" == anEvent or "UNIT_EXITING_VEHICLE" == anEvent then
		VUHDO_REMOVE_HOTS = false;

		VUHDO_normalRaidReload();

	elseif "PLAYER_FLAGS_CHANGED" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if VUHDO_RAID[anArg1] then
			VUHDO_updateHealth(anArg1, 6);
			VUHDO_updateBouquetsForEvent(anArg1, 6);
		end

	elseif "UNIT_POWER_BAR_SHOW" == anEvent or "UNIT_POWER_BAR_HIDE" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if VUHDO_RAID[anArg1] then
			VUHDO_RAID[anArg1]["isAltPower"] = VUHDO_isAltPowerActive(anArg1);
			VUHDO_updateBouquetsForEvent(anArg1, 30);
		end

	elseif "UNIT_CONNECTION" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if VUHDO_RAID[anArg1] then
			VUHDO_updateHealth(anArg1, VUHDO_UPDATE_DC);
		end

	elseif "UNIT_NAME_UPDATE" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if VUHDO_RAID[anArg1] ~= nil then
			VUHDO_resetNameTextCache();

			VUHDO_updateHealthBarsFor(anArg1, 7);
		end

	elseif "UNIT_FACTION" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if VUHDO_RAID[anArg1] then
			VUHDO_updateBouquetsForEvent(anArg1, 34);
		end

	elseif "INCOMING_RESURRECT_CHANGED" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if VUHDO_RAID[anArg1] ~= nil then
			VUHDO_updateBouquetsForEvent(anArg1, 25);
		end

	elseif "INCOMING_SUMMON_CHANGED" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if VUHDO_RAID[anArg1] ~= nil then
			VUHDO_updateBouquetsForEvent(anArg1, 38);
		end

	elseif "UNIT_PHASE" == anEvent then
		if not VUHDO_RAID then
			return;
		end

		if VUHDO_RAID[anArg1] ~= nil then
			VUHDO_updateBouquetsForEvent(anArg1, 39);
		end

	end

	return;

end



local tButtons;
local tUnitEventStartTime;
local tUnitEventDuration;

--
local function VUHDO_runProfiledUnitDispatch(anEvent, anArg1, anArg2, anArg3, anArg4, anArg5)

	if VUHDO_HANDLER_PROFILING_ENABLED then
		tUnitEventStartTime = debugprofilestop();
	end

	VUHDO_dispatchUnitEvent(anEvent, anArg1, anArg2, anArg3, anArg4, anArg5);

	if VUHDO_HANDLER_PROFILING_ENABLED then
		tUnitEventDuration = (debugprofilestop() - tUnitEventStartTime) * 1000;
		VUHDO_updateHandlerOnEventMetrics(anEvent, tUnitEventDuration, anArg1, anArg2, anArg3, anArg4, anArg5);
	end

	return;

end



--
function VUHDO_onButtonUnitEvent(aButton, anEvent, anArg1, anArg2, anArg3, anArg4, anArg5)

	if VUHDO_SPECIAL_UNIT_TOKENS[anArg1] then
		return;
	end

	tButtons = VUHDO_UNIT_BUTTONS[anArg1];

	if tButtons and aButton ~= tButtons[1] then
		return;
	end

	VUHDO_runProfiledUnitDispatch(anEvent, anArg1, anArg2, anArg3, anArg4, anArg5);

	return;

end



--
function VUHDO_onSpecialUnitEvent(aFrame, anEvent, anArg1, anArg2, anArg3, anArg4, anArg5)

	VUHDO_runProfiledUnitDispatch(anEvent, anArg1, anArg2, anArg3, anArg4, anArg5);

	return;

end



--
local function VUHDO_getPowerEventsInterest()

	return VUHDO_isAnyoneInterestedIn(VUHDO_UPDATE_MANA)
		or VUHDO_isAnyoneInterestedIn(VUHDO_UPDATE_OTHER_POWERS)
		or VUHDO_isAnyoneInterestedIn(VUHDO_UPDATE_ALT_POWER)
		or VUHDO_isAnyoneInterestedIn(VUHDO_UPDATE_OWN_HOLY_POWER)
		or VUHDO_isAnyoneInterestedIn(VUHDO_UPDATE_CHI)
		or VUHDO_isAnyoneInterestedIn(VUHDO_UPDATE_COMBO_POINTS)
		or VUHDO_isAnyoneInterestedIn(VUHDO_UPDATE_SOUL_SHARDS)
		or VUHDO_isAnyoneInterestedIn(VUHDO_UPDATE_RUNES)
		or VUHDO_isAnyoneInterestedIn(VUHDO_UPDATE_ARCANE_CHARGES);

end



--
local function VUHDO_getThreatEventsInterest()

	return VUHDO_INTERNAL_TOGGLES[VUHDO_UPDATE_THREAT_LEVEL]
		or VUHDO_isAnyoneInterestedIn(VUHDO_UPDATE_AGGRO);

end



--
local function VUHDO_getShieldInterest()

	return VUHDO_PANEL_SETUP["BAR_COLORS"]["HOTS"]["showShieldAbsorb"]
		or VUHDO_CONFIG["SHOW_SHIELD_BAR"]
		or VUHDO_isAnyoneInterestedIn(VUHDO_UPDATE_SHIELD);

end



--
local function VUHDO_getHealAbsorbInterest()

	return VUHDO_CONFIG["SHOW_HEAL_ABSORB_BAR"]
		or VUHDO_isAnyoneInterestedIn(VUHDO_UPDATE_SHIELD);

end



--
local tCnt;
local tEvent;
local function VUHDO_unregisterKnownUnitEventsFromFrame(aFrame)

	for tCnt = 1, #sAllUnitEventNames do
		tEvent = sAllUnitEventNames[tCnt];

		aFrame:UnregisterEvent(tEvent);
	end

	return;

end



--
local function VUHDO_registerUnitEventForCore(aFrame, aUnits, aEventName)

	if type(aUnits) == "string" then
		aFrame:RegisterUnitEvent(aEventName, aUnits);
	else
		aFrame:RegisterUnitEvent(aEventName, unpack(aUnits));
	end

	return;

end



--
local function VUHDO_applyCoreUnitRegistrations(aFrame, aUnits)

	VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_AURA");
	VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_HEALTH");
	VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_MAXHEALTH");
	VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_CONNECTION");
	VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_NAME_UPDATE");
	VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_FACTION");
	VUHDO_registerUnitEventForCore(aFrame, aUnits, "INCOMING_RESURRECT_CHANGED");
	VUHDO_registerUnitEventForCore(aFrame, aUnits, "INCOMING_SUMMON_CHANGED");
	VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_PHASE");
	VUHDO_registerUnitEventForCore(aFrame, aUnits, "PLAYER_FLAGS_CHANGED");
	VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_PET");
	VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_ENTERED_VEHICLE");
	VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_EXITED_VEHICLE");
	VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_EXITING_VEHICLE");

	if VUHDO_getThreatEventsInterest() then
		VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_THREAT_SITUATION_UPDATE");
	end

	if VUHDO_getPowerEventsInterest() then
		VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_DISPLAYPOWER");
		VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_MAXPOWER");
		VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_POWER_UPDATE");
	end

	if VUHDO_isAnyoneInterestedIn(VUHDO_UPDATE_UNIT_TARGET) then
		VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_TARGET");
	end

	if VUHDO_isAnyoneInterestedIn(VUHDO_UPDATE_ALT_POWER) then
		VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_POWER_BAR_SHOW");
		VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_POWER_BAR_HIDE");
	end

	if VUHDO_CONFIG["SHOW_INCOMING"] or VUHDO_CONFIG["SHOW_OWN_INCOMING"] then
		VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_HEAL_PREDICTION");
	end

	if VUHDO_getShieldInterest() then
		VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_ABSORB_AMOUNT_CHANGED");
	end

	if VUHDO_getHealAbsorbInterest() then
		VUHDO_registerUnitEventForCore(aFrame, aUnits, "UNIT_HEAL_ABSORB_AMOUNT_CHANGED");
	end

	return;

end



--
local function VUHDO_registerHealButtonUnitEvents(aFrame, aUnit)

	VUHDO_unregisterKnownUnitEventsFromFrame(aFrame);

	VUHDO_applyCoreUnitRegistrations(aFrame, aUnit);

	aFrame:SetScript("OnEvent", VUHDO_onButtonUnitEvent);

	aFrame["vuhdo_unit_events"] = aUnit;

	return;

end



--
local function VUHDO_registerMultiUnitFrameEvents(aFrame, aUnits)

	VUHDO_unregisterKnownUnitEventsFromFrame(aFrame);

	VUHDO_applyCoreUnitRegistrations(aFrame, aUnits);

	aFrame:SetScript("OnEvent", VUHDO_onSpecialUnitEvent);

	return;

end



--
function VUHDO_registerUnitEventsForButton(aButton, aUnit)

	if not aUnit or not aButton then
		return;
	end

	if aButton:GetScript("OnEvent") and aButton["vuhdo_unit_events"] == aUnit then
		return;
	end

	VUHDO_registerHealButtonUnitEvents(aButton, aUnit);

	return;

end



--
function VUHDO_unregisterUnitEventsForButton(aButton)

	if not aButton then
		return;
	end

	VUHDO_unregisterKnownUnitEventsFromFrame(aButton);

	aButton:SetScript("OnEvent", nil);

	aButton["vuhdo_unit_events"] = nil;

	return;

end



--
function VUHDO_unregisterAllButtonUnitEvents()

	if not VUHDO_UNIT_BUTTONS then
		return;
	end

	for tUnit, tButtons in pairs(VUHDO_UNIT_BUTTONS) do
		for _, tButton in pairs(tButtons) do
			if tButton and tUnit then
				VUHDO_unregisterUnitEventsForButton(tButton);
			end
		end
	end

	return;

end



--
function VUHDO_refreshAllHealButtonUnitEvents()

	if not VUHDO_UNIT_BUTTONS then
		return;
	end

	for tUnit, tButtons in pairs(VUHDO_UNIT_BUTTONS) do
		if not VUHDO_SPECIAL_UNIT_TOKENS[tUnit] then
			for _, tButton in pairs(tButtons) do
				if tButton and tUnit then
					VUHDO_registerHealButtonUnitEvents(tButton, tUnit);
				end
			end
		end
	end

	return;

end



--
local function VUHDO_buildSpecialUnitList()

	twipe(sAllSpecialUnits);

	tinsert(sAllSpecialUnits, "player");
	tinsert(sAllSpecialUnits, "focus");
	tinsert(sAllSpecialUnits, "target");

	for tCnt = 1, VUHDO_MAX_BOSS_FRAMES do
		tinsert(sAllSpecialUnits, format("boss%d", tCnt));
	end

	return;

end



--
local function VUHDO_buildSpecialUnitTokens()

	twipe(VUHDO_SPECIAL_UNIT_TOKENS);

	for tCnt = 1, #sAllSpecialUnits do
		VUHDO_SPECIAL_UNIT_TOKENS[sAllSpecialUnits[tCnt]] = true;
	end

	return;

end



--
local tChunk;
local function VUHDO_createSpecialUnitFrames()

	twipe(sSpecialUnitChunks);

	for tCnt = 1, #sAllSpecialUnits do
		if (tCnt - 1) % 4 == 0 then
			tChunk = { };

			tinsert(sSpecialUnitChunks, tChunk);
		end

		tinsert(tChunk, sAllSpecialUnits[tCnt]);
	end

	for tCnt = #sSpecialUnitFrames + 1, #sSpecialUnitChunks do
		sSpecialUnitFrames[tCnt] = CreateFrame("Frame", format("VuhDoSpecialUnitEventFrame%d", tCnt), UIParent);
	end

	return;

end



--
local tHasValid;
local function VUHDO_chunkHasValidUnit(aChunk)

	tHasValid = false;

	for tIdx = 1, #aChunk do
		if UnitExists(aChunk[tIdx]) then
			tHasValid = true;

			break;
		end
	end

	return tHasValid;

end



--
function VUHDO_refreshSpecialUnitFrames()

	for tCnt = 1, #sSpecialUnitFrames do
		if tCnt <= #sSpecialUnitChunks and VUHDO_chunkHasValidUnit(sSpecialUnitChunks[tCnt]) then
			VUHDO_registerMultiUnitFrameEvents(sSpecialUnitFrames[tCnt], sSpecialUnitChunks[tCnt]);
		else
			VUHDO_unregisterKnownUnitEventsFromFrame(sSpecialUnitFrames[tCnt]);

			sSpecialUnitFrames[tCnt]:SetScript("OnEvent", nil);
		end
	end

	return;

end



--
function VUHDO_updateToggledUnitEvents()

	VUHDO_refreshSpecialUnitFrames();
	VUHDO_refreshAllHealButtonUnitEvents();

	return;

end



--
function VUHDO_initUnitEventHandler()

	VUHDO_buildSpecialUnitList();
	VUHDO_buildSpecialUnitTokens();
	VUHDO_createSpecialUnitFrames();
	VUHDO_refreshSpecialUnitFrames();

	return;

end