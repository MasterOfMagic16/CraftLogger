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
	local insert = table.insert
	local concat = table.concat
		
	--Prep Variable Columns
	CSDebug:StartProfiling("GET COLUMNS")
	local optionalReagentsList, reagentsList = {}, {}
	local optionalReagentsSeen, reagentsSeen = {}, {}
	
	for _, craftOutput in ipairs(craftOutputs) do
		for _, reagent in pairs(craftOutput.optionalReagents) do
			local key = reagent.itemID
			if not optionalReagentsSeen[key] then 
				optionalReagentsSeen[key] = true
				optionalReagentsList[#optionalReagentsList + 1] = reagent
			end
		end
		
		for _, reagent in pairs(craftOutput.reagents) do
			local key = reagent.itemID
			if not reagentsSeen[key] then 
				reagentsSeen[key] = true
				reagentsList[#reagentsList + 1] = reagent
			end
		end
	end
	
	local function compFuncReagent(reagent1,reagent2) return reagent1.itemID < reagent2.itemID end
	
	table.sort(optionalReagentsList, compFuncReagent)
	table.sort(reagentsList, compFuncReagent)
	local bonusStatNames = {"resourcefulness", "craftingspeed", "multicraft", "ingenuity"}
	
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
	
	for _, bonusStatName in pairs(bonusStatNames) do
		insert(columns, bonusStatName .. " Value")
		insert(columns, bonusStatName .. " Percent")
		insert(columns, bonusStatName .. " Bonus")
	end
	
	for _, reagent in ipairs(optionalReagentsList) do
		local qualityTitle = (reagent.quality == nil and "") or ("*" .. reagent.quality)
		local title = reagent.itemName .. qualityTitle
		insert(columns, title .. " Provided By Customer")
		insert(columns, title .. " Consumed Quantity")
	end
	
	for _, reagent in ipairs(reagentsList) do
		local qualityTitle = (reagent.quality == nil and "") or ("*" .. reagent.quality)
		local title = reagent.itemName .. qualityTitle
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
	local function addLine(tbl)
		csvTable[#csvTable + 1] = concat(tbl, ",")
	end
	
	local numColumns = #columns
	local numCraftOutputs = #craftOutputs
	
	local columnKeys = {}
	for i, column in ipairs(columns) do
		columnKeys[i] = column
	end
	
	--Data
	--Headers
	addLine(columnKeys)
	
	local extractors = CraftLogger.Export:GetExtractors(columns)
	local cachedProfessionStats = {}
	local cachedItemStats = {}
	for i = 1, numCraftOutputs do
		local co = craftOutputs[i]
		
		local item = co.item
		local concentration = co.concentration
		
		local bonusMap = {}
        local bonusStats = co.bonusStats
        for j = 1, #bonusStats do
            local stat = bonusStats[j]
            bonusMap[stat.bonusStatName] = stat
        end
		co.bonusMap = bonusMap
		
		local reagentMap = {}
		local reagents = co.reagents
        for j = 1, #reagents do
            local reagent = reagents[j]
            local qualityTitle = (reagent.quality == nil) and "" or ("*" .. reagent.quality)
            reagentMap[reagent.itemName .. qualityTitle] = reagent
        end
		co.reagentMap = reagentMap
		
		local optionalReagentMap = {}
		local optionalReagents = co.optionalReagents
        for j = 1, #optionalReagents do
            local reagent = optionalReagents[j]
            local qualityTitle = (reagent.quality == nil) and "" or ("*" .. reagent.quality)
            optionalReagentMap[reagent.itemName .. qualityTitle] = reagent
        end
		co.optionalReagentMap = optionalReagentMap
		
		--Prep
		if not cachedProfessionStats[co.recipeID] then
			cachedProfessionStats[co.recipeID] = C_TradeSkillUI.GetProfessionInfoByRecipeID(co.recipeID)
		end
		local professionInfo = cachedProfessionStats[co.recipeID]
		co.profession = professionInfo.parentProfessionName
		co.expansionName = professionInfo.expansionName
		
		co.isOldWorldRecipe = co.expansionID <= 8
		
		co.isGear = C_Item.GetItemInventoryTypeByID(item.itemID) ~= 0
		local bindType = select(14, C_Item.GetItemInfo(item.itemID))
		co.isSoulbound = 	bindType == Enum.ItemBind.OnAcquire or
							bindType == Enum.ItemBind.Quest or
							bindType == Enum.ItemBind.ToWoWAccount or
							bindType == Enum.ItemBind.ToBnetAccount
		
		
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
			for _, reagent in pairs(co.reagents) do
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
		
		
		
		
		
		
		local row = {}
		for j = 1, #extractors do
			local value = extractors[j](co, co.bonusMap, co.reagentMap, co.optionalReagentMap)
			row[j] = value == nil and "" or tostring(value)
		end
		addLine(row)
	end
	
	CSDebug:StopProfiling("MAKE DATA")
	
	
	
	
	
	CSDebug:StartProfiling("TABLE COMBINE")
	local csv = concat(csvTable, "\n")
	CSDebug:StopProfiling("TABLE COMBINE")
	
	return csv
end

--[[
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
	
	for _, bonusStat in pairs(craftOutput.bonusStats) do
		map[bonusStat.bonusStatName .. " Value"] = bonusStat.bonusStatValue
		map[bonusStat.bonusStatName .. " Percent"] = bonusStat.ratingPct
		map[bonusStat.bonusStatName .. " Bonus"] = bonusStat.extraValue
	end
	
	local allReagents = GUTIL:Concat({
		craftOutput.reagents,
		craftOutput.optionalReagents,
		})

	for _, reagent in pairs(allReagents) do
		if reagent.quantity > 0 then
			local qualityTitle = (reagent.quality == nil and "") or ("*" .. reagent.quality)
			local title = reagent.itemName .. qualityTitle
			map[title .. " ID"] = reagent.itemID
			map[title .. " Provided By Customer"] = reagent.isOrderReagentIn
			map[title .. " Consumed Quantity"] = reagent.quantity
			map[title .. " Returned Quantity"] = reagent.quantityReturned
			map[title .. " Triggered Resourcefulness"] = reagent.triggeredResourcefulness
			map[title .. " Resourcefulness Factor"] = reagent.resourcefulnessFactor	
		end
	end
	
	return map
end
]]

function CraftLogger.Export:GetExtractors(columns)
	local extractors = {}
	
	local function createBonusExtractor(colName, suffix, field)
		local bonusKey = colName:sub(1, -#suffix - 1)
		return function(co, bonusMap, reagentMap, optionalReagentMap)
			local stat = bonusMap[bonusKey]
			return stat and stat[field]
		end
	end
	
	local function createReagentExtractor(colName, suffix, field)
		local reagentKey = colName:sub(1, -#suffix - 1)
		return function(co, bonusMap, reagentMap, optionalReagentMap)
			local reagent = reagentMap[reagentKey] or optionalReagentMap[reagentKey]
			return reagent and reagent[field]
		end
	end
	
	for _, colName in ipairs(columns) do
		if colName == "Date" then
			table.insert(extractors, function(co) return co.date end)
		elseif colName == "Game Version" then
			table.insert(extractors, function(co) return co.gameVersion end)
		elseif colName == "CraftSim Version" then
			table.insert(extractors, function(co) return co.craftSimVersion end)
		elseif colName == "CraftLogger Version" then
			table.insert(extractors, function(co) return co.craftLoggerVersion end)
		elseif colName == "Crafter UID" then
			table.insert(extractors, function(co) return co.crafterUID end)
		elseif colName == "Work Order" then
			table.insert(extractors, function(co) return co.isWorkOrder end)
		elseif colName == "Recraft" then
			table.insert(extractors, function(co) return co.isRecraft end)
		elseif colName == "Gear" then
			table.insert(extractors, function(co) return co.isGear end)
		elseif colName == "Item Level" then
			table.insert(extractors, function(co) return co.itemLevel end)
		elseif colName == "Soulbound" then
			table.insert(extractors, function(co) return co.isSoulbound end)
		elseif colName == "Old World Recipe" then
			table.insert(extractors, function(co) return co.isOldWorldRecipe end)
		elseif colName == "Expansion" then
			table.insert(extractors, function(co) return co.expansionName end)
		elseif colName == "Profession" then
			table.insert(extractors, function(co) return co.profession end)
		elseif colName == "Category ID" then
			table.insert(extractors, function(co) return co.categoryID end)
		elseif colName == "Category Name" then
			table.insert(extractors, function(co) return co.categoryName end)
		elseif colName == "Recipe ID" then
			table.insert(extractors, function(co) return co.recipeID end)
		elseif colName == "Recipe Name" then
			table.insert(extractors, function(co) return co.recipeName end)
		elseif colName == "Enchanting Target ID" then
			table.insert(extractors, function(co) return co.enchantTargetItemID end)
		elseif colName == "Enchanting Target Name" then
			table.insert(extractors, function(co) return co.enchantTargetItemName end)
		elseif colName == "Item ID" then
			table.insert(extractors, function(co) return co.item.itemID end)
		elseif colName == "Item Name" then
			table.insert(extractors, function(co) return co.item.itemName end)
		elseif colName == "Item Quality" then
			table.insert(extractors, function(co) return co.item.quality end)
		elseif colName == "Normal Quantity" then
			table.insert(extractors, function(co) return co.item.normalQuantity end)
		elseif colName == "Produced Quantity" then
			table.insert(extractors, function(co) return co.item.quantity end)
		elseif colName == "Extra Quantity" then
			table.insert(extractors, function(co) return co.item.extraQuantity end)
		elseif colName == "Triggered Multicraft" then
			table.insert(extractors, function(co) return co.item.triggeredMulticraft end)
		elseif colName == "Multicraft Factor" then
			table.insert(extractors, function(co) return co.item.multicraftFactor end)
		elseif colName == "Concentrating" then
			table.insert(extractors, function(co) return co.concentration.concentrating end)
		elseif colName == "Concentration Spent" then
			table.insert(extractors, function(co) return co.concentration.concentrationSpent end)
		elseif colName == "Concentration Refunded" then
			table.insert(extractors, function(co) return co.concentration.ingenuityRefund end)
		elseif colName == "Triggered Ingenuity" then
			table.insert(extractors, function(co) return co.concentration.triggeredIngenuity end)
		elseif colName == "Resourcefulness-Eligible Reagent Types Used" then
			table.insert(extractors, function(co) return co.typesUsed end)
		elseif colName == "Resourcefulness-Eligible Reagent Types Returned" then
			table.insert(extractors, function(co) return co.typesReturned end)
		
		elseif colName:find(" Value") then
			table.insert(extractors, createBonusExtractor(colName, " Value", "bonusStatValue"))
		elseif colName:find(" Percent") then
			table.insert(extractors, createBonusExtractor(colName, " Percent", "ratingPct"))
		elseif colName:find(" Bonus") then
			table.insert(extractors, createBonusExtractor(colName, " Bonus", "extraValue"))
	
			
		elseif colName:find(" ID") then
			table.insert(extractors, createReagentExtractor(colName, " ID", "itemID"))
		elseif colName:find(" Provided By Customer") then
			table.insert(extractors, createReagentExtractor(colName, " Provided By Customer", "isOrderReagentIn"))
		elseif colName:find(" Consumed Quantity") then
			table.insert(extractors, createReagentExtractor(colName, " Consumed Quantity", "quantity"))
		elseif colName:find(" Returned Quantity") then
			table.insert(extractors, createReagentExtractor(colName, " Returned Quantity", "quantityReturned"))
		elseif colName:find(" Triggered Resourcefulness") then
			table.insert(extractors, createReagentExtractor(colName, " Triggered Resourcefulness", "triggeredResourcefulness"))
		elseif colName:find(" Resourcefulness Factor") then
			table.insert(extractors, createReagentExtractor(colName, " Resourcefulness Factor", "resourcefulnessFactor"))
		
		else
			table.insert(extractors, function() return nil end)
		end

	end
	
	return extractors
end