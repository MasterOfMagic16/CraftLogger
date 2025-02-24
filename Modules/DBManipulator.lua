local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

CraftLogger.DBManipulator = GUTIL:CreateRegistreeForEvents({ "PLAYER_LOGOUT" })

--Initialize Saved DB Variables
CraftLoggerDB = CraftLoggerDB or {}
VersionReshapes = VersionReshapes or {}

local print
local CSDebug
function CraftLogger.DBManipulator:Init()
	CSDebug = CraftSimAPI:GetCraftSim().DEBUG
	print = CraftSimAPI:GetCraftSim().DEBUG:RegisterDebugID("CraftLogger.DBManipulator")
	print("DBManipulator Loaded")
	
	--Handle Data Size Constraints
	CraftLogger.DBManipulator.RollingDataFalloff()
	
	--Handle Database Changes From Previous Versions
	CraftLogger.DBManipulator:ReshapeByVersion()
	
	--Initialize Classes & Stats
	CraftLogger.CraftOutputList:new(CraftLoggerDB)
	CraftLoggerDB:SetAllStats()
end

function CraftLogger.DBManipulator:PLAYER_LOGOUT()
	--Storage Efficiency
	CraftLoggerDB:Clean()
end


--Globals
function CLDisable()
	CraftLoggerDBSettings.enabled = false
	systemPrint("CraftLogger: Disabled DB.")
end

function CLEnable()
	CraftLoggerDBSettings.enabled = true
	systemPrint("CraftLogger: Enabled DB.")
end

function CraftLogger.DBManipulator.RollingDataFalloff()
	local craftCap = 250000 -- around 340k-400k actual cap, but want enough leeway
	local removeCount = max(0, #CraftLoggerDB - craftCap)
	
	local function removefunc(craftOutput, index) 
		return index <= removeCount
	end
	
	CraftLogger.UTIL:RemoveFromTable(CraftLoggerDB, removefunc)
end

--No Class or Extended Stats
function CraftLogger.DBManipulator:ReshapeByVersion()
	if not VersionReshapes["0.2.0"] then
		for _, craftOutput in pairs(CraftLoggerDB) do
			local bonusStats = {}
			for key, bonusStat in pairs(craftOutput.bonusStats) do
				if type(key) == "number" or bonusStat.bonusStatName then
					bonusStats[bonusStat.bonusStatName] = bonusStat
					bonusStats[bonusStat.bonusStatName].bonusStatName = nil
				end
			end
			craftOutput.bonusStats = bonusStats
		end
		VersionReshapes["0.2.0"] = true
	end
end
