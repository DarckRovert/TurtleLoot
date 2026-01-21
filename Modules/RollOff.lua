-- TurtleLoot Roll-Off Module
-- Manage roll-offs for loot

local TL = _G.TurtleLoot

TL.RollOff = {
    active = false,
    currentRoll = nil,
    rolls = {}
}

function TL.RollOff:Initialize()
    TL:InitializeRollOff()
end

-- Initialize roll-off module
function TL:InitializeRollOff()
    -- Listen for chat messages (rolls)
    self:RegisterGameEvent("CHAT_MSG_SYSTEM", function(event, message)
        TL.RollOff:OnSystemMessage(message)
    end)
end

-- Start a roll-off
function TL.RollOff:Start(itemLink, duration, note)
    if self.active then
        TL:Warning("A roll is already in progress")
        return false
    end
    
    if not TL:IsValidItemLink(itemLink) then
        TL:Error("Invalid item link")
        return false
    end
    
    duration = duration or TL.Settings:Get("masterLoot.defaultRollTime", 30)
    note = note or TL.Settings:Get("masterLoot.defaultRollNote", "/roll for MS or /roll 99 for OS")
    
    -- Create roll data
    self.currentRoll = {
        itemLink = itemLink,
        itemID = TL:GetItemIDFromLink(itemLink),
        duration = duration,
        note = note,
        startTime = GetTime(),
        endTime = GetTime() + duration,
        initiator = TL:GetPlayerName(),
    }
    
    self.rolls = {}
    self.active = true
    
    -- Announce roll start
    if TL.Settings:Get("masterLoot.announceRollStart") then
        self:AnnounceStart()
    end
    
    -- Show roll window
    if TL.Settings:Get("rollTracking.showRollWindow") then
        TL:ShowRollWindow()
    end
    
    -- Schedule roll end
    TL:ScheduleTimer(duration, function()
        TL.RollOff:End()
    end)
    
    -- Fire event
    TL:FireEvent("ROLL_STARTED", self.currentRoll)
    
    return true
end

-- End the roll-off
function TL.RollOff:End()
    if not self.active then
        return
    end
    
    self.active = false
    
    -- Announce roll end
    if TL.Settings:Get("masterLoot.announceRollEnd") then
        self:AnnounceEnd()
    end
    
    -- Determine winner
    local winner = self:DetermineWinner()
    
    -- Fire event
    TL:FireEvent("ROLL_ENDED", self.currentRoll, self.rolls, winner)
    
    -- Save to history
    self:SaveToHistory()
    
    return winner
end

-- Announce roll start
function TL.RollOff:AnnounceStart()
    local channel = TL:IsInRaid() and "RAID_WARNING" or "PARTY"
    local message = string.format("Roll for %s - %s", self.currentRoll.itemLink, self.currentRoll.note)
    
    if TL:IsInGroup() then
        SendChatMessage(message, channel)
    end
end

-- Announce roll end
function TL.RollOff:AnnounceEnd()
    local winner = self:DetermineWinner()
    
    if winner then
        local channel = TL:IsInRaid() and "RAID" or "PARTY"
        local message = string.format("%s won %s with a roll of %d", 
            winner.player, self.currentRoll.itemLink, winner.roll)
        
        if TL:IsInGroup() then
            SendChatMessage(message, channel)
        end
    end
end

-- Handle system message (roll detection)
function TL.RollOff:OnSystemMessage(message)
    if not self.active then
        return
    end
    
    -- Parse roll: "PlayerName rolls 45 (1-100)"
    local _, _, player, roll, minRoll, maxRoll = string.find(message, "(.+) rolls (%d+) %((%d+)%-(%d+)%)")
    
    if player and roll then
        roll = tonumber(roll)
        minRoll = tonumber(minRoll)
        maxRoll = tonumber(maxRoll)
        
        -- Record the roll
        self:RecordRoll(player, roll, minRoll, maxRoll)
    end
end

-- Record a player's roll
function TL.RollOff:RecordRoll(player, roll, minRoll, maxRoll)
    -- Check if player already rolled
    for _, r in ipairs(self.rolls) do
        if r.player == player then
            TL:Warning(player .. " already rolled (" .. r.roll .. ")")
            return
        end
    end
    
    -- Determine bracket (MS/OS)
    local bracket = "MS"
    if maxRoll == 99 then
        bracket = "OS"
    end
    
    -- Check soft reserve
    local hasSoftRes = false
    if TL.SoftRes and self.currentRoll then
        hasSoftRes = TL.SoftRes:HasReserve(player, self.currentRoll.itemID)
    end
    
    -- Get plus ones
    local plusOnes = 0
    if TL.PlusOnes then
        plusOnes = TL.PlusOnes:Get(player)
    end
    
    -- Add roll
    local rollData = {
        player = player,
        roll = roll,
        minRoll = minRoll,
        maxRoll = maxRoll,
        bracket = bracket,
        timestamp = GetTime(),
        hasSoftRes = hasSoftRes,
        plusOnes = plusOnes,
    }
    
    table.insert(self.rolls, rollData)
    
    -- Fire event
    TL:FireEvent("ROLL_RECORDED", rollData)
    
    -- Update roll window
    TL:UpdateRollWindow()
end

-- Determine the winner
function TL.RollOff:DetermineWinner()
    if table.getn(self.rolls) == 0 then
        return nil
    end
    
    -- Enrich rolls with SR and +1 data
    for _, rollData in ipairs(self.rolls) do
        -- Check if player has soft reserve for this item
        if TL.SoftRes then
            rollData.hasSoftRes = TL.SoftRes:HasReserve(rollData.player, self.currentRoll.itemID)
        else
            rollData.hasSoftRes = false
        end
        
        -- Get player's plus ones
        if TL.PlusOnes then
            rollData.plusOnes = TL.PlusOnes:Get(rollData.player)
        else
            rollData.plusOnes = 0
        end
    end
    
    -- Sort by priority:
    -- 1. Soft Reserve (if enabled)
    -- 2. Bracket (MS > OS)
    -- 3. Plus Ones (higher = better)
    -- 4. Roll value (higher = better)
    table.sort(self.rolls, function(a, b)
        -- Priority 1: Soft Reserve
        if TL.Settings:Get("rollOff.softResPriority", true) then
            if a.hasSoftRes ~= b.hasSoftRes then
                return a.hasSoftRes -- SR wins
            end
        end
        
        -- Priority 2: Bracket (MS vs OS)
        if a.bracket ~= b.bracket then
            return a.bracket == "MS" -- MS has priority
        end
        
        -- Priority 3: Plus Ones (if enabled)
        if TL.Settings:Get("rollOff.plusOneBonus", true) then
            if a.plusOnes ~= b.plusOnes then
                return a.plusOnes > b.plusOnes
            end
        end
        
        -- Priority 4: Roll value
        return a.roll > b.roll
    end)
    
    return self.rolls[1]
end

-- Save roll to history
function TL.RollOff:SaveToHistory()
    local history = TL.DB:Get("rollHistory", {})
    
    table.insert(history, {
        roll = self.currentRoll,
        rolls = self.rolls,
        winner = self:DetermineWinner(),
        timestamp = TL:GetTimestamp(),
    })
    
    TL.DB:Set("rollHistory", history)
end

-- Update roll window with current rolls
function TL:UpdateRollWindow()
    if TL.RollWindow and TL.RollWindow.frame and TL.RollWindow.frame:IsVisible() then
        -- Fire event to update the window
        TL:FireEvent("ROLL_WINDOW_UPDATE", TL.RollOff.rolls)
    end
end
