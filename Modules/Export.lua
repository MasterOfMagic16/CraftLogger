local CraftLogger = select(2, ...)

local GUTIL = CraftLogger.GUTIL

CraftLogger.Export = {}

local CSDebug
function CraftLogger.Export:Init()
	CSDebug = CraftSimAPI:GetCraftSim().DEBUG
end

function CLExport()
	CSDebug:StartProfiling("OVERALL EXPORT")
	local craftOutputTable = CraftLogger.Export:GetDBCraftOutputTable()
	CSDebug:StartProfiling("GET EXPORT TEXT")
	local text = CraftLogger.Export:GetCraftOutputTableCSV(craftOutputTable)
	CSDebug:StopProfiling("GET EXPORT TEXT")
	CraftLogger.UTIL:KethoEditBox_Show(text)
	CSDebug:StopProfiling("OVERALL EXPORT")
end

function CraftLogger.Export:GetDBCraftOutputTable()
	local craftOutputs = GUTIL:Map(CraftLoggerDB, 
		function(co) 
		return CraftLogger.CraftOutput(co)
		end)
	return CraftLogger.CraftOutputTable(craftOutputs)
end

function CraftLogger.Export:GetCraftOutputTableCSV(craftOutputTable)
	CSDebug:StartProfiling("COPY")
	local craftOutputTable = craftOutputTable:Copy()
	CSDebug:StopProfiling("COPY")
	--Prep Data
	CSDebug:StartProfiling("PREP DATA")
	for _, craftOutput in pairs(craftOutputTable.craftOutputs) do
		craftOutput:SetAllStats()
	end
	CSDebug:StopProfiling("PREP DATA")
	
	--Prep Variable Columns
	CSDebug:StartProfiling("GET COLUMNS")
	local optionalReagentsList, reagentsList = {}, {}
	local optionalReagentsSeen, reagentsSeen = {}, {}
	
	for _, craftOutput in pairs(craftOutputTable.craftOutputs) do
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
	
	local extractors = CraftLogger.Export:GetExtractors(columns)
	CSDebug:StopProfiling("GET COLUMNS")
	--Generate CSV
	
	CSDebug:StartProfiling("MAKE DATA")
	local csvTable = {""}
	local function addLine(tbl)
		csvTable[#csvTable + 1] = table.concat(tbl, ",")
	end
	
	local numColumns = #columns
	local craftOutputs = craftOutputTable.craftOutputs
	local numCraftOutputs = #craftOutputs
	
	local columnKeys = {}
	for i, column in ipairs(columns) do
		columnKeys[i] = column
	end
	
	--Data
	--Headers
	addLine(columnKeys)
	
	
	for i = 1, numCraftOutputs do
		print("Check")
		local co = craftOutputs[i]
		local row = {}
		for j = 1, #extractors do
			local value = extractors[j](co)
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
	
	local function insertBonusStatExtractor(str, colName, field)
		local bonusStatKey = colName:sub(1, -#(str)-1)
		table.insert(extractors, function(co)
				local value
				for _, bonusStat in ipairs(co.bonusStats) do
					if bonusStat.bonusStatName == bonusStatKey then
						value = bonusStat[field]
						break
					end
				end
				return value
			end)
	end
	
	local function insertReagentExtractor(str, colName, field)
		local reagentKey = colName:sub(1, -#(str)-1)
		table.insert(extractors, function(co)
				local allReagents = GUTIL:Concat({
				co.reagents,
				co.optionalReagents,
				})
				
				local value
				for _, reagent in ipairs(allReagents) do
					local qualityTitle = (reagent.quality == nil and "") or ("*" .. reagent.quality)
					local title = reagent.itemName .. qualityTitle
					if title == reagentKey then
						value = reagent[field]
						break
					end
				end
				return value
			end)
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
			insertBonusStatExtractor(" Value", colName, "bonusStatValue")
		elseif colName:find(" Percent") then
			insertBonusStatExtractor(" Percent", colName, "ratingPct")
		elseif colName:find(" Bonus") then
			insertBonusStatExtractor(" Bonus", colName, "extraValue")
			
		elseif colName:find(" ID") then
			insertReagentExtractor(" ID", colName, "itemID")
		elseif colName:find(" Provided By Customer") then
			insertReagentExtractor(" Provided By Customer", colName, "isOrderReagentIn")
		elseif colName:find(" Consumed Quantity") then
			insertReagentExtractor(" Consumed Quantity", colName, "quantity")
		elseif colName:find(" Returned Quantity") then
			insertReagentExtractor(" Returned Quantity", colName, "returnedQuantity")
		elseif colName:find(" Triggered Resourcefulness") then
			insertReagentExtractor(" Triggered Resourcefulness", colName, "triggeredResourcefulness")
		elseif colName:find(" Resourcefulness Factor") then
			insertReagentExtractor(" Resourcefulness Factor", colName, "resourcefulnessFactor")
			
		else
			table.insert(extractors, function() return "No Column Function" end)
		end
	end
	
	return extractors
end


function CraftLogger.Export:PrepareCraftOutputMap(craftOutput)
	--Do Not Manipulate Craft Output! No Nested Tables!
	
	--Set Data to Column Names
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

