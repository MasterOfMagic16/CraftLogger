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
	--Prep Data
	CSDebug:StartProfiling("PREP DATA")
	for _, craftOutput in pairs(craftOutputs) do
		local professionInfo = C_TradeSkillUI.GetProfessionInfoByRecipeID(craftOutput.recipeID)
		craftOutput.profession = professionInfo.parentProfessionName
		craftOutput.expansionName = professionInfo.expansionName
		
		craftOutput.isOldWorldRecipe = craftOutput.expansionID <= 8
		
		craftOutput.isGear = C_Item.GetItemInventoryTypeByID(craftOutput.item.itemID) ~= 0
		local bindType = select(14, C_Item.GetItemInfo(craftOutput.item.itemID))
		craftOutput.isSoulbound = 	bindType == Enum.ItemBind.OnAcquire or
							bindType == Enum.ItemBind.Quest or
							bindType == Enum.ItemBind.ToWoWAccount or
							bindType == Enum.ItemBind.ToBnetAccount
		
		--Normal Quantity
		craftOutput.item.normalQuantity = craftOutput.item.quantity - (craftOutput.item.extraQuantity or 0)
		
		if GUTIL:Find(craftOutput.bonusStats, function(bs) return bs.bonusStatName == "multicraft" end) then
			--Triggered Multicraft
			--Multicraft Factor
			if craftOutput.item.extraQuantity then
				craftOutput.item.triggeredMulticraft = true
				craftOutput.item.multicraftFactor = craftOutput.item.extraQuantity / craftOutput.item.normalQuantity
			else
				craftOutput.item.triggeredMulticraft = false
				craftOutput.item.multicraftFactor = nil
			end
		end
		
		if GUTIL:Find(craftOutput.bonusStats, function(bs) return bs.bonusStatName == "resourcefulness" end) then
			local typesUsed = 0
			local typesReturned = 0
			for _, reagent in pairs(craftOutput.reagents) do
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
			craftOutput.typesUsed = typesUsed
			craftOutput.typesReturned = typesReturned
		end
		
		if GUTIL:Find(craftOutput.bonusStats, function(bs) return bs.bonusStatName == "ingenuity" end) then
			if craftOutput.concentration.concentrating and craftOutput.concentration.triggeredIngenuity then
				craftOutput.concentration.ingenuityRefund = math.ceil(craftOutput.concentration.concentrationSpent / 2)
			else
				craftOutput.concentration.ingenuityRefund = nil
			end
		end
	end
	CSDebug:StopProfiling("PREP DATA")
	
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
		table.insert(columns, bonusStatName .. " Value")
		table.insert(columns, bonusStatName .. " Percent")
		table.insert(columns, bonusStatName .. " Bonus")
	end
	
	for _, reagent in ipairs(optionalReagentsList) do
		local qualityTitle = (reagent.quality == nil and "") or ("*" .. reagent.quality)
		local title = reagent.itemName .. qualityTitle
		table.insert(columns, title .. " Provided By Customer")
		table.insert(columns, title .. " Consumed Quantity")
	end
	
	for _, reagent in ipairs(reagentsList) do
		local qualityTitle = (reagent.quality == nil and "") or ("*" .. reagent.quality)
		local title = reagent.itemName .. qualityTitle
		table.insert(columns, title .. " Provided By Customer")
		table.insert(columns, title .. " Consumed Quantity")
		table.insert(columns, title .. " Returned Quantity")
		table.insert(columns, title .. " Triggered Resourcefulness")
		table.insert(columns, title .. " Resourcefulness Factor")
	end
	CSDebug:StopProfiling("GET COLUMNS")
	--Generate CSV
	
	CSDebug:StartProfiling("MAKE DATA")
	local csvTable = {""}
	local function addLine(tbl)
		csvTable[#csvTable + 1] = table.concat(tbl, ",")
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
	for i = 1, numCraftOutputs do
		local co = craftOutputs[i]
		
		local bonusMap = {}
        local bonusStats = co.bonusStats
        for j = 1, #bonusStats do
            local stat = bonusStats[j]
            bonusMap[stat.bonusStatName] = stat
        end
		
		local reagentMap = {}
		local reagents = co.reagents
        for j = 1, #reagents do
            local reagent = reagents[j]
            local qualityTitle = (reagent.quality == nil) and "" or ("*" .. reagent.quality)
            reagentMap[reagent.itemName .. qualityTitle] = reagent
        end
		
		local optionalReagentMap = {}
		local optReagents = co.optionalReagents
        for j = 1, #optReagents do
            local reagent = optReagents[j]
            local qualityTitle = (reagent.quality == nil) and "" or ("*" .. reagent.quality)
            optionalReagentMap[reagent.itemName .. qualityTitle] = reagent
        end
		
		local row = {}
		for j = 1, #extractors do
			local value = extractors[j](co, bonusMap, reagentMap, optionalReagentMap)
			row[j] = value == nil and "" or tostring(value)
		end
		addLine(row)
	end
	
	CSDebug:StopProfiling("MAKE DATA")
	
	CSDebug:StartProfiling("TABLE COMBINE")
	local csv = table.concat(csvTable, "\n")
	CSDebug:StopProfiling("TABLE COMBINE")
	
	return csv
end

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

