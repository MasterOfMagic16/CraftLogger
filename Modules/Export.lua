local CraftLogger = select(2, ...)

local GUTIL = CraftLogger.GUTIL

CraftLogger.Export = {}

function CLExport()
	local craftOutputTable = CraftLogger.Export:GetDBCraftOutputTable()
	local text = CraftLogger.Export:GetCraftOutputTableCSV(craftOutputTable)
	CraftLogger.UTIL:KethoEditBox_Show(text)
end

function CraftLogger.Export:GetDBCraftOutputTable()
	local craftOutputs = GUTIL:Map(CraftLoggerDB, 
		function(co) 
		return CraftLogger.CraftOutput(co)
		end)
	return CraftLogger.CraftOutputTable(craftOutputs)
end

function CraftLogger.Export:GetCraftOutputTableCSV(craftOutputTable)
	local craftOutputTable = craftOutputTable:Copy()
	
	--Prep Data
	for _, craftOutput in pairs(craftOutputTable.craftOutputs) do
		craftOutput:SetOtherStats()
		craftOutput:SetMulticraftStats()
		craftOutput:SetResourcefulnessStats()
		craftOutput:SetIngenuityStats()
	end
	
	--Prep Variable Columns
	local optionalReagentsList = {}
	local reagentsList = {}
	for _, craftOutput in pairs(craftOutputTable.craftOutputs) do
		for _, reagent in pairs(craftOutput.optionalReagents) do
			if not GUTIL:Some(optionalReagentsList, function(r) return r.itemID == reagent.itemID end) then
				table.insert(optionalReagentsList, {
					itemID = reagent.itemID,
					itemName = reagent.itemName,
					quality = reagent.quality,
					})
			end
		end
		
		for _, reagent in pairs(craftOutput.reagents) do
			if not GUTIL:Some(reagentsList, function(r) return r.itemID == reagent.itemID end) then
				table.insert(reagentsList, {
					itemID = reagent.itemID,
					itemName = reagent.itemName,
					quality = reagent.quality
					})
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
	
	--Generate CSV
	local function join(basedata, data) 
		if data ~= nil then
			return basedata .. tostring(data) .. "," 
		else
			return basedata .. ","
		end
	end
	
	local csv = ""
	
	--Headers
	for _, column in ipairs(columns) do
		csv = join(csv, column)
	end
	csv = csv .. "\n"
	
	--Data
	for _, craftOutput in ipairs(craftOutputTable.craftOutputs) do
		local craftOutputMap = CraftLogger.Export:PrepareCraftOutputMap(craftOutput)
		
		local line = ""
		for _, column in ipairs(columns) do
			line = join(line, craftOutputMap[column])
		end
		
		csv = csv .. line .. "\n"
	end
	
	return csv
end

function CraftLogger.Export:PrepareCraftOutputMap(craftOutput)
	craftOutput = craftOutput:Copy()
	
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
