-- TurtleLoot GDKP Module
-- Gold Dragon Kill Points auction system

local TL = _G.TurtleLoot

TL.GDKP = {
    activeSession = nil,
    activeAuction = nil,
    sessions = {},
    bids = {}
}

-- Initialize function called by bootstrap
function TL.GDKP:Initialize()
    TL:InitializeGDKP()
end

-- Initialize GDKP module
function TL:InitializeGDKP()
    -- Load sessions from database
    local dbSessions = self.DB:Get("gdkp.sessions", {})
    self.GDKP.sessions = dbSessions
    
    -- Listen for bid messages (via addon channel)
    TL.Events:Register("COMM_MESSAGE_" .. self.COMM.TYPES.GDKP_BID, function(data, sender)
        TL.GDKP:OnBidReceived(data, sender)
    end)
    
    -- Listen for auction start (via addon channel)
    TL.Events:Register("COMM_MESSAGE_" .. self.COMM.TYPES.GDKP_START, function(data, sender)
        TL.GDKP:OnAuctionStartReceived(data, sender)
    end)
    
    -- Listen for manual bids in chat
    self:RegisterGameEvent("CHAT_MSG_RAID", function(event, message, sender)
        TL.GDKP:HandleChatBid(message, sender)
    end)
    
    self:RegisterGameEvent("CHAT_MSG_RAID_WARNING", function(event, message, sender)
        TL.GDKP:HandleChatBid(message, sender)
    end)
    
    self:RegisterGameEvent("CHAT_MSG_PARTY", function(event, message, sender)
        TL.GDKP:HandleChatBid(message, sender)
    end)
    
    -- Auto-Payout Events
    self:RegisterGameEvent("TRADE_SHOW", function()
        TL.GDKP:OnTradeShow()
    end)
    
    self:RegisterGameEvent("TRADE_CLOSED", function()
        TL.GDKP:OnTradeClosed()
    end)
    
    self:RegisterGameEvent("CHAT_MSG_SYSTEM", function(event, message)
        TL.GDKP:OnSystemMessage(message)
    end)
end

-- Create a new session
function TL.GDKP:CreateSession(name)
    local session = {
        id = TL:GetTimestamp(),
        name = name or "GDKP Session",
        created = TL:GetTimestamp(),
        createdBy = TL:GetPlayerName(),
        auctions = {},
        pot = 0,
        raiders = {}
    }
    
    table.insert(self.sessions, session)
    self.activeSession = session
    
    -- Save to database
    TL.DB:Set("gdkp.sessions", self.sessions)
    
    TL:Success("GDKP session created: " .. name)
    
    return session
end

-- Start an auction
function TL.GDKP:StartAuction(itemLink, minBid, increment, duration)
    if not self.activeSession then
        TL:Error("No active GDKP session. Create one first.")
        return false
    end
    
    if self.activeAuction then
        TL:Warning("An auction is already in progress")
        return false
    end
    
    if not TL:IsValidItemLink(itemLink) then
        TL:Error("Invalid item link")
        return false
    end
    
    minBid = minBid or TL.Settings:Get("gdkp.defaultMinBid", 100)
    increment = increment or TL.Settings:Get("gdkp.defaultIncrement", 50)
    duration = duration or TL.Settings:Get("gdkp.defaultAuctionTime", 30)
    
    -- Create auction
    self.activeAuction = {
        itemLink = itemLink,
        itemID = TL:GetItemIDFromLink(itemLink),
        minBid = minBid,
        increment = increment,
        duration = duration,
        startTime = GetTime(),
        endTime = GetTime() + duration,
        auctioneer = TL:GetPlayerName(),
        currentBid = 0,
        currentBidder = nil,
        antiSnipeTime = TL.Settings:Get("gdkp.antiSnipeTime", 10),
    }
    
    self.bids = {}
    
    -- Announce auction start
    if TL.Settings:Get("gdkp.announceStart") then
        self:AnnounceAuctionStart()
    end
    
    -- Broadcast to raid
    if TL:IsInGroup() then
        TL.Comm:Send(TL.COMM.TYPES.GDKP_START, {
            itemLink = itemLink,
            minBid = minBid,
            increment = increment,
            duration = duration,
        })
    end
    
    -- Schedule auction end
    TL:ScheduleTimer(duration, function()
        TL.GDKP:EndAuction()
    end)
    
    -- Fire event
    TL:FireEvent("GDKP_AUCTION_START", self.activeAuction)
    
    return true
end

-- Place a bid
function TL.GDKP:PlaceBid(amount, playerName)
    if not self.activeAuction then
        TL:Error("No active auction")
        return false
    end
    
    playerName = playerName or TL:GetPlayerName()
    amount = tonumber(amount)
    
    if not amount then
        TL:Error("Invalid bid amount")
        return false
    end
    
    -- Check minimum bid
    local minRequired = math.max(self.activeAuction.minBid, self.activeAuction.currentBid + self.activeAuction.increment)
    
    if amount < minRequired then
        TL:Warning("Bid too low. Minimum: " .. TL:FormatGold(minRequired * 10000))
        return false
    end
    
    -- Update current bid
    self.activeAuction.currentBid = amount
    self.activeAuction.currentBidder = playerName
    
    -- Record bid
    table.insert(self.bids, {
        player = playerName,
        amount = amount,
        timestamp = GetTime(),
    })
    
    -- Anti-snipe: extend auction if bid is near end
    local timeLeft = self.activeAuction.endTime - GetTime()
    if timeLeft < self.activeAuction.antiSnipeTime then
        self.activeAuction.endTime = GetTime() + self.activeAuction.antiSnipeTime
    end
    
    -- Announce new bid
    if TL.Settings:Get("gdkp.announceNewBid") then
        self:AnnounceNewBid(playerName, amount)
    end
    
    -- Broadcast bid
    if TL:IsInGroup() then
        TL.Comm:Send(TL.COMM.TYPES.GDKP_BID, {
            player = playerName,
            amount = amount,
        })
    end
    
    -- Fire event
    TL:FireEvent("GDKP_BID_UPDATE", {
        amount = amount,
        bidder = playerName,
        endTime = self.activeAuction.endTime
    })
    
    return true
end

-- End the auction
function TL.GDKP:EndAuction()
    if not self.activeAuction then
        return
    end
    
    local winner = self.activeAuction.currentBidder
    local amount = self.activeAuction.currentBid
    
    -- Add to session
    table.insert(self.activeSession.auctions, {
        itemLink = self.activeAuction.itemLink,
        itemID = self.activeAuction.itemID,
        winner = winner,
        amount = amount,
        timestamp = TL:GetTimestamp(),
        bids = self.bids,
    })
    
    -- Update pot
    if winner and amount > 0 then
        self.activeSession.pot = self.activeSession.pot + amount
    end
    
    -- Save session
    TL.DB:Set("gdkp.sessions", self.sessions)
    
    -- Announce end
    if TL.Settings:Get("gdkp.announceEnd") then
        self:AnnounceAuctionEnd(winner, amount)
    end
    
    -- Fire event
    TL:FireEvent("GDKP_AUCTION_END", self.activeAuction, winner, amount)
    
    -- Clear active auction
    self.activeAuction = nil
    self.bids = {}
end

-- Announce auction start
function TL.GDKP:AnnounceAuctionStart()
    local channel = TL.Settings:Get("gdkp.announceToRaid") and (TL:IsInRaid() and "RAID" or "PARTY") or nil
    local message = string.format("Auction: %s - Min bid: %s, Increment: %s",
        self.activeAuction.itemLink,
        TL:FormatGold(self.activeAuction.minBid * 10000),
        TL:FormatGold(self.activeAuction.increment * 10000)
    )
    
    if channel and TL:IsInGroup() then
        SendChatMessage(message, channel)
    else
        TL:Print(message)
    end
end

-- Announce new bid
function TL.GDKP:AnnounceNewBid(playerName, amount)
    local channel = TL.Settings:Get("gdkp.announceToRaid") and (TL:IsInRaid() and "RAID" or "PARTY") or nil
    local message = string.format("%s bid %s", playerName, TL:FormatGold(amount * 10000))
    
    if channel and TL:IsInGroup() then
        SendChatMessage(message, channel)
    else
        TL:Print(message)
    end
end

-- Announce auction end
function TL.GDKP:AnnounceAuctionEnd(winner, amount)
    local channel = TL.Settings:Get("gdkp.announceToRaid") and (TL:IsInRaid() and "RAID" or "PARTY") or nil
    local message
    
    if winner and amount > 0 then
        message = string.format("%s won %s for %s",
            winner,
            self.activeAuction.itemLink,
            TL:FormatGold(amount * 10000)
        )
    else
        message = string.format("No bids for %s", self.activeAuction.itemLink)
    end
    
    if channel and TL:IsInGroup() then
        SendChatMessage(message, channel)
    else
        TL:Print(message)
    end
end

-- Handle received bid
function TL.GDKP:OnBidReceived(data, sender)
    -- Update auction with received bid
    if self.activeAuction then
        TL:FireEvent("GDKP_BID_RECEIVED", data, sender)
    end
end

-- Handle received auction start
function TL.GDKP:OnAuctionStartReceived(data, sender)
    TL:FireEvent("GDKP_AUCTION_START_RECEIVED", data, sender)
    
    -- Auto-join session logic could go here
    if not self.activeSession then
        self.activeAuction = data
        TL:Print("Joined GDKP auction for " .. (data.itemLink or "Unknown Item"))
    end
end

-- Handle manual chat bids
function TL.GDKP:HandleChatBid(message, sender)
    -- Only accept if we are the auctioneer
    if not self.activeAuction or self.activeAuction.auctioneer ~= TL:GetPlayerName() then
        return
    end
    
    -- Simple parsing: look for numbers
    local amount = nil
    
    -- Check for "bid 50" pattern
    local _, _, bidAmount = string.find(string.lower(message), "bid%s+(%d+)")
    if bidAmount then
        amount = tonumber(bidAmount)
    else
        -- Check for just numbers "50" or "50g"
        local _, _, justNum = string.find(message, "^%s*(%d+)g?%s*$")
        if justNum then
            amount = tonumber(justNum)
        end
    end
    
    if amount then
        -- Validate and place bid
        if amount > self.activeAuction.currentBid then
            self:PlaceBid(amount, sender)
        end
    end
end

-- Get active session
function TL.GDKP:GetActiveSession()
    return self.activeSession
end

-- Get all sessions
function TL.GDKP:GetSessions()
    return self.sessions
end

-- Distribute gold to raiders
function TL.GDKP:DistributeGold()
    if not self.activeSession then
        TL:Error("No active GDKP session")
        return false
    end
    
    local pot = self.activeSession.pot
    if pot <= 0 then
        TL:Warning("No gold in pot to distribute")
        return false
    end
    
    -- Get raiders (from raid roster or session raiders)
    local raiders = {}
    if TL:IsInRaid() then
        for i = 1, GetNumRaidMembers() do
            local name = GetRaidRosterInfo(i)
            if name then
                table.insert(raiders, name)
            end
        end
    elseif TL:IsInParty() then
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name then
                table.insert(raiders, name)
            end
        end
        table.insert(raiders, UnitName("player"))
    else
        TL:Error("Not in a group")
        return false
    end
    
    -- Calculate cuts
    local numRaiders = table.getn(raiders)
    if numRaiders == 0 then
        TL:Error("No raiders found")
        return false
    end
    
    -- Get cut percentage (default 100% = full split)
    local cutPercent = TL.Settings:Get("gdkp.cutPercent", 100)
    local distributablePot = math.floor(pot * cutPercent / 100)
    local cutPerPerson = math.floor(distributablePot / numRaiders)
    
    -- Store distribution info
    self.activeSession.distribution = {
        timestamp = TL:GetTimestamp(),
        pot = pot,
        cutPercent = cutPercent,
        distributablePot = distributablePot,
        numRaiders = numRaiders,
        cutPerPerson = cutPerPerson,
        raiders = {},
    }
    
    -- Record each raider's cut
    for i = 1, table.getn(raiders) do
        local raider = raiders[i]
        table.insert(self.activeSession.distribution.raiders, {
            name = raider,
            cut = cutPerPerson,
            paid = false,
        })
    end
    
    -- Save session
    TL.DB:Set("gdkp.sessions", self.sessions)
    
    -- Announce distribution
    if TL.Settings:Get("gdkp.announceDistribution") then
        local channel = TL:IsInRaid() and "RAID" or "PARTY"
        local message = string.format("GDKP Distribution: %s per person (%d raiders, %d%% of %s pot)",
            TL:FormatGold(cutPerPerson * 10000),
            numRaiders,
            cutPercent,
            TL:FormatGold(pot * 10000)
        )
        SendChatMessage(message, channel)
    end
    
    -- Fire event
    TL:FireEvent("GDKP_DISTRIBUTION_CALCULATED", self.activeSession.distribution)
    
    TL:Success(string.format("Distribution calculated: %s per person", TL:FormatGold(cutPerPerson * 10000)))
    
    return true
end

-- Mark a raider as paid
function TL.GDKP:MarkPaid(raiderName)
    if not self.activeSession or not self.activeSession.distribution then
        TL:Error("No distribution calculated")
        return false
    end
    
    for i = 1, table.getn(self.activeSession.distribution.raiders) do
        local raider = self.activeSession.distribution.raiders[i]
        if raider.name == raiderName then
            raider.paid = true
            raider.paidAt = TL:GetTimestamp()
            
            -- Save session
            TL.DB:Set("gdkp.sessions", self.sessions)
            
            TL:Success(raiderName .. " marked as paid")
            TL:FireEvent("GDKP_RAIDER_PAID", raiderName)
            return true
        end
    end
    
    TL:Warning("Raider not found: " .. raiderName)
    return false
end

-- Get distribution status
function TL.GDKP:GetDistributionStatus()
    if not self.activeSession or not self.activeSession.distribution then
        return nil
    end
    
    local dist = self.activeSession.distribution
    local paid = 0
    local unpaid = 0
    
    for i = 1, table.getn(dist.raiders) do
        if dist.raiders[i].paid then
            paid = paid + 1
        else
            unpaid = unpaid + 1
        end
    end
    
    return {
        total = dist.numRaiders,
        paid = paid,
        unpaid = unpaid,
        cutPerPerson = dist.cutPerPerson,
        totalDistributed = paid * dist.cutPerPerson,
        totalRemaining = unpaid * dist.cutPerPerson,
    }
end

-- Close active session
function TL.GDKP:CloseSession()
    if not self.activeSession then
        TL:Warning("No active session to close")
        return false
    end
    
    self.activeSession.closed = true
    self.activeSession.closedAt = TL:GetTimestamp()
    
    -- Save session
    TL.DB:Set("gdkp.sessions", self.sessions)
    
    TL:Success("GDKP session closed: " .. self.activeSession.name)
    
    -- Fire event
    TL:FireEvent("GDKP_SESSION_CLOSED", self.activeSession)
    
    self.activeSession = nil
    
    return true
end

-- Export session to string
function TL.GDKP:ExportSession(sessionID)
    local session = nil
    
    if sessionID then
        -- Find session by ID
        for i = 1, table.getn(self.sessions) do
            if self.sessions[i].id == sessionID then
                session = self.sessions[i]
                break
            end
        end
    else
        session = self.activeSession
    end
    
    if not session then
        TL:Error("Session not found")
        return nil
    end
    
    -- Build CSV export
    local lines = {}
    
    -- Header
    table.insert(lines, "TurtleLoot GDKP Export")
    table.insert(lines, "Session: " .. session.name)
    table.insert(lines, "Created: " .. TL:FormatDate(session.created))
    table.insert(lines, "Created By: " .. session.createdBy)
    table.insert(lines, "Total Pot: " .. TL:FormatGold(session.pot * 10000))
    table.insert(lines, "")
    
    -- Auctions
    table.insert(lines, "Item,Winner,Amount,Timestamp")
    for i = 1, table.getn(session.auctions) do
        local auction = session.auctions[i]
        local itemName = auction.itemLink and string.gsub(auction.itemLink, "%[(.-)%]", "%1") or "Unknown"
        local winner = auction.winner or "No bids"
        local amount = auction.amount or 0
        local timestamp = TL:FormatDate(auction.timestamp)
        
        table.insert(lines, string.format("%s,%s,%s,%s",
            itemName,
            winner,
            TL:FormatGold(amount * 10000),
            timestamp
        ))
    end
    
    -- Distribution
    if session.distribution then
        table.insert(lines, "")
        table.insert(lines, "Distribution")
        table.insert(lines, "Raider,Cut,Paid")
        
        for i = 1, table.getn(session.distribution.raiders) do
            local raider = session.distribution.raiders[i]
            table.insert(lines, string.format("%s,%s,%s",
                raider.name,
                TL:FormatGold(raider.cut * 10000),
                raider.paid and "Yes" or "No"
            ))
        end
    end
    
    return table.concat(lines, "\n")
end

-- Auto-Payout Logic
function TL.GDKP:OnTradeShow()
    if not self.activeSession or not self.activeSession.distribution then return end
    
    local target = UnitName("target")
    if not target or not UnitIsPlayer("target") then return end
    
    -- Check if target is a raider who needs payment
    for _, raider in ipairs(self.activeSession.distribution.raiders) do
        if raider.name == target and not raider.paid then
            -- Found unpaid raider!
            self.currentTradeTarget = target
            
            -- Calculate amount in copper
            local amount = raider.cut * 10000
            
            -- Check if we have enough money
            if GetMoney() >= amount then
                SetTradeMoney(amount)
                TL:Print("Auto-Payout: Offered " .. TL:FormatGold(amount) .. " to " .. target)
            else
                TL:Warning("Not enough gold to pay " .. target .. " (Need " .. TL:FormatGold(amount) .. ")")
            end
            break
        end
    end
end

function TL.GDKP:OnTradeClosed()
    -- Keep target for a moment to catch the system message
    TL:ScheduleTimer(1, function()
        TL.GDKP.currentTradeTarget = nil
    end)
end

function TL.GDKP:OnSystemMessage(message)
    if message == ERR_TRADE_COMPLETE then
        if self.currentTradeTarget then
            self:MarkPaid(self.currentTradeTarget)
            self.currentTradeTarget = nil
        end
    end
end
