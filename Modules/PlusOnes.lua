-- TurtleLoot Plus Ones Module
-- Track +1 points for players

local TL = _G.TurtleLoot

TL.PlusOnes = {
    data = {} -- playerName -> points
}

-- Initialize function called by bootstrap
function TL.PlusOnes:Initialize()
    TL:InitializePlusOnes()
end

-- Initialize plus ones module
function TL:InitializePlusOnes()
    -- Load data from database
    self.PlusOnes.data = self.DB:Get("plusOnes", {})
    
    -- Listen for whisper commands
    if self.Settings:Get("plusOnes.enableWhisperCommand") then
        self:RegisterGameEvent("CHAT_MSG_WHISPER", function(event, message, sender)
            TL.PlusOnes:HandleWhisperCommand(message, sender)
        end)
    end
    
    -- Listen for incoming data
    self:RegisterEvent("PLUSONE_DATA_RECEIVED", function(data, sender)
        TL.PlusOnes:OnDataReceived(data, sender)
    end)
end

-- Get player's plus ones
function TL.PlusOnes:Get(playerName)
    return self.data[playerName] or TL.Settings:Get("plusOnes.defaultPoints", 0)
end

-- Set player's plus ones
function TL.PlusOnes:Set(playerName, points)
    points = tonumber(points) or 0
    self.data[playerName] = points
    
    -- Save to database
    TL.DB:Set("plusOnes", self.data)
    
    -- Broadcast update if enabled
    if TL.Settings:Get("plusOnes.autoShareData") and TL:IsInGroup() then
        TL.Comm:Send(TL.COMM.TYPES.PLUSONE_UPDATE, {
            player = playerName,
            points = points,
        })
    end
    
    -- Fire event
    TL:FireEvent("PLUSONE_UPDATED", playerName, points)
end

-- Add plus ones to a player
function TL.PlusOnes:Add(playerName, points)
    local current = self:Get(playerName)
    self:Set(playerName, current + points)
end

-- Subtract plus ones from a player
function TL.PlusOnes:Subtract(playerName, points)
    local current = self:Get(playerName)
    self:Set(playerName, math.max(0, current - points))
end

-- Import plus ones data
function TL.PlusOnes:Import(data)
    -- Expected format: playerName,points\nplayerName,points
    
    if not data or data == "" then
        TL:Error("No data to import")
        return false
    end
    
    self.data = {}
    
    -- Parse CSV
    for line in string.gfind(data, "[^\n]+") do
        local _, _, playerName, points = string.find(line, "([^,]+),(%d+)")
        if playerName and points then
            playerName = string.trim(playerName)
            points = tonumber(points)
            self.data[playerName] = points
        end
    end
    
    -- Save to database
    TL.DB:Set("plusOnes", self.data)
    
    TL:Success("Plus ones imported successfully")
    
    -- Broadcast to raid if enabled
    if TL.Settings:Get("plusOnes.autoShareData") and TL:IsInGroup() then
        TL.Comm:BroadcastData(TL.COMM.TYPES.PLUSONE_BROADCAST, self.data)
    end
    
    return true
end

-- Export plus ones data
function TL.PlusOnes:Export()
    local lines = {}
    
    for playerName, points in pairs(self.data) do
        table.insert(lines, playerName .. "," .. points)
    end
    
    return table.concat(lines, "\n")
end

-- Handle whisper command
function TL.PlusOnes:HandleWhisperCommand(message, sender)
    message = string.lower(string.trim(message))
    
    if message == "!p1" or message == "!plusone" or message == "!plusones" then
        local points = self:Get(sender)
        SendChatMessage("You have " .. points .. " plus one(s).", "WHISPER", nil, sender)
    end
end

-- Handle received data
function TL.PlusOnes:OnDataReceived(data, sender)
    TL:Print("Received plus one data from " .. sender)
    -- For now, auto-accept
    self.data = data
    TL.DB:Set("plusOnes", self.data)
end

-- Get all plus ones
function TL.PlusOnes:GetAll()
    return self.data
end

-- Clear all plus ones
function TL.PlusOnes:Clear()
    self.data = {}
    TL.DB:Set("plusOnes", self.data)
    TL:Print("Plus ones cleared")
end

-- Get tooltip lines for an item (shows top +1 holders in raid)
function TL.PlusOnes:GetTooltipLines(itemLink)
    if not TL.Settings:Get("plusOnes.showTooltips") then
        return {}
    end
    
    -- Get all raid members with their +1 counts
    local playersWithPoints = {}
    
    if TL:IsInRaid() then
        for i = 1, GetNumRaidMembers() do
            local name = GetRaidRosterInfo(i)
            if name then
                local points = self:Get(name)
                if points > 0 then
                    table.insert(playersWithPoints, {
                        name = name,
                        points = points
                    })
                end
            end
        end
    elseif TL:IsInParty() then
        -- Add self
        local selfName = TL:GetPlayerName()
        local selfPoints = self:Get(selfName)
        if selfPoints > 0 then
            table.insert(playersWithPoints, {
                name = selfName,
                points = selfPoints
            })
        end
        
        -- Add party members
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name then
                local points = self:Get(name)
                if points > 0 then
                    table.insert(playersWithPoints, {
                        name = name,
                        points = points
                    })
                end
            end
        end
    else
        -- Solo - just show self
        local selfName = TL:GetPlayerName()
        local selfPoints = self:Get(selfName)
        if selfPoints > 0 then
            table.insert(playersWithPoints, {
                name = selfName,
                points = selfPoints
            })
        end
    end
    
    if table.getn(playersWithPoints) == 0 then
        return {}
    end
    
    -- Sort by points descending
    table.sort(playersWithPoints, function(a, b)
        return a.points > b.points
    end)
    
    -- Build tooltip lines (show top 5)
    local lines = {}
    table.insert(lines, "|cff00ff00Plus Ones:|r")
    
    local maxShow = math.min(5, table.getn(playersWithPoints))
    for i = 1, maxShow do
        local player = playersWithPoints[i]
        table.insert(lines, "  " .. player.name .. ": +" .. player.points)
    end
    
    if table.getn(playersWithPoints) > 5 then
        table.insert(lines, "  |cff888888... and " .. (table.getn(playersWithPoints) - 5) .. " more|r")
    end
    
    return lines
end
