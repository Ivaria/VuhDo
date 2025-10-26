local _;

local sManagerFrame;
local sShadowHeader;
local sInitialized = false;



--
function VUHDO_isSecureSystemReady()

	return sInitialized;

end



--
local tInitConfigFunc = [=[
	tinsert(sShadowFrames, self);

	self:SetID(#sShadowFrames);
	self:SetAttribute("Manager", sManager);

	sManager:CallMethod("UpdateShadowButtonCount", #sShadowFrames);
]=];
local tOnAttributeChanged = [=[
	if name == "unit" then
		local tUnit = value;

		if type(tUnit) == "string" then
			tUnit = strlower(tUnit);
		else
			tUnit = nil;
		end;

		local tManager = self:GetAttribute("Manager");

		if tManager then
			tManager:RunAttribute("_processunit", tUnit);
		end
	end
]=];
local tChild;
function VUHDO_initSecureShadowHeader()

	if InCombatLockdown() or not VUHDO_CONFIG or not VUHDO_CONFIG["COMBAT_ROSTER"] or not VUHDO_CONFIG["COMBAT_ROSTER"]["enabled"] then
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

	function sManagerFrame:ShowDebugCounts(aFrameCount, aMappingCount)

		VUHDO_Msg(format("Secure environment: %d real frames registered, %d unit mappings", aFrameCount, aMappingCount));

		return;

	end

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

		sFallbackPanels = newtable();
		tinsert(sFallbackPanels, 1);

		sNextFallbackButton = newtable();
		sFallbackButtonStart = newtable();

		for tPanelNum = 1, 10 do
			sNextFallbackButton[tPanelNum] = 1;
			sFallbackButtonStart[tPanelNum] = 1;
		end
	]=]);

	sManagerFrame:SetAttribute("_processunit", [=[
		local tUnit = ...;

		if not tUnit then
			return;
		end

		local tMappings = sUnitMap[tUnit];

		if tMappings then
			for tMappingIdx = 1, #tMappings do
				local tMapping = tMappings[tMappingIdx];
				local tPanelNum = tMapping[1];
				local tButtonNum = tMapping[2];
				local tRealFrame = sRealFrames[tPanelNum] and sRealFrames[tPanelNum][tButtonNum];

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

				local tTempMapping = newtable();
				tTempMapping[1] = tFirstPanel;
				tTempMapping[2] = tFirstButton;

				local tTempMappings = newtable();
				tinsert(tTempMappings, tTempMapping);

				sUnitMap[tUnit] = tTempMappings;
			end
		end
	]=]);

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

	for tIdx = 1, 40 do
		tChild = sShadowHeader:GetAttribute("child" .. tIdx);

		if tChild then
			tChild:SetAttribute("_onattributechanged", tOnAttributeChanged);
		end
	end

	sInitialized = true;

	VUHDO_refreshUI();

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

		local tMappingCount = 0;

		for tUnit, tMappings in pairs(sUnitMap) do
			tMappingCount = tMappingCount + 1;
		end

		sManager:CallMethod("ShowDebugCounts", tFrameCount, tMappingCount);
	]=]);

	return;

end



--
local tMapping;
function VUHDO_pushSecureUnitMapping(aUnit, aMappings)

	if not sInitialized or InCombatLockdown() then
		return false;
	end

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
function VUHDO_clearSecureMappings()

	if not sInitialized or InCombatLockdown() then
		return false;
	end

	sManagerFrame:Execute([=[
		sUnitMap = newtable();

		for tPanelNum = 1, 10 do
			sNextFallbackButton[tPanelNum] = 1;
		end
	]=]);

	return true;

end



--
local tPanelNum;
function VUHDO_setSecureFallbackPanels(aPanelList)

	if not sInitialized or InCombatLockdown() then
		return false;
	end

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