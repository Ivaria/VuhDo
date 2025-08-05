local _;

local GetTime = GetTime;
local pairs = pairs;
local GetCVar = GetCVar;
local tonumber = tonumber;
local string = string;
local xpcall = xpcall;
local debugprofilestop = debugprofilestop;
local MeasureCall = C_AddOnProfiler and C_AddOnProfiler.MeasureCall;
local GetFramerate = GetFramerate;
local format = string.format;
local tinsert = table.insert;
local tcreate = table.create or VUHDO_tableCreate;
local tremove = table.remove;
local twipe = table.wipe;
local max = math.max;
local min = math.min;
local floor = math.floor;
local InCombatLockdown = InCombatLockdown;


VUHDO_DEFERRED_TASK_PRIORITY_LOW = 1;
VUHDO_DEFERRED_TASK_PRIORITY_NORMAL = 2;
VUHDO_DEFERRED_TASK_PRIORITY_HIGH = 3;
VUHDO_DEFERRED_TASK_PRIORITY_CRITICAL = 4;

VUHDO_DEFER_UPDATE_HEALTH = 1;
VUHDO_DEFER_UPDATE_HEALTH_BARS_FOR = 2;
VUHDO_DEFER_SET_HEALTH = 3;
VUHDO_DEFER_UPDATE_SHIELD_BAR = 4;
VUHDO_DEFER_UPDATE_HEAL_ABSORB_BAR = 5;
VUHDO_DEFER_UPDATE_MANA_BARS = 6;
VUHDO_DEFER_UPDATE_UNIT_HOTS = 7;
VUHDO_DEFER_INIT_ALL_EVENT_BOUQUETS = 8;
VUHDO_DEFER_UPDATE_BOUQUETS_FOR_EVENT = 9;
VUHDO_DEFER_UPDATE_UNIT_CYCLIC_BOUQUET = 10;
VUHDO_DEFER_UPDATE_UNIT_DEBUFF_ICONS = 11;
VUHDO_DEFER_UPDATE_UNIT_AGGRO = 12;
VUHDO_DEFER_UPDATE_UNIT_RANGE = 13;
VUHDO_DEFER_UPDATE_ALL_CLUSTERS = 14;
VUHDO_DEFER_UPDATE_CLUSTER_HIGHLIGHTS = 15;
VUHDO_DEFER_AOE_UPDATE_ALL = 16;
VUHDO_DEFER_UPDATE_SPELL_TRACE = 17;
VUHDO_DEFER_UPDATE_ALL_RAID_BARS = 18;
VUHDO_DEFER_UPDATE_PANEL_BUTTONS = 19;
VUHDO_DEFER_HANDLE_SCALE_CHANGE = 20;
VUHDO_DEFER_INIT_HEAL_BUTTON = 21;
VUHDO_DEFER_POSITION_HEAL_BUTTON = 22;
VUHDO_DEFER_REDRAW_PANEL_COMPLETE = 23;
VUHDO_DEFER_INIT_ALL_HEAL_BUTTONS_COMPLETE = 24;
VUHDO_DEFER_POSITION_CONFIG_PANELS = 25;
VUHDO_DEFER_REDRAW_PANEL = 26;
VUHDO_DEFER_REDRAW_ALL_PANELS_COMPLETE = 27;


local VUHDO_DEFERRED_TASK_TYPES = {
	VUHDO_DEFER_UPDATE_HEALTH,
	VUHDO_DEFER_UPDATE_HEALTH_BARS_FOR,
	VUHDO_DEFER_SET_HEALTH,
	VUHDO_DEFER_UPDATE_SHIELD_BAR,
	VUHDO_DEFER_UPDATE_HEAL_ABSORB_BAR,
	VUHDO_DEFER_UPDATE_MANA_BARS,
	VUHDO_DEFER_UPDATE_UNIT_HOTS,
	VUHDO_DEFER_INIT_ALL_EVENT_BOUQUETS,
	VUHDO_DEFER_UPDATE_BOUQUETS_FOR_EVENT,
	VUHDO_DEFER_UPDATE_UNIT_CYCLIC_BOUQUET,
	VUHDO_DEFER_UPDATE_UNIT_DEBUFF_ICONS,
	VUHDO_DEFER_UPDATE_UNIT_AGGRO,
	VUHDO_DEFER_UPDATE_UNIT_RANGE,
	VUHDO_DEFER_UPDATE_ALL_CLUSTERS,
	VUHDO_DEFER_UPDATE_CLUSTER_HIGHLIGHTS,
	VUHDO_DEFER_AOE_UPDATE_ALL,
	VUHDO_DEFER_UPDATE_SPELL_TRACE,
	VUHDO_DEFER_UPDATE_ALL_RAID_BARS,
	VUHDO_DEFER_UPDATE_PANEL_BUTTONS,
	VUHDO_DEFER_HANDLE_SCALE_CHANGE,
	VUHDO_DEFER_INIT_HEAL_BUTTON,
	VUHDO_DEFER_POSITION_HEAL_BUTTON,
	VUHDO_DEFER_REDRAW_PANEL_COMPLETE,
	VUHDO_DEFER_INIT_ALL_HEAL_BUTTONS_COMPLETE,
	VUHDO_DEFER_POSITION_CONFIG_PANELS,
	VUHDO_DEFER_REDRAW_PANEL,
	VUHDO_DEFER_REDRAW_ALL_PANELS_COMPLETE,
};

local VUHDO_COMBAT_UNSAFE_TASKS = {
	[VUHDO_DEFER_INIT_HEAL_BUTTON] = true,
	[VUHDO_DEFER_POSITION_HEAL_BUTTON] = true,
	[VUHDO_DEFER_REDRAW_PANEL_COMPLETE] = true,
	[VUHDO_DEFER_INIT_ALL_HEAL_BUTTONS_COMPLETE] = true,
	[VUHDO_DEFER_POSITION_CONFIG_PANELS] = true,
	[VUHDO_DEFER_REDRAW_PANEL] = true,
	[VUHDO_DEFER_REDRAW_ALL_PANELS_COMPLETE] = true,
	[VUHDO_DEFER_UPDATE_PANEL_BUTTONS] = true,
	[VUHDO_DEFER_UPDATE_ALL_RAID_BARS] = true,
};

local sDeferredTaskDelegates;
local sNextTaskEnqueueOrder = 0;

local VUHDO_DEFERRED_TASK_PROFILING_ENABLED = true;

local VUHDO_MAX_EXEC_TIME_COMBAT_US = 200 * 1000;
local VUHDO_MAX_EXEC_TIME_OOC_US = 1500 * 1000;
local VUHDO_MAX_EXEC_TIME_FRACTION = 0.01;

local VUHDO_DEFERRED_TASK_CONFIG = {
	["TARGET_EXEC_TIME_US"] = 500,
	["MAX_EXEC_TIME_US"] = 1000,
	["MIN_TASKS_PER_FRAME"] = 1,
	["INITIAL_TASKS_PER_FRAME"] = 25,
	["MAX_TASKS_PER_FRAME"] = 50,
	["ADJUST_INTERVAL_SECS"] = 1.5,
	["INCREASE_STEP"] = 1,
	["DECREASE_STEP_NORMAL"] = 1,
	["DECREASE_STEP_LARGE"] = 0.75,
	["IDLE_TASK_INC_THRESHOLD_US"] = 50,
	["DEFAULT_TARGET_FPS"] = 120,
	["MIN_FPS_FOR_BUDGET_CALC"] = 30,
	["MAX_FPS_FOR_BUDGET_CALC"] = 300,
	["FRAME_BUDGET_FRACTION"] = 0.24,
	["TARGET_TIME_RATIO_OF_MAX"] = 0.5,
	["ABS_MAX_QUEUE_TIME_US"] = 2500,
	["ABS_MIN_QUEUE_TIME_US"] = 75,
};

local VUHDO_DEFERRED_TASK_STATE = {
	["isInit"] = false,
	["maxTasksPerFrame"] = VUHDO_DEFERRED_TASK_CONFIG["INITIAL_TASKS_PER_FRAME"],
	["lastAdjustTime"] = 0,
	["processingTimeUs"] = 0,
	["framesWithWork"] = 0,
	["tasksProcessed"] = 0,
	["totalFramesInInterval"] = 0,
	["avgCostSmoothingFactor"] = 0.1,
	["totalTimeSpentUsByType"] = nil,
	["invocationCountByType"] = nil,
	["avgCostUsByType"] = nil,
	["lastAvgCostUsByType"] = nil,

	["metrics"] = {
		["sessionStartTime"] = 0,
		["totalTasksEnqueued"] = 0,
		["totalTasksDeduped"] = 0,
		["totalTasksProcessedSession"] = 0,
		["totalProcessingTimeUsSession"] = 0,
		["chunksExecutedSuccessfully"] = 0,
		["minQueueLength"] = 999999,
		["maxQueueLength"] = 0,
		["sumQueueLength"] = 0,
		["queueLengthSamples"] = 0,
		["minTasksInChunk"] = 999999,
		["maxTasksInChunk"] = 0,
		["minChunkTimeUs"] = 999999999,
		["maxChunkTimeUs"] = 0,
		["hardStopsHit"] = 0,
		["budgetExceededStops"] = 0,
		["unsafeTasksProcessed"] = 0,
		["tasksEnqueuedByType"] = { },
		["tasksProcessedByTypeSession"] = { },
		["totalTimeUsByTypeSession"] = { },
	},
};

local VUHDO_DEFERRED_TASK_CHUNK_CONFIG = {
	["LIMIT"] = 5,
};

local VUHDO_DEFERRED_TASK_CHUNK_SNAPSHOTS = {
	-- {
	--	["totalChunkTimeUs" = <total time>,
	--	["numTasksInChunk"] = <total tasks>,
	--	["tasks"] = {
	--		{
	--			["type"] = <task type>,
	--			["unit"] = <unit>,
	--			["mode"] = <mode>,
	--			["durationUs"] = <microsecond duration>,
	--		},
	--		["timestamp"] = <task timestamp>,
	--	},
	-- },
};

local VUHDO_DEFERRED_TASK_POOL;
local VUHDO_DEFERRED_TASK_POOL_MAX_SIZE = 1500;

local VUHDO_TASK_PRIORITY_QUEUE = { };
local VUHDO_TASK_QUEUE_MAP = { };



--
function VUHDO_getDeferredTaskConfig()

	return VUHDO_DEFERRED_TASK_CONFIG;

end



--
function VUHDO_getDeferredTaskState()

	return VUHDO_DEFERRED_TASK_STATE;

end



--
function VUHDO_deferUpdateHealth(aUnit, aMode, aPriority)

	VUHDO_deferTask(VUHDO_DEFER_UPDATE_HEALTH, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_CRITICAL, aUnit, aMode);

	return;

end



--
function VUHDO_deferUpdateBouquetsForEvent(aUnit, aMode, aPriority)

	VUHDO_deferTask(VUHDO_DEFER_UPDATE_BOUQUETS_FOR_EVENT, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_NORMAL, aUnit, aMode);

	return;

end



--
function VUHDO_deferUpdateShieldBar(aUnit, aPriority)

	VUHDO_deferTask(VUHDO_DEFER_UPDATE_SHIELD_BAR, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_HIGH, aUnit, 1);

	return;

end



--
function VUHDO_deferUpdateHealAbsorbBar(aUnit, aPriority)

	VUHDO_deferTask(VUHDO_DEFER_UPDATE_HEAL_ABSORB_BAR, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_HIGH, aUnit, 1);

	return;

end



--
function VUHDO_deferUpdateHealthBarsFor(aUnit, aMode, aPriority)

	VUHDO_deferTask(VUHDO_DEFER_UPDATE_HEALTH_BARS_FOR, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_HIGH, aUnit, aMode);

	return;

end



--
function VUHDO_deferUpdateAllClusters(aPriority)

	VUHDO_deferTask(VUHDO_DEFER_UPDATE_ALL_CLUSTERS, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_NORMAL);

	return;

end



--
function VUHDO_deferAoeUpdateAll(aPriority)

	VUHDO_deferTask(VUHDO_DEFER_AOE_UPDATE_ALL, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_NORMAL);

	return;

end



--
function VUHDO_deferUpdateSpellTrace(aPriority)

	VUHDO_deferTask(VUHDO_DEFER_UPDATE_SPELL_TRACE, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_NORMAL);

	return;

end



--
function VUHDO_deferUpdateAllRaidBars(aPriority)

	VUHDO_deferTask(VUHDO_DEFER_UPDATE_ALL_RAID_BARS, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_HIGH);

	return;

end



--
function VUHDO_deferUpdatePanelButtons(aPanelNum, aPriority)

	VUHDO_deferTask(VUHDO_DEFER_UPDATE_PANEL_BUTTONS, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_HIGH, aPanelNum);

	return;

end



--
function VUHDO_deferUpdateManaBars(aUnit, aMode, aPriority)

	VUHDO_deferTask(VUHDO_DEFER_UPDATE_MANA_BARS, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_NORMAL, aUnit, aMode);

	return;

end



--
function VUHDO_deferSetHealth(aUnit, aMode, aPriority)

	VUHDO_deferTask(VUHDO_DEFER_SET_HEALTH, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_CRITICAL, aUnit, aMode);

	return;

end



--
function VUHDO_deferUpdateClusterHighlights(aPriority)

	VUHDO_deferTask(VUHDO_DEFER_UPDATE_CLUSTER_HIGHLIGHTS, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_NORMAL);

	return;

end



--
function VUHDO_deferHandleScaleChange(aPriority)

	VUHDO_deferTask(VUHDO_DEFER_HANDLE_SCALE_CHANGE, aPriority or VUHDO_DEFERRED_TASK_PRIORITY_HIGH);

	return;

end



--
local tNewTask;
local function VUHDO_createDeferredTaskDelegate()

	tNewTask = {
		["args"] = { },
		["delegate"] = nil,
		["type"] = nil,
		["priority"] = VUHDO_DEFERRED_TASK_PRIORITY_NORMAL,
		["enqueueOrder"] = 0,
		["heapIndex"] = 0
	};

	return tNewTask;

end



--
local tCleanupTask;
local function VUHDO_cleanupDeferredTaskDelegate(aTask)

	tCleanupTask = aTask;

	twipe(tCleanupTask["args"]);
	tCleanupTask["delegate"] = nil;
	tCleanupTask["type"] = nil;
	tCleanupTask["priority"] = VUHDO_DEFERRED_TASK_PRIORITY_NORMAL;
	tCleanupTask["enqueueOrder"] = 0;
	tCleanupTask["heapIndex"] = 0;

	return;

end



do
	--
	local function VUHDO_getTaskKey(aType, aArgs)

		local tKey = tostring(aType);
		for i = 1, #aArgs do
			tKey = tKey .. "|" .. tostring(aArgs[i] or "");
		end
		return tKey;

	end



	--
	local function VUHDO_heapCompare(aTaskA, aTaskB)

		if aTaskA["priority"] ~= aTaskB["priority"] then
			return aTaskA["priority"] > aTaskB["priority"];
		end

		if aTaskA["enqueueOrder"] ~= aTaskB["enqueueOrder"] then
			return aTaskA["enqueueOrder"] < aTaskB["enqueueOrder"];
		end

		return aTaskA["heapIndex"] < aTaskB["heapIndex"];

	end



	--
	local tTaskA;
	local tTaskB;
	local function VUHDO_heapSwap(aHeap, anIndexA, anIndexB)

		tTaskA = aHeap[anIndexA];
		tTaskB = aHeap[anIndexB];

		aHeap[anIndexA] = tTaskB;
		aHeap[anIndexB] = tTaskA;

		tTaskA["heapIndex"] = anIndexB;
		tTaskB["heapIndex"] = anIndexA;

		return;

	end



	--
	local tChildIndex;
	local tParentIndex;
	local function VUHDO_heapSiftUp(aHeap, anIndex)

		tChildIndex = anIndex;
		tParentIndex = floor(tChildIndex / 2);

		while tChildIndex > 1 and VUHDO_heapCompare(aHeap[tChildIndex], aHeap[tParentIndex]) do
			VUHDO_heapSwap(aHeap, tChildIndex, tParentIndex);

			tChildIndex = tParentIndex;
			tParentIndex = floor(tChildIndex / 2);
		end

		return;

	end



	--
	local tParentIndex;
	local tLeftChildIndex;
	local tRightChildIndex;
	local tSwapIndex;
	local function VUHDO_heapSiftDown(aHeap, anIndex, aNumElements)

		tParentIndex = anIndex;

		while true do
			tLeftChildIndex = tParentIndex * 2;
			tRightChildIndex = tLeftChildIndex + 1;

			tSwapIndex = tParentIndex;

			if tLeftChildIndex <= aNumElements and VUHDO_heapCompare(aHeap[tLeftChildIndex], aHeap[tSwapIndex]) then
				tSwapIndex = tLeftChildIndex;
			end

			if tRightChildIndex <= aNumElements and VUHDO_heapCompare(aHeap[tRightChildIndex], aHeap[tSwapIndex]) then
				tSwapIndex = tRightChildIndex;
			end

			if tSwapIndex == tParentIndex then
				break;
			end

			VUHDO_heapSwap(aHeap, tParentIndex, tSwapIndex);

			tParentIndex = tSwapIndex;
		end

		return;

	end



	--
	local tNewIndex;
	function VUHDO_heapInsert(aHeap, aTask, aTaskMap)

		sNextTaskEnqueueOrder = sNextTaskEnqueueOrder + 1;
		aTask["enqueueOrder"] = sNextTaskEnqueueOrder;

		tNewIndex = #aHeap + 1;
		aHeap[tNewIndex] = aTask;
		aTask["heapIndex"] = tNewIndex;

		aTaskMap[VUHDO_getTaskKey(aTask["type"], aTask["args"])] = aTask;

		VUHDO_heapSiftUp(aHeap, tNewIndex);

		return;

	end



	--
	local tHeapSize;
	local tTopTask;
	local tTopTaskKey;
	function VUHDO_heapExtractTop(aHeap, aTaskMap)

		tHeapSize = #aHeap;
		if tHeapSize == 0 then
			return nil;
		end

		tTopTask = aHeap[1];

		tTopTaskKey = VUHDO_getTaskKey(tTopTask["type"], tTopTask["args"]);
		aTaskMap[tTopTaskKey] = nil;

		if tHeapSize == 1 then
			aHeap[1] = nil;
		else
			aHeap[1] = aHeap[tHeapSize];
			aHeap[tHeapSize] = nil;
			aHeap[1]["heapIndex"] = 1;

			VUHDO_heapSiftDown(aHeap, 1, tHeapSize - 1);
		end

		tTopTask["heapIndex"] = 0;

		return tTopTask;

	end



	--
	local tOldPriority;
	local function VUHDO_heapUpdateTask(aHeap, aTask, aNewPriority)

		tOldPriority = aTask["priority"];
		aTask["priority"] = aNewPriority;

		sNextTaskEnqueueOrder = sNextTaskEnqueueOrder + 1;
		aTask["enqueueOrder"] = sNextTaskEnqueueOrder;

		if aNewPriority > tOldPriority then
			VUHDO_heapSiftUp(aHeap, aTask["heapIndex"]);
		elseif aNewPriority < tOldPriority then
			VUHDO_heapSiftDown(aHeap, aTask["heapIndex"], #aHeap);
		else
			VUHDO_heapSiftUp(aHeap, aTask["heapIndex"]);
		end

		return;

	end



	--
	local tTaskChunkSnapshots;
	local tNewSnapshot;
	local tExistingSnapshot;
	local tIsDuplicate;
	local tCompositionKey;
	local tTaskTypes;
	local function VUHDO_addChunkSnapshot(aTotalChunkTimeUs, aNumTasksInChunk, aTasksDetailTable)

		if not VUHDO_DEFERRED_TASK_PROFILING_ENABLED or aTotalChunkTimeUs < (VUHDO_DEFERRED_TASK_CONFIG["MAX_EXEC_TIME_US"] or 2000) then
			return;
		end

		tTaskChunkSnapshots = VUHDO_DEFERRED_TASK_CHUNK_SNAPSHOTS;
		tIsDuplicate = false;

		if aNumTasksInChunk > 0 and aTasksDetailTable and #aTasksDetailTable > 0 then
			tTaskTypes = { };

			for _, tTaskDetail in ipairs(aTasksDetailTable) do
				tinsert(tTaskTypes, tostring(tTaskDetail["type"]));
			end

			tCompositionKey = table.concat(tTaskTypes, ",");

			for _, tExistingSnapshot in ipairs(tTaskChunkSnapshots) do
				if not tExistingSnapshot["compositionKey"] then
					tTaskTypes = { };

					if tExistingSnapshot["tasks"] then
						for _, tTaskDetail in ipairs(tExistingSnapshot["tasks"]) do
							tinsert(tTaskTypes, tostring(tTaskDetail["type"]));
						end
					end

					tExistingSnapshot["compositionKey"] = table.concat(tTaskTypes, ",");
				end

				if tExistingSnapshot["compositionKey"] == tCompositionKey then
					tExistingSnapshot["dedupedCount"] = (tExistingSnapshot["dedupedCount"] or 1) + 1;

					if aTotalChunkTimeUs > tExistingSnapshot["totalChunkTimeUs"] then
						tExistingSnapshot["totalChunkTimeUs"] = aTotalChunkTimeUs;
						tExistingSnapshot["timestamp"] = time();

						twipe(tExistingSnapshot["tasks"]);

						for _, tTaskDetailSnapshot in ipairs(aTasksDetailTable) do
							tinsert(tExistingSnapshot["tasks"], {
								["type"] = tTaskDetailSnapshot["type"],
								["args"] = tTaskDetailSnapshot["args"],
								["argCount"] = tTaskDetailSnapshot["argCount"],
								["durationUs"] = tTaskDetailSnapshot["durationUs"],
							});
						end
					end

					tIsDuplicate = true;

					break;
				end
			end
		end

		if not tIsDuplicate then
			tNewSnapshot = {
				["totalChunkTimeUs"] = aTotalChunkTimeUs,
				["numTasksInChunk"] = aNumTasksInChunk,
				["tasks"] = { },
				["timestamp"] = time(),
				["dedupedCount"] = 1,
			};

			if aTasksDetailTable and #aTasksDetailTable > 0 then
				tTaskTypes = { };

				for _, tTaskDetailSnapshot in ipairs(aTasksDetailTable) do
					tinsert(tNewSnapshot["tasks"], {
						["type"] = tTaskDetailSnapshot["type"],
						["args"] = tTaskDetailSnapshot["args"],
						["argCount"] = tTaskDetailSnapshot["argCount"],
						["durationUs"] = tTaskDetailSnapshot["durationUs"],
					});

					tinsert(tTaskTypes, tostring(tTaskDetailSnapshot["type"]));
				end

				tNewSnapshot["compositionKey"] = table.concat(tTaskTypes, ",");
			else
				tNewSnapshot["compositionKey"] = "";
			end

			tinsert(tTaskChunkSnapshots, tNewSnapshot);
		end

		table.sort(tTaskChunkSnapshots, function(a, b) return a.totalChunkTimeUs > b.totalChunkTimeUs; end);

		while #tTaskChunkSnapshots > VUHDO_DEFERRED_TASK_CHUNK_CONFIG["LIMIT"] do
			tremove(tTaskChunkSnapshots);
		end

		return;

	end



	--
	local tMetrics;
	local function VUHDO_sampleDeferredTaskQueueLength(aCurrentQueueLen)

		if not VUHDO_DEFERRED_TASK_PROFILING_ENABLED or not aCurrentQueueLen or aCurrentQueueLen <= 0 then
			return;
		end

		tMetrics = VUHDO_DEFERRED_TASK_STATE["metrics"];

		tMetrics["minQueueLength"] = min(tMetrics["minQueueLength"], aCurrentQueueLen);
		tMetrics["maxQueueLength"] = max(tMetrics["maxQueueLength"], aCurrentQueueLen);
		tMetrics["sumQueueLength"] = tMetrics["sumQueueLength"] + aCurrentQueueLen;
		tMetrics["queueLengthSamples"] = tMetrics["queueLengthSamples"] + 1;

		return;

	end



	--
	local tMetrics;
	local function VUHDO_incrementDeferredTaskHardStops()

		if not VUHDO_DEFERRED_TASK_PROFILING_ENABLED then
			return;
		end

		tMetrics = VUHDO_DEFERRED_TASK_STATE["metrics"];
		tMetrics["hardStopsHit"] = (tMetrics["hardStopsHit"] or 0) + 1;

		return;

	end



	--
	local tMetrics;
	local function VUHDO_incrementDeferredTaskBudgetExceededStops()

		if not VUHDO_DEFERRED_TASK_PROFILING_ENABLED then
			return;
		end

		tMetrics = VUHDO_DEFERRED_TASK_STATE["metrics"];
		tMetrics["budgetExceededStops"] = (tMetrics["budgetExceededStops"] or 0) + 1;

		return;

	end



	--
	local tMetrics;
	local function VUHDO_updateDeferredMinMaxTasksInChunk(aTasksCompletedInChunk)

		if not VUHDO_DEFERRED_TASK_PROFILING_ENABLED or not aTasksCompletedInChunk or aTasksCompletedInChunk <= 0 then
			return;
		end

		tMetrics = VUHDO_DEFERRED_TASK_STATE["metrics"];

		tMetrics["minTasksInChunk"] = min(tMetrics["minTasksInChunk"], aTasksCompletedInChunk);
		tMetrics["maxTasksInChunk"] = max(tMetrics["maxTasksInChunk"], aTasksCompletedInChunk);

		return;

	end



	--
	local tMetrics;
	local tHistory;
	local function VUHDO_updateDeferredTaskIndividualMetrics(aTaskType, aTaskDurationUs, aArgsSummary, aArgCount)

		if not VUHDO_DEFERRED_TASK_PROFILING_ENABLED then
			return;
		end

		tMetrics = VUHDO_DEFERRED_TASK_STATE["metrics"];

		if not tMetrics["tasksProcessedByTypeSession"][aTaskType] then
			tMetrics["tasksProcessedByTypeSession"][aTaskType] = 0;

			if tMetrics["totalTimeUsByTypeSession"][aTaskType] == nil then
				tMetrics["totalTimeUsByTypeSession"][aTaskType] = 0;
			end

			tMetrics["minTaskTimeUsByTypeSession"][aTaskType] = 9999999;
			tMetrics["maxTaskTimeUsByTypeSession"][aTaskType] = 0;
			tMetrics["maxTaskTimeUsContextByTypeSession"][aTaskType] = nil;
			tMetrics["taskDurationHistoryByType"][aTaskType] = { };
		end

		tMetrics["tasksProcessedByTypeSession"][aTaskType] = tMetrics["tasksProcessedByTypeSession"][aTaskType] + 1;
		tMetrics["totalTimeUsByTypeSession"][aTaskType] = tMetrics["totalTimeUsByTypeSession"][aTaskType] + aTaskDurationUs;

		tMetrics["minTaskTimeUsByTypeSession"][aTaskType] = min(tMetrics["minTaskTimeUsByTypeSession"][aTaskType], aTaskDurationUs);

		tHistory = tMetrics["taskDurationHistoryByType"][aTaskType];
		tinsert(tHistory, aTaskDurationUs);

		if #tHistory > 1000 then
			tremove(tHistory, 1);
		end

		if aTaskDurationUs > (tMetrics["maxTaskTimeUsByTypeSession"][aTaskType] or -1) then
			tMetrics["maxTaskTimeUsByTypeSession"][aTaskType] = aTaskDurationUs;

			tMetrics["maxTaskTimeUsContextByTypeSession"][aTaskType] = {
				["args"] = aArgsSummary,
				["argCount"] = aArgCount,
			};
		end

		return;

	end



	--
	local tMetrics;
	local function VUHDO_updateDeferredTaskChunkMetrics(aChunkElapsedTime, aNumTasksProcessed)

		if not VUHDO_DEFERRED_TASK_PROFILING_ENABLED or not aNumTasksProcessed or aNumTasksProcessed <= 0 then
			return;
		end

		tMetrics = VUHDO_DEFERRED_TASK_STATE["metrics"];

		tMetrics["chunksExecutedSuccessfully"] = (tMetrics["chunksExecutedSuccessfully"] or 0) + 1;
		tMetrics["totalTasksProcessedSession"] = (tMetrics["totalTasksProcessedSession"] or 0) + aNumTasksProcessed;
		tMetrics["totalProcessingTimeUsSession"] = (tMetrics["totalProcessingTimeUsSession"] or 0) + aChunkElapsedTime;
		tMetrics["minChunkTimeUs"] = min(tMetrics["minChunkTimeUs"] or 999999999, aChunkElapsedTime);
		tMetrics["maxChunkTimeUs"] = max(tMetrics["maxChunkTimeUs"] or 0, aChunkElapsedTime);

		return;

	end



	--
	local tTaskConfig;
	local tCurFps;
	local tBaseFpsForBudget;
	local tCVarMaxFps;
	local tEffectiveFps;
	local tFrameBudgetUs;
	local tTargetMaxTimeUs;
	local tMaxExecTimeUs;
	local tAbsMaxQueueTimeUs;
	local tExecLimitUs;
	local tMaxQueueTimeUs;
	function VUHDO_updateDynamicDeferTargets()

		tTaskConfig = VUHDO_DEFERRED_TASK_CONFIG;

		tCurFps = GetFramerate();

		if not tCurFps or tCurFps <= 0 then
			tBaseFpsForBudget = tTaskConfig["DEFAULT_TARGET_FPS"];
		else
			tBaseFpsForBudget = tCurFps;
		end

		tCVarMaxFps = tonumber(GetCVar("maxFPS")) or 0;

		if tCVarMaxFps > 0 and tCVarMaxFps < 999 then
			tBaseFpsForBudget = min(tBaseFpsForBudget, tCVarMaxFps);
		end

		tEffectiveFps = max(tTaskConfig["MIN_FPS_FOR_BUDGET_CALC"], min(tBaseFpsForBudget, tTaskConfig["MAX_FPS_FOR_BUDGET_CALC"]));

		tFrameBudgetUs = 1000000 / tEffectiveFps;
		tTargetMaxTimeUs = tFrameBudgetUs * tTaskConfig["FRAME_BUDGET_FRACTION"];

		if InCombatLockdown() then
			tMaxExecTimeUs = VUHDO_MAX_EXEC_TIME_COMBAT_US;
		else
			tMaxExecTimeUs = VUHDO_MAX_EXEC_TIME_OOC_US;
		end

		tAbsMaxQueueTimeUs = tTaskConfig["ABS_MAX_QUEUE_TIME_US"];
		tExecLimitUs = floor(tMaxExecTimeUs * VUHDO_MAX_EXEC_TIME_FRACTION);

		tMaxQueueTimeUs = min(tAbsMaxQueueTimeUs, tExecLimitUs);
		tMaxQueueTimeUs = max(tMaxQueueTimeUs, tTaskConfig["ABS_MIN_QUEUE_TIME_US"]);

		tTaskConfig["MAX_EXEC_TIME_US"] = floor(
			min(tMaxQueueTimeUs,
				max(tTaskConfig["ABS_MIN_QUEUE_TIME_US"] / tTaskConfig["TARGET_TIME_RATIO_OF_MAX"], tTargetMaxTimeUs)
			)
		);

		tTaskConfig["TARGET_EXEC_TIME_US"] = floor(tTaskConfig["MAX_EXEC_TIME_US"] * tTaskConfig["TARGET_TIME_RATIO_OF_MAX"]);
		tTaskConfig["TARGET_EXEC_TIME_US"] = max(tTaskConfig["ABS_MIN_QUEUE_TIME_US"], tTaskConfig["TARGET_EXEC_TIME_US"]);
		tTaskConfig["IDLE_TASK_INC_THRESHOLD_US"] = floor(tTaskConfig["TARGET_EXEC_TIME_US"] * 0.33);

		return;

	end



	--
	local tDelegate;
	local tTaskKey;
	local tTask;
	local tNewTask;
	local tMetrics;
	local tCurrentPriority;
	function VUHDO_enqueueDeferredTask(aType, aPriority, ...)

		if not aType then
			return;
		end

		if not sDeferredTaskDelegates then
			return;
		end

		if not VUHDO_DEFERRED_TASK_POOL then
			return;
		end

		tCurrentPriority = aPriority or VUHDO_DEFERRED_TASK_PRIORITY_NORMAL;

		if VUHDO_DEFERRED_TASK_PROFILING_ENABLED then
			tMetrics = VUHDO_DEFERRED_TASK_STATE["metrics"];
		end

		tDelegate = sDeferredTaskDelegates[aType];

		if tDelegate then
			if VUHDO_DEFERRED_TASK_PROFILING_ENABLED then
				tMetrics["totalTasksEnqueued"] = tMetrics["totalTasksEnqueued"] + 1;

				if not tMetrics["tasksEnqueuedByType"][aType] then
					tMetrics["tasksEnqueuedByType"][aType] = 0;
				end

				tMetrics["tasksEnqueuedByType"][aType] = tMetrics["tasksEnqueuedByType"][aType] + 1;
			end

			tNewTask = VUHDO_DEFERRED_TASK_POOL:get();

			for tArgCnt = 1, select("#", ...) do
				tNewTask["args"][tArgCnt] = select(tArgCnt, ...);
			end

			tNewTask["delegate"] = tDelegate;
			tNewTask["type"] = aType;
			tNewTask["priority"] = tCurrentPriority;
			tNewTask["enqueueTime"] = GetTime(); -- Track when task was enqueued

			tTaskKey = VUHDO_getTaskKey(aType, tNewTask["args"]);
			tTask = VUHDO_TASK_QUEUE_MAP[tTaskKey];

			if tTask then
				VUHDO_heapUpdateTask(VUHDO_TASK_PRIORITY_QUEUE, tTask, tCurrentPriority);

				tTask["delegate"] = tDelegate;

				VUHDO_DEFERRED_TASK_POOL:release(tNewTask);

				if VUHDO_DEFERRED_TASK_PROFILING_ENABLED then
					tMetrics["totalTasksDeduped"] = tMetrics["totalTasksDeduped"] + 1;
				end
			else
				VUHDO_heapInsert(VUHDO_TASK_PRIORITY_QUEUE, tNewTask, VUHDO_TASK_QUEUE_MAP);
			end
		end

		return;

	end



	--
	local tTaskState;
	local tTaskConfig;
	local tMaxTasksPerFrame;
	local tAvgTimeForInterval;
	local tTotalTimeSpent;
	local tInvocationCount;
	local tNewAvgCost;
	local tOldAvgCost;
	local tSmoothingFactor;
	function VUHDO_adjustDynamicDeferTasks()

		VUHDO_updateDynamicDeferTargets();

		tTaskState = VUHDO_DEFERRED_TASK_STATE;
		tTaskConfig = VUHDO_DEFERRED_TASK_CONFIG;

		tMaxTasksPerFrame = tTaskState["maxTasksPerFrame"];
		tSmoothingFactor = tTaskState["avgCostSmoothingFactor"];

		if VUHDO_DEFERRED_TASK_TYPES then
			for _, tTaskType in pairs(VUHDO_DEFERRED_TASK_TYPES) do
				tTotalTimeSpent = tTaskState["totalTimeSpentUsByType"][tTaskType] or 0;
				tInvocationCount = tTaskState["invocationCountByType"][tTaskType] or 0;

				if tInvocationCount > 0 then
					tNewAvgCost = tTotalTimeSpent / tInvocationCount;
					tOldAvgCost = tTaskState["lastAvgCostUsByType"][tTaskType] or tNewAvgCost;
					tTaskState["avgCostUsByType"][tTaskType] = (tNewAvgCost * tSmoothingFactor) + (tOldAvgCost * (1 - tSmoothingFactor));
					tTaskState["lastAvgCostUsByType"][tTaskType] = tTaskState["avgCostUsByType"][tTaskType];
					tTaskState["totalTimeSpentUsByType"][tTaskType] = 0;
					tTaskState["invocationCountByType"][tTaskType] = 0;
				elseif tTaskState["avgCostUsByType"][tTaskType] == nil then
					 tTaskState["avgCostUsByType"][tTaskType] = (tTaskConfig["TARGET_EXEC_TIME_US"] / max(1, tTaskConfig["INITIAL_TASKS_PER_FRAME"])) * 1.5;
					 tTaskState["lastAvgCostUsByType"][tTaskType] = tTaskState["avgCostUsByType"][tTaskType];
				end
			end
		end

		if tTaskState["totalFramesInInterval"] > 0 then
			tAvgTimeForInterval = tTaskState["processingTimeUs"] / tTaskState["totalFramesInInterval"];

			if tTaskState["tasksProcessed"] > 0 then
				if tAvgTimeForInterval < tTaskConfig["TARGET_EXEC_TIME_US"] then
					tMaxTasksPerFrame = tTaskState["maxTasksPerFrame"] + tTaskConfig["INCREASE_STEP"];
				elseif tAvgTimeForInterval > tTaskConfig["MAX_EXEC_TIME_US"] then
					tMaxTasksPerFrame = floor(tTaskState["maxTasksPerFrame"] * tTaskConfig["DECREASE_STEP_LARGE"]);
				elseif tAvgTimeForInterval > tTaskConfig["TARGET_EXEC_TIME_US"] then
					 tMaxTasksPerFrame = tTaskState["maxTasksPerFrame"] - tTaskConfig["DECREASE_STEP_NORMAL"];
				end
			elseif tAvgTimeForInterval < tTaskConfig["IDLE_TASK_INC_THRESHOLD_US"] then
				tMaxTasksPerFrame = tTaskState["maxTasksPerFrame"] + tTaskConfig["INCREASE_STEP"];
			end
		end

		tTaskState["maxTasksPerFrame"] = floor(max(tTaskConfig["MIN_TASKS_PER_FRAME"], min(tMaxTasksPerFrame, tTaskConfig["MAX_TASKS_PER_FRAME"])));

		tTaskState["processingTimeUs"] = 0;
		tTaskState["framesWithWork"] = 0;
		tTaskState["tasksProcessed"] = 0;
		tTaskState["totalFramesInInterval"] = 0;
		tTaskState["lastAdjustTime"] = GetTime();

		return;

	end



	--
	local tStack;
	local function VUHDO_deferredTaskErrorHandler(tError)

		-- tError is the original error string/object
		-- debugstack([thread,] startLevel, numLevels, levelsToSkip)
		-- we want to skip 3 levels:
		-- 1. this error handler function itself
		-- 2. the C/internal call for xpcall
		-- 3. the function wrapper around the delegate
		-- then start capturing from the next level (the actual delegate).
		local tStack = debugstack(1, 20, 3); -- capture up to 20 levels, after skipping 3

		return tostring(tError) .. "\nStacktrace:\n" .. tStack;

	end



	--
	local sCurrentTaskForPcall;
	local function VUHDO_pcallTaskDelegate()

		return sCurrentTaskForPcall["delegate"](unpack(sCurrentTaskForPcall["args"]));

	end



	--
	local function VUHDO_pcallWrapper()

		return xpcall(VUHDO_pcallTaskDelegate, VUHDO_deferredTaskErrorHandler);

	end



	--
	local tTask;
	local tTaskType;
	local tDelegateSuccess;
	local tDelegateResult;
	local tTaskDurationUs;
	local tTaskStartTime;
	local tArgsSummary;
	local tCnt;
	local tProfilerResult;
	function VUHDO_executeSingleTask(aTask)

		tTask = aTask;
		tTaskType = tTask["type"];

		if not tTask["delegate"] then
			return false, "No delegate function", 0;
		end

		sCurrentTaskForPcall = tTask;

		tTaskDurationUs = 0;

		if MeasureCall then
			tProfilerResult, tDelegateSuccess, tDelegateResult = MeasureCall(VUHDO_pcallWrapper);

			if tProfilerResult and tProfilerResult.elapsedMilliseconds then
				tTaskDurationUs = tProfilerResult.elapsedMilliseconds * 1000;
			end
		else
			tTaskStartTime = debugprofilestop();

			tDelegateSuccess, tDelegateResult = VUHDO_pcallWrapper();

			tTaskDurationUs = (debugprofilestop() - tTaskStartTime) * 1000;
		end

		sCurrentTaskForPcall = nil;

		if VUHDO_DEFERRED_TASK_STATE["totalTimeSpentUsByType"] then
			VUHDO_DEFERRED_TASK_STATE["totalTimeSpentUsByType"][tTaskType] = (VUHDO_DEFERRED_TASK_STATE["totalTimeSpentUsByType"][tTaskType] or 0) + tTaskDurationUs;
			VUHDO_DEFERRED_TASK_STATE["invocationCountByType"][tTaskType] = (VUHDO_DEFERRED_TASK_STATE["invocationCountByType"][tTaskType] or 0) + 1;
		end

		if not tDelegateSuccess then
			tArgsSummary = "";

			if tTask["args"] and #tTask["args"] > 0 then
				for tCnt = 1, #tTask["args"] do
					if tCnt > 1 then
						tArgsSummary = tArgsSummary .. ",";
					end

					tArgsSummary = tArgsSummary .. tostring(tTask["args"][tCnt] or "nil");
				end
			else
				tArgsSummary = "none";
			end

			VUHDO_Msg(format("Task Execution Failure: [ Args: %s Type: %s Prio: %s ]\nError: %s",
				tArgsSummary, tostring(tTaskType), tostring(tTask["priority"]),
				tostring(tDelegateResult)
			));
		end

		return tDelegateSuccess, tDelegateResult, tTaskDurationUs;

	end



	--
	local tTaskState;
	local tTaskConfig;
	local tTasksCompleted;
	local tHardStopTime;
	local tBudgetRemainingUs;
	local tDefaultEstimatedCostPerTask;
	local tTask;
	local tTaskType;
	local tEstimatedCostOfNextTask;
	local tDelegatePcallFunction;
	local tProfilerResult;
	local tDelegateSuccess;
	local tDelegateResult;
	local tTaskDurationUs;
	local tTaskStartTime;
	local tCurrentQueueLen;
	local tTaskMetricsForSnapshot = { };
	local tSuccess;
	local tResult;
	local tArgsSummary;
	function VUHDO_executeDeferredTaskChunk()

		tTaskState = VUHDO_DEFERRED_TASK_STATE;
		tTaskConfig = VUHDO_DEFERRED_TASK_CONFIG;

		if VUHDO_DEFERRED_TASK_PROFILING_ENABLED then
			tCurrentQueueLen = #VUHDO_TASK_PRIORITY_QUEUE;

			VUHDO_sampleDeferredTaskQueueLength(tCurrentQueueLen);

			twipe(tTaskMetricsForSnapshot);
		end

		tTasksCompleted = 0;
		tHardStopTime = (debugprofilestop() * 1000) + tTaskConfig["MAX_EXEC_TIME_US"] + 100;
		tBudgetRemainingUs = tTaskConfig["TARGET_EXEC_TIME_US"];
		tDefaultEstimatedCostPerTask = (tTaskConfig["TARGET_EXEC_TIME_US"] / max(1, tTaskConfig["INITIAL_TASKS_PER_FRAME"])) * 1.2;

		for tTaskCount = 1, tTaskState["maxTasksPerFrame"] do
			if #VUHDO_TASK_PRIORITY_QUEUE == 0 then
				break;
			end

			if (debugprofilestop() * 1000) > tHardStopTime and tTasksCompleted >= tTaskConfig["MIN_TASKS_PER_FRAME"] then
				VUHDO_incrementDeferredTaskHardStops();

				break;
			end

			tTask = VUHDO_TASK_PRIORITY_QUEUE[1];

			tTaskType = tTask["type"];
			tEstimatedCostOfNextTask = tTaskState["avgCostUsByType"][tTaskType] or tDefaultEstimatedCostPerTask;

			if (tTasksCompleted < tTaskConfig["MIN_TASKS_PER_FRAME"]) or (tEstimatedCostOfNextTask <= tBudgetRemainingUs) then
				tTask = VUHDO_heapExtractTop(VUHDO_TASK_PRIORITY_QUEUE, VUHDO_TASK_QUEUE_MAP);

				if tTask["delegate"] and tTaskType then
					tSuccess, tResult, tTaskDurationUs = VUHDO_executeSingleTask(tTask);

					if VUHDO_DEFERRED_TASK_PROFILING_ENABLED then
						tArgsSummary = "";

						if tTask["args"] and #tTask["args"] > 0 then
							for tCnt = 1, #tTask["args"] do
								if tCnt > 1 then
									tArgsSummary = tArgsSummary .. ",";
								end

								tArgsSummary = tArgsSummary .. tostring(tTask["args"][tCnt] or "nil");
							end
						else
							tArgsSummary = "none";
						end

						VUHDO_updateDeferredTaskIndividualMetrics(tTaskType, tTaskDurationUs, tArgsSummary, #tTask["args"] or 0);

						if tTaskMetricsForSnapshot then
							tinsert(tTaskMetricsForSnapshot, {
								["type"] = tTaskType,
								["args"] = tArgsSummary,
								["argCount"] = #tTask["args"] or 0,
								["durationUs"] = tTaskDurationUs,
							});
						end
					end

					tTasksCompleted = tTasksCompleted + 1;
					tBudgetRemainingUs = tBudgetRemainingUs - tTaskDurationUs;

					VUHDO_DEFERRED_TASK_POOL:release(tTask);

					tTask = nil;
				end
			else
				VUHDO_incrementDeferredTaskBudgetExceededStops();

				break;
			end
		end

		if VUHDO_DEFERRED_TASK_PROFILING_ENABLED and tTasksCompleted > 0 then
			VUHDO_updateDeferredMinMaxTasksInChunk(tTasksCompleted);
		end

		return tTasksCompleted, tTaskMetricsForSnapshot;

	end



	--
	local tTaskState;
	local tTaskConfig;
	local tNumTasksProcessed;
	local tChunkElapsedTime;
	local tChunkDelegate;
	local tProfilerResult;
	local tChunkStartTime;
	local tChunkTaskMetrics;
	local tFrameProcessStartTime;
	function VUHDO_processDeferredTaskQueue()

		VUHDO_checkAllSemaphoreTimeouts();

		if VUHDO_DEFERRED_TASK_STATE["totalFramesInInterval"] % 100 == 0 then
			VUHDO_validateAllSemaphoreStates();
		end

		tTaskState = VUHDO_DEFERRED_TASK_STATE;
		tTaskConfig = VUHDO_DEFERRED_TASK_CONFIG;

		if VUHDO_DEFERRED_TASK_PROFILING_ENABLED then
			tMetrics = VUHDO_DEFERRED_TASK_STATE["metrics"];
		end

		tNumTasksProcessed = 0;
		tChunkElapsedTime = 0;

		if not VUHDO_DEFERRED_TASK_POOL then
			return;
		end

		if #VUHDO_TASK_PRIORITY_QUEUE > 0 then
			tChunkDelegate = VUHDO_executeDeferredTaskChunk;

			if MeasureCall then
				tProfilerResult, tNumTasksProcessed, tChunkTaskMetrics = MeasureCall(tChunkDelegate);

				if tProfilerResult and tProfilerResult.elapsedMilliseconds then
					tChunkElapsedTime = tProfilerResult.elapsedMilliseconds * 1000;
				end
			else
				tChunkStartTime = debugprofilestop();

				tNumTasksProcessed, tChunkTaskMetrics = tChunkDelegate();

				tChunkElapsedTime = (debugprofilestop() - tChunkStartTime) * 1000;
			end

			if VUHDO_DEFERRED_TASK_PROFILING_ENABLED and tNumTasksProcessed and tNumTasksProcessed > 0 then
				VUHDO_updateDeferredTaskChunkMetrics(tChunkElapsedTime, tNumTasksProcessed);

				if tChunkTaskMetrics then
					VUHDO_addChunkSnapshot(tChunkElapsedTime, tNumTasksProcessed, tChunkTaskMetrics);
				end
			end
		end

		tTaskState["processingTimeUs"] = tTaskState["processingTimeUs"] + tChunkElapsedTime;
		tTaskState["totalFramesInInterval"] = tTaskState["totalFramesInInterval"] + 1;

		if tNumTasksProcessed > 0 then
			tTaskState["framesWithWork"] = tTaskState["framesWithWork"] + 1;
			tTaskState["tasksProcessed"] = tTaskState["tasksProcessed"] + tNumTasksProcessed;
		end

		if GetTime() - tTaskState["lastAdjustTime"] >= tTaskConfig["ADJUST_INTERVAL_SECS"] then
			VUHDO_adjustDynamicDeferTasks();
		end

		return;

	end



	--
	function VUHDO_deferTask(aType, aPriority, ...)

		VUHDO_enqueueDeferredTask(aType, aPriority, ...);

		return;

	end



	--
	function VUHDO_setDeferredTaskProfiling(anIsEnabled)

		VUHDO_DEFERRED_TASK_PROFILING_ENABLED = anIsEnabled;

		if anIsEnabled then
			VUHDO_Msg("Task profiling is enabled.");
		else
			VUHDO_Msg("Task Profiling is disabled.");
		end

		return;

	end



	--
	function VUHDO_isDeferredTaskProfilingEnabled()

		return VUHDO_DEFERRED_TASK_PROFILING_ENABLED;

	end



	--
	local tMetricsReset;
	function VUHDO_resetDeferredTaskMetrics()

		tMetricsReset = VUHDO_DEFERRED_TASK_STATE["metrics"];

		tMetricsReset["sessionStartTime"] = GetTime();
		tMetricsReset["totalTasksEnqueued"] = 0;
		tMetricsReset["totalTasksDeduped"] = 0;
		tMetricsReset["totalTasksProcessedSession"] = 0;
		tMetricsReset["totalProcessingTimeUsSession"] = 0;
		tMetricsReset["chunksExecutedSuccessfully"] = 0;

		tMetricsReset["minQueueLength"] = 999999;
		tMetricsReset["maxQueueLength"] = 0;
		tMetricsReset["sumQueueLength"] = 0;
		tMetricsReset["queueLengthSamples"] = 0;

		tMetricsReset["minTasksInChunk"] = 999999;
		tMetricsReset["maxTasksInChunk"] = 0;

		tMetricsReset["minChunkTimeUs"] = 999999999;
		tMetricsReset["maxChunkTimeUs"] = 0;

		tMetricsReset["hardStopsHit"] = 0;
		tMetricsReset["budgetExceededStops"] = 0;
		tMetricsReset["unsafeTasksProcessed"] = 0;

		twipe(tMetricsReset["tasksEnqueuedByType"]);
		twipe(tMetricsReset["tasksProcessedByTypeSession"]);
		twipe(tMetricsReset["totalTimeUsByTypeSession"]);

		if tMetricsReset["minTaskTimeUsByTypeSession"] then
			twipe(tMetricsReset["minTaskTimeUsByTypeSession"]);
		else
			tMetricsReset["minTaskTimeUsByTypeSession"] = { };
		end

		if tMetricsReset["maxTaskTimeUsByTypeSession"] then
			twipe(tMetricsReset["maxTaskTimeUsByTypeSession"]);
		else
			tMetricsReset["maxTaskTimeUsByTypeSession"] = { };
		end

		if tMetricsReset["maxTaskTimeUsContextByTypeSession"] then
			twipe(tMetricsReset["maxTaskTimeUsContextByTypeSession"]);
		else
			tMetricsReset["maxTaskTimeUsContextByTypeSession"] = { };
		end

		if tMetricsReset["taskDurationHistoryByType"] then
			twipe(tMetricsReset["taskDurationHistoryByType"]);
		else
			tMetricsReset["taskDurationHistoryByType"] = { };
		end

		twipe(VUHDO_DEFERRED_TASK_CHUNK_SNAPSHOTS);

		if VUHDO_DEFERRED_TASK_POOL and VUHDO_DEFERRED_TASK_POOL.resetMetrics then
			VUHDO_DEFERRED_TASK_POOL:resetMetrics();
		end

		if VUHDO_DEFERRED_TASK_PROFILING_ENABLED then
			VUHDO_Msg("Deferred task metrics reset.");
		end

		return;

	end



	--
	local tSortedDurations;
	local tHistoryCount;
	local tIndex;
	local tResults;
	local tDuration;
	function VUHDO_calculateTrimmedMeans(aTaskType, aHistory)

		if not aHistory or #aHistory == 0 then
			return {
				["tm50"] = 0,
				["tm80"] = 0,
				["tm90"] = 0,
				["tm99"] = 0,
				["tm100"] = 0,
			};
		end

		tSortedDurations = { };

		for _, tDuration in ipairs(aHistory) do
			tinsert(tSortedDurations, tDuration);
		end

		table.sort(tSortedDurations);

		tHistoryCount = #tSortedDurations;
		tResults = { };

		tIndex = max(1, floor(tHistoryCount * 0.5));
		tResults["tm50"] = tSortedDurations[tIndex];

		tIndex = max(1, floor(tHistoryCount * 0.8));
		tResults["tm80"] = tSortedDurations[tIndex];

		tIndex = max(1, floor(tHistoryCount * 0.9));
		tResults["tm90"] = tSortedDurations[tIndex];

		tIndex = max(1, floor(tHistoryCount * 0.99));
		tResults["tm99"] = tSortedDurations[tIndex];

		tResults["tm100"] = tSortedDurations[tHistoryCount];

		return tResults;

	end



	--
	local tMetrics;
	local tTaskConfig;
	local tSessionDuration;
	local tEnqueued;
	local tProcessed;
	local tAvgCost;
	local tTotalTimeUsForType;
	local tCurrentHardCap;
	local tPoolMetrics;
	local tMinTaskTime;
	local tMaxTaskTime;
	local tMaxTaskContextUnit;
	local tMaxTaskContextMode;
	local tMaxTaskContextArgs;
	local tDedupedText;
	local tTrimmedMeans;
	local tArgsSummary;
	function VUHDO_printDeferredTaskMetrics(anIsReset)

		if not VUHDO_DEFERRED_TASK_PROFILING_ENABLED then
			VUHDO_Msg("Task profiling is currently disabled.");

			return;
		end

		tMetrics = VUHDO_DEFERRED_TASK_STATE["metrics"];
		tTaskConfig = VUHDO_DEFERRED_TASK_CONFIG;

		tSessionDuration = GetTime() - (tMetrics["sessionStartTime"] or GetTime());

		if tSessionDuration < 0 then
			tSessionDuration = 0;
		end

		VUHDO_Msg("|cffFFD100--- Deferred Task Queue Metrics (Session: " .. format("%.2f sec", tSessionDuration) .. ") ---|r");

		VUHDO_Msg(format("|cffFFA500** Overall Tasks:|r Enqueued: %d, Deduped: %d, Processed: %d, Unsafe: %d",
			(tMetrics["totalTasksEnqueued"] or 0), (tMetrics["totalTasksDeduped"] or 0), (tMetrics["totalTasksProcessedSession"] or 0), (tMetrics["unsafeTasksProcessed"] or 0)));
		VUHDO_Msg(format("|cffFFA500** Overall Time:|r Total: %s, Chunks Executed: %d",
			VUHDO_formatTime(tMetrics["totalProcessingTimeUsSession"]), (tMetrics["chunksExecutedSuccessfully"] or 0)));

		VUHDO_Msg("|cffFFA500** Queue Length:|r Current: " .. #VUHDO_TASK_PRIORITY_QUEUE);

		if (tMetrics["queueLengthSamples"] or 0) > 0 then
			VUHDO_Msg(format("  Samples: Min: %d, Max: %d, Avg: %.2f",
				(tMetrics["minQueueLength"] == 999999 and 0 or (tMetrics["minQueueLength"] or 0)),
				(tMetrics["maxQueueLength"] or 0),
				((tMetrics["sumQueueLength"] or 0) / tMetrics["queueLengthSamples"])));
		else
			VUHDO_Msg("  Samples: No queue length samples recorded (empty or reset).");
		end

		VUHDO_Msg("|cffFFA500** Chunk Performance (for " .. (tMetrics["chunksExecutedSuccessfully"] or 0) .. " successful chunks):|r");

		if (tMetrics["chunksExecutedSuccessfully"] or 0) > 0 then
			VUHDO_Msg(format("  Tasks/Chunk: Min: %d, Max: %d, Avg: %.2f",
				(tMetrics["minTasksInChunk"] == 999999 and 0 or (tMetrics["minTasksInChunk"] or 0)),
				(tMetrics["maxTasksInChunk"] or 0),
				((tMetrics["totalTasksProcessedSession"] or 0) / tMetrics["chunksExecutedSuccessfully"])));
			VUHDO_Msg(format("  Time/Chunk: Min: %s, Max: %s, Avg: %s",
				VUHDO_formatTime(tMetrics["minChunkTimeUs"] == 999999999 and 0 or tMetrics["minChunkTimeUs"]),
				VUHDO_formatTime(tMetrics["maxChunkTimeUs"]),
				VUHDO_formatTime((tMetrics["totalProcessingTimeUsSession"] or 0) / tMetrics["chunksExecutedSuccessfully"])
			));
		else
			VUHDO_Msg("  No chunks processed tasks or metrics reset.");
		end

		VUHDO_Msg(format("  Stops: Hard (Time Limit): %d, Budget Exceeded: %d",
			(tMetrics["hardStopsHit"] or 0), (tMetrics["budgetExceededStops"] or 0)));

		VUHDO_Msg("|cffFFA500** Per-Task Type (Enqueued, Processed, tm50, tm80, tm90, tm99, tm100 [Args]): **|r");

		if VUHDO_DEFERRED_TASK_TYPES then
			for _, tTaskType in ipairs(VUHDO_DEFERRED_TASK_TYPES) do
				tEnqueued = (tMetrics["tasksEnqueuedByType"] and tMetrics["tasksEnqueuedByType"][tTaskType]) or 0;
				tProcessed = (tMetrics["tasksProcessedByTypeSession"] and tMetrics["tasksProcessedByTypeSession"][tTaskType]) or 0;
				tTotalTimeUsForType = (tMetrics["totalTimeUsByTypeSession"] and tMetrics["totalTimeUsByTypeSession"][tTaskType]) or 0;

				tAvgCost = 0;

				if tProcessed > 0 then
					tAvgCost = tTotalTimeUsForType / tProcessed;
				else
				    tAvgCost = (VUHDO_DEFERRED_TASK_STATE["avgCostUsByType"] and VUHDO_DEFERRED_TASK_STATE["avgCostUsByType"][tTaskType]) or 0;
				end

				tMinTaskTime = (tMetrics["minTaskTimeUsByTypeSession"] and tMetrics["minTaskTimeUsByTypeSession"][tTaskType]);
				tMaxTaskTime = (tMetrics["maxTaskTimeUsByTypeSession"] and tMetrics["maxTaskTimeUsByTypeSession"][tTaskType]);
				tMaxTaskContextArgs = "-";

				if tMetrics["maxTaskTimeUsContextByTypeSession"] and tMetrics["maxTaskTimeUsContextByTypeSession"][tTaskType] then
					tMaxTaskContextArgs = tostring(tMetrics["maxTaskTimeUsContextByTypeSession"][tTaskType]["args"] or "-");
				end

				tTrimmedMeans = VUHDO_calculateTrimmedMeans(tTaskType, tMetrics["taskDurationHistoryByType"][tTaskType]);

				VUHDO_Msg(format("  Type[%s]: E=%d, P=%d, tm50=%s, tm80=%s, tm90=%s, tm99=%s, tm100=%s [%s]",
					tostring(tTaskType), tEnqueued, tProcessed,
					VUHDO_formatTime(tTrimmedMeans["tm50"]), VUHDO_formatTime(tTrimmedMeans["tm80"]), 
					VUHDO_formatTime(tTrimmedMeans["tm90"]), VUHDO_formatTime(tTrimmedMeans["tm99"]), 
					VUHDO_formatTime(tTrimmedMeans["tm100"]),
					tMaxTaskContextArgs
				));
			end
		else
			VUHDO_Msg("  (VUHDO_DEFERRED_TASK_TYPES not found for detailed stats)");
		end

		VUHDO_Msg("|cffFFA500** Dynamic Config:|r");

		VUHDO_Msg(format("  Target Time/Chunk: %s, Max Time/Chunk: %s",
			VUHDO_formatTime(tTaskConfig["TARGET_EXEC_TIME_US"]), VUHDO_formatTime(tTaskConfig["MAX_EXEC_TIME_US"])));
		VUHDO_Msg(format("  Max Tasks/Frame: %d, Idle Inc Threshold: %s",
			(VUHDO_DEFERRED_TASK_STATE["maxTasksPerFrame"] or 0), VUHDO_formatTime(tTaskConfig["IDLE_TASK_INC_THRESHOLD_US"])));

		tCurrentHardCap = InCombatLockdown() and VUHDO_MAX_EXEC_TIME_COMBAT_US or VUHDO_MAX_EXEC_TIME_OOC_US;

		VUHDO_Msg(format("  Game Hard Cap (Combat=%s): %s, Effective Max Queue Time: %s",
			tostring(InCombatLockdown()), VUHDO_formatTime(tCurrentHardCap),
			VUHDO_formatTime(min((tTaskConfig["ABS_MAX_QUEUE_TIME_US"] or 0), floor(tCurrentHardCap * VUHDO_MAX_EXEC_TIME_FRACTION)))
		));

		VUHDO_Msg("|cffFFA500** Pool Stats (Size, Idle, PeakIdle, Hits, Misses, RejectedReleases): **|r");

		if VUHDO_DEFERRED_TASK_POOL and VUHDO_DEFERRED_TASK_POOL.getMetrics then
			tPoolMetrics = VUHDO_DEFERRED_TASK_POOL:getMetrics();

			VUHDO_Msg(format("  Tasks Pool: %d, %d, %d, %d, %d, %d",
				(tPoolMetrics["maxSize"] or 0), (tPoolMetrics["currentIdle"] or 0), (tPoolMetrics["peakIdleCount"] or 0),
				(tPoolMetrics["hits"] or 0), (tPoolMetrics["misses"] or 0), (tPoolMetrics["rejectedReleases"] or 0)
			));
		else
			VUHDO_Msg("  Tasks Pool: Metrics unavailable.");
		end

		if #VUHDO_DEFERRED_TASK_CHUNK_SNAPSHOTS > 0 then
			VUHDO_Msg("|cffFFA500** Top " .. #VUHDO_DEFERRED_TASK_CHUNK_SNAPSHOTS .. " Expensive Deferred Task Chunks (Threshold: >" .. (VUHDO_formatTime(VUHDO_DEFERRED_TASK_CONFIG["MAX_EXEC_TIME_US"])) .. "): **|r");

			for tSnapshotCnt, tSnapshot in ipairs(VUHDO_DEFERRED_TASK_CHUNK_SNAPSHOTS) do
				tDedupedText = "";

				if (tSnapshot["dedupedCount"] or 0) > 1 then
					tDedupedText = format(" (deduped %d times)", tSnapshot["dedupedCount"]);
				end

				VUHDO_Msg(format("  #%d: ChunkTotalTime: %s, NumTasks: %d, Timestamp: %s%s",
					tSnapshotCnt,
					VUHDO_formatTime(tSnapshot["totalChunkTimeUs"]),
					tSnapshot["numTasksInChunk"],
					date("%m/%d/%y %H:%M:%S", tSnapshot["timestamp"]),
					tDedupedText
				));

				if tSnapshot["tasks"] then
					for tCnt, tTask in ipairs(tSnapshot["tasks"]) do
						tArgsSummary = tTask["args"] or "none";

						VUHDO_Msg(format("    T%d: Type[%s] %s (Args:%s)",
							tCnt,
							tostring(tTask["type"]),
							VUHDO_formatTime(tTask["durationUs"]),
							tArgsSummary
						));
					end
				end
			end
		else
			VUHDO_Msg("|cffFFA500** No expensive deferred task chunks captured. **|r");
		end

		VUHDO_Msg("|cffFFD100--- End of Metrics ---|r");

		if anIsReset then
			VUHDO_resetDeferredTaskMetrics();
		end

		return;

	end
end





--
local tTask;
local tTasksToReinsert;
local tTasksProcessed;
local tSuccess;
local tResult;
local function VUHDO_extractAllTasksFromQueue()

	tTasksToReinsert = {};

	while #VUHDO_TASK_PRIORITY_QUEUE > 0 do
		tTask = VUHDO_heapExtractTop(VUHDO_TASK_PRIORITY_QUEUE, VUHDO_TASK_QUEUE_MAP);
		tinsert(tTasksToReinsert, tTask);
	end

	twipe(VUHDO_TASK_QUEUE_MAP);

	return tTasksToReinsert;

end



--
local tTask;
function VUHDO_reinsertTasksToQueue(aTasksToReinsert)

	for _, tTask in ipairs(aTasksToReinsert) do
		VUHDO_heapInsert(VUHDO_TASK_PRIORITY_QUEUE, tTask, VUHDO_TASK_QUEUE_MAP);
	end

	return;

end



--
local tSemaphores;
local tWaitingTasks;
local tTask;
local tSemaphoreTasksProcessed;
local tTasksToReinsert;
local tTasksProcessed;
local tSuccess;
local tResult;
local tIndex;
local tIterationCount;
local tTotalTasksProcessed;
local tCurrentTask;
local tTasksProcessedThisIteration;
local tCombatSafeTasks;
local tCombatUnsafeTasks;
function VUHDO_processCombatUnsafeTasksBeforeLockdown()

	if not VUHDO_CONFIG["USE_DEFERRED_REDRAW"] then
		return;
	end

	tTotalTasksProcessed = 0;
	tIterationCount = 0;

	repeat
		tTasksProcessedThisIteration = 0;
		tCombatSafeTasks = { };
		tCombatUnsafeTasks = { };

		while #VUHDO_TASK_PRIORITY_QUEUE > 0 do
			tCurrentTask = VUHDO_heapExtractTop(VUHDO_TASK_PRIORITY_QUEUE, VUHDO_TASK_QUEUE_MAP);

			if VUHDO_COMBAT_UNSAFE_TASKS[tCurrentTask["type"]] then
				tinsert(tCombatUnsafeTasks, tCurrentTask);
			else
				tinsert(tCombatSafeTasks, tCurrentTask);
			end
		end

		for _, tTask in ipairs(tCombatUnsafeTasks) do
			tSuccess, tResult = VUHDO_executeSingleTask(tTask);

			if tSuccess then
				tTasksProcessedThisIteration = tTasksProcessedThisIteration + 1;
				tTotalTasksProcessed = tTotalTasksProcessed + 1;
			end

			VUHDO_DEFERRED_TASK_POOL:release(tTask);
		end

		for _, tTask in ipairs(tCombatSafeTasks) do
			VUHDO_heapInsert(VUHDO_TASK_PRIORITY_QUEUE, tTask, VUHDO_TASK_QUEUE_MAP);
		end

		tIterationCount = tIterationCount + 1;
		VUHDO_checkAllSemaphoreTimeouts();

	until tTasksProcessedThisIteration == 0 or tIterationCount > 10;

	if VUHDO_DEFERRED_TASK_PROFILING_ENABLED then
		VUHDO_Msg("WARNING: Processed " .. tTotalTasksProcessed .. " combat-unsafe tasks in " .. tIterationCount .. " iterations before combat lockdown.");
	end

	if tTotalTasksProcessed > 0 then
		VUHDO_DEFERRED_TASK_STATE["metrics"]["unsafeTasksProcessed"] = (VUHDO_DEFERRED_TASK_STATE["metrics"]["unsafeTasksProcessed"] or 0) + tTotalTasksProcessed;
	end

	return;

end



--
local tTaskTypeCount;
local tTasksToReinsert;
function VUHDO_initTaskSystem()

	if not VUHDO_DEFERRED_TASK_STATE["isInit"] then
		sDeferredTaskDelegates = {
			[VUHDO_DEFER_UPDATE_HEALTH] = _G["VUHDO_updateHealth"],
			[VUHDO_DEFER_UPDATE_HEALTH_BARS_FOR] = _G["VUHDO_updateHealthBarsFor"],
			[VUHDO_DEFER_SET_HEALTH] = _G["VUHDO_setHealth"],
			[VUHDO_DEFER_UPDATE_SHIELD_BAR] = _G["VUHDO_updateShieldBar"],
			[VUHDO_DEFER_UPDATE_HEAL_ABSORB_BAR] = _G["VUHDO_updateHealAbsorbBar"],
			[VUHDO_DEFER_UPDATE_MANA_BARS] = _G["VUHDO_updateManaBars"],
			[VUHDO_DEFER_UPDATE_UNIT_HOTS] = _G["VUHDO_updateUnitHoTs"],
			[VUHDO_DEFER_INIT_ALL_EVENT_BOUQUETS] = _G["VUHDO_deferInitAllEventBouquetsDelegate"],
			[VUHDO_DEFER_UPDATE_BOUQUETS_FOR_EVENT] = _G["VUHDO_updateBouquetsForEvent"],
			[VUHDO_DEFER_UPDATE_UNIT_CYCLIC_BOUQUET] = _G["VUHDO_updateUnitCyclicBouquet"],
			[VUHDO_DEFER_UPDATE_UNIT_DEBUFF_ICONS] = _G["VUHDO_updateUnitDebuffIcons"],
			[VUHDO_DEFER_UPDATE_UNIT_AGGRO] = _G["VUHDO_updateUnitAggro"],
			[VUHDO_DEFER_UPDATE_UNIT_RANGE] = _G["VUHDO_updateUnitRange"],
			[VUHDO_DEFER_UPDATE_ALL_CLUSTERS] = _G["VUHDO_updateAllClusters"],
			[VUHDO_DEFER_UPDATE_CLUSTER_HIGHLIGHTS] = _G["VUHDO_updateClusterHighlights"],
			[VUHDO_DEFER_AOE_UPDATE_ALL] = _G["VUHDO_aoeUpdateAll"],
			[VUHDO_DEFER_UPDATE_SPELL_TRACE] = _G["VUHDO_updateSpellTrace"],
			[VUHDO_DEFER_UPDATE_ALL_RAID_BARS] = _G["VUHDO_deferUpdateAllRaidBarsDelegate"],
			[VUHDO_DEFER_UPDATE_PANEL_BUTTONS] = _G["VUHDO_updatePanelButtons"],
			[VUHDO_DEFER_HANDLE_SCALE_CHANGE] = _G["VUHDO_handleScaleChange"],
			[VUHDO_DEFER_INIT_HEAL_BUTTON] = _G["VUHDO_deferInitHealButtonDelegate"],
			[VUHDO_DEFER_POSITION_HEAL_BUTTON] = _G["VUHDO_deferPositionHealButtonDelegate"],
			[VUHDO_DEFER_REDRAW_PANEL_COMPLETE] = _G["VUHDO_deferRedrawPanelCompleteDelegate"],
			[VUHDO_DEFER_INIT_ALL_HEAL_BUTTONS_COMPLETE] = _G["VUHDO_deferInitAllHealButtonsCompleteDelegate"],
			[VUHDO_DEFER_POSITION_CONFIG_PANELS] = _G["VUHDO_deferPositionConfigPanelsDelegate"],
			[VUHDO_DEFER_REDRAW_PANEL] = _G["VUHDO_deferRedrawPanelDelegate"],
			[VUHDO_DEFER_REDRAW_ALL_PANELS_COMPLETE] = _G["VUHDO_deferRedrawAllPanelsCompleteDelegate"],
		};

		tTaskTypeCount = 0;

		if VUHDO_DEFERRED_TASK_TYPES then
			tTaskTypeCount = #VUHDO_DEFERRED_TASK_TYPES;
		end

		VUHDO_DEFERRED_TASK_STATE["totalTimeSpentUsByType"] = tcreate(0, tTaskTypeCount);
		VUHDO_DEFERRED_TASK_STATE["invocationCountByType"] = tcreate(0, tTaskTypeCount);
		VUHDO_DEFERRED_TASK_STATE["avgCostUsByType"] = tcreate(0, tTaskTypeCount);
		VUHDO_DEFERRED_TASK_STATE["lastAvgCostUsByType"] = tcreate(0, tTaskTypeCount);

		VUHDO_resetDeferredTaskMetrics();

		VUHDO_DEFERRED_TASK_POOL = VUHDO_createTablePool(
			"DeferredTask",
			VUHDO_DEFERRED_TASK_POOL_MAX_SIZE,
			VUHDO_createDeferredTaskDelegate,
			VUHDO_cleanupDeferredTaskDelegate
		);

		tTasksToReinsert = VUHDO_extractAllTasksFromQueue();

		for _, tTask in ipairs(tTasksToReinsert) do
			VUHDO_DEFERRED_TASK_POOL:release(tTask);
		end

		sNextTaskEnqueueOrder = 0;

		VUHDO_updateDynamicDeferTargets();

		VUHDO_DEFERRED_TASK_STATE["lastAdjustTime"] = GetTime();
		VUHDO_DEFERRED_TASK_STATE["maxTasksPerFrame"] = VUHDO_DEFERRED_TASK_CONFIG["INITIAL_TASKS_PER_FRAME"];

		VUHDO_DEFERRED_TASK_STATE["isInit"] = true;
	end

	return;

end
