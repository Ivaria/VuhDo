local _;



-- for saving once learnt yards in saved variables
local VUHDO_CLUSTER_BLACKLIST = { };
local VUHDO_RAID = {};

local sqrt = sqrt;
local CheckInteractDistance = CheckInteractDistance;
local GetMapInfo = GetMapInfo;
local GetCurrentMapDungeonLevel = GetCurrentMapDungeonLevel;
local WorldMapFrame = WorldMapFrame;
local GetMouseFocus = GetMouseFocus;
local pairs = pairs;
local GetTime = GetTime;
local GetSpellCooldown = GetSpellCooldown;
local twipe = table.wipe;
local tsort = table.sort;
local VUHDO_setMapToCurrentZone;
local VUHDO_tableUniqueAdd;

local VUHDO_COORD_DELTAS = { };
setmetatable(VUHDO_COORD_DELTAS, VUHDO_META_NEW_ARRAY);

local VUHDO_MAX_SAMPLES = 50;
local VUHDO_MAX_ITERATIONS = 120; -- For a 40 man raid there is a total of +800 iterations



--
local VUHDO_CLUSTER_BASE_RAID = { };
function VUHDO_clusterBuilderInitLocalOverrides()
	VUHDO_CLUSTER_BASE_RAID = _G["VUHDO_CLUSTER_BASE_RAID"];
	VUHDO_RAID = _G["VUHDO_RAID"];

	VUHDO_setMapToCurrentZone = _G["VUHDO_setMapToCurrentZone"];
	VUHDO_tableUniqueAdd = _G["VUHDO_tableUniqueAdd"];
end



--
local tIsValid;
local function VUHDO_isValidClusterUnit(anInfo)
	tIsValid = not anInfo["dead"]	and anInfo["connected"] and anInfo["visible"];
	VUHDO_CLUSTER_BLACKLIST[anInfo["unit"]] = not tIsValid;
	return tIsValid;
end



--
local tX1, tY1, tX2, tY2;
local tIsValid;
local function VUHDO_determineDistanceBetween(aUnit, anotherUnit)
	tIsValid = true;

	tX1, tY1 = UnitPosition(aUnit);
	if tX1 + tY1 <= 0 then
		VUHDO_CLUSTER_BLACKLIST[aUnit] = true;
		tIsValid = false;
	end

	tX2, tY2 = UnitPosition(anotherUnit);
	if tX2 + tY2 <= 0 then
		VUHDO_CLUSTER_BLACKLIST[anotherUnit] = true;
		tIsValid = false;
	end

	if not tIsValid then
		return nil, nil;
	end

	return tX1 - tX2, tY1 - tY2;
end



--
local tUnit, tInfo;
local tAnotherUnit, tAnotherInfo;
local tX, tY, tDeltaX, tDeltaY;
local tMaxX, tMaxY;
local tNumRaid;
local tIndex = 0;
local tNumSamples, tNumIterations;
local VuhDoDummyStub = {
	["GetName"] = function() return ""; end
};

function VUHDO_updateAllClusters()
	if WorldMapFrame:IsShown()
		or not (GetMouseFocus() or VuhDoDummyStub):GetName() then -- @UGLY Carbonite workaround
		return;
	end

	tX, tY = UnitPosition("player");
	if (tX or 0) + (tY or 0) <= 0 then
		VUHDO_setMapToCurrentZone();
	end

	tNumSamples, tNumIterations = 0, 0;
	tNumRaid = #VUHDO_CLUSTER_BASE_RAID;

	while true do
		tIndex = tIndex + 1;
		if tIndex > tNumRaid then
			tIndex = 0;
			break;
		end

		tInfo = VUHDO_CLUSTER_BASE_RAID[tIndex];
		tUnit = tInfo["unit"];

		if VUHDO_isValidClusterUnit(tInfo) then
			for tCnt = tIndex + 1, tNumRaid do
				tAnotherInfo = VUHDO_CLUSTER_BASE_RAID[tCnt];

				if VUHDO_isValidClusterUnit(tAnotherInfo) then
					tAnotherUnit = tAnotherInfo["unit"];
					tDeltaX, tDeltaY = VUHDO_determineDistanceBetween(tUnit, tAnotherUnit);

					if tDeltaX then
						if not VUHDO_COORD_DELTAS[tUnit][tAnotherUnit] then
							VUHDO_COORD_DELTAS[tUnit][tAnotherUnit] = { };
						end
						VUHDO_COORD_DELTAS[tUnit][tAnotherUnit][1] = tDeltaX;
						VUHDO_COORD_DELTAS[tUnit][tAnotherUnit][2] = tDeltaY;

						-- and the other way round to reduce iterations
						if not VUHDO_COORD_DELTAS[tAnotherUnit] then
							VUHDO_COORD_DELTAS[tAnotherUnit] = { };
						end
						if not VUHDO_COORD_DELTAS[tAnotherUnit][tUnit] then
							VUHDO_COORD_DELTAS[tAnotherUnit][tUnit] = { };
						end
						VUHDO_COORD_DELTAS[tAnotherUnit][tUnit][1] = tDeltaX;
						VUHDO_COORD_DELTAS[tAnotherUnit][tUnit][2] = tDeltaY;

						tNumSamples = tNumSamples + 1;
						if tNumSamples > 50 then break; end -- VUHDO_MAX_SAMPLES
					end
				end
				tNumIterations = tNumIterations + 1;
				if tNumIterations > 120 then break; end -- VUHDO_MAX_ITERATIONS
			end -- for
		else -- Blacklist updaten
			for tCnt = tIndex + 1, tNumRaid do
				tAnotherInfo = VUHDO_CLUSTER_BASE_RAID[tCnt];
				if not tAnotherInfo then break;	end
				VUHDO_isValidClusterUnit(tAnotherInfo);
			end
		end

		if tNumSamples > 50 or tNumIterations > 120 then break; end -- VUHDO_MAX_SAMPLES -- VUHDO_MAX_ITERATIONS
	end
end



--
function VUHDO_resetClusterCoordDeltas()
	twipe(VUHDO_COORD_DELTAS);
end



--
local function VUHDO_sortClusterComparator(aUnit, anotherUnit)
	return VUHDO_RAID[aUnit]["healthmax"] - VUHDO_RAID[aUnit]["health"]
		> VUHDO_RAID[anotherUnit]["healthmax"] - VUHDO_RAID[anotherUnit]["health"];
end



--
local tDistance, tNumber, tInfo;
local tStart, tDuration;
function VUHDO_getUnitsInRadialClusterWith(aUnit, aYardsPow, anArray, aCdSpell)
	twipe(anArray);

	if aCdSpell then
		tStart, tDuration = GetSpellCooldown(aCdSpell);
		tDuration = tDuration or 0;

		if tDuration > 1.5 then -- Don't remove clusters for gcd
			tStart = tStart or 0;
			if tStart + tDuration > GetTime() then
				return anArray;
			end
		end
	end

	tInfo = VUHDO_RAID[aUnit];
	if tInfo and not VUHDO_CLUSTER_BLACKLIST[aUnit] then
		anArray[1] = aUnit;-- Source is always part of the cluster
	end
	if not VUHDO_COORD_DELTAS[aUnit] then
		return anArray;
	end

	for tOtherUnit, tDeltas in pairs(VUHDO_COORD_DELTAS[aUnit]) do
		tDistance = ((tDeltas[1] or 0) ^ 2)  + ((tDeltas[2] or 0) ^ 2);
		if tDistance <= aYardsPow and not VUHDO_CLUSTER_BLACKLIST[tOtherUnit] then
			anArray[#anArray + 1] = tOtherUnit;
		end
	end

	tsort(anArray, VUHDO_sortClusterComparator);
	return anArray;
end
local VUHDO_getUnitsInRadialClusterWith = VUHDO_getUnitsInRadialClusterWith;



--
local tWinnerUnit, tInfo, tWinnerMissLife;
local tCurrMissLife;
local function VUHDO_getMostDeficitUnitOutOf(anIncludeList, anExcludeList)
	tWinnerUnit = nil;
	tWinnerMissLife = -1;

	for _, tUnit in pairs(anIncludeList) do
		if not anExcludeList[tUnit] then
			tInfo = VUHDO_RAID[tUnit];
			if tInfo and tInfo["healthmax"] - tInfo["health"] > tWinnerMissLife then
				tWinnerUnit = tUnit;
				tWinnerMissLife = tInfo["healthmax"] - tInfo["health"];
			end
		end
	end
	return tWinnerUnit;
end



--
local tNextJumps = { };
local tExcludeList = { };
local tNumJumps = 0;
function VUHDO_getUnitsInChainClusterWith(aUnit, aYardsPow, anArray, aMaxTargets, aCdSpell)
	twipe(anArray);
	twipe(tExcludeList)
	for tCnt = 1, aMaxTargets do
		anArray[tCnt] = aUnit;
		tExcludeList[aUnit] = true;
		VUHDO_getUnitsInRadialClusterWith(aUnit, aYardsPow, tNextJumps, aCdSpell);
		aUnit = VUHDO_getMostDeficitUnitOutOf(tNextJumps, tExcludeList);
		if not aUnit then break; end
	end
	return anArray;
end



--
local tDeltas, tDistance;
function VUHDO_getDistanceBetween(aUnit, anotherUnit)
	if VUHDO_CLUSTER_BLACKLIST[aUnit] or VUHDO_CLUSTER_BLACKLIST[anotherUnit] then
		return nil;
	end

	if VUHDO_COORD_DELTAS[aUnit] and VUHDO_COORD_DELTAS[aUnit][anotherUnit] then
		tDeltas = VUHDO_COORD_DELTAS[aUnit][anotherUnit];
		return sqrt(((tDeltas[1] or 0) ^ 2)  + ((tDeltas[2] or 0) ^ 2));
	end

	return nil;
end



--
local tDeltas, tXCoord, tYCoord;
local function VUHDO_getRealPosition(aUnit)
	if VUHDO_CLUSTER_BLACKLIST[aUnit] then return nil; end

	if VUHDO_COORD_DELTAS[aUnit] then
		tXCoord, tYCoord = UnitPosition(aUnit);
		if tXCoord and tYCoord then
			return tXCoord, tYCoord;
		end
	end

	return nil;
end

--------------------------------------------------------------------------------------------------

local VuhDoLine = { };
local sLines = { };
VuhDoLine.__index = VuhDoLine;

--
local tLine;
function VuhDoLine.create(aLineNum, aStartX, aStartY, anEndX, anEndY)
	--local tLine = { };
	if (sLines[aLineNum] == nil) then
		sLines[aLineNum] = { };
		setmetatable(sLines[aLineNum], VuhDoLine);
	end
	tLine = sLines[aLineNum];

	tLine.startX, tLine.startY, tLine.endX, tLine.endY
		= aStartX, aStartY, anEndX, anEndY;
	return tLine;
end



--
function VuhDoLine:enthaelt(anX, anY)
	return (anX >= self.startX and anX <= self.endX) or (anX <= self.startX and anX >= self.endX);
end

function VuhDoLine:hoehe()
	return self.endY - self.startY;
end

function VuhDoLine:breite()
	return self.endX - self.startX;
end

function VuhDoLine:steigung()
	return self:hoehe() / self:breite();
end

function VuhDoLine:laenge()
	return sqrt((self:hoehe() * self:hoehe()) + (self:breite() * self:breite()));
end

function VuhDoLine:achsenabschnitt()
	return self.startY - (self:steigung() * self.startX);
end


local tX;
function VuhDoLine:schnittpunkt(aLine)
	tX = (aLine:achsenabschnitt() - self:achsenabschnitt()) / (self:steigung() - aLine:steigung());
	return  tX, self:steigung() * tX + self:achsenabschnitt();
end



--
local tLineToTarget;
local tOrthogonale;
local tOrthoLaenge;
local tPlayerX, tPlayerY;
local tTargetX, tTargetY;
local tZuPruefenX, tZuPruefenY;
local tSchnittX, tSchnittY;
local tDestCluster = { };
local tNumFound;
local tUnit;
function VUHDO_getUnitsInLinearCluster(aUnit, anArray, aRange, aMaxTargets, anIsHealsPlayer, aCdSpell)
	twipe(anArray);
	twipe(tDestCluster);

	if aCdSpell then
		tStart, tDuration = GetSpellCooldown(aCdSpell);
		tDuration = tDuration or 0;

		if tDuration > 1.5 then -- Don't remove clusters for gcd
			tStart = tStart or 0;
			if tStart + tDuration > GetTime() then
				return anArray;
			end
		end
	end

	if VUHDO_MAP_WIDTH == 0 or not VUHDO_COORD_DELTAS[aUnit] then return; end

	tPlayerX, tPlayerY = VUHDO_getRealPosition("player");
	if not tPlayerX then return; end

	tTargetX, tTargetY = VUHDO_getRealPosition(aUnit);
	if not tTargetX then return; end

	tLineToTarget = VuhDoLine.create(1, tPlayerX, tPlayerY, tTargetX, tTargetY);

	for _, tInfo in pairs(VUHDO_CLUSTER_BASE_RAID) do
		tUnit = tInfo["unit"];
		if "player" ~= tUnit and not VUHDO_CLUSTER_BLACKLIST[tUnit] then
			tZuPruefenX, tZuPruefenY = VUHDO_getRealPosition(tUnit);
			if tZuPruefenX then

				tOrthogonale = VuhDoLine.create(2,
					tZuPruefenX - tLineToTarget:hoehe(),
					tZuPruefenY + tLineToTarget:breite(),
					tZuPruefenX + tLineToTarget:hoehe(),
					tZuPruefenY - tLineToTarget:breite());

				tSchnittX, tSchnittY = tOrthogonale:schnittpunkt(tLineToTarget);

				if tLineToTarget:enthaelt(tSchnittX, tSchnittY) then
					tOrthoLaenge = VuhDoLine.create(3, tZuPruefenX, tZuPruefenY,
						tSchnittX, tSchnittY);
					if tOrthoLaenge:laenge() <= aRange then
						tDestCluster[#tDestCluster + 1] = aUnit;
					end
				end
			end
		end
	end

	if anIsHealsPlayer then
		if (VUHDO_tableUniqueAdd(tDestCluster, "player")) then
			aMaxTargets = aMaxTargets + 1;
		end
	end

	tsort(tDestCluster, VUHDO_sortClusterComparator);
	tNumFound = #tDestCluster;
	for tCnt = 1, tNumFound > aMaxTargets and aMaxTargets or tNumFound do
		anArray[tCnt] = tDestCluster[tCnt];
	end
end

