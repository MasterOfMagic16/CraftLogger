local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

print("ValueTracker Loaded")

CraftLogger.ValueTracker = GUTIL:CreateRegistreeForEvents({ "AUCTION_HOUSE_SHOW_COMMODITY_WON_NOTIFICATION", "TRADE_SKILL_ITEM_CRAFTED_RESULT" })

CLItemsTracked = {}

function CraftLogger.ValueTracker:AUCTION_HOUSE_SHOW_COMMODITY_WON_NOTIFICATION(commodityName, commodityQuantity)
	print("Triggered Add Item")
	
	itemTracker = GUTIL:Find(CLItemsTracked, function(itemTracker) return itemTracker.name == commodityName end)
	if itemTracker then
		itemTracker:Add(commodityQuantity)
	else
		itemTracker = CraftLogger.ItemTracker(commodityName, commodityQuantity)
		table.insert(CLItemsTracked, itemTracker)
	end
end

--craftOutput should have all stats set after addition to CraftLoggerDB
function CraftLogger.ValueTracker:TransferCraftValue(craftOutput)
	print("Triggered TransferCraftValue")
end


--TSM_API.GetCustomPriceValue(minBuyoutPriceSourceKey, tsmItemString)
--TSM_API.ToItemString(recipeData.resultData.expectedItem:GetItemLink())