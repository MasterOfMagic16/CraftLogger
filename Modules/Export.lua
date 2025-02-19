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
	local text = CraftLogger.Export:GetCraftOutputTableCSV(craftOutputs)
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
	--Get Columns
	
	--Prep Variable Columns
	local maxReagentTypes = 0
	local maxOptionalReagentTypes = 0
	for i = 1, #craftOutputs do
		local co = craftOutputs[i]
		
		maxOptionalReagentTypes = max(maxOptionalReagentTypes, #co.optionalReagents)
		maxReagentTypes = max(maxReagentTypes, #co.reagents)
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
	
	for _, bonusStatName in ipairs({"resourcefulness", "craftingspeed", "multicraft", "ingenuity"}) do
		table.insert(columns, bonusStatName .. " Value")
		table.insert(columns, bonusStatName .. " Percent")
		table.insert(columns, bonusStatName .. " Bonus")
	end
	
	for i = 1, maxOptionalReagentTypes do
		local title = "Optional Reagent " .. i
		table.insert(columns, title .. " Name")
		table.insert(columns, title .. " Quality")
		table.insert(columns, title .. " Provided By Customer")
		table.insert(columns, title .. " Consumed Quantity")
	end
	
	for i = 1, maxReagentTypes do
		local title = "Required Reagent " .. i
		table.insert(columns, title .. " Name")
		table.insert(columns, title .. " Quality")
		table.insert(columns, title .. " Provided By Customer")
		table.insert(columns, title .. " Consumed Quantity")
		table.insert(columns, title .. " Returned Quantity")
		table.insert(columns, title .. " Triggered Resourcefulness")
		table.insert(columns, title .. " Resourcefulness Factor")
	end
	
	--Generate CSV
	
	local csvTable = {table.concat(columns, ",")}
	local row = {}
	
	local cachedProfessionInfo = {}
	local cachedItemStats = {}
	for i = 1, #craftOutputs do
		local co = craftOutputs[i]

		cachedProfessionInfo[co.recipeID] = cachedProfessionInfo[co.recipeID] or C_TradeSkillUI.GetProfessionInfoByRecipeID(co.recipeID)
		local professionInfo = cachedProfessionInfo[co.recipeID]
		co.profession = professionInfo.parentProfessionName
		co.expansionName = professionInfo.expansionName
		co.isOldWorldRecipe = co.expansionID <= 8
		
		local itemStats = cachedItemStats[co.item.itemID]
		if not itemStats then
			local isGear = C_Item.GetItemInventoryTypeByID(co.item.itemID) ~= 0
			local bindType = select(14, C_Item.GetItemInfo(co.item.itemID))
			local isSoulbound = bindType == Enum.ItemBind.OnAcquire or
								bindType == Enum.ItemBind.Quest or
								bindType == Enum.ItemBind.ToWoWAccount or
								bindType == Enum.ItemBind.ToBnetAccount
			itemStats = {isGear = isGear, isSoulbound = isSoulbound}
			cachedItemStats[co.item.itemID] = itemStats
		end
		co.isGear = itemStats.isGear
		co.isSoulbound = itemStats.isSoulbound
		
		--Non-Cache
		co.item.normalQuantity = co.item.quantity - (co.item.extraQuantity or 0)
		
		local bonusStats = co.bonusStats

		if bonusStats["multicraft"] then
			if co.item.extraQuantity then
				co.item.triggeredMulticraft = true
				co.item.multicraftFactor = co.item.extraQuantity / co.item.normalQuantity
			else
				co.item.triggeredMulticraft = false
				co.item.multicraftFactor = nil
			end
		end

		if bonusStats["resourcefulness"] then
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

		if bonusStats["ingenuity"] then
			if co.concentration.concentrating and co.concentration.triggeredIngenuity then
				co.concentration.ingenuityRefund = ceil(co.concentration.concentrationSpent / 2)
			else
				co.concentration.ingenuityRefund = nil
			end
		end
		
		local map = CraftLogger.Export:PrepareCraftOutputMap(co)
		
		for j = 1, #columns do 
			local value = map[columns[j]]
			row[j] = value ~= nil and tostring(value) or ""
		end
		
		csvTable[i + 1] = table.concat(row, ",")
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