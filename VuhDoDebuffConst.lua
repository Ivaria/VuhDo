local GetSpellName = C_Spell.GetSpellName;

--
VUHDO_DEBUFF_TYPE_NONE = 0;
VUHDO_DEBUFF_TYPE_POISON = 1;
VUHDO_DEBUFF_TYPE_DISEASE = 2;
VUHDO_DEBUFF_TYPE_MAGIC = 3;
VUHDO_DEBUFF_TYPE_CURSE = 4;
VUHDO_DEBUFF_TYPE_CUSTOM = 6;
VUHDO_DEBUFF_TYPE_MISSING_BUFF = 7;
VUHDO_DEBUFF_TYPE_BLEED = 8;
VUHDO_DEBUFF_TYPE_ENRAGE = 9;



--
VUHDO_INIT_PURGE_ABILITIES = {
	["WARRIOR"] = { },
	["ROGUE"] = {
		[VUHDO_DEBUFF_TYPE_ENRAGE] = { 5938 }, -- VUHDO_SPELL_ID.SHIV
	},
	["HUNTER"] = {
		[VUHDO_DEBUFF_TYPE_MAGIC] = { 19801 }, -- VUHDO_SPELL_ID.TRANQUILIZING_SHOT
		[VUHDO_DEBUFF_TYPE_ENRAGE] = { 19801 }, -- VUHDO_SPELL_ID.TRANQUILIZING_SHOT
	},
	["MAGE"] = {
		[VUHDO_DEBUFF_TYPE_MAGIC] = { 30449 }, -- VUHDO_SPELL_ID.SPELLSTEAL
	},
	["DRUID"] = {
		[VUHDO_DEBUFF_TYPE_ENRAGE] = { 2908 }, -- VUHDO_SPELL_ID.SOOTHE
	},
	["PALADIN"] = { },
	["PRIEST"] = {
		[VUHDO_DEBUFF_TYPE_MAGIC] = { 528 }, -- VUHDO_SPELL_ID.DISPEL_MAGIC
	},
	["SHAMAN"] = {
		[VUHDO_DEBUFF_TYPE_MAGIC] = { 370, 378773 }, -- VUHDO_SPELL_ID.PURGE, VUHDO_SPELL_ID.GREATER_PURGE
	},
	["WARLOCK"] = {
		[VUHDO_DEBUFF_TYPE_MAGIC] = { "*" }, -- VUHDO_SPELL_ID.DEVOUR_MAGIC 19505
	},
	["DEATHKNIGHT"] = { },
	["MONK"] = {
		[VUHDO_DEBUFF_TYPE_ENRAGE] = { 450432 }, -- VUHDO_SPELL_ID.PRESSURE_POINTS
	},
	["DEMONHUNTER"] = {
		[VUHDO_DEBUFF_TYPE_MAGIC] = { 278326 }, -- VUHDO_SPELL_ID.CONSUME_MAGIC
	},
	["EVOKER"] = {
		[VUHDO_DEBUFF_TYPE_ENRAGE] = { 406971 }, -- VUHDO_SPELL_ID.OPPRESSING_ROAR (Overawe talent)
	},
};



--
VUHDO_INIT_DISPEL_ABILITIES = {
	["WARRIOR"] = { },
	["ROGUE"] = { },
	["HUNTER"] = { },
	["MAGE"] = {
		[VUHDO_DEBUFF_TYPE_CURSE] = { 475 }, -- VUHDO_SPELL_ID.REMOVE_LESSER_CURSE 
	},
	["DRUID"] = {
		[VUHDO_DEBUFF_TYPE_POISON] = { 2893, 8946 }, -- VUHDO_SPELL_ID.ABOLISH_POISON, VUHDO_SPELL_ID.CURE_POISON_DRUID
		[VUHDO_DEBUFF_TYPE_CURSE] = { 2782 }, -- VUHDO_SPELL_ID.REMOVE_CURSE
	},
	["PALADIN"] = {
		[VUHDO_DEBUFF_TYPE_POISON] = { 1152, 4987 }, -- VUHDO_SPELL_ID.PURIFY, VUHDO_SPELL_ID.PALA_CLEANSE
		[VUHDO_DEBUFF_TYPE_DISEASE] = { 1152, 4987 }, -- VUHDO_SPELL_ID.PURIFY, VUHDO_SPELL_ID.PALA_CLEANSE
		[VUHDO_DEBUFF_TYPE_MAGIC] = { 4987 }, -- VUHDO_SPELL_ID.PALA_CLEANSE
		[VUHDO_DEBUFF_TYPE_BLEED] = { 1022 }, -- VUHDO_SPELL_ID.BLESSING_OF_PROTECTION
	},
	["PRIEST"] = {
		[VUHDO_DEBUFF_TYPE_DISEASE] = { 552, 528 }, -- VUHDO_SPELL_ID.ABOLISH_DISEASE, VUHDO_SPELL_ID.CURE_DISEASE_PRIEST
		[VUHDO_DEBUFF_TYPE_MAGIC] = { 527 }, -- VUHDO_SPELL_ID.DISPEL_MAGIC
	},
	["SHAMAN"] = {
		[VUHDO_DEBUFF_TYPE_DISEASE] = { 2870 }, -- VUHDO_SPELL_ID.CURE_DISEASE_SHAMAN
		[VUHDO_DEBUFF_TYPE_POISON] = { 526 }, -- VUHDO_SPELL_ID.CURE_POISON_SHAMAN
	},
	["WARLOCK"] = {
		[VUHDO_DEBUFF_TYPE_MAGIC] = { "*" },
	},
	["DEATHKNIGHT"] = { },
	["MONK"] = {
		-- Monk has two dispel spells with the same name ("Detox") so need to reference by ID
		[VUHDO_DEBUFF_TYPE_POISON] = { 218164, 115450 },
		[VUHDO_DEBUFF_TYPE_DISEASE] = { 218164, 115450 },
		[VUHDO_DEBUFF_TYPE_MAGIC] = { 115450 }, -- Now Mistweaver "Detox" only
	},
	["DEMONHUNTER"] = { },
	["EVOKER"] = {
		-- Evoker 'Expunge' morphs into 'Naturalize' for Preservation spec
		-- Mapping needed for VUHDO_isSpellKnown() by name so use spell ID to force check by IsSpellKnown()
		[VUHDO_DEBUFF_TYPE_POISON] = { 360823, 365585, 374251 }, -- VUHDO_SPELL_ID.NATURALIZE, VUHDO_SPELL_ID.EXPUNGE, VUHDO_SPELL_ID.CAUTERIZING_FLAME
		[VUHDO_DEBUFF_TYPE_MAGIC] = { 360823 }, -- VUHDO_SPELL_ID.NATURALIZE
		[VUHDO_DEBUFF_TYPE_CURSE] = { 374251 }, -- VUHDO_SPELL_ID.CAUTERIZING_FLAME
		[VUHDO_DEBUFF_TYPE_DISEASE] = { 374251 }, -- VUHDO_SPELL_ID.CAUTERIZING_FLAME
		[VUHDO_DEBUFF_TYPE_BLEED] = { 374251 }, -- VUHDO_SPELL_ID.CAUTERIZING_FLAME
	},
};



VUHDO_SPEC_TO_DEBUFF_ABIL = { 
	[115450] = GetSpellName(115450), -- MW Monk "Detox"
	[218164] = GetSpellName(218164), -- WW/BM Monk "Detox"
	[360823] = GetSpellName(360823), -- Preservation Evoker "Naturalize" (morphed "Expunge")
	[390632] = GetSpellName(527), -- Priest 'Improved Purify' must be mapped to 'Purify'
	[378773] = GetSpellName(370), -- Shaman 'Greater Purge' must be mapped to 'Purge'
};



VUHDO_INIT_IGNORE_DEBUFFS_BY_CLASS = {
	["WARRIOR"] = {
		[VUHDO_SPELL_ID.DEBUFF_ANCIENT_HYSTERIA] = true,
		[VUHDO_SPELL_ID.DEBUFF_IGNITE_MANA] = true,
		[VUHDO_SPELL_ID.DEBUFF_TAINTED_MIND] = true,
		[VUHDO_SPELL_ID.DEBUFF_VIPER_STING] = true,
		[VUHDO_SPELL_ID.DEBUFF_IMPOTENCE] = true,
		[VUHDO_SPELL_ID.DEBUFF_DECAYED_INT] = true,
		[VUHDO_SPELL_ID.DEBUFF_UNSTABLE_AFFL] = true,
	},
	["ROGUE"] = {
		[VUHDO_SPELL_ID.DEBUFF_SILENCE] = true,
		[VUHDO_SPELL_ID.DEBUFF_ANCIENT_HYSTERIA] = true,
		[VUHDO_SPELL_ID.DEBUFF_IGNITE_MANA] = true,
		[VUHDO_SPELL_ID.DEBUFF_TAINTED_MIND] = true,
		[VUHDO_SPELL_ID.DEBUFF_VIPER_STING] = true,
		[VUHDO_SPELL_ID.DEBUFF_IMPOTENCE] = true,
		[VUHDO_SPELL_ID.DEBUFF_DECAYED_INT] = true,
		[VUHDO_SPELL_ID.DEBUFF_UNSTABLE_AFFL] = true,
		[VUHDO_SPELL_ID.DEBUFF_SONIC_BURST] = true,
	},
	["HUNTER"] = {
		[VUHDO_SPELL_ID.DEBUFF_MAGMA_SHACKLES] = true,
		[VUHDO_SPELL_ID.DEBUFF_UNSTABLE_AFFL] = true,
		[VUHDO_SPELL_ID.DEBUFF_SONIC_BURST] = true,
	},
	["MAGE"] = {
		[VUHDO_SPELL_ID.DEBUFF_MAGMA_SHACKLES] = true,
		[VUHDO_SPELL_ID.DEBUFF_DECAYED_STR] = true,
		[VUHDO_SPELL_ID.DEBUFF_CRIPPLE] = true,
		[VUHDO_SPELL_ID.DEBUFF_UNSTABLE_AFFL] = true,
		--[(GetSpellName(87923))] = true, -- MOP okay Wind Blast (TBCC: MoP-specific, commented out)
	},
	["DRUID"] = {
		[VUHDO_SPELL_ID.DEBUFF_UNSTABLE_AFFL] = true,
	},
	["PALADIN"] = {
		[VUHDO_SPELL_ID.DEBUFF_UNSTABLE_AFFL] = true,
	},
	["PRIEST"] = {
		[VUHDO_SPELL_ID.DEBUFF_DECAYED_STR] = true,
		[VUHDO_SPELL_ID.DEBUFF_CRIPPLE] = true,
		[VUHDO_SPELL_ID.DEBUFF_UNSTABLE_AFFL] = true,
		--[(GetSpellName(87923))] = true, -- MOP okay Wind Blast (TBCC: MoP-specific, commented out)
	},
	["SHAMAN"] = {
		[VUHDO_SPELL_ID.DEBUFF_UNSTABLE_AFFL] = true,
	},
	["WARLOCK"] = {
		[VUHDO_SPELL_ID.DEBUFF_DECAYED_STR] = true,
		[VUHDO_SPELL_ID.DEBUFF_CRIPPLE] = true,
		[VUHDO_SPELL_ID.DEBUFF_UNSTABLE_AFFL] = true,
		--[(GetSpellName(87923))] = true, -- MOP okay Wind Blast (TBCC: MoP-specific, commented out)
	},
	["DEATHKNIGHT"] = {
		[VUHDO_SPELL_ID.DEBUFF_UNSTABLE_AFFL] = true,
	},
	["MONK"] = {
		[VUHDO_SPELL_ID.DEBUFF_UNSTABLE_AFFL] = true,
	},
	["DEMONHUNTER"] = {
		[VUHDO_SPELL_ID.DEBUFF_UNSTABLE_AFFL] = true,
	},
	["EVOKER"] = {
		[VUHDO_SPELL_ID.DEBUFF_UNSTABLE_AFFL] = true,
	},
};



--
VUHDO_INIT_IGNORE_DEBUFFS_MOVEMENT = {
	[VUHDO_SPELL_ID.DEBUFF_FROSTBOLT] = true,
	[VUHDO_SPELL_ID.DEBUFF_MAGMA_SHACKLES] = true,
	[VUHDO_SPELL_ID.DEBUFF_SLOW] = true,
	[VUHDO_SPELL_ID.DEBUFF_CHILLED] = true,
	[VUHDO_SPELL_ID.DEBUFF_CONEOFCOLD] = true,
	[VUHDO_SPELL_ID.DEBUFF_CONCUSSIVESHOT] = true,
	[VUHDO_SPELL_ID.DEBUFF_THUNDERCLAP] = true,
	[VUHDO_SPELL_ID.DEBUFF_DAZED] = true,
	[VUHDO_SPELL_ID.DEBUFF_FROST_SHOCK] = true,
	[VUHDO_SPELL_ID.FROSTBOLT_VOLLEY] = true,
	--[(GetSpellName(88184))] = true, -- MOP okay Lethargic Poison (TBCC: MoP-specific, commented out)
	--[(GetSpellName(87759))] = true, -- MOP okay Shockwave (TBCC: MoP-specific, commented out)
	--[(GetSpellName(88075))] = true, -- MOP okay Typhoon (TBCC: MoP-specific, commented out)
	--[(GetSpellName(90938))] = true, -- MOP okay Bloodbolt (TBCC: MoP-specific, commented out)
	--[(GetSpellName(92007))] = true, -- MOP okay Swirling Vapor (TBCC: MoP-specific, commented out)
	--[(GetSpellName(88169))] = true, -- MOP okay Frost Blossom (TBCC: MoP-specific, commented out)
	--[(GetSpellName(87861))] = true, -- MOP okay Fists of Frost (TBCC: MoP-specific, commented out)
	--[(GetSpellName(83776))] = true, -- MOP okay Dragon's Breath (TBCC: MoP-specific, commented out)
	--[(GetSpellName(7964))] = true, --  MOP okay Smoke Bomb (TBCC: MoP-specific, commented out)
	--[(GetSpellName(83785))] = true, -- MOP okay Shockwave (TBCC: MoP-specific, commented out)
	--[(GetSpellName(81630))] = true, -- MOP okay Viscous Poison (TBCC: MoP-specific, commented out)
	--[(GetSpellName(82764))] = true, -- MOP okay Wing Clip (TBCC: MoP-specific, commented out)
	--[(GetSpellName(76825))] = true, -- MOP okay Ice Blast (TBCC: MoP-specific, commented out)
	--[(GetSpellName(73963))] = true, -- MOP okay Blinding Toxin (TBCC: MoP-specific, commented out)
	--[(GetSpellName(76508))] = true, -- MOP okay Frostbolt (TBCC: MoP-specific, commented out)
	--[(GetSpellName(76682))] = true, -- MOP okay Frostbomb (TBCC: MoP-specific, commented out)
	--[(GetSpellName(12611))] = true, -- MOP okay Cone of Cold (TBCC: MoP-specific, commented out)
	--[(GetSpellName(76094))] = true, -- MOP okay Curse of Fatigue (TBCC: MoP-specific, commented out)
	--[(GetSpellName(76604))] = true, -- MOP okay Void Rip (TBCC: MoP-specific, commented out)
};



--
VUHDO_INIT_IGNORE_DEBUFFS_DURATION = {
	[VUHDO_SPELL_ID.DEBUFF_PSYCHIC_HORROR] = true,
	[VUHDO_SPELL_ID.DEBUFF_CHILLED] = true,
	[VUHDO_SPELL_ID.DEBUFF_CONEOFCOLD] = true,
	[VUHDO_SPELL_ID.DEBUFF_CONCUSSIVESHOT] = true,
	[VUHDO_SPELL_ID.DEBUFF_FALTER] = true,
	--[(GetSpellName(87759))] = true, -- MOP okay Shockwave
	--[(GetSpellName(90938))] = true, -- MOP okay Bloodbolt
	--[(GetSpellName(92007))] = true, -- MOP pkay Swirling Vapor
	--[(GetSpellName(83776))] = true, -- MOP okay Dragon's Breath
	--[(GetSpellName(7964))] = true, -- MOP okay Smoke Bomb
	--[(GetSpellName(83785))] = true, -- MOP okay Shockwave
	--[(GetSpellName(81630))] = true, -- MOP okay Viscous Poison
	--[(GetSpellName(82670))] = true, -- MOP okay Skull Crack
	--[(GetSpellName(73963))] = true, -- MOP okay Blinding Toxin
	--[(GetSpellName(76508))] = true, -- MOP okay Frostbolt
	--[(GetSpellName(76185))] = true, -- MOP okay Stone Blow
};



VUHDO_INIT_IGNORE_DEBUFFS_NO_HARM = {
	[VUHDO_SPELL_ID.DEBUFF_HUNTERS_MARK] = true,
	[VUHDO_SPELL_ID.DEBUFF_ARCANE_CHARGE] = true,
	[VUHDO_SPELL_ID.DEBUFF_MAJOR_DREAMLESS] = true,
	[VUHDO_SPELL_ID.DEBUFF_GREATER_DREAMLESS] = true,
	[VUHDO_SPELL_ID.DEBUFF_DREAMLESS_SLEEP] = true,
	[VUHDO_SPELL_ID.MISDIRECTION] = true,
	[VUHDO_SPELL_ID.DEBUFF_DELUSIONS_OF_JINDO] = true,
	[VUHDO_SPELL_ID.DEBUFF_MIND_VISION] = true,
	[VUHDO_SPELL_ID.DEBUFF_MUTATING_INJECTION] = true,
	[VUHDO_SPELL_ID.DEBUFF_BANISH] = true,
	[VUHDO_SPELL_ID.DEBUFF_PHASE_SHIFT] = true,
	--[(GetSpellName(41425))] = true, -- Hypothermia
	--[(GetSpellName(123981))] = true, -- Perdition
	--[(GetSpellName(53753))] = true, -- Nightmare Slumber
	--[(GetSpellName(78993))] = true, -- Concentration
	--[(GetSpellName(105701))] = true, -- Potion of Focus
	--[(GetSpellName(57724))] = true, -- Sated
	--[(GetSpellName(57723))] = true, -- Exhaustion
	--[(GetSpellName(80354))] = true, -- Temporal Displacement
	--[VUHDO_SPELL_ID.DEBUFF_FATIGUED] = true,
	--[(GetSpellName(95809))] = true, -- Insanity
};

