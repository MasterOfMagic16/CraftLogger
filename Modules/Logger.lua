local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

CraftLogger.Logger = GUTIL:CreateRegistreeForEvents({ "TRADE_SKILL_ITEM_CRAFTED_RESULT" })

local print
function CraftLogger.Logger:Init()
	print = CraftSimAPI:GetCraftSim().DEBUG:RegisterDebugID("CraftLogger.Logger")
	print("Logger Loaded")
end

function CraftLogger.Logger:SetRecipeData(recipeData)
	CraftLogger.Logger.currentRecipeData = recipeData
	CraftLogger.Logger.recipeDataFresh = true
end

function CraftLogger.Logger:SetCraftableAmount(craftAbleAmount)
	CraftLogger.Logger.craftAbleAmountRemaining = craftAbleAmount
end

--Mirrors CraftSim with extra handling
local accumulatingCraftOutputData = {}
local isAccumulatingCraftOutputData = true
function CraftLogger.Logger:TRADE_SKILL_ITEM_CRAFTED_RESULT(craftingItemResultData)
	local recipeData = CraftLogger.Logger.currentRecipeData
	
	--Filter Conditions
	if not CraftLoggerDBSettings.enabled then
		systemPrint("CraftLogger: CraftLogger Is Currently Disabled. Please Run /run CLEnable() When Ready.")
		return
	end
	
	local language = GetLocale()
	if language ~= "enUS" and language ~= "enGB" then
		systemPrint("CraftLogger: Currently Does Not Support Other Languages.")
		return
	end
	
	if not CraftLogger.Logger.recipeDataFresh then
		systemPrint("CraftLogger: recipeData Generation Failed.")
		return
	end
	
	if craftingItemResultData.isEnchant then
		systemPrint("CraftLogger: Currently Does Not Support Gear Enchants.")
		return
	end
	
	if recipeData.isSalvageRecipe then
		systemPrint("CraftLogger: Currently Does Not Support Salvage Recipes.")
		return
	end
	
	if recipeData.isQuestRecipe then
		systemPrint("CraftLogger: Does Not Track Quest Recipes.")
		return
	end
	
	if recipeData.recipeInfo.isDummyRecipe then
		systemPrint("CraftLogger: Does Not Track Dummy Recipes.")
		return
	end
	
	if CraftLogger.Logger.craftAbleAmountRemaining < 1 then
		systemPrint("CraftLogger: Does Not Track CraftAmounts Beyond Initial Craftable Amount Due To ReagentData Errors.")
		return
	end

	local possibleItems = recipeData.resultData.itemsByQuality
	if not GUTIL:Find(possibleItems, function(i) return i:GetItemID() == craftingItemResultData.itemID end) then
		systemPrint("CraftLogger: Failed. Item Created Is Not Possible With Current RecipeData.")
		return
	end
	--End Filter Conditions
	
	local craftOutputData = {test = "test"}
	local craftOutput = CraftLogger.CraftOutput:new(craftOutputData)
	craftOutput:Generate(recipeData, craftingItemResultData)
	
	CLTest = craftOutput

	table.insert(accumulatingCraftOutputData, craftOutput)
	if isAccumulatingCraftOutputData then
        isAccumulatingCraftOutputData = false
        C_Timer.After(0.2, function()
            CraftLogger.Logger:AccumulateCraftOutputs()
        end)
    end
end

function CraftLogger.Logger:AccumulateCraftOutputs()	
    isAccumulatingCraftOutputData = true
	
    local collectedCraftOutputData = accumulatingCraftOutputData
    accumulatingCraftOutputData = {}

	--The only lag error is quantity
	print("CheckL")
	local accumulatedCraftOutput = collectedCraftOutputData[1]:Copy()
	accumulatedCraftOutput.item.quantity = 0
	local craftedItemID = accumulatedCraftOutput.item.itemID
	for _, craftOutput in pairs(collectedCraftOutputData) do
		if craftOutput.item.itemID ~= craftedItemID then
			systemPrint("CraftLogger: Currently Does Not Support Multiple Items Output.")
			return
		end	
		accumulatedCraftOutput.item.quantity = accumulatedCraftOutput.item.quantity + craftOutput.item.quantity
	end

	--Verify Output is Clean For CraftLoggerDB
	accumulatedCraftOutput:Clean()
	table.insert(CraftLoggerDB, accumulatedCraftOutput)
	systemPrint("CraftLogger: Added To DB")
	accumulatedCraftOutput:Printing()
	
	--Issue Handling for cast amount > 1
	CraftLogger.Logger.craftAbleAmountRemaining = CraftLogger.Logger.craftAbleAmountRemaining - 1
	CraftLogger.Logger.currentRecipeData.buffData:Update()
	CraftLogger.Logger.currentRecipeData.professionGearSet:LoadCurrentEquippedSet()
	CraftLogger.Logger.currentRecipeData:Update()
end
