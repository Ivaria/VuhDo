local _;

local tinsert = table.insert;

local VUHDO_PLAYER_UNIT = "player";
local VUHDO_MAX_SHADOW_BUTTONS = 40;

local sManagerFrame;
local sShadowHeader;
local sLastSecurePlayerToken;
local sInitialized = false;



local function VUHDO_normalizeMappingUnit(aUnit)

	if not aUnit then
		return nil;
	end

	if aUnit == VUHDO_PLAYER_UNIT then
		return VUHDO_PLAYER_UNIT;
	end

	if sLastSecurePlayerToken and aUnit == sLastSecurePlayerToken then
		return VUHDO_PLAYER_UNIT;
	end

	return aUnit;

end



--
function VUHDO_isSecureShadowHeaderReady()

	return sInitialized;

end



--
local tInitConfigFunc = [=[
	tinsert(sShadowFrames, self);

	self:SetID(#sShadowFrames);
	self:SetAttribute("vuhdo_manager_ref", sManager);

	sManager:CallMethod("UpdateShadowButtonCount", #sShadowFrames);
]=];
local tOnAttributeChanged = [=[
	if name == "unit" then
		local tManager = self:GetAttribute("vuhdo_manager_ref");
		local tShadowButtonId = self:GetID();

		if tManager then
			local tUnit = value;

			if type(tUnit) == "string" then
				tUnit = strlower(tUnit);
			else
				tUnit = nil;
			end

			local tOldUnit = self:GetAttribute("vuhdo_last_unit");

			if not tUnit and tOldUnit then
				tManager:RunAttribute("vuhdo_clear_unit_method", tOldUnit, tShadowButtonId);
			elseif tUnit and tUnit ~= tOldUnit then
				tManager:RunAttribute("vuhdo_process_unit_method", tUnit, tShadowButtonId, tOldUnit);
			end

			self:SetAttribute("vuhdo_last_unit", tUnit);
		end
	end
]=];
local tChild;
function VUHDO_initSecureShadowHeader()

	if InCombatLockdown() or not VUHDO_CONFIG["COMBAT_ROSTER"]["enabled"] then
		return false;
	end

	sManagerFrame = VuhDoSecureManagerFrame;
	sShadowHeader = VuhDoShadowGroupHeader;

	if not sManagerFrame or not sShadowHeader then
		return false;
	end

	sManagerFrame["shadowButtonsConfigured"] = 0;
	sManagerFrame["pendingButtonCount"] = 0;

	function sManagerFrame:Execute(aBody)

		return SecureHandlerExecute(self, aBody);

	end;

	function sManagerFrame:UpdateShadowButtonCount(aCount)

		self["pendingButtonCount"] = aCount;

		return;

	end;

	function sShadowHeader:Execute(aBody)

		return SecureHandlerExecute(self, aBody);

	end;

	function sShadowHeader:SetFrameRef(aLabel, aRefFrame)

		return SecureHandlerSetFrameRef(self, aLabel, aRefFrame);

	end;

	sManagerFrame:Execute([=[
		sManager = self;

		sRealFrames = newtable();

		for tPanelNum = 1, 10 do
			sRealFrames[tPanelNum] = newtable();
		end;

		sUnitMap = newtable();
		sShadowToRealMap = newtable();
		sShadowButtonHasMapping = newtable();

		for tShadowId = 1, 40 do
			sShadowButtonHasMapping[tShadowId] = false;
		end

		sFallbackPanels = newtable();
		tinsert(sFallbackPanels, 1);

		sNextFallbackButton = newtable();
		sFallbackButtonStart = newtable();

		for tPanelNum = 1, 10 do
			sNextFallbackButton[tPanelNum] = 1;
			sFallbackButtonStart[tPanelNum] = 1;
		end

		sProcessQueue = newtable();
		sClearQueue = newtable();
		sProcessQueuePool = newtable();
		sShadowLastUnit = newtable();
		sShadowClearedUnit = newtable();

		sPlayerRaidToken = nil;
		sPendingRefresh = false;

		sMaxShadowButtons = 40; -- VUHDO_MAX_SHADOW_BUTTONS

		sFallbackMappingPool = newtable();

		for tIdx = 1, sMaxShadowButtons do
			local tMapping = newtable();
			tMapping[1] = 0;
			tMapping[2] = 0;

			local tMappings = newtable();
			tinsert(tMappings, tMapping);

			local tPoolEntry = newtable();
			tPoolEntry[1] = tMapping;
			tPoolEntry[2] = tMappings;

			tinsert(sFallbackMappingPool, tPoolEntry);

			local tQueueEntry = newtable();
			tinsert(sProcessQueuePool, tQueueEntry);
		end

		sFallbackPoolIndex = 1;
	]=]);

	sLastSecurePlayerToken = nil;

	sManagerFrame:SetAttribute("vuhdo_process_unit_method", [=[
		local tUnit, tShadowButtonId, tOldUnit = ...;

		if not tShadowButtonId then
			return;
		end

		local tQueueData = sProcessQueue[tShadowButtonId];

		if not tQueueData then
			local tPoolSize = #sProcessQueuePool;

			if tPoolSize > 0 then
				tQueueData = sProcessQueuePool[tPoolSize];
				sProcessQueuePool[tPoolSize] = nil;
			else
				tQueueData = newtable();
			end

			sProcessQueue[tShadowButtonId] = tQueueData;
		else
			wipe(tQueueData);
		end

		local tRawUnit = tUnit;
		local tPrevUnit = sShadowClearedUnit[tShadowButtonId];

		if tPrevUnit then
			sShadowClearedUnit[tShadowButtonId] = nil;
		elseif sShadowLastUnit[tShadowButtonId] then
			tPrevUnit = sShadowLastUnit[tShadowButtonId];
		else
			tPrevUnit = tOldUnit;
		end

		local tPreviousAlias = sPlayerRaidToken;

		if tOldUnit and tPreviousAlias and tOldUnit == tPreviousAlias then
			sPlayerRaidToken = tRawUnit or tPreviousAlias;
		elseif not tPreviousAlias and tRawUnit and tRawUnit ~= "player" then
			sPlayerRaidToken = tRawUnit;
		end

		if tRawUnit and (tRawUnit == "player" or (sPlayerRaidToken and tRawUnit == sPlayerRaidToken)) then
			tUnit = "player";
		else
			tUnit = tRawUnit;
		end

		if tPrevUnit and (tPrevUnit == "player" or (tPreviousAlias and tPrevUnit == tPreviousAlias)) then
			tPrevUnit = "player";
		end

		tQueueData[1] = tUnit;
		tQueueData[2] = tPrevUnit;

		sShadowLastUnit[tShadowButtonId] = tUnit;

		sClearQueue[tShadowButtonId] = nil;

		sPendingRefresh = true;

		sManager:SetAttribute("state-vuhdo_batch_timer", "process");
	]=]);

	sManagerFrame:SetAttribute("vuhdo_clear_unit_method", [=[
		local tUnit, tShadowButtonId = ...;

		if not tShadowButtonId then
			return;
		end

		local tRawUnit = tUnit;

		if tRawUnit == "player" or (sPlayerRaidToken and tRawUnit == sPlayerRaidToken) then
			tUnit = "player";
		end

		sShadowClearedUnit[tShadowButtonId] = tUnit;
		sShadowLastUnit[tShadowButtonId] = nil;

		sClearQueue[tShadowButtonId] = tUnit;

		sPendingRefresh = true;

		sManager:SetAttribute("state-vuhdo_batch_timer", "process");
	]=]);

	sManagerFrame:SetAttribute("_onstate-vuhdo_batch_timer", [=[
		if newstate ~= "process" and sPendingRefresh then
			if next(sClearQueue) == nil and next(sProcessQueue) == nil then
				sPendingRefresh = false;

				return;
			end

			for tShadowButtonId, tOldUnit in pairs(sClearQueue) do
				local tHasPreMapping = sShadowButtonHasMapping[tShadowButtonId];

				if tHasPreMapping then
					local tMappings = sShadowToRealMap[tShadowButtonId];

					if tMappings then
						for tMappingIdx = 1, #tMappings do
							local tMapping = tMappings[tMappingIdx];
							local tRealFrame = sRealFrames[tMapping[1]] and sRealFrames[tMapping[1]][tMapping[2]];

							if tRealFrame then
								tRealFrame:SetAttribute("unit", nil);
							end
						end
					end
				else
					local tMappings = sUnitMap[tOldUnit];

					if tMappings then
						for tMappingIdx = 1, #tMappings do
							local tMapping = tMappings[tMappingIdx];
							local tRealFrame = sRealFrames[tMapping[1]] and sRealFrames[tMapping[1]][tMapping[2]];

							if tRealFrame then
								tRealFrame:SetAttribute("unit", nil);

								tRealFrame:Hide();
							end
						end

						sUnitMap[tOldUnit] = nil;
					end
				end
			end

			for tShadowButtonId, tQueueData in pairs(sProcessQueue) do
				local tHasPreMapping = sShadowButtonHasMapping[tShadowButtonId];

				if tHasPreMapping then
					local tUnit = tQueueData[1];
					local tOldUnit = tQueueData[2];

					local tFallbackMappings = sUnitMap[tUnit];

					if tFallbackMappings then
						for tMappingIdx = 1, #tFallbackMappings do
							local tMapping = tFallbackMappings[tMappingIdx];
							local tFallbackFrame = sRealFrames[tMapping[1]] and sRealFrames[tMapping[1]][tMapping[2]];

							if tFallbackFrame then
								tFallbackFrame:SetAttribute("unit", nil);

								tFallbackFrame:Hide();
							end
						end
					end

					local tMappings = sShadowToRealMap[tShadowButtonId];

					if tMappings then
						if tUnit == "player" then
							for tMappingIdx = 1, #tMappings do
								local tMapping = tMappings[tMappingIdx];
								local tRealFrame = sRealFrames[tMapping[1]] and sRealFrames[tMapping[1]][tMapping[2]];

								if tRealFrame then
									tRealFrame:SetAttribute("unit", nil);

									tRealFrame:Hide();
								end
							end
						else
							for tMappingIdx = 1, #tMappings do
								local tMapping = tMappings[tMappingIdx];
								local tRealFrame = sRealFrames[tMapping[1]] and sRealFrames[tMapping[1]][tMapping[2]];

								if tRealFrame then
									tRealFrame:SetAttribute("unit", tUnit);

									tRealFrame:Show();
								end
							end
						end
					end
				end
			end

			for tShadowButtonId, tQueueData in pairs(sProcessQueue) do
				local tHasPreMapping = sShadowButtonHasMapping[tShadowButtonId];

				if not tHasPreMapping then
					local tUnit = tQueueData[1];
					local tOldUnit = tQueueData[2];

					if tUnit ~= "player" then
						local tMappings = sUnitMap[tUnit];

						if tMappings then
							for tMappingIdx = 1, #tMappings do
								local tMapping = tMappings[tMappingIdx];
								local tRealFrame = sRealFrames[tMapping[1]] and sRealFrames[tMapping[1]][tMapping[2]];

								if tRealFrame then
									tRealFrame:SetAttribute("unit", tUnit);

									tRealFrame:Show();
							end
							end
						elseif tOldUnit and sUnitMap[tOldUnit] then
							sUnitMap[tUnit] = sUnitMap[tOldUnit];
							sUnitMap[tOldUnit] = nil;

							local tReassignedMappings = sUnitMap[tUnit];

							for tMappingIdx = 1, #tReassignedMappings do
								local tMapping = tReassignedMappings[tMappingIdx];
								local tRealFrame = sRealFrames[tMapping[1]] and sRealFrames[tMapping[1]][tMapping[2]];

								if tRealFrame then
									tRealFrame:SetAttribute("unit", tUnit);

									tRealFrame:Show();
							end
							end
						else
							for tFallbackIdx = 1, #sFallbackPanels do
								local tFallbackPanel = sFallbackPanels[tFallbackIdx];
								local tFallbackButton = sNextFallbackButton[tFallbackPanel];
								local tFallbackFrame = sRealFrames[tFallbackPanel] and sRealFrames[tFallbackPanel][tFallbackButton];

								if tFallbackFrame then
									tFallbackFrame:SetAttribute("unit", tUnit);

									tFallbackFrame:Show();

									sNextFallbackButton[tFallbackPanel] = tFallbackButton + 1;
								end
							end

							if #sFallbackPanels > 0 then
								local tFirstPanel = sFallbackPanels[1];
								local tFirstButton = sNextFallbackButton[tFirstPanel] - 1;

								if sFallbackPoolIndex <= sMaxShadowButtons then
									local tPoolEntry = sFallbackMappingPool[sFallbackPoolIndex];
									sFallbackPoolIndex = sFallbackPoolIndex + 1;

									local tTempMapping = tPoolEntry[1];
									local tTempMappings = tPoolEntry[2];

									tTempMapping[1] = tFirstPanel;
									tTempMapping[2] = tFirstButton;

									sUnitMap[tUnit] = tTempMappings;
								end
							end
						end
					end
				end
			end

			for tShadowButtonId, tQueueData in pairs(sProcessQueue) do
				wipe(tQueueData);

				tinsert(sProcessQueuePool, tQueueData);

				sProcessQueue[tShadowButtonId] = nil;
			end

			wipe(sClearQueue);

			sFallbackPoolIndex = 1;

			sPendingRefresh = false;
		end
	]=]);

	RegisterStateDriver(sManagerFrame, "vuhdo_batch_timer", "[pet]pet;nopet;");

	sShadowHeader:SetFrameRef("sManager", sManagerFrame);

	sShadowHeader:Execute([=[
		sManager = self:GetFrameRef("sManager");

		sShadowFrames = newtable();
	]=]);

	sShadowHeader:SetAttribute("showPlayer", true);
	sShadowHeader:SetAttribute("showSolo", true);
	sShadowHeader:SetAttribute("showParty", true);
	sShadowHeader:SetAttribute("showRaid", true);
	sShadowHeader:SetAttribute("groupFilter", "1,2,3,4,5,6,7,8");
	sShadowHeader:SetAttribute("groupBy", nil);
	sShadowHeader:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8");
	sShadowHeader:SetAttribute("sortMethod", "INDEX");
	sShadowHeader:SetAttribute("template", "VuhDoShadowButtonTemplate");
	sShadowHeader:SetAttribute("maxColumns", 1);
	sShadowHeader:SetAttribute("unitsPerColumn", 40);
	sShadowHeader:SetAttribute("point", "TOP");
	sShadowHeader:SetAttribute("yOffset", 0);
	sShadowHeader:SetAttribute("initialConfigFunction", tInitConfigFunc);
	sShadowHeader:SetAttribute("startingIndex", -39);
	sShadowHeader:Show();
	sShadowHeader:SetAttribute("startingIndex", 1);

	for tCnt = 1, 40 do
		tChild = sShadowHeader:GetAttribute("child" .. tCnt);

		if tChild then
			tChild:SetAttribute("_onattributechanged", tOnAttributeChanged);
		end
	end

	sInitialized = true;

	return true;

end



--
function VUHDO_registerSecureRealFrame(aPanelNum, aButtonNum, aFrame)

	if not sInitialized or InCombatLockdown() then
		return false;
	end

	sManagerFrame:SetFrameRef("tempFrame", aFrame);

	sManagerFrame:Execute(format([=[
		local tPanelNum = %d;
		local tButtonNum = %d;
		local tRealFrame = self:GetFrameRef("tempFrame");

		if not sRealFrames[tPanelNum] then
			sRealFrames[tPanelNum] = newtable();
		end

		sRealFrames[tPanelNum][tButtonNum] = tRealFrame;
	]=], aPanelNum, aButtonNum));

	return true;

end



--
function VUHDO_debugSecureEnvironment()

	if not sInitialized then
		return;
	end

	if InCombatLockdown() then
		VUHDO_Msg("Cannot debug secure environment during combat.");

		return;
	end

	sManagerFrame:Execute([=[
		local tFrameCount = 0;

		for tPanel = 1, 10 do
			if sRealFrames[tPanel] then
				for tButton = 1, 40 do
					if sRealFrames[tPanel][tButton] then
						tFrameCount = tFrameCount + 1;
					end
				end
			end
		end

		local tShadowMappingCount = 0;

		for tShadowId, tMappings in pairs(sShadowToRealMap) do
			tShadowMappingCount = tShadowMappingCount + 1;
		end

		local tFallbackMappingCount = 0;

		for tUnit, tMappings in pairs(sUnitMap) do
			tFallbackMappingCount = tFallbackMappingCount + 1;
		end

		print(format("VuhDo: Secure environment: %d real frames registered, %d shadow-to-real mappings, %d fallback unit mappings, player token: %s", tFrameCount, tShadowMappingCount, tFallbackMappingCount, tostring(sPlayerRaidToken)));
	]=]);

	return;

end



--
function VUHDO_setSecureFallbackButtonStart(aPanelNum, aButtonStart)

	if not sInitialized or InCombatLockdown() then
		return false;
	end

	sManagerFrame:Execute(format([=[
		sFallbackButtonStart[%d] = %d;
		sNextFallbackButton[%d] = %d;
	]=], aPanelNum, aButtonStart, aPanelNum, aButtonStart));

	return true;

end



--
local tMapping;
local function VUHDO_pushSecureUnitMapping(aUnit, aMappings)

	sManagerFrame:Execute(format([=[
		sUnitMap[%q] = newtable();
	]=], aUnit));

	for tMappingIdx = 1, #aMappings do
		tMapping = aMappings[tMappingIdx];

		sManagerFrame:Execute(format([=[
			local tEntry = newtable();

			tEntry[1] = %d;
			tEntry[2] = %d;

			tinsert(sUnitMap[%q], tEntry);
		]=], tMapping[1], tMapping[2], aUnit));
	end

	return true;

end



--
local function VUHDO_clearSecureMappings()

	sManagerFrame:Execute([=[
		wipe(sUnitMap);

		for tPanelNum = 1, 10 do
			sNextFallbackButton[tPanelNum] = sFallbackButtonStart[tPanelNum];
		end
	]=]);

	return true;

end



--
local tPanelNum;
local function VUHDO_setSecureFallbackPanels(aPanelList)

	sManagerFrame:Execute([=[
		sFallbackPanels = newtable();
	]=]);

	for tPanelIdx = 1, #aPanelList do
		tPanelNum = aPanelList[tPanelIdx];

		sManagerFrame:Execute(format([=[
			tinsert(sFallbackPanels, %d);
		]=], tPanelNum));
	end

	return true;

end



--
local function VUHDO_setSecurePlayerToken(aPlayerToken)

	if aPlayerToken == sLastSecurePlayerToken then
		return true;
	end

	if aPlayerToken then
		sManagerFrame:Execute(format([=[
			sPlayerRaidToken = %q;
	]=], aPlayerToken));
	else
		sManagerFrame:Execute([=[
			sPlayerRaidToken = nil;
	]=]);
	end

	sLastSecurePlayerToken = aPlayerToken;

	return true;

end



--
local tPlayerToken;
local function VUHDO_updateSecurePlayerToken()

	tPlayerToken = nil;

	if IsInRaid() then
		for tCnt = 1, 40 do
			tPlayerToken = "raid" .. tCnt;

			if UnitIsUnit("player", tPlayerToken) then
				break;
			end

			tPlayerToken = nil;
		end
	elseif IsInGroup() then
		for tCnt = 1, 4 do
			tPlayerToken = "party" .. tCnt;

			if UnitIsUnit("player", tPlayerToken) then
				break;
			end

			tPlayerToken = nil;
		end
	end

	return VUHDO_setSecurePlayerToken(tPlayerToken);

end



--
local tShadowButton;
local tShadowId;
local tUnit;
local function VUHDO_initShadowToRealMappings()

	sManagerFrame:Execute([=[
		wipe(sShadowToRealMap);

		for tShadowId = 1, 40 do
			sShadowButtonHasMapping[tShadowId] = false;
		end
	]=]);

	for tCnt = 1, 40 do
		tShadowButton = sShadowHeader:GetAttribute("child" .. tCnt);

		if tShadowButton then
			tShadowId = tShadowButton:GetID();
			tUnit = tShadowButton:GetAttribute("unit");

			if tUnit then
				sManagerFrame:SetFrameRef("tempShadowButton", tShadowButton);

				sManagerFrame:Execute(format([=[
					local tShadowId = %d;
					local tUnit = %q;
					local tMappings = sUnitMap[tUnit];

					if tMappings then
						sShadowToRealMap[tShadowId] = tMappings;
						sShadowButtonHasMapping[tShadowId] = true;
					end
				]=], tShadowId, strlower(tUnit)));
			end
		end
	end

	sManagerFrame:Execute([=[
		wipe(sUnitMap);
	]=]);

	return true;

end



--
local tUnitMappings = { };
local tFallbackPanels;
local tModels;
local tSetup;
local tSortBy;
local tButtonIdx;
local tColIdx;
local tGroupArray;
local tUnitCount;
function VUHDO_computeAndPushSecureMappings()

	if not sInitialized or InCombatLockdown() then
		return false;
	end

	VUHDO_updateSecurePlayerToken();

	VUHDO_clearSecureMappings();

	wipe(tUnitMappings);

	tFallbackPanels = VUHDO_CONFIG["COMBAT_ROSTER"]["fallbackPanels"] or { 1 };
	VUHDO_setSecureFallbackPanels(tFallbackPanels);

	for tPanelNum = 1, VUHDO_MAX_PANELS do
		if VUHDO_isPanelVisible(tPanelNum) then
			tModels = VUHDO_getDynamicModelArray(tPanelNum);
			tSetup = VUHDO_PANEL_SETUP[tPanelNum];
			tSortBy = tSetup["MODEL"]["sort"];

			tButtonIdx = 1;
			tColIdx = 1;

			for tModelIndex, tModelId in ipairs(tModels) do
				tGroupArray = VUHDO_getGroupMembersSorted(tModelId, tSortBy, tPanelNum, tModelIndex);

				for _, tUnit in ipairs(tGroupArray) do
					local tNormalizedUnit = VUHDO_normalizeMappingUnit(tUnit);

					if not tUnitMappings[tNormalizedUnit] then
						tUnitMappings[tNormalizedUnit] = {};
					end

					tinsert(tUnitMappings[tNormalizedUnit], {tPanelNum, tButtonIdx});

					tButtonIdx = tButtonIdx + 1;
				end

				tColIdx = tColIdx + 1;
			end
		end
	end

	tUnitCount = 0;

	for tUnit, tMappings in pairs(tUnitMappings) do
		VUHDO_pushSecureUnitMapping(tUnit, tMappings);

		tUnitCount = tUnitCount + 1;
	end

	if VUHDO_CONFIG["COMBAT_ROSTER"]["debug"] then
		VUHDO_debugSecureEnvironment();
	end

	VUHDO_initShadowToRealMappings();

	return true;

end



--
local tPanelButtons;
local tButton;
local tUnit;
function VUHDO_syncPanelButtonRaidIds()

	for tPanelNum = 1, VUHDO_MAX_PANELS do
		tPanelButtons = VUHDO_getPanelButtons(tPanelNum);

		if tPanelButtons then
			for tButtonIdx = 1, #tPanelButtons do
				tButton = tPanelButtons[tButtonIdx];

				if tButton then
					tUnit = tButton:GetAttribute("unit");

					if tUnit and tButton["raidid"] ~= tUnit then
						tButton["raidid"] = tUnit;
					end
				end
			end
		end
	end

	return;

end