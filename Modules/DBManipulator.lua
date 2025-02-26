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
			
			--Array to Key-Value for bonusStats
			for key, bonusStat in ipairs(craftOutput.bonusStats) do
				craftOutput.bonusStats[bonusStat.bonusStatName] = bonusStat
				craftOutput.bonusStats[bonusStat.bonusStatName].bonusStatName = nil
				craftOutput.bonusStats[key] = nil
			end
			
			--Item to Items list
			if craftOutput.item then
				craftOutput.items = {craftOutput.item}
				craftOutput.item = nil
				if craftOutput.itemLevel then
					craftOutput.items[1].itemLevel = craftOutput.itemLevel
				end
				craftOutput.itemLevel = nil
			end
			
			--Salvage Category
			if craftOutput.isSalvageRecipe == nil then
				craftOutput.isSalvageRecipe = false
			end
		end
		VersionReshapes["0.2.0"] = true
	end
end
