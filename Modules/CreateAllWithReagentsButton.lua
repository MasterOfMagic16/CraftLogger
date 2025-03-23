local CraftLogger = select(2, ...)

local systemPrint = print

local GGUI = CraftLogger.GGUI
local GUTIL = CraftLogger.GUTIL

CraftLogger.CreateAllWithReagentsButton = {}

--Need to verify accuracy
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
		local text = "CraftLogger: Create All [" .. tostring(craftableAmount) .. "]"
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
		label = "CraftLogger: Create All [    ]",
        tooltipOptions = {
            anchor = "ANCHOR_CURSOR_RIGHT",
            text = "Create All Using Only The Current Reagent Configuration\nWill Craft With Simulation Mode If Active",
        },
        clickCallback = function() recipeData:Craft(craftableAmount) end,
    }
	CraftLogger.CreateAllWithReagentsButton.Button:Show()

	--Finish
	initialized = true
end
