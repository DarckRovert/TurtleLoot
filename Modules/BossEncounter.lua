-- TurtleLoot Boss Encounter Module
-- Announcements of Soft Reserves when pulling bosses

local TL = _G.TurtleLoot

TL.BossEncounter = {
    lastAnnouncedBoss = nil,
    lastAnnouncedTime = 0
}

function TL.BossEncounter:Initialize()
    TL:InitializeBossEncounter()
end

function TL:InitializeBossEncounter()
    -- Combat start listener
    self:RegisterGameEvent("PLAYER_REGEN_DISABLED", function()
        TL.BossEncounter:OnCombatStart()
    end)
end

function TL.BossEncounter:OnCombatStart()
    if not TL.Settings:Get("softRes.announceReservedLoot") then return end
    
    local targetName = UnitName("target")
    if not targetName then return end
    
    -- Anti-spam check (don't announce same boss twice in 2 mins)
    if self.lastAnnouncedBoss == targetName and (GetTime() - self.lastAnnouncedTime < 120) then
        return
    end
    
    -- Check if target is significant (Elite, World Boss, Rare Elite)
    local classification = UnitClassification("target")
    if classification == "normal" or classification == "minus" then return end
    
    -- Verify Atlas is ready
    if not TL.AtlasIntegration or not TL.AtlasIntegration:IsAvailable() then
        return
    end
    
    -- Find Boss in Atlas Data
    local bossLoot = self:FindBossLoot(targetName)
    if not bossLoot or table.getn(bossLoot) == 0 then return end
    
    -- Filter loot for reserves
    local reservedItems = {}
    for _, item in ipairs(bossLoot) do
        local itemID = item.itemID
        if TL.SoftRes and TL.SoftRes.reserves[itemID] then
            local reserves = TL.SoftRes.reserves[itemID]
            if table.getn(reserves) > 0 then
                local itemName = GetItemInfo(itemID) or ("Item #"..itemID)
                table.insert(reservedItems, {
                    name = itemName,
                    reserves = reserves
                })
            end
        end
    end
    
    -- Announce
    if table.getn(reservedItems) > 0 then
        self:AnnounceReserves(targetName, reservedItems)
        self.lastAnnouncedBoss = targetName
        self.lastAnnouncedTime = GetTime()
    end
end

function TL.BossEncounter:FindBossLoot(bossName)
    local instances = TL.AtlasIntegration:GetInstances()
    for _, instance in ipairs(instances) do
        local bosses = TL.AtlasIntegration:GetBossList(instance.key)
        if bosses then
            for _, boss in ipairs(bosses) do
                if boss.name == bossName then
                    -- Found boss!
                    return TL.AtlasIntegration:GetBossLoot(instance.key, boss.id)
                end
            end
        end
    end
    return nil
end

function TL.BossEncounter:AnnounceReserves(bossName, items)
    TL:Print("--- RESERVAS PARA " .. string.upper(bossName) .. " ---")
    local channel = TL:IsInRaid() and "RAID_WARNING" or "PARTY"
    
    SendChatMessage("--- RESERVAS: " .. bossName .. " ---", channel)
    
    for _, item in ipairs(items) do
        local names = table.concat(item.reserves, ", ")
        SendChatMessage(item.name .. ": " .. names, channel)
    end
end
