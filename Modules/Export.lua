local CraftLogger = select(2, ...)

local GUTIL = CraftLogger.GUTIL

CraftLogger.Export = {}

local CSDebug
function CraftLogger.Export:Init()
	CSDebug = CraftSimAPI:GetCraftSim().DEBUG
end

function CLTest()
	local craftOutputs = CraftLogger.Export:GetDBCraftOutputs()
	
	CSDebug:StartProfiling("Test 1")
	for j = 1, 500 do
		local numCraftOutputs = #craftOutputs
		local maxReagentTypes = 0
		local maxOptionalReagentTypes = 0
		for i = 1, numCraftOutputs do
			local co = craftOutputs[i]
			
			maxOptionalReagentTypes = max(maxOptionalReagentTypes, #co.optionalReagents)
			
			maxReagentTypes = max(maxReagentTypes, #co.reagents)
		end
	end
	CSDebug:StopProfiling("Test 1")
	
	
	CSDebug:StartProfiling("Test 2")
	for j = 1, 500 do
		local numCraftOutputs = #craftOutputs
		local maxReagentTypes = 0
		local maxOptionalReagentTypes = 0
		for i = 1, numCraftOutputs do
			local co = craftOutputs[i]
			
			local optionalReagents = co.optionalReagents
			local optionalReagentTypes = #optionalReagents
			maxOptionalReagentTypes = max(maxOptionalReagentTypes, optionalReagentTypes)
			
			local reagents = co.reagents
			local ReagentTypes = #reagents
			maxReagentTypes = max(maxReagentTypes, ReagentTypes)
		end
	end
	CSDebug:StopProfiling("Test 2")
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
	local maximum = max
	local str = tostring
	local getProfessionInfo = C_TradeSkillUI.GetProfessionInfoByRecipeID
	local getItemInfo = C_Item.GetItemInfo
	local getItemInventoryType = C_Item.GetItemInventoryTypeByID
	local ceiling = ceil
	
	--Get Columns
	CSDebug:StartProfiling("GET COLUMNS")
	
	--Prep Variable Columns
	local maxReagentTypes = 0
	local maxOptionalReagentTypes = 0
	for i = 1, numCraftOutputs do
		local co = craftOutputs[i]
		
		maxOptionalReagentTypes = maximum(maxOptionalReagentTypes, #co.optionalReagents)
		maxReagentTypes = maximum(maxReagentTypes, #co.reagents)
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
	
	local numColumns = #columns
	
	for _, bonusStatName in ipairs({"resourcefulness", "craftingspeed", "multicraft", "ingenuity"}) do
		numColumns = numColumns + 1
		columns[numColumns] = bonusStatName .. " Value"
		
		numColumns = numColumns + 1
		columns[numColumns] = bonusStatName .. " Percent"
		
		numColumns = numColumns + 1
		columns[numColumns] = bonusStatName .. " Bonus"
	end
	
	for i = 1, maxOptionalReagentTypes do
		local title = "Optional Reagent " .. i
		
		numColumns = numColumns + 1
		columns[numColumns] = title .. " Name"
		
		numColumns = numColumns + 1
		columns[numColumns] = title .. " Quality"
		
		numColumns = numColumns + 1
		columns[numColumns] = title .. " Provided By Customer"
		
		numColumns = numColumns + 1
		columns[numColumns] = title .. " Consumed Quantity"
	end
	
	for i = 1, maxReagentTypes do
		local title = "Required Reagent " .. i
		
		numColumns = numColumns + 1
		columns[numColumns] = title .. " Name"
		
		numColumns = numColumns + 1
		columns[numColumns] = title .. " Quality"
		
		numColumns = numColumns + 1
		columns[numColumns] = title .. " Provided By Customer"
		
		numColumns = numColumns + 1
		columns[numColumns] = title .. " Consumed Quantity"
		
		numColumns = numColumns + 1
		columns[numColumns] = title .. " Returned Quantity"
		
		numColumns = numColumns + 1
		columns[numColumns] = title .. " Triggered Resourcefulness"
		
		numColumns = numColumns + 1
		columns[numColumns] = title .. " Resourcefulness Factor"
	end
	CSDebug:StopProfiling("GET COLUMNS")
	
	--Generate CSV
	
	CSDebug:StartProfiling("MAKE DATA")
	
	local csvTable = {concat(columns, ",")}
	local row = {}
	local map = {}
	
	local cachedProfessionInfo = {}
	local cachedItemStats = {}

	for i = 1, numCraftOutputs do
		local co = craftOutputs[i]
		local item = co.item
		local itemID = item.itemID
		local concentration = co.concentration
		local recipeID = co.recipeID
		
		cachedProfessionInfo[recipeID] = cachedProfessionInfo[recipeID] or getProfessionInfo(recipeID)
		local professionInfo = cachedProfessionInfo[recipeID]
		co.profession = professionInfo.parentProfessionName
		co.expansionName = professionInfo.expansionName
		co.isOldWorldRecipe = co.expansionID <= 8
		
		local itemStats = cachedItemStats[itemID]
		if not itemStats then
			local isGear = getItemInventoryType(itemID) ~= 0
			local bindType = select(14, getItemInfo(item.itemID))
		
		
		
			local isSoulbound = bindType == Enum.ItemBind.OnAcquire or
								bindType == Enum.ItemBind.Quest or
								bindType == Enum.ItemBind.ToWoWAccount or
								bindType == Enum.ItemBind.ToBnetAccount
		
		
		
		
		
			itemStats = {isGear = isGear, isSoulbound = isSoulbound}
			cachedItemStats[itemID] = itemStats
		end
		co.isGear = itemStats.isGear
		co.isSoulbound = itemStats.isSoulbound
		
		--Non-Cache
		local quantity = item.quantity 
		local extraQuantity = item.extraQuantity
		local normalQuantity = quantity - (extraQuantity or 0)
		
		item.normalQuantity = normalQuantity

		local bonusStats = co.bonusStats
		
		if bonusStats["multicraft"] then
			if extraQuantity then
				item.triggeredMulticraft = true
				item.multicraftFactor = extraQuantity / normalQuantity
			else
				item.triggeredMulticraft = false
			end
		end
		
		if bonusStats["resourcefulness"] then
			local typesUsed = 0
			local typesReturned = 0
			local reagents = co.reagents
		
			for j = 1, #reagents do
				local reagent = reagents[j]
				typesUsed = typesUsed + 1
				
				local quantityReturned = reagent.quantityReturned
				if quantityReturned then
					typesReturned = typesReturned + 1
					reagent.triggeredResourcefulness = true
					reagent.resourcefulnessFactor = quantityReturned / reagent.quantity
				else
					reagent.triggeredResourcefulness = false
				end
			end
			co.typesUsed = typesUsed
			co.typesReturned = typesReturned
		end
		
		if bonusStats["ingenuity"] then
			concentration.ingenuityRefund = (concentration.concentrating and concentration.triggeredIngenuity and ceiling(concentration.concentrationSpent / 2)) or nil
		end
		
		
		
		
		map["Date"] = co.date
		map["Game Version"] = co.gameVersion
		map["CraftSim Version"] = co.craftSimVersion
		map["CraftLogger Version"] = co.craftLoggerVersion
		map["Crafter UID"] = co.crafterUID
		map["Work Order"] = co.isWorkOrder
		map["Recraft"] = co.isRecraft
		map["Gear"] = co.isGear
		map["Item Level"] = co.itemLevel
		map["Soulbound"] = co.isSoulbound
		map["Old World Recipe"] = co.isOldWorldRecipe
		map["Expansion"] = co.expansionName
		map["Profession"] = co.profession
		map["Category ID"] = co.categoryID
		map["Category Name"] = co.categoryName
		map["Recipe ID"] = co.recipeID
		map["Recipe Name"] = co.recipeName
		map["Enchanting Target ID"] = co.enchantTargetItemID
		map["Enchanting Target Name"] = co.enchantTargetItemName
		map["Item ID"] = co.item.itemID
		map["Item Name"] = co.item.itemName
		map["Item Quality"] = co.item.quality
		map["Normal Quantity"] = co.item.normalQuantity
		map["Produced Quantity"] = co.item.quantity
		map["Extra Quantity"] = co.item.extraQuantity
		map["Triggered Multicraft"] = co.item.triggeredMulticraft
		map["Multicraft Factor"] = co.item.multicraftFactor
		map["Concentrating"] = co.concentration.concentrating
		map["Concentration Spent"] = co.concentration.concentrationSpent
		map["Concentration Refunded"] = co.concentration.ingenuityRefund
		map["Triggered Ingenuity"] = co.concentration.triggeredIngenuity
		map["Resourcefulness-Eligible Reagent Types Used"] = co.typesUsed
		map["Resourcefulness-Eligible Reagent Types Returned"] = co.typesReturned
		
		for i = 1, #co.reagents do
			local reagent = co.reagents[i]
			local title = "Required Reagent " .. i
			map[title .. " Name"] = reagent.itemName
			map[title .. " Quality"] = reagent.quality
			map[title .. " Provided By Customer"] = reagent.isOrderReagentIn
			map[title .. " Consumed Quantity"] = reagent.quantity
			map[title .. " Returned Quantity"] = reagent.quantityReturned
			map[title .. " Triggered Resourcefulness"] = reagent.triggeredResourcefulness
			map[title .. " Resourcefulness Factor"] = reagent.resourcefulnessFactor	
		end
		
		for i = 1, #co.optionalReagents do
			local reagent = co.optionalReagents[i]
			local title = "Optional Reagent " .. i
			map[title .. " Name"] = reagent.itemName
			map[title .. " Quality"] = reagent.quality
			map[title .. " Provided By Customer"] = reagent.isOrderReagentIn
			map[title .. " Consumed Quantity"] = reagent.quantity
		end
		
		for bonusStatName, bonusStat in pairs(co.bonusStats) do
			map[bonusStatName .. " Value"] = bonusStat.bonusStatValue
			map[bonusStatName .. " Percent"] = bonusStat.ratingPct
			map[bonusStatName .. " Bonus"] = bonusStat.extraValue
		end
		
		for j = 1, numColumns do 
			local value = map[columns[j]]
			row[j] = value ~= nil and str(value) or ""
		end
		
		
		
		
		
		
		
		csvTable[i + 1] = concat(row, ",")
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
	
	for bonusStatName, bonusStat in pairs(craftOutput.bonusStats) do
		map[bonusStatName .. " Value"] = bonusStat.bonusStatValue
		map[bonusStatName .. " Percent"] = bonusStat.ratingPct
		map[bonusStatName .. " Bonus"] = bonusStat.extraValue
	end

	return map
end