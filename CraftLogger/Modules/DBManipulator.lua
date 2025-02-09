local CraftLogger = select(2, ...)

local GUTIL = CraftLogger.GUTIL

CraftLogger.DBManipulator = GUTIL:CreateRegistreeForEvents({ "PLAYER_LOGIN" })

function CraftLogger.DBManipulator:PLAYER_LOGIN()
	CraftLogger.DBManipulator.DBBackup = CraftLogger.UTIL:CopyNestedTable(CraftLoggerDB)
	CraftLogger.DBManipulator.SessionBackup = CraftLogger.UTIL:CopyNestedTable(CraftLoggerDB)
end

--Globals
function CLRestoreSession()
	print("CraftLogger: Restoring Session Backup...")
	CraftLogger.DBManipulator:RestoreDBSessionBackup()
	print("CraftLogger: Session Backup Restored.")
end

function CLUndo()
	print("CraftLogger: Restoring Backup...")
	CraftLogger.DBManipulator:RestoreDBBackup()
	print("CraftLogger: Backup Restored.")
end

function CLClear()
	print("CraftLogger: Clearing DB...")
	
	local function DBClear()
		CraftLoggerDB = {}
		assert(#CraftLoggerDB == 0, "CraftLogger: Failed DB Clear.")
		print("CraftLogger: DB Cleared.")
	end
	
	CraftLogger.DBManipulator:Protect(DBClear)
end

function CLClearByDate(date1, date2)
	print("CraftLogger: Clearing DB By Date...")
	
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
	
		print("CraftLogger: " .. number .. " entries removed.")
	end
	
	CraftLogger.DBManipulator:Protect(DBClearByDate, date1, date2)
end

function CLRemoveLast()
	print("CraftLogger: Removing DB Last Entry...")
	
	local function DBRemoveLastEntry()
		local sizeBefore = #CraftLoggerDB
		CraftLoggerDB[#CraftLoggerDB] = nil
		local sizeAfter = #CraftLoggerDB
		assert(sizeBefore - sizeAfter == 1, "CraftLogger: Failed DB Remove Last Entry.")
		print("CraftLogger: Removed DB Last Entry.")
	end
	
	CraftLogger.DBManipulator:Protect(DBRemoveLastEntry)
end

function CLClean()
	print("CraftLogger: Cleaning DB...")
	
	local function DBClean()
		local craftOutputTable = CraftLogger.DBManipulator:GetDBCraftOutputTable()
		craftOutputTable:Clean()
		CraftLoggerDB = craftOutputTable.craftOutputs
		print("CraftLogger: Cleaned DB.")
	end
	
	CraftLogger.DBManipulator:Protect(DBClean)
end

function CLDisable()
	print("CraftLogger: Disabling DB...")
	
	local function DBDisable()
		CraftLoggerDBSettings.enabled = false
		print("CraftLogger: Disabled DB.")
	end
	
	CraftLogger.DBManipulator:Protect(DBDisable)
end

function CLEnable()
	print("CraftLogger: Enabling DB...")
	
	local function DBEnable()
		CraftLoggerDBSettings.enabled = true
		print("CraftLogger: Enabled DB.")
	end
	
	CraftLogger.DBManipulator:Protect(DBEnable)
end

function CLRemoveRows(firstrow, rowtable)
	print("CraftLogger: Removing Rows...")
	
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
		print("CraftLogger: Removed Rows. Row Indices Have Changed. Please Regenerate Spreadsheet Before Using Again.")
	end
	
	CraftLogger.DBManipulator:Protect(DBRemoveRows, firstrow, rowtable)
end

function CLFilter(valremovefunc, field1, field2)
	print("CraftLogger: Filtering DB...")
	
	local function DBFilter(valremovefunc, field1, field2)
	
		local craftOutputTable = CraftLogger.DBManipulator:GetDBCraftOutputTable()
		for _, craftOutput in pairs(craftOutputTable.craftOutputs) do
			craftOutput:SetOtherStats()
			craftOutput:SetMulticraftStats()
			craftOutput:SetResourcefulnessStats()
			craftOutput:SetIngenuityStats()
		end
	
		local sizeBefore = #craftOutputTable.craftOutputs
		
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
		CraftLogger.UTIL:RemoveFromTable(craftOutputTable.craftOutputs, removefunc)
		
		for _, craftOutput in pairs(craftOutputTable.craftOutputs) do
			if field2 then
				assert(not valremovefunc(craftOutput[field1][field2]), "CraftLogger: Failed Filter DB.")
			else
				assert(not valremovefunc(craftOutput[field1]), "CraftLogger: Failed Filter DB.")
			end
		end
		
		local sizeAfter = #craftOutputTable.craftOutputs
		
		craftOutputTable:Clean()
		CraftLoggerDB = craftOutputTable.craftOutputs
		
		print("CraftLogger: Filtered " .. assert(sizeBefore - sizeAfter, "CraftLogger: Failed Filter DB.") .. " Rows From DB.")
	end
	
	CraftLogger.DBManipulator:Protect(DBFilter, valremovefunc, field1, field2)
end

--locals
function CraftLogger.DBManipulator:Protect(func, ...)
	local retOK1, err1 = pcall(CraftLogger.DBManipulator.SetDBBackup)
	if not retOK1 then
		err1 = err1 or "CraftLogger: Unknown Error Occurred."
		print(err1 .. " Generate Backup Failed, But DB Safe.")
		return
	end
	
	--Main
	local retOK2, err2 = pcall(func, ...)
	
	if not retOK2 then
		err2 = err2 or "CraftLogger: Unknown Error Occurred."
		print(err2 .. " Restoring DB...")
		
		local retOK3, err3 = pcall(CraftLogger.DBManipulator.RestoreDBBackup)
		if not retOK3 then
			err3 = err3 or "CraftLogger: Unknown Error Occurred."
			print(err3 .. " Restoration Failed, Restoring Session Start DB...")
			
			local retOK4, err4 = pcall(CraftLogger.DBManipulator.RestoreDBSessionBackup)
			if not retOK4 then
				err4 = err4 or "CraftLogger: Unknown Error Occurred."
				print(err4 .. " Restoration Failed. DB Integrity Unknown.")
			else
				print("CraftLogger: DB Session Start Successfully Restored.")
			end
		else
			print("CraftLogger: DB Restored.")
		end
	end
end

function CraftLogger.DBManipulator:SetDBBackup()
	assert(CraftLoggerDB, "CraftLogger: No CraftLoggerDB.")
	CraftLogger.DBManipulator.DBBackup = CraftLogger.UTIL:CopyNestedTable(CraftLoggerDB)
end

function CraftLogger.DBManipulator:RestoreDBBackup()
	assert(CraftLogger.DBManipulator.DBBackup, "CraftLogger: No Backup.")
	CraftLoggerDB = CraftLogger.UTIL:CopyNestedTable(CraftLogger.DBManipulator.DBBackup)
end

function CraftLogger.DBManipulator:RestoreDBSessionBackup()
	assert(CraftLogger.DBManipulator.SessionBackup, "CraftLogger: No Session Backup.")
	CraftLoggerDB = CraftLogger.UTIL:CopyNestedTable(CraftLogger.DBManipulator.SessionBackup)
end

function CraftLogger.DBManipulator:GetDBCraftOutputTable()
	--Initialize Classes, craftOutputs doesnt copy any classes further down.
	local craftOutputs = GUTIL:Map(CraftLoggerDB, 
		function(co) 
		return CraftLogger.CraftOutput(co)
		end)
	return CraftLogger.CraftOutputTable(craftOutputs)
end