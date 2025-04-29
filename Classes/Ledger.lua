local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

CraftLogger.Ledger = CraftLogger.CraftLoggerObject:extend()

function CraftLogger.Ledger:new()

end