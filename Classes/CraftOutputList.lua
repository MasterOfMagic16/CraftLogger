local CraftLogger = select(2, ...)

local GUTIL = CraftLogger.GUTIL

CraftLogger.CraftOutputList = CraftLogger.CraftLoggerObject:extend()

--Creates Linked To Tables
function CraftLogger.CraftOutputList:new(craftOutputListData)
	for _, craftOutputData in ipairs(craftOutputListData or {}) do
		table.insert(self, CraftLogger.CraftOutput:new(craftOutputData))
	end
end

function CraftLogger.CraftOutputList:Copy()
	local copy = CraftLogger.CraftOutputList()
	for _, craftOutput in ipairs(self) do
		table.insert(copy, craftOutput:Copy())
	end
	
	return copy
end

--CraftLoggerDB Storage Reduction
function CraftLogger.CraftOutputList:Clean()
	for _, craftOutput in ipairs(self) do
		craftOutput:Clean()
	end
end

local cachedProfessionInfo = {}
local cachedItemStats = {}
function CraftLogger.CraftOutputList:SetAllStats()
	for _, craftOutput in ipairs(self) do
		craftOutput:SetAllStats(cachedProfessionInfo, cachedItemStats)
	end
end