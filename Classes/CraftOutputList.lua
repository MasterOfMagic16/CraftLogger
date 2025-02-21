local CraftLogger = select(2, ...)

local GUTIL = CraftLogger.GUTIL

CraftLogger.CraftOutputList = CraftLogger.CraftLoggerObject:extend()

--Sets Object Prototype As CraftOutputList
function CraftLogger.CraftOutputList:new(craftOutputListData)
	craftOutputListData = craftOutputListData or {}
	
	--Set Craft Output Object Prototypes
	for _, craftOutputData in ipairs(craftOutputListData) do
		CraftLogger.CraftOutput:new(craftOutputData)
	end
	
	setmetatable(craftOutputListData, self)
	self.__index = self
	
	return craftOutputListData
end

function CraftLogger.CraftOutputList:Copy()
	local copy = CraftLogger.CraftOutputList:new()
	for i, craftOutput in ipairs(self) do
		copy[i] = craftOutput:Copy()
	end
	return copy
end

function CraftLogger.CraftOutputList:Clear()
	for key, value in pairs(self) do
		self[key] = nil
	end
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

function CraftLogger.CraftOutputList:InsertLoggerCraftOutput(craftOutput)
	craftOutput:SetAllStats(cachedProfessionInfo, cachedItemStats)
	table.insert(self, craftOutput)
end