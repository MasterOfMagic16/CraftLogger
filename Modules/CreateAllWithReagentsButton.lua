local CraftLogger = select(2, ...)

print("Loaded")

local systemPrint = print

local GGUI = CraftLogger.GGUI
local GUTIL = CraftLogger.GUTIL

CraftLogger.CreateAllWithReagentsButton = {}

--Address issues with recipedata generation same time as craftsim 
--Get function to update?
--Concentration doesn't trigger update
local initialized = false
function CraftLogger.CreateAllWithReagentsButton:Init()
	if initialized then return end
	
	local recipeData
	local craftableAmount
	
	local function Init()
		print("Init Called")
		recipeData = CraftSimAPI:GetCraftSim().INIT.currentRecipeData:Copy()
		craftableAmount = max(1, recipeData.reagentData:GetCraftableAmount(recipeData:GetCrafterUID()))
		local text = "Create All With Reagents [" .. (craftableAmount or "Err") .. "]"
		CraftLogger.CreateAllWithReagentsButton.Button:SetText(text)
	end

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
	
	Button = CraftLogger.CreateAllWithReagentsButton.Button
	
	local hookFrame = ProfessionsFrame.CraftingPage.SchematicForm
	hooksecurefunc(hookFrame, "Init", Init)
	
	hookFrame:RegisterCallback(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified, Init)
	hookFrame:RegisterCallback(ProfessionsRecipeSchematicFormMixin.Event.UseBestQualityModified, Init)

	local recipeTab = ProfessionsFrame.TabSystem.tabs[1]

	recipeTab:HookScript("OnClick", Init)
	
	ProfessionsFrame.CraftingPage.SchematicForm.Details.CraftingChoicesContainer.ConcentrateContainer
		.ConcentrateToggleButton:HookScript("OnClick", Init)
	
	CraftLogger.CreateAllWithReagentsButton.Button:Show()
	
	initialized = true
end