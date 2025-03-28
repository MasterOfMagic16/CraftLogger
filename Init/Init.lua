local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

CraftLogger.INIT = GUTIL:CreateRegistreeForEvents ({ "PLAYER_LOGIN" })

--Initialize Saved Non-DB Variables
CraftLoggerDBSettings = CraftLoggerDBSettings or {enabled = true}

local print
function CraftLogger.INIT:PLAYER_LOGIN()
	if C_AddOns.IsAddOnLoaded("CraftSim") then
		systemPrint("CraftLogger: Loaded.")
	
		--Debug
		CraftSimAPI:GetCraftSim().DEBUG:RegisterDebugID("Profiling")
		print = CraftSimAPI:GetCraftSim().DEBUG:RegisterDebugID("CraftLogger.Init")
		print("INIT Loaded")
	
		--Module Inits
		CraftLogger.UTIL:Init()
		CraftLogger.CraftOutput:Init()
		CraftLogger.Logger:Init()
		CraftLogger.DBManipulator:Init()
		CraftLogger.Export:Init()
		CraftLogger.CreateAllWithReagentsButton:Init()
		
		--Craft Hooks
		CraftLogger.INIT:InitCraftRecipeHooks()
	else
		systemPrint("CraftLogger: CraftSim Addon Is Not Loaded. CraftLogger Is Disabled.")
		CraftLoggerDBSettings.enabled = false
	end
end

--Mirrors CraftSim with extra handling
function CraftLogger.INIT:InitCraftRecipeHooks()
	local function OnCraft(onCraftTable)
		CraftLogger.Logger.recipeDataFresh = false
		
		local recipeData = CraftSimAPI:GetRecipeData({
				recipeID = onCraftTable.recipeID,
				orderData = onCraftTable.orderData,
				isRecraft = onCraftTable.isRecraft,
			})
		
		recipeData:SetNonQualityReagentsMax()
		
		--Modified Reagent Generation
		local schematicForm = CraftLogger.UTIL:GetSchematicFormByVisibility()
		local craftingReagentInfoTbl = onCraftTable.craftingReagentInfoTbl
		
		local function SchematicHandling()
			recipeData:SetAllReagentsBySchematicForm()
			if recipeData.isEnchantingRecipe then
				local transaction = schematicForm:GetTransaction()
				local enchantAllocation = transaction:GetEnchantAllocation()
				recipeData.enchantTargetItemID = enchantAllocation:GetItemID()
			end
		end
		
		local function CraftTblHandling()
			recipeData:SetReagentsByCraftingReagentInfoTbl(craftingReagentInfoTbl)
			if recipeData.isEnchantingRecipe then 
				recipeData.enchantTargetItemID = C_Item.GetItemID(onCraftTable.itemTargetLocation)
			end
		end
	
		--This goes first because of possible hardware override
		if #craftingReagentInfoTbl > 0 then
			CraftTblHandling()
		elseif schematicForm then
			SchematicHandling()
		else
			systemPrint("CraftLogger: No Reagent Data Found.")
			error()
		end

		--When not craftable, reagentData wasn't generated correctly. Likely that optional reagents were used without changing required allocations.
		--This only happens with defaultGUI, therefore:
		if recipeData.reagentData:GetCraftableAmount(recipeData:GetCrafterUID()) == 0 then
			SchematicHandling()
		end
		
		recipeData:SetEquippedProfessionGearSet()

		recipeData.concentrating = onCraftTable.concentrating

		if recipeData.isSalvageRecipe then
			-- itemTargetLocation HAS to be set
			local item = Item:CreateFromItemLocation(onCraftTable.itemTargetLocation)
			--CraftLogger.DEBUG:InspectTable(item or {}, "salvage - itemTargetLocation item")
			if item then
				recipeData:SetSalvageItem(item:GetItemID())
			end
		end

		if recipeData.isRecraft then
			recipeData.allocationItemGUID = onCraftTable.itemGUID
		end

		recipeData:Update()
		
		local craftAbleAmount = recipeData.reagentData:GetCraftableAmount(recipeData:GetCrafterUID())
		
		--Salvage CraftAble Amount handling
		if recipeData.isSalvageRecipe then
			local reagentData = recipeData.reagentData
			local salvageReagentSlot = reagentData.salvageReagentSlot
			
			local function hasQuantityXTimes(crafterUID)
				if not salvageReagentSlot.activeItem then 
					return 0
				end 
				
				local itemID = salvageReagentSlot.activeItem:GetItemID()
				local itemCount = CraftSimAPI:GetCraftSim().CRAFTQ:GetItemCountFromCraftQueueCache(crafterUID, itemID)
				local itemFitCount = math.floor(itemCount / salvageReagentSlot.requiredQuantity)
				
				return itemFitCount
			end
			
			local crafterUID = recipeData:GetCrafterUID()
			local itemFitCount = hasQuantityXTimes(crafterUID)
			craftAbleAmount = math.min(itemFitCount, craftAbleAmount)
		end
		
		--Some recipes like recraft have pre-filled reagents, and so evaluate as 0 craftable.
		--However, I've only seen these craftable one at a time, so craftableAmount = 1
		craftAbleAmount = max(1, craftAbleAmount)
		if (onCraftTable.amount - craftAbleAmount) > 0 then
			systemPrint("CraftLogger: Tracking Will Stop After " .. max(0, craftAbleAmount) .. " Crafts Due To Craft Amount Command > Craftable Amount.")
		end
		
		CraftLogger.Logger:SetCraftableAmount(craftAbleAmount)
		CraftLogger.Logger:SetRecipeData(recipeData)
	end

	hooksecurefunc(C_TradeSkillUI, "CraftRecipe",
		function(recipeID, amount, craftingReagentInfoTbl, recipeLevel, orderID, concentrating)
			OnCraft({
				recipeID = recipeID,
				amount = amount or 1,
				craftingReagentInfoTbl = craftingReagentInfoTbl or {},
				recipeLevel = recipeLevel,
				orderData = orderID and C_CraftingOrders.GetClaimedOrder(),
				concentrating = concentrating,
				callerData = {
					api = "CraftRecipe",
					params = { recipeID, amount, craftingReagentInfoTbl, recipeLevel, orderID, concentrating },
				}
			})
		end)
	hooksecurefunc(C_TradeSkillUI, "CraftEnchant",
		function(recipeID, amount, craftingReagentInfoTbl, enchantItemLocation, concentrating)
			OnCraft({
				recipeID = recipeID,
				amount = amount or 1,
				craftingReagentInfoTbl = craftingReagentInfoTbl or {},
				itemTargetLocation = enchantItemLocation,
				isEnchant = true,
				concentrating = concentrating,
				callerData = {
					api = "CraftEnchant",
					params = { recipeID, amount, craftingReagentInfoTbl, enchantItemLocation, concentrating },
				}
			})
		end)
	hooksecurefunc(C_TradeSkillUI, "RecraftRecipe",
		function(itemGUID, craftingReagentTbl, removedModifications, applyConcentration)
			OnCraft({
				recipeID = select(1, C_TradeSkillUI.GetOriginalCraftRecipeID(itemGUID)),
				amount = 1,
				isRecraft = true,
				itemGUID = itemGUID,
				craftingReagentInfoTbl = craftingReagentTbl or {},
				concentrating = applyConcentration,
				callerData = {
					api = "RecraftRecipe",
					params = { itemGUID, craftingReagentTbl, removedModifications, applyConcentration },
				}
			})
		end)
	hooksecurefunc(C_TradeSkillUI, "RecraftRecipeForOrder",
		function(orderID, itemGUID, craftingReagentTbl, removedModifications, applyConcentration)
			OnCraft({
				recipeID = select(1, C_TradeSkillUI.GetOriginalCraftRecipeID(itemGUID)),
				amount = 1,
				isRecraft = true,
				itemGUID = itemGUID,
				orderData = C_CraftingOrders.GetClaimedOrder(),
				craftingReagentInfoTbl = craftingReagentTbl or {},
				concentrating = applyConcentration,
				callerData = {
					api = "RecraftRecipe",
					params = { orderID, itemGUID, craftingReagentTbl, removedModifications, applyConcentration },
				}
			})
		end)
	hooksecurefunc(C_TradeSkillUI, "CraftSalvage",
		function(recipeID, amount, itemTargetLocation, craftingReagentTbl, applyConcentration)
			OnCraft({
				recipeID = recipeID,
				amount = amount or 1,
				itemTargetLocation = itemTargetLocation,
				craftingReagentInfoTbl = craftingReagentTbl or {},
				concentrating = applyConcentration,
				callerData = {
					api = "CraftSalvage",
					params = { recipeID, amount, itemTargetLocation, craftingReagentTbl, applyConcentration },
				}
			})
		end)
end