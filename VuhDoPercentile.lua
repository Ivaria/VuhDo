local _;

local floor = math.floor;
local max = math.max;
local min = math.min;
local twipe = table.wipe;



--
local tPercentileTracker;
function VUHDO_createPercentileTracker(aPercentiles)

	tPercentileTracker = {
		["percentiles"] = aPercentiles or { 0.5, 0.8, 0.9, 0.99, 1.0, },
		["markers"] = { },
		["counts"] = { },
		["positions"] = { },
		["desiredPositions"] = { },
		["heights"] = { },
		["totalCount"] = 0,
		["initialized"] = false,
	};

	for tIndex = 1, #tPercentileTracker["percentiles"] do
		tPercentileTracker["markers"][tIndex] = 0;
		tPercentileTracker["counts"][tIndex] = 0;
		tPercentileTracker["positions"][tIndex] = tIndex;
		tPercentileTracker["desiredPositions"][tIndex] = 1 + (tPercentileTracker["totalCount"] - 1) * tPercentileTracker["percentiles"][tIndex];
		tPercentileTracker["heights"][tIndex] = 0;
	end


	local tPercentileCount;
	local tHeight;
	local tHeightPrev;
	local tHeightNext;
	local tCountDiff;
	local tPosDiff;
	local tPosDiffNext;
	function tPercentileTracker:parabolicP2(anIndex, aSign)

		tPercentileCount = #self["percentiles"];

		tHeight = self["heights"][anIndex];
		tHeightPrev = anIndex > 1 and self["heights"][anIndex - 1] or tHeight;
		tHeightNext = anIndex < tPercentileCount and self["heights"][anIndex + 1] or tHeight;
		tCountDiff = (anIndex < tPercentileCount and self["counts"][anIndex + 1] or 0) - (anIndex > 1 and self["counts"][anIndex - 1] or 0);
		tPosDiff = self["positions"][anIndex] - (anIndex > 1 and self["positions"][anIndex - 1] or self["positions"][anIndex]);
		tPosDiffNext = (anIndex < tPercentileCount and self["positions"][anIndex + 1] or self["positions"][anIndex]) - self["positions"][anIndex];

		if tCountDiff == 0 or tPosDiff == 0 or tPosDiffNext == 0 then
			return tHeight;
		end

		return tHeight + (aSign / tCountDiff) * ((tPosDiff * (tHeightNext - tHeight) / tPosDiffNext) + (tPosDiffNext * (tHeight - tHeightPrev) / tPosDiff));

	end


	local tPercentileCount;
	local tHeight;
	local tHeightNext;
	local tCountDiff;
	local tPosDiff;
	function tPercentileTracker:linearP2(anIndex, aSign)

		tPercentileCount = #self["percentiles"];

		tHeight = self["heights"][anIndex];
		tHeightNext = (anIndex + aSign >= 1 and anIndex + aSign <= tPercentileCount) and self["heights"][anIndex + aSign] or tHeight;
		tCountDiff = (anIndex + aSign >= 1 and anIndex + aSign <= tPercentileCount) and self["counts"][anIndex + aSign] or self["counts"][anIndex];
		tPosDiff = (anIndex + aSign >= 1 and anIndex + aSign <= tPercentileCount) and self["positions"][anIndex + aSign] or self["positions"][anIndex];

		if tPosDiff == 0 then
			return tHeight;
		end

		return tHeight + aSign * (tHeightNext - tHeight) / tPosDiff;

	end


	local tPercentileCount;
	local tMarkerIndex;
	local tSign;
	local tNewHeight;
	local tDiff;
	local tHeight;
	local tHeightPrev;
	local tHeightNext;
	local tLinearHeight;
	function tPercentileTracker:update(aValue)

		tPercentileCount = #self["percentiles"];

		if not self["initialized"] then
			if self["totalCount"] < tPercentileCount then
				self["markers"][self["totalCount"] + 1] = aValue;
				self["totalCount"] = self["totalCount"] + 1;

				if self["totalCount"] == tPercentileCount then
					table.sort(self["markers"]);

					for tIndex = 1, tPercentileCount do
						self["heights"][tIndex] = self["markers"][tIndex];
					end

					self["initialized"] = true;
				end
			end

			return;
		end

		self["totalCount"] = self["totalCount"] + 1;

		tMarkerIndex = 0;

		for tIndex = 1, tPercentileCount - 1 do
			if aValue < self["heights"][tIndex] then
				tMarkerIndex = tIndex;
				break;
			end
		end

		if tMarkerIndex == 0 then
			tMarkerIndex = tPercentileCount;
		end

		for tIndex = tMarkerIndex, tPercentileCount do
			self["counts"][tIndex] = self["counts"][tIndex] + 1;
		end

		for tIndex = 1, tPercentileCount do
			self["desiredPositions"][tIndex] = self["desiredPositions"][tIndex] + self["percentiles"][tIndex];
		end

		for tIndex = 1, tPercentileCount - 1 do
			tDiff = self["desiredPositions"][tIndex] - self["positions"][tIndex];

			if (tDiff >= 1 and self["counts"][tIndex + 1] - self["counts"][tIndex] > 1) or
			   (tDiff <= -1 and self["counts"][tIndex - 1] - self["counts"][tIndex] < -1) then
				tSign = tDiff > 0 and 1 or -1;
				tNewHeight = self:parabolicP2(tIndex, tSign);

				tHeightPrev = tIndex > 1 and self["heights"][tIndex - 1] or 0;
				tHeightNext = tIndex < tPercentileCount and self["heights"][tIndex + 1] or math.huge;
				
				if tNewHeight and tNewHeight == tNewHeight and tNewHeight ~= math.huge and tNewHeight ~= -math.huge and tHeightPrev < tNewHeight and tNewHeight < tHeightNext then
					self["heights"][tIndex] = tNewHeight;
				else
					tLinearHeight = self:linearP2(tIndex, tSign);

					if tLinearHeight and tLinearHeight == tLinearHeight and tLinearHeight ~= math.huge and tLinearHeight ~= -math.huge then
						self["heights"][tIndex] = tLinearHeight;
					end
				end

				self["positions"][tIndex] = self["positions"][tIndex] + tSign;
			end
		end

		return;

	end


	local tResult;
	local tHeight;
	local tSafeHeights;
	function tPercentileTracker:getPercentiles()

		if not tResult then
			tResult = { };
		else
			twipe(tResult);
		end

		if not self["initialized"] then
			for tIndex = 1, #self["percentiles"] do
				tResult["tm" .. floor(self["percentiles"][tIndex] * 100)] = 0;
			end

			return tResult;
		end

		tSafeHeights = { };

		for tIndex = 1, #self["percentiles"] do
			tHeight = self["heights"][tIndex];

			if tHeight and tHeight == tHeight and tHeight ~= math.huge and tHeight ~= -math.huge then
				tSafeHeights[tIndex] = tHeight;
			else
				tSafeHeights[tIndex] = 0;
			end
		end

		for tIndex = 1, #self["percentiles"] do
			tResult["tm" .. floor(self["percentiles"][tIndex] * 100)] = tSafeHeights[tIndex];
		end

		return tResult;

	end

	function tPercentileTracker:reset()

		self["initialized"] = false;
		self["totalCount"] = 0;

		for tIndex = 1, #self["percentiles"] do
			self["markers"][tIndex] = 0;
			self["counts"][tIndex] = 0;
			self["positions"][tIndex] = tIndex;
			self["desiredPositions"][tIndex] = 1 + (self["totalCount"] - 1) * self["percentiles"][tIndex];
			self["heights"][tIndex] = 0;
		end

		return;

	end

	function tPercentileTracker:getTotalCount()

		return self["totalCount"];

	end

	function tPercentileTracker:isInitialized()

		return self["initialized"];

	end

	return tPercentileTracker;

end
