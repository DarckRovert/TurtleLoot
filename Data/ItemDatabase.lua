-- TurtleLoot Item Database
-- Handles item lookups and caching

local TL = TurtleLoot

TL.ItemDB = {
    cache = {},
    pendingCallbacks = {}
}

local ItemDB = TL.ItemDB

-- Get item info (with caching)
function ItemDB:GetItemInfo(itemLink)
    if not itemLink then return nil end
    
    -- Extract item ID from link
    local itemId = self:GetItemIdFromLink(itemLink)
    if not itemId then return nil end
    
    -- Check cache
    if self.cache[itemId] then
        return self.cache[itemId]
    end
    
    -- Get from WoW API
    local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture = GetItemInfo(itemLink)
    
    if name then
        local itemData = {
            id = itemId,
            name = name,
            link = link,
            quality = quality,
            itemLevel = iLevel,
            reqLevel = reqLevel,
            class = class,
            subclass = subclass,
            maxStack = maxStack,
            equipSlot = equipSlot,
            texture = texture
        }
        
        self.cache[itemId] = itemData
        return itemData
    end
    
    return nil
end

-- Get item ID from link
function ItemDB:GetItemIdFromLink(itemLink)
    if not itemLink then return nil end
    
    local _, _, itemId = string.find(itemLink, "item:(%d+)")
    return tonumber(itemId)
end

-- Get item link from ID
function ItemDB:GetItemLinkFromId(itemId)
    return "item:" .. itemId .. ":0:0:0"
end

-- Check if item is cached
function ItemDB:IsItemCached(itemLink)
    local itemId = self:GetItemIdFromLink(itemLink)
    return self.cache[itemId] ~= nil
end

-- Clear cache
function ItemDB:ClearCache()
    self.cache = {}
end

-- Get item quality color
function ItemDB:GetQualityColor(quality)
    local colors = {
        [0] = "|cff9d9d9d", -- Poor (gray)
        [1] = "|cffffffff", -- Common (white)
        [2] = "|cff1eff00", -- Uncommon (green)
        [3] = "|cff0070dd", -- Rare (blue)
        [4] = "|cffa335ee", -- Epic (purple)
        [5] = "|cffff8000", -- Legendary (orange)
    }
    return colors[quality] or "|cffffffff"
end

-- Format item link with color
function ItemDB:FormatItemLink(itemLink)
    local itemData = self:GetItemInfo(itemLink)
    if not itemData then return itemLink end
    
    local color = self:GetQualityColor(itemData.quality)
    return color .. "[" .. itemData.name .. "]|r"
end
