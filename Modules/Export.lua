local CraftLogger = select(2, ...)

local GUTIL = CraftLogger.GUTIL

CraftLogger.Export = {}

local CSDebug
function CraftLogger.Export:Init()
	CSDebug = CraftSimAPI:GetCraftSim().DEBUG
end

function CLExport()
	CSDebug:StartProfiling("OVERALL EXPORT")
	local text = CraftLogger.Export:GetCraftOutputListCSV(CraftLoggerDB)
	CraftLogger.UTIL:KethoEditBox_Show(text)
	CSDebug:StopProfiling("OVERALL EXPORT")
end

function CraftLogger.Export:GetCraftOutputListCSV(craftOutputs)
	--Get Columns
	--Prep Variable Columns
	local maxItems = 0
	local maxReagentTypes = 0
	for _, craftOutput in ipairs(craftOutputs) do
		maxItems = max(maxItems, #craftOutput.items)
		maxReagentTypes = max(maxReagentTypes, #craftOutput.reagents + #craftOutput.specialReagents)
	end
	
	--Set Columns & Order
	local columns = {
		"Date",
		"Game Version",
		"CraftSim Version",
		"CraftLogger Version",
		"Crafter UID",
		"Expansion",
		"Profession",
		"Category Name",
		"Recipe Name",
		"Work Order",
		"Recraft",
		"Salvage",
		"Old World Recipe",
		"Concentrating",
		"Concentration Spent",
		"Triggered Ingenuity",
		"Concentration Refunded",
		"Enchanting Target Name",
		"Resourcefulness-Eligible Reagent Types Used",
		"Resourcefulness-Eligible Reagent Types Returned",
		}
	
	for _, bonusStatName in ipairs({"resourcefulness", "craftingspeed", "multicraft", "ingenuity"}) do
		table.insert(columns, bonusStatName .. " Value")
		table.insert(columns, bonusStatName .. " Percent")
		table.insert(columns, bonusStatName .. " Bonus")
	end
	
	for i = 1, maxItems do
		local title = "Item " .. i 
		table.insert(columns, title .. " Name")
		table.insert(columns, title .. " Quality")
		table.insert(columns, title .. " Produced Quantity")
		table.insert(columns, title .. " Normal Quantity")
		table.insert(columns, title .. " Triggered Multicraft")
		table.insert(columns, title .. " Extra Quantity")
		table.insert(columns, title .. " Multicraft Factor")
		table.insert(columns, title .. " Soulbound")
		table.insert(columns, title .. " Gear")
		table.insert(columns, title .. " Item Level")
	end
	
	for i = 1, maxReagentTypes do
		local title = "Reagent " .. i
		table.insert(columns, title .. " Name")
		table.insert(columns, title .. " Quality")
		table.insert(columns, title .. " Consumed Quantity")
		table.insert(columns, title .. " Triggered Resourcefulness")
		table.insert(columns, title .. " Returned Quantity")
		table.insert(columns, title .. " Resourcefulness Factor")
		table.insert(columns, title .. " Provided By Customer")
	end
	
	--Generate CSV
	local csvTable = {table.concat(columns, ",")}
	local row = {}
	for _, craftOutput in ipairs(craftOutputs) do
		local craftOutputMap = CraftLogger.Export:PrepareCraftOutputMap(craftOutput)
		
		for j = 1, #columns do 
			local value = craftOutputMap[columns[j]]
			row[j] = value ~= nil and tostring(value) or ""
		end
		
		table.insert(csvTable, table.concat(row, ","))
	end

	local csv = table.concat(csvTable, "\n")

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
		["Salvage"] = craftOutput.isSalvageRecipe,
		["Old World Recipe"] = craftOutput.isOldWorldRecipe,
		["Expansion"] = craftOutput.expansionName,
		["Profession"] = craftOutput.profession,
		["Category ID"] = craftOutput.categoryID,
		["Category Name"] = craftOutput.categoryName,
		["Recipe ID"] = craftOutput.recipeID,
		["Recipe Name"] = craftOutput.recipeName,
		["Enchanting Target ID"] = craftOutput.enchantTargetItemID,
		["Enchanting Target Name"] = craftOutput.enchantTargetItemName,
		["Concentrating"] = craftOutput.concentration.concentrating,
		["Concentration Spent"] = craftOutput.concentration.concentrationSpent,
		["Concentration Refunded"] = craftOutput.concentration.ingenuityRefund,
		["Triggered Ingenuity"] = craftOutput.concentration.triggeredIngenuity,
		["Resourcefulness-Eligible Reagent Types Used"] = craftOutput.typesUsed,
		["Resourcefulness-Eligible Reagent Types Returned"] = craftOutput.typesReturned,
		}
		
	for i = 1, #craftOutput.items do
		local item = craftOutput.items[i]
		local title = "Item " .. i 
		map[title .. " Name"] = item.itemName
		map[title .. " Quality"] = item.quality
		map[title .. " Normal Quantity"] = item.normalQuantity
		map[title .. " Produced Quantity"] = item.quantity 
		map[title .. " Extra Quantity"] = item.extraQuantity
		map[title .. " Triggered Multicraft"] = item.triggeredMulticraft 
		map[title .. " Multicraft Factor"] = item.multicraftFactor 
		map[title .. " Gear"] = item.isGear 
		map[title .. " Item Level"] = item.itemLevel 
		map[title .. " Soulbound"] = item.isSoulbound
	end
	
	local allReagents = GUTIL:Concat({craftOutput.reagents, craftOutput.specialReagents})
		
	for i = 1, #allReagents do
		local reagent = allReagents[i]
		local title = "Reagent " .. i
		map[title .. " Name"] = reagent.itemName
		map[title .. " Quality"] = reagent.quality
		map[title .. " Provided By Customer"] = reagent.isOrderReagentIn
		map[title .. " Consumed Quantity"] = reagent.quantity
		map[title .. " Returned Quantity"] = reagent.quantityReturned
		map[title .. " Triggered Resourcefulness"] = reagent.triggeredResourcefulness
		map[title .. " Resourcefulness Factor"] = reagent.resourcefulnessFactor	
	end
	
	for bonusStatName, bonusStat in pairs(craftOutput.bonusStats) do
		map[bonusStatName .. " Value"] = bonusStat.bonusStatValue
		map[bonusStatName .. " Percent"] = bonusStat.ratingPct
		map[bonusStatName .. " Bonus"] = bonusStat.extraValue
	end

	return map
end