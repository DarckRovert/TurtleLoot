-- TurtleLoot Communication
-- Addon communication system for raid-wide data sync

local TL = _G.TurtleLoot

-- Communication constants
TL.COMM = TL.COMM or {}
TL.COMM.PREFIX = "TL"
TL.COMM.VERSION = 1
TL.COMM.TYPES = {
    SOFTRES_BROADCAST = "SOFTRES_BROADCAST",
    SOFTRES_LIST_BROADCAST = "SOFTRES_LIST_BROADCAST", -- Added
    SOFTRES_RESERVE_ADD = "SOFTRES_RESERVE_ADD",       -- Added
    SOFTRES_RESERVE_REMOVE = "SOFTRES_RESERVE_REMOVE", -- Added
    SOFTRES_CLEAR = "SOFTRES_CLEAR",                   -- Added
    PLUSONE_BROADCAST = "PLUSONE_BROADCAST",
    GDKP_BID = "GDKP_BID",
    GDKP_START = "GDKP_START",                         -- Added
    ROLL_START = "ROLL_START"
}

TL.Comm = {
    messageQueue = {},
    throttleDelay = 0.5, -- seconds between messages
    lastSendTime = 0,
    processing = false,
    
    -- Auto-sync improvements
    syncStatus = {
        softReserves = false,
        lootHistory = false,
        wishlists = false,
        lootCouncil = false,
        priorities = false
    },
    lastSyncTime = {},
    syncInterval = 300, -- 5 minutes
    checksums = {},
    compressionEnabled = true,
    reconnectHandling = true
}

-- Initialize function called by bootstrap
function TL.Comm:Initialize()
    TL:InitializeCommunication()
end

-- Initialize communication system
function TL:InitializeCommunication()
    -- In Vanilla WoW, we don't need to register addon message prefix
    -- RegisterAddonMessagePrefix only exists in TBC+
    
    -- Listen for addon messages
    self:RegisterGameEvent("CHAT_MSG_ADDON", function(event, prefix, message, channel, sender)
        if prefix == TL.COMM.PREFIX then
            TL.Comm:HandleMessage(message, channel, sender)
        end
    end)
    
    -- Create throttle processing frame
    if not TL.Comm.throttleFrame then
        TL.Comm.throttleFrame = CreateFrame("Frame")
        TL.Comm.throttleFrame:SetScript("OnUpdate", function()
            TL.Comm:ProcessQueue()
        end)
    end
    
    -- Auto-sync timer
    if not TL.Comm.syncFrame then
        TL.Comm.syncFrame = CreateFrame("Frame")
        TL.Comm.syncFrame.elapsed = 0
        TL.Comm.syncFrame:SetScript("OnUpdate", function()
            this.elapsed = this.elapsed + arg1
            if this.elapsed >= 30 then -- Check every 30 seconds
                TL.Comm:AutoSync()
                this.elapsed = 0
            end
        end)
    end
    
    -- Handle reconnections
    if TL.Comm.reconnectHandling then
        self:RegisterGameEvent("PLAYER_ENTERING_WORLD", function()
            TL.Comm:OnReconnect()
        end)
    end
end  -- Cierra InitializeCommunication

-- Send a message to the raid/party (with throttling)
function TL.Comm:Send(messageType, data, target, priority)
    local message = self:Encode(messageType, data)
    
    if not message then
        TL:Error("Failed to encode message")
        return
    end
    
    -- Determine channel
    local channel = "RAID"
    if not TL:IsInRaid() then
        if TL:IsInParty() then
            channel = "PARTY"
        else
            TL:Warning("Not in a group, cannot send message")
            return
        end
    end
    
    -- Add to queue with priority (default = 5, higher = more important)
    priority = priority or 5
    
    table.insert(self.messageQueue, {
        message = message,
        channel = target and "WHISPER" or channel,
        target = target,
        priority = priority,
        timestamp = GetTime()
    })
    
    -- Sort queue by priority (higher first)
    table.sort(self.messageQueue, function(a, b)
        return a.priority > b.priority
    end)
end

-- Encode a message
function TL.Comm:Encode(messageType, data)
    -- Simple encoding: VERSION:TYPE:DATA
    local encoded = TL.COMM.VERSION .. ":" .. messageType .. ":"
    
    if type(data) == "table" then
        -- Simple table serialization (can be improved with proper serialization library)
        encoded = encoded .. self:SerializeTable(data)
    else
        encoded = encoded .. tostring(data or "")
    end
    
    return encoded
end

-- Decode a message
function TL.Comm:Decode(message)
    local version, messageType, data = string.match(message, "^(%d+):([^:]+):(.*)$")
    
    if not version or not messageType then
        return nil
    end
    
    version = tonumber(version)
    
    -- Check version compatibility
    if version ~= TL.COMM.VERSION then
        TL:Warning("Received message with incompatible version: " .. version)
        return nil
    end
    
    -- Try to deserialize if it looks like a table
    if data and string.sub(data, 1, 1) == "{" then
        local deserializedData = self:DeserializeTable(data)
        if deserializedData then
            return messageType, deserializedData
        end
    end
    
    return messageType, data
end

-- Handle incoming message
function TL.Comm:HandleMessage(message, channel, sender)
    local messageType, data = self:Decode(message)
    
    if not messageType then
        return
    end
    
    -- Fire event for message type
    TL:FireEvent("COMM_MESSAGE_" .. messageType, data, sender, channel)
    
    -- Handle specific message types
    if messageType == TL.COMM.TYPES.SOFTRES_BROADCAST then
        TL:FireEvent("SOFTRES_DATA_RECEIVED", data, sender)
    elseif messageType == TL.COMM.TYPES.PLUSONE_BROADCAST then
        TL:FireEvent("PLUSONE_DATA_RECEIVED", data, sender)
    elseif messageType == TL.COMM.TYPES.GDKP_BID then
        TL:FireEvent("GDKP_BID_RECEIVED", data, sender)
    elseif messageType == TL.COMM.TYPES.ROLL_START then
        TL:FireEvent("ROLL_START_RECEIVED", data, sender)
    elseif messageType == "VERSION_CHECK" then
        TL.Comm:HandleVersionCheck(data, sender)
    -- Handle sync messages
    elseif string.find(messageType, "_SYNC$") then
        TL.Comm:HandleSyncData(messageType, data, sender)
    end
end

-- Advanced table serialization (Lua 5.0 compatible)
-- Handles nested tables, strings with special characters, numbers, booleans, nil
function TL.Comm:SerializeTable(tbl, depth)
    depth = depth or 0
    
    -- Prevent infinite recursion
    if depth > 10 then
        return "{}"
    end
    
    local result = {}
    
    for k, v in pairs(tbl) do
        local key = self:SerializeValue(k)
        local value = self:SerializeValue(v, depth)
        table.insert(result, "[" .. key .. "]=" .. value)
    end
    
    return "{" .. table.concat(result, ",") .. "}"
end

-- Serialize a single value
function TL.Comm:SerializeValue(val, depth)
    local valType = type(val)
    
    if valType == "table" then
        return self:SerializeTable(val, (depth or 0) + 1)
    elseif valType == "string" then
        -- Escape special characters: \ " , = [ ] { }
        local escaped = string.gsub(val, "\\", "\\\\")
        escaped = string.gsub(escaped, "\"", "\\\"")
        escaped = string.gsub(escaped, ",", "\\,")
        escaped = string.gsub(escaped, "=", "\\=")
        escaped = string.gsub(escaped, "%[", "\\[")
        escaped = string.gsub(escaped, "%]", "\\]")
        escaped = string.gsub(escaped, "{", "\\{")
        escaped = string.gsub(escaped, "}", "\\}")
        return "\"" .. escaped .. "\""
    elseif valType == "number" then
        return tostring(val)
    elseif valType == "boolean" then
        return val and "true" or "false"
    elseif valType == "nil" then
        return "nil"
    else
        -- Unknown type, convert to string
        return "\"" .. tostring(val) .. "\""
    end
end

-- Deserialize a table from string (Lua 5.0 compatible)
function TL.Comm:DeserializeTable(str)
    if not str or str == "" then
        return nil
    end
    
    -- Remove outer braces
    if string.sub(str, 1, 1) == "{" and string.sub(str, -1) == "}" then
        str = string.sub(str, 2, -2)
    end
    
    if str == "" then
        return {}
    end
    
    local result = {}
    local pos = 1
    
    while pos <= string.len(str) do
        -- Parse key
        local keyStart, keyEnd, key = string.find(str, "^%[(.-)%]=", pos)
        if not keyStart then
            break
        end
        
        pos = keyEnd + 1
        
        -- Parse value
        local value, newPos = self:DeserializeValue(str, pos)
        
        if not newPos then
            break
        end
        
        -- Unescape key
        key = self:UnescapeString(key)
        
        -- Convert key if it's a number
        local numKey = tonumber(key)
        if numKey then
            key = numKey
        end
        
        result[key] = value
        pos = newPos
        
        -- Skip comma
        if string.sub(str, pos, pos) == "," then
            pos = pos + 1
        end
    end
    
    return result
end

-- Deserialize a single value
function TL.Comm:DeserializeValue(str, pos)
    local char = string.sub(str, pos, pos)
    
    -- Table
    if char == "{" then
        local depth = 1
        local endPos = pos + 1
        
        while endPos <= string.len(str) and depth > 0 do
            local c = string.sub(str, endPos, endPos)
            if c == "{" then
                depth = depth + 1
            elseif c == "}" then
                depth = depth - 1
            end
            endPos = endPos + 1
        end
        
        local tableStr = string.sub(str, pos, endPos - 1)
        return self:DeserializeTable(tableStr), endPos
    
    -- String
    elseif char == "\"" then
        local endPos = pos + 1
        local escaped = false
        
        while endPos <= string.len(str) do
            local c = string.sub(str, endPos, endPos)
            if escaped then
                escaped = false
            elseif c == "\\" then
                escaped = true
            elseif c == "\"" then
                break
            end
            endPos = endPos + 1
        end
        
        local strVal = string.sub(str, pos + 1, endPos - 1)
        return self:UnescapeString(strVal), endPos + 1
    
    -- Number, boolean, or nil
    else
        local endPos = pos
        while endPos <= string.len(str) do
            local c = string.sub(str, endPos, endPos)
            if c == "," or c == "}" or c == "]" then
                break
            end
            endPos = endPos + 1
        end  -- Cierra while
        
        local valStr = string.sub(str, pos, endPos - 1)
        
        -- Try number
        local num = tonumber(valStr)
        if num then
            return num, endPos
        end
        
        -- Boolean
        if valStr == "true" then
            return true, endPos
        elseif valStr == "false" then
            return false, endPos
        elseif valStr == "nil" then
            return nil, endPos
        else
            -- Unknown, return as string
            return valStr, endPos
        end  -- Cierra el if interno (valStr == "true")
    end  -- Cierra el if-elseif-else principal (if char == "{")
end  -- Cierra la función DeserializeValue

-- Unescape a string
function TL.Comm:UnescapeString(str)
    if not str then return "" end
    
    local result = string.gsub(str, "\\(.)", function(c)
        return c
    end)
    
    return result
end

-- Request data from raid/party
function TL.Comm:RequestData(dataType)
    self:Send(dataType .. "_REQUEST", {})
end

-- Process message queue with throttling
function TL.Comm:ProcessQueue()
    if self.processing then
        return
    end
    
    -- Check if we can send (throttle check)
    local now = GetTime()
    if now - self.lastSendTime < self.throttleDelay then
        return
    end
    
    -- Get next message from queue
    if table.getn(self.messageQueue) == 0 then
        return
    end
    
    self.processing = true
    
    local msg = table.remove(self.messageQueue, 1)
    
    -- Send the message
    if msg.target then
        SendAddonMessage(TL.COMM.PREFIX, msg.message, msg.channel, msg.target)
    else
        SendAddonMessage(TL.COMM.PREFIX, msg.message, msg.channel)
    end
    
    self.lastSendTime = now
    self.processing = false
    
    -- Debug
    if TL.Settings and TL.Settings:Get("general.debugMode") then
        TL:Print("Sent message: " .. string.sub(msg.message, 1, 50) .. "...")
    end
end  -- Cierra ProcessQueue

-- Send message immediately (bypass throttle) - use sparingly!
function TL.Comm:SendImmediate(messageType, data, target)
    local message = self:Encode(messageType, data)
    
    if not message then
        TL:Error("Failed to encode message")
        return
    end
    
    -- Determine channel
    local channel = "RAID"
    if not TL:IsInRaid() then
        if TL:IsInParty() then
            channel = "PARTY"
        else
            TL:Warning("Not in a group, cannot send message")
            return
        end
    end
    
    -- Send immediately
    if target then
        SendAddonMessage(TL.COMM.PREFIX, message, "WHISPER", target)
    else
        SendAddonMessage(TL.COMM.PREFIX, message, channel)
    end
    
    self.lastSendTime = GetTime()
end  -- Cierra SendImmediate

-- Clear message queue
function TL.Comm:ClearQueue()
    self.messageQueue = {}
    TL:Print("Message queue cleared")
end

-- Get queue size
function TL.Comm:GetQueueSize()
    return table.getn(self.messageQueue)
end

-- Broadcast data to raid/party
function TL.Comm:BroadcastData(dataType, data, priority)
    self:Send(dataType .. "_BROADCAST", data, nil, priority)
end

-- ========================================
-- AUTO-SYNC IMPROVEMENTS (PHASE 6)
-- ========================================

-- Calculate checksum for data integrity
function TL.Comm:CalculateChecksum(data)
    if type(data) ~= "table" then
        return 0
    end
    
    local str = self:SerializeTable(data)
    local checksum = 0
    
    for i = 1, string.len(str) do
        checksum = checksum + string.byte(str, i)
    end
    
    -- Implementar módulo manualmente (checksum % 65536)
    return checksum - (math.floor(checksum / 65536) * 65536)
end

-- Compress data (simple RLE-like compression for repeated values)
function TL.Comm:CompressData(data)
    if not self.compressionEnabled then
        return data
    end
    
    -- For now, just return data as-is
    -- Real compression would require more complex algorithm
    -- that's safe for Lua 5.0
    return data
end

-- Decompress data
function TL.Comm:DecompressData(data)
    if not self.compressionEnabled then
        return data
    end
    
    return data
end

-- Auto-sync all important data
function TL.Comm:AutoSync()
    if not TL:IsInRaid() and not TL:IsInParty() then
        return
    end
    
    local now = time()
    
    -- Sync soft reserves
    if self:ShouldSync("softReserves", now) then
        self:SyncSoftReserves()
    end
    
    -- Sync loot history (session only)
    if self:ShouldSync("lootHistory", now) then
        self:SyncLootHistory()
    end
    
    -- Sync wishlists
    if self:ShouldSync("wishlists", now) then
        self:SyncWishlists()
    end
    
    -- Sync loot council votes
    if self:ShouldSync("lootCouncil", now) then
        self:SyncLootCouncil()
    end
    
    -- Sync priorities
    if self:ShouldSync("priorities", now) then
        self:SyncPriorities()
    end
end

-- Check if data type should be synced
function TL.Comm:ShouldSync(dataType, now)
    local lastSync = self.lastSyncTime[dataType] or 0
    return (now - lastSync) >= self.syncInterval
end

-- Sync soft reserves
function TL.Comm:SyncSoftReserves()
    if not TL.SoftRes then return end
    
    local data = {
        reserves = TL.SoftRes.reserves or {},
        availableItems = TL.SoftRes.availableItems or {}
    }
    
    local checksum = self:CalculateChecksum(data)
    
    -- Only sync if data changed
    if self.checksums.softReserves ~= checksum then
        self:BroadcastData("SOFTRES_SYNC", data, 7)
        self.checksums.softReserves = checksum
        self.lastSyncTime.softReserves = time()
        self.syncStatus.softReserves = true
    end
end

-- Sync loot history (current session only)
function TL.Comm:SyncLootHistory()
    if not TL.LootHistory then return end
    
    local sessionHistory = {}
    local currentSession = date("%Y-%m-%d")
    
    if TL.LootHistory.history then
        for i = 1, table.getn(TL.LootHistory.history) do
            local entry = TL.LootHistory.history[i]
            if entry.session == currentSession then
                table.insert(sessionHistory, entry)
            end
        end
    end
    
    local checksum = self:CalculateChecksum(sessionHistory)
    
    if self.checksums.lootHistory ~= checksum then
        self:BroadcastData("HISTORY_SYNC", sessionHistory, 6)
        self.checksums.lootHistory = checksum
        self.lastSyncTime.lootHistory = time()
        self.syncStatus.lootHistory = true
    end
end

-- Sync wishlists
function TL.Comm:SyncWishlists()
    if not TL.Wishlist then return end
    
    local playerName = UnitName("player")
    local wishlist = TL.Wishlist.wishlists[playerName] or {}
    
    local checksum = self:CalculateChecksum(wishlist)
    
    if self.checksums.wishlists ~= checksum then
        self:BroadcastData("WISHLIST_SYNC", {player = playerName, items = wishlist}, 5)
        self.checksums.wishlists = checksum
        self.lastSyncTime.wishlists = time()
        self.syncStatus.wishlists = true
    end
end

-- Sync loot council data
function TL.Comm:SyncLootCouncil()
    if not TL.LootCouncil then return end
    
    -- Only council members sync
    if not TL.LootCouncil:IsCouncilMember(UnitName("player")) then
        return
    end
    
    local data = {
        councilMembers = TL.LootCouncil.councilMembers or {},
        currentVoting = TL.LootCouncil.currentVoting
    }
    
    local checksum = self:CalculateChecksum(data)
    
    if self.checksums.lootCouncil ~= checksum then
        self:BroadcastData("COUNCIL_SYNC", data, 8)
        self.checksums.lootCouncil = checksum
        self.lastSyncTime.lootCouncil = time()
        self.syncStatus.lootCouncil = true
    end
end

-- Sync priorities
function TL.Comm:SyncPriorities()
    if not TL.LootPriority then return end
    
    -- Only raid leader syncs priorities
    if not TL:IsRaidLeader() and not TL:IsRaidOfficer() then
        return
    end
    
    local priorities = TL.LootPriority.playerPriorities or {}
    local checksum = self:CalculateChecksum(priorities)
    
    if self.checksums.priorities ~= checksum then
        self:BroadcastData("PRIORITY_SYNC", priorities, 6)
        self.checksums.priorities = checksum
        self.lastSyncTime.priorities = time()
        self.syncStatus.priorities = true
    end
end

-- Handle reconnection
function TL.Comm:OnReconnect()
    -- Reset sync status
    for key in pairs(self.syncStatus) do
        self.syncStatus[key] = false
    end
    
    -- Request full sync from raid
    if TL:IsInRaid() or TL:IsInParty() then
        TL:Print("Reconnected! Requesting data sync...")
        
        -- Broadcast our version to the raid
        self:Send("VERSION_CHECK", {version = TL.version, player = UnitName("player")}, nil, 3)
        
        -- Request all data types
        self:RequestData("SOFTRES")
        self:RequestData("HISTORY")
        self:RequestData("WISHLIST")
        self:RequestData("COUNCIL")
        self:RequestData("PRIORITY")
        
        -- Force sync after 5 seconds
        TL:ScheduleTimer(5, function()
            TL.Comm:ForceFullSync()
        end)
    end
end  -- Cierra OnReconnect

-- Handle incoming version check
function TL.Comm:HandleVersionCheck(data, sender)
    if not data or not data.version then return end
    
    local theirVersion = data.version
    local ourVersion = TL.version
    
    -- Simple version comparison (assumes format X.Y.Z)
    if theirVersion ~= ourVersion then
        -- Check if theirs is newer
        local theirParts = {string.match(theirVersion, "(%d+)%.(%d+)%.(%d+)")}
        local ourParts = {string.match(ourVersion, "(%d+)%.(%d+)%.(%d+)")}
        
        if theirParts[1] and ourParts[1] then
            local theirMajor = tonumber(theirParts[1]) or 0
            local theirMinor = tonumber(theirParts[2]) or 0
            local theirPatch = tonumber(theirParts[3]) or 0
            local ourMajor = tonumber(ourParts[1]) or 0
            local ourMinor = tonumber(ourParts[2]) or 0
            local ourPatch = tonumber(ourParts[3]) or 0
            
            if theirMajor > ourMajor or 
               (theirMajor == ourMajor and theirMinor > ourMinor) or
               (theirMajor == ourMajor and theirMinor == ourMinor and theirPatch > ourPatch) then
                TL:Warning("A newer version of TurtleLoot (" .. theirVersion .. ") is available! (You have: " .. ourVersion .. ")")
            end
        end
    end
end

-- Force full sync of all data
function TL.Comm:ForceFullSync()
    -- Reset checksums to force sync
    self.checksums = {}
    self.lastSyncTime = {}
    
    -- Trigger immediate sync
    self:AutoSync()
    
    TL:Print("Full data sync completed")
end

-- Get sync status for UI
function TL.Comm:GetSyncStatus()
    local allSynced = true
    local syncedCount = 0
    local totalCount = 0
    
    for key, status in pairs(self.syncStatus) do
        totalCount = totalCount + 1
        if status then
            syncedCount = syncedCount + 1
        else
            allSynced = false
        end
    end
    
    return allSynced, syncedCount, totalCount
end

-- Get sync status text for UI
function TL.Comm:GetSyncStatusText()
    local allSynced, syncedCount, totalCount = self:GetSyncStatus()
    
    if allSynced then
        return "|cff00ff00Synced ✓|r"
    else
        return "|cffffff00Syncing... (" .. syncedCount .. "/" .. totalCount .. ")|r"
    end
end

-- Handle sync data received
function TL.Comm:HandleSyncData(dataType, data, sender)
    -- Verify checksum if included
    if data.checksum then
        local calculatedChecksum = self:CalculateChecksum(data.payload)
        if calculatedChecksum ~= data.checksum then
            TL:Warning("Checksum mismatch from " .. sender .. " for " .. dataType)
            return
        end
    end
    
    -- Update local data based on type
    if dataType == "SOFTRES_SYNC" then
        if TL.SoftRes then
            TL.SoftRes:MergeReserves(data)
            self.syncStatus.softReserves = true
        end
    elseif dataType == "HISTORY_SYNC" then
        if TL.LootHistory then
            TL.LootHistory:MergeHistory(data)
            self.syncStatus.lootHistory = true
        end
    elseif dataType == "WISHLIST_SYNC" then
        if TL.Wishlist then
            TL.Wishlist:UpdatePlayerWishlist(data.player, data.items)
            self.syncStatus.wishlists = true
        end
    elseif dataType == "COUNCIL_SYNC" then
        if TL.LootCouncil then
            TL.LootCouncil:UpdateCouncilData(data)
            self.syncStatus.lootCouncil = true
        end
    elseif dataType == "PRIORITY_SYNC" then
        if TL.LootPriority then
            TL.LootPriority:UpdatePriorities(data)
            self.syncStatus.priorities = true
        end
    end
end  -- Cierra HandleSyncData

-- End of Communication module
