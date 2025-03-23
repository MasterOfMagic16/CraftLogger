local CraftLogger = select(2, ...)

print("Loaded")

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

CraftLogger.CreateAllWithReagentsButton = {}

function CLCraftTest()
	print("Called")
	
	--The only possible issue is that this might not craft what is expected.
	--However, what is actually crafted will still match CraftLogger, so good.
	local recipeData = CraftSimAPI:GetCraftSim().INIT.currentRecipeData:Copy()

	local craftAbleAmount = max(1, recipeData.reagentData:GetCraftableAmount(recipeData:GetCrafterUID()))
	recipeData:Craft(craftableAmount)
end
