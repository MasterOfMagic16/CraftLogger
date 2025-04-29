local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

print("Auction Loaded")

CraftLogger.Auction = CraftLogger.CraftLoggerObject:extend()

function CraftLogger.Auction:new(auctionData)
	print("CheckL2.2")
	if auctionData and auctionData.itemLink then
		auctionData.item = Item:CreateFromItemLink(auctionData.itemLink)
	end
	print("CheckL2.4")
	auctionData = auctionData or {}
	setmetatable(auctionData, self)
	self.__index = self
	return auctionData
end

function CraftLogger.Auction:Generate(item, duration, quantity, unitPrice)
	print("gen")
	print(item)
	CLitem = item
	self.itemLink = item:GetItemLink()
	print("CheckG1")
	self.item = item
	self.duration = duration
	self.quantity = quantity
	self.unitPrice = unitPrice
	self.postTime = time()
	print("CheckG2")
	self.expirationTime = self:GetExpirationTime()
end

function CraftLogger.Auction:GetExpirationTime()
	local hours
	if self.duration == 1 then 
		hours = 12
	elseif self.duration == 2 then
		hours = 24
	elseif self.duration == 3 then
		hours = 48
	else
		print("Error, duration invalid for auction.")
		error()
	end
	
	local seconds = hours * 60 * 60
	local expirationTime = self.postTime + seconds
	
	return expirationTime
end

function CraftLogger.Auction:CheckSaleHint(itemName, quantity, unitPrice)
	local oldItemName = self.item:GetItemName()
	if itemName == oldItemName and quantity == self.quantity and unitPrice == self.unitPrice then
		return true
	end
end
