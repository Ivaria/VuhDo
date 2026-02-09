local _;

local pairs = pairs;
local ipairs = ipairs;
local tinsert = table.insert;
local tsort = table.sort;
local strfind = string.find;

VUHDO_AURA_GROUPS_SELECTED = VUHDO_AURA_GROUPS_SELECTED or nil;
VUHDO_AURA_GROUPS_COMBO_MODEL = VUHDO_AURA_GROUPS_COMBO_MODEL or { };
VUHDO_PANEL_AURA_GROUPS_COMBO_MODEL = VUHDO_PANEL_AURA_GROUPS_COMBO_MODEL or { };
VUHDO_AURA_GROUPS_FILTER_SELECTED = VUHDO_AURA_GROUPS_FILTER_SELECTED or "";
VUHDO_AURA_GROUPS_EXCLUDE_SELECTED = VUHDO_AURA_GROUPS_EXCLUDE_SELECTED or "";
VUHDO_AURA_GROUPS_PRIORITY = VUHDO_AURA_GROUPS_PRIORITY or 50;
VUHDO_AURA_GROUPS_CAN_COLOR_BAR = VUHDO_AURA_GROUPS_CAN_COLOR_BAR or false;
VUHDO_AURA_GROUPS_CAN_COLOR_TEXT = VUHDO_AURA_GROUPS_CAN_COLOR_TEXT or false;
VUHDO_AURA_GROUPS_ENABLED = VUHDO_AURA_GROUPS_ENABLED or true;

VUHDO_AURA_FILTER_OPTIONS = {
	{ "HELPFUL", _G["VUHDO_I18N_AURA_GROUP_ALL_BUFFS"] or "All Buffs" },
	{ "HARMFUL", _G["VUHDO_I18N_AURA_GROUP_ALL_DEBUFFS"] or "All Debuffs" },
	{ "HELPFUL|PLAYER|RAID_IN_COMBAT", _G["VUHDO_I18N_AURA_GROUP_MY_HOTS"] or "My HoTs" },
	{ "HELPFUL|RAID_IN_COMBAT", _G["VUHDO_I18N_AURA_GROUP_ALL_HOTS"] or "All HoTs" },
	{ "HARMFUL|RAID_PLAYER_DISPELLABLE", _G["VUHDO_I18N_AURA_FILTER_HARMFUL_DISPELLABLE"] or "Dispellable" },
	{ "HARMFUL|CROWD_CONTROL", _G["VUHDO_I18N_AURA_GROUP_CC"] or "CC Effects" },
	{ "HELPFUL|BIG_DEFENSIVE", _G["VUHDO_I18N_AURA_GROUP_BIG_DEF"] or "Big Defensives" },
	{ "HELPFUL|RAID|PLAYER", _G["VUHDO_I18N_AURA_GROUP_MY_BUFFS"] or "My Raid Buffs" },
	{ "HELPFUL|RAID", _G["VUHDO_I18N_AURA_GROUP_ALL_RAID_BUFFS"] or "All Raid Buffs" },
	{ "HARMFUL|RAID", _G["VUHDO_I18N_AURA_GROUP_RAID_DEBUFFS"] or "Raid Debuffs" },
	{ "HELPFUL|IMPORTANT", _G["VUHDO_I18N_AURA_GROUP_IMPORTANT_BUFFS"] or "Important Buffs" },
	{ "HARMFUL|IMPORTANT", _G["VUHDO_I18N_AURA_GROUP_IMPORTANT_DEBUFFS"] or "Important Debuffs" },
	{ "HELPFUL|CANCELABLE", _G["VUHDO_I18N_AURA_GROUP_CANCELABLE"] or "Cancelable Buffs" },
	{ "HELPFUL|NOT_CANCELABLE", _G["VUHDO_I18N_AURA_GROUP_NOT_CANCELABLE"] or "Not Cancelable Buffs" },
	{ "HELPFUL|MAW", _G["VUHDO_I18N_AURA_GROUP_TORGHAST_ANIMA"] or "Torghast Anima Powers" },
	{ "HARMFUL|INCLUDE_NAME_PLATE_ONLY|PLAYER", _G["VUHDO_I18N_AURA_GROUP_MY_NAMEPLATE"] or "My Nameplate Debuffs" },
	{ "HARMFUL|INCLUDE_NAME_PLATE_ONLY", _G["VUHDO_I18N_AURA_GROUP_ALL_NAMEPLATE"] or "All Nameplate Debuffs" },
};

VUHDO_AURA_EXCLUDE_FILTER_OPTIONS = {
	{ "", _G["VUHDO_I18N_AURA_FILTER_NONE"] or "(None)" },
	{ "PLAYER", _G["VUHDO_I18N_PLAYER"] or "Player" },
};

local sSelectedGroupId = nil;



--
local tAllGroups;
local tDisplayName;
local tSortTable;
function VUHDO_initAuraGroupsComboModel()

	table.wipe(VUHDO_AURA_GROUPS_COMBO_MODEL);

	tAllGroups = VUHDO_getAllAuraGroups();

	if not tAllGroups then
		return;
	end

	tSortTable = { };

	for tGroupId, tGroup in pairs(tAllGroups) do
		tDisplayName = VUHDO_getAuraGroupDisplayName(tGroupId);

		tinsert(tSortTable, { tGroupId, tDisplayName });
	end

	tsort(tSortTable, function(anA, anotherA) return anA[2] < anotherA[2]; end);

	for _, tEntry in ipairs(tSortTable) do
		tinsert(VUHDO_AURA_GROUPS_COMBO_MODEL, { tEntry[1], tEntry[2] });
	end

	return;

end



--
local tAllGroups;
local tDisplayName;
local tSortTable;
function VUHDO_initPanelAuraGroupsComboModel()

	table.wipe(VUHDO_PANEL_AURA_GROUPS_COMBO_MODEL);

	tAllGroups = VUHDO_getAllAuraGroups();

	if not tAllGroups then
		return;
	end

	tSortTable = { };

	for tGroupId, _ in pairs(tAllGroups) do
		if VUHDO_getAuraGroup(tGroupId) then
			tDisplayName = VUHDO_getAuraGroupDisplayName(tGroupId);

			tinsert(tSortTable, { tGroupId, tDisplayName });
		end
	end

	tsort(tSortTable, function(anA, anotherA) return anA[2] < anotherA[2]; end);

	for _, tEntry in ipairs(tSortTable) do
		tinsert(VUHDO_PANEL_AURA_GROUPS_COMBO_MODEL, { tEntry[1], tEntry[2] });
	end

	return;

end



--
function VUHDO_auraGroupsComboChanged(aComboBox, aValue, anArrayModel)

	VUHDO_AURA_GROUPS_SELECTED = aValue;
	sSelectedGroupId = aValue;

	VUHDO_auraGroupsRefreshRightPanel();

	return;

end



--
local tGroupCombo;
function VUHDO_auraGroupsRefreshList()

	VUHDO_initAuraGroupsComboModel();

	tGroupCombo = _G["VuhDoNewOptionsAuraGroupsStorePanelGroupCombo"];
	if tGroupCombo then
		VUHDO_lnfComboBoxInitFromModel(tGroupCombo);
	end

	return;

end



--
function VUHDO_auraGroupsListDropdownInitFromModel()

	return;

end



--
function VUHDO_auraGroupsOnGroupSelected(aGroupId)

	sSelectedGroupId = aGroupId;
	VUHDO_AURA_GROUPS_SELECTED = aGroupId;

	VUHDO_auraGroupsRefreshRightPanel();

	return;

end



--
local tGroup;
local tNameEditBox;
local tFilterCombo;
local tExcludeFilterCombo;
local tPrioritySlider;
local tCanColorBarCheck;
local tCanColorTextCheck;
local tEnabledCheck;
local tDeleteButton;
local tIsBuiltIn;
function VUHDO_auraGroupsRefreshRightPanel()

	tGroup = sSelectedGroupId and VUHDO_getAuraGroupRaw(sSelectedGroupId) or nil;
	tIsBuiltIn = tGroup and VUHDO_isBuiltInAuraGroup(sSelectedGroupId);

	tNameEditBox = _G["VuhDoNewOptionsAuraGroupsStorePanelNameEditBox"];
	tFilterCombo = _G["VuhDoNewOptionsAuraGroupsStorePanelFilterCombo"];
	tExcludeFilterCombo = _G["VuhDoNewOptionsAuraGroupsStorePanelExcludeFilterCombo"];
	tPrioritySlider = _G["VuhDoNewOptionsAuraGroupsStorePanelPrioritySlider"];
	tCanColorBarCheck = _G["VuhDoNewOptionsAuraGroupsStorePanelCanColorBarCheckButton"];
	tCanColorTextCheck = _G["VuhDoNewOptionsAuraGroupsStorePanelCanColorTextCheckButton"];
	tDeleteButton = _G["VuhDoNewOptionsAuraGroupsStorePanelDeleteButton"];

	if tDeleteButton then
		if tGroup and not tIsBuiltIn then
			tDeleteButton:Enable();
			tDeleteButton:SetAlpha(1);
		else
			tDeleteButton:Disable();
			tDeleteButton:SetAlpha(0.5);
		end
	end

	if tNameEditBox then
		if tGroup then
			tNameEditBox:Show();
			if tIsBuiltIn then
				tNameEditBox:SetText(VUHDO_getAuraGroupDisplayName(sSelectedGroupId) or "");
				tNameEditBox:Disable();
				tNameEditBox:SetAlpha(0.5);
			else
				tNameEditBox:SetText(tGroup["displayName"] or "");
				tNameEditBox:Enable();
				tNameEditBox:SetAlpha(1);
			end
		else
			tNameEditBox:SetText("");
			tNameEditBox:Hide();
		end
	end

	if tFilterCombo and tGroup then
		tFilterCombo:SetShown(true);
		VUHDO_AURA_GROUPS_FILTER_SELECTED = tGroup["filter"] or "";
		VUHDO_lnfComboBoxInitFromModel(tFilterCombo);
		tFilterCombo:Enable();
		tFilterCombo:SetAlpha(1);
		if tIsBuiltIn then
			tFilterCombo:Disable();
			tFilterCombo:SetAlpha(0.5);
		end
	end

	if tExcludeFilterCombo and tGroup then
		tExcludeFilterCombo:SetShown(true);
		VUHDO_AURA_GROUPS_EXCLUDE_SELECTED = tGroup["excludeFilter"] or "";
		VUHDO_lnfComboBoxInitFromModel(tExcludeFilterCombo);
		tExcludeFilterCombo:Enable();
		tExcludeFilterCombo:SetAlpha(1);
		if tIsBuiltIn then
			tExcludeFilterCombo:Disable();
			tExcludeFilterCombo:SetAlpha(0.5);
		end
	end

	if tPrioritySlider and tGroup then
		tPrioritySlider:SetShown(true);
		VUHDO_AURA_GROUPS_PRIORITY = tGroup["priority"] or 50;
		local tInnerSlider = _G[tPrioritySlider:GetName() .. "Slider"];
		VUHDO_lnfSliderInitFromModel(tInnerSlider);
		tInnerSlider:Enable();
		tPrioritySlider:SetAlpha(1);
		if tIsBuiltIn then
			tInnerSlider:Disable();
			tPrioritySlider:SetAlpha(0.5);
		end
	end

	if tCanColorBarCheck and tGroup then
		tCanColorBarCheck:SetShown(true);
		VUHDO_AURA_GROUPS_CAN_COLOR_BAR = tGroup["canColorBar"];
		VUHDO_lnfCheckButtonInitFromModel(tCanColorBarCheck);
		tCanColorBarCheck:Enable();
		tCanColorBarCheck:SetAlpha(1);
		if tIsBuiltIn then
			tCanColorBarCheck:Disable();
			tCanColorBarCheck:SetAlpha(0.5);
		end
	end

	if tCanColorTextCheck and tGroup then
		tCanColorTextCheck:SetShown(true);
		VUHDO_AURA_GROUPS_CAN_COLOR_TEXT = tGroup["canColorText"];
		VUHDO_lnfCheckButtonInitFromModel(tCanColorTextCheck);
		tCanColorTextCheck:Enable();
		tCanColorTextCheck:SetAlpha(1);
		if tIsBuiltIn then
			tCanColorTextCheck:Disable();
			tCanColorTextCheck:SetAlpha(0.5);
		end
	end

	tEnabledCheck = _G["VuhDoNewOptionsAuraGroupsStorePanelEnabledCheckButton"];

	if tEnabledCheck and tGroup then
		tEnabledCheck:SetShown(true);

		if tIsBuiltIn then
			VUHDO_AURA_GROUPS_ENABLED = not (VUHDO_CONFIG["AURA_GROUP_DISABLED"] and VUHDO_CONFIG["AURA_GROUP_DISABLED"][sSelectedGroupId]);
		else
			VUHDO_AURA_GROUPS_ENABLED = tGroup["enabled"] ~= false;
		end

		VUHDO_lnfCheckButtonInitFromModel(tEnabledCheck);

		tEnabledCheck:Enable();
		tEnabledCheck:SetAlpha(1);
	end

	if not tGroup then
		if tFilterCombo then
			tFilterCombo:Hide();
		end

		if tExcludeFilterCombo then
			tExcludeFilterCombo:Hide();
		end

		if tPrioritySlider then
			tPrioritySlider:Hide();
		end

		if tCanColorBarCheck then
			tCanColorBarCheck:Hide();
		end

		if tCanColorTextCheck then
			tCanColorTextCheck:Hide();
		end

		if _G["VuhDoNewOptionsAuraGroupsStorePanelEnabledCheckButton"] then
			_G["VuhDoNewOptionsAuraGroupsStorePanelEnabledCheckButton"]:Hide();
		end
	end

	return;

end



--
local tNewId;
function VUHDO_auraGroupsOnNewGroup()

	tNewId = VUHDO_generateAuraGroupId();

	VUHDO_CONFIG["AURA_GROUPS"][tNewId] = {
		["filter"] = "HELPFUL|PLAYER",
		["excludeFilter"] = nil,
		["priority"] = 50,
		["canColorBar"] = false,
		["canColorText"] = false,
		["enabled"] = true,
		["displayName"] = "New Group",
		["isHarmful"] = false,
	};

	sSelectedGroupId = tNewId;
	VUHDO_AURA_GROUPS_SELECTED = tNewId;
	VUHDO_auraGroupsRefreshList();
	VUHDO_auraGroupsRefreshRightPanel();

	return;

end



--
local tNewId;
local tSourceGroup;
function VUHDO_auraGroupsOnCloneGroup(aSourceId)

	tSourceGroup = VUHDO_getAuraGroup(aSourceId);

	if not tSourceGroup then
		return;
	end

	tNewId = VUHDO_cloneAuraGroup(aSourceId, VUHDO_getAuraGroupDisplayName(aSourceId) .. " (Copy)");

	if tNewId then
		sSelectedGroupId = tNewId;
		VUHDO_AURA_GROUPS_SELECTED = tNewId;
		VUHDO_auraGroupsRefreshList();
		VUHDO_auraGroupsRefreshRightPanel();
	end

	return;

end



--
function VUHDO_auraGroupsOnDeleteGroup(aGroupId)

	if VUHDO_isBuiltInAuraGroup(aGroupId) then
		return;
	end

	VUHDO_CONFIG["AURA_GROUPS"][aGroupId] = nil;
	sSelectedGroupId = nil;
	VUHDO_AURA_GROUPS_SELECTED = nil;

	VUHDO_auraGroupsRefreshList();
	VUHDO_auraGroupsRefreshRightPanel();

	return;

end



--
function VUHDO_auraGroupsFilterChanged(aComboBox, aValue, anArrayModel)

	if sSelectedGroupId and VUHDO_CONFIG["AURA_GROUPS"][sSelectedGroupId] then
		VUHDO_CONFIG["AURA_GROUPS"][sSelectedGroupId]["filter"] = aValue or "";

		VUHDO_CONFIG["AURA_GROUPS"][sSelectedGroupId]["isHarmful"] = (aValue and strfind(aValue, "HARMFUL")) and true or false;
	end

	VUHDO_rebuildCanColorBarGroupsCache();

	return;

end



--
function VUHDO_auraGroupsExcludeFilterChanged(aComboBox, aValue, anArrayModel)

	if sSelectedGroupId and VUHDO_CONFIG["AURA_GROUPS"][sSelectedGroupId] then
		VUHDO_CONFIG["AURA_GROUPS"][sSelectedGroupId]["excludeFilter"] = (aValue ~= "" and aValue) or nil;
	end

	return;

end



--
function VUHDO_auraGroupsPriorityChanged(aComponent, aValue)

	if sSelectedGroupId and VUHDO_CONFIG["AURA_GROUPS"][sSelectedGroupId] then
		VUHDO_CONFIG["AURA_GROUPS"][sSelectedGroupId]["priority"] = tonumber(aValue) or 50;
	end

	if _G["VUHDO_rebuildCanColorBarGroupsCache"] then
		_G["VUHDO_rebuildCanColorBarGroupsCache"]();
	end

	return;

end



--
function VUHDO_auraGroupsCanColorBarChanged(aCheckButton)

	if sSelectedGroupId and VUHDO_CONFIG["AURA_GROUPS"][sSelectedGroupId] then
		VUHDO_CONFIG["AURA_GROUPS"][sSelectedGroupId]["canColorBar"] = aCheckButton:GetChecked();
	end

	if _G["VUHDO_rebuildCanColorBarGroupsCache"] then
		_G["VUHDO_rebuildCanColorBarGroupsCache"]();
	end

	return;

end



--
function VUHDO_auraGroupsCanColorTextChanged(aCheckButton)

	if sSelectedGroupId and VUHDO_CONFIG["AURA_GROUPS"][sSelectedGroupId] then
		VUHDO_CONFIG["AURA_GROUPS"][sSelectedGroupId]["canColorText"] = aCheckButton:GetChecked();
	end

	if _G["VUHDO_rebuildCanColorBarGroupsCache"] then
		_G["VUHDO_rebuildCanColorBarGroupsCache"]();
	end

	return;

end



--
function VUHDO_auraGroupsEnabledChanged(aParent, aValue)

	if not sSelectedGroupId then
		return;
	end

	if VUHDO_isBuiltInAuraGroup(sSelectedGroupId) then
		if not VUHDO_CONFIG["AURA_GROUP_DISABLED"] then
			VUHDO_CONFIG["AURA_GROUP_DISABLED"] = { };
		end

		if aValue then
			VUHDO_CONFIG["AURA_GROUP_DISABLED"][sSelectedGroupId] = nil;
		else
			VUHDO_CONFIG["AURA_GROUP_DISABLED"][sSelectedGroupId] = true;
		end
	else
		if VUHDO_CONFIG["AURA_GROUPS"] and VUHDO_CONFIG["AURA_GROUPS"][sSelectedGroupId] then
			VUHDO_CONFIG["AURA_GROUPS"][sSelectedGroupId]["enabled"] = aValue;
		end
	end

	VUHDO_rebuildCanColorBarGroupsCache();

	VUHDO_auraGroupsRefreshList();

	VUHDO_reloadUI(false);

	return;

end



--
function VUHDO_auraGroupsOnShow()

	VUHDO_auraGroupsRefreshList();

	if sSelectedGroupId and VUHDO_getAuraGroupRaw(sSelectedGroupId) then
		VUHDO_auraGroupsOnGroupSelected(sSelectedGroupId);
	else
		sSelectedGroupId = nil;
	end

	return;

end
