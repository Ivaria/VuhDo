local _;

local floor = math.floor;
local ceil = math.ceil;
local tsort = table.sort;



--
local tPercentileTracker;
function VUHDO_createPercentileTracker(aPercentiles)

	if not aPercentiles then
		aPercentiles = { 0.5, 0.8, 0.9, 0.99, 1.0 };
	end

	tPercentileTracker = {
		["percentiles"] = aPercentiles,
		["buffer"] = { },
		["bufferSize"] = 1000,
		["nextIndex"] = 1,
		["isFull"] = false,
		["maxValue"] = 0,
		["totalCount"] = 0,
		["sorted"] = nil,
		["lastSortCount"] = 0,
		["sortThreshold"] = 100,
		["resultCache"] = { },
	};

	for tIndex = 1, #aPercentiles do
		local tPercentile = aPercentiles[tIndex];
		local tKey = "tm" .. floor(tPercentile * 100);
		tPercentileTracker["resultCache"][tIndex] = tKey;
	end

	function tPercentileTracker:update(aValue)

		self["buffer"][self["nextIndex"]] = aValue;
		self["nextIndex"] = self["nextIndex"] + 1;

		if self["nextIndex"] > self["bufferSize"] then
			self["nextIndex"] = 1;
			self["isFull"] = true;
		end

		if aValue > self["maxValue"] then
			self["maxValue"] = aValue;
		end

		self["totalCount"] = self["totalCount"] + 1;

		if self["totalCount"] - self["lastSortCount"] >= self["sortThreshold"] then
			self["sorted"] = nil;
		end

		return;

	end

	local tResult;
	local tPercentile;
	local tPosition;
	local tFloorPos;
	local tCeilPos;
	local tValue;
	local tWeight;
	local tValue1;
	local tValue2;
	local tCount;
	local tSortedCount;
	local tCachedKey;
	function tPercentileTracker:getPercentiles()

		tResult = { };

		if self["totalCount"] == 0 then
			for tIndex = 1, #self["percentiles"] do
				tCachedKey = self["resultCache"][tIndex];
				tResult[tCachedKey] = 0;
			end

			return tResult;
		end

		if not self["sorted"] then
			self["sorted"] = { };

			tCount = self["isFull"] and self["bufferSize"] or (self["nextIndex"] - 1);

			for tIndex = 1, tCount do
				self["sorted"][tIndex] = self["buffer"][tIndex];
			end

			tsort(self["sorted"]);

			self["lastSortCount"] = self["totalCount"];
		end

		tSortedCount = #self["sorted"];

		for tIndex = 1, #self["percentiles"] do
			tPercentile = self["percentiles"][tIndex];
			tPosition = tPercentile * tSortedCount;

			tFloorPos = floor(tPosition);
			tCeilPos = ceil(tPosition);

			if tFloorPos <= 0 then
				tValue = self["sorted"][1];
			elseif tCeilPos > tSortedCount then
				tValue = self["sorted"][tSortedCount];
			elseif tFloorPos == tCeilPos then
				tValue = self["sorted"][tFloorPos];
			else
				tValue1 = self["sorted"][tFloorPos];
				tValue2 = self["sorted"][tCeilPos];
				tWeight = tPosition - tFloorPos;

				tValue = tValue1 + (tValue2 - tValue1) * tWeight;
			end

			tCachedKey = self["resultCache"][tIndex];
			tResult[tCachedKey] = tValue;
		end

		-- Add max value if 100th percentile (1.0) is included in the percentiles
		for tIndex = 1, #self["percentiles"] do
			if self["percentiles"][tIndex] == 1.0 then
				tResult["tm100"] = self["maxValue"];
				break;
			end
		end

		return tResult;

	end



	--
	function tPercentileTracker:reset()

		for tIndex = 1, self["bufferSize"] do
			self["buffer"][tIndex] = nil;
		end

		self["nextIndex"] = 1;
		self["isFull"] = false;
		self["maxValue"] = 0;
		self["totalCount"] = 0;
		self["sorted"] = nil;
		self["lastSortCount"] = 0;

		return;

	end



	--
	function tPercentileTracker:isInitialized()

		return self["totalCount"] > 0;

	end

	return tPercentileTracker;

end



--
function VUHDO_sortPercentileKeys(aPercentileKeys)

	table.sort(aPercentileKeys, function(a, b)
		local aPercentile = tonumber(string.sub(a, 3)) or 0;
		local bPercentile = tonumber(string.sub(b, 3)) or 0;

		return aPercentile < bPercentile;
	end);

	return;

end