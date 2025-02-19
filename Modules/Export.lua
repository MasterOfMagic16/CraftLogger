local CraftLogger = select(2, ...)

local GUTIL = CraftLogger.GUTIL

CraftLogger.Export = {}

local CSDebug
function CraftLogger.Export:Init()
	CSDebug = CraftSimAPI:GetCraftSim().DEBUG
end

function CLExport()
	CSDebug:StartProfiling("OVERALL EXPORT")
	local craftOutputs = CraftLogger.Export:GetDBCraftOutputs()
	local multiplier = 1
	local used = {}
	for i = 1, multiplier do
		used = GUTIL:Concat({used, craftOutputs})
	end


	CSDebug:StartProfiling("GET EXPORT TEXT")
	local text = CraftLogger.Export:GetCraftOutputTableCSV(craftOutputs)
	local text = CraftLogger.Export:GetCraftOutputTableCSV(used)
	CSDebug:StopProfiling("GET EXPORT TEXT")
	CraftLogger.UTIL:KethoEditBox_Show(text)
	CSDebug:StopProfiling("OVERALL EXPORT")
end

function CraftLogger.Export:GetDBCraftOutputs()
	local craftOutputs = GUTIL:Map(CraftLoggerDB, 
		function(co) 
		return CraftLogger.CraftOutput(co)
		end)
	return craftOutputs
end

function CraftLogger.Export:GetCraftOutputTableCSV(craftOutputs)
	
	--Speed
	local numCraftOutputs = #craftOutputs
	local colIndex = 0
	local concat = table.concat
	local insert = function(tbl, value) tbl[#tbl + 1] = value return tbl end
	
	--Get Columns
	CSDebug:StartProfiling("GET COLUMNS")
	
	--Prep Variable Columns
	--local maxItemTypes = 0
	local maxReagentTypes = 0
	local maxOptionalReagentTypes = 0
	for i = 1, numCraftOutputs do
		local co = craftOutputs[i]
		
		--local itemTypes = #co.items
		--maxItemTypes = max(maxItemTypes, itemTypes)
		
		local optionalReagentTypes = #co.optionalReagents
		maxOptionalReagentTypes = max(maxOptionalReagentTypes, optionalReagentTypes)
		
		local ReagentTypes = #co.reagents
		maxReagentTypes = max(maxReagentTypes, ReagentTypes)
	end
	
	--Set Columns & Order
	local columns = {
		"Date",
		"Game Version",
		"CraftSim Version",
		"CraftLogger Version",
		"Crafter UID",
		"Work Order",
		"Recraft",
		"Gear",
		"Item Level",
		"Soulbound",
		"Old World Recipe",
		"Expansion",
		"Profession",
		"Category Name",
		"Recipe Name",
		"Enchanting Target Name",
		"Item Name",
		"Item Quality",
		"Normal Quantity",
		"Produced Quantity",
		"Extra Quantity",
		"Triggered Multicraft",
		"Multicraft Factor",
		"Concentrating",
		"Concentration Spent",
		"Concentration Refunded",
		"Triggered Ingenuity",
		"Resourcefulness-Eligible Reagent Types Used",
		"Resourcefulness-Eligible Reagent Types Returned",
		}
	
	local bonusStatNames = {"resourcefulness", "craftingspeed", "multicraft", "ingenuity"}
	for _, bonusStatName in pairs(bonusStatNames) do
		insert(columns, bonusStatName .. " Value")
		insert(columns, bonusStatName .. " Percent")
		insert(columns, bonusStatName .. " Bonus")
	end
	
	--[[
	for i = 1, maxItemTypes do
		local title = "Item " .. i
		insert(columns, title .. " Name")
		insert(columns, title .. " Quality")
		insert(columns, title .. " Provided By Customer")
		insert(columns, title .. " Consumed Quantity")
	end
	]]
	
	for i = 1, maxOptionalReagentTypes do
		local title = "Optional Reagent " .. i
		insert(columns, title .. " Name")
		insert(columns, title .. " Quality")
		insert(columns, title .. " Provided By Customer")
		insert(columns, title .. " Consumed Quantity")
	end
	
	for i = 1, maxReagentTypes do
		local title = "Required Reagent " .. i
		insert(columns, title .. " Name")
		insert(columns, title .. " Quality")
		insert(columns, title .. " Provided By Customer")
		insert(columns, title .. " Consumed Quantity")
		insert(columns, title .. " Returned Quantity")
		insert(columns, title .. " Triggered Resourcefulness")
		insert(columns, title .. " Resourcefulness Factor")
	end
	CSDebug:StopProfiling("GET COLUMNS")
	
	
	--Generate CSV
	
	--Speed
	local numColumns = #columns
	
	
	
	CSDebug:StartProfiling("MAKE DATA")
	local csvTable = {}
	
	local function addRow(tbl)
		csvTable[#csvTable + 1] = concat(tbl, ",")
	end
	
	--Headers
	csvTable[1] = concat(columns, ",")

	local cachedProfessionInfo = {}
	local cachedItemStats = {}
	local function compFuncID(item1, item2) return item1.itemID < item2.itemID end
	local sort = table.sort
	
	local other = 0
	local multicraft = 0
	local resourcefulness = 0
	local ingenuity = 0
	local maptime = 0
	local build = 0
	local columnFind = 0
	local coFind = 0
	local valueFix = 0
	
	local function clear(tbl)
		for i = 1, #tbl do
			tbl[i] = nil
		end
	end
	
	local str = tostring
	
	local row = {}
	
	for i = 1, numCraftOutputs do
		local co = craftOutputs[i]
		local item = co.item
		local concentration = co.concentration

		--Set Stats
		
		local recipeID = co.recipeID
		
		local professionInfo 
		if cachedProfessionInfo[recipeID] then
			professionInfo = cachedProfessionInfo[recipeID]
		else
			professionInfo = C_TradeSkillUI.GetProfessionInfoByRecipeID(recipeID)
			cachedProfessionInfo[recipeID] = professionInfo
		end
		co.profession = professionInfo.parentProfessionName
		co.expansionName = professionInfo.expansionName
		
		co.isOldWorldRecipe = co.expansionID <= 8
		
		local itemID = item.itemID
		if cachedItemStats[itemID] then
			co.isGear = cachedItemStats[itemID].isGear
			co.isSoulbound = cachedItemStats[itemID].isSoulbound
		else
			cachedItemStats[itemID] = {}
			
			local isGear = C_Item.GetItemInventoryTypeByID(itemID) ~= 0
			co.isGear = isGear
			cachedItemStats[itemID].isGear = isGear
			
			local bindType = select(14, C_Item.GetItemInfo(item.itemID))
			local isSoulbound = bindType == Enum.ItemBind.OnAcquire or
								bindType == Enum.ItemBind.Quest or
								bindType == Enum.ItemBind.ToWoWAccount or
								bindType == Enum.ItemBind.ToBnetAccount
			co.isSoulbound = isSoulbound
			cachedItemStats[itemID].isSoulbound = isSoulbound
		end

		--Non-Cache
		item.normalQuantity = item.quantity - (item.extraQuantity or 0)
		
		local function tblfind(tbl, func)
			for i = 1, #tbl do
				if func(tbl[i]) then
					return true
				end
			end
			return false
		end
		
		local bonusStats = co.bonusStats
		
		if tblfind(bonusStats, function(stat) return stat.bonusStatName == "multicraft" end) then
			if item.extraQuantity then
				item.triggeredMulticraft = true
				item.multicraftFactor = item.extraQuantity / item.normalQuantity
			else
				item.triggeredMulticraft = false
				item.multicraftFactor = nil
			end
		end
		
		if tblfind(bonusStats, function(stat) return stat.bonusStatName == "resourcefulness" end) then
			local typesUsed = 0
			local typesReturned = 0
			local reagents = co.reagents
			
			for j = 1, #reagents do
				local reagent = reagents[j]
				typesUsed = typesUsed + 1
				
				if reagent.quantityReturned then
					typesReturned = typesReturned + 1
					reagent.triggeredResourcefulness = true
					reagent.resourcefulnessFactor = reagent.quantityReturned / reagent.quantity
				else
					reagent.triggeredResourcefulness = false
					reagent.resourcefulnessFactor = nil
				end
			end
			co.typesUsed = typesUsed
			co.typesReturned = typesReturned
		end

		if tblfind(bonusStats, function(stat) return stat.bonusStatName == "ingenuity" end) then
			if concentration.concentrating and concentration.triggeredIngenuity then
				concentration.ingenuityRefund = math.ceil(concentration.concentrationSpent / 2)
			else
				concentration.ingenuityRefund = nil
			end
		end
		
		--Get Overall Map
		local craftOutputMap = CraftLogger.Export:PrepareCraftOutputMap(co)

		clear(row)
		for j = 1, numColumns do 
			local value = craftOutputMap[columns[j]]
			row[j] = value ~= nil and str(value) or ""
		end
		
		csvTable[i + 1] = concat(row, ",") -- optimized
	end
	CSDebug:StopProfiling("MAKE DATA")

	CSDebug:StartProfiling("TABLE COMBINE")
	local csv = concat(csvTable, "\n")
	CSDebug:StopProfiling("TABLE COMBINE")
	
	return csv
end

function CraftLogger.Export:PrepareCraftOutputMap(craftOutput)
	
	local map = {
		["Date"] = craftOutput.date,
		["Game Version"] = craftOutput.gameVersion,
		["CraftSim Version"] = craftOutput.craftSimVersion,
		["CraftLogger Version"] = craftOutput.craftLoggerVersion,
		["Crafter UID"] = craftOutput.crafterUID,
		["Work Order"] = craftOutput.isWorkOrder,
		["Recraft"] = craftOutput.isRecraft,
		["Gear"] = craftOutput.isGear,
		["Item Level"] = craftOutput.itemLevel,
		["Soulbound"] = craftOutput.isSoulbound,
		["Old World Recipe"] = craftOutput.isOldWorldRecipe,
		["Expansion"] = craftOutput.expansionName,
		["Profession"] = craftOutput.profession,
		["Category ID"] = craftOutput.categoryID,
		["Category Name"] = craftOutput.categoryName,
		["Recipe ID"] = craftOutput.recipeID,
		["Recipe Name"] = craftOutput.recipeName,
		["Enchanting Target ID"] = craftOutput.enchantTargetItemID,
		["Enchanting Target Name"] = craftOutput.enchantTargetItemName,
		["Item ID"] = craftOutput.item.itemID,
		["Item Name"] = craftOutput.item.itemName,
		["Item Quality"] = craftOutput.item.quality,
		["Normal Quantity"] = craftOutput.item.normalQuantity,
		["Produced Quantity"] = craftOutput.item.quantity,
		["Extra Quantity"] = craftOutput.item.extraQuantity,
		["Triggered Multicraft"] = craftOutput.item.triggeredMulticraft,
		["Multicraft Factor"] = craftOutput.item.multicraftFactor,
		["Concentrating"] = craftOutput.concentration.concentrating,
		["Concentration Spent"] = craftOutput.concentration.concentrationSpent,
		["Concentration Refunded"] = craftOutput.concentration.ingenuityRefund,
		["Triggered Ingenuity"] = craftOutput.concentration.triggeredIngenuity,
		["Resourcefulness-Eligible Reagent Types Used"] = craftOutput.typesUsed,
		["Resourcefulness-Eligible Reagent Types Returned"] = craftOutput.typesReturned,
		}
		
		
	for i = 1, #craftOutput.reagents do
		local reagent = craftOutput.reagents[i]
		local title = "Required Reagent " .. i
		map[title .. " Name"] = reagent.itemName
		map[title .. " Quality"] = reagent.quality
		map[title .. " Provided By Customer"] = reagent.isOrderReagentIn
		map[title .. " Consumed Quantity"] = reagent.quantity
		map[title .. " Returned Quantity"] = reagent.quantityReturned
		map[title .. " Triggered Resourcefulness"] = reagent.triggeredResourcefulness
		map[title .. " Resourcefulness Factor"] = reagent.resourcefulnessFactor	
	end
	
	for i = 1, #craftOutput.optionalReagents do
		local reagent = craftOutput.optionalReagents[i]
		local title = "Optional Reagent " .. i
		map[title .. " Name"] = reagent.itemName
		map[title .. " Quality"] = reagent.quality
		map[title .. " Provided By Customer"] = reagent.isOrderReagentIn
		map[title .. " Consumed Quantity"] = reagent.quantity
	end
	
	for i = 1, #craftOutput.bonusStats do
		local bonusStat = craftOutput.bonusStats[i]
		local title = bonusStat.bonusStatName
		map[title .. " Value"] = bonusStat.bonusStatValue
		map[title .. " Percent"] = bonusStat.ratingPct
		map[title .. " Bonus"] = bonusStat.extraValue
	end

	return map
end