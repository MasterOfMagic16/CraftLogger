local CraftLogger = select(2, ...)

local GUTIL = CraftLogger.GUTIL

CraftLogger.CraftOutputTable = CraftLogger.CraftLoggerObject:extend()

function CraftLogger.CraftOutputTable:new(craftOutputs)
	self.craftOutputs = {}
	for _, craftOutput in pairs(craftOutputs or {}) do
		table.insert(self.craftOutputs, craftOutput:Copy())
	end
end

function CraftLogger.CraftOutputTable:Clear()
	self.craftOutputs = {}
end

function CraftLogger.CraftOutputTable:Copy()
	local copy = CraftLogger.CraftOutputTable(self.craftOutputs)
	return copy
end

--Prepare for addition to CraftLoggerDB
function CraftLogger.CraftOutputTable:Clean()
	for _, craftOutput in pairs(self.craftOutputs) do
		craftOutput:Clean()
	end
end