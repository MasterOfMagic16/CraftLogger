local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

print("ValueTracker Loaded")

CraftLogger.ValueTracker = GUTIL:CreateRegistreeForEvents({ "AUCTION_HOUSE_SHOW_COMMODITY_WON_NOTIFICATION", "TRADE_SKILL_ITEM_CRAFTED_RESULT" })

CLItemsTracked = {}

function CraftLogger.ValueTracker:AUCTION_HOUSE_SHOW_COMMODITY_WON_NOTIFICATION(commodityName, commodityQuantity)
	print("Triggered")
	
	itemTracker = GUTIL:Find(CLItemsTracked, function(itemTracker) return itemTracker.name == commodityName end)
	if itemTracker then
		itemTracker:Add(commodityQuantity)
	else
		itemTracker = CraftLogger.ItemTracker(commodityName, commodityQuantity)
		table.insert(CLItemsTracked, itemTracker)
	end
end