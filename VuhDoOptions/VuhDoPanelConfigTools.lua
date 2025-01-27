local _;
VUHDO_GLOBAL_ICONS = { };

local GI_SCAN_MAX = 200001;
VUHDO_GI_SCAN_IDX = GI_SCAN_MAX;

local GetSpellInfo = GetSpellInfo or VUHDO_getSpellInfo;
local GetSpellName = C_Spell.GetSpellName;
local GetSpellBookItemTexture = GetSpellBookItemTexture or VUHDO_getSpellBookItemTexture;
local pairs = pairs;


--
function VUHDO_removeFromModel(aPanelNum, anOrderNum)
	tremove(VUHDO_PANEL_MODELS[aPanelNum], anOrderNum);
	VUHDO_initDynamicPanelModels();
end



--
function VUHDO_insertIntoModel(aPanelNum, anOrderNum, anIsLeft, aModelId)
	tinsert(VUHDO_PANEL_MODELS[aPanelNum], anOrderNum + (anIsLeft and 0 or 1), aModelId)
	VUHDO_initDynamicPanelModels();
end



--
function VUHDO_rewritePanelModels()
	for tCnt = 1, VUHDO_MAX_PANELS do
		VUHDO_PANEL_SETUP[tCnt]["MODEL"]["groups"] = VUHDO_PANEL_MODELS[tCnt];
	end
end



--
function VUHDO_tableCount(anArray)
	local tCount = 0;
	for _ in pairs(anArray) do tCount = tCount + 1; end
	return tCount;
end



--
function VUHDO_getModelSafeName(anUnsafeName)
	return strtrim(gsub(anUnsafeName or "", "[.#]", " "));
end



--
function VUHDO_getOrCreateGroupOrderPanel(aParentPanelNum, aPanelNum)
	local tName = "Vd" .. aParentPanelNum .. "GrpOrd" .. aPanelNum;
	if not _G[tName] then
		local tPanel = CreateFrame("Frame", tName, _G["Vd" .. aParentPanelNum], "VuhDoGrpOrdTemplate");
		VUHDO_fixFrameLevels(false, tPanel, 2, tPanel:GetChildren());
	end

	return _G[tName];
end



--
function VUHDO_getOrCreateGroupSelectPanel(aParentPanelNum, aPanelNum)
	local tName = "Vd" .. aParentPanelNum .. "GrpSel" .. aPanelNum;
	if not _G[tName] then
		local tPanel = CreateFrame("Frame", tName, _G["Vd" .. aParentPanelNum], "VuhDoGrpSelTemplate");
		VUHDO_fixFrameLevels(false, tPanel, 2, tPanel:GetChildren());
	end

	return _G[tName];
end



--
local sGroupOrderBarsRight = { };
function VUHDO_getConfigOrderBarRight(aPanelNum, anOrderNum)
	local tIndex = aPanelNum * 100 + anOrderNum;
	if not sGroupOrderBarsRight[tIndex] then
		local tPanel = VUHDO_getOrCreateGroupOrderPanel(aPanelNum, anOrderNum);
		sGroupOrderBarsRight[tIndex] = _G[tPanel:GetName() .. "InsTxuR"];
	end

	return sGroupOrderBarsRight[tIndex];
end



--
local sGroupOrderBarsLeft = { };
function VUHDO_getConfigOrderBarLeft(aPanelNum, anOrderNum)
	local tIndex = aPanelNum * 100 + anOrderNum;
	if not sGroupOrderBarsLeft[tIndex] then
		local tPanel = VUHDO_getOrCreateGroupOrderPanel(aPanelNum, anOrderNum);
		sGroupOrderBarsLeft[tIndex] = _G[tPanel:GetName() .. "InsTxuL"];
	end

	return sGroupOrderBarsLeft[tIndex];
end



--
local tSpellNameById;
function VUHDO_resolveSpellId(aSpellName)
	if tonumber(aSpellName or "x") then
		tSpellNameById = GetSpellName(tonumber(aSpellName));
		if tSpellNameById then
			return tSpellNameById;
		end
	end
	return aSpellName;
end



--
local tText, tTextById, tLabel;
function VUHDO_newOptionsSpellEditBoxCheckId(anEditBox)
	tLabel = _G[anEditBox:GetName() .. "Hint"];
	tText = anEditBox:GetText();
	tTextById = VUHDO_resolveSpellId(tText);

	if tText ~= tTextById then
		tTextById = strsub(tTextById, 1, 20);
		tLabel:SetText(tTextById);
	else
		tLabel:SetText("");
	end
end



--
local VUHDO_USED_BUFFS = { };
function VUHDO_updateGlobalIconList()
	table.wipe(VUHDO_USED_BUFFS);

	-- Add custom debuffs
	for _, tName in pairs(VUHDO_CONFIG["CUSTOM_DEBUFF"]["STORED"]) do
		VUHDO_USED_BUFFS[tName] = true;
	end

	-- Add spell traces
	for _, tName in pairs(VUHDO_CONFIG["SPELL_TRACE"]["STORED"]) do
		VUHDO_USED_BUFFS[tName] = true;
	end

	-- Add bouquet item buffs
	for _, tItems in pairs(VUHDO_BOUQUETS["STORED"]) do
		tItems = VUHDO_decompressIfCompressed(tItems);
		for _, tItem in pairs(tItems) do
		  --  tItem["name"] can be nil for some reason (maybe on compressing bouquets?)
			if tItem["name"] and not VUHDO_BOUQUET_BUFFS_SPECIAL[tItem["name"]] then
				VUHDO_USED_BUFFS[tItem["name"]] = true;
			end
		end
	end

	-- Add standard icons
	for _, tValues in pairs(VUHDO_CUSTOM_ICONS) do
		if tValues[2] then
			VUHDO_USED_BUFFS[tValues[1]] = true;
			VUHDO_GLOBAL_ICONS[tValues[1]] = tValues[2];
		end
	end

	-- Add standard ignore debuffs
	for tName, _  in pairs(VUHDO_DEBUFF_BLACKLIST) do
		VUHDO_USED_BUFFS[tName] = true;
	end

	-- Remove obsolete
	for tName, _ in pairs(VUHDO_GLOBAL_ICONS) do
		if not VUHDO_USED_BUFFS[tName] then
			VUHDO_GLOBAL_ICONS[tName] = nil;
		end
	end

	-- Add new
	for tName, _ in pairs(VUHDO_USED_BUFFS) do
		if (VUHDO_GLOBAL_ICONS[tName] == nil) then
			if tonumber(tName) then
				local _, _, tIcon = GetSpellInfo(tonumber(tName));
				VUHDO_GLOBAL_ICONS[tName] = tIcon;
			else
				VUHDO_GLOBAL_ICONS[tName] = "";
			end
		end
	end
end



--
local function VUHDO_tableContains(aTable, aValue)
	for _, tValue in pairs(aTable) do
		if tValue == aValue then return true; end
	end

	return false;
end



--
local tStep = 50;
local tRef;
local tName, _, tIcon;
local function VUHDO_scanNextGlobalIcons()
	if not VUHDO_tableContains(VUHDO_GLOBAL_ICONS, "") then
		return;
	end
	tRef = VUHDO_GLOBAL_ICONS;
	for tCnt = VUHDO_GI_SCAN_IDX + tStep , VUHDO_GI_SCAN_IDX, -1 do
		tName, _, tIcon = GetSpellInfo(tCnt);
		if tRef[tName] == "" then tRef[tName] = tIcon; end
	end

	VUHDO_GI_SCAN_IDX = VUHDO_GI_SCAN_IDX - tStep;

	if VUHDO_GI_SCAN_IDX < 1 then VUHDO_GI_SCAN_IDX = GI_SCAN_MAX; end
end



--
function VUHDO_optionsOnUpdate(self, aTimeDelta)
	VUHDO_scanNextGlobalIcons();
	VUHDO_updateRequestsInProgress();
end



--
function VUHDO_getGlobalIcon(aDeBuffName)
	if not aDeBuffName then return nil; end
	return GetSpellBookItemTexture(aDeBuffName) or VUHDO_GLOBAL_ICONS[aDeBuffName];
end



--
local tCnt;
local tStringChar;
local tPrefixChar;
local tSubstring;
local tPrefixSuffix;
local tStringSuffix;
local function VUHDO_radixTreePrefixSubstring(aPrefix, aString)

	if not aPrefix or not aString then
		return;
	end

	tCnt = 1;

	while tCnt <= strlen(aString) do
		tStringChar = string.sub(aString, tCnt, tCnt);
		tPrefixChar = string.sub(aPrefix, tCnt, tCnt);

		if tStringChar ~= tPrefixChar then
			break;
		end

		tCnt = tCnt + 1;
	end

	if tCnt > 1 then
		tSubstring = string.sub(aPrefix, 1, tCnt - 1);

		tPrefixSuffix = string.sub(aPrefix, tCnt, strlen(aPrefix));
		tStringSuffix = string.sub(aString, tCnt, strlen(aString));

		return tSubstring, tPrefixSuffix, tStringSuffix;
	else
		return nil, nil, nil;
	end

end



--
function VUHDO_radixTreeCreate()

	local tRootNode = {
		["prefix"] = "",
		["isLeaf"] = true,
		["children"] = { },
	};

	return tRootNode;

end



--
local tChar;
local tFound;
local tNode;
local tSubstringChar;
local tNodeTemp;
function VUHDO_radixTreeAdd(aTree, aString)

	if not aTree or not aString then
		return;
	end

	if aTree["prefix"] == aString and not aTree["isLeaf"] then
		aTree["isLeaf"] = true;
	else
		tChar = string.sub(aString, 1, 1);

		tFound = false;
		for tChildChar, tChild in pairs(aTree["children"]) do
			if tChildChar == tChar then
				tFound = true;
			end
		end

		if tChar and not tFound then
			aTree["children"][tChar] = {
				["prefix"] = aString,
				["isLeaf"] = true,
				["children"] = { },
			};
		elseif tChar then
			tNode = aTree["children"][tChar];

			tSubstring, tPrefixSuffix, tStringSuffix = VUHDO_radixTreePrefixSubstring(tNode["prefix"], aString);
			tSubstringChar = string.sub(tSubstring, 1, 1);

			if tSubstringChar and VUHDO_strempty(tPrefixSuffix) then
				VUHDO_radixTreeAdd(aTree["children"][tSubstringChar], tStringSuffix);
			elseif tSubstringChar then
				tNode["prefix"] = tPrefixSuffix;

				tNodeTemp = aTree["children"][tSubstringChar];

				aTree["children"][tSubstringChar] = {
					["prefix"] = tSubstring,
					["isLeaf"] = false,
					["children"] = {
						[tPrefixSuffix] = {
							["prefix"] = tNodeTemp["prefix"],
							["isLeaf"] = tNodeTemp["isLeaf"],
							["children"] = tNodeTemp["children"],
						},
					},
				};

				if VUHDO_strempty(tStringSuffix) then
					aTree["children"][tSubstringChar]["isLeaf"] = true;
				else
					VUHDO_radixTreeAdd(aTree["children"][tSubstringChar], tStringSuffix);
				end
			end
		end
	end

end



--
function VUHDO_radixTreeAddAll(aTree, ...)

	if not aTree then
		return;
	end

	for _, tString in pairs({ ... }) do
		VUHDO_radixTreeAdd(aTree, tString);
	end

end



--
function VUHDO_radixTreeContains(aTree, aString)

	if not aTree or not aString then
		return;
	end

	tChar = string.sub(aString, 1, 1);

	if tChar then
		tNode = aTree["children"][tChar];

		if not tNode then
			return false;
		else
			tSubstring, tPrefixSuffix, tStringSuffix = VUHDO_radixTreePrefixSubstring(tNode["prefix"], aString);

			if not VUHDO_strempty(tPrefixSuffix) then
				return false;
			elseif VUHDO_strempty(tStringSuffix) then
				return tNode["isLeaf"];
			else
				return VUHDO_radixTreeContains(tNode, tStringSuffix);
			end
		end
	else
		return false;
	end

end
