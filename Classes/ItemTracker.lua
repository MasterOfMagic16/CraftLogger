local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

print("ItemTracker Loaded")

CraftLogger.ItemTracker = CraftLogger.CraftLoggerObject:extend()

function CraftLogger.ItemTracker:new(itemID, quantity, price)
	self.itemID = itemID
	self.quantity = quantity or 0
	self.value = self.quantity * (price or 0)
end

function CraftLogger.ItemTracker:GetPrice()
	if self.quantity == 0 then
		return 0
	end
	return self.value / self.quantity
end

function CraftLogger.ItemTracker:Add(quantity, price)
	local gainedValue = quantity * (price or 0)
	
	self.quantity = self.quantity + quantity 
	self.value = self.value + gainedValue
	
	return gainedValue
end

function CraftLogger.ItemTracker:Subtract(quantity)
	local lostValue = quantity * self:GetPrice()
	
	self.quantity = self.quantity - quantity 
	self.value = self.value - lostValue
	
	return lostValue
end