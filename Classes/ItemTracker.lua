local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

CraftLogger.ItemTracker = CraftLogger.CraftLoggerObject:extend()

function CraftLogger.ItemTracker:new()
	
end