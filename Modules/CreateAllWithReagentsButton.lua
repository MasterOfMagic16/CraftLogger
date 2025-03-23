local CraftLogger = select(2, ...)

print("Loaded")

local systemPrint = print

local GGUI = CraftLogger.GGUI
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

--Make it update craftable amount
--Doesn't work for orders, but fine since one craft anyway
function CraftLogger.CreateAllWithReagentsButton:Init()	
	CraftLogger.CreateAllWithReagentsButton.Button = GGUI.Button {
		parent = ProfessionsFrame.CraftingPage.CreateAllButton,
        anchorPoints = { {
            anchorParent = ProfessionsFrame.CraftingPage.CreateAllButton,
            anchorA = "RIGHT", anchorB = "LEFT", offsetX = -10,
        } },
        adjustWidth = true,
        label = "Create All With Reagents []",
        tooltipOptions = {
            anchor = "ANCHOR_CURSOR_RIGHT",
            text = "Create All Using Only Current Reagent Configuration",
        },
        clickCallback = function() CLCraftTest() end,
    }
	
	CraftLogger.CreateAllWithReagentsButton.Button:Show()
end
