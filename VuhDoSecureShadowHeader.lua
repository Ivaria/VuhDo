local _;

local tinsert = table.insert;
local format = string.format;

local sManagerFrame;
local sShadowHeader;
local sShadowPetHeader;
local sInitialized = false;

local VUHDO_getPanelButtons;
local VUHDO_safeSetAttribute;

local VUHDO_INTERNAL_TOGGLES;
local VUHDO_CONFIG;
local VUHDO_PANEL_SETUP;
local VUHDO_MAX_PANELS;
local VUHDO_UPDATE_PETS;
local VUHDO_AURA_FRAMES;



--
function VUHDO_secureShadowHeaderInitLocalOverrides()

	VUHDO_INTERNAL_TOGGLES = _G["VUHDO_INTERNAL_TOGGLES"];
	VUHDO_CONFIG = _G["VUHDO_CONFIG"];
	VUHDO_PANEL_SETUP = _G["VUHDO_PANEL_SETUP"];
	VUHDO_MAX_PANELS = _G["VUHDO_MAX_PANELS"];
	VUHDO_UPDATE_PETS = _G["VUHDO_UPDATE_PETS"];
	VUHDO_AURA_FRAMES = _G["VUHDO_AURA_FRAMES"];

	VUHDO_getPanelButtons = _G["VUHDO_getPanelButtons"];
	VUHDO_safeSetAttribute = _G["VUHDO_safeSetAttribute"];

	return;

end



--
local tRealButtonsForPanel;
local tRealButton;
local tButtonName;
local tButtonAuraFrames;
local tNewUnit;
local function VUHDO_refreshAuraFramesForButton(aPanelNum, aButtonNum)

	if not aPanelNum or not aButtonNum then
		return;
	end

	tRealButtonsForPanel = VUHDO_getPanelButtons(aPanelNum);
	tRealButton = tRealButtonsForPanel and tRealButtonsForPanel[aButtonNum];

	if not tRealButton then
		return;
	end

	tNewUnit = tRealButton:GetAttribute("unit");

	tRealButton["raidid"] = tNewUnit;

	tButtonName = tRealButton:GetName();
	tButtonAuraFrames = tButtonName and VUHDO_AURA_FRAMES[tButtonName];

	if not tButtonAuraFrames then
		return;
	end

	for tAnchorIndex, tAnchorFrames in pairs(tButtonAuraFrames) do
		for tSlotIndex, tFrame in pairs(tAnchorFrames) do
			if tFrame then
				VUHDO_safeSetAttribute(tFrame, "unit", tNewUnit);

				tFrame["raidid"] = tNewUnit;
			end
		end
	end

	return;

end



--
function VUHDO_isSecureShadowHeaderReady()

	return sInitialized;

end



--
local tFallbackPanel;
local tSetup;
local tIsPetsLast;
local function VUHDO_updateSecureFallbackConfig()

	if not sManagerFrame or InCombatLockdown() then
		return false;
	end

	tFallbackPanel = VUHDO_CONFIG["COMBAT_ROSTER"]["fallbackPanel"] or 1;

	tSetup = VUHDO_PANEL_SETUP[tFallbackPanel];
	tIsPetsLast = tSetup and tSetup["MODEL"] and tSetup["MODEL"]["isPetsLast"] or false;

	sManagerFrame:Execute(format([=[
		sFallbackPanel = %d;
		sIsPetsLastEnabled = %s;

		if sIsDebugEnabled then
			print("[VuhDo] Fallback config: panel=" .. tostring(sFallbackPanel) .. ", isPetsLast=" .. tostring(sIsPetsLastEnabled));
		end
	]=], tFallbackPanel, tostring(tIsPetsLast)));

	return true;

end



--
-- Shadow Button ID Scheme:
--
-- Player shadow buttons: Internal IDs 1-40, child frames "child1" to "child40"
-- Pet shadow buttons:    Internal IDs 41-80, child frames "child1" to "child40"
--
-- Pet buttons use IDs 41-80 (instead of 1-40) to prevent key collisions in shared data structures.
-- Convert when accessing pet child frames: childFrame = GetAttribute("child" .. (shadowButtonId - 40))
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

			if sIsDebugEnabled then
				print("[VuhDo] Shadow button", tShadowButtonId, "unit changed: old=", tostring(tOldUnit), "new=", tostring(tUnit));
			end

			if not tUnit and tOldUnit then
				tManager:RunAttribute("vuhdo_clear_unit_method", tOldUnit, tShadowButtonId);
			elseif tUnit and tUnit ~= tOldUnit then
				tManager:RunAttribute("vuhdo_process_unit_method", tUnit, tShadowButtonId, tOldUnit);
			elseif sIsDebugEnabled then
				print("[VuhDo] Shadow button", tShadowButtonId, "unit change skipped (no change or invalid)");
			end

			self:SetAttribute("vuhdo_last_unit", tUnit);
		end
	end
]=];
local tPetInitConfigFunc = [=[
	tinsert(sShadowPetButtons, self);

	self:SetID(#sShadowPetButtons + 40);
	self:SetAttribute("vuhdo_manager_ref", sManager);
	self:SetAttribute("toggleForVehicle", false);

	sManager:CallMethod("UpdateShadowButtonCount", #sShadowPetButtons);
]=];
local tOnPetAttributeChanged = [=[
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

			local tOldUnit = self:GetAttribute("vuhdo_last_pet_unit");

			if sIsDebugEnabled then
				print("[VuhDo] Pet shadow button", tShadowButtonId, "unit changed: old=", tostring(tOldUnit), "new=", tostring(tUnit));
			end

			if not tUnit and tOldUnit then
				tManager:RunAttribute("vuhdo_clear_pet_unit_method", tOldUnit, tShadowButtonId);
			elseif tUnit and tUnit ~= tOldUnit then
				tManager:RunAttribute("vuhdo_process_pet_unit_method", tUnit, tShadowButtonId, tOldUnit);
			elseif sIsDebugEnabled then
				print("[VuhDo] Pet shadow button", tShadowButtonId, "unit change skipped (no change or invalid)");
			end

			self:SetAttribute("vuhdo_last_pet_unit", tUnit);
		end
	end
]=];
local tChild;
local tFallbackPanel;
local tHasPetHeader;
function VUHDO_initSecureShadowHeader()

	if InCombatLockdown() or not VUHDO_CONFIG["COMBAT_ROSTER"]["enabled"] then
		return false;
	end

	sManagerFrame = VuhDoSecureManagerFrame;
	sShadowHeader = VuhDoShadowGroupHeader;

	if not sManagerFrame or not sShadowHeader then
		return false;
	end

	if VUHDO_INTERNAL_TOGGLES and VUHDO_INTERNAL_TOGGLES[VUHDO_UPDATE_PETS] then
		sShadowPetHeader = VuhDoShadowPetHeader;

		if not sShadowPetHeader then
			VUHDO_Msg("Warning: Pet shadow header frame not found, pet tracking disabled.");
			sShadowPetHeader = nil;
		end
	else
		sShadowPetHeader = nil;
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

	function sManagerFrame:UpdatePanelVisibility()

		VUHDO_updatePanelVisibility();

		return;

	end

	function sManagerFrame:RefreshAuraFramesForButton(aPanelNum, aButtonNum)

		VUHDO_refreshAuraFramesForButton(aPanelNum, aButtonNum);

		return;

	end

	function sShadowHeader:Execute(aBody)

		return SecureHandlerExecute(self, aBody);

	end

	function sShadowHeader:SetFrameRef(aLabel, aRefFrame)

		return SecureHandlerSetFrameRef(self, aLabel, aRefFrame);

	end

	if sShadowPetHeader then
		function sShadowPetHeader:Execute(aBody)

			return SecureHandlerExecute(self, aBody);

		end

		function sShadowPetHeader:SetFrameRef(aLabel, aRefFrame)

			return SecureHandlerSetFrameRef(self, aLabel, aRefFrame);

		end
	end

	sManagerFrame:SetFrameRef("sShadowHeader", sShadowHeader);

	if sShadowPetHeader then
		sManagerFrame:SetFrameRef("sShadowPetHeader", sShadowPetHeader);
	end

	tHasPetHeader = sShadowPetHeader ~= nil;

	sManagerFrame:Execute(format([=[
		sManager = self;
		sShadowHeader = self:GetFrameRef("sShadowHeader");

		if %s then
			sShadowPetHeader = self:GetFrameRef("sShadowPetHeader");
		else
			sShadowPetHeader = nil;
		end

		sRealButtons = newtable();
		sButtonToUnit = newtable();

		for tPanelNum = 1, 10 do
			sRealButtons[tPanelNum] = newtable();
			sButtonToUnit[tPanelNum] = newtable();
		end

		sUnitMap = newtable();
		sShadowToRealMap = newtable();
		sShadowButtonHasMapping = newtable();

		for tShadowId = 1, 80 do
			sShadowButtonHasMapping[tShadowId] = false;
		end

		sNextFallbackButton = newtable();
		sFallbackButtonStart = newtable();

		sProcessQueue = newtable();
		sClearQueue = newtable();
		sProcessQueuePool = newtable();
		sShadowLastUnit = newtable();
		sShadowClearedUnit = newtable();

		sPendingRefresh = false;

		sMaxShadowButtons = 80;

		if sShadowPetHeader then
			sShadowPetButtons = newtable();
			sPetProcessQueue = newtable();
			sPetClearQueue = newtable();
			sPetShadowLastUnit = newtable();
			sPetShadowClearedUnit = newtable();
			sFallbackPetUnits = newtable();
		else
			sShadowPetButtons = nil;
			sPetProcessQueue = nil;
			sPetClearQueue = nil;
			sPetShadowLastUnit = nil;
			sPetShadowClearedUnit = nil;
			sFallbackPetUnits = nil;
		end

		sFallbackPlayerUnits = newtable();
		sIsPetsLastEnabled = false;

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
			tPoolEntry["inUse"] = false;

			tinsert(sFallbackMappingPool, tPoolEntry);

			local tQueueEntry = newtable();
			tinsert(sProcessQueuePool, tQueueEntry);
		end

		sFallbackPoolIndex = 1;

		sFreePoolIndices = newtable();

		for tIdx = 1, sMaxShadowButtons do
			tinsert(sFreePoolIndices, tIdx);
		end

		sIsDebugEnabled = false;
		sUnitToPoolIndex = newtable();
	]=], tostring(tHasPetHeader)));

	VUHDO_updateSecureFallbackConfig();

	sManagerFrame:Execute(format([=[
		sNextFallbackButton[%d] = 1;
		sFallbackButtonStart[%d] = 1;
	]=], tFallbackPanel, tFallbackPanel));

	if VUHDO_CONFIG["COMBAT_ROSTER"]["debug"] then
		sManagerFrame:Execute([=[
			sIsDebugEnabled = true;
		]=]);
	end

	sManagerFrame:SetAttribute("vuhdo_process_unit_method", [=[
		local tUnit, tShadowButtonId, tOldUnit = ...;

		if not tShadowButtonId or tShadowButtonId < 1 or tShadowButtonId > 40 then
			if sIsDebugEnabled then
				print("[VuhDo] WARNING: Invalid player shadow ID:", tostring(tShadowButtonId));
			end

			return;
		end

		if sIsDebugEnabled then
			print("[VuhDo] Queueing unit:", tUnit, "shadow:", tShadowButtonId, "oldUnit:", tostring(tOldUnit));
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

		if not tShadowButtonId or tShadowButtonId < 1 or tShadowButtonId > 40 then
			if sIsDebugEnabled then
				print("[VuhDo] WARNING: Invalid player shadow ID:", tostring(tShadowButtonId));
			end

			return;
		end

		if sIsDebugEnabled then
			print("[VuhDo] Queueing clear for unit:", tUnit, "shadow:", tShadowButtonId);
		end

		sShadowClearedUnit[tShadowButtonId] = tUnit;
		sShadowLastUnit[tShadowButtonId] = nil;

		sClearQueue[tShadowButtonId] = tUnit;

		sPendingRefresh = true;

		sManager:SetAttribute("state-vuhdo_batch_timer", "process");
	]=]);

	sManagerFrame:SetAttribute("vuhdo_clear_button_unit_method", [=[
		local tPanelNum, tButtonNum, tOldUnit, anIsHideFallback = ...;

		local tPanelButtons = tPanelNum and sRealButtons[tPanelNum];
		local tRealButton = tPanelButtons and tButtonNum and tPanelButtons[tButtonNum];

		if tRealButton then
			tRealButton:SetAttribute("unit", nil);

			if sButtonToUnit[tPanelNum] then
				sButtonToUnit[tPanelNum][tButtonNum] = nil;
			end

			sManager:CallMethod("RefreshAuraFramesForButton", tPanelNum, tButtonNum);

			if tPanelNum == sFallbackPanel and tOldUnit then
				local tIsPetUnit = string.find(strlower(tOldUnit), "pet") ~= nil;
				local tFoundInFallback = false;

				if tIsPetUnit and sFallbackPetUnits and sFallbackPetUnits[tPanelNum] then
					for tIdx = 1, #sFallbackPetUnits[tPanelNum] do
						if sFallbackPetUnits[tPanelNum][tIdx] == tOldUnit then
							tremove(sFallbackPetUnits[tPanelNum], tIdx);
							tFoundInFallback = true;

							if sIsDebugEnabled then
								print("[VuhDo] Removed pet from fallback list:", tOldUnit);
							end

							break;
						end
					end
				elseif not tIsPetUnit and sFallbackPlayerUnits[tPanelNum] then
					for tIdx = 1, #sFallbackPlayerUnits[tPanelNum] do
						if sFallbackPlayerUnits[tPanelNum][tIdx] == tOldUnit then
							tremove(sFallbackPlayerUnits[tPanelNum], tIdx);
							tFoundInFallback = true;

							if sIsDebugEnabled then
								print("[VuhDo] Removed player from fallback list:", tOldUnit);
							end

							break;
						end
					end
				end

				if sIsPetsLastEnabled and tFoundInFallback then
					sManager:RunAttribute("vuhdo_reassign_fallback_buttons_method", tPanelNum);
				end
			end

			if anIsHideFallback then
				tRealButton:Hide();
			end

			if sIsDebugEnabled then
				local tAfterUnit = tRealButton:GetAttribute("unit");
				local tIsShown = tRealButton:IsShown();
				local tParent = tRealButton:GetParent();
				local tParentShown = tParent and tParent:IsShown();
				local tParentName = tParent and tParent:GetName();

				print("[VuhDo] Cleared button panel:", tPanelNum, "button:", tButtonNum, "unit:", tOldUnit, "afterUnit:", tostring(tAfterUnit), "isShown:", tIsShown, "parent:", tostring(tParentName), "parentShown:", tostring(tParentShown));
			end
		end
	]=]);

	sManagerFrame:SetAttribute("vuhdo_assign_unit_to_button_method", [=[
		local tPanelNum, tButtonNum, tUnit, anIsShow = ...;

		local tPanelButtons = tPanelNum and sRealButtons[tPanelNum];
		local tRealButton = tPanelButtons and tButtonNum and tPanelButtons[tButtonNum];

		if tRealButton then
			tRealButton:SetAttribute("unit", tUnit);

			sButtonToUnit[tPanelNum][tButtonNum] = tUnit;

			sManager:CallMethod("RefreshAuraFramesForButton", tPanelNum, tButtonNum);

			if anIsShow then
				tRealButton:Show();

				RegisterUnitWatch(tRealButton);
			end
		end
	]=]);

	sManagerFrame:SetAttribute("vuhdo_process_pet_unit_method", [=[
		if not sShadowPetHeader then
			return;
		end

		local tUnit, tShadowButtonId, tOldUnit = ...;

		if not tShadowButtonId or tShadowButtonId < 41 or tShadowButtonId > 80 then
			if sIsDebugEnabled then
				print("[VuhDo] WARNING: Invalid pet shadow ID:", tostring(tShadowButtonId));
			end

			return;
		end

		if sIsDebugEnabled then
			print("[VuhDo] Queueing pet unit:", tUnit, "shadow:", tShadowButtonId, "oldUnit:", tostring(tOldUnit));
		end

		local tQueueData = sPetProcessQueue[tShadowButtonId];

		if not tQueueData then
			local tPoolSize = #sProcessQueuePool;

			if tPoolSize > 0 then
				tQueueData = sProcessQueuePool[tPoolSize];
				sProcessQueuePool[tPoolSize] = nil;
			else
				tQueueData = newtable();
			end

			sPetProcessQueue[tShadowButtonId] = tQueueData;
		else
			wipe(tQueueData);
		end

		local tPrevUnit = sPetShadowClearedUnit[tShadowButtonId];

		if tPrevUnit then
			sPetShadowClearedUnit[tShadowButtonId] = nil;
		elseif sPetShadowLastUnit[tShadowButtonId] then
			tPrevUnit = sPetShadowLastUnit[tShadowButtonId];
		else
			tPrevUnit = tOldUnit;
		end

		tQueueData[1] = tUnit;
		tQueueData[2] = tPrevUnit;

		sPetShadowLastUnit[tShadowButtonId] = tUnit;

		if sPetClearQueue[tShadowButtonId] == tUnit then
			sPetClearQueue[tShadowButtonId] = nil;
		end

		sPendingRefresh = true;

		sManager:SetAttribute("state-vuhdo_batch_timer", "process");
	]=]);

	sManagerFrame:SetAttribute("vuhdo_clear_pet_unit_method", [=[
		if not sShadowPetHeader then
			return;
		end

		local tUnit, tShadowButtonId = ...;

		if not tShadowButtonId or tShadowButtonId < 41 or tShadowButtonId > 80 then
			if sIsDebugEnabled then
				print("[VuhDo] WARNING: Invalid pet shadow ID:", tostring(tShadowButtonId));
			end

			return;
		end

		if sIsDebugEnabled then
			print("[VuhDo] Queueing clear for pet unit:", tUnit, "shadow:", tShadowButtonId);
		end

		sPetShadowClearedUnit[tShadowButtonId] = tUnit;
		sPetShadowLastUnit[tShadowButtonId] = nil;

		sPetClearQueue[tShadowButtonId] = tUnit;

		sPendingRefresh = true;

		sManager:SetAttribute("state-vuhdo_batch_timer", "process");
	]=]);

	sManagerFrame:SetAttribute("vuhdo_reassign_fallback_buttons_method", [=[
		local tFallbackPanel = ...;

		if not tFallbackPanel or tFallbackPanel <= 0 then
			return;
		end

		local tPlayerUnits = sFallbackPlayerUnits[tFallbackPanel];
		local tPetUnits = sFallbackPetUnits and sFallbackPetUnits[tFallbackPanel];

		if not tPlayerUnits then
			return;
		end

		local tFallbackPanelButtons = sRealButtons[tFallbackPanel];

		if not tFallbackPanelButtons then
			return;
		end

		local tStartButton = sFallbackButtonStart[tFallbackPanel] or 1;
		local tButtonIndex = tStartButton;
		local tMaxButtonIndex = 80;

		if sIsDebugEnabled then
			print("[VuhDo] Reassigning fallback buttons: players=", #tPlayerUnits, "pets=", tPetUnits and #tPetUnits or 0);
		end

		for tIdx = 1, #tPlayerUnits do
			if tButtonIndex > tMaxButtonIndex then
				if sIsDebugEnabled then
					print("[VuhDo] WARNING: Fallback exceeded max buttons, truncating player units");
				end

				break;
			end

			local tUnit = tPlayerUnits[tIdx];
			local tButton = tFallbackPanelButtons[tButtonIndex];

			if tButton then
				tButton:SetAttribute("unit", tUnit);

				if sButtonToUnit[tFallbackPanel] then
					sButtonToUnit[tFallbackPanel][tButtonIndex] = tUnit;
				end

				sManager:CallMethod("RefreshAuraFramesForButton", tFallbackPanel, tButtonIndex);

				tButton:Show();

				RegisterUnitWatch(tButton);

				if sIsDebugEnabled then
					print("[VuhDo]   Button", tButtonIndex, "->", tUnit, "(player)");
				end
			end

			tButtonIndex = tButtonIndex + 1;
		end

		if tPetUnits then
			for tIdx = 1, #tPetUnits do
				if tButtonIndex > tMaxButtonIndex then
					if sIsDebugEnabled then
						print("[VuhDo] WARNING: Fallback exceeded max buttons, truncating pet units");
					end

					break;
				end

				local tUnit = tPetUnits[tIdx];
				local tButton = tFallbackPanelButtons[tButtonIndex];

				if tButton then
					tButton:SetAttribute("unit", tUnit);

					if sButtonToUnit[tFallbackPanel] then
						sButtonToUnit[tFallbackPanel][tButtonIndex] = tUnit;
					end

					sManager:CallMethod("RefreshAuraFramesForButton", tFallbackPanel, tButtonIndex);

					tButton:Show();

					RegisterUnitWatch(tButton);

					if sIsDebugEnabled then
						print("[VuhDo]   Button", tButtonIndex, "->", tUnit, "(pet)");
					end
				end

				tButtonIndex = tButtonIndex + 1;
			end
		end
	]=]);

	sManagerFrame:SetAttribute("vuhdo_release_pool_entry_method", [=[
		local tUnit = ...;

		if not tUnit then
			return;
		end

		local tPoolIdx = sUnitToPoolIndex[tUnit];

		if tPoolIdx and sFallbackMappingPool[tPoolIdx] then
			sFallbackMappingPool[tPoolIdx]["inUse"] = false;
			tinsert(sFreePoolIndices, tPoolIdx);

			if sIsDebugEnabled then
				print("[VuhDo] Released pool entry:", tPoolIdx, "for unit:", tUnit);
			end
		end

		sUnitToPoolIndex[tUnit] = nil;
		sUnitMap[tUnit] = nil;
	]=]);

	sManagerFrame:SetAttribute("vuhdo_search_and_clear_unit_method", [=[
		local tOldUnit, tHasPreMapping = ...;

		if not tOldUnit then
			return false;
		end

		local tFoundButton = false;

		for tPanelNum = 1, 10 do
			if sButtonToUnit[tPanelNum] then
				for tButtonIndex, tMappedUnit in pairs(sButtonToUnit[tPanelNum]) do
					if tMappedUnit == tOldUnit then
						tFoundButton = true;

						local tPanelButtons = sRealButtons[tPanelNum];
						local tCheckButton = tPanelButtons and tPanelButtons[tButtonIndex];

						if tCheckButton then
							if sIsDebugEnabled then
								print("[VuhDo] Found and clearing unit:", tOldUnit, "from button:", tButtonIndex, "panel:", tPanelNum, "preMapped:", tHasPreMapping);
							end

							tCheckButton:SetAttribute("unit", nil);

							sManager:CallMethod("RefreshAuraFramesForButton", tPanelNum, tButtonIndex);

							sButtonToUnit[tPanelNum][tButtonIndex] = nil;

							if not tHasPreMapping then
								tCheckButton:Hide();
							end
						end
					end
				end
			end
		end

		return tFoundButton;
	]=]);

	sManagerFrame:SetAttribute("vuhdo_process_clear_queue_method", [=[
		for tShadowButtonId, tOldUnit in pairs(sClearQueue) do
			if not tShadowButtonId or tShadowButtonId < 1 or tShadowButtonId > 40 then
				if sIsDebugEnabled then
					print("[VuhDo] WARNING: Invalid player shadow ID in clear queue:", tostring(tShadowButtonId));
				end
			else
				if sIsDebugEnabled then
					print("[VuhDo] Clear queue entry: shadow:", tShadowButtonId, "oldUnit:", tostring(tOldUnit));
				end

				local tHasPreMapping = sShadowButtonHasMapping[tShadowButtonId];

				if tOldUnit then
					if sIsDebugEnabled then
						print("[VuhDo] Processing clear for unit:", tOldUnit, "shadow:", tShadowButtonId, "hasPreMapping:", tHasPreMapping);
					end

					local tMappings;

					if tHasPreMapping then
						tMappings = sShadowToRealMap[tShadowButtonId];

						if sIsDebugEnabled and not tMappings then
							print("[VuhDo] WARNING: sShadowToRealMap[", tShadowButtonId, "] is nil for unit:", tOldUnit, "- mapping may be stale or missing");
						end
					else
						tMappings = sUnitMap[tOldUnit];

						if sIsDebugEnabled and not tMappings then
							print("[VuhDo] sUnitMap[", tOldUnit, "] is nil (fallback unit)");
						end
					end

					if tMappings then
						if sIsDebugEnabled then
							print("[VuhDo] Found mappings for unit:", tOldUnit, "count:", #tMappings);
						end

						local tMappingsCount = #tMappings;
						local tClearedAnyButton = false;

						for tMappingIdx = 1, tMappingsCount do
							local tMapping = tMappings[tMappingIdx];
							local tPanelNum = tMapping[1];
							local tButtonNum = tMapping[2];

							local tPanelButtons = tPanelNum and sRealButtons[tPanelNum];
							local tRealButton = tPanelButtons and tButtonNum and tPanelButtons[tButtonNum];

							if tRealButton then
								local tShouldClear = true;

								if tHasPreMapping then
									local tCurrentUnit = tRealButton:GetAttribute("unit");

									tShouldClear = tCurrentUnit == tOldUnit;
								end

								if tShouldClear then
									tClearedAnyButton = true;

									sManager:RunAttribute("vuhdo_clear_button_unit_method", tPanelNum, tButtonNum, tOldUnit, false);
								elseif sIsDebugEnabled and tHasPreMapping then
									local tCurrentUnit = tRealButton:GetAttribute("unit");

									print("[VuhDo] Skipped clearing pre-mapped button panel:", tPanelNum, "button:", tButtonNum, "current unit:", tCurrentUnit, "old unit:", tOldUnit);
								end
							end
						end

						if not tHasPreMapping and tClearedAnyButton then
							sManager:RunAttribute("vuhdo_release_pool_entry_method", tOldUnit);
						end

						if tHasPreMapping and sShadowClearedUnit[tShadowButtonId] == tOldUnit then
							sShadowClearedUnit[tShadowButtonId] = nil;
						end
					else
						if sIsDebugEnabled then
							if tHasPreMapping then
								print("[VuhDo] WARNING: No mapping found for pre-mapped unit:", tOldUnit, "shadow:", tShadowButtonId, "- mapping is stale, searching for buttons with this unit");
							else
								print("[VuhDo] No mapping found for fallback unit:", tOldUnit, "searching panels...");
							end
						end

						local tFoundButton = sManager:RunAttribute("vuhdo_search_and_clear_unit_method", tOldUnit, tHasPreMapping);

						if sShadowClearedUnit[tShadowButtonId] == tOldUnit then
							sShadowClearedUnit[tShadowButtonId] = nil;
						end

						if tFoundButton then
							if not tHasPreMapping and sUnitMap[tOldUnit] then
								sManager:RunAttribute("vuhdo_release_pool_entry_method", tOldUnit);
							end
						else
							if sIsDebugEnabled then
								print("[VuhDo] WARNING: Could not find button for unit:", tOldUnit, "shadow:", tShadowButtonId, "preMapped:", tHasPreMapping, "- mapping may have been cleared already");
							end
						end
					end
				else
					if sIsDebugEnabled then
						print("[VuhDo] WARNING: Skipping clear queue entry - shadow:", tShadowButtonId, "oldUnit:", tostring(tOldUnit));
					end
				end
			end
		end
	]=]);

	sManagerFrame:SetAttribute("vuhdo_process_pet_clear_queue_method", [=[
		if not sShadowPetHeader or not sPetClearQueue then
			return;
		end

		for tShadowButtonId, tOldUnit in pairs(sPetClearQueue) do
			if not tShadowButtonId or tShadowButtonId < 41 or tShadowButtonId > 80 then
				if sIsDebugEnabled then
					print("[VuhDo] WARNING: Invalid pet shadow ID in clear queue:", tostring(tShadowButtonId));
				end
			else
				if sIsDebugEnabled then
					print("[VuhDo] Pet clear queue entry: shadow:", tShadowButtonId, "oldUnit:", tostring(tOldUnit));
				end

				local tHasPreMapping = sShadowButtonHasMapping[tShadowButtonId];

				if tOldUnit then
					if sIsDebugEnabled then
						print("[VuhDo] Processing pet clear for unit:", tOldUnit, "shadow:", tShadowButtonId, "hasPreMapping:", tHasPreMapping);
					end

					local tMappings;

					if tHasPreMapping then
						tMappings = sShadowToRealMap[tShadowButtonId];
					else
						tMappings = sUnitMap[tOldUnit];
					end

					if tMappings then
						local tMappingsCount = #tMappings;
						local tClearedAnyButton = false;

						for tMappingIdx = 1, tMappingsCount do
							local tMapping = tMappings[tMappingIdx];
							local tPanelNum = tMapping[1];
							local tButtonNum = tMapping[2];

							local tPanelButtons = tPanelNum and sRealButtons[tPanelNum];
							local tRealButton = tPanelButtons and tButtonNum and tPanelButtons[tButtonNum];

							if tRealButton then
								local tShouldClear = true;

								if tHasPreMapping then
									local tCurrentUnit = tRealButton:GetAttribute("unit");
									tShouldClear = tCurrentUnit == tOldUnit;
								end

								if tShouldClear then
									tClearedAnyButton = true;
									sManager:RunAttribute("vuhdo_clear_button_unit_method", tPanelNum, tButtonNum, tOldUnit, false);
								end
							end
						end

						if not tHasPreMapping and tClearedAnyButton then
							sManager:RunAttribute("vuhdo_release_pool_entry_method", tOldUnit);
						end

						if tHasPreMapping and sPetShadowClearedUnit[tShadowButtonId] == tOldUnit then
							sPetShadowClearedUnit[tShadowButtonId] = nil;
						end
					else
						if sIsDebugEnabled then
							if tHasPreMapping then
								print("[VuhDo] WARNING: No mapping found for pre-mapped pet:", tOldUnit, "shadow:", tShadowButtonId, "- mapping may be stale or missing");
							else
								print("[VuhDo] No mapping found for fallback pet:", tOldUnit, "searching panels...");
							end
						end

						local tFoundButton = sManager:RunAttribute("vuhdo_search_and_clear_unit_method", tOldUnit, tHasPreMapping);

						if sPetShadowClearedUnit[tShadowButtonId] == tOldUnit then
							sPetShadowClearedUnit[tShadowButtonId] = nil;
						end

						if tFoundButton then
							if not tHasPreMapping and sUnitMap[tOldUnit] then
								sManager:RunAttribute("vuhdo_release_pool_entry_method", tOldUnit);
							end
						else
							if sIsDebugEnabled then
								print("[VuhDo] WARNING: Could not find button for pet:", tOldUnit, "shadow:", tShadowButtonId, "preMapped:", tHasPreMapping);
							end
						end
					end
				end
			end
		end
	]=]);

	sManagerFrame:SetAttribute("vuhdo_process_premapped_units_method", [=[
		for tShadowButtonId, tQueueData in pairs(sProcessQueue) do
			if not tShadowButtonId or tShadowButtonId < 1 or tShadowButtonId > 40 then
				if sIsDebugEnabled then
					print("[VuhDo] WARNING: Invalid player shadow ID in premapped:", tostring(tShadowButtonId));
				end
			else
				local tHasPreMapping = sShadowButtonHasMapping[tShadowButtonId];

				if tHasPreMapping then
					local tUnit = tQueueData[1];
					local tOldUnit = tQueueData[2];

					if sIsDebugEnabled then
						print("[VuhDo] Phase 2 processing: shadow:", tShadowButtonId, "unit:", tUnit, "oldUnit:", tostring(tOldUnit));
					end

					local tMappings = sShadowToRealMap[tShadowButtonId];

					if tMappings and #tMappings > 0 then
						if tUnit then
							local tFallbackMappings = sUnitMap[tUnit];

							if tFallbackMappings then
								if sIsDebugEnabled then
									print("[VuhDo] Phase 2: Unit has fallback mappings, clearing - unit:", tUnit, "count:", #tFallbackMappings);
								end

								local tFallbackMappingsCount = #tFallbackMappings;

								for tMappingIdx = 1, tFallbackMappingsCount do
									local tMapping = tFallbackMappings[tMappingIdx];
									local tPanelNum = tMapping[1];
									local tButtonNum = tMapping[2];

									local tPanelButtons = tPanelNum and sRealButtons[tPanelNum];
									local tFallbackButton = tPanelButtons and tButtonNum and tPanelButtons[tButtonNum];

									if tFallbackButton then
										local tCurrentUnit = tFallbackButton:GetAttribute("unit");

										if tCurrentUnit == tUnit and tCurrentUnit ~= "player" then
											sManager:RunAttribute("vuhdo_clear_button_unit_method", tPanelNum, tButtonNum, tUnit, true);
										end
									end
								end

								sManager:RunAttribute("vuhdo_release_pool_entry_method", tUnit);
							end

							local tMappingsCount = #tMappings;

							for tMappingIdx = 1, tMappingsCount do
								local tMapping = tMappings[tMappingIdx];
								local tPanelNum = tMapping[1];
								local tButtonNum = tMapping[2];

								if sIsDebugEnabled then
									print("[VuhDo] Phase 2: Assigning unit to premapped button - panel:", tPanelNum, "button:", tButtonNum, "unit:", tUnit);
								end

								sManager:RunAttribute("vuhdo_assign_unit_to_button_method", tPanelNum, tButtonNum, tUnit, true);
							end
						else
							local tMappingsCount = #tMappings;

							for tMappingIdx = 1, tMappingsCount do
								local tMapping = tMappings[tMappingIdx];
								local tPanelNum = tMapping[1];
								local tButtonNum = tMapping[2];

								if sIsDebugEnabled then
									print("[VuhDo] Phase 2: Clearing premapped button - panel:", tPanelNum, "button:", tButtonNum, "oldUnit:", tostring(tOldUnit));
								end

								sManager:RunAttribute("vuhdo_clear_button_unit_method", tPanelNum, tButtonNum, tOldUnit, false);
							end

							sShadowButtonHasMapping[tShadowButtonId] = false;
							sShadowToRealMap[tShadowButtonId] = nil;
						end
					else
						if sIsDebugEnabled then
							print("[VuhDo] Phase 2: No valid mappings for shadow:", tShadowButtonId, "clearing flag");
						end

						sShadowButtonHasMapping[tShadowButtonId] = false;
						sShadowToRealMap[tShadowButtonId] = nil;
					end
				end
			end
		end
	]=]);

	sManagerFrame:SetAttribute("vuhdo_process_fallback_units_method", [=[
		for tShadowButtonId, tQueueData in pairs(sProcessQueue) do
			if not tShadowButtonId or tShadowButtonId < 1 or tShadowButtonId > 40 then
				if sIsDebugEnabled then
					print("[VuhDo] WARNING: Invalid player shadow ID in fallback:", tostring(tShadowButtonId));
				end
			else
				local tHasPreMapping = sShadowButtonHasMapping[tShadowButtonId];

				if sIsDebugEnabled then
					local tUnit = tQueueData[1];
					local tOldUnit = tQueueData[2];

					print("[VuhDo] Processing queue entry shadow:", tShadowButtonId, "unit:", tostring(tUnit), "oldUnit:", tostring(tOldUnit), "hasPreMapping:", tHasPreMapping);
				end

				if not tHasPreMapping then
					local tUnit = tQueueData[1];
					local tOldUnit = tQueueData[2];

					if sIsDebugEnabled then
						print("[VuhDo] Phase 3 fallback processing for unit:", tUnit, "oldUnit:", tostring(tOldUnit));
					end

					if tUnit ~= "player" then
						local tMappings = sUnitMap[tUnit];

						if sIsDebugEnabled then
							print("[VuhDo] Phase 3 Case 3A check: unit:", tUnit, "hasMapping:", tMappings ~= nil);
						end

						if tMappings then
							local tMappingsCount = #tMappings;

							for tMappingIdx = 1, tMappingsCount do
								local tMapping = tMappings[tMappingIdx];
								local tPanelNum = tMapping[1];
								local tButtonNum = tMapping[2];

								local tPanelButtons = tPanelNum and sRealButtons[tPanelNum];
								local tRealButton = tPanelButtons and tButtonNum and tPanelButtons[tButtonNum];

								if tRealButton then
									sManager:RunAttribute("vuhdo_assign_unit_to_button_method", tPanelNum, tButtonNum, tUnit, true);
								end
							end
						elseif tOldUnit and tUnit ~= tOldUnit and sUnitMap[tOldUnit] then
							if sIsDebugEnabled then
								print("[VuhDo] Phase 3 Case 3B: Reusing old unit mapping for unit:", tUnit, "oldUnit:", tOldUnit);
							end

							sUnitMap[tUnit] = sUnitMap[tOldUnit];
							sUnitMap[tOldUnit] = nil;

							local tPoolIdx = sUnitToPoolIndex[tOldUnit];

							if tPoolIdx then
								sUnitToPoolIndex[tUnit] = tPoolIdx;
								sUnitToPoolIndex[tOldUnit] = nil;

								if sIsDebugEnabled then
									print("[VuhDo] Transferred pool entry:", tPoolIdx, "from unit:", tOldUnit, "to unit:", tUnit);
								end
							end

							local tReassignedMappings = sUnitMap[tUnit];

							if tReassignedMappings then
								local tReassignedMappingsCount = #tReassignedMappings;

								for tMappingIdx = 1, tReassignedMappingsCount do
									local tMapping = tReassignedMappings[tMappingIdx];
									local tPanelNum = tMapping[1];
									local tButtonNum = tMapping[2];

									local tPanelButtons = tPanelNum and sRealButtons[tPanelNum];
									local tRealButton = tPanelButtons and tButtonNum and tPanelButtons[tButtonNum];

									if tRealButton then
										local tCurrentUnit = tRealButton:GetAttribute("unit");

										if tCurrentUnit == tOldUnit or tCurrentUnit == tUnit then
											sManager:RunAttribute("vuhdo_assign_unit_to_button_method", tPanelNum, tButtonNum, tUnit, true);
										end
									end
								end
							end
						else
							if sIsDebugEnabled then
								if tUnit == tOldUnit then
									print("[VuhDo] Phase 3 Case 3C: Token reuse detected - unit:", tUnit, "oldUnit:", tOldUnit, "creating new mapping");
								elseif tOldUnit and not sUnitMap[tOldUnit] then
									print("[VuhDo] Phase 3 Case 3C: Old unit mapping was cleared - unit:", tUnit, "oldUnit:", tOldUnit, "creating new mapping");
								end
							end

							if sIsDebugEnabled then
								print("[VuhDo] Phase 3 Case 3C (new fallback): unit:", tUnit);
							end

							if tUnit and tUnit ~= "player" then
								local tAssignedPanel = nil;
								local tAssignedButtonIndex = nil;

								local tFallbackPanel = sFallbackPanel;

								if tFallbackPanel then
									if not sFallbackPlayerUnits[tFallbackPanel] then
										sFallbackPlayerUnits[tFallbackPanel] = newtable();
									end

									if sFallbackPetUnits then
										if not sFallbackPetUnits[tFallbackPanel] then
											sFallbackPetUnits[tFallbackPanel] = newtable();
										end
									end

									local tPlayerUnits = sFallbackPlayerUnits[tFallbackPanel];
									local tPetUnits = sFallbackPetUnits and sFallbackPetUnits[tFallbackPanel];

									local tAlreadyExists = false;

									for tIdx = 1, #tPlayerUnits do
										if tPlayerUnits[tIdx] == tUnit then
											tAlreadyExists = true;

											break;
										end
									end

									if not tAlreadyExists then
										tinsert(tPlayerUnits, tUnit);

										if sIsDebugEnabled then
											print("[VuhDo] Added player to fallback list:", tUnit, "total players:", #tPlayerUnits);
										end

										if sIsPetsLastEnabled then
											sManager:RunAttribute("vuhdo_reassign_fallback_buttons_method", tFallbackPanel);
										else
											local tStartButton = sFallbackButtonStart[tFallbackPanel] or 1;
											local tPetCount = tPetUnits and #tPetUnits or 0;
											local tButtonIndex = tStartButton + #tPlayerUnits + tPetCount - 1;

											sManager:RunAttribute("vuhdo_assign_unit_to_button_method", tFallbackPanel, tButtonIndex, tUnit, true);
										end

										tAssignedPanel = tFallbackPanel;

										local tStartButton = sFallbackButtonStart[tFallbackPanel] or 1;
										local tPetCount = tPetUnits and #tPetUnits or 0;
										tAssignedButtonIndex = tStartButton + #tPlayerUnits + tPetCount - 1;
									end
								end

								if sIsDebugEnabled then
									print("[VuhDo] Case 3C result: assignedPanel:", tAssignedPanel, "assignedButtonIndex:", tAssignedButtonIndex);
								end

								if tAssignedPanel and tAssignedButtonIndex and tFallbackPanel then
									local tPoolEntry = nil;
									local tPoolIndex = nil;

									local tFreeCount = #sFreePoolIndices;

									if tFreeCount > 0 then
										tPoolIndex = sFreePoolIndices[tFreeCount];
										sFreePoolIndices[tFreeCount] = nil;
										tPoolEntry = sFallbackMappingPool[tPoolIndex];
									end

									if sIsDebugEnabled then
										print("[VuhDo] Pool search: free=", tFreeCount, "allocated=", tPoolIndex or "none");
									end

									if not tPoolEntry then
										local tTempMapping = newtable();
										local tTempMappings = newtable();

										tTempMapping[1] = tAssignedPanel;
										tTempMapping[2] = tAssignedButtonIndex;

										tinsert(tTempMappings, tTempMapping);

										local tNewPoolEntry = newtable();

										tNewPoolEntry[1] = tTempMapping;
										tNewPoolEntry[2] = tTempMappings;
										tNewPoolEntry["inUse"] = true;

										local tNewPoolIdx = #sFallbackMappingPool + 1;
										sFallbackMappingPool[tNewPoolIdx] = tNewPoolEntry;

										sUnitMap[tUnit] = tTempMappings;
										sUnitToPoolIndex[tUnit] = tNewPoolIdx;

										if sIsDebugEnabled then
											print("[VuhDo] Pool exhausted, grew pool to:", tNewPoolIdx, "for unit:", tUnit, "panel:", tAssignedPanel, "button:", tAssignedButtonIndex);
										end
									else
										tPoolEntry["inUse"] = true;

										local tTempMapping = tPoolEntry[1];
										local tTempMappings = tPoolEntry[2];

										tTempMapping[1] = tAssignedPanel;
										tTempMapping[2] = tAssignedButtonIndex;

										sUnitMap[tUnit] = tTempMappings;
										sUnitToPoolIndex[tUnit] = tPoolIndex;

										if sIsDebugEnabled then
											print("[VuhDo] Allocated pool entry:", tPoolIndex, "for unit:", tUnit, "panel:", tAssignedPanel, "button:", tAssignedButtonIndex);
										end
									end
								end
							end
						end
					end
				end
			end
		end
	]=]);

	sManagerFrame:SetAttribute("vuhdo_process_pet_premapped_units_method", [=[
		if not sShadowPetHeader or not sPetProcessQueue then
			return;
		end

		for tShadowButtonId, tQueueData in pairs(sPetProcessQueue) do
			if not tShadowButtonId or tShadowButtonId < 41 or tShadowButtonId > 80 then
				if sIsDebugEnabled then
					print("[VuhDo] WARNING: Invalid pet shadow ID in premapped:", tostring(tShadowButtonId));
				end
			else
				local tHasPreMapping = sShadowButtonHasMapping[tShadowButtonId];

				if tHasPreMapping then
					local tUnit = tQueueData[1];
					local tOldUnit = tQueueData[2];

					if sIsDebugEnabled then
						print("[VuhDo] Pet Phase 2 processing: shadow:", tShadowButtonId, "unit:", tUnit, "oldUnit:", tostring(tOldUnit));
					end

					local tMappings = sShadowToRealMap[tShadowButtonId];

					if tMappings and #tMappings > 0 then
						if tUnit then
							local tFallbackMappings = sUnitMap[tUnit];

							if tFallbackMappings then
								if sIsDebugEnabled then
									print("[VuhDo] Pet Phase 2: Unit has fallback mappings, clearing - unit:", tUnit, "count:", #tFallbackMappings);
								end

								local tFallbackMappingsCount = #tFallbackMappings;

								for tMappingIdx = 1, tFallbackMappingsCount do
									local tMapping = tFallbackMappings[tMappingIdx];
									local tPanelNum = tMapping[1];
									local tButtonNum = tMapping[2];

									local tPanelButtons = tPanelNum and sRealButtons[tPanelNum];
									local tFallbackButton = tPanelButtons and tButtonNum and tPanelButtons[tButtonNum];

									if tFallbackButton then
										local tCurrentUnit = tFallbackButton:GetAttribute("unit");

										if tCurrentUnit == tUnit then
											sManager:RunAttribute("vuhdo_clear_button_unit_method", tPanelNum, tButtonNum, tUnit, true);
										end
									end
								end

								sManager:RunAttribute("vuhdo_release_pool_entry_method", tUnit);
							end

							local tMappingsCount = #tMappings;

							for tMappingIdx = 1, tMappingsCount do
								local tMapping = tMappings[tMappingIdx];
								local tPanelNum = tMapping[1];
								local tButtonNum = tMapping[2];

								if sIsDebugEnabled then
									print("[VuhDo] Pet Phase 2: Assigning unit to premapped button - panel:", tPanelNum, "button:", tButtonNum, "unit:", tUnit);
								end

								sManager:RunAttribute("vuhdo_assign_unit_to_button_method", tPanelNum, tButtonNum, tUnit, true);
							end
						else
							local tMappingsCount = #tMappings;

							for tMappingIdx = 1, tMappingsCount do
								local tMapping = tMappings[tMappingIdx];
								local tPanelNum = tMapping[1];
								local tButtonNum = tMapping[2];

								if sIsDebugEnabled then
									print("[VuhDo] Pet Phase 2: Clearing premapped button - panel:", tPanelNum, "button:", tButtonNum, "oldUnit:", tostring(tOldUnit));
								end

								sManager:RunAttribute("vuhdo_clear_button_unit_method", tPanelNum, tButtonNum, tOldUnit, false);
							end

							sShadowButtonHasMapping[tShadowButtonId] = false;
							sShadowToRealMap[tShadowButtonId] = nil;
						end
					else
						if sIsDebugEnabled then
							print("[VuhDo] Pet Phase 2: No valid mappings for shadow:", tShadowButtonId, "clearing flag");
						end

						sShadowButtonHasMapping[tShadowButtonId] = false;
						sShadowToRealMap[tShadowButtonId] = nil;
					end
				end
			end
		end
	]=]);

	sManagerFrame:SetAttribute("vuhdo_process_pet_fallback_units_method", [=[
		if not sShadowPetHeader or not sPetProcessQueue then
			return;
		end

		for tShadowButtonId, tQueueData in pairs(sPetProcessQueue) do
			if not tShadowButtonId or tShadowButtonId < 41 or tShadowButtonId > 80 then
				if sIsDebugEnabled then
					print("[VuhDo] WARNING: Invalid pet shadow ID in fallback:", tostring(tShadowButtonId));
				end
			else
				local tHasPreMapping = sShadowButtonHasMapping[tShadowButtonId];

				if not tHasPreMapping then
					local tUnit = tQueueData[1];
					local tOldUnit = tQueueData[2];

					if sIsDebugEnabled then
						print("[VuhDo] Pet fallback processing for unit:", tUnit, "oldUnit:", tostring(tOldUnit));
					end

					if tUnit and tUnit ~= "player" then
						local tMappings = sUnitMap[tUnit];

						if sIsDebugEnabled then
							print("[VuhDo] Pet Phase 3 Case A check: unit:", tUnit, "hasMapping:", tMappings ~= nil);
						end

						if tMappings then
							local tMappingsCount = #tMappings;

							for tMappingIdx = 1, tMappingsCount do
								local tMapping = tMappings[tMappingIdx];
								local tPanelNum = tMapping[1];
								local tButtonNum = tMapping[2];

								local tPanelButtons = tPanelNum and sRealButtons[tPanelNum];
								local tRealButton = tPanelButtons and tButtonNum and tPanelButtons[tButtonNum];

								if tRealButton then
									sManager:RunAttribute("vuhdo_assign_unit_to_button_method", tPanelNum, tButtonNum, tUnit, true);
								end
							end
						elseif tOldUnit and tUnit ~= tOldUnit and sUnitMap[tOldUnit] then
							if sIsDebugEnabled then
								print("[VuhDo] Pet Phase 3 Case B: Reusing old unit mapping for unit:", tUnit, "oldUnit:", tOldUnit);
							end

							sUnitMap[tUnit] = sUnitMap[tOldUnit];
							sUnitMap[tOldUnit] = nil;

							local tPoolIdx = sUnitToPoolIndex[tOldUnit];

							if tPoolIdx then
								sUnitToPoolIndex[tUnit] = tPoolIdx;
								sUnitToPoolIndex[tOldUnit] = nil;

								if sIsDebugEnabled then
									print("[VuhDo] Pet transferred pool entry:", tPoolIdx, "from:", tOldUnit, "to:", tUnit);
								end
							end

							local tReassignedMappings = sUnitMap[tUnit];

							if tReassignedMappings then
								local tReassignedMappingsCount = #tReassignedMappings;

								for tMappingIdx = 1, tReassignedMappingsCount do
									local tMapping = tReassignedMappings[tMappingIdx];
									local tPanelNum = tMapping[1];
									local tButtonNum = tMapping[2];

									local tPanelButtons = tPanelNum and sRealButtons[tPanelNum];
									local tRealButton = tPanelButtons and tButtonNum and tPanelButtons[tButtonNum];

									if tRealButton then
										local tCurrentUnit = tRealButton:GetAttribute("unit");

										if tCurrentUnit == tOldUnit or tCurrentUnit == tUnit then
											sManager:RunAttribute("vuhdo_assign_unit_to_button_method", tPanelNum, tButtonNum, tUnit, true);
										end
									end
								end
							end
						else
							local tAssignedPanel = nil;
							local tAssignedButtonIndex = nil;
							local tFallbackPanel = sFallbackPanel;

							if tFallbackPanel then
								if sFallbackPetUnits then
									if not sFallbackPetUnits[tFallbackPanel] then
										sFallbackPetUnits[tFallbackPanel] = newtable();
									end
								end

								if not sFallbackPlayerUnits[tFallbackPanel] then
									sFallbackPlayerUnits[tFallbackPanel] = newtable();
								end

								local tPetUnits = sFallbackPetUnits and sFallbackPetUnits[tFallbackPanel];
								local tPlayerUnits = sFallbackPlayerUnits[tFallbackPanel];

								if tPetUnits then
									local tAlreadyExists = false;

									for tIdx = 1, #tPetUnits do
										if tPetUnits[tIdx] == tUnit then
											tAlreadyExists = true;

											break;
										end
									end

									if not tAlreadyExists then
										tinsert(tPetUnits, tUnit);

										if sIsDebugEnabled then
											print("[VuhDo] Added pet to fallback list:", tUnit, "total pets:", #tPetUnits);
										end

										if sIsPetsLastEnabled then
											sManager:RunAttribute("vuhdo_reassign_fallback_buttons_method", tFallbackPanel);
										else
											local tStartButton = sFallbackButtonStart[tFallbackPanel] or 1;
											local tButtonIndex = tStartButton + #tPlayerUnits + #tPetUnits - 1;

											sManager:RunAttribute("vuhdo_assign_unit_to_button_method", tFallbackPanel, tButtonIndex, tUnit, true);
										end

										tAssignedPanel = tFallbackPanel;

										local tStartButton = sFallbackButtonStart[tFallbackPanel] or 1;
										tAssignedButtonIndex = tStartButton + #tPlayerUnits + #tPetUnits - 1;
									end
								end
							end

							if sIsDebugEnabled then
								print("[VuhDo] Pet fallback result: panel:", tAssignedPanel, "button:", tAssignedButtonIndex);
							end

							if tAssignedPanel and tAssignedButtonIndex and tFallbackPanel then
								local tPoolEntry = nil;
								local tPoolIndex = nil;

								local tFreeCount = #sFreePoolIndices;

								if tFreeCount > 0 then
									tPoolIndex = sFreePoolIndices[tFreeCount];

									sFreePoolIndices[tFreeCount] = nil;

									tPoolEntry = sFallbackMappingPool[tPoolIndex];
								end

								if not tPoolEntry then
									local tTempMapping = newtable();
									local tTempMappings = newtable();

									tTempMapping[1] = tAssignedPanel;
									tTempMapping[2] = tAssignedButtonIndex;
									tinsert(tTempMappings, tTempMapping);

									local tNewPoolEntry = newtable();

									tNewPoolEntry[1] = tTempMapping;
									tNewPoolEntry[2] = tTempMappings;
									tNewPoolEntry["inUse"] = true;

									local tNewPoolIdx = #sFallbackMappingPool + 1;
									sFallbackMappingPool[tNewPoolIdx] = tNewPoolEntry;

									sUnitMap[tUnit] = tTempMappings;
									sUnitToPoolIndex[tUnit] = tNewPoolIdx;

									if sIsDebugEnabled then
										print("[VuhDo] Pool exhausted, grew pool to:", tNewPoolIdx, "for pet unit:", tUnit, "panel:", tAssignedPanel, "button:", tAssignedButtonIndex);
									end
								else
									tPoolEntry["inUse"] = true;

									local tTempMapping = tPoolEntry[1];
									local tTempMappings = tPoolEntry[2];

									tTempMapping[1] = tAssignedPanel;
									tTempMapping[2] = tAssignedButtonIndex;

									sUnitMap[tUnit] = tTempMappings;

									sUnitToPoolIndex[tUnit] = tPoolIndex;
								end
							end
						end
					end
				end
			end
		end
	]=]);

	sManagerFrame:SetAttribute("_onstate-vuhdo_batch_timer", [=[
		if newstate ~= "process" and sPendingRefresh then
			if sIsDebugEnabled then
				local tClearCount = 0;
				local tProcessCount = 0;
				local tPetClearCount = 0;
				local tPetProcessCount = 0;

				for _ in pairs(sClearQueue) do
					tClearCount = tClearCount + 1;
				end

				for _ in pairs(sProcessQueue) do
					tProcessCount = tProcessCount + 1;
				end

				if sPetClearQueue then
					for _ in pairs(sPetClearQueue) do
						tPetClearCount = tPetClearCount + 1;
					end
				end

				if sPetProcessQueue then
					for _ in pairs(sPetProcessQueue) do
						tPetProcessCount = tPetProcessCount + 1;
					end
				end

				print("[VuhDo] Batch processing triggered, player clear:", tClearCount, "player process:", tProcessCount, "pet clear:", tPetClearCount, "pet process:", tPetProcessCount);
			end

			local tHasPetQueues = (sPetClearQueue and next(sPetClearQueue)) or (sPetProcessQueue and next(sPetProcessQueue));

			if not next(sClearQueue) and not next(sProcessQueue) and not tHasPetQueues then
				if sIsDebugEnabled then
					print("[VuhDo] Queues empty, skipping batch processing");
				end

				sPendingRefresh = false;

				return;
			end

			sManager:RunAttribute("vuhdo_process_clear_queue_method");

			if sShadowPetHeader then
				sManager:RunAttribute("vuhdo_process_pet_clear_queue_method");
			end

			sManager:RunAttribute("vuhdo_process_premapped_units_method");
			sManager:RunAttribute("vuhdo_process_fallback_units_method");

			if sShadowPetHeader then
				sManager:RunAttribute("vuhdo_process_pet_premapped_units_method");
				sManager:RunAttribute("vuhdo_process_pet_fallback_units_method");
			end

			if sIsDebugEnabled then
				local tProcessCountBefore = 0;

				for _ in pairs(sProcessQueue) do
					tProcessCountBefore = tProcessCountBefore + 1;
				end

				local tClearCountBefore = 0;

				for _ in pairs(sClearQueue) do
					tClearCountBefore = tClearCountBefore + 1;
				end

				if tProcessCountBefore > 0 or tClearCountBefore > 0 then
					print("[VuhDo] Cleanup: clearing p:", tProcessCountBefore, "c:", tClearCountBefore);
				end
			end

			for tShadowButtonId, tQueueData in pairs(sProcessQueue) do
				wipe(tQueueData);

				tinsert(sProcessQueuePool, tQueueData);

				sProcessQueue[tShadowButtonId] = nil;
			end

			if sPetProcessQueue then
				for tShadowButtonId, tQueueData in pairs(sPetProcessQueue) do
					wipe(tQueueData);
					tinsert(sProcessQueuePool, tQueueData);
					sPetProcessQueue[tShadowButtonId] = nil;
				end
			end

			wipe(sClearQueue);

			if sPetClearQueue then
				wipe(sPetClearQueue);
			end

			sPendingRefresh = false;

			sManager:CallMethod("UpdatePanelVisibility");

			if sIsDebugEnabled then
				local tProcessCount = 0;

				for _ in pairs(sProcessQueue) do
					tProcessCount = tProcessCount + 1;
				end

				local tClearCount = 0;

				for _ in pairs(sClearQueue) do
					tClearCount = tClearCount + 1;
				end

				if tProcessCount > 0 or tClearCount > 0 or sPendingRefresh then
					print("[VuhDo] WARNING: Cleanup failed: p:", tProcessCount, "c:", tClearCount, "pending:", sPendingRefresh);
				end
			end
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

	if sShadowPetHeader then
		sShadowPetHeader:SetFrameRef("sManager", sManagerFrame);

		sShadowPetHeader:Execute([=[
			sManager = self:GetFrameRef("sManager");

			sShadowPetButtons = newtable();
		]=]);

		sShadowPetHeader:SetAttribute("showPlayer", true);
		sShadowPetHeader:SetAttribute("showSolo", true);
		sShadowPetHeader:SetAttribute("showParty", true);
		sShadowPetHeader:SetAttribute("showRaid", true);
		sShadowPetHeader:SetAttribute("groupFilter", "1,2,3,4,5,6,7,8");
		sShadowPetHeader:SetAttribute("groupBy", nil);
		sShadowPetHeader:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8");
		sShadowPetHeader:SetAttribute("sortMethod", "INDEX");
		sShadowPetHeader:SetAttribute("template", "VuhDoShadowPetButtonTemplate");
		sShadowPetHeader:SetAttribute("maxColumns", 1);
		sShadowPetHeader:SetAttribute("unitsPerColumn", 40);
		sShadowPetHeader:SetAttribute("point", "TOP");
		sShadowPetHeader:SetAttribute("yOffset", 0);
		sShadowPetHeader:SetAttribute("initialConfigFunction", tPetInitConfigFunc);
		sShadowPetHeader:SetAttribute("startingIndex", -39);
		sShadowPetHeader:Show();
		sShadowPetHeader:SetAttribute("startingIndex", 1);

		for tCnt = 1, 40 do
			tChild = sShadowPetHeader:GetAttribute("child" .. tCnt);

			if tChild then
				tChild:SetAttribute("_onattributechanged", tOnPetAttributeChanged);
			end
		end
	end

	sInitialized = true;

	VUHDO_registerAllSecureButtons();

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
local tPanelButtons;
local tButton;
function VUHDO_registerAllSecureButtons()

	if not sInitialized or InCombatLockdown() then
		return false;
	end

	for tPanelNum = 1, VUHDO_MAX_PANELS do
		tPanelButtons = VUHDO_getPanelButtons(tPanelNum);

		if tPanelButtons then
			for tButtonIdx = 1, #tPanelButtons do
				tButton = tPanelButtons[tButtonIdx];

				if tButton then
					VUHDO_registerSecureRealButton(tPanelNum, tButtonIdx, tButton);
				end
			end
		end
	end

	return true;

end



--
local tButton;
local tChildIndex;
local tCnt;
local tPlayerShadowButtons;
local tPlayerShadowButtonsWithUnits;
local tPetShadowButtons;
local tPetShadowButtonsWithUnits;
local tDebugPanelNum;
local tDebugPanelButtons;
local tDebugButtonIdx;
local tDebugHealButton;
local tDebugButtonName;
local tDebugAuraByAnchor;
local tDebugButtonCount;
local tDebugAuraCount;
function VUHDO_debugSecureEnvironment()

	if not sInitialized then
		return;
	end

	if InCombatLockdown() then
		VUHDO_Msg("Cannot debug secure environment during combat.");

		return;
	end

	VUHDO_Msg("|cffFFD100--- Secure Shadow Header Debug ---|r");

	tPlayerShadowButtons = 0;
	tPlayerShadowButtonsWithUnits = 0;

	if sShadowHeader then
		for tCnt = 1, 40 do
			tButton = sShadowHeader:GetAttribute("child" .. tCnt);

			if tButton then
				tPlayerShadowButtons = tPlayerShadowButtons + 1;

				if tButton:GetAttribute("unit") then
					tPlayerShadowButtonsWithUnits = tPlayerShadowButtonsWithUnits + 1;
				end
			end
		end

		VUHDO_Msg(format("|cffFFA500** Player Header:|r |cffB0E0E6Child Frames:|r %d (|cffB0E0E6With Units:|r %d)",
			tPlayerShadowButtons, tPlayerShadowButtonsWithUnits));
	else
		VUHDO_Msg("|cffFFA500** Player Header:|r |cffff0000ERROR - frame ref is nil!|r");
	end

	tPetShadowButtons = 0;
	tPetShadowButtonsWithUnits = 0;

	if sShadowPetHeader then
		for tCnt = 41, 80 do
			tChildIndex = tCnt - 40;
			tButton = sShadowPetHeader:GetAttribute("child" .. tChildIndex);

			if tButton then
				tPetShadowButtons = tPetShadowButtons + 1;

				if tButton:GetAttribute("unit") then
					tPetShadowButtonsWithUnits = tPetShadowButtonsWithUnits + 1;
				end
			end
		end

		VUHDO_Msg(format("|cffFFA500** Pet Header:|r |cffB0E0E6Child Frames:|r %d (|cffB0E0E6With Units:|r %d)",
			tPetShadowButtons, tPetShadowButtonsWithUnits));
	else
		if VUHDO_INTERNAL_TOGGLES and VUHDO_INTERNAL_TOGGLES[VUHDO_UPDATE_PETS] then
			VUHDO_Msg("|cffFFA500** Pet Header:|r |cffff0000ERROR - frame ref is nil!|r");
		else
			VUHDO_Msg("|cffFFA500** Pet Header:|r |cffB0E0E6Not initialized (pets not configured)|r");
		end
	end

	tDebugButtonCount = 0;
	tDebugAuraCount = 0;

	for tDebugPanelNum = 1, VUHDO_MAX_PANELS do
		tDebugPanelButtons = VUHDO_getPanelButtons(tDebugPanelNum);

		if tDebugPanelButtons then
			for tDebugButtonIdx = 1, #tDebugPanelButtons do
				tDebugHealButton = tDebugPanelButtons[tDebugButtonIdx];

				if tDebugHealButton then
					tDebugButtonCount = tDebugButtonCount + 1;

					tDebugButtonName = tDebugHealButton:GetName();
					tDebugAuraByAnchor = tDebugButtonName and VUHDO_AURA_FRAMES[tDebugButtonName];

					if tDebugAuraByAnchor then
						for tAnchorIndex, tAnchorFrames in pairs(tDebugAuraByAnchor) do
							for tSlotIndex, tDebugAuraSlotFrame in pairs(tAnchorFrames) do
								if tDebugAuraSlotFrame then
									tDebugAuraCount = tDebugAuraCount + 1;
								end
							end
						end
					end
				end
			end
		end
	end

	VUHDO_Msg(format("|cffFFA500** Real Frames:|r |cffB0E0E6Buttons:|r %d, |cffB0E0E6Aura Frames:|r %d",
		tDebugButtonCount, tDebugAuraCount));

	sManagerFrame:Execute([=[
		local tPlayerShadowMappingCount = 0;
		local tPetShadowMappingCount = 0;

		for tShadowId, tMappings in pairs(sShadowToRealMap) do
			if tShadowId >= 1 and tShadowId <= 40 then
				tPlayerShadowMappingCount = tPlayerShadowMappingCount + 1;
			elseif tShadowId >= 41 and tShadowId <= 80 then
				if sShadowPetHeader then
					tPetShadowMappingCount = tPetShadowMappingCount + 1;
				end
			end
		end

		local tPlayerFallbackMappingCount = 0;
		local tPetFallbackMappingCount = 0;

		if sUnitMap then
			for tUnit, tMappings in pairs(sUnitMap) do
				if string.find(strlower(tUnit), "pet") then
					if sShadowPetHeader then
						tPetFallbackMappingCount = tPetFallbackMappingCount + 1;
					end
				else
					tPlayerFallbackMappingCount = tPlayerFallbackMappingCount + 1;
				end
			end
		end

		print(format("|cffffe566[VuhDo]|r |cffFFA500** Shadow Mappings:|r |cffB0E0E6Player:|r %d, |cffB0E0E6Pet:|r %d (|cffB0E0E6Total:|r %d) | |cffB0E0E6Fallback:|r |cffB0E0E6Player:|r %d, |cffB0E0E6Pet:|r %d (|cffB0E0E6Total:|r %d)",
			tPlayerShadowMappingCount, tPetShadowMappingCount, tPlayerShadowMappingCount + tPetShadowMappingCount,
			tPlayerFallbackMappingCount, tPetFallbackMappingCount, tPlayerFallbackMappingCount + tPetFallbackMappingCount));
	]=]);

	VUHDO_Msg("|cffFFD100--- End of Debug ---|r");

	return;

end



--
function VUHDO_setSecureDebugEnabled(anIsEnabled)

	if not sInitialized then
		return;
	end

	if InCombatLockdown() then
		VUHDO_Msg("Cannot modify secure debug flag during combat.");

		return;
	end

	sManagerFrame:Execute(format([=[
		sIsDebugEnabled = %s;
	]=], anIsEnabled and "true" or "false"));

	VUHDO_CONFIG["COMBAT_ROSTER"]["debug"] = anIsEnabled;

	if anIsEnabled then
		VUHDO_Msg("Secure shadow header debug is now |cff00ff00enabled|r.");
	else
		VUHDO_Msg("Secure shadow header debug is now |cffff0000disabled|r.");
	end

	return;

end



--
function VUHDO_setCombatRosterEnabled(anIsEnabled)

	if InCombatLockdown() then
		VUHDO_Msg("Cannot modify combat roster setting during combat.");

		return;
	end

	VUHDO_CONFIG["COMBAT_ROSTER"]["enabled"] = anIsEnabled;

	if anIsEnabled then
		VUHDO_Msg("Combat roster is now |cff00ff00enabled|r.");
	else
		VUHDO_Msg("Combat roster is now |cffff0000disabled|r.");
	end

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
local tCodeLines;
local tMapping;
local function VUHDO_pushAllSecureUnitMappings(aUnitMappings)

	tCodeLines = { };

	tinsert(tCodeLines, "local tEntry, tMappings;");

	for tUnit, tMappings in pairs(aUnitMappings) do
		tinsert(tCodeLines, format("tMappings = newtable();"));

		for tMappingIdx = 1, #tMappings do
			tMapping = tMappings[tMappingIdx];

			tinsert(tCodeLines, format(
				"tEntry = newtable(); tEntry[1] = %d; tEntry[2] = %d; tinsert(tMappings, tEntry);",
				tMapping[1], tMapping[2]
			));
		end

		tinsert(tCodeLines, format("sUnitMap[%q] = tMappings;", tUnit));
	end

	sManagerFrame:Execute(table.concat(tCodeLines, "\n"));

	return true;

end



--
local function VUHDO_clearSecureMappings()

	sManagerFrame:Execute([=[
		local tReleasedCount = 0;

		for tUnit, tPoolIdx in pairs(sUnitToPoolIndex) do
			if tPoolIdx and sFallbackMappingPool[tPoolIdx] then
				sFallbackMappingPool[tPoolIdx]["inUse"] = false;
				tReleasedCount = tReleasedCount + 1;
			end
		end

		if sIsDebugEnabled and tReleasedCount > 0 then
			print("[VuhDo] clearSecureMappings: Released", tReleasedCount, "pool entries");
		end

		local tClearedButtonCount = 0;

		local tPanelNum = sFallbackPanel;

		if tPanelNum then
				local tPanelButtons = sRealButtons[tPanelNum];
				local tStartIndex = sFallbackButtonStart[tPanelNum];

				if tPanelButtons and tStartIndex then
					local tPanelClearedCount = 0;

					for tButtonIdx = tStartIndex, tStartIndex + sMaxShadowButtons - 1 do
						local tButton = tPanelButtons[tButtonIdx];

						if tButton then
							local tUnit = tButton:GetAttribute("unit");

							if tUnit then
								tButton:SetAttribute("unit", nil);

								sManager:CallMethod("RefreshAuraFramesForButton", tPanelNum, tButtonIdx);

								tPanelClearedCount = tPanelClearedCount + 1;
							end
						end
					end

					tClearedButtonCount = tClearedButtonCount + tPanelClearedCount;

					if sIsDebugEnabled and tPanelClearedCount > 0 then
						print("[VuhDo] clearSecureMappings: Cleared", tPanelClearedCount, "fallback buttons from panel", tPanelNum);
					end
				end
			end

		if sIsDebugEnabled and tClearedButtonCount > 0 then
			print("[VuhDo] clearSecureMappings: Total cleared", tClearedButtonCount, "fallback buttons");
		end

		wipe(sUnitToPoolIndex);
		wipe(sUnitMap);

		if sFallbackPanel then
			sNextFallbackButton[sFallbackPanel] = sFallbackButtonStart[sFallbackPanel];
		end
	]=]);

	return true;

end



--
local tShadowButton;
local tShadowId;
local tUnit;
local function VUHDO_initShadowToRealMappings()

	sManagerFrame:Execute([=[
		wipe(sShadowToRealMap);

		for tShadowId = 1, 80 do
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

	if sShadowPetHeader then
		for tCnt = 1, 40 do
			tShadowButton = sShadowPetHeader:GetAttribute("child" .. tCnt);

			if tShadowButton then
				tShadowId = tShadowButton:GetID();
				tUnit = tShadowButton:GetAttribute("unit");

				if tUnit then
					sManagerFrame:SetFrameRef("sShadowPetButton", tShadowButton);

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
						local tMappings = sShadowToRealMap[tShadowId];
						local tAlreadyAssigned = true;

						if tMappings then
							local tMappingsCount = #tMappings;

							for tMappingIdx = 1, tMappingsCount do
								local tMapping = tMappings[tMappingIdx];
								local tPanelNum = tMapping[1];
								local tButtonNum = tMapping[2];

								local tPanelButtons = tPanelNum and sRealButtons[tPanelNum];
								local tRealButton = tPanelButtons and tButtonNum and tPanelButtons[tButtonNum];

								if tRealButton then
									local tCurrentUnit = tRealButton:GetAttribute("unit");

									if tCurrentUnit ~= tUnit then
										tAlreadyAssigned = false;

										break;
									end
								else
									tAlreadyAssigned = false;

									break;
								end
							end
						else
							tAlreadyAssigned = false;
						end

						if not tAlreadyAssigned then
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

							if sIsDebugEnabled then
								print("[VuhDo] initShadowToReal queued: shadow:", tShadowId, "unit:", tUnit);
							end

							sPendingRefresh = true;
						elseif sIsDebugEnabled then
							--print("[VuhDo] initShadowToReal skipped: shadow:", tShadowId, "unit:", tUnit, "already assigned");
						end
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
local tUnitMappings = { };
local tModels;
local tSetup;
local tSortBy;
local tButtonIndex;
local tColIndex;
local tGroupArray;
local tUnitCount;
function VUHDO_computeAndPushSecureMappings()

	if not sInitialized or InCombatLockdown() then
		return false;
	end

	VUHDO_clearSecureMappings();

	sManagerFrame:Execute([=[
		if sFallbackPanel and sFallbackPanel > 0 then
			if sFallbackPlayerUnits[sFallbackPanel] then
				wipe(sFallbackPlayerUnits[sFallbackPanel]);
			end

			if sFallbackPetUnits and sFallbackPetUnits[sFallbackPanel] then
				wipe(sFallbackPetUnits[sFallbackPanel]);
			end

			if sIsDebugEnabled then
				print("[VuhDo] Cleared fallback tracking lists");
			end
		end
	]=]);

	wipe(tUnitMappings);

	VUHDO_updateSecureFallbackConfig();

	for tPanelNum = 1, VUHDO_MAX_PANELS do
		if VUHDO_isPanelVisible(tPanelNum) then
			tModels = VUHDO_getDynamicModelArray(tPanelNum);
			tSetup = VUHDO_PANEL_SETUP[tPanelNum];
			tSortBy = tSetup["MODEL"]["sort"];

			tButtonIndex = 1;
			tColIndex = 1;

			for tModelIndex, tModelId in ipairs(tModels) do
				tGroupArray = VUHDO_getGroupMembersSorted(tModelId, tSortBy, tPanelNum, tModelIndex);

				if #tGroupArray > 0 then
					for _, tUnit in ipairs(tGroupArray) do
						if tUnit and not tUnitMappings[tUnit] then
							tUnitMappings[tUnit] = { };
						end

						if tUnit then
							tinsert(tUnitMappings[tUnit], { tPanelNum, tButtonIndex });
						end

						tButtonIndex = tButtonIndex + 1;
					end
				end

				tColIndex = tColIndex + 1;
			end
		end
	end

	tUnitCount = 0;

	for tUnit, tMappings in pairs(tUnitMappings) do
		tUnitCount = tUnitCount + 1;
	end

	if tUnitCount == 0 then
		return true;
	end

	VUHDO_pushAllSecureUnitMappings(tUnitMappings);

	if VUHDO_CONFIG["COMBAT_ROSTER"]["debug"] then
		VUHDO_debugSecureEnvironment();
	end

	VUHDO_initShadowToRealMappings();

	return true;

end



--



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



--
function VUHDO_clearSecurePetMappings()

	if not sInitialized or InCombatLockdown() then
		return false;
	end

	if not sShadowPetHeader then
		return true;
	end

	sManagerFrame:Execute([=[
		for tShadowId = 41, 80 do
			sShadowButtonHasMapping[tShadowId] = false;
			sShadowToRealMap[tShadowId] = nil;
		end

		if sIsDebugEnabled then
			print("[VuhDo] Cleared pet mappings");
		end
	]=]);

	return true;

end