-- TurtleLoot Awarded Loot Module
-- Track and manage awarded loot

local TL = _G.TurtleLoot

TL.AwardedLoot = {
    history = {}
}

function TL.AwardedLoot:Initialize()
    TL:InitializeAwardedLoot()
end

-- Initialize awarded loot module
function TL:InitializeAwardedLoot()
    -- Load history from database
    self.AwardedLoot.history = self.DB:Get("awardHistory", {})
    
    -- Listen for trade completion
    self:RegisterGameEvent("TRADE_ACCEPT_UPDATE", function()
        TL.AwardedLoot:OnTradeAccepted()
    end)
    
    -- Listen for master loot
    self:RegisterGameEvent("LOOT_SLOT_CLEARED", function()
        TL.AwardedLoot:OnLootSlotCleared()
    end)
end

-- Award an item to a player
function TL.AwardedLoot:Award(itemLink, playerName, note)
    if not TL:IsValidItemLink(itemLink) then
        TL:Error("Invalid item link")
        return false
    end
    
    if not playerName or playerName == "" then
        TL:Error("Invalid player name")
        return false
    end
    
    -- Create award record
    local award = {
        itemLink = itemLink,
        itemID = TL:GetItemIDFromLink(itemLink),
        player = playerName,
        note = note or "",
        timestamp = TL:GetTimestamp(),
        awardedBy = TL:GetPlayerName(),
    }
    
    -- Add to history
    table.insert(self.history, award)
    
    -- Save to database
    TL.DB:Set("awardHistory", self.history)
    
    -- Announce if enabled
    if TL.Settings:Get("awardLoot.announceAwards") then
        self:AnnounceAward(award)
    end
    
    -- Fire event
    TL:FireEvent("ITEM_AWARDED", award)
    
    -- Auto-trade if enabled
    if TL.Settings:Get("awardLoot.autoTradeAfterAward") then
        self:InitiateTrade(playerName, itemLink)
    end
    
    return true
end

-- Announce award
function TL.AwardedLoot:AnnounceAward(award)
    local message = string.format("%s awarded to %s", award.itemLink, award.player)
    
    if award.note and award.note ~= "" then
        message = message .. " (" .. award.note .. ")"
    end
    
    -- Announce to raid
    if TL.Settings:Get("awardLoot.announceToRaid") and TL:IsInGroup() then
        local channel = TL:IsInRaid() and "RAID" or "PARTY"
        SendChatMessage(message, channel)
    else
        TL:Print(message)
    end
    
    -- Announce to guild
    if TL.Settings:Get("awardLoot.announceToGuild") and IsInGuild() then
        SendChatMessage(message, "GUILD")
    end
end

-- Initiate trade with player
function TL.AwardedLoot:InitiateTrade(playerName, itemLink)
    -- Find player in raid/party
    local unitID = nil
    
    if TL:IsInRaid() then
        for i = 1, GetNumRaidMembers() do
            local name = GetRaidRosterInfo(i)
            if name == playerName then
                unitID = "raid" .. i
                break
            end
        end
    elseif TL:IsInParty() then
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name == playerName then
                unitID = "party" .. i
                break
            end
        end
    end
    
    if unitID then
        InitiateTrade(unitID)
    else
        TL:Warning("Could not find player " .. playerName .. " to trade")
    end
end

-- Handle trade accepted
function TL.AwardedLoot:OnTradeAccepted()
    -- Track traded items
    -- This is called when trade window updates
    local player, target = TradeFramePlayerNameText:GetText(), TradeFrameRecipientNameText:GetText()
    
    if not player or not target then
        return
    end
    
    -- Check if trade is complete (both sides accepted)
    local playerAccepted = TradeFramePlayerEnchantInset:IsShown()
    local targetAccepted = TradeFrameRecipientEnchantInset:IsShown()
    
    if not (playerAccepted and targetAccepted) then
        return
    end
    
    -- Scan player's trade slots for items
    for i = 1, 6 do
        local itemLink = GetTradePlayerItemLink(i)
        if itemLink then
            -- Mark recent awards as delivered
            for j = table.getn(self.history), 1, -1 do
                local award = self.history[j]
                if award.player == target and award.itemLink == itemLink and not award.delivered then
                    award.delivered = true
                    award.deliveredAt = TL:GetTimestamp()
                    TL.DB:Set("awardHistory", self.history)
                    TL:Print(string.format("Marked %s as delivered to %s", itemLink, target))
                    break
                end
            end
        end
    end
end

-- Handle loot slot cleared (master loot)
function TL.AwardedLoot:OnLootSlotCleared()
    -- Track master looted items
    -- This event fires when a loot slot is cleared (item taken)
    -- In Vanilla, we can't easily track WHO got the item from this event alone
    -- We rely on the Award() function being called explicitly
    -- This is just a placeholder for potential future enhancements
end

-- Get award history
function TL.AwardedLoot:GetHistory(limit)
    limit = limit or 50
    local history = {}
    
    local startIndex = math.max(1, table.getn(self.history) - limit + 1)
    for i = startIndex, table.getn(self.history) do
        table.insert(history, self.history[i])
    end
    
    return history
end

-- Get awards for a specific player
function TL.AwardedLoot:GetPlayerHistory(playerName, limit)
    limit = limit or 50
    local history = {}
    
    for i = table.getn(self.history), 1, -1 do
        if self.history[i].player == playerName then
            table.insert(history, self.history[i])
            if table.getn(history) >= limit then
                break
            end
        end
    end
    
    return history
end

-- Clear history
function TL.AwardedLoot:ClearHistory()
    self.history = {}
    TL.DB:Set("awardHistory", self.history)
    TL:Print("Award history cleared")
end

-- Export history to string
function TL.AwardedLoot:Export()
    if table.getn(self.history) == 0 then
        return "No award history to export"
    end
    
    local lines = {}
    table.insert(lines, "TurtleLoot Award History Export")
    table.insert(lines, "Generated: " .. TL:FormatDate(time()))
    table.insert(lines, "Total Awards: " .. table.getn(self.history))
    table.insert(lines, "")
    table.insert(lines, "Player,Item,ItemID,Note,Timestamp,AwardedBy,Delivered")
    
    for i = 1, table.getn(self.history) do
        local award = self.history[i]
        local itemName = TL:GetItemNameFromLink(award.itemLink) or "Unknown"
        local delivered = award.delivered and "Yes" or "No"
        local note = award.note or ""
        
        -- Escape commas in fields
        itemName = string.gsub(itemName, ",", ";")
        note = string.gsub(note, ",", ";")
        
        local line = string.format("%s,%s,%s,%s,%s,%s,%s",
            award.player,
            itemName,
            award.itemID or "",
            note,
            TL:FormatDate(award.timestamp),
            award.awardedBy or "",
            delivered
        )
        
        table.insert(lines, line)
    end
    
    return table.concat(lines, "\n")
end

-- Get statistics
function TL.AwardedLoot:GetStats()
    local stats = {
        totalAwards = table.getn(self.history),
        delivered = 0,
        pending = 0,
        playerCounts = {},
        itemCounts = {},
    }
    
    for i = 1, table.getn(self.history) do
        local award = self.history[i]
        
        -- Count delivered vs pending
        if award.delivered then
            stats.delivered = stats.delivered + 1
        else
            stats.pending = stats.pending + 1
        end
        
        -- Count by player
        stats.playerCounts[award.player] = (stats.playerCounts[award.player] or 0) + 1
        
        -- Count by item
        local itemName = TL:GetItemNameFromLink(award.itemLink) or "Unknown"
        stats.itemCounts[itemName] = (stats.itemCounts[itemName] or 0) + 1
    end
    
    return stats
end
