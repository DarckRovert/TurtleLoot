-- TurtleLoot Atlas-TW Integration
-- Integration with Atlas-TW addon for instance loot data

local TL = _G.TurtleLoot

TL.AtlasIntegration = {
    enabled = false,
    instances = {}
}

-- Initialize function called by bootstrap
function TL.AtlasIntegration:Initialize()
    TL:InitializeAtlasIntegration()
end

-- Initialize Atlas integration
function TL:InitializeAtlasIntegration()
    -- Initial check
    if _G.AtlasTW and _G.AtlasTW.InstanceData then
         self:Success("Atlas-TW detected immediately.")
         TL.AtlasIntegration:EnableIntegration()
         return
    end

    -- Delay caching to ensure all instance data is loaded
    -- Atlas-TW loads instance files after ADDON_LOADED variables
    local retries = 0
    local callback
    callback = function()
        if _G.AtlasTW and _G.AtlasTW.InstanceData then
             TL.AtlasIntegration:EnableIntegration()
             TL.Events:UnregisterGameEvent("PLAYER_ENTERING_WORLD", callback)
        else
             retries = retries + 1
             if retries > 5 then
                 TL:Print("Atlas-TW integration failed: Data not found after 5 retries.")
                 TL.Events:UnregisterGameEvent("PLAYER_ENTERING_WORLD", callback)
             end
        end
    end
    
    self.Events:RegisterGameEvent("PLAYER_ENTERING_WORLD", callback)
end

function TL.AtlasIntegration:EnableIntegration()
    self.enabled = true
    self:CacheInstances()
    TL:Success("Atlas-TW integration enabled and data cached!")
    
    -- Diagnostic Probe: Print what we found to help user debug missing dungeons
    if _G.AtlasTW and _G.AtlasTW.InstanceData then
        local count = 0
        local typesFound = {}
        for k, v in pairs(_G.AtlasTW.InstanceData) do
            count = count + 1
            if v.Type then typesFound[v.Type] = (typesFound[v.Type] or 0) + 1 end
        end
        TL:Print("DEBUG: AtlasTW has " .. count .. " total entries.")
        for typeName, num in pairs(typesFound) do
             TL:Print("DEBUG: Found Type '" .. tostring(typeName) .. "': " .. num .. " entries")
        end
    end
end

-- Cache available instances from Atlas-TW
function TL.AtlasIntegration:CacheInstances()
    if not _G.AtlasTW or not _G.AtlasTW.InstanceData then
        return
    end
    
    self.instances = {}
    
    -- Debug: Count total instances
    local totalCount = 0
    local addedCount = 0
    
    for key, data in pairs(_G.AtlasTW.InstanceData) do
        totalCount = totalCount + 1
        
        -- More flexible filtering - just need a Name
        if data.Name then
            -- Handle level (can be a number or a table with min/max)
            local levelStr = "??"
            if type(data.Level) == "number" then
                levelStr = tostring(data.Level)
            elseif type(data.Level) == "table" then
                if data.Level.min and data.Level.max then
                    levelStr = data.Level.min .. "-" .. data.Level.max
                elseif data.Level[1] and data.Level[2] then
                    levelStr = data.Level[1] .. "-" .. data.Level[2]
                end
            end
            
            table.insert(self.instances, {
                key = key,
                name = data.Name,
                level = levelStr,
                acronym = data.Acronym or "",
                maxPlayers = data.MaxPlayers or 5,
            })
            addedCount = addedCount + 1
        end
    end
    
    TL:Print("Atlas-TW: Found " .. totalCount .. " total instances, added " .. addedCount .. " to list")
    TL:Print("BEFORE SORT: table.getn=" .. table.getn(self.instances))
    
    -- Sort by level and name
    table.sort(self.instances, function(a, b)
        if a.level == b.level then
            return a.name < b.name
        end
        return a.level < b.level
    end)
    
    TL:Print("AFTER SORT: table.getn=" .. table.getn(self.instances))
    TL:Print("First 3 after sort: " .. (self.instances[1] and self.instances[1].name or "nil") .. ", " .. (self.instances[2] and self.instances[2].name or "nil") .. ", " .. (self.instances[3] and self.instances[3].name or "nil"))
end

-- Get list of instances
function TL.AtlasIntegration:GetInstances()
    return self.instances
end

-- Get instance data by key
function TL.AtlasIntegration:GetInstance(key)
    if not _G.AtlasTW or not _G.AtlasTW.InstanceData then
        return nil
    end
    
    return _G.AtlasTW.InstanceData[key]
end

-- Get all loot from an instance
function TL.AtlasIntegration:GetInstanceLoot(instanceKey)
    local instance = self:GetInstance(instanceKey)
    if not instance or not instance.Bosses then
        return {}
    end
    
    -- Validate that Bosses is a table
    if type(instance.Bosses) ~= "table" then
        TL:Print("Error: instance.Bosses is not a table for " .. tostring(instanceKey))
        return {}
    end
    
    local allLoot = {}
    local seenItems = {}
    
    -- Iterate through all bosses
    for _, boss in ipairs(instance.Bosses) do
        -- Validate boss is a table
        if type(boss) == "table" then
            -- Atlas-TW uses 'items' not 'loot' after initialization
            local lootTable = boss.items or boss.loot
            if lootTable and type(lootTable) == "table" then
                for _, item in ipairs(lootTable) do
                    if type(item) == "table" then
                        local itemID = item.id or item[1]
                        if itemID and not seenItems[itemID] then
                            table.insert(allLoot, {
                                itemID = itemID,
                                boss = boss.name,
                                dropRate = item.dropRate or item[2],
                            })
                            seenItems[itemID] = true
                        end
                    end
                end
            end
        end
    end
    
    return allLoot
end

-- Get loot filtered by quality
function TL.AtlasIntegration:GetInstanceLootByQuality(instanceKey, minQuality)
    local allLoot = self:GetInstanceLoot(instanceKey)
    local filtered = {}
    
    for _, lootData in ipairs(allLoot) do
        -- Try to get item info from cache
        local itemName, itemLink, itemQuality = GetItemInfo(lootData.itemID)
        
        -- If item is in cache, filter by quality
        if itemQuality then
            if itemQuality >= minQuality then
                table.insert(filtered, lootData)
            end
        else
            -- If not in cache, include it anyway (can't determine quality)
            -- This prevents missing items that aren't cached yet
            table.insert(filtered, lootData)
        end
    end
    
    return filtered
end

-- Generate soft reserve CSV from instance
function TL.AtlasIntegration:GenerateSoftResCSV(instanceKey, minQuality)
    minQuality = minQuality or 3 -- Default: Rare (Blue)
    
    local loot = self:GetInstanceLootByQuality(instanceKey, minQuality)
    local lines = {}
    local itemList = {}
    
    for _, lootData in ipairs(loot) do
        -- Format: itemID (no players yet)
        if lootData and lootData.itemID then
            table.insert(lines, tostring(lootData.itemID))
            table.insert(itemList, lootData.itemID)
        end
    end
    
    if table.getn(lines) == 0 then
        return "-- No items found for this instance\n-- This could mean the instance has no loot data in Atlas-TW", {}
    end
    
    -- Broadcast item list to raid if leader
    if TL.SoftRes and TL.SoftRes.isLeader and TL:IsInGroup() then
        TL.SoftRes:BroadcastItemList(itemList)
    end
    
    return table.concat(lines, "\n"), itemList
end

-- Get boss list for an instance
function TL.AtlasIntegration:GetBossList(instanceKey)
    local instance = self:GetInstance(instanceKey)
    if not instance or not instance.Bosses then
        return {}
    end
    
    local bosses = {}
    for _, boss in ipairs(instance.Bosses) do
        table.insert(bosses, {
            id = boss.id,
            name = boss.name,
            prefix = boss.prefix,
        })
    end
    
    return bosses
end

-- Get loot for a specific boss
function TL.AtlasIntegration:GetBossLoot(instanceKey, bossId)
    local instance = self:GetInstance(instanceKey)
    if not instance or not instance.Bosses then
        return {}
    end
    
    for _, boss in ipairs(instance.Bosses) do
        if boss.id == bossId then
            local loot = {}
            if boss.loot then
                for _, item in ipairs(boss.loot) do
                    if item.id then
                        table.insert(loot, {
                            itemID = item.id,
                            dropRate = item.dropRate,
                        })
                    end
                end
            end
            return loot
        end
    end
    
    return {}
end

-- Check if Atlas-TW is available
function TL.AtlasIntegration:IsAvailable()
    return self.enabled
end
