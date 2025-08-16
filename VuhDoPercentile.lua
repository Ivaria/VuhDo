local _;

local floor = math.floor;
local max = math.max;
local min = math.min;
local twipe = table.wipe;
local tinsert = table.insert;
local tremove = table.remove;
local tsort = table.sort;
local random = math.random;



--
local tPercentileTracker;
function VUHDO_createPercentileTracker(aPercentiles)

	if not aPercentiles then
		aPercentiles = { 0.5, 0.8, 0.9, 0.99, 1.0 };
	end

	tPercentileTracker = { };

	tPercentileTracker["percentiles"] = aPercentiles;
	tPercentileTracker["mainReservoir"] = { };
	tPercentileTracker["extremeReservoir"] = { };
	tPercentileTracker["mainReservoirSize"] = 1000;
	tPercentileTracker["extremeReservoirSize"] = 200;
	tPercentileTracker["threshold"] = nil;
	tPercentileTracker["mainSorted"] = true;
	tPercentileTracker["extremeSorted"] = true;
	tPercentileTracker["maxValue"] = 0;
	tPercentileTracker["totalCount"] = 0;

	local tReservoir;
	local tMaxGap;
	local tGapThreshold;
	local tGap;
	local function autoDetectThreshold(self)

		if #self["mainReservoir"] < 20 then
			return nil;
		end

		if not self["mainSorted"] then
			tsort(self["mainReservoir"]);

			self["mainSorted"] = true;
		end

		tReservoir = self["mainReservoir"];
		tMaxGap = 0;
		tGapThreshold = nil;

		for tIndex = 1, #tReservoir - 1 do
			tGap = tReservoir[tIndex + 1] / tReservoir[tIndex];

			if tGap > tMaxGap and tGap > 10 then
				tMaxGap = tGap;
				tGapThreshold = tReservoir[tIndex];
			end
		end

		return tGapThreshold;

	end

	local tProbability;
	local tIndex;
	function tPercentileTracker:update(aValue)

		self["totalCount"] = self["totalCount"] + 1;

		if aValue > self["maxValue"] then
			self["maxValue"] = aValue;
		end

		if not self["threshold"] then
			self["threshold"] = autoDetectThreshold(self);
		end

		if self["threshold"] and aValue > self["threshold"] then
			if #self["extremeReservoir"] < self["extremeReservoirSize"] then
				tinsert(self["extremeReservoir"], aValue);
			else
				tProbability = self["extremeReservoirSize"] / self["totalCount"];

				if random() < tProbability then
					tIndex = random(1, self["extremeReservoirSize"]);
					self["extremeReservoir"][tIndex] = aValue;
				end
			end

			self["extremeSorted"] = false;
		else
			if #self["mainReservoir"] < self["mainReservoirSize"] then
				tinsert(self["mainReservoir"], aValue);
			else
				tProbability = self["mainReservoirSize"] / self["totalCount"];

				if random() < tProbability then
					tIndex = random(1, self["mainReservoirSize"]);
					self["mainReservoir"][tIndex] = aValue;
				end
			end

			self["mainSorted"] = false;
		end

		return;

	end

	local tResult;
	local tCombined;
	local tPercentile;
	local tPosition;
	local tFloorPos;
	local tCeilPos;
	local tValue;
	local tWeight;
	local tValue1;
	local tValue2;
	local tIndex;
	function tPercentileTracker:getPercentiles()

		tResult = { };

		if #self["mainReservoir"] == 0 and #self["extremeReservoir"] == 0 then
			for tIndex = 1, #self["percentiles"] do
				tResult["tm" .. floor(self["percentiles"][tIndex] * 100)] = 0;
			end

			return tResult;
		end

		if not self["mainSorted"] then
			tsort(self["mainReservoir"]);
			self["mainSorted"] = true;
		end

		if not self["extremeSorted"] then
			tsort(self["extremeReservoir"]);
			self["extremeSorted"] = true;
		end

		tCombined = { };

		for tIndex = 1, #self["mainReservoir"] do
			tinsert(tCombined, self["mainReservoir"][tIndex]);
		end

		for tIndex = 1, #self["extremeReservoir"] do
			tinsert(tCombined, self["extremeReservoir"][tIndex]);
		end

		tsort(tCombined);

		for tIndex = 1, #self["percentiles"] do
			tPercentile = self["percentiles"][tIndex];
			tPosition = tPercentile * #tCombined;
			tFloorPos = floor(tPosition);
			tCeilPos = ceil(tPosition);

			if tFloorPos <= 0 then
				tValue = tCombined[1];
			elseif tCeilPos > #tCombined then
				tValue = tCombined[#tCombined];
			elseif tFloorPos == tCeilPos then
				tValue = tCombined[tFloorPos];
			else
				tValue1 = tCombined[tFloorPos];
				tValue2 = tCombined[tCeilPos];
				tWeight = tPosition - tFloorPos;
				tValue = tValue1 + (tValue2 - tValue1) * tWeight;
			end

			tResult["tm" .. floor(tPercentile * 100)] = tValue;
		end

		tResult["tm100"] = self["maxValue"];

		return tResult;

	end

	function tPercentileTracker:reset()

		twipe(self["mainReservoir"]);
		twipe(self["extremeReservoir"]);

		self["totalCount"] = 0;
		self["threshold"] = nil;
		self["mainSorted"] = true;
		self["extremeSorted"] = true;
		self["maxValue"] = 0;

		return;

	end


	function tPercentileTracker:isInitialized()

		return #self["mainReservoir"] > 0 or #self["extremeReservoir"] > 0;

	end

	return tPercentileTracker;

end
