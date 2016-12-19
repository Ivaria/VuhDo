local pairs = pairs;

local VUHDO_TRACE_SPELLS = {
	[1064] = { -- Chain Heal
		["mine"] = true,
		["others"] = false,
	},
	[200128] = { -- Trail of Light
		["mine"] = true,
		["others"] = false,
	},
	[34861] = { -- Holy Word: Sanctify
		["mine"] = true,
		["others"] = false,
	},
	[596] = { -- Prayer of Healing
		["mine"] = true,
		["others"] = false,
	},
	[194509] = { -- Power Word: Radiance
		["mine"] = true,
		["others"] = false,
	},
	[132157] = { -- Holy Nova
		["mine"] = true,
		["others"] = false,
	},
};

local VUHDO_ACTIVE_TRACE_SPELLS = { 
	-- [<unit GUID>] = {
	--	["latest"] = <latest trace spell ID>,
	--	["spells"] = {
	--		[<spell ID>] = {
	--			["icon"] = <spell icon>,
	--			["duration"] = <duration of trace>,
	--		},
	--	},
	-- },
};



--
local VUHDO_PLAYER_GUID = -1;
local VUHDO_RAID_GUIDS = { };
local VUHDO_INTERNAL_TOGGLES = { };
local sShowSpellTrace = nil;
function VUHDO_spellTraceInitLocalOverrides()

	VUHDO_PLAYER_GUID = UnitGUID("player");
	VUHDO_RAID_GUIDS = _G["VUHDO_RAID_GUIDS"];
	VUHDO_INTERNAL_TOGGLES = _G["VUHDO_INTERNAL_TOGGLES"];
	sShowSpellTrace = VUHDO_CONFIG["SHOW_SPELL_TRACE"];

end



--
function VUHDO_parseCombatLogSpellTrace(aMessage, aSrcGuid, aDstGuid, aSpellName, aSpellId)

	if not VUHDO_INTERNAL_TOGGLES[37] or not sShowSpellTrace or 
		aMessage ~= "SPELL_HEAL" or not VUHDO_TRACE_SPELLS[aSpellId] or 
		(aSrcGuid ~= VUHDO_PLAYER_GUID and not VUHDO_TRACE_SPELLS[aSpellId]["others"]) or 
		(aSrcGuid == VUHDO_PLAYER_GUID and not VUHDO_TRACE_SPELLS[aSpellId]["mine"]) or 
		not VUHDO_RAID_GUIDS[aDstGuid] then
		return;
	end

	if not VUHDO_ACTIVE_TRACE_SPELLS[aDstGuid] or not VUHDO_ACTIVE_TRACE_SPELLS[aDstGuid]["spells"] or 
		not VUHDO_ACTIVE_TRACE_SPELLS[aDstGuid]["spells"][aSpellId] then
		local tName, _, tIcon = GetSpellInfo(aSpellId);

		if not tName then
			return;
		end

		if not VUHDO_ACTIVE_TRACE_SPELLS[aDstGuid] then
			VUHDO_ACTIVE_TRACE_SPELLS[aDstGuid] = { 
				["spells"] = { },
			};
		end

		VUHDO_ACTIVE_TRACE_SPELLS[aDstGuid]["spells"][aSpellId] = {
			["icon"] = tIcon,
		};
	end

	VUHDO_ACTIVE_TRACE_SPELLS[aDstGuid]["spells"][aSpellId]["duration"] = 0.1;
	VUHDO_ACTIVE_TRACE_SPELLS[aDstGuid]["latest"] = aSpellId;

	VUHDO_updateBouquetsForEvent(VUHDO_RAID_GUIDS[aDstGuid], VUHDO_UPDATE_SPELL_TRACE);

end



--
function VUHDO_updateSpellTrace(aTimeDelta)

	for tUnitGuid, tActiveTrace in pairs(VUHDO_ACTIVE_TRACE_SPELLS) do
		local i = 0;
		local tActiveTraceSpells = tActiveTrace["spells"];

		for tSpellId, tActiveTraceSpell in pairs(tActiveTraceSpells) do
			if tActiveTraceSpell then
				local tDuration = tActiveTraceSpell["duration"] - aTimeDelta;
	
				if tDuration <= 0 then
					VUHDO_ACTIVE_TRACE_SPELLS[tUnitGuid]["spells"][tSpellId] = nil;

					if tActiveTrace["latest"] == tSpellId then
						VUHDO_ACTIVE_TRACE_SPELLS[tUnitGuid]["latest"] = nil;
					end

					local tUnit = VUHDO_RAID_GUIDS[tUnitGuid];

					if tUnit then
						VUHDO_updateBouquetsForEvent(tUnit, VUHDO_UPDATE_SPELL_TRACE);
					end
				else
					VUHDO_ACTIVE_TRACE_SPELLS[tUnitGuid]["spells"][tSpellId]["duration"] = tDuration;
				end

				i = i + 1;
			end
		end

		if not i then
			VUHDO_ACTIVE_TRACE_SPELLS[tUnitGuid] = nil;
		end
	end

end



--
function VUHDO_getSpellTraceForUnit(aUnit)

	if not VUHDO_INTERNAL_TOGGLES[37] or not sShowSpellTrace or not aUnit then
		return;
	end

	local tUnitGuid = UnitGUID(aUnit);

	if not tUnitGuid or not VUHDO_ACTIVE_TRACE_SPELLS[tUnitGuid] then
		return;
	end

	local tLatestTraceSpellId = VUHDO_ACTIVE_TRACE_SPELLS[tUnitGuid]["latest"];

	if tLatestTraceSpellId then
		return VUHDO_ACTIVE_TRACE_SPELLS[tUnitGuid]["spells"][tLatestTraceSpellId];
	end

end

