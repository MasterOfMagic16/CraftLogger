local CraftLogger = select(2, ...)

local GUTIL = CraftLogger.GUTIL

CraftLogger.UTIL = {}

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
		eb:SetMultiLine(true)
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