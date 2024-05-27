local huge = math.huge;



local VUHDO_CUSTOM_DEBUFF_CONFIG = { };
local VUHDO_UNIT_CUSTOM_DEBUFFS = { };
setmetatable(VUHDO_UNIT_CUSTOM_DEBUFFS, VUHDO_META_NEW_ARRAY);
local VUHDO_LAST_UNIT_DEBUFFS = { };
local VUHDO_PLAYER_ABILITIES = { };



local VUHDO_IGNORE_DEBUFFS_BY_CLASS = { };
local VUHDO_IGNORE_DEBUFF_NAMES = { };



--
local VUHDO_DEBUFF_TYPES = {
	["Magic"] = VUHDO_DEBUFF_TYPE_MAGIC,
	["Disease"] = VUHDO_DEBUFF_TYPE_DISEASE,
	["Poison"] = VUHDO_DEBUFF_TYPE_POISON,
	["Curse"] = VUHDO_DEBUFF_TYPE_CURSE
};




VUHDO_DEBUFF_BLACKLIST = {
	[GetSpellInfo(69127)] = true, -- Chill of the Throne
	[GetSpellInfo(57724)] = true, -- Sated (Bloodlust)
	[GetSpellInfo(71328)] = true, -- Dungeon Cooldown
	[GetSpellInfo(57723)] = true, -- Exhaustion (Heroism)
	[GetSpellInfo(80354)] = true, -- Temporal Displacement (Time Warp)
	[VUHDO_SPELL_ID.DEBUFF_FATIGUED] = true -- Fatigued (Primal Fury)
};





-- BURST CACHE ---------------------------------------------------

local VUHDO_CONFIG;
local VUHDO_RAID;
local VUHDO_PANEL_SETUP;
local VUHDO_DEBUFF_COLORS = { };

local VUHDO_shouldScanUnit;
local VUHDO_DEBUFF_BLACKLIST = { };

local UnitIsFriend = UnitIsFriend;
local table = table;
local GetTime = GetTime;
local PlaySoundFile = PlaySoundFile;
local InCombatLockdown = InCombatLockdown;
local twipe = table.wipe;
local pairs = pairs;
local _;
local tostring = tostring;
local ForEachAura = AuraUtil.ForEachAura or VUHDO_forEachAura;
local UnpackAuraData = AuraUtil.UnpackAuraData or VUHDO_unpackAuraData;
local GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID;

local sIsNotRemovableOnly;
local sIsNotRemovableOnlyIcons;
local sIsUseDebuffIcon;
local sIsUseDebuffIconBossOnly;
local sIsMiBuColorsInFight;
local sStdDebuffSound;
local sAllDebuffSettings;
local sIsShowOnlyForFriendly;
local sEmpty = { };
--local sColorArray = nil;

function VUHDO_debuffsInitLocalOverrides()
	VUHDO_CONFIG = _G["VUHDO_CONFIG"];
	VUHDO_RAID = _G["VUHDO_RAID"];
	VUHDO_PANEL_SETUP = _G["VUHDO_PANEL_SETUP"];
	VUHDO_DEBUFF_BLACKLIST = _G["VUHDO_DEBUFF_BLACKLIST"];

	VUHDO_shouldScanUnit = _G["VUHDO_shouldScanUnit"];

	sIsNotRemovableOnly = not VUHDO_CONFIG["DETECT_DEBUFFS_REMOVABLE_ONLY"];
	sIsNotRemovableOnlyIcons = not VUHDO_CONFIG["DETECT_DEBUFFS_REMOVABLE_ONLY_ICONS"];
	sIsUseDebuffIcon = VUHDO_PANEL_SETUP["BAR_COLORS"]["useDebuffIcon"];
	sIsUseDebuffIconBossOnly = VUHDO_PANEL_SETUP["BAR_COLORS"]["useDebuffIconBossOnly"];
	sIsMiBuColorsInFight = VUHDO_BUFF_SETTINGS["CONFIG"]["BAR_COLORS_IN_FIGHT"];
	sStdDebuffSound = VUHDO_CONFIG["SOUND_DEBUFF"];
	sAllDebuffSettings = VUHDO_CONFIG["CUSTOM_DEBUFF"]["STORED_SETTINGS"];
	sIsShowOnlyForFriendly = VUHDO_CONFIG["CUSTOM_DEBUFF"]["isShowOnlyForFriendly"];

	VUHDO_DEBUFF_COLORS = {
		[1] = VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF1"],
		[2] = VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF2"],
		[3] = VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF3"],
		[4] = VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF4"],
		[6] = VUHDO_PANEL_SETUP["BAR_COLORS"]["DEBUFF6"],
	};

	--[[if not sColorArray then
		sColorArray = { };
		for tCnt = 1, 40 do
			sColorArray[tCnt] = { };
		end
	end]]
end

----------------------------------------------------



--
local function VUHDO_copyColorTo(aSource, aDest)
	aDest["R"], aDest["G"], aDest["B"] = aSource["R"], aSource["G"], aSource["B"];
	aDest["TR"], aDest["TG"], aDest["TB"] = aSource["TR"], aSource["TG"], aSource["TB"];
	aDest["O"], aDest["TO"] = aSource["O"], aSource["TO"];
	aDest["useText"], aDest["useBackground"], aDest["useOpacity"] = aSource["useText"], aSource["useBackground"], aSource["useOpacity"];
	return aDest;
end



--
local tSourceColor;
local tDebuffSettings;
local tDebuff;
local tColor = { };
local tEmpty = { };
function _VUHDO_getDebuffColor(anInfo)

	if anInfo["charmed"] then
		return VUHDO_PANEL_SETUP["BAR_COLORS"]["CHARMED"];
	end

	tDebuff = anInfo["debuff"];

	if not anInfo["mibucateg"] and (tDebuff or 0) == 0 then -- VUHDO_DEBUFF_TYPE_NONE
		return tEmpty;
	end

	if (tDebuff or 6) ~= 6 and VUHDO_DEBUFF_COLORS[tDebuff] then -- VUHDO_DEBUFF_TYPE_CUSTOM
		return VUHDO_DEBUFF_COLORS[tDebuff];
	end

	tDebuffSettings = sAllDebuffSettings[anInfo["debuffName"]];

	if tDebuff == 6 and tDebuffSettings ~= nil -- VUHDO_DEBUFF_TYPE_CUSTOM
		and tDebuffSettings["isColor"] then
		if tDebuffSettings["color"] ~= nil then
			tSourceColor = tDebuffSettings["color"];
		else
			tSourceColor = VUHDO_DEBUFF_COLORS[6];
		end

		twipe(tColor);

		if VUHDO_DEBUFF_COLORS[6]["useBackground"] then
			tColor["R"], tColor["G"], tColor["B"], tColor["O"], tColor["useBackground"] = tSourceColor["R"], tSourceColor["G"], tSourceColor["B"], tSourceColor["O"], true;
		end

		if VUHDO_DEBUFF_COLORS[6]["useText"] then
			tColor["TR"], tColor["TG"], tColor["TB"], tColor["TO"], tColor["useText"] = tSourceColor["TR"], tSourceColor["TG"], tSourceColor["TB"], tSourceColor["TO"], true;
		end

		return tColor;
	end

	if not anInfo["mibucateg"] or not VUHDO_BUFF_SETTINGS[anInfo["mibucateg"]] then	return tEmpty; end

	tSourceColor = VUHDO_BUFF_SETTINGS[anInfo["mibucateg"]]["missingColor"];
	twipe(tColor);
	if VUHDO_BUFF_SETTINGS["CONFIG"]["BAR_COLORS_TEXT"] then
		tColor["useText"], tColor["TR"], tColor["TG"], tColor["TB"], tColor["TO"] = true, tSourceColor["TR"], tSourceColor["TG"], tSourceColor["TB"], tSourceColor["TO"];
	end

	if VUHDO_BUFF_SETTINGS["CONFIG"]["BAR_COLORS_BACKGROUND"] then
		tColor["useBackground"], tColor["R"], tColor["G"], tColor["B"], tColor["O"] = true, tSourceColor["R"], tSourceColor["G"], tSourceColor["B"], tSourceColor["O"];
	end

	return tColor;
end



--
local tCopy = { };
function VUHDO_getDebuffColor(anInfo)
	return VUHDO_copyColorTo(_VUHDO_getDebuffColor(anInfo), tCopy);
end



--
local tNextSoundTime = 0;
local function VUHDO_playDebuffSound(aSound, aDebuffName)
	if (aSound or "") == "" or GetTime() < tNextSoundTime then
		return;
	end

	local tSuccess = VUHDO_playSoundFile(aSound);

	if tSuccess then
		tNextSoundTime = GetTime() + 2;
	else
		if aDebuffName then
			VUHDO_Msg(format(VUHDO_I18N_PLAY_SOUND_FILE_CUSTOM_DEBUFF_ERR, aSound, aDebuffName));
		else
			VUHDO_Msg(format(VUHDO_I18N_PLAY_SOUND_FILE_DEBUFF_ERR, aSound));
		end
	end
end



--
local VUHDO_UNIT_DEBUFF_INFOS = { };
setmetatable(VUHDO_UNIT_DEBUFF_INFOS, {
	__index = function(aTable, aKey)
	  local tValue = {
			["CHOSEN"] = { [1] = nil, [2] = 0 },
			[VUHDO_DEBUFF_TYPE_POISON] = { },
			[VUHDO_DEBUFF_TYPE_DISEASE] = { },
			[VUHDO_DEBUFF_TYPE_MAGIC] = { },
			[VUHDO_DEBUFF_TYPE_CURSE] = { },
		};

		rawset(aTable, aKey, tValue);
		return tValue;
	end
});



-- debuff type, aura name, aura spell Id, isStandard: true|false
local VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT = { VUHDO_DEBUFF_TYPE_NONE, "", nil, false };

local sCurChosenInfo = {
	-- [<unit ID>] = {
	--	[<aura instance ID>] = {
	--		VUHDO_DEBUFF_TYPE_<NONE|POISON|DISEASE|MAGIC|CURSE|CUSTOM|MISSING_BUFF>,
	--		<aura spell Id>,
	--		<aura name>,
	--		<isStandard: true|false>,
	--	},
	-- },
};

local sCurChosenListHead = { };
local sCurChosen = { };
local sCurIcons = { };



--
local tCurChosenPrev;
local function VUHDO_addCurChosen(aUnit, anAuraInstanceId, aType, aName, aSpellId, anIsStandard)

	if sCurChosenInfo[aUnit][anAuraInstanceId] then
		if aType ~= nil then
			sCurChosenInfo[aUnit][anAuraInstanceId][1] = aType;
			sCurChosen[aUnit][1] = aType;
		end

		if aName ~= nil then
			sCurChosenInfo[aUnit][anAuraInstanceId][2] = aName;
			sCurChosen[aUnit][2] = aName;
		end

		if aSpellId ~= nil then
			sCurChosenInfo[aUnit][anAuraInstanceId][3] = aSpellId;
			sCurChosen[aUnit][3] = aSpellId;
		end

		if anIsStandard ~= nil then
			sCurChosenInfo[aUnit][anAuraInstanceId][4] = anIsStandard;
			sCurChosen[aUnit][4] = anIsStandard;
		end
	else
		sCurChosenInfo[aUnit][anAuraInstanceId] = {
			aType or VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[1],
			aName or VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[2],
			aSpellId or VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[3],
			(anIsStandard ~= nil) and anIsStandard or VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[4]
		};

		tCurChosenPrev = sCurChosenListHead[aUnit];

		sCurChosenListHead[aUnit] = { ["auraInstanceId"] = anAuraInstanceId };

		if tCurChosenPrev then
			sCurChosenListHead[aUnit]["prev"] = tCurChosenPrev;
			tCurChosenPrev["next"] = sCurChosenListHead[aUnit];
		end

		sCurChosen[aUnit][1], sCurChosen[aUnit][2], sCurChosen[aUnit][3], sCurChosen[aUnit][4] =
			aType or sCurChosen[aUnit][1] or VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[1],
			aName or sCurChosen[aUnit][2] or VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[2],
			aSpellId or sCurChosen[aUnit][3] or VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[3],
			(anIsStandard ~= nil) and anIsStandard or (sCurChosen[aUnit][4] or VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[4]);
	end

end



--
local tCurChosen;
local tCurChosenPrev;
local tCurChosenNext;
local function VUHDO_removeCurChosen(aUnit, anAuraInstanceId)

	if not sCurChosenInfo[aUnit][anAuraInstanceId] then
		return;
	end

	tCurChosen = sCurChosenListHead[aUnit];

	while tCurChosen and tCurChosen["auraInstanceId"] do
		if tCurChosen["auraInstanceId"] == anAuraInstanceId then
			tCurChosenPrev = tCurChosen["prev"];
			tCurChosenNext = tCurChosen["next"];

			if tCurChosenPrev and not tCurChosenNext then
				-- remove head
				tCurChosenPrev["next"] = nil;

				sCurChosenListHead[aUnit] = tCurChosenPrev;
			elseif tCurChosenPrev and tCurChosenNext then
				-- remove link
				tCurChosenNext["prev"] = tCurChosenPrev;
				tCurChosenPrev["next"] = tCurChosenNext;
			elseif not tCurChosenPrev and tCurChosenNext then
				-- remove tail
				tCurChosenNext["prev"] = nil;
			else
				sCurChosenListHead[aUnit] = nil;
			end

			sCurChosenInfo[aUnit][anAuraInstanceId] = nil;

			tCurChosen = nil;
		else
			tCurChosen = tCurChosen["prev"];
		end
	end

end



--
local tAuraInstanceId;
local function VUHDO_getCurChosenInfo(aUnit)

	if not sCurChosenListHead[aUnit] or not sCurChosenInfo[aUnit] then
		return;
	end

	tAuraInstanceId = sCurChosenListHead[aUnit]["auraInstanceId"];

	if not tAuraInstanceId then
		return;
	end

	return sCurChosenInfo[aUnit][tAuraInstanceId];

end



--
local tCurChosen;
local tCurChosenInfo;
local function VUHDO_updateCurChosen(aUnit)

	sCurChosen[aUnit][1], sCurChosen[aUnit][2], sCurChosen[aUnit][3], sCurChosen[aUnit][4] =
		VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[1], VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[2],
		VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[3], VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[4];

	tCurChosen = sCurChosenListHead[aUnit];

	while tCurChosen and tCurChosen["auraInstanceId"] do
		tCurChosenInfo = sCurChosenInfo[aUnit][tCurChosen["auraInstanceId"]];

		if tCurChosenInfo then
			if tCurChosenInfo[1] and sCurChosen[aUnit][1] == VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[1] then
				sCurChosen[aUnit][1] = tCurChosenInfo[1];
			end

			if tCurChosenInfo[2] and sCurChosen[aUnit][2] == VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[2] then
				sCurChosen[aUnit][2] = tCurChosenInfo[2];
			end

			if tCurChosenInfo[3] and sCurChosen[aUnit][3] == VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[3] then
				sCurChosen[aUnit][3] = tCurChosenInfo[3];
			end

			if tCurChosenInfo[4] and sCurChosen[aUnit][4] == VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[4] then
				sCurChosen[aUnit][4] = tCurChosenInfo[4];
			end
		end

		tCurChosen = tCurChosen["prev"];
	end

end



--
local tUnitDebuffInfo;
local function VUHDO_initDebuffInfos(aUnit)

	tUnitDebuffInfo = VUHDO_UNIT_DEBUFF_INFOS[aUnit];
	tUnitDebuffInfo[1][2] = nil; -- VUHDO_DEBUFF_TYPE_POISON
	tUnitDebuffInfo[2][2] = nil; -- VUHDO_DEBUFF_TYPE_DISEASE
	tUnitDebuffInfo[3][2] = nil; -- VUHDO_DEBUFF_TYPE_MAGIC
	tUnitDebuffInfo[4][2] = nil; -- VUHDO_DEBUFF_TYPE_CURSE

	if not sCurChosenInfo[aUnit] then
		sCurChosenInfo[aUnit] = { };
	else
		for tAuraInstanceId, _ in pairs(sCurChosenInfo[aUnit]) do
			sCurChosenInfo[aUnit][tAuraInstanceId] = nil;
		end
	end

	sCurChosenListHead[aUnit] = nil;

	if not sCurChosen[aUnit] then
		sCurChosen[aUnit] = { };
	end

	sCurChosen[aUnit][1], sCurChosen[aUnit][2], sCurChosen[aUnit][3], sCurChosen[aUnit][4] =
		VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[1], VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[2],
		VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[3], VUHDO_DEBUFF_CUR_CHOSEN_DEFAULT[4];

	if not sCurIcons[aUnit] then
		sCurIcons[aUnit] = { };
	else
		for tAuraInstanceId, _ in pairs(sCurIcons[aUnit]) do
			sCurIcons[aUnit][tAuraInstanceId] = nil;
		end
	end

	if not VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit] then
		VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit] = { };
	else
		for tAuraInstanceId, _ in pairs(VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit]) do
			VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId] = nil;
		end
	end

	return tUnitDebuffInfo;

end



--
local tIconArray;
local function VUHDO_getOrCreateIconArray(aUnit, anIcon, anExpiry, aStacks, aDuration, anIsBuff, aSpellId, anAuraInstanceId, aName)

	if not sCurIcons[aUnit] then
		sCurIcons[aUnit] = { };
	end

	if not sCurIcons[aUnit][anAuraInstanceId] then
		tIconArray = { anIcon, anExpiry, aStacks, aDuration, anIsBuff, aSpellId, anAuraInstanceId, aName };
	else
		tIconArray = sCurIcons[aUnit][anAuraInstanceId];

		tIconArray[1], tIconArray[2], tIconArray[3], tIconArray[4], tIconArray[5], tIconArray[6], tIconArray[7], tIconArray[8]
			= anIcon, anExpiry, aStacks, aDuration, anIsBuff, aSpellId, anAuraInstanceId, aName;
	end

	return tIconArray;

end



--
local sUnit;
local sNow;
local sUnitDebuffInfo;

local tDebuffConfig;
local tIsShown;
local tInfo;
local tType;
local tAbility;
local tIsRelevant;
local tSchool;
local tRemaining;
local function VUHDO_determineDebuffPredicate(anAuraInstanceId, aName, anIcon, aStacks, aTypeString, aDuration, anExpiry, aUnitCaster, aSpellId, anIsBossDebuff, anIsUpdate)

	if not anIcon then
		return;
	end

	if (anExpiry or 0) == 0 then
		anExpiry = (sCurIcons[sUnit][anAuraInstanceId] or sEmpty)[2] or sNow;
	end

	-- Custom Debuff?
	tDebuffConfig = VUHDO_CUSTOM_DEBUFF_CONFIG[aName] or VUHDO_CUSTOM_DEBUFF_CONFIG[tostring(aSpellId)] or sEmpty;
	tIsShown = false;

	-- Color?
	if not anIsUpdate and tDebuffConfig[1] and ((tDebuffConfig[3] and aUnitCaster == "player") or (tDebuffConfig[4] and aUnitCaster ~= "player")) then
		VUHDO_addCurChosen(sUnit, anAuraInstanceId, 6, aName, aSpellId, false); -- VUHDO_DEBUFF_TYPE_CUSTOM

		tIsShown = true;
	end

	aStacks = aStacks or 0;

	if tDebuffConfig[2] and ((tDebuffConfig[3] and aUnitCaster == "player") or (tDebuffConfig[4] and aUnitCaster ~= "player")) then -- Icon?
		sCurIcons[sUnit][anAuraInstanceId] = VUHDO_getOrCreateIconArray(sUnit, anIcon, anExpiry, aStacks, aDuration, false, aSpellId, anAuraInstanceId, aName);

		tIsShown = true;
	end

	tType = VUHDO_DEBUFF_TYPES[aTypeString];
	tAbility = VUHDO_PLAYER_ABILITIES[tType] and UnitIsFriend("player", sUnit);
	tIsRelevant = not VUHDO_IGNORE_DEBUFF_NAMES[aName]
		and not (VUHDO_IGNORE_DEBUFFS_BY_CLASS[tInfo["class"] or ""] or sEmpty)[aName];

	if tType and tIsRelevant then
		tSchool = sUnitDebuffInfo[tType];
		tRemaining = floor(anExpiry - sNow);

		if (tSchool[2] or 0) < tRemaining then
			tSchool[1], tSchool[2], tSchool[3], tSchool[4] = anIcon, tRemaining, aStacks, aDuration;
		end
	end

	if not tIsShown and not VUHDO_DEBUFF_BLACKLIST[aName] and not VUHDO_DEBUFF_BLACKLIST[tostring(aSpellId)] and tIsRelevant then
		if sIsUseDebuffIcon and (anIsBossDebuff or not sIsUseDebuffIconBossOnly)
			and (sIsNotRemovableOnlyIcons or tAbility ~= nil) then
			sCurIcons[sUnit][anAuraInstanceId] = VUHDO_getOrCreateIconArray(sUnit, anIcon, anExpiry, aStacks, aDuration, false, aSpellId, anAuraInstanceId, aName);

			if not anIsUpdate then
				VUHDO_addCurChosen(sUnit, anAuraInstanceId, nil, nil, nil, true);
			end
		end

		-- Entweder Fähigkeit vorhanden ODER noch keiner gewählt UND auch nicht entfernbare
		-- Either ability available OR none selected AND not removable (DETECT_DEBUFFS_REMOVABLE_ONLY)
		if tType and (tAbility or (sCurChosen[sUnit][1] == 0 and sIsNotRemovableOnly)) then -- VUHDO_DEBUFF_TYPE_NONE
			if not anIsUpdate then
				VUHDO_addCurChosen(sUnit, anAuraInstanceId, tType, nil, nil, nil);
			end

			sUnitDebuffInfo["CHOSEN"][1], sUnitDebuffInfo["CHOSEN"][2] = anIcon, aStacks;
		end
	end

end



--
local function VUHDO_determineBuffPredicate(anAuraInstanceId, aName, anIcon, aStacks, aDuration, anExpiry, aUnitCaster, aSpellId, anIsUpdate)

	if not anIcon then
		return;
	end

	tDebuffConfig = VUHDO_CUSTOM_DEBUFF_CONFIG[aName] or VUHDO_CUSTOM_DEBUFF_CONFIG[tostring(aSpellId)] or sEmpty;

	if not anIsUpdate and tDebuffConfig[1] and ((tDebuffConfig[3] and aUnitCaster == "player") or (tDebuffConfig[4] and aUnitCaster ~= "player")) then -- Color?
		VUHDO_addCurChosen(sUnit, anAuraInstanceId, 6, aName, aSpellId, false); -- VUHDO_DEBUFF_TYPE_CUSTOM
	end

	if tDebuffConfig[2] and ((tDebuffConfig[3] and aUnitCaster == "player") or (tDebuffConfig[4] and aUnitCaster ~= "player")) then -- Icon?
		sCurIcons[sUnit][anAuraInstanceId] = VUHDO_getOrCreateIconArray(sUnit, anIcon, anExpiry, aStacks or 0, aDuration, true, aSpellId, anAuraInstanceId, aName);
	end

end



--
function VUHDO_determineAuraPredicate(anAuraData, anIsUpdate)

	if anAuraData and anAuraData.isHarmful then
		VUHDO_determineDebuffPredicate(
			anAuraData.auraInstanceID,
			anAuraData.name,
			anAuraData.icon,
			anAuraData.applications,
			anAuraData.dispelName,
			anAuraData.duration,
			anAuraData.expirationTime,
			anAuraData.sourceUnit,
			anAuraData.spellId,
			anAuraData.isBossAura,
			anIsUpdate
		);
	elseif anAuraData and anAuraData.isHelpful then
		VUHDO_determineBuffPredicate(
			anAuraData.auraInstanceID,
			anAuraData.name,
			anAuraData.icon,
			anAuraData.applications,
			anAuraData.duration,
			anAuraData.expirationTime,
			anAuraData.sourceUnit,
			anAuraData.spellId,
			anIsUpdate
		);
	end

end



--
local tCurChosenStoredName;
function VUHDO_getDeterminedDebuffInfo(aUnit)

	if not sAllDebuffSettings or not sCurChosen or not sCurChosen[aUnit] then
		return;
	end

	-- we need to return the actual key that the debuff settings are stored under
	-- this key is either the debuff name or the debuff spell ID
	if sAllDebuffSettings[sCurChosen[aUnit][2]] ~= nil then
		tCurChosenStoredName = sCurChosen[aUnit][2];
	elseif sAllDebuffSettings[tostring(sCurChosen[aUnit][3] or -1)] ~= nil then
		tCurChosenStoredName = tostring(sCurChosen[aUnit][3]);
	end

	return sCurChosen[aUnit][1], tCurChosenStoredName;

end



--
local tAura;
local tDoUpdate;
local tName;
local tDebuffSettings;
local tCurChosenInfo;
local tDoStdSound;
function VUHDO_determineDebuff(aUnit, aUpdateInfo)

	tInfo = (VUHDO_RAID or sEmpty)[aUnit];

	if not tInfo then
		return 0, ""; -- VUHDO_DEBUFF_TYPE_NONE
	elseif VUHDO_CONFIG_SHOW_RAID then
		return tInfo["debuff"], tInfo["debuffName"];
	end

	if VUHDO_shouldScanUnit(aUnit) then
		sUnit = aUnit;
		sNow = GetTime();

		if not aUpdateInfo or (aUpdateInfo and aUpdateInfo.isFullUpdate) then
			sUnitDebuffInfo = VUHDO_initDebuffInfos(aUnit);

			ForEachAura(aUnit, "HARMFUL", nil, VUHDO_determineAuraPredicate, true);
			ForEachAura(aUnit, "HELPFUL", nil, VUHDO_determineAuraPredicate, true);
		elseif aUpdateInfo then
			sUnitDebuffInfo = (sCurIcons[aUnit] and sCurChosen[aUnit]) and VUHDO_UNIT_DEBUFF_INFOS[aUnit] or VUHDO_initDebuffInfos(aUnit);

			if aUpdateInfo.addedAuras then
				for _, tAuraData in pairs(aUpdateInfo.addedAuras) do
					VUHDO_determineAuraPredicate(tAuraData);
				end
			end

			if aUpdateInfo.updatedAuraInstanceIDs then
				for _, tAuraInstanceId in pairs(aUpdateInfo.updatedAuraInstanceIDs) do
					tAura = GetAuraDataByAuraInstanceID(aUnit, tAuraInstanceId);

					if tAura then
						VUHDO_determineAuraPredicate(tAura, true);
					end
				end
			end

			if aUpdateInfo.removedAuraInstanceIDs then
				tDoUpdate = false;

				for _, tAuraInstanceId in pairs(aUpdateInfo.removedAuraInstanceIDs) do
					if sCurIcons[aUnit] and sCurIcons[aUnit][tAuraInstanceId] then
						sCurIcons[aUnit][tAuraInstanceId] = nil;

						if sCurChosenInfo[aUnit] and sCurChosenInfo[aUnit][tAuraInstanceId] then
							VUHDO_removeCurChosen(aUnit, tAuraInstanceId);

							tDoUpdate = true;
						end
					end
				end

				if tDoUpdate then
					VUHDO_updateCurChosen(aUnit);
				end
			end
		end

		tDoStdSound = false;

		-- Gained new custom debuff?
		-- note we only play sounds for debuff customs with isIcon set to true
		if sCurIcons[aUnit] then
			for tAuraInstanceId, tDebuffInfo in pairs(sCurIcons[aUnit]) do
				tName = tDebuffInfo[8];

				if not VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId] then
					if not sIsShowOnlyForFriendly or UnitIsFriend("player", aUnit) then
						-- tExpiry, tStacks, tIcon, tAuraInstanceId, tName
						VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId] = {
							tDebuffInfo[2], tDebuffInfo[3], tDebuffInfo[1], tDebuffInfo[7], tName
						};

						VUHDO_addDebuffIcon(aUnit, tDebuffInfo[1], tName, tDebuffInfo[2], tDebuffInfo[3], tDebuffInfo[4], tDebuffInfo[5], tDebuffInfo[6], tDebuffInfo[7]);

						if not VUHDO_IS_CONFIG and VUHDO_MAY_DEBUFF_ANIM then
							-- the key used to store the debuff settings is either the debuff name or spell ID
							tDebuffSettings = sAllDebuffSettings[tName] or sAllDebuffSettings[tostring(tDebuffInfo[6])];

							if tDebuffSettings then -- particular custom debuff sound?
								VUHDO_playDebuffSound(tDebuffSettings["SOUND"], tName);
							elseif VUHDO_CONFIG["CUSTOM_DEBUFF"]["SOUND"] then -- default custom debuff sound?
								VUHDO_playDebuffSound(VUHDO_CONFIG["CUSTOM_DEBUFF"]["SOUND"], tName);
							end
						end

						tCurChosenInfo = sCurChosenInfo[aUnit][tAuraInstanceId];

						if sStdDebuffSound and tCurChosenInfo
							and (tCurChosenInfo[1] ~= VUHDO_DEBUFF_TYPE_NONE or tCurChosenInfo[4])
							and tCurChosenInfo[1] ~= VUHDO_DEBUFF_TYPE_CUSTOM
							and tCurChosenInfo[1] ~= VUHDO_LAST_UNIT_DEBUFFS[aUnit]
							and tInfo["range"] then
								VUHDO_LAST_UNIT_DEBUFFS[aUnit] = tCurChosenInfo[1];
								tDoStdSound = true;
						end

						VUHDO_updateBouquetsForEvent(aUnit, 29); -- VUHDO_UPDATE_CUSTOM_DEBUFF
					end
				-- update number of stacks?
				elseif VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId] and
					(VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId][1] ~= tDebuffInfo[2]
					or VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId][2] ~= tDebuffInfo[3]
					or VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId][3] ~= tDebuffInfo[1]
					or VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId][4] ~= tDebuffInfo[7]
					or VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId][5] ~= tName) then
					VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId][1] = tDebuffInfo[2];
					VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId][2] = tDebuffInfo[3];
					VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId][3] = tDebuffInfo[1];
					VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId][4] = tDebuffInfo[7];
					VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId][5] = tName;

					VUHDO_updateDebuffIcon(aUnit, tDebuffInfo[1], tName, tDebuffInfo[2], tDebuffInfo[3], tDebuffInfo[4], tDebuffInfo[5], tDebuffInfo[6], tDebuffInfo[7]);

					VUHDO_updateBouquetsForEvent(aUnit, 29); -- VUHDO_UPDATE_CUSTOM_DEBUFF
				end
			end
		end

		-- Play standard debuff sound?
		if sStdDebuffSound and tDoStdSound then
			VUHDO_playDebuffSound(sStdDebuffSound);
		end
	end -- shouldScanUnit

	-- Lost old custom debuff?
	for tAuraInstanceId, tUnitCustomDebuff in pairs(VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit]) do
		if tUnitCustomDebuff and (not sCurIcons[aUnit] or not sCurIcons[aUnit][tAuraInstanceId]) then
			VUHDO_removeDebuffIcon(aUnit, tUnitCustomDebuff[5]);
			VUHDO_UNIT_CUSTOM_DEBUFFS[aUnit][tAuraInstanceId] = nil;

			VUHDO_updateBouquetsForEvent(aUnit, 29); -- VUHDO_UPDATE_CUSTOM_DEBUFF
		end
	end

	if sCurChosen[aUnit][1] == VUHDO_DEBUFF_TYPE_NONE and tInfo["missbuff"] and (sIsMiBuColorsInFight or not InCombatLockdown()) then
		sCurChosen[aUnit][1] = VUHDO_DEBUFF_TYPE_MISSING_BUFF;
	end

	return VUHDO_getDeterminedDebuffInfo(aUnit);

end

local VUHDO_determineDebuff = VUHDO_determineDebuff;



--
function VUHDO_updateAllCustomDebuffs(anIsEnableAnim)

	twipe(VUHDO_UNIT_CUSTOM_DEBUFFS);

	VUHDO_MAY_DEBUFF_ANIM = false;

	for tUnit, tInfo in pairs(VUHDO_RAID) do
		VUHDO_removeAllDebuffIcons(tUnit);
		tInfo["debuff"], tInfo["debuffName"] = VUHDO_determineDebuff(tUnit);
	end

	VUHDO_MAY_DEBUFF_ANIM = anIsEnableAnim;

end



-- Remove debuffing abilities individually not known to the player
function VUHDO_initDebuffs()
	local tAbility;

	local _, tClass = UnitClass("player");
	twipe(VUHDO_PLAYER_ABILITIES);

	for tDebuffType, tAbilities in pairs(VUHDO_INIT_DEBUFF_ABILITIES[tClass] or sEmpty) do
		for tCnt = 1, #tAbilities do
			tAbility = tAbilities[tCnt];

--			VUHDO_Msg("check: " .. tAbility);
			if VUHDO_isSpellKnown(tAbility) or tAbility == "*" then
				if VUHDO_SPEC_TO_DEBUFF_ABIL[tAbility] then
					tAbility = VUHDO_SPEC_TO_DEBUFF_ABIL[tAbility];
				elseif type(tAbility) == "number" then
					tAbility = GetSpellInfo(tAbility);
				end

				VUHDO_PLAYER_ABILITIES[tDebuffType] = tAbility;

--				VUHDO_Msg("KEEP: Type " .. tDebuffType .. " because of spell " .. VUHDO_PLAYER_ABILITIES[tDebuffType]);
				break;
			end
		end
	end
--	VUHDO_Msg("---");

	if not VUHDO_CONFIG then VUHDO_CONFIG = _G["VUHDO_CONFIG"]; end

	twipe(VUHDO_CUSTOM_DEBUFF_CONFIG);

	for _, tDebuffName in pairs(VUHDO_CONFIG["CUSTOM_DEBUFF"]["STORED"]) do
		if not VUHDO_CUSTOM_DEBUFF_CONFIG[tDebuffName] then
			VUHDO_CUSTOM_DEBUFF_CONFIG[tDebuffName] = { };
		end

		VUHDO_CUSTOM_DEBUFF_CONFIG[tDebuffName][1] = VUHDO_CONFIG["CUSTOM_DEBUFF"]["STORED_SETTINGS"][tDebuffName]["isColor"];
		VUHDO_CUSTOM_DEBUFF_CONFIG[tDebuffName][2] = VUHDO_CONFIG["CUSTOM_DEBUFF"]["STORED_SETTINGS"][tDebuffName]["isIcon"];

		if VUHDO_CONFIG["CUSTOM_DEBUFF"]["STORED_SETTINGS"][tDebuffName]["isMine"] == nil then
			VUHDO_CONFIG["CUSTOM_DEBUFF"]["STORED_SETTINGS"][tDebuffName]["isMine"] = true;
		end

		VUHDO_CUSTOM_DEBUFF_CONFIG[tDebuffName][3] = VUHDO_CONFIG["CUSTOM_DEBUFF"]["STORED_SETTINGS"][tDebuffName]["isMine"];

		if VUHDO_CONFIG["CUSTOM_DEBUFF"]["STORED_SETTINGS"][tDebuffName]["isOthers"] == nil then
			VUHDO_CONFIG["CUSTOM_DEBUFF"]["STORED_SETTINGS"][tDebuffName]["isOthers"] = true;
		end

		VUHDO_CUSTOM_DEBUFF_CONFIG[tDebuffName][4] = VUHDO_CONFIG["CUSTOM_DEBUFF"]["STORED_SETTINGS"][tDebuffName]["isOthers"];
	end

	for tDebuffName, _ in pairs(VUHDO_CUSTOM_DEBUFF_CONFIG) do
		if not VUHDO_CONFIG["CUSTOM_DEBUFF"]["STORED_SETTINGS"][tDebuffName] then
			VUHDO_CUSTOM_DEBUFF_CONFIG[tDebuffName] = nil;
		end
	end

	twipe(VUHDO_IGNORE_DEBUFF_NAMES);

	if VUHDO_CONFIG["DETECT_DEBUFFS_IGNORE_NO_HARM"] then
		VUHDO_IGNORE_DEBUFFS_BY_CLASS = VUHDO_INIT_IGNORE_DEBUFFS_BY_CLASS;
		VUHDO_tableAddAllKeys(VUHDO_IGNORE_DEBUFF_NAMES, VUHDO_INIT_IGNORE_DEBUFFS_NO_HARM);
	else
		VUHDO_IGNORE_DEBUFFS_BY_CLASS = sEmpty;
	end

	if VUHDO_CONFIG["DETECT_DEBUFFS_IGNORE_MOVEMENT"] then
		VUHDO_tableAddAllKeys(VUHDO_IGNORE_DEBUFF_NAMES, VUHDO_INIT_IGNORE_DEBUFFS_MOVEMENT);
	end

	if VUHDO_CONFIG["DETECT_DEBUFFS_IGNORE_DURATION"] then
		VUHDO_tableAddAllKeys(VUHDO_IGNORE_DEBUFF_NAMES, VUHDO_INIT_IGNORE_DEBUFFS_DURATION);
	end
end



--
function VUHDO_getDebuffAbilities()
	return VUHDO_PLAYER_ABILITIES;
end



--
function VUHDO_getUnitDebuffSchoolInfos(aUnit, aDebuffSchool)
	return VUHDO_UNIT_DEBUFF_INFOS[aUnit][aDebuffSchool];
end


--
function VUHDO_getChosenDebuffInfo(aUnit)
	return VUHDO_UNIT_DEBUFF_INFOS[aUnit]["CHOSEN"];
end



--
function VUHDO_resetDebuffsFor(aUnit)
	VUHDO_initDebuffInfos(aUnit);
end



--
function VUHDO_getUnitCustomDebuffs()
	
	return VUHDO_UNIT_CUSTOM_DEBUFFS;

end



--
function VUHDO_getDebuffCurIcons()

	return sCurIcons;

end



--
function VUHDO_getDebuffCurChosenInfo()

	return sCurChosenInfo;

end



--
function VUHDO_getDebuffCurChosenListHead()

	return sCurChosenListHead;

end



--
function VUHDO_getDebuffCurChosen()

	return sCurChosen;

end
