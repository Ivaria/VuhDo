local _;

local tinsert = table.insert;
local format = string.format;

local sManagerFrame;
local sShadowHeader;
local sInitialized = false;



--
function VUHDO_isSecureShadowHeaderReady()

	return sInitialized;

end



--
local function VUHDO_setSecureFallbackPanel(aPanelNum)

	if not sManagerFrame then
		return false;
	end

	sManagerFrame:Execute(format([=[
		sFallbackPanel = %d;
	]=], aPanelNum));

	return true;

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
local tChild;
local tFallbackPanel;
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

	function sManagerFrame:UpdatePanelVisibility()

		VUHDO_updatePanelVisibility();

		return;

	end

	function sShadowHeader:Execute(aBody)

		return SecureHandlerExecute(self, aBody);

	end

	function sShadowHeader:SetFrameRef(aLabel, aRefFrame)

		return SecureHandlerSetFrameRef(self, aLabel, aRefFrame);

	end

	sManagerFrame:SetFrameRef("sShadowHeader", sShadowHeader);

	sManagerFrame:Execute([=[
		sManager = self;
		sShadowHeader = self:GetFrameRef("sShadowHeader");

		sRealButtons = newtable();
		sDebuffFrames = newtable();
		sButtonToUnit = newtable();

		for tPanelNum = 1, 10 do
			sRealButtons[tPanelNum] = newtable();
			sDebuffFrames[tPanelNum] = newtable();
			sButtonToUnit[tPanelNum] = newtable();
		end

		sUnitMap = newtable();
		sShadowToRealMap = newtable();
		sShadowButtonHasMapping = newtable();

		for tShadowId = 1, 40 do
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
	]=]);

	tFallbackPanel = VUHDO_CONFIG["COMBAT_ROSTER"]["fallbackPanel"] or 1;
	VUHDO_setSecureFallbackPanel(tFallbackPanel);

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

		if not tShadowButtonId then
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

		if not tShadowButtonId then
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

			local tPanelDebuffFrames = tPanelNum and sDebuffFrames[tPanelNum];
			local tDebuffFrames = tPanelDebuffFrames and tButtonNum and tPanelDebuffFrames[tButtonNum];

			if tDebuffFrames then
				for tIconNum, tDebuffFrame in pairs(tDebuffFrames) do
					tDebuffFrame:SetAttribute("unit", nil);
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

			local tPanelDebuffFrames = tPanelNum and sDebuffFrames[tPanelNum];
			local tDebuffFrames = tPanelDebuffFrames and tButtonNum and tPanelDebuffFrames[tButtonNum];

			if tDebuffFrames then
				for tIconNum, tDebuffFrame in pairs(tDebuffFrames) do
					tDebuffFrame:SetAttribute("unit", tUnit);
				end
			end

			if anIsShow then
				tRealButton:Show();
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

	sManagerFrame:SetAttribute("vuhdo_update_stale_mapping_method", [=[
		local tShadowButtonId, tShadowButtonCurrentUnit = ...;

		if not tShadowButtonId then
			return;
		end

		if tShadowButtonCurrentUnit then
			local tNewUnitMappings = sUnitMap[tShadowButtonCurrentUnit];

			if tNewUnitMappings then
				sShadowToRealMap[tShadowButtonId] = tNewUnitMappings;

				if sIsDebugEnabled then
					print("[VuhDo] Updated stale mapping - sShadowToRealMap[", tShadowButtonId, "] now points to fallback mappings for unit:", tShadowButtonCurrentUnit);
				end
			else
				sShadowButtonHasMapping[tShadowButtonId] = false;
				sShadowToRealMap[tShadowButtonId] = nil;

				if sIsDebugEnabled then
					print("[VuhDo] Fixed stale mapping state - cleared sShadowButtonHasMapping[", tShadowButtonId, "] and sShadowToRealMap[", tShadowButtonId, "] (unit has no mappings)");
				end
			end
		else
			sShadowButtonHasMapping[tShadowButtonId] = false;
			sShadowToRealMap[tShadowButtonId] = nil;

			if sIsDebugEnabled then
				print("[VuhDo] Fixed stale mapping state - cleared sShadowButtonHasMapping[", tShadowButtonId, "] and sShadowToRealMap[", tShadowButtonId, "] (shadow button has no unit)");
			end
		end
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

							local tPanelDebuffFrames = tPanelNum and sDebuffFrames[tPanelNum];
							local tDebuffFrames = tPanelDebuffFrames and tButtonIndex and tPanelDebuffFrames[tButtonIndex];

							if tDebuffFrames then
								for tIconNum, tDebuffFrame in pairs(tDebuffFrames) do
									tDebuffFrame:SetAttribute("unit", nil);
								end
							end

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
			local tShadowButton = sShadowHeader and sShadowHeader:GetAttribute("child" .. tShadowButtonId);
			local tShadowButtonCurrentUnit = tShadowButton and tShadowButton:GetAttribute("unit");

			if sIsDebugEnabled then
				print("[VuhDo] Clear queue entry: shadow:", tShadowButtonId, "oldUnit:", tostring(tOldUnit), "currentUnit:", tostring(tShadowButtonCurrentUnit));
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

					if tHasPreMapping then
						local tShadowButton = sShadowHeader and sShadowHeader:GetAttribute("child" .. tShadowButtonId);
						local tShadowButtonCurrentUnit = tShadowButton and tShadowButton:GetAttribute("unit");

						sManager:RunAttribute("vuhdo_update_stale_mapping_method", tShadowButtonId, tShadowButtonCurrentUnit);
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
					if not tOldUnit then
						print("[VuhDo] WARNING: Skipping clear queue entry - shadow:", tShadowButtonId, "oldUnit is nil or falsy");
					else
						print("[VuhDo] WARNING: Skipping clear queue entry - shadow:", tShadowButtonId, "oldUnit:", tostring(tOldUnit), "currentUnit:", tostring(tShadowButtonCurrentUnit), "unknown reason");
					end
				end
			end
		end
	]=]);

	sManagerFrame:SetAttribute("vuhdo_process_premapped_units_method", [=[
		for tShadowButtonId, tQueueData in pairs(sProcessQueue) do
			local tHasPreMapping = sShadowButtonHasMapping[tShadowButtonId];

			if tHasPreMapping then
				local tUnit = tQueueData[1];
				local tOldUnit = tQueueData[2];

				if sIsDebugEnabled then
					print("[VuhDo] Phase 2 processing: shadow:", tShadowButtonId, "unit:", tUnit, "oldUnit:", tostring(tOldUnit));
				end

				local tShadowButton = sShadowHeader and sShadowHeader:GetAttribute("child" .. tShadowButtonId);
				local tShadowButtonCurrentUnit = tShadowButton and tShadowButton:GetAttribute("unit");

				if sIsDebugEnabled and tUnit == "player" then
					print("[VuhDo] Phase 2: Queue entry says unit: player, shadow button current unit:", tostring(tShadowButtonCurrentUnit));
				end

				if not tShadowButtonCurrentUnit then
					if tUnit == "player" then
						if sIsDebugEnabled then
							print("[VuhDo] Phase 2: Shadow button unit is nil but queue entry is 'player' - assigning to pre-mapped button (player left raid)");
						end

						tShadowButtonCurrentUnit = tUnit;
					else
						if sIsDebugEnabled then
							print("[VuhDo] Phase 2: Shadow button unit is nil - unit likely left group, skipping assignment for:", tUnit);
						end

						sShadowButtonHasMapping[tShadowButtonId] = false;
						sShadowToRealMap[tShadowButtonId] = nil;
					end
				end

				if tShadowButtonCurrentUnit and tShadowButtonCurrentUnit ~= tUnit then
					if sIsDebugEnabled then
						print("[VuhDo] Phase 2 WARNING: Stale mapping detected - shadow:", tShadowButtonId, "expected unit:", tUnit, "actual unit:", tShadowButtonCurrentUnit, "- updating or fixing stale state");
					end

					sManager:RunAttribute("vuhdo_update_stale_mapping_method", tShadowButtonId, tShadowButtonCurrentUnit);

					local tNewUnitMappings = sUnitMap[tShadowButtonCurrentUnit];

					if not tNewUnitMappings then
						-- FIXME: why is this empty?
					else
						-- FIXME: why is this empty?
					end
				elseif tShadowButtonCurrentUnit then
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
					end

					if tFallbackMappings then
						sManager:RunAttribute("vuhdo_release_pool_entry_method", tUnit);
					end

					local tMappings = sShadowToRealMap[tShadowButtonId];

					if tMappings then
						local tMappingsCount = #tMappings;

						for tMappingIdx = 1, tMappingsCount do
							local tMapping = tMappings[tMappingIdx];
							local tPanelNum = tMapping[1];
							local tButtonNum = tMapping[2];

							local tPanelButtons = tPanelNum and sRealButtons[tPanelNum];
							local tRealButton = tPanelButtons and tButtonNum and tPanelButtons[tButtonNum];

							if tRealButton then
								local tCurrentButtonUnit = tRealButton:GetAttribute("unit");

								if tCurrentButtonUnit == tUnit then
									if sIsDebugEnabled then
										print("[VuhDo] Phase 2: Button already has correct unit, skipping assignment - panel:", tPanelNum, "button:", tButtonNum, "unit:", tUnit);
									end
								else
									if sIsDebugEnabled then
										print("[VuhDo] Phase 2: Setting unit:", tUnit, "on panel:", tPanelNum, "button:", tButtonNum, "previous unit:", tostring(tCurrentButtonUnit));
									end

									sManager:RunAttribute("vuhdo_assign_unit_to_button_method", tPanelNum, tButtonNum, tUnit, true);
								end
							end
						end
					elseif sIsDebugEnabled then
						print("[VuhDo] Phase 2: No mappings found for shadow:", tShadowButtonId);
					end
				end
			end
		end
	]=]);

	sManagerFrame:SetAttribute("vuhdo_process_fallback_units_method", [=[
		for tShadowButtonId, tQueueData in pairs(sProcessQueue) do
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

							if sIsDebugEnabled then
								print("[VuhDo] Searching fallback panel", tFallbackPanel, "for empty button");
							end

							if tFallbackPanel then
								local tFallbackButtonIndex = nil;
								local tFallbackButton = nil;

								local tFallbackPanelButtons = sRealButtons[tFallbackPanel];

								if tFallbackPanelButtons then
									local tStartIndex = sFallbackButtonStart[tFallbackPanel];
									local tCheckIndex = tStartIndex;

									while (tCheckIndex - tStartIndex) < sMaxShadowButtons do
										local tCheckButton = tFallbackPanelButtons[tCheckIndex];

										if tCheckButton then
											local tCheckUnit = tCheckButton:GetAttribute("unit");

											if not tCheckUnit then
												tFallbackButtonIndex = tCheckIndex;
												tFallbackButton = tCheckButton;

												break;
											end
										end

										tCheckIndex = tCheckIndex + 1;
									end
								end

								if not tFallbackButton then
									tFallbackButtonIndex = sNextFallbackButton[tFallbackPanel];

									if not tFallbackPanelButtons then
										tFallbackPanelButtons = sRealButtons[tFallbackPanel];
									end

									tFallbackButton = tFallbackButtonIndex and tFallbackPanelButtons and tFallbackPanelButtons[tFallbackButtonIndex];

									if sIsDebugEnabled then
										if tFallbackButton then
											print("[VuhDo] Using next fallback button panel:", tFallbackPanel, "button:", tFallbackButtonIndex);
										else
											print("[VuhDo] No fallback button available at panel:", tFallbackPanel, "button:", tFallbackButtonIndex);
										end
									end
								end

								if tFallbackButton then
									local tCurrentUnit = tFallbackButton:GetAttribute("unit");

									if sIsDebugEnabled then
										print("[VuhDo] Found fallback button panel:", tFallbackPanel, "button:", tFallbackButtonIndex, "currentUnit:", tostring(tCurrentUnit));
									end

									if not tCurrentUnit then
										if sIsDebugEnabled then
											print("[VuhDo] Assigning unit:", tUnit, "to fallback button panel:", tFallbackPanel, "button:", tFallbackButtonIndex);
										end

										sManager:RunAttribute("vuhdo_assign_unit_to_button_method", tFallbackPanel, tFallbackButtonIndex, tUnit, true);

										RegisterUnitWatch(tFallbackButton);

										if sIsDebugEnabled then
											local tButtonName = tFallbackButton:GetName();
											local tAfterUnit = tFallbackButton:GetAttribute("unit");
											local tIsShown = tFallbackButton:IsShown();

											print("[VuhDo] After assignment - button:", tButtonName or "nil", "unit:", tostring(tAfterUnit), "isShown:", tIsShown);
										end

										if not sRealButtons[tFallbackPanel][tFallbackButtonIndex] then
											sRealButtons[tFallbackPanel][tFallbackButtonIndex] = tFallbackButton;
										end

										if tFallbackButtonIndex >= sNextFallbackButton[tFallbackPanel] then
											sNextFallbackButton[tFallbackPanel] = tFallbackButtonIndex + 1;
										end

										tAssignedPanel = tFallbackPanel;
										tAssignedButtonIndex = tFallbackButtonIndex;
									end
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
									sUnitMap[tUnit] = tTempMappings;

									if sIsDebugEnabled then
										print("[VuhDo] Pool exhausted, created new mapping for unit:", tUnit, "panel:", tAssignedPanel, "button:", tAssignedButtonIndex);
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
	]=]);

	sManagerFrame:SetAttribute("_onstate-vuhdo_batch_timer", [=[
		if newstate ~= "process" and sPendingRefresh then
			if sIsDebugEnabled then
				local tClearCount = 0;
				local tProcessCount = 0;

				for _ in pairs(sClearQueue) do
					tClearCount = tClearCount + 1;
				end

				for _ in pairs(sProcessQueue) do
					tProcessCount = tProcessCount + 1;
				end

				print("[VuhDo] Batch processing triggered, clear queue:", tClearCount, "process queue:", tProcessCount);
			end

			if not next(sClearQueue) and not next(sProcessQueue) then
				if sIsDebugEnabled then
					print("[VuhDo] Queues empty, skipping batch processing");
				end

				sPendingRefresh = false;

				return;
			end

			sManager:RunAttribute("vuhdo_process_clear_queue_method");

			sManager:RunAttribute("vuhdo_process_premapped_units_method");

			sManager:RunAttribute("vuhdo_process_fallback_units_method");

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

			wipe(sClearQueue);

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

		print(format("[VuhDo] Secure environment: %d real frames, %d debuff frames, %d shadow-to-real mappings, %d fallback unit mappings",
			tFrameCount, tDebuffFrameCount, tShadowMappingCount, tFallbackMappingCount));
	]=]);

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

								local tPanelDebuffFrames = sDebuffFrames[tPanelNum];
								local tDebuffFrames = tPanelDebuffFrames and tPanelDebuffFrames[tButtonIdx];

								if tDebuffFrames then
									for tIconNum, tDebuffFrame in pairs(tDebuffFrames) do
										tDebuffFrame:SetAttribute("unit", nil);
									end
								end

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
							print("[VuhDo] initShadowToReal skipped: shadow:", tShadowId, "unit:", tUnit, "already assigned");
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
local tFallbackPanel;
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

	wipe(tUnitMappings);

	tFallbackPanel = VUHDO_CONFIG["COMBAT_ROSTER"]["fallbackPanel"] or 1;
	VUHDO_setSecureFallbackPanel(tFallbackPanel);

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