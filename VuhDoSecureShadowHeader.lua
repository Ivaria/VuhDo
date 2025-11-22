local _;

local tinsert = table.insert;

local VUHDO_PLAYER_UNIT = "player";

local sManagerFrame;
local sShadowHeader;
local sLastSecurePlayerToken;
local sInitialized = false;



--
function VUHDO_isSecureShadowHeaderReady()

	return sInitialized;

end



--
local tInitConfigFunc = [=[
	tinsert(sShadowButtons, self);

	self:SetID(#sShadowButtons);
	self:SetAttribute("vuhdo_manager_ref", sManager);

	sManager:CallMethod("UpdateShadowButtonCount", #sShadowButtons);
]=];
local tOnAttributeChanged = [=[
	local tShadowButtonId = self:GetID();

	if not tShadowButtonId then
		return;
	end

	if name == "unit" then
		local tManager = self:GetAttribute("vuhdo_manager_ref");

		if tManager then
			local tUnit = value;

			if type(tUnit) ~= "string" then
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

	end

	function sManagerFrame:UpdateShadowButtonCount(aCount)

		self["pendingButtonCount"] = aCount;

		return;

	end

	function sShadowHeader:Execute(aBody)

		return SecureHandlerExecute(self, aBody);

	end

	function sShadowHeader:SetFrameRef(aLabel, aRefFrame)

		return SecureHandlerSetFrameRef(self, aLabel, aRefFrame);

	end

	sManagerFrame:Execute([=[
		sManager = self;

		sRealButtons = newtable();
		sDebuffFrames = newtable();

		for tPanelNum = 1, 10 do
			sRealButtons[tPanelNum] = newtable();
			sDebuffFrames[tPanelNum] = newtable();
		end

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

		sMaxShadowButtons = 40;

		sFallbackMappingPool = newtable();

		for tCnt = 1, sMaxShadowButtons do
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

		local tPrevUnit = sShadowClearedUnit[tShadowButtonId];

		if tPrevUnit then
			sShadowClearedUnit[tShadowButtonId] = nil;
		elseif sShadowLastUnit[tShadowButtonId] then
			tPrevUnit = sShadowLastUnit[tShadowButtonId];
		else
			tPrevUnit = tOldUnit;
		end

		if tOldUnit and sPlayerRaidToken and tOldUnit == sPlayerRaidToken then
			if tUnit then
				sPlayerRaidToken = tUnit;
			end
		end

		tQueueData[1] = tUnit;
		tQueueData[2] = tPrevUnit;

		sShadowLastUnit[tShadowButtonId] = tUnit;

		if sClearQueue[tShadowButtonId] == tUnit then
			sClearQueue[tShadowButtonId] = nil;
		end

		sPendingRefresh = true;

		sManager:SetAttribute("state-vuhdo_batch_timer", "process");
	]=]);

	sManagerFrame:SetAttribute("vuhdo_clear_unit_method", [=[
		local tUnit, tShadowButtonId = ...;

		if not tShadowButtonId then
			return;
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
							local tRealButton = tMapping[1] and tMapping[2] and sRealButtons[tMapping[1]] and sRealButtons[tMapping[1]][tMapping[2]];

							if tRealButton then
								if tOldUnit and not (sPlayerRaidToken and tOldUnit == sPlayerRaidToken) then
									local tCurrentUnit = tRealButton:GetAttribute("unit");

									if tCurrentUnit == tOldUnit then
										tRealButton:SetAttribute("unit", nil);

										local tDebuffFrames = tMapping[1] and tMapping[2] and sDebuffFrames[tMapping[1]] and sDebuffFrames[tMapping[1]][tMapping[2]];

										if tDebuffFrames then
											for tIconNum, tDebuffFrame in pairs(tDebuffFrames) do
												tDebuffFrame:SetAttribute("unit", nil);
											end
										end
									end
								end
							end
						end
					end
				else
					if tOldUnit then
						if not (sPlayerRaidToken and tOldUnit == sPlayerRaidToken) then
							local tMappings = sUnitMap[tOldUnit];

							if tMappings then
								for tMappingIdx = 1, #tMappings do
									local tMapping = tMappings[tMappingIdx];
									local tRealButton = tMapping[1] and tMapping[2] and sRealButtons[tMapping[1]] and sRealButtons[tMapping[1]][tMapping[2]];

									if tRealButton then
										tRealButton:SetAttribute("unit", nil);

										local tDebuffFrames = tMapping[1] and tMapping[2] and sDebuffFrames[tMapping[1]] and sDebuffFrames[tMapping[1]][tMapping[2]];

										if tDebuffFrames then
											for tIconNum, tDebuffFrame in pairs(tDebuffFrames) do
												tDebuffFrame:SetAttribute("unit", nil);
											end
										end

										tRealButton:Hide();
									end
								end

								sUnitMap[tOldUnit] = nil;
							end
						end
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
							local tFallbackButton = tMapping[1] and tMapping[2] and sRealButtons[tMapping[1]] and sRealButtons[tMapping[1]][tMapping[2]];

							if tFallbackButton then
								local tCurrentUnit = tFallbackButton:GetAttribute("unit");

								if tCurrentUnit == tUnit and tCurrentUnit ~= "player" and not (sPlayerRaidToken and tCurrentUnit == sPlayerRaidToken) then
									tFallbackButton:SetAttribute("unit", nil);

									local tDebuffFrames = tMapping[1] and tMapping[2] and sDebuffFrames[tMapping[1]] and sDebuffFrames[tMapping[1]][tMapping[2]];

									if tDebuffFrames then
										for tIconNum, tDebuffFrame in pairs(tDebuffFrames) do
											tDebuffFrame:SetAttribute("unit", nil);
										end
									end

									tFallbackButton:Hide();
								end
							end
						end
					end

					local tMappings = sShadowToRealMap[tShadowButtonId];

					if tMappings then
						for tMappingIdx = 1, #tMappings do
							local tMapping = tMappings[tMappingIdx];
							local tRealButton = tMapping[1] and tMapping[2] and sRealButtons[tMapping[1]] and sRealButtons[tMapping[1]][tMapping[2]];

							if tRealButton then
								tRealButton:SetAttribute("unit", tUnit);

								local tDebuffFrames = tMapping[1] and tMapping[2] and sDebuffFrames[tMapping[1]] and sDebuffFrames[tMapping[1]][tMapping[2]];

								if tDebuffFrames then
									for tIconNum, tDebuffFrame in pairs(tDebuffFrames) do
										tDebuffFrame:SetAttribute("unit", tUnit);
									end
								end

								tRealButton:Show();
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
							local tButtonUnit = tUnit;

							for tMappingIdx = 1, #tMappings do
								local tMapping = tMappings[tMappingIdx];
								local tRealButton = tMapping[1] and tMapping[2] and sRealButtons[tMapping[1]] and sRealButtons[tMapping[1]][tMapping[2]];

								if tRealButton then
									tRealButton:SetAttribute("unit", tButtonUnit);

									local tDebuffFrames = tMapping[1] and tMapping[2] and sDebuffFrames[tMapping[1]] and sDebuffFrames[tMapping[1]][tMapping[2]];

									if tDebuffFrames then
										for tIconNum, tDebuffFrame in pairs(tDebuffFrames) do
											tDebuffFrame:SetAttribute("unit", tButtonUnit);
										end
									end

									tRealButton:Show();
								end
							end
						elseif tOldUnit then
							if sUnitMap[tOldUnit] then
								sUnitMap[tUnit] = sUnitMap[tOldUnit];
								sUnitMap[tOldUnit] = nil;

								local tReassignedMappings = sUnitMap[tUnit];

								if tReassignedMappings then
									local tButtonUnit = tUnit;

									for tMappingIdx = 1, #tReassignedMappings do
										local tMapping = tReassignedMappings[tMappingIdx];
										local tCurrentUnit = tRealButton:GetAttribute("unit");

										if tCurrentUnit == tUnit and tCurrentUnit ~= "player" and not (sPlayerRaidToken and tCurrentUnit == sPlayerRaidToken) then
											local tRealButton = tMapping[1] and tMapping[2] and sRealButtons[tMapping[1]] and
												sRealButtons[tMapping[1]][tMapping[2]];

											if tRealButton then
												tRealButton:SetAttribute("unit", tButtonUnit);

												local tDebuffFrames = tMapping[1] and tMapping[2] and sDebuffFrames[tMapping[1]] and
													sDebuffFrames[tMapping[1]][tMapping[2]];

												if tDebuffFrames then
													for tIconNum, tDebuffFrame in pairs(tDebuffFrames) do
														tDebuffFrame:SetAttribute("unit", tButtonUnit);
													end
												end

												tRealButton:Show();
											end
										end
									end
								end
							end
						else
							if not (tUnit and sPlayerRaidToken and tUnit == sPlayerRaidToken) then
								local tAssignedPanel = nil;
								local tAssignedButtonIndex = nil;

								for tFallbackIdx = 1, #sFallbackPanels do
									local tFallbackPanel = sFallbackPanels[tFallbackIdx];

									if tFallbackPanel then
										local tFallbackButtonIndex = nil;
										local tFallbackButton = nil;

										local tStartIndex = sFallbackButtonStart[tFallbackPanel];
										local tCheckIndex = tStartIndex;

										while true do
											local tCheckButton = sRealButtons[tFallbackPanel] and sRealButtons[tFallbackPanel][tCheckIndex];
											if not tCheckButton then
												break;
											end

											local tCheckUnit = tCheckButton:GetAttribute("unit");
											if not tCheckUnit then
												tFallbackButtonIndex = tCheckIndex;
												tFallbackButton = tCheckButton;
												break;
											end

											tCheckIndex = tCheckIndex + 1;
										end

										if not tFallbackButton then
											tFallbackButtonIndex = sNextFallbackButton[tFallbackPanel];
											tFallbackButton = tFallbackButtonIndex and sRealButtons[tFallbackPanel] and
												sRealButtons[tFallbackPanel][tFallbackButtonIndex];
										end

										if tFallbackButton then
											tFallbackButton:SetAttribute("unit", tUnit);

											local tDebuffFrames = tFallbackPanel and tFallbackButtonIndex and
												sDebuffFrames[tFallbackPanel] and sDebuffFrames[tFallbackPanel][tFallbackButtonIndex];

											if tDebuffFrames then
												for tIconNum, tDebuffFrame in pairs(tDebuffFrames) do
													tDebuffFrame:SetAttribute("unit", tUnit);
												end
											end

											tFallbackButton:Show();

											if tFallbackButtonIndex >= sNextFallbackButton[tFallbackPanel] then
												sNextFallbackButton[tFallbackPanel] = tFallbackButtonIndex + 1;
											end

											if not tAssignedPanel then
												tAssignedPanel = tFallbackPanel;
												tAssignedButtonIndex = tFallbackButtonIndex;
											end
										end
									end
								end

								if tAssignedPanel and tAssignedButtonIndex and #sFallbackPanels > 0 then
									if sFallbackPoolIndex <= sMaxShadowButtons then
										local tPoolEntry = sFallbackMappingPool[sFallbackPoolIndex];
										sFallbackPoolIndex = sFallbackPoolIndex + 1;

										local tTempMapping = tPoolEntry[1];
										local tTempMappings = tPoolEntry[2];

										if tAssignedPanel and tAssignedButtonIndex then
											tTempMapping[1] = tAssignedPanel;
											tTempMapping[2] = tAssignedButtonIndex;

											sUnitMap[tUnit] = tTempMappings;
										end
									end
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

		sShadowButtons = newtable();
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
function VUHDO_registerSecureRealButton(aPanelNum, aButtonNum, aButton)

	if not sInitialized or InCombatLockdown() then
		return false;
	end

	sManagerFrame:SetFrameRef("sRealButton", aButton);

	sManagerFrame:Execute(format([=[
		local tPanelNum = %d;
		local tButtonNum = %d;
		local tRealButton = self:GetFrameRef("sRealButton");

		if not sRealButtons[tPanelNum] then
			sRealButtons[tPanelNum] = newtable();
		end

		sRealButtons[tPanelNum][tButtonNum] = tRealButton;
	]=], aPanelNum, aButtonNum));

	return true;

end



--
function VUHDO_registerSecureDebuffFrame(aPanelNum, aButtonNum, anIconNum, aDebuffFrame)

	if not sInitialized or InCombatLockdown() then
		return false;
	end

	sManagerFrame:SetFrameRef("sDebuffFrame", aDebuffFrame);

	sManagerFrame:Execute(format([=[
		local tPanelNum = %d;
		local tButtonNum = %d;
		local tIconNum = %d;
		local tDebuffFrame = self:GetFrameRef("sDebuffFrame");

		if not sDebuffFrames[tPanelNum] then
			sDebuffFrames[tPanelNum] = newtable();
		end

		if not sDebuffFrames[tPanelNum][tButtonNum] then
			sDebuffFrames[tPanelNum][tButtonNum] = newtable();
		end

		sDebuffFrames[tPanelNum][tButtonNum][tIconNum] = tDebuffFrame;
	]=], aPanelNum, aButtonNum, anIconNum));

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
		local tDebuffFrameCount = 0;

		for tPanel = 1, 10 do
			if sRealButtons[tPanel] then
				for tButtonIndex = 1, 40 do
					if sRealButtons[tPanel][tButtonIndex] then
						tFrameCount = tFrameCount + 1;
					end

					if sDebuffFrames[tPanel] and sDebuffFrames[tPanel][tButtonIndex] then
						for tIconNum, tDebuffFrame in pairs(sDebuffFrames[tPanel][tButtonIndex]) do
							if tDebuffFrame then
								tDebuffFrameCount = tDebuffFrameCount + 1;
							end
						end
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

		print(format("VuhDo: Secure environment: %d real frames, %d debuff frames, %d shadow-to-real mappings, %d fallback unit mappings, player token: %s", tFrameCount, tDebuffFrameCount, tShadowMappingCount, tFallbackMappingCount, tostring(sPlayerRaidToken)));
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
				sManagerFrame:SetFrameRef("sShadowButton", tShadowButton);

				sManagerFrame:Execute(format([=[
					local tShadowId = %d;
					local tUnit = %q;
					local tMappings = sUnitMap[tUnit];

					if tMappings then
						sShadowToRealMap[tShadowId] = tMappings;
						sShadowButtonHasMapping[tShadowId] = true;
					end
				]=], tShadowId, tUnit));
			end
		end
	end

	sManagerFrame:Execute([=[
		wipe(sUnitMap);
	]=]);

	for tCnt = 1, 40 do
		tShadowButton = sShadowHeader:GetAttribute("child" .. tCnt);

		if tShadowButton then
			tShadowId = tShadowButton:GetID();
			tUnit = tShadowButton:GetAttribute("unit");

			if tUnit then
				sManagerFrame:Execute(format([=[
					local tShadowId = %d;
					local tUnit = %q;

					if sShadowButtonHasMapping[tShadowId] then
						local tQueueData = sProcessQueue[tShadowId];

						if not tQueueData then
							local tPoolSize = #sProcessQueuePool;

							if tPoolSize > 0 then
								tQueueData = sProcessQueuePool[tPoolSize];
								sProcessQueuePool[tPoolSize] = nil;
							else
								tQueueData = newtable();
							end

							sProcessQueue[tShadowId] = tQueueData;
						else
							wipe(tQueueData);
						end

						tQueueData[1] = tUnit;
						tQueueData[2] = nil;

						sShadowLastUnit[tShadowId] = tUnit;

						sPendingRefresh = true;
					end
				]=], tShadowId, tUnit));
			end
		end
	end

	sManagerFrame:Execute([=[
		if sPendingRefresh then
			self:SetAttribute("state-vuhdo_batch_timer", "process");
		end
	]=]);

	return true;

end



--
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
local tUnitMappings = { };
local tFallbackPanels;
local tModels;
local tSetup;
local tSortBy;
local tButtonIndex;
local tColIndex;
local tGroupArray;
local tUnitCount;
local tNormalizedUnit;
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

			tButtonIndex = 1;
			tColIndex = 1;

			for tModelIndex, tModelId in ipairs(tModels) do
				tGroupArray = VUHDO_getGroupMembersSorted(tModelId, tSortBy, tPanelNum, tModelIndex);

				for _, tUnit in ipairs(tGroupArray) do
					tNormalizedUnit = VUHDO_normalizeMappingUnit(tUnit);

					if tNormalizedUnit and not tUnitMappings[tNormalizedUnit] then
						tUnitMappings[tNormalizedUnit] = { };
					end

					tinsert(tUnitMappings[tNormalizedUnit], { tPanelNum, tButtonIndex });

					tButtonIndex = tButtonIndex + 1;
				end

				tColIndex = tColIndex + 1;
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
local tDebuffFrame;
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

					for tCnt = 40, VUHDO_CONFIG["CUSTOM_DEBUFF"]["max_num"] + 39 do
						tDebuffFrame = VUHDO_getBarIconFrame(tButton, tCnt);

						if tDebuffFrame then
							tUnit = tDebuffFrame:GetAttribute("unit");

							if tUnit and tDebuffFrame["raidid"] ~= tUnit then
								tDebuffFrame["raidid"] = tUnit;
							end
						end
					end
				end
			end
		end
	end

	return;

end