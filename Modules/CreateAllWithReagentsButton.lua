local CraftLogger = select(2, ...)

print("Loaded")

local systemPrint = print

local GGUI = CraftLogger.GGUI
local GUTIL = CraftLogger.GUTIL

CraftLogger.CreateAllWithReagentsButton = {}

--Need to verify accuracy
--This will trigger what simulation mode has
--required selectable reagent issue
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
		
		
		--Implement Salvage as well
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
			craftableAmount = math.min(itemFitCount, craftableAmount)
		end
		
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
