-- TurtleLoot Helper Functions
-- Utility functions used throughout the addon

local TL = _G.TurtleLoot

-- Debug: Confirm Helpers loaded
DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TurtleLoot]|r Helpers.lua loaded")

-- Print a message to chat
function TL:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. self.COLORS.PRIMARY .. "TurtleLoot:|r " .. tostring(msg))
end

-- Print a colored message
function TL:ColoredPrint(color, msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. self.COLORS.PRIMARY .. "TurtleLoot:|r |cff" .. color .. tostring(msg) .. "|r")
end

-- Print a warning
function TL:Warning(msg)
    self:ColoredPrint(self.COLORS.WARNING, msg)
end

-- Print an error
function TL:Error(msg)
    self:ColoredPrint(self.COLORS.ERROR, msg)
end

-- Print a success message
function TL:Success(msg)
    self:ColoredPrint(self.COLORS.SUCCESS, msg)
end

-- Check if a value is empty (nil, empty string, or empty table)
function TL:IsEmpty(value)
    if value == nil then return true end
    if type(value) == "string" and value == "" then return true end
    if type(value) == "table" then
        for _ in pairs(value) do
            return false
        end
        return true
    end
    return false
end

-- Deep copy a table
function TL:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[TL:DeepCopy(orig_key)] = TL:DeepCopy(orig_value)
        end
        setmetatable(copy, TL:DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Round a number to specified decimal places
function TL:Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Check if player is in a raid
function TL:IsInRaid()
    return GetNumRaidMembers() > 0
end

-- Check if player is in a party
function TL:IsInParty()
    return GetNumPartyMembers() > 0
end

-- Check if player is in a group (raid or party)
function TL:IsInGroup()
    return self:IsInRaid() or self:IsInParty()
end

-- Get the player's name
function TL:GetPlayerName()
    return UnitName("player")
end

-- Normalize player name (remove server, lowercase)
function TL:NormalizePlayerName(name)
    if not name then return "" end
    name = string.gsub(name, "%-.*", "") -- Remove server name
    return string.lower(name)
end

-- Check if player is master looter
function TL:IsMasterLooter()
    local lootMethod, masterLooterPartyID, masterLooterRaidID = GetLootMethod()
    if lootMethod ~= "master" then return false end
    
    if self:IsInRaid() then
        if masterLooterRaidID then
            local name = GetRaidRosterInfo(masterLooterRaidID)
            return name == self:GetPlayerName()
        end
    else
        if masterLooterPartyID == 0 then
            return true
        end
    end
    return false
end

-- Validate item link
function TL:IsValidItemLink(itemLink)
    if not itemLink then return false end
    local _, _, itemID = string.find(itemLink, "item:(%d+)")
    return itemID ~= nil
end

-- Extract item ID from item link
function TL:GetItemIDFromLink(itemLink)
    if not itemLink then return nil end
    local _, _, itemID = string.find(itemLink, "item:(%d+)")
    return tonumber(itemID)
end

-- Get item quality from item link
function TL:GetItemQuality(itemLink)
    if not self:IsValidItemLink(itemLink) then return 0 end
    local _, _, quality = GetItemInfo(itemLink)
    return quality or 0
end

-- Get item quality color
function TL:GetQualityColor(quality)
    return self.COLORS.QUALITY[quality] or self.COLORS.QUALITY[1]
end

-- Format gold amount
function TL:FormatGold(copper)
    if not copper or copper == 0 then return "0g" end
    
    local gold = math.floor(copper / 10000)
    local silver = math.floor(mod(copper, 10000) / 100)
    local copperRemainder = mod(copper, 100)
    
    local result = ""
    if gold > 0 then
        result = result .. gold .. "g"
    end
    if silver > 0 then
        if result ~= "" then
            result = result .. " "
        end
        result = result .. silver .. "s"
    end
    if copperRemainder > 0 or result == "" then
        if result ~= "" then
            result = result .. " "
        end
        result = result .. copperRemainder .. "c"
    end
    
    return result
end

-- Get current timestamp
function TL:GetTimestamp()
    return time()
end

-- Parse CSV line
function TL:ParseCSV(line)
    local fields = {}
    local fieldStart = 1
    local inQuotes = false
    
    for i = 1, string.len(line) do
        local char = string.sub(line, i, i)
        
        if char == '"' then
            inQuotes = not inQuotes
        elseif char == ',' and not inQuotes then
            local field = string.sub(line, fieldStart, i - 1)
            -- Remove quotes
            field = string.gsub(field, '"', '')
            table.insert(fields, field)
            fieldStart = i + 1
        end
    end
    
    -- Add last field
    local field = string.sub(line, fieldStart)
    field = string.gsub(field, '"', '')
    table.insert(fields, field)
    
    return fields
end

-- Validate item link
function TL:ValidateItemLink(link)
    if not link then return false end
    local _, _, itemId = string.find(link, "item:(%d+)")
    return itemId ~= nil
end

-- Get player class
function TL:GetPlayerClass(name)
    if not name then return nil end
    
    -- Check if in raid
    for i = 1, 40 do
        local raidName, _, _, _, class = GetRaidRosterInfo(i)
        if raidName == name then
            return class
        end
    end
    
    -- Check if in party
    for i = 1, 4 do
        local partyName = UnitName("party" .. i)
        if partyName == name then
            local _, class = UnitClass("party" .. i)
            return class
        end
    end
    
    -- Check if it's the player
    if name == UnitName("player") then
        local _, class = UnitClass("player")
        return class
    end
    
    return nil
end

-- Duplicate function removed - already defined at line 70

-- Get raid roster
function TL:GetRaidRoster()
    local roster = {}
    
    if self:IsInRaid() then
        for i = 1, 40 do
            local name, rank, subgroup, _, class = GetRaidRosterInfo(i)
            if name then
                table.insert(roster, {
                    name = name,
                    rank = rank,
                    subgroup = subgroup,
                    class = class
                })
            end
        end
    else
        -- Solo player
        local name = UnitName("player")
        local _, class = UnitClass("player")
        table.insert(roster, {
            name = name,
            rank = 2,
            subgroup = 1,
            class = class
        })
    end
    
    return roster
end

-- Format timestamp to readable date
function TL:FormatDate(timestamp)
    -- Vanilla WoW doesn't have date() function, use simple format
    if not timestamp then timestamp = time() end
    -- Just return the timestamp as string for now
    -- In Vanilla WoW, we don't have date formatting
    return "Session " .. tostring(timestamp)
end

-- Check if a value is in a table
function TL:InTable(table, value)
    for _, v in pairs(table) do
        if v == value then return true end
    end
    return false
end

-- Get table size
function TL:TableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Merge two tables
function TL:MergeTables(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            TL:MergeTables(t1[k], v)
        else
            t1[k] = v
        end
    end
    return t1
end

-- Schedule a timer (simple implementation for vanilla)
function TL:ScheduleTimer(delay, callback)
    local frame = CreateFrame("Frame")
    local elapsed = 0
    frame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= delay then
            frame:SetScript("OnUpdate", nil)
            callback()
        end
    end)
    return frame
end

-- Show roll window (placeholder)
function TL:ShowRollWindow()
    -- Placeholder - will be implemented in UI
end

-- Show master looter dialog (placeholder)
function TL:ShowMasterLooterDialog()
    -- Placeholder - will be implemented in UI
end

-- Get item name from link
function TL:GetItemNameFromLink(itemLink)
    if not itemLink then return nil end
    
    -- Extract item name from link: |cffffffff|Hitem:12345:0:0:0|h[Item Name]|h|r
    local _, _, itemName = string.find(itemLink, "%[(.-)%]")
    return itemName
end

-- Check if player has soft reserve
function TL:HasReserve(playerName, itemID)
    if not playerName or not itemID then return false end
    if not self.SoftRes or not self.SoftRes.GetReserves then return false end
    
    local reserves = self.SoftRes:GetReserves(itemID)
    if not reserves then return false end
    
    for _, name in ipairs(reserves) do
        if name == playerName then
            return true
        end
    end
    return false
end

-- Get item link from ID
function TL:GetItemLinkFromID(itemID)
    if not itemID then return nil end
    
    -- Try to get the actual item link from cache
    local itemName, itemLink = GetItemInfo(itemID)
    if itemLink then
        return itemLink
    end
    
    -- If not in cache, create a proper itemLink format that WoW can understand
    -- Format: |cffXXXXXX|Hitem:ITEMID:0:0:0|h[Item Name]|h|r
    -- Since we don't have the item cached, use a gray color and generic name
    return "|cff9d9d9d|Hitem:" .. itemID .. ":0:0:0|h[Item:" .. itemID .. "]|h|r"
end
