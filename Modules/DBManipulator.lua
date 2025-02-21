local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

CraftLogger.DBManipulator = GUTIL:CreateRegistreeForEvents({ "PLAYER_LOGOUT" })

--Initialize Saved DB Variables
CraftLoggerDB = CraftLoggerDB or {}
VersionReshapes = VersionReshapes or {}

local print
function CraftLogger.DBManipulator:Init()
	print = CraftSimAPI:GetCraftSim().DEBUG:RegisterDebugID("CraftLogger.DBManipulator")
	print("DBManipulator Loaded")
	
	--Handle Database Changes From Previous Versions
	CraftLogger.DBManipulator:ReshapeByVersion()
	
	--Initialize Classes & Stats
	CraftLogger.CraftOutputList:new(CraftLoggerDB)
	CraftLoggerDB:SetAllStats()
	
	--Set Backups
	CraftLogger.DBManipulator.DBBackup = CraftLoggerDB:Copy()
	CraftLogger.DBManipulator.SessionBackup = CraftLoggerDB:Copy()
end

function CraftLogger.DBManipulator:PLAYER_LOGOUT()
	--Storage Efficiency
	CraftLoggerDB:Clean()
end


--Globals
function CLRestoreSession()
	systemPrint("CraftLogger: Restoring Session Backup...")
	CraftLogger.DBManipulator:RestoreDBSessionBackup()
	systemPrint("CraftLogger: Session Backup Restored.")
end

function CLUndo()
	systemPrint("CraftLogger: Restoring Backup...")
	CraftLogger.DBManipulator:RestoreDBBackup()
	systemPrint("CraftLogger: Backup Restored.")
end

function CLClear()
	systemPrint("CraftLogger: Clearing DB...")
	
	local function DBClear()
		CraftLoggerDB:Clear()
		assert(#CraftLoggerDB == 0, "CraftLogger: Failed DB Clear.")
		systemPrint("CraftLogger: DB Cleared.")
	end
	
	CraftLogger.DBManipulator:Protect(DBClear)
end

function CLClearByDate(date1, date2)
	systemPrint("CraftLogger: Clearing DB By Date...")
	
	local function DBClearByDate(date1, date2)
		local time1 = CraftLogger.UTIL:ConvertDateToTime(date1)
		local time2 = CraftLogger.UTIL:ConvertDateToTime(date2)
		local number = 0

		local function removefunc(craftOutput)
			local craftTime = CraftLogger.UTIL:ConvertDateToTime(craftOutput.date)
			if date2 then
				if time1 <= craftTime and craftTime <= time2 then
					number = number + 1
					return true
				end
			else
				if time1 <= craftTime then
					number = number + 1
					return true
				end
			end
			return false
		end
		
		CraftLogger.UTIL:RemoveFromTable(CraftLoggerDB, removefunc)
	
		for index, craftOutput in pairs(CraftLoggerDB) do
			local craftTime = CraftLogger.UTIL:ConvertDateToTime(craftOutput.date)
			if time2 then 
				assert((craftTime < time1) or (time2 < craftTime), "CraftLogger: Failed DB Clear By Date.")
			else
				assert(craftTime < time1, "CraftLogger: Failed DB Clear By Date.")
			end
		end
	
		systemPrint("CraftLogger: " .. number .. " entries removed.")
	end
	
	CraftLogger.DBManipulator:Protect(DBClearByDate, date1, date2)
end

function CLRemoveLast()
	systemPrint("CraftLogger: Removing DB Last Entry...")
	
	local function DBRemoveLastEntry()
		local sizeBefore = #CraftLoggerDB
		CraftLoggerDB[#CraftLoggerDB] = nil
		local sizeAfter = #CraftLoggerDB
		assert(sizeBefore - sizeAfter == 1, "CraftLogger: Failed DB Remove Last Entry.")
		systemPrint("CraftLogger: Removed DB Last Entry.")
	end
	
	CraftLogger.DBManipulator:Protect(DBRemoveLastEntry)
end

function CLSetStats()
	systemPrint("CraftLogger: Setting Stats...")
	
	local function DBSetStats()
		CraftLoggerDB:SetAllStats()
		systemPrint("CraftLogger: Stats Set.")
	end
	
	CraftLogger.DBManipulator:Protect(DBSetStats)
end

function CLClean()
	systemPrint("CraftLogger: Cleaning DB...")
	
	local function DBClean()
		CraftLoggerDB:Clean()
		systemPrint("CraftLogger: Cleaned DB.")
	end
	
	CraftLogger.DBManipulator:Protect(DBClean)
end

function CLDisable()
	systemPrint("CraftLogger: Disabling DB...")
	
	local function DBDisable()
		CraftLoggerDBSettings.enabled = false
		systemPrint("CraftLogger: Disabled DB.")
	end
	
	CraftLogger.DBManipulator:Protect(DBDisable)
end

function CLEnable()
	systemPrint("CraftLogger: Enabling DB...")
	
	local function DBEnable()
		CraftLoggerDBSettings.enabled = true
		systemPrint("CraftLogger: Enabled DB.")
	end
	
	CraftLogger.DBManipulator:Protect(DBEnable)
end

function CLRemoveRows(firstrow, rowtable)
	systemPrint("CraftLogger: Removing Rows...")
	
	local function DBRemoveRows(firstrow, rowtable)
		assert(type(rowtable) == "table", "CraftLogger: Error, rowtable Is Not Table.")
		local sizeBefore = #CraftLoggerDB
		
		local function removefunc(craftOutput, index) 
			if GUTIL:Find(rowtable, function(row) return (row - firstrow + 1) == index end) then
				return true
			end
			return false
		end
		CraftLogger.UTIL:RemoveFromTable(CraftLoggerDB, removefunc)
		
		local sizeAfter = #CraftLoggerDB
		
		assert(sizeBefore - sizeAfter == #rowtable, "CraftLogger: Failed Remove Rows.")
		systemPrint("CraftLogger: Removed Rows. Row Indices Have Changed. Please Regenerate Spreadsheet Before Using Again.")
	end
	
	CraftLogger.DBManipulator:Protect(DBRemoveRows, firstrow, rowtable)
end

function CLFilter(valremovefunc, field1, field2)
	systemPrint("CraftLogger: Filtering DB...")
	
	local function DBFilter(valremovefunc, field1, field2)
		local sizeBefore = #CraftLoggerDB
		
		local function removefunc(craftOutput)
			local val = craftOutput[field1]
			if field2 then
				val = val[field2]
			end
			if valremovefunc(val) then
				return true
			end
			return false
		end
		CraftLogger.UTIL:RemoveFromTable(CraftLoggerDB, removefunc)
		
		for _, craftOutput in pairs(CraftLoggerDB) do
			if field2 then
				assert(not valremovefunc(craftOutput[field1][field2]), "CraftLogger: Failed Filter DB.")
			else
				assert(not valremovefunc(craftOutput[field1]), "CraftLogger: Failed Filter DB.")
			end
		end
		
		local sizeAfter = #CraftLoggerDB
		
		systemPrint("CraftLogger: Filtered " .. assert(sizeBefore - sizeAfter, "CraftLogger: Failed Filter DB.") .. " Rows From DB.")
	end
	
	CraftLogger.DBManipulator:Protect(DBFilter, valremovefunc, field1, field2)
end

--locals
function CraftLogger.DBManipulator:Protect(func, ...)
	local retOK1, err1 = pcall(CraftLogger.DBManipulator.SetDBBackup)
	if not retOK1 then
		err1 = err1 or "CraftLogger: Unknown Error Occurred."
		systemPrint(err1 .. " Generate Backup Failed, But DB Safe.")
		return
	end
	
	--Main
	local retOK2, err2 = pcall(func, ...)
	
	if not retOK2 then
		err2 = err2 or "CraftLogger: Unknown Error Occurred."
		systemPrint(err2 .. " Restoring DB...")
		
		local retOK3, err3 = pcall(CraftLogger.DBManipulator.RestoreDBBackup)
		if not retOK3 then
			err3 = err3 or "CraftLogger: Unknown Error Occurred."
			systemPrint(err3 .. " Restoration Failed, Restoring Session Start DB...")
			
			local retOK4, err4 = pcall(CraftLogger.DBManipulator.RestoreDBSessionBackup)
			if not retOK4 then
				err4 = err4 or "CraftLogger: Unknown Error Occurred."
				systemPrint(err4 .. " Restoration Failed. DB Integrity Unknown.")
			else
				systemPrint("CraftLogger: DB Session Start Successfully Restored.")
			end
		else
			systemPrint("CraftLogger: DB Restored.")
		end
	end
end

function CraftLogger.DBManipulator:SetDBBackup()
	assert(CraftLoggerDB, "CraftLogger: No CraftLoggerDB.")
	CraftLogger.DBManipulator.DBBackup = CraftLoggerDB:Copy()
end

function CraftLogger.DBManipulator:RestoreDBBackup()
	assert(CraftLogger.DBManipulator.DBBackup, "CraftLogger: No Backup.")
	CraftLoggerDB = CraftLogger.DBManipulator.DBBackup:Copy()
end

function CraftLogger.DBManipulator:RestoreDBSessionBackup()
	assert(CraftLogger.DBManipulator.SessionBackup, "CraftLogger: No Session Backup.")
	CraftLoggerDB = CraftLogger.DBManipulator.SessionBackup:Copy()
end

--No Class or Extended Stats
function CraftLogger.DBManipulator:ReshapeByVersion()
	if not VersionReshapes["0.2.0"] then
		for _, craftOutput in pairs(CraftLoggerDB) do
			local bonusStats = {}
			for key, bonusStat in pairs(craftOutput.bonusStats) do
				if bonusStat.bonusStatName then
					bonusStats[bonusStat.bonusStatName] = bonusStat
					bonusStats[bonusStat.bonusStatName].bonusStatName = nil
				end
			end
			craftOutput.bonusStats = bonusStats
		end
		VersionReshapes["0.2.0"] = true
	end
end
