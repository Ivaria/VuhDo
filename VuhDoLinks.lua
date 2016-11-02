--[[ VuhDoLinks.lua

This code handles all the VuhDo specific Hyperlinks.  VuhDo provides a custom 
hyperlink that allows for sharing of profiles, key layouts and custom bouquets.

]]--

local function VUHDO_chatLinkFilterFunc(_, event, messageStr, senderPlayer, language, channelStr, targetPlayer, flags, channelId, ...)

	if flag == "GM" or flag == "DEV" or (event == "CHAT_MSG_CHANNEL" and channelId > 0) then
		return;
	end

	local newStr = "";
	local done = false;
	local remainingStr = messageStr;

	repeat
		local start, finish, playerName, linkName = remainingStr:find("%[VuhDo: ([^%s]+) %- ([^%]]+)%]");

		if playerName and linkName then
			playerName = playerName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
			linkName = linkName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");

			newStr = newStr .. remainingStr:sub(1, start - 1) .. 
			"|Hvuhdo|h|cffffe566[VuhDo: " .. playerName .. 
			" |r|cffffe566- " .. linkName .. "]|h|r";

			remainingStr = remainingStr:sub(finish + 1);
		else
			done = true;
		end
	until(done)

	if newStr ~= "" then
		if event == "CHAT_MSG_WHISPER" and not UnitInParty(senderPlayer) and not UnitInRaid(senderPlayer) then 
			return true;
		else
			return false, newStr, senderPlayer, language, channelStr, targetPlayer, flags, channelId, ...;
		end
	end

end

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_CONVERSATION", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", VUHDO_chatLinkFilterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", VUHDO_chatLinkFilterFunc)

local function VUHDO_createLinkTooltipButton()

	if not ItemRefTooltip.VuhDo_Tooltip_Button then
		ItemRefTooltip.VuhDo_Tooltip_Button = CreateFrame("Button", "VuhDoTooltipImportButton", ItemRefTooltip, "UIPanelButtonTemplate")
        end
        
	local linkImportButton = ItemRefTooltip.VuhDo_Tooltip_Button;

	linkImportButton:SetPoint("BOTTOMRIGHT", ItemRefTooltip, "BOTTOMRIGHT", -10, 5);
	linkImportButton:SetWidth(100);
	
	linkImportButton:SetText("Import");

	linkImportButton:RegisterEvent("PLAYER_REGEN_ENABLED");
	linkImportButton:RegisterEvent("PLAYER_REGEN_DISABLED");
	
	--[[
	local function onCombat(self, event)
		if (event == "PLAYER_REGEN_ENABLED") then
			linkImportButton:Enable();
		else
			linkImportButton:Disable();
		end
        end

	linkImportButton:SetScript("OnEvent", onCombat);

	if (InCombatLockdown()) then
		linkImportButton:Disable();
        end
        
	if not VuhDoSaved.import_disabled or VuhDo.IsImporting() then
        
		linkImportButton:SetText("Import");
		linkImportButton:SetScript("OnClick", function()

                local func = function()
	                VuhDo.SetImporting(true);
		        VuhDo.OpenOptions();

			local optionsFrame = VuhDo.OptionsFrame();
                
			if not(optionsFrame) then
				VuhDo.ToggleOptions();
				optionsFrame = VuhDo.OptionsFrame();
			end

			if not(VuhDo.IsOptionsOpen()) then
				VuhDo.ToggleOptions();
			end

                local function importData(data)

			local id = data.id
			local num = 2;

			while VuhDoSaved.displays[id] do
				id = data.id.." "..num;
				num = num + 1;
			end

			data.id = id;
			data.parent = nil;

			VuhDo.Add(data);
			VuhDo.NewDisplayButton(data);

		end

                importData(data);

		VuhDo.Add(data);
                VuhDo.NewDisplayButton(data);

		coroutine.yield();

                if(children) then
                    for index, childData in pairs(children) do
                        importData(childData);
                        tinsert(data.controlledChildren, childData.id);
                        childData.parent = data.id;
                        VuhDo.Add(data);
                        VuhDo.Add(childData);
                        coroutine.yield();
                    end
                end

                if (children) then
                  for index, childData in pairs(children) do
                        VuhDo.NewDisplayButton(childData);
                        local childButton = VuhDo.GetDisplayButton(childData.id);
                        childButton:SetGroup(data.id, data.regionType == "dynamicgroup");
                        childButton:SetGroupOrder(index, #data.controlledChildren);
                        coroutine.yield();
                    end

                    local button = VuhDo.GetDisplayButton(data.id);
                    button.callbacks.UpdateExpandButton();
                    VuhDo.UpdateDisplayButton(data);
                    VuhDo.ReloadGroupRegionOptions(data);
                    VuhDo.SortDisplayButtons();
                end

                VuhDo.Add(data);
                ItemRefTooltip:Hide();
                VuhDo.PickDisplay(data.id);
                VuhDo.CloseImportExport();
                VuhDo.SetImporting(false);
                end

                local co = coroutine.create(func);
                VuhDo.dynFrame:AddAction("import", co);
            end);
            else
                -- TODO enable button after importing finished
                linkImportButton:SetText("Import disabled");
                linkImportButton:SetScript("OnClick", function()
                    VuhDo.CloseImportExport();
                end);
            end
        end
	]]--

	local import = true;

        if import then
            linkImportButton:Show();
        end

end

function VUHDO_showLinkTooltip(content)

	VUHDO_createLinkTooltipButton();

	ShowUIPanel(ItemRefTooltip);

	if not ItemRefTooltip:IsVisible() then
		ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
	end

	ItemRefTooltip:ClearLines();

	for i,v in pairs(content) do
		local sides, a1, a2, a3, a4, a5, a6, a7, a8 = unpack(v);

		if sides == 1 then
			ItemRefTooltip:AddLine(a1, a2, a3, a4, a5);
		elseif sides == 2 then
			ItemRefTooltip:AddDoubleLine(a1, a2, a3, a4, a5, a6, a7, a8);
		end
	end

	ItemRefTooltip:Show();

end

hooksecurefunc("ChatFrame_OnHyperlinkShow", function(self, link, text, button)

	if link == "vuhdo" then
		local _, _, playerName, linkType, linkName = text:find("|Hvuhdo|h|cffffe566%[VuhDo: ([^%s]+) |r|cffffe566%- ([^%-]+) %- (.+)%]|h");

		if playerName and linkType and linkName then
			playerName = playerName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
			linkName = linkName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
			linkType = linkType:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");

			if IsShiftKeyDown() then
				local editbox = GetCurrentKeyBoardFocus();

				if editbox then
					editbox:Insert("[VuhDo: " .. playerName .. " - " .. linkType .. " - " .. linkName .. "]");
				end
			else
				VUHDO_showLinkTooltip({
					{2, "VuhDo", linkType .. ": " .. linkName, 0.5, 0, 1, 1, 1, 1},
					{1, "Click to import this " .. string.lower(linkType) .. " from " .. playerName .. ".", 1, 0.82, 0},
					{1, " ", 1, 0.82, 0},
					{1, " ", 1, 0.82, 0}
				});

				-- TODO: VUHDO_requestLinkInfo(playerName, linkType, linkName);
			end
		else
			VUHDO_showLinkTooltip({
				{1, "VuhDo", 0.5, 0, 1},
				{1, "Malformed VuhDo link.", 1, 0, 0}
			});
		end
	end

end);

local OriginalSetHyperlink = ItemRefTooltip.SetHyperlink

function ItemRefTooltip:SetHyperlink(link, ...)

	if link and link:sub(0, 9) == "vuhdo" then
		return;
	end

	return OriginalSetHyperlink(self, link, ...);

end

local OriginalHandleModifiedItemClick = HandleModifiedItemClick

function HandleModifiedItemClick(link, ...)

	if link and link:find("|Hvuhdo|h") then
		return;
	end

	return OriginalHandleModifiedItemClick(link, ...);

end

local function VUHDO_requestLinkInfo(playerName, linkType, linkName)



end

