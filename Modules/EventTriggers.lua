--[[





]]

local CraftLogger = select(2, ...)

local systemPrint = print

local GUTIL = CraftLogger.GUTIL

CraftLogger.EventTriggers = GUTIL:CreateRegistreeForEvents({})


--[[
Events:

What I would like to track:
*Buys
*Sells
*Crafts
*Other things that change money

Everything else is superfluous right now

With each, I want:
Inputs (including wealth)
Outputs (including wealth)
Time

]]