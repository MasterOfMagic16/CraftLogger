local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

print("ValueTracker Loaded")
print("If I am a silly-billy and left this comment in, please remind me to contact TSM for license permission for the Mail hooks")

CraftLogger.ValueTracker = GUTIL:CreateRegistreeForEvents({})

--[[ Trackers ]]--

--Track Value Positions
function CraftLogger.ValueTracker:Init()
	CraftLoggerADB = CraftLoggerADB or {auctions = {}}
	CraftLogger.ValueTracker.inventory = CraftLogger.Inventory(GetMoney())
	CraftLogger.AuctionHouse:new(CraftLoggerADB)
	CraftLogger.ValueTracker.auctionHouse = CraftLoggerADB

	CLI = CraftLogger.ValueTracker.inventory
	CLA = CraftLogger.ValueTracker.auctionHouse
end



--[[ Events ]]--

CraftLogger.ValueTracker.hooks = {}

--Mail Events
CraftLogger.ValueTracker.hooks.TakeInboxItem = TakeInboxItem
TakeInboxItem = function(...)
	CraftLogger.ValueTracker:ScanCollectedMail("TakeInboxItem", ...)
end

CraftLogger.ValueTracker.hooks.TakeInboxMoney = TakeInboxMoney
TakeInboxMoney = function(...)
	CraftLogger.ValueTracker:ScanCollectedMail("TakeInboxMoney", ...)
end

CraftLogger.ValueTracker.hooks.AutoLootMailItem = AutoLootMailItem
AutoLootMailItem = function(...)
	CraftLogger.ValueTracker:ScanCollectedMail("AutoLootMailItem", ...)
end

--Auction Events

--missing bids "place bid"
hooksecurefunc(C_AuctionHouse, "PostCommodity", function(...) CraftLogger.ValueTracker.auctionHouse:PostCommodity(...) end)
hooksecurefunc(C_AuctionHouse, "PostItem", function(...) CraftLogger.ValueTracker.auctionHouse:PostItem(...) end)
hooksecurefunc(C_AuctionHouse, "CancelAuction", function(...) CraftLogger.ValueTracker.auctionHouse:CancelAuction(...) end)

--[[
CraftLogger.ValueTracker.hooks.CancelAuction = C_AuctionHouse.CancelAuction
C_AuctionHouse.CancelAuction = function(...)
	CraftLogger.ValueTracker.auctionHouse:CancelAuction(...)
	CraftLogger.ValueTracker.hooks.CancelAuction(...)
end
]]


--Craft Events
--[[
--craftSalvage?
]]
--Merchant Events
--[[
hooksecurefunc("BuyMerchantItem", func)
hooksecurefunc("BuybackItem", func)
]]
--Trade Events
--Trash Events
--Etc.




--[[ Handlers ]]--
function CraftLogger.ValueTracker:ScanCollectedMail(oFunc, index, subIndex)
	CraftLogger.ValueTracker:RecordMail(index, subIndex)
	CraftLogger.ValueTracker.hooks[oFunc](index, subIndex)
end

function CraftLogger.ValueTracker:RecordMail(index, subIndex)
	print("Trigger Record")
	
	local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, itemCount, wasRead, x, y, z, isGM, firstItemQuantity, firstItemLink  = GetInboxHeaderInfo(index)
	local invoiceType, itemName, playerName, bid, buyout, deposit, consignment, moneyDelay, etaHour, etaMin, count, commerceAuction = GetInboxInvoiceInfo(index)
	--Consignment is AHcut

	local mailType
	if invoiceType == "seller" then
		mailType = "Sale"
	elseif invoiceType == "buyer" then
		mailType = "Purchase"
	else	
		print("Mail Type Not Supported. No Error")
		return
	end
	
	local quantity = count
	local unitPrice = floor(buyout / quantity + 0.5)
	
	local item
	if mailType == "Sale" then
		local auctionIndex = CraftLogger.ValueTracker.auctionHouse:FindAuctionBySaleHint(itemName, quantity, unitPrice)
		if not auctionIndex then
			return
		end
		local auction = self.auctionHouse.auctions[auctionIndex]
		item = auction.item
	elseif mailType == "Purchase" then
		item = Item:CreateFromItemLink(firstItemLink)
	end
	
	local itemID = item:GetItemID()
	if mailType == "Sale" then
		--probably add check for "canlootmailindex"
		print("Trigger Sale")
		CraftLogger.ValueTracker.inventory:Sell(itemID, quantity, price)
	elseif mailType == "Purchase" then
		--probably add check for "validateauctionitemmail"
		--Something weird about vanilla classic
		print("Trigger Buy")
		CraftLogger.ValueTracker.inventory:Buy(itemID, quantity, price)
	end
end