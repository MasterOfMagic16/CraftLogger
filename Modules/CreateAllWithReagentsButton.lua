local CraftLogger = select(2, ...)

print("Loaded")

local systemPrint = print

local GGUI = CraftLogger.GGUI
local GUTIL = CraftLogger.GUTIL

CraftLogger.CreateAllWithReagentsButton = {}

--Need to verify accuracy
--This will trigger what simulation mode has
--If zero, gray out
local initialized = false
function CraftLogger.CreateAllWithReagentsButton:Init()
	if initialized then return end

	--Hook 
	local recipeData 
	local craftableAmount 
	local function Update()
		--Parameters
		recipeData = CraftSimAPI:GetCraftSim().INIT.currentRecipeData:Copy()
		craftableAmount = recipeData.reagentData:GetCraftableAmount(recipeData:GetCrafterUID())
		
		--Text Update
		local text = "Create All With Reagents [" .. tostring(craftableAmount) .. "]"
		CraftLogger.CreateAllWithReagentsButton.Button:SetText(text)
		
		C_Timer.After(.01, function()
			local enabled = ProfessionsFrame.CraftingPage.CreateAllButton:IsEnabled()
			CraftLogger.CreateAllWithReagentsButton.Button:SetEnabled(enabled)
			end)
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
            text = "CraftLogger:\nCreate All Using Only The Current Reagent Configuration\n(Will Use Simulation Mode If Applicable)",
        },
        clickCallback = function() recipeData:Craft(craftableAmount) end,
    }
	CraftLogger.CreateAllWithReagentsButton.Button:Show()

	--Finish
	initialized = true
end
