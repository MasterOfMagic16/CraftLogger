local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

CraftLogger.CraftOutput = CraftLogger.CraftLoggerObject:extend()

local print
function CraftLogger.CraftOutput:Init()
	print = CraftSimAPI:GetCraftSim().DEBUG:RegisterDebugID("CraftLogger.CraftOutput")
	print("CraftOutput Loaded")
end

--Creates Linked To Tables
function CraftLogger.CraftOutput:new(craftOutputData)
	craftOutputData = craftOutputData or {}
	setmetatable(craftOutputData, self)
	self.__index = self
	return craftOutputData
end

--Create new data for upload to CraftLoggerDB
function CraftLogger.CraftOutput:Generate(recipeData, craftingItemResultData)
	--MetaData
	self.date = date("%m/%d/%y %H:%M:%S")
	self.gameVersion = select(1, GetBuildInfo())
	self.craftSimVersion = C_AddOns.GetAddOnMetadata("CraftSim", "Version")
	self.craftLoggerVersion = C_AddOns.GetAddOnMetadata("CraftLogger", "Version")
	self.crafterUID = recipeData:GetCrafterUID()
	
	--Recipe Data 
	self.expansionID = recipeData.expansionID
	local retOK, err = pcall(function() assert(recipeData.categoryID and recipeData.categoryID ~= 0, "CraftLogger: Categories Not Loaded. Please Open Profession Window.") end)
	if not retOK then
		systemPrint(err)
		return
	end
	self.categoryID = recipeData.categoryID
	self.categoryName = C_TradeSkillUI.GetCategoryInfo(self.categoryID).name
	self.recipeID = recipeData.recipeID
	self.recipeName = recipeData.recipeName
	self.isWorkOrder = recipeData:IsWorkOrder()
	self.isRecraft = recipeData.isRecraft
	self.enchantTargetItemID = recipeData.enchantTargetItemID
	if self.enchantTargetItemID then 
		self.enchantTargetItemName = C_Item.GetItemNameByID(recipeData.enchantTargetItemID)
	end
	
	--Item Data
	self.items = 
		{{itemName = C_Item.GetItemNameByID(craftingItemResultData.itemID),
		itemID = craftingItemResultData.itemID,
		quality = craftingItemResultData.craftingQuality,
		quantity = craftingItemResultData.quantity,
		extraQuantity = (craftingItemResultData.multicraft ~= 0 and craftingItemResultData.multicraft) or nil,
		}}
	if C_Item.GetItemInventoryTypeByID(craftingItemResultData.itemID) ~= 0 then
		self.items[1].itemLevel = select(4, C_Item.GetItemInfo(craftingItemResultData.hyperlink))
	end
	
	--Concentration Data
	self.concentration = {}
	if recipeData.supportsQualities then
		local concentrationSpent = craftingItemResultData.concentrationSpent
		if concentrationSpent > 0 then
			self.concentration.concentrating = true
			self.concentration.concentrationSpent = concentrationSpent
			if craftingItemResultData.hasIngenuityProc then
				self.concentration.triggeredIngenuity = true
			else
				self.concentration.triggeredIngenuity = false
			end
		else
			self.concentration.concentrating = false
		end
	end
		
	--Reagent Data
	craftingItemResultData.resourcesReturned = craftingItemResultData.resourcesReturned or {}
	
	self.reagents = {}
	for _, reagent in pairs(recipeData.reagentData.requiredReagents) do
		for _, reagentItem in pairs(reagent.items) do
			local itemID = reagentItem.item:GetItemID()
			
			if reagentItem:IsOrderReagentIn(recipeData) then
				local orderReagent = GUTIL:Find(recipeData.orderData.reagents, function(r) return r.reagent.itemID == itemID end)
				if not orderReagent then
					systemPrint("CraftLogger: Error, Order Reagent Not Found.")
					error()
				end
				if reagentItem.quantity ~= 0 and not (not reagent.hasQuality and reagentItem.quantity == orderReagent.reagent.quantity) then
					systemPrint("CraftLogger: Error, Order Reagent Already Has Quantity.")
					error()
				end
				reagentItem.quantity = orderReagent.reagent.quantity
			end
			
			if reagentItem.quantity > 0 then
				local craftingResourceReturnInfo = GUTIL:Find(
					craftingItemResultData.resourcesReturned, 
					function(cRRI)
					return cRRI.itemID == itemID
					end) 
					or {}
				
				local quality
				if reagent.hasQuality and reagentItem.qualityID ~= 0 then
					quality = reagentItem.qualityID
				end
				
				table.insert(self.reagents, {
					itemName = reagentItem.item:GetItemName(),
					itemID = itemID,
					quality = quality,
					quantity = reagentItem.quantity,
					quantityReturned = craftingResourceReturnInfo.quantity,
					isOrderReagentIn = reagentItem:IsOrderReagentIn(recipeData),
					})
			end
		end
	end
	
	local salvageReagentSlot = recipeData.reagentData.salvageReagentSlot
	local salvageReagent = salvageReagentSlot.activeItem
	if salvageReagent then
		local itemID = salvageReagent.item:GetItemID()
		
		local craftingResourceReturnInfo = GUTIL:Find(
			craftingItemResultData.resourcesReturned, 
			function(cRRI)
			return cRRI.itemID == itemID
			end) 
			or {}
			
		local isOrderReagentIn = false
		if recipeData.orderData then
			local orderReagent = GUTIL:Find(recipeData.orderData.reagents or {},
				function(reagentInfo) 
				return reagentInfo.reagent.itemID == itemID 
				end)
			if orderReagent then
				isOrderReagentIn = true 
			end
		end
		
		local quality = C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemID)

		table.insert(self.reagents, {
			itemName = salvageReagent.item:GetItemName(),
			itemID = itemID,
			quality = quality,
			quantity = salvageReagentSlot.requiredQuantity,
			quantityReturned = craftingResourceReturnInfo.quantity,
			isOrderReagentIn = isOrderReagentIn,
			})
	end

	local optionalSlots = GUTIL:Concat({
		recipeData.reagentData.optionalReagentSlots or {},
		recipeData.reagentData.finishingReagentSlots or {},
		})
	table.insert(optionalSlots, recipeData.reagentData.requiredSelectableReagentSlot)
	
	self.optionalReagents = {}	
	for _, optionalReagentSlot in pairs(optionalSlots) do
		optionalReagentSlot = optionalReagentSlot or {}
		local optionalReagent = optionalReagentSlot.activeReagent
		if optionalReagent then
			local itemID = optionalReagent.item:GetItemID()

			local craftingResourceReturnInfo = GUTIL:Find(
				craftingItemResultData.resourcesReturned, 
				function(cRRI)
				return cRRI.itemID == itemID
				end) 
				or {}
				
			local quality
			if optionalReagent.qualityID ~= 0 then
				quality = optionalReagent.qualityID
			end

			table.insert(self.optionalReagents, {
				itemName = optionalReagent.item:GetItemName(),
				itemID = itemID,
				quality = quality,
				quantity = optionalReagentSlot.maxQuantity,
				quantityReturned = craftingResourceReturnInfo.quantity,
				isOrderReagentIn = optionalReagent:IsOrderReagentIn(recipeData),
				})
		end
	end
	
	--Stat Data
	recipeData.professionStats = recipeData.professionStats or {}
	
	--Assume Only 1 Extra Value
	self.bonusStats = {}
	for _, professionStat in pairs(recipeData.professionStats) do
		local name = professionStat.name
		if 		(name == "multicraft" and recipeData.supportsMulticraft) or
				(name == "resourcefulness" and recipeData.supportsResourcefulness) or
				(name == "craftingspeed" and recipeData.supportsCraftingspeed) or
				(name == "ingenuity" and recipeData.supportsIngenuity) then
			
			self.bonusStats[name] = {
				bonusStatValue = GUTIL:Round(professionStat.value),
				ratingPct = professionStat:GetPercent(),
				extraValue = professionStat.extraValues[1] or 0,
				}
		end
	end
end

function CraftLogger.CraftOutput:Printing()
	systemPrint("Recipe: " .. self.recipeName .. " @ " .. self.date)

	for _, item in pairs(self.items) do
		local qualityTitleOuter = (item.quality == nil and "") or ("*" .. item.quality)
		systemPrint("Result: " .. item.itemName .. qualityTitleOuter .. ": x" .. item.quantity)
	end
	
	local allReagents = GUTIL:Concat({
		self.reagents,
		self.optionalReagents,
		})
	
	for _, reagent in pairs(allReagents) do
		if reagent.quantity > 0 then 
			local qualityTitle = (reagent.quality == nil and "") or ("*" .. reagent.quality)
			systemPrint("Reagent: " .. reagent.itemName .. qualityTitle .. ": x" .. reagent.quantity)
		end
	end
	
	for _, reagent in pairs(allReagents) do
		if reagent.quantityReturned then
			local qualityTitle = (reagent.quality == nil and "") or ("*" .. reagent.quality)
			systemPrint("savedReagent: " .. reagent.itemName .. qualityTitle .. ": x" .. reagent.quantityReturned)
		end
	end

	local concentratingPrint = (self.concentration.concentrating == nil and "N/A") or tostring(self.concentration.concentrating)
	local triggeredIngenuityPrint = (self.concentration.triggeredIngenuity == nil and "N/A") or tostring(self.concentration.triggeredIngenuity)
	systemPrint("Concentrating: " .. concentratingPrint .. ", Triggered Ingenuity: " .. triggeredIngenuityPrint)
	
	for bonusStatName, bonusStat in pairs(self.bonusStats) do
		systemPrint(bonusStatName .. ": " .. bonusStat.bonusStatValue .. " (" .. math.floor(bonusStat.ratingPct * 10^2 + .5) / 10^2 .. "%)")
	end
end

function CraftLogger.CraftOutput:Copy()
	local copiedTable = CraftLogger.UTIL:CopyNestedTable(self)
	local copy = CraftLogger.CraftOutput:new(copiedTable)

	return copy
end

--Prepare for addition to CraftLoggerDB
function CraftLogger.CraftOutput:Clean()
	--Other
	self.test = nil
	self.profession = nil
	self.expansionName = nil
	self.isOldWorldRecipe = nil
	self.isGear = nil
	self.isSoulbound = nil
	
	--Multicraft
	for _, item in pairs(self.items) do
		item.normalQuantity = nil
		item.triggeredMulticraft = nil
		item.multicraftFactor = nil
	end

	--Resourcefulness
	self.typesUsed = nil
	self.typesReturned = nil
	for _, reagent in pairs(self.reagents) do
		reagent.triggeredResourcefulness = nil
		reagent.resourcefulnessFactor = nil
	end
	
	--Ingenuity
	self.concentration.ingenuityRefund = nil
end

--For Export
function CraftLogger.CraftOutput:SetAllStats(cachedProfessionInfo, cachedItemStats)
	cachedProfessionInfo[self.recipeID] = cachedProfessionInfo[self.recipeID] or C_TradeSkillUI.GetProfessionInfoByRecipeID(self.recipeID)
	local professionInfo = cachedProfessionInfo[self.recipeID]
	self.profession = professionInfo.parentProfessionName
	self.expansionName = professionInfo.expansionName
	self.isOldWorldRecipe = self.expansionID <= 8
	
	local bonusStats = self.bonusStats
	
	for _, item in pairs(self.items) do
		local itemStats = cachedItemStats[item.itemID]
		if not itemStats then
			local isGear = C_Item.GetItemInventoryTypeByID(item.itemID) ~= 0
			local bindType = select(14, C_Item.GetItemInfo(item.itemID))
			local isSoulbound = bindType == Enum.ItemBind.OnAcquire or
								bindType == Enum.ItemBind.Quest or
								bindType == Enum.ItemBind.ToWoWAccount or
								bindType == Enum.ItemBind.ToBnetAccount
			itemStats = {isGear = isGear, isSoulbound = isSoulbound}
			cachedItemStats[item.itemID] = itemStats
		end
		item.isGear = itemStats.isGear
		item.isSoulbound = itemStats.isSoulbound
		
		--Non-Cache
		item.normalQuantity = item.quantity - (item.extraQuantity or 0)
		
		if bonusStats["multicraft"] then
			if item.extraQuantity then
				item.triggeredMulticraft = true
				item.multicraftFactor = item.extraQuantity / item.normalQuantity
			else
				item.triggeredMulticraft = false
				item.multicraftFactor = nil
			end
		end
	end

	if bonusStats["resourcefulness"] then
		local typesUsed = 0
		local typesReturned = 0
		local reagents = self.reagents

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
		self.typesUsed = typesUsed
		self.typesReturned = typesReturned
	end

	if bonusStats["ingenuity"] then
		if self.concentration.concentrating and self.concentration.triggeredIngenuity then
			self.concentration.ingenuityRefund = ceil(self.concentration.concentrationSpent / 2)
		else
			self.concentration.ingenuityRefund = nil
		end
	end
end