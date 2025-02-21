local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

CraftLogger.UTIL = {}

local print
function CraftLogger.UTIL:Init()
	print = CraftSimAPI:GetCraftSim().DEBUG:RegisterDebugID("CraftLogger.Util")
	print("UTIL Loaded")
end

--Core
function CraftLogger.UTIL:GetSchematicFormByVisibility()
    if ProfessionsFrame.CraftingPage.SchematicForm:IsVisible() then
        return ProfessionsFrame.CraftingPage.SchematicForm
    elseif ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm:IsVisible() then
        return ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm
    end
end

function CraftLogger.UTIL:CopyNestedTable(tbl)
	if type(tbl) ~= "table" then 
		return tbl
	end
	
	local returnTable = {}
	for key, value in pairs(tbl) do
		returnTable[key] = CraftLogger.UTIL:CopyNestedTable(value)
	end 

	return returnTable
end

function CraftLogger.UTIL:KethoEditBox_Show(text)
	if not KethoEditBox then
		local f = CreateFrame("Frame", "KethoEditBox", UIParent, "DialogBoxFrame")
		f:SetPoint("CENTER")
		f:SetSize(600, 500)
		
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
			edgeSize = 16,
			insets = { left = 8, right = 6, top = 8, bottom = 8 },
		})
		f:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue
		-- Movable
		f:SetMovable(true)
		f:SetClampedToScreen(true)
		f:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				self:StartMoving()
			end
		end)
		f:SetScript("OnMouseUp", f.StopMovingOrSizing)
		
		-- ScrollFrame
		local sf = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame", KethoEditBox, "UIPanelScrollFrameTemplate")
		sf:SetPoint("LEFT", 16, 0)
		sf:SetPoint("RIGHT", -32, 0)
		sf:SetPoint("TOP", 0, -16)
		sf:SetPoint("BOTTOM", KethoEditBoxButton, "TOP", 0, 0)
		
		-- EditBox
		local eb = CreateFrame("EditBox", "KethoEditBoxEditBox", KethoEditBoxScrollFrame)
		eb:SetSize(sf:GetSize())
		--eb:SetMultiLine(true)
		eb:GetRegions():SetNonSpaceWrap(true)
		eb:SetAutoFocus(false) -- dont automatically focus
		eb:SetFontObject("ChatFontNormal")
		eb:SetScript("OnEscapePressed", function() f:Hide() end)
		sf:SetScrollChild(eb)
		-- Resizable
		f:SetResizable(true)
		--f:SetMinResize(150, 100)
		
		local rb = CreateFrame("Button", "KethoEditBoxResizeButton", KethoEditBox)
		rb:SetPoint("BOTTOMRIGHT", -6, 7)
		rb:SetSize(16, 16)
		
		rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
		rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
		rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
		
		rb:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" then
				f:StartSizing("BOTTOMRIGHT")
				self:GetHighlightTexture():Hide() -- more noticeable
			end
		end)
		rb:SetScript("OnMouseUp", function(self, button)
			f:StopMovingOrSizing()
			self:GetHighlightTexture():Show()
			eb:SetWidth(sf:GetWidth())
		end)
		f:Show()
	end
	
	if text then
		KethoEditBoxEditBox:SetText(text)
	end
	KethoEditBox:Show()
end

--Manipulate
function CraftLogger.UTIL:RemoveFromTable(input, removefunc)
	local n=#input
	for i=1,n do
		if removefunc(input[i], i) then
			input[i]=nil
		end
	end

	local j=0
	for i=1,n do
		if input[i]~=nil then
			j=j+1
			input[j]=input[i]
		end
	end
	for i=j+1,n do
		input[i]=nil
	end
end

function CraftLogger.UTIL:ConvertDateToTime(date1)
	if not date1 then
		return
	end
	
	local function split(inputstr, sep)
		if sep == nil then
			sep = "%s"
		end
		local t = {}
		for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
			table.insert(t, str)
		end
		return t
	end
	
	split1 = split(date1)
	firsthalf = split1[1]
	secondhalf = split1[2]
	
	firsthalfsplit = split(firsthalf, "/")
	month = tonumber(firsthalfsplit[1])
	day = tonumber(firsthalfsplit[2])
	year = tonumber("20" .. firsthalfsplit[3])
	
	secondhalfsplit = split(secondhalf, ":")
	hour = tonumber(secondhalfsplit[1])
	minute = tonumber(secondhalfsplit[2])
	second = tonumber(secondhalfsplit[3])

	local dateTbl = {
		year = year,
		month = month,
		day = day,
		hour = hour,
		min = minute,
		sec = second,
	}
	
	return time(dateTbl)
end

--Debug
function CraftLogger.UTIL:PrintCraftTable(craftingReagentInfoTbl)
	systemPrint("CraftLogger: Begin Table.")
	if #craftingReagentInfoTbl == 0 then
		systemPrint("CraftLogger: Table Empty.")
		return
	end
	for _, reagent in pairs(craftingReagentInfoTbl) do
		systemPrint(C_Item.GetItemNameByID(reagent.itemID))
		systemPrint(reagent.quantity)
	end
	systemPrint("CraftLogger: End Table.")
end

function CraftLogger.UTIL:PrintSchematicForm(recipeData)
	systemPrint("CraftLogger: Begin Schematic.")
	local schematicForm = CraftLogger.UTIL:GetSchematicFormByVisibility()
	if not schematicForm then
		systemPrint("CraftLogger: No Schematic.")
		return
	end
	local schematicInfo = C_TradeSkillUI.GetRecipeSchematic(recipeData.recipeID, recipeData.isRecraft)

	local reagentSlots = schematicForm.reagentSlots
	local currentTransaction = schematicForm:GetTransaction()

	local currentOptionalReagent = 1
	local currentFinishingReagent = 1

	for slotIndex, currentSlot in pairs(schematicInfo.reagentSlotSchematics) do
		local reagentType = currentSlot.reagentType
		if reagentType == 1 then
			local slotAllocations = currentTransaction:GetAllocations(slotIndex)

			for i, reagent in pairs(currentSlot.reagents) do
				local reagentAllocation = (slotAllocations and slotAllocations:FindAllocationByReagent(reagent)) or nil
				local allocations = 0
				if reagentAllocation ~= nil then
					allocations = reagentAllocation:GetQuantity()
					systemPrint(C_Item.GetItemNameByID(reagent.itemID))
					--systemPrint("reagent #" .. i .. " allocation:")
					--systemPrint(reagentAllocation)
					systemPrint(allocations)
				end
			end
		elseif reagentType == 0 then
			if currentSlot.required then
				local requiredSelectableReagentSlot = reagentSlots[1][1]
				local button = requiredSelectableReagentSlot.Button
				local allocatedItemID = button:GetItemID()
				if allocatedItemID then
					systemPrint("Set Required Selectable")
					systemPrint(requiredSelectableReagentSlot.maxQuantity)
				end
			elseif reagentSlots[reagentType] ~= nil then
				local optionalSlots = reagentSlots[reagentType][currentOptionalReagent]
				if not optionalSlots then
					systemPrint("End Optional")
					error()
				end
				local button = optionalSlots.Button
				local allocatedItemID = button:GetItemID()
				if allocatedItemID then
					systemPrint("Set Optional Reagent")
				end

				currentOptionalReagent = currentOptionalReagent + 1
			end
		elseif reagentType == 2 then
			if reagentSlots[reagentType] ~= nil then
				local optionalSlots = reagentSlots[reagentType][currentFinishingReagent]
				if not optionalSlots then
					systemPrint("End Finishing")
					error()
				end
				local button = optionalSlots.Button
				local allocatedItemID = button:GetItemID()
				if allocatedItemID then
					systemPrint("Set Optional Reagent")
				end

				currentFinishingReagent = currentFinishingReagent + 1
			end
		end
	end
	systemPrint("CraftLogger: End Schematic.")
end