local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

CraftLogger.AuctionHouse = CraftLogger.CraftLoggerObject:extend()

function CraftLogger.AuctionHouse:new(auctionHouseData)
	print("CheckL")
	auctionHouseData = auctionHouseData or {auctions = {}}
	print("CheckL2")

	--Set Craft Output Object Prototypes
	for _, auctionData in ipairs(auctionHouseData.auctions) do
		CraftLogger.Auction:new(auctionData)
	end
	
	print("CheckL3")
	
	setmetatable(auctionHouseData, self)
	self.__index = self
	
	return auctionHouseData
end

--TODO: Probably will be issues with item mixin on DB storage

--[[ Auction Control ]]--

function CraftLogger.AuctionHouse:PostCommodity(item, duration, quantity, unitPrice)
	local auction = CraftLogger.Auction:new()
	auction:Generate(item, duration, quantity, unitPrice)
	table.insert(self.auctions, auction)
end

--ignore bids for now
function CraftLogger.AuctionHouse:PostItem(item, duration, quantity, bid, buyout)
	if buyout and bid then
		print("Buyout and bid not supported. Error.")
		print(bid)
		print(buyout)
		error()
	end
	bid = bid or buyout
	local auction = CraftLogger.Auction:new()
	print("CheckL2.6")
	auction:Generate(item, duration, quantity, bid)
	print("CheckL2.7")
	table.insert(self.auctions, auction)
end

--Might not work as post-hook
function CraftLogger.AuctionHouse:CancelAuction(ownedAuctionID)
	print("Cancel Called")
	local auctionIndex = self:FindAuctionByAuctionID(ownedAuctionID)
	table.remove(self.auctions, auctionIndex)
end



--[[ Find Auction ]]--

function CraftLogger.AuctionHouse:FindAuctionBySaleHint(itemName, quantity, unitPrice)
	print("Sale Hint")
	
	self:ClearExpired()
	
	
	
	local found = false
	local auctionIndex
	for index, auction in pairs(self.auctions) do
		if auction:CheckSaleHint(itemName, quantity, unitPrice)then
			if found then
				print("Duplicate Auction. Error.")
				error()
			end
			auctionIndex = index
			found = true
		end
	end
	
	if not auctionIndex then
		print("Auction Not Found. No Error")
		--error()
	else
		print("found")
	end
	return auctionIndex
end

function CraftLogger.AuctionHouse:FindAuctionByAuctionID(ownedAuctionID)
	local ownedAuction
	
	local found = false
	local gameIndex
	
	local index = 0
	local auctionInfo = 0
	while auctionInfo do
		index = index + 1
		auctionInfo = C_AuctionHouse.GetOwnedAuctionInfo(index)
		if auctionInfo and auctionInfo.auctionID == ownedAuctionID then
			if found then
				print("Duplicate Auction @ ID. No Error.")
				--error()
			end
			found = true
			gameIndex = index
		end
	end
	if not found then
		print("Auction Not Found @ ID. No Error.")
		--error()
	else
		print("Found @ ID")
	end
			
	local ownedAuctionInfo = C_AuctionHouse.GetOwnedAuctionInfo(gameIndex)

	print("Check0")
	local itemInfo = C_Item.GetItemInfo(ownedAuctionInfo.itemLink)
	print("Check1")
	local itemName = itemInfo.itemName
	print("Check2")
	local quantity = ownedAuctionInfo.quantity
	print("Check3")
	local unitPrice = ownedAuctionInfo.buyoutAmount
	print("Check4")
	local auctionIndex = self:FindAuctionBySaleHint(itemName, quantity, unitPrice)
	return auctionIndex
end



--[[ Other ]]--

function CraftLogger.AuctionHouse:ClearExpired()
	local currentTime = time()
	local function removefunc(auction)
		if currentTime > auction.expirationTime then
			return true
		end
		return false
	end
	
	CraftLogger.UTIL:RemoveFromTable(self.auctions, removefunc)
end

















