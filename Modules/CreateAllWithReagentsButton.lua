local CraftLogger = select(2, ...)

print("Loaded")

local systemPrint = print

local GGUI = CraftLogger.GGUI
local GUTIL = CraftLogger.GUTIL

CraftLogger.CreateAllWithReagentsButton = {}

local initialized = false
function CraftLogger.CreateAllWithReagentsButton:Init()
	if initialized then return end
	
	local craftableAmount

	local function Init()
		local recipeData = CraftSimAPI:GetCraftSim().INIT.currentRecipeData:Copy()
		craftableAmount = max(1, recipeData.reagentData:GetCraftableAmount(recipeData:GetCrafterUID()))
		CraftLogger.CreateAllWithReagentsButton.Button.label = "Create All With Reagents [" .. craftableAmount .. "]"
	end

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
        clickCallback = function() recipeData:Craft(craftableAmount) end,
    }
	
	Button = CraftLogger.CreateAllWithReagentsButton.Button
	
	Init()
	
	local hookFrame = ProfessionsFrame.CraftingPage.SchematicForm
	hooksecurefunc(hookFrame, "Init", Init)
	
	CraftLogger.CreateAllWithReagentsButton.Button:Show()
	
	initialized = true
end