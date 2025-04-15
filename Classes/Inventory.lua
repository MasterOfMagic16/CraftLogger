local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

print("Inventory Loaded")

CraftLogger.Inventory = CraftLogger.CraftLoggerObject:extend()

function CraftLogger.Inventory:new(wealth)
	self.itemTrackers = {}
	self.wealth = wealth or 0
end

function CraftLogger.Inventory:GetValue()
	local value = self.wealth
	for _, itemTracker in ipairs(self.itemTrackers) do
		value = value + itemTracker.value
	end
	return value
end

function CraftLogger.Inventory:FindItemTracker(name)
	local itemTracker = GUTIL:Find(self.itemTrackers, function(itemTracker) return itemTracker.name == name end)
	return itemTracker
end

--Value Neutral
function CraftLogger.Inventory:Buy(name, quantity, price)
	local startValue = self:GetValue()

	--Can make this get player money, above as well if so
	self.wealth = self.wealth - quantity * price

	local itemTracker = self:FindItemTracker(name)
	if itemTracker then
		itemTracker:Add(quantity, price)
	else
		itemTracker = CraftLogger.ItemTracker(name, quantity, price)
		table.insert(self.itemTrackers, itemTracker)
	end

	if self:GetValue() ~= startValue then
		print("WARNING: Buy is not value-neutral.")
	end
end


function CraftLogger.Inventory:Sell(name, quantity, price)
	--Can make this get player money, above as well if so
	self.wealth = self.wealth + quantity * price

	local itemTracker = self:FindItemTracker(name)
	if itemTracker then
		itemTracker:Subtract(quantity)
	else
		print("WARNING: Sold item does not exist.")
	end
end

function CraftLogger.Inventory:Craft(inputs, output)
	local startValue = self:GetValue()

	local lostValue = 0
	for name, quantity in pairs(inputs) do
		itemTracker = self:FindItemTracker(name)
		lostValue = lostValue + itemTracker:Subtract(quantity)
	end
	
	local name, quantity = output
	local price = lostValue / quantity
	local itemTracker = self:FindItemTracker(name)
	if itemTracker then
		itemTracker:Add(quantity, price)
	else
		itemTracker = CraftLogger.ItemTracker(name, quantity, price)
		table.insert(self.itemTrackers, itemTracker)
	end
	
	if self:GetValue() ~= startValue then
		print("WARNING: Craft is not value-neutral.")
	end
end