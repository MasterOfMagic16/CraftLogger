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

function CraftLogger.CreateAllWithReagentsButton:Init()	
	print("Initted")
	local sizeX = 880
	local sizeY = 420
	
	local backdropOptions = {
		bgFile = "Interface\\Buttons\\WHITE8X8",
		borderOptions = {
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		},
		colorR = 0,
		colorG = 0,
		colorB = 0,
		colorA = 1,
	}

	print("CheckOT")
	CraftLogger.CreateAllWithReagentsButton.frame = GGUI.Frame({
		parent = ProfessionsFrame,
		anchorParent = ProfessionsFrame,
		sizeX = sizeX,
		sizeY = sizeY,
		frameID = "CreateAllWithReagentsButtonFrame",
		title = "CRAFT_QUEUE_TITLE", --Possible Weirdness
		collapseable = true,
		closeable = true,
		moveable = true,
		backdropOptions = backdropOptions,
		--onCloseCallback = CraftSim.CONTROL_PANEL:HandleModuleClose("MODULE_CRAFT_QUEUE"),
		frameTable = CraftLogger.INIT.FRAMES,
		frameConfigTable = {},
		frameStrata = "HIGH",
		raiseOnInteraction = true,
		frameLevel = CraftLogger.UTIL:NextFrameLevel()
	})
	
	CraftLogger.CreateAllWithReagentsButton.frame:Show()
	
	print("Check2")
end
