VUHDO_ACTIVE_HOTS = { };
VUHDO_ACTIVE_HOTS_OTHERS = { };
VUHDO_PLAYER_HOTS = { };

VUHDO_SPELL_TYPE_HOT = 1;  -- Spell type heal over time



local twipe = table.wipe;
local pairs = pairs;



--
VUHDO_SPELLS = {
	-- Paladin

	-- Priest
	[VUHDO_SPELL_ID.RENEW] = { ["isHot"] = true, },
	[VUHDO_SPELL_ID.POWERWORD_SHIELD] = { ["isHot"] = true, },

	-- Shaman
	[VUHDO_SPELL_ID.BUFF_EARTH_SHIELD] = { ["isHot"] = true, },

	-- Druid
	[VUHDO_SPELL_ID.REJUVENATION] = { ["isHot"] = true, },
	[VUHDO_SPELL_ID.REGROWTH] = { ["isHot"] = true, },

	-- Hunter
	[VUHDO_SPELL_ID.MEND_PET] = { ["isHot"] = true, },

	-- Monk

	-- Mage
	[VUHDO_SPELL_ID.ICE_BARRIER] = { ["isHot"] = true, },

	-- Evoker
};
local VUHDO_SPELLS = VUHDO_SPELLS;



-- initializes some dynamic information into VUHDO_SPELLS
function VUHDO_initFromSpellbook()

	twipe(VUHDO_PLAYER_HOTS);

	for tSpellName, someParams in pairs(VUHDO_SPELLS) do
		if someParams["isHot"] and (VUHDO_isSpellKnown(tSpellName) or VUHDO_isTalentKnown(tSpellName)) then
			VUHDO_PLAYER_HOTS[#VUHDO_PLAYER_HOTS + 1] = tSpellName;
		end
	end

	if "PRIEST" == VUHDO_PLAYER_CLASS then
		VUHDO_PLAYER_HOTS[#VUHDO_PLAYER_HOTS + 1] = VUHDO_SPELL_ID.ECHO_OF_LIGHT;
		VUHDO_PLAYER_HOTS[#VUHDO_PLAYER_HOTS + 1] = VUHDO_SPELL_ID.SPIRIT_SHELL;
	end

	if "DRUID" == VUHDO_PLAYER_CLASS then
		VUHDO_PLAYER_HOTS[#VUHDO_PLAYER_HOTS + 1] = VUHDO_SPELL_ID.GERMINATION;
		VUHDO_PLAYER_HOTS[#VUHDO_PLAYER_HOTS + 1] = VUHDO_SPELL_ID.SPRING_BLOSSOMS;
	end

	twipe(VUHDO_ACTIVE_HOTS);
	twipe(VUHDO_ACTIVE_HOTS_OTHERS);

	for tPanelNum = 1, 10 do -- VUHDO_MAX_PANELS
		local tHotSlots = VUHDO_PANEL_SETUP[tPanelNum]["HOTS"]["SLOTS"];

		if tHotSlots["firstFlood"] then
			tHotSlots["firstFlood"] = nil;

			for tCnt = 1, #VUHDO_PLAYER_HOTS do
				if not (VUHDO_SPELLS[VUHDO_PLAYER_HOTS[tCnt]] or { })["nodefault"] then
					if tCnt < 6 then
						tinsert(tHotSlots, VUHDO_PLAYER_HOTS[tCnt]);
					elseif tCnt > 8 then
						tinsert(tHotSlots, VUHDO_PLAYER_HOTS[tCnt - 3]);
					end

					if #tHotSlots == 12 then -- VUHDO_MAX_HOTS
						break;
					end
				end
			end
		end

		local tHotCfg = VUHDO_PANEL_SETUP[tPanelNum]["HOTS"]["SLOTCFG"];

		if tHotCfg["firstFlood"] then
			for tCnt = 1, #tHotSlots do
				tHotCfg["" .. tCnt]["others"] = VUHDO_EXCLUSIVE_HOTS[tHotSlots[tCnt]];
			end

			tHotCfg["firstFlood"] = nil;
		end

		for tCnt = #tHotSlots + 1, 12 do -- VUHDO_MAX_HOTS
			tinsert(tHotSlots, "");
		end

		for tCnt, tHotName in pairs(tHotSlots) do
			if not VUHDO_strempty(tHotName) then
				VUHDO_ACTIVE_HOTS[tHotName] = true;

				if tHotCfg["" .. tCnt]["others"] then
					VUHDO_ACTIVE_HOTS_OTHERS[tHotName] = true;
				end
			end
		end
	end

	VUHDO_initTalentSpellCaches();
	VUHDO_initRuneSpellCaches();

	VUHDO_setKnowsSwiftmend(VUHDO_isSpellKnown(VUHDO_SPELL_ID.SWIFTMEND));
	VUHDO_setKnowsTrailOfLight(VUHDO_isTalentKnown(VUHDO_SPELL_ID.TRAIL_OF_LIGHT));

end
