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
	CSDebug:StartProfiling("GET EXPORT TEXT")
	local text = CraftLogger.Export:GetCraftOutputTableCSV(craftOutputs)
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
	
	local insert = function(tbl, value) tbl[#tbl + 1] = value return tbl end
	local concat = table.concat
	local numCraftOutputs = #craftOutputs
	
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
	
	
	
	
	CSDebug:StartProfiling("MAKE DATA")
	
	local csvTable = {}
	
	local function addRow(tbl)
		insert(csvTable, concat(tbl, ","))
	end
	
	local numColumns = #columns
	
	--Headers
	addRow(columns)

	local cachedProfessionInfo = {}
	local cachedItemStats = {}
	
	
	
	local prepTime = 0
	local pullTime = 0
	
	
	for i = 1, numCraftOutputs do
		CSDebug:StartProfiling("Prep Data")
		local co = craftOutputs[i]
		local item = co.item
		local concentration = co.concentration
		
		--Build Maps For Variable Columns
		local function compFuncID(item1, item2) return item1.itemID < item2.itemID end

		--[[
		local items = co.items
		table.sort(items, compFuncID)
		local itemMap = {}
		for j = 1, #items do
			optionalReagentMap["Item " .. j] = items[j]
		end
		co.itemMap = itemMap
		]]
		
		local reagents = co.reagents
		table.sort(reagents, compFuncID)
		local reagentMap = {}
		for j = 1, #reagents do
			reagentMap["Required Reagent " .. j] = reagents[j]
		end
		co.reagentMap = reagentMap
		
		local optionalReagents = co.optionalReagents
		table.sort(optionalReagents, compFuncID)
		local optionalReagentMap = {}
		for j = 1, #optionalReagents do
			optionalReagentMap["Optional Reagent " .. j] = optionalReagents[j]
		end
		co.optionalReagentMap = optionalReagentMap
		
		local bonusStats = co.bonusStats
		local bonusMap = {}
        for j = 1, #bonusStats do
            bonusMap[bonusStats[j].bonusStatName] = bonusStats[j]
        end
		co.bonusMap = bonusMap

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
		
		if co.bonusMap["multicraft"] then
			if item.extraQuantity then
				item.triggeredMulticraft = true
				item.multicraftFactor = item.extraQuantity / item.normalQuantity
			else
				item.triggeredMulticraft = false
				item.multicraftFactor = nil
			end
		end
		
		if co.bonusMap["resourcefulness"] then
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
		
		if co.bonusMap["ingenuity"] then
			if concentration.concentrating and concentration.triggeredIngenuity then
				concentration.ingenuityRefund = math.ceil(concentration.concentrationSpent / 2)
			else
				concentration.ingenuityRefund = nil
			end
		end

		--Get Overall Map
		local craftOutputMap = CraftLogger.Export:PrepareCraftOutputMap(co)
		prepTime = prepTime + CSDebug:StopProfiling("Prep Data")

		CSDebug:StartProfiling("Pull Data")
		--Build Data 
		local row = {}
		for j = 1, numColumns do 
			local value = craftOutputMap[columns[j]]
			row[j] = value == nil and "" or tostring(value)
		end
		pullTime = pullTime + CSDebug:StopProfiling("Pull Data")
		
		addRow(row)
	end
	CSDebug:StopProfiling("MAKE DATA")

	print(prepTime)
	print(pullTime)
	
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

	local bonusMap = craftOutput.bonusMap
	for title, bonusStat in pairs(bonusMap) do
		map[title .. " Value"] = bonusStat.bonusStatValue
		map[title .. " Percent"] = bonusStat.ratingPct
		map[title .. " Bonus"] = bonusStat.extraValue
	end

	local optionalReagentMap = craftOutput.optionalReagentMap
	for title, reagent in pairs(optionalReagentMap) do
		map[title .. " Name"] = reagent.itemName
		map[title .. " Quality"] = reagent.quality
		map[title .. " Provided By Customer"] = reagent.isOrderReagentIn
		map[title .. " Consumed Quantity"] = reagent.quantity
	end

	local reagentMap = craftOutput.reagentMap
	for title, reagent in pairs(reagentMap) do
		map[title .. " Name"] = reagent.itemName
		map[title .. " Quality"] = reagent.quality
		map[title .. " Provided By Customer"] = reagent.isOrderReagentIn
		map[title .. " Consumed Quantity"] = reagent.quantity
		map[title .. " Returned Quantity"] = reagent.quantityReturned
		map[title .. " Triggered Resourcefulness"] = reagent.triggeredResourcefulness
		map[title .. " Resourcefulness Factor"] = reagent.resourcefulnessFactor	
	end
	
	return map
end