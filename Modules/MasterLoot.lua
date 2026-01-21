-- TurtleLoot Master Loot Module
-- Enhanced master looting interface

local TL = _G.TurtleLoot

TL.MasterLoot = {
    active = false,
    currentLoot = {}
}

function TL.MasterLoot:Initialize()
    TL:InitializeMasterLoot()
end

-- Initialize master loot module
function TL:InitializeMasterLoot()
    -- Listen for loot events
    self:RegisterGameEvent("LOOT_OPENED", function()
        TL.MasterLoot:OnLootOpened()
    end)
    
    self:RegisterGameEvent("LOOT_CLOSED", function()
        TL.MasterLoot:OnLootClosed()
    end)
    
    self:RegisterGameEvent("LOOT_SLOT_CLEARED", function()
        TL.MasterLoot:OnLootSlotCleared(arg1)
    end)
end

-- Handle loot window opened
function TL.MasterLoot:OnLootOpened()
    if not TL:IsMasterLooter() then
        return
    end
    
    self.active = true
    self.currentLoot = {}
    
    -- Get minimum quality threshold from settings
    local minQuality = TL.Settings:Get("awardLoot.minimumQuality", 3) -- Default: Rare (blue)
    
    -- Get all loot items
    local numLoot = GetNumLootItems()
    local itemsAboveThreshold = {}
    
    for slot = 1, numLoot do
        local lootIcon, lootName, lootQuantity, rarity = GetLootSlotInfo(slot)
        local itemLink = GetLootSlotLink(slot)
        
        if itemLink then
            local itemID = TL:GetItemIDFromLink(itemLink)
            local quality = rarity or TL:GetItemQuality(itemLink)
            
            -- Check for soft reserves
            local reserves = {}
            local hasReserves = false
            if TL.SoftRes then
                reserves = TL.SoftRes:GetReserves(itemLink) or {}
                hasReserves = table.getn(reserves) > 0
            end
            
            -- Add to current loot list
            table.insert(self.currentLoot, {
                slot = slot,
                itemLink = itemLink,
                itemID = itemID,
                quality = quality,
                quantity = lootQuantity or 1,
                icon = lootIcon,
                name = lootName,
                reserves = reserves,
                hasReserves = hasReserves,
            })
            
            -- Track items above quality threshold
            if quality >= minQuality then
                table.insert(itemsAboveThreshold, {
                    slot = slot,
                    itemLink = itemLink,
                    itemID = itemID,
                    quality = quality,
                    quantity = lootQuantity or 1,
                    icon = lootIcon,
                    name = lootName,
                    reserves = reserves,
                    hasReserves = hasReserves,
                })
            end
            
            -- Announce reserved items
            if hasReserves and TL.Settings:Get("softRes.announceReservedLoot", true) then
                self:AnnounceReservedItem(itemLink, reserves)
            end
            
            -- Announce priority suggestion
            if TL.LootPriority and TL.Settings:Get("lootPriority.announceTopPriority", true) then
                if quality >= minQuality then
                    TL.LootPriority:AnnounceSuggestion(itemLink)
                end
            end
        end
    end
    
    -- Auto-open dialog for items above threshold
    if table.getn(itemsAboveThreshold) > 0 then
        -- Announce items to raid if configured
        if TL.Settings:Get("awardLoot.announceLoot", true) then
            self:AnnounceLoot(itemsAboveThreshold)
        end
        
        -- Auto-open dialog if enabled
        if TL.Settings:Get("masterLoot.autoOpenDialog", true) then
            local distributionMethod = TL.Settings:Get("awardLoot.defaultMethod", "roll")
            local firstItem = itemsAboveThreshold[1]
            
            if distributionMethod == "roll" then
                -- Start roll for first item
                if TL.RollOff then
                    TL.RollOff:Start(firstItem.itemLink)
                end
            elseif distributionMethod == "manual" then
                -- Open award dialog
                if TL.AwardDialog then
                    TL.AwardDialog:Show(firstItem.itemLink)
                end
            end
        end
    end
    
    -- Fire event
    TL:FireEvent("MASTER_LOOT_OPENED", self.currentLoot, itemsAboveThreshold)
end

-- Handle loot window closed
function TL.MasterLoot:OnLootClosed()
    self.active = false
    self.currentLoot = {}
    
    TL:FireEvent("MASTER_LOOT_CLOSED")
end

-- Handle loot slot cleared
function TL.MasterLoot:OnLootSlotCleared(slot)
    -- Remove from current loot
    for i, loot in ipairs(self.currentLoot) do
        if loot.slot == slot then
            table.remove(self.currentLoot, i)
            break
        end
    end
end

-- Give item to player
function TL.MasterLoot:GiveItem(slot, playerName)
    if not self.active then
        TL:Error("No loot window is open")
        return false
    end
    
    -- Find candidate index
    local candidateIndex = nil
    for i = 1, 40 do -- Max 40 players in raid
        local candidate = GetMasterLootCandidate(slot, i)
        if candidate == playerName then
            candidateIndex = i
            break
        end
    end
    
    if not candidateIndex then
        TL:Error("Player " .. playerName .. " is not a valid loot candidate")
        return false
    end
    
    -- Give loot
    GiveMasterLoot(slot, candidateIndex)
    
    -- Get item info for the slot
    local itemLink = GetLootSlotLink(slot)
    
    -- Fire event
    TL:FireEvent("ITEM_MASTER_LOOTED", playerName, itemLink)
    
    return true
end

-- Get current loot
function TL.MasterLoot:GetCurrentLoot()
    return self.currentLoot
end

-- Check if master looting is active
function TL.MasterLoot:IsActive()
    return self.active
end

-- Announce loot to raid
function TL.MasterLoot:AnnounceLoot(items)
    if not TL:IsInGroup() then
        return
    end
    
    local channel = TL:IsInRaid() and "RAID" or "PARTY"
    
    for _, item in ipairs(items) do
        local message = "Loot: " .. item.itemLink
        if item.quantity > 1 then
            message = message .. " x" .. item.quantity
        end
        SendChatMessage(message, channel)
    end
end

-- Announce reserved item
function TL.MasterLoot:AnnounceReservedItem(itemLink, reserves)
    if not TL:IsInGroup() then
        return
    end
    
    local channel = TL:IsInRaid() and "RAID" or "PARTY"
    local numReserves = table.getn(reserves)
    
    if numReserves == 1 then
        local message = itemLink .. " reserved by " .. reserves[1]
        SendChatMessage(message, channel)
    elseif numReserves > 1 then
        local playerList = table.concat(reserves, ", ")
        local message = itemLink .. " reserved by " .. playerList
        SendChatMessage(message, channel)
    end
end

-- Award item to reserver (if only one reserve)
function TL.MasterLoot:AwardToReserver(slot)
    if not self.active then
        TL:Error("No loot window is open")
        return false
    end
    
    -- Find the item in current loot
    local lootItem = nil
    for _, item in ipairs(self.currentLoot) do
        if item.slot == slot then
            lootItem = item
            break
        end
    end
    
    if not lootItem then
        TL:Error("Item not found in loot")
        return false
    end
    
    if not lootItem.hasReserves then
        TL:Error("Item has no reserves")
        return false
    end
    
    local numReserves = table.getn(lootItem.reserves)
    
    if numReserves == 1 then
        -- Single reserve, award directly
        local playerName = lootItem.reserves[1]
        return self:GiveItem(slot, playerName)
    else
        -- Multiple reserves, need to decide
        TL:Print("Item has multiple reserves: " .. table.concat(lootItem.reserves, ", "))
        return false
    end
end

-- Placeholder for master looter dialog
function TL:ShowMasterLooterDialog()
    -- Will be implemented in UI file
end
