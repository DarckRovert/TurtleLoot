-- TurtleLoot Tooltip Module
-- Add soft reserve and plus one information to item tooltips

local TL = _G.TurtleLoot

TL.Tooltips = {}

-- Initialize tooltip hooks
function TL:InitializeTooltips()
    -- Hook GameTooltip for items
    local originalSetLootItem = GameTooltip.SetLootItem
    GameTooltip.SetLootItem = function(self, slot)
        originalSetLootItem(self, slot)
        TL.Tooltips:AddItemInfo(self, GetLootSlotLink(slot))
    end
    
    local originalSetLootRollItem = GameTooltip.SetLootRollItem
    GameTooltip.SetLootRollItem = function(self, rollID)
        originalSetLootRollItem(self, rollID)
        local _, _, _, _, _, link = GetLootRollItemInfo(rollID)
        TL.Tooltips:AddItemInfo(self, link)
    end
    
    -- Hook for bag items
    local originalSetBagItem = GameTooltip.SetBagItem
    GameTooltip.SetBagItem = function(self, bag, slot)
        originalSetBagItem(self, bag, slot)
        local link = GetContainerItemLink(bag, slot)
        TL.Tooltips:AddItemInfo(self, link)
    end
    
    -- Hook for inventory items
    local originalSetInventoryItem = GameTooltip.SetInventoryItem
    GameTooltip.SetInventoryItem = function(self, unit, slot)
        originalSetInventoryItem(self, unit, slot)
        local link = GetInventoryItemLink(unit, slot)
        TL.Tooltips:AddItemInfo(self, link)
    end
    
    -- Hook for merchant items
    local originalSetMerchantItem = GameTooltip.SetMerchantItem
    GameTooltip.SetMerchantItem = function(self, slot)
        originalSetMerchantItem(self, slot)
        local link = GetMerchantItemLink(slot)
        TL.Tooltips:AddItemInfo(self, link)
    end
    
    -- Hook for hyperlinks (chat links)
    local originalSetHyperlink = GameTooltip.SetHyperlink
    GameTooltip.SetHyperlink = function(self, link)
        originalSetHyperlink(self, link)
        TL.Tooltips:AddItemInfo(self, link)
    end
    
    -- Tooltip hooks initialized
end

-- Add soft reserve and plus one info to tooltip
function TL.Tooltips:AddItemInfo(tooltip, itemLink)
    if not TL or not itemLink then
        return
    end
    
    local itemID = TL:GetItemIDFromLink(itemLink)
    if not itemID then
        return
    end
    
    local addedLines = false
    
    -- Add soft reserve information
    if TL.Settings:Get("softRes.showTooltips") then
        local srLines = TL.SoftRes:GetTooltipLines(itemLink)
        if table.getn(srLines) > 0 then
            if not addedLines then
                tooltip:AddLine(" ") -- Spacer
                addedLines = true
            end
            
            for _, line in ipairs(srLines) do
                tooltip:AddLine(line, 1, 1, 1, true) -- White text, wrap
            end
        end
    end
    
    -- Add plus one information
    if TL.Settings:Get("plusOnes.showTooltips") then
        local p1Lines = TL.PlusOnes:GetTooltipLines(itemLink)
        if table.getn(p1Lines) > 0 then
            if not addedLines then
                tooltip:AddLine(" ") -- Spacer
                addedLines = true
            end
            
            for _, line in ipairs(p1Lines) do
                tooltip:AddLine(line, 1, 1, 1, true) -- White text, wrap
            end
        end
    end
    
    -- Add loot priority information
    if TL.LootPriority and TL.Settings:Get("lootPriority.showTooltips") then
        local priorityLines = TL.LootPriority:GetTooltipLines(itemLink)
        if table.getn(priorityLines) > 0 then
            if not addedLines then
                tooltip:AddLine(" ") -- Spacer
                addedLines = true
            end
            
            for _, line in ipairs(priorityLines) do
                tooltip:AddLine(line, 1, 1, 1, true) -- White text, wrap
            end
        end
    end
    
    -- Add upgrade analysis information
    if TL.UpgradeAnalyzer and TL.Settings:Get("upgradeAnalyzer.showTooltips") then
        local playerName = UnitName("player")
        local upgradeText = TL.UpgradeAnalyzer:GetUpgradeText(itemLink, playerName)
        
        if upgradeText then
            if not addedLines then
                tooltip:AddLine(" ") -- Spacer
                addedLines = true
            end
            
            tooltip:AddLine("For You: " .. upgradeText, 1, 1, 1, true)
        end
        
        -- Show top beneficiaries if raid leader/officer
        if TL and TL.IsRaidLeader and TL.IsRaidOfficer and TL.IsInRaid and TL.IsInParty and (TL:IsRaidLeader() or TL:IsRaidOfficer()) and (TL:IsInRaid() or TL:IsInParty()) then
            local top3 = TL.UpgradeAnalyzer:GetTopBeneficiaries(itemLink)
            
            if table.getn(top3) > 0 then
                if not addedLines then
                    tooltip:AddLine(" ") -- Spacer
                    addedLines = true
                end
                
                tooltip:AddLine("|cff88ff00Top Upgrades:|r", 1, 1, 1)
                
                for i = 1, math.min(3, table.getn(top3)) do
                    local entry = top3[i]
                    local text = string.format("%d. %s (+%d%%)", i, entry.player, math.floor(entry.upgradePercent))
                    tooltip:AddLine(text, 0.7, 0.7, 0.7)
                end
            end
        end
    end
    
    -- Force tooltip to resize
    if addedLines then
        tooltip:Show()
    end
end

-- Helper: Extract item ID from item link
function TL:GetItemIDFromLink(itemLink)
    if not itemLink then
        return nil
    end
    
    local _, _, itemID = string.find(itemLink, "item:(%d+)")
    return tonumber(itemID)
end
