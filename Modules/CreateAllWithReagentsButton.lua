local CraftLogger = select(2, ...)

print("Loaded")

local systemPrint = print

local GGUI = CraftLogger.GGUI
local GUTIL = CraftLogger.GUTIL

CraftLogger.CreateAllWithReagentsButton = {}

--Issue with possible differences in RecipeData for the craft command
--Can text be dynamic?
local initialized = false
function CraftLogger.CreateAllWithReagentsButton:Init()
	if initialized then return end

	--Hook 
	local recipeData 
	local craftableAmount 
	local function Update()
		--Parameters
		recipeData = CraftSimAPI:GetCraftSim().INIT.currentRecipeData:Copy()
		craftableAmount = max(1, recipeData.reagentData:GetCraftableAmount(recipeData:GetCrafterUID()))
		
		--Text Update
		local text = "Create All With Reagents [" .. (craftableAmount or "Err") .. "]"
		CraftLogger.CreateAllWithReagentsButton.Button:SetText(text)
	end
	hooksecurefunc(CraftSimAPI:GetCraftSim().INIT, "TriggerModulesByRecipeType", Update)
	
	--Frame
	CraftLogger.CreateAllWithReagentsButton.Button = GGUI.Button{
		parent = ProfessionsFrame.CraftingPage.CreateAllButton,
        anchorPoints = { {
            anchorParent = ProfessionsFrame.CraftingPage.CreateAllButton,
            anchorA = "RIGHT", anchorB = "LEFT", offsetX = -10,
        } },
        adjustWidth = true,
		label = "Create All With Reagents [    ]",
        tooltipOptions = {
            anchor = "ANCHOR_CURSOR_RIGHT",
            text = "Create All Using Only Current Reagent Configuration",
        },
        clickCallback = function() recipeData:Craft(craftableAmount) end,
    }
	CraftLogger.CreateAllWithReagentsButton.Button:Show()

	--Finish
	initialized = true
end
