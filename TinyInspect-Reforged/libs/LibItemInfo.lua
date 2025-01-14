
local MAJOR, MINOR = "LibItemInfo.7000", 6
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end

local locale = GetLocale()

local ItemLevelPattern = gsub(ITEM_LEVEL, "%%d", "(%%d+)")
local ItemLevelPlusPat = gsub(ITEM_LEVEL_PLUS, "%%d%+", "(%%d+%%+)")

local tooltip = CreateFrame("GameTooltip", "LibItemLevelTooltip1", UIParent, "GameTooltipTemplate")
local unittip = CreateFrame("GameTooltip", "LibItemLevelTooltip2", UIParent, "GameTooltipTemplate")

function lib:HasLocalCached(item)
    if (not item or item == "" or item == "0") then return true end
    if (tonumber(item)) then
        return select(10, GetItemInfo(tonumber(item)))
    else
        local id, gem1, gem2, gem3 = string.match(item, "item:(%d+):[^:]*:(%d-):(%d-):(%d-):")
        return self:HasLocalCached(id) and self:HasLocalCached(gem1) and self:HasLocalCached(gem2) and self:HasLocalCached(gem3)
    end
end

function lib:GetStatsViaTooltip(tip, stats)
    if (type(stats) == "table") then
        local line, text, r, g, b, statValue, statName
        for i = 2, tip:NumLines() do
            line = _G[tip:GetName().."TextLeft" .. i]
            text = line:GetText() or ""
            r, g, b = line:GetTextColor()
            for statValue, statName in string.gmatch(text, "%+([0-9,]+)([^%+%|]+)") do
                statName = strtrim(statName)
                statName = statName:gsub("與$", "") --zhTW
                statName = statName:gsub("和$", "") --zhTW
                statName = statName:gsub("，", "")  --zhCN
                statName = statName:gsub("%s*&$", "") --enUS
                statValue = statValue:gsub(",","")
                statValue = tonumber(statValue) or 0
                if (not stats[statName]) then
                    stats[statName] = { value = statValue, r = r, g = g, b = b }
                else
                    stats[statName].value = stats[statName].value + statValue
                    if (g > stats[statName].g) then
                        stats[statName].r = r
                        stats[statName].g = g
                        stats[statName].b = b
                    end
                end
            end
        end
    end
    return stats
end

-- koKR
if (locale == "koKR") then
    function lib:GetStatsViaTooltip(tip, stats)
        if (type(stats) == "table") then
            local line, text, r, g, b, statValue, statName
            for i = 2, tip:NumLines() do
                line = _G[tip:GetName().."TextLeft" .. i]
                text = line:GetText() or ""
                r, g, b = line:GetTextColor()
                for statName, statValue in string.gmatch(text, "([^%+]+)%+([0-9,]+)") do
                    statName = statName:gsub("|c%x%x%x%x%x%x%x%x", "")
                    statName = statName:gsub(".-:", "")
                    statName = strtrim(statName)
                    statName = statName:gsub("%s*/%s*", "")
                    statValue = statValue:gsub(",","")
                    statValue = tonumber(statValue) or 0
                    if (not stats[statName]) then
                        stats[statName] = { value = statValue, r = r, g = g, b = b }
                    else
                        stats[statName].value = stats[statName].value + statValue
                        if (g > stats[statName].g) then
                            stats[statName].r = r
                            stats[statName].g = g
                            stats[statName].b = b
                        end
                    end
                end
            end
        end
        return stats
    end
end

function lib:GetItemInfo(link, stats, withoutExtra)
    return self:GetItemInfoViaTooltip(link, stats, withoutExtra)
end

function lib:GetItemInfoViaTooltip(link, stats)
    if (not link or link == "") then
        return 0, 0
    end
    if (not string.match(link, "item:%d+:")) then
        return 1, -1
    end
    if (not self:HasLocalCached(link)) then
        return 1, 0
    end
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetHyperlink(link)
    local text, level
    for i = 2, 5 do
        if (_G[tooltip:GetName().."TextLeft" .. i]) then
            text = _G[tooltip:GetName().."TextLeft" .. i]:GetText() or ""
            level = string.match(text, ItemLevelPattern)
            if (level) then break end
            level = string.match(text, ItemLevelPlusPat)
            if (level) then break end
        end
    end
    self:GetStatsViaTooltip(tooltip, stats)
    if (level and string.find(level, "+")) then else
        level = tonumber(level) or 0
    end
    if (withoutExtra) then
        return 0, level
    else
        return 0, level, GetItemInfo(link)
    end
end

function lib:GetContainerItemLevel(pid, id)
    if (pid < 0) then
        local link = GetContainerItemLink(pid, id)
        return self:GetItemInfo(link)
    end
    local text, level
    if (pid and id) then
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:SetBagItem(pid, id)
        for i = 2, 5 do
            if (_G[tooltip:GetName().."TextLeft" .. i]) then
                text = _G[tooltip:GetName().."TextLeft" .. i]:GetText() or ""
                level = string.match(text, ItemLevelPattern)
                if (level) then break end
            end
        end
    end
    return 0, tonumber(level) or 0
end

DKS_ItemNumber = {
	[1] = "HeadSlot",
	[2] = "NeckSlot",
	[3] = "ShoulderSlot",
	[4] = "ShirtSlot",
	[5] = "ChestSlot",
	[6] = "WaistSlot",
	[7] = "LegsSlot",
	[8] = "FeetSlot",
	[9] = "WristSlot",
	[10] = "HandsSlot",
	[11] = "Finger0Slot",
	[12] = "Finger1Slot",
	[13] = "Trinket0Slot",
	[14] = "Trinket1Slot",
	[15] = "BackSlot",
	[16] = "MainHandSlot",
	[17] = "SecondaryHandSlot",
	[18] = "RangedSlot"
}


function lib:GetUnitItemInfo(unit, index, stats)
    if (not UnitExists(unit)) then return 1, -1 end  --C_PaperDollInfo.GetInspectItemLevel
    unittip:SetOwner(UIParent, "ANCHOR_NONE")
	
	index = DKS_ItemNumber[index]
	index = GetInventorySlotInfo(index)
	
    unittip:SetInventoryItem(unit, index)
    local link = GetInventoryItemLink(unit, index) or select(2, unittip:GetItem())
    if (not link or link == "") then
		local link = GetInventoryItemLink(unit, index)
        return 0, 0
    end
    if (not self:HasLocalCached(link)) then
        return 1, 0
    end
    local text, level
    for i = 2, 5 do
        if (_G[unittip:GetName().."TextLeft" .. i]) then
            text = _G[unittip:GetName().."TextLeft" .. i]:GetText() or ""
            level = string.match(text, ItemLevelPattern)
            if (level) then break end
        end
    end
	
	local itemId = GetInventoryItemLink(unit, index)
    if (not itemId) then return 1, 0 end
    _, link2, _, level,_,_,_,_,_,_,_, classID,_ = GetItemInfo(itemId)
	
    self:GetStatsViaTooltip(unittip, stats)
    if (string.match(link, "item:(%d+):")) then
        return 0, tonumber(level) or 0, GetItemInfo(link)
    else
        local line = _G[unittip:GetName().."TextLeft1"]
        local r, g, b = line:GetTextColor()
        local name = ("|cff%.2x%.2x%.2x%s|r"):format((r or 1)*255, (g or 1)*255, (b or 1)*255, line:GetText() or "")
        return 0, tonumber(level) or 0, name
    end
end

function lib:GetUnitItemLevel(unit, stats)
    local total, counts, maxlevel = 0, 0, 0
    local _, count, level
    for i = 1, 18 do
        if (i ~= 4) then  
            count, level = self:GetUnitItemInfo(unit, i, stats)
            counts = counts + count
            total = total + level            
            maxlevel = max(maxlevel, level)
        end
    end
    local mcount, mlevel, mquality, mslot, ocount, olevel, oquality, oslot
    mcount, mlevel, _, _, mquality, _, _, _, _, _, mslot = self:GetUnitItemInfo(unit, 16, stats)
    ocount, olevel, _, _, oquality, _, _, _, _, _, oslot = self:GetUnitItemInfo(unit, 17, stats)
--    rcount, rlevel, _, _, rquality, _, _, _, _, _, rslot = self:GetUnitItemInfo(unit, 18, stats)
--    counts = counts + mcount + ocount + rcount
--    if (mquality == 6 or oquality == 6) then
--        total = total + max(mlevel, olevel) * 2
--    elseif (oslot == "INVTYPE_2HWEAPON" or mslot == "INVTYPE_2HWEAPON" or mslot == "INVTYPE_RANGED" or mslot == "INVTYPE_RANGEDRIGHT") then 
--        total = total + max(mlevel, olevel) * 2
--    else
--        total = total + mlevel + olevel + rlevel
--    end
--    maxlevel = max(maxlevel, mlevel, olevel, rlevel)
--    return counts, total/max(16-counts,1), total, max(mlevel,olevel), (mquality == 6 or oquality == 6), maxlevel

   
    -- get the counts of missing items
    local tv, v = 0, 0
    for i = 1, 18 do
        if (i ~= 4) then
          local link = GetInventoryItemLink(unit, i)
          if (not link) then
              tv = tv + 1
          end 
        end     
    end
    return counts, total/max(17-tv,1), total, max(mlevel,olevel), (mquality == 6 or oquality == 6), maxlevel
end

function lib:GetQuestItemlink(questType, id)
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetQuestLogItem(questType, id)
    return select(2, tooltip:GetItem()) or GetQuestLogItemLink(questType, id)
end
