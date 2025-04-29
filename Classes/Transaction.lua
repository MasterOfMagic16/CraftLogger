local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

CraftLogger.Transaction = CraftLogger.CraftLoggerObject:extend()

function CraftLogger.Transaction:new()

end