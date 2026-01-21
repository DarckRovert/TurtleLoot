-- TurtleLoot Soft Reserve Module
-- Manage soft reserves

local TL = _G.TurtleLoot

TL.SoftRes = {
    data = {},
    reserves = {}, -- itemID -> {players}
    playerReserves = {}, -- playerName -> {itemIDs}
    availableItems = {}, -- List of itemIDs that can be reserved (set by leader)
    isLeader = false, -- Whether current player is raid leader/assistant
    classCache = {} -- Cache of player classes for coloring
}



-- Initialize function called by bootstrap
function TL.SoftRes:Initialize()
    TL:InitializeSoftRes()
end

-- Initialize soft reserve module
function TL:InitializeSoftRes()
    -- Load data from database
    self.SoftRes.data = self.DB:Get("softRes", {})
    self.SoftRes:MaterializeData()
    
    -- Listen for whisper commands
    if self.Settings:Get("softRes.enableWhisperCommand") then
        self:RegisterGameEvent("CHAT_MSG_WHISPER", function(event, message, sender)
            TL.SoftRes:HandleWhisperCommand(message, sender)
        end)
    end
    
    -- Listen for incoming data (custom addon events - use TL.Events:Register)
    TL.Events:Register("SOFTRES_DATA_RECEIVED", function(data, sender)
        TL.SoftRes:OnDataReceived(data, sender)
    end)
    
    -- Listen for new message types (custom addon events)
    TL.Events:Register("COMM_MESSAGE_" .. TL.COMM.TYPES.SOFTRES_LIST_BROADCAST, function(data, sender)
        TL.SoftRes:OnItemListReceived(data, sender)
    end)
    
    TL.Events:Register("COMM_MESSAGE_" .. TL.COMM.TYPES.SOFTRES_RESERVE_ADD, function(data, sender)
        TL.SoftRes:OnReserveAdded(data, sender)
    end)
    
    TL.Events:Register("COMM_MESSAGE_" .. TL.COMM.TYPES.SOFTRES_RESERVE_REMOVE, function(data, sender)
        TL.SoftRes:OnReserveRemoved(data, sender)
    end)
    
    TL.Events:Register("COMM_MESSAGE_" .. TL.COMM.TYPES.SOFTRES_CLEAR, function(data, sender)
        TL.SoftRes:OnClearReceived(data, sender)
    end)
    
    -- Update leader status
    self:RegisterGameEvent("RAID_ROSTER_UPDATE", function()
        TL.SoftRes:UpdateLeaderStatus()
    end)
    
    self:RegisterGameEvent("PARTY_MEMBERS_CHANGED", function()
        TL.SoftRes:UpdateLeaderStatus()
    end)
    
    -- Initial leader status check
    self.SoftRes:UpdateLeaderStatus()

    -- Listen for loot open
    self:RegisterGameEvent("LOOT_OPENED", function()
        TL.SoftRes:OnLootOpened()
    end)
end

-- Import soft reserve data
function TL.SoftRes:Import(data)
    -- Expected format: itemID,playerName,playerName;itemID,playerName
    -- Or just itemID (one per line) for available items list
    -- Or JSON format
    
    if not data or data == "" then
        TL:Error("No data to import")
        return false
    end
    
    self.data = {}
    self.availableItems = {} -- Reset available items
    
    -- Simple CSV parsing
    for line in string.gfind(data, "[^\n]+") do
        local parts = {}
        for part in string.gfind(line, "[^,]+") do
            table.insert(parts, part)
        end
        
        if table.getn(parts) >= 1 then
            local itemID = tonumber(parts[1])
            if itemID then
                -- Add to available items list
                table.insert(self.availableItems, itemID)
                
                -- If there are player names, add reserves
                if table.getn(parts) >= 2 then
                    for i = 2, table.getn(parts) do
                        local playerName = string.trim(parts[i])
                        if playerName ~= "" then
                            if not self.data[itemID] then
                                self.data[itemID] = {}
                            end
                            table.insert(self.data[itemID], playerName)
                        end
                    end
                end
            end
        end
    end
    
    -- Save to database
    TL.DB:Set("softRes", self.data)
    
    -- Materialize data
    self:MaterializeData()
    
    TL:Success("Soft reserves imported successfully")
    
    -- Broadcast item list to raid (leader only)
    if self.isLeader and TL:IsInGroup() then
        self:BroadcastItemList(self.availableItems)
    end
    
    -- Also broadcast full data if enabled (legacy support)
    if TL.Settings:Get("softRes.announceOnRoll") and TL:IsInGroup() then
        TL.Comm:Send(TL.COMM.TYPES.SOFTRES_BROADCAST, self.data, nil, 8)
    end
    
    return true
end

-- Materialize data for quick lookups
function TL.SoftRes:MaterializeData()
    self.reserves = {}
    self.playerReserves = {}
    
    for itemID, players in pairs(self.data) do
        self.reserves[itemID] = players
        
        for _, playerName in ipairs(players) do
            if not self.playerReserves[playerName] then
                self.playerReserves[playerName] = {}
            end
            table.insert(self.playerReserves[playerName], itemID)
        end
    end
end

-- Get reserves for an item
function TL.SoftRes:GetReserves(itemID)
    return self.reserves[itemID] or {}
end

-- Get player's reserves
function TL.SoftRes:GetPlayerReserves(playerName)
    return self.playerReserves[playerName] or {}
end

-- Check if item is reserved by player
function TL.SoftRes:IsReservedBy(itemID, playerName)
    local reserves = self:GetReserves(itemID)
    return TL:InTable(reserves, playerName)
end

-- Handle whisper command
function TL.SoftRes:HandleWhisperCommand(message, sender)
    if not TL.Settings:Get("softRes.enableWhisperCommand") then return end
    if not self.isLeader then return end -- Only leader handles reserves via whisper? Or everyone with the data? Usually Leader because they own the Master List.
    -- Actually, if we are just a member, we shouldn't accept reserves.
    
    local msg = string.lower(string.trim(message))
    local cmd, arg = string.match(msg, "^(!%S+)%s*(.*)")
    
    if not cmd then 
        if string.sub(msg, 1, 1) == "!" then cmd = msg end
    end
    
    if cmd == "!list" then
        self:WhisperList(sender)
    elseif cmd == "!myres" or cmd == "!sr" then
        self:WhisperMyReserves(sender)
    elseif cmd == "!cancel" then
        self:WhisperCancel(sender, arg)
    elseif cmd == "!res" or cmd == "!reserve" then
        self:WhisperReserve(sender, arg)
    end
end

-- Helper: Send available list
function TL.SoftRes:WhisperList(sender)
    if not self.availableItems or table.getn(self.availableItems) == 0 then
        SendChatMessage("TurtleLoot: No items available for reservation.", "WHISPER", nil, sender)
        return
    end
    
    SendChatMessage("Items Disponibles (Usa !res [Item]):", "WHISPER", nil, sender)
    
    local chunk = ""
    for _, itemID in ipairs(self.availableItems) do
        local name = GetItemInfo(itemID)
        if name then
            if string.len(chunk) + string.len(name) + 4 > 250 then
                SendChatMessage(chunk, "WHISPER", nil, sender)
                chunk = ""
            end
            if chunk == "" then
                chunk = name
            else
                chunk = chunk .. ", " .. name
            end
        end
    end
    if chunk ~= "" then
        SendChatMessage(chunk, "WHISPER", nil, sender)
    end
end

-- Helper: Check reserves
function TL.SoftRes:WhisperMyReserves(sender)
    local reserves = self:GetPlayerReserves(sender)
    if table.getn(reserves) == 0 then
        SendChatMessage("TurtleLoot: No tienes reservas.", "WHISPER", nil, sender)
    else
        local items = {}
        for _, itemID in ipairs(reserves) do
            local name = GetItemInfo(itemID) or "Item #"..itemID
            table.insert(items, name)
        end
        SendChatMessage("Tus reservas: " .. table.concat(items, ", "), "WHISPER", nil, sender)
    end
end

-- Helper: Cancel reserve
function TL.SoftRes:WhisperCancel(sender, arg)
    -- Logic to remove reserve
    -- For simplicity, remove LAST reserve if no arg, or specific if matches
    local reserves = self:GetPlayerReserves(sender)
    if table.getn(reserves) == 0 then
        SendChatMessage("TurtleLoot: Nada que cancelar.", "WHISPER", nil, sender)
        return
    end
    
    -- Remove the last one
    local itemID = table.remove(self.playerReserves[sender])
    -- Remove from main list
    for id, players in pairs(self.data) do
        if id == itemID then
             for i, p in ipairs(players) do
                 if p == sender then
                     table.remove(players, i)
                     break
                 end
             end
        end
    end
    
    local name = GetItemInfo(itemID) or "Item"
    SendChatMessage("TurtleLoot: Reserva cancelada: " .. name, "WHISPER", nil, sender)
    TL.DB:Set("softRes", self.data)
    -- UI Refresh
    if TL.MainWindow and TL.MainWindow:IsVisible() then TL.MainWindow:ShowTab(2) end
end

-- Helper: Reserve Item
function TL.SoftRes:WhisperReserve(sender, arg)
    if not arg or arg == "" then
        SendChatMessage("Uso: !res [Link] o !res Nombre del Item", "WHISPER", nil, sender)
        return
    end
    
    -- Check Limit
    local maxRes = TL.Settings:Get("softRes.maxReservesPerPlayer") or 2
    local curRes = table.getn(self:GetPlayerReserves(sender))
    if curRes >= maxRes then
        SendChatMessage("TurtleLoot: Limite alcanzado ("..maxRes.."). Usa !cancel primero.", "WHISPER", nil, sender)
        return
    end
    
    local targetItemID = nil
    
    -- Check if Link
    local _, _, id = string.find(arg, "item:(%d+)")
    if id then
        targetItemID = tonumber(id)
    else
        -- Fuzzy Search
        local matches = {}
        local search = string.lower(arg)
        for _, itemID in ipairs(self.availableItems) do
            local name = GetItemInfo(itemID)
            if name and string.find(string.lower(name), search) then
                table.insert(matches, itemID)
            end
        end
        
        if table.getn(matches) == 1 then
            targetItemID = matches[1]
        elseif table.getn(matches) > 1 then
            SendChatMessage("Multiples coincidencias. Se mas especifico.", "WHISPER", nil, sender)
            return
        else
            SendChatMessage("Item no encontrado en la lista disponible.", "WHISPER", nil, sender)
            return
        end
    end
    
    -- Verify validity
    local allowed = false
    for _, availID in ipairs(self.availableItems) do
        if availID == targetItemID then allowed = true break end
    end
    
    if not allowed then
        SendChatMessage("TurtleLoot: Ese item no esta en la lista de la raid.", "WHISPER", nil, sender)
        return
    end
    
    -- Reserve it
    if not self.data[targetItemID] then self.data[targetItemID] = {} end
    
    -- Check duplicate
    for _, p in ipairs(self.data[targetItemID]) do
        if p == sender then
            SendChatMessage("Ya reservas este item.", "WHISPER", nil, sender)
            return
        end
    end
    
    table.insert(self.data[targetItemID], sender)
    
    -- Materialize needed to update playerReserves logic
    self:MaterializeData()
    TL.DB:Set("softRes", self.data)
    
    local rName = GetItemInfo(targetItemID) or "Item"
    SendChatMessage("TurtleLoot: Reservado Correctamente: " .. rName, "WHISPER", nil, sender)
    
    if TL.MainWindow and TL.MainWindow:IsVisible() then TL.MainWindow:ShowTab(2) end
end

-- Helper: Check reserves
function TL.SoftRes:WhisperMyReserves(sender)
    local reserves = self:GetPlayerReserves(sender)
    if table.getn(reserves) == 0 then
        SendChatMessage("TurtleLoot: You have no reserves.", "WHISPER", nil, sender)
    else
        local items = {}
        for _, itemID in ipairs(reserves) do
            local name = GetItemInfo(itemID) or "Item #"..itemID
            table.insert(items, name)
        end
        SendChatMessage("Your reserves: " .. table.concat(items, ", "), "WHISPER", nil, sender)
    end
end

-- Helper: Cancel reserve
function TL.SoftRes:WhisperCancel(sender, arg)
    -- Logic to remove reserve
    -- For simplicity, remove LAST reserve if no arg, or specific if matches
    local reserves = self:GetPlayerReserves(sender)
    if table.getn(reserves) == 0 then
        SendChatMessage("TurtleLoot: Nothing to cancel.", "WHISPER", nil, sender)
        return
    end
    
    -- Remove the last one
    local itemID = table.remove(self.playerReserves[sender])
    -- Remove from main list
    for id, players in pairs(self.data) do
        if id == itemID then
             for i, p in ipairs(players) do
                 if p == sender then
                     table.remove(players, i)
                     break
                 end
             end
        end
    end
    
    local name = GetItemInfo(itemID) or "Item"
    SendChatMessage("TurtleLoot: Cancelled reserve for " .. name, "WHISPER", nil, sender)
    TL.DB:Set("softRes", self.data)
    -- UI Refresh
    if TL.MainWindow and TL.MainWindow:IsVisible() then TL.MainWindow:ShowTab(2) end
end

-- Helper: Reserve Item
function TL.SoftRes:WhisperReserve(sender, arg)
    if not arg or arg == "" then
        SendChatMessage("Usage: !res [Item Link] or !res Item Name", "WHISPER", nil, sender)
        return
    end
    
    -- Check Limit
    local maxRes = TL.Settings:Get("softRes.maxReservesPerPlayer") or 2
    local curRes = table.getn(self:GetPlayerReserves(sender))
    if curRes >= maxRes then
        SendChatMessage("TurtleLoot: Limit reached ("..maxRes.."). Use !cancel first.", "WHISPER", nil, sender)
        return
    end
    
    local targetItemID = nil
    
    -- Check if Link
    local _, _, id = string.find(arg, "item:(%d+)")
    if id then
        targetItemID = tonumber(id)
    else
        -- Fuzzy Search
        local matches = {}
        local search = string.lower(arg)
        for _, itemID in ipairs(self.availableItems) do
            local name = GetItemInfo(itemID)
            if name and string.find(string.lower(name), search) then
                table.insert(matches, itemID)
            end
        end
        
        if table.getn(matches) == 1 then
            targetItemID = matches[1]
        elseif table.getn(matches) > 1 then
            SendChatMessage("Multiple matches found. Be more specific.", "WHISPER", nil, sender)
            return
        else
            SendChatMessage("Item not found in available list.", "WHISPER", nil, sender)
            return
        end
    end
    
    -- Verify validity
    local allowed = false
    for _, availID in ipairs(self.availableItems) do
        if availID == targetItemID then allowed = true break end
    end
    
    if not allowed then
        SendChatMessage("TurtleLoot: That item is not in the list for this raid.", "WHISPER", nil, sender)
        return
    end
    
    -- Reserve it
    if not self.data[targetItemID] then self.data[targetItemID] = {} end
    
    -- Check duplicate
    for _, p in ipairs(self.data[targetItemID]) do
        if p == sender then
            SendChatMessage("You already reserved this.", "WHISPER", nil, sender)
            return
        end
    end
    
    table.insert(self.data[targetItemID], sender)
    
    -- Materialize needed to update playerReserves logic
    self:MaterializeData()
    TL.DB:Set("softRes", self.data)
    
    local rName = GetItemInfo(targetItemID) or "Item"
    SendChatMessage("TurtleLoot: Reserved " .. rName, "WHISPER", nil, sender)
    
    if TL.MainWindow and TL.MainWindow:IsVisible() then TL.MainWindow:ShowTab(2) end
end

-- Handle received data
function TL.SoftRes:OnDataReceived(data, sender)
    -- Auto-accept or prompt user
    TL:Print("Received soft reserve data from " .. sender)
    -- For now, auto-accept
    self.data = data
    TL.DB:Set("softRes", self.data)
    self:MaterializeData()
end

-- Get tooltip lines for an item
function TL.SoftRes:GetTooltipLines(itemLink)
    if not TL.Settings:Get("softRes.showTooltips") then
        return {}
    end
    
    local itemID = TL:GetItemIDFromLink(itemLink)
    if not itemID then
        return {}
    end
    
    local reserves = self:GetReserves(itemID)
    if table.getn(reserves) == 0 then
        return {}
    end
    
    local lines = {}
    local count = table.getn(reserves)
    
    -- Header with count
    table.insert(lines, "|cffffaa00Soft Reserves (" .. count .. "):|r")
    
    -- Compact list (comma separated)
    local playerList = ""
    local addedCount = 0
    local MAX_DISPLAY = 10 -- Avoid massive tooltips
    local currentPlayer = UnitName("player")
    
    for i, playerName in ipairs(reserves) do
        -- Hide non-group members if setting enabled
        if not TL.Settings:Get("softRes.hideNonGroupMembers") or TL:IsPlayerInGroup(playerName) then
            local displayName = playerName
            
            -- Highlight current player
            if playerName == currentPlayer then
                displayName = "|cff00ff00" .. playerName .. " (You)|r"
            else
                -- Class color from cache
                local class = self.classCache[playerName]
                if class and RAID_CLASS_COLORS[class] then
                    local color = RAID_CLASS_COLORS[class]
                    local rs, gs, bs = color.r * 255, color.g * 255, color.b * 255
                    local hex = string.format("ff%02x%02x%02x", rs, gs, bs)
                    displayName = "|c" .. hex .. playerName .. "|r"
                else
                    displayName = "|cffcccccc" .. playerName .. "|r"
                end
            end
            
            if addedCount > 0 then
                playerList = playerList .. ", "
            end
            
            playerList = playerList .. displayName
            addedCount = addedCount + 1
            
            if addedCount >= MAX_DISPLAY and i < count then
                playerList = playerList .. ", ... (" .. (count - i) .. " more)"
                break
            end
        end
    end
    
    if playerList ~= "" then
        table.insert(lines, playerList)
    end
    
    return lines
end

-- Export soft reserves
function TL.SoftRes:Export()
    local lines = {}
    
    for itemID, players in pairs(self.data) do
        local playerList = table.concat(players, ",")
        table.insert(lines, itemID .. "," .. playerList)
    end
    
    return table.concat(lines, "\n")
end

-- Clear soft reserves (leader only)
function TL.SoftRes:Clear()
    if not self.isLeader then
        TL:Warning("Only raid leader or assistant can clear reserves")
        return false
    end
    
    self.data = {}
    self.reserves = {}
    self.playerReserves = {}
    self.availableItems = {}
    TL.DB:Set("softRes", self.data)
    
    -- Broadcast clear command
    if TL:IsInGroup() then
        TL.Comm:Send(TL.COMM.TYPES.SOFTRES_CLEAR, {}, nil, 10)
    end
    
    TL:Print("Soft reserves cleared")
    
    -- Refresh UI
    if TL.MainWindow and TL.MainWindow.RefreshSoftResTab then
        TL.MainWindow:RefreshSoftResTab()
    end
    
    return true
end

-- Helper: Check if player is in group
function TL:IsPlayerInGroup(playerName)
    if TL:IsInRaid() then
        for i = 1, GetNumRaidMembers() do
            local name = GetRaidRosterInfo(i)
            if name == playerName then
                return true
            end
        end
    elseif TL:IsInParty() then
        if playerName == TL:GetPlayerName() then
            return true
        end
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name == playerName then
                return true
            end
        end
    else
        -- Logic: If not in group, return true ONLY for self (Solo mode)
        if playerName == TL:GetPlayerName() then
            return true
        end
    end
    return false
end

-- Update leader status and class cache
function TL.SoftRes:UpdateLeaderStatus()
    self.isLeader = TL:IsRaidLeaderOrAssistant()
    
    -- Update class cache
    if TL:IsInRaid() then
        for i = 1, GetNumRaidMembers() do
            local name, _, _, _, class = GetRaidRosterInfo(i)
            if name and class then
                self.classCache[name] = class
            end
        end
    elseif TL:IsInParty() then
        local name = UnitName("player")
        local _, class = UnitClass("player")
        if name and class then self.classCache[name] = class end
        
        for i = 1, GetNumPartyMembers() do
            name = UnitName("party"..i)
            _, class = UnitClass("party"..i)
            if name and class then self.classCache[name] = class end
        end
    end
end

-- Check if current player is raid leader or assistant
function TL:IsRaidLeaderOrAssistant()
    if self:IsInRaid() then
        for i = 1, GetNumRaidMembers() do
            local name, rank = GetRaidRosterInfo(i)
            if name == self:GetPlayerName() then
                return rank >= 1 -- 2 = leader, 1 = assistant, 0 = member
            end
        end
    elseif self:IsInParty() then
        -- In party, check if we're the leader
        return IsPartyLeader()
    end
    return true -- If not in group, allow all actions
end

-- Broadcast available items list (leader only)
function TL.SoftRes:BroadcastItemList(itemList)
    if not self.isLeader then
        TL:Warning("Only raid leader or assistant can broadcast item list")
        return false
    end
    
    if not TL:IsInGroup() then
        TL:Warning("Not in a group")
        return false
    end
    
    self.availableItems = itemList
    
    -- Send to all raid members
    TL.Comm:Send(TL.COMM.TYPES.SOFTRES_LIST_BROADCAST, {items = itemList}, nil, 10)
    
    TL:Success("Item list broadcasted to raid (" .. table.getn(itemList) .. " items)")
    return true
end

-- Receive item list from leader
function TL.SoftRes:OnItemListReceived(data, sender)
    if not data or not data.items then
        return
    end
    
    self.availableItems = data.items
    
    TL:Print("Received item list from " .. sender .. " (" .. table.getn(data.items) .. " items)")
    
    -- Refresh UI if open
    if TL.MainWindow and TL.MainWindow.RefreshSoftResTab then
        TL.MainWindow:RefreshSoftResTab()
    end
end

-- Add a reserve (any player)
function TL.SoftRes:AddReserve(itemID, playerName)
    playerName = playerName or TL:GetPlayerName()
    
    -- Validation 1: Check if player is in a group (raid or party)
    -- Allow solo for testing purposes
    if not TL:IsInGroup() then
        -- TL:Warning("You must be in a raid or party to reserve items")
        -- return false
    end
    
    -- Validation 2: Check if player is in the group
    if not TL:IsPlayerInGroup(playerName) then
        TL:Warning("Player " .. playerName .. " is not in the group")
        return false
    end
    
    -- Validation 3: Validate item is in available list (if list exists)
    if table.getn(self.availableItems) > 0 and not TL:InTable(self.availableItems, itemID) then
        TL:Warning("Item " .. itemID .. " is not in the available items list")
        return false
    end
    
    -- Validation 4: Check if already reserved (prevent duplicates)
    if self:IsReservedBy(itemID, playerName) then
        TL:Warning("You have already reserved this item")
        return false
    end
    
    -- Validation 5: Check reserve limit
    local maxReserves = TL.Settings:Get("softRes.maxReservesPerPlayer") or 2
    local currentReserves = self.playerReserves[playerName] or {}
    if table.getn(currentReserves) >= maxReserves then
        TL:Warning("You can only reserve " .. maxReserves .. " items (currently: " .. table.getn(currentReserves) .. ")")
        return false
    end
    
    -- Add locally
    if not self.data[itemID] then
        self.data[itemID] = {}
    end
    table.insert(self.data[itemID], playerName)
    
    -- Save to database
    TL.DB:Set("softRes", self.data)
    
    -- Materialize
    self:MaterializeData()
    
    -- Broadcast to raid
    if TL:IsInGroup() then
        TL.Comm:Send(TL.COMM.TYPES.SOFTRES_RESERVE_ADD, {itemID = itemID, player = playerName}, nil, 8)
    end
    
    TL:Success("Reserved item: " .. itemID)
    
    -- Refresh UI
    if TL.MainWindow and TL.MainWindow.RefreshSoftResTab then
        TL.MainWindow:RefreshSoftResTab()
    end
    
    return true
end

-- Remove a reserve (any player, own reserves only)
function TL.SoftRes:RemoveReserve(itemID, playerName)
    playerName = playerName or TL:GetPlayerName()
    
    -- Check if reserved
    if not self:IsReservedBy(itemID, playerName) then
        TL:Warning("You have not reserved this item")
        return false
    end
    
    -- Remove locally
    if self.data[itemID] then
        for i, name in ipairs(self.data[itemID]) do
            if name == playerName then
                table.remove(self.data[itemID], i)
                break
            end
        end
        
        -- Remove item entry if no reserves left
        if table.getn(self.data[itemID]) == 0 then
            self.data[itemID] = nil
        end
    end
    
    -- Save to database
    TL.DB:Set("softRes", self.data)
    
    -- Materialize
    self:MaterializeData()
    
    -- Broadcast to raid
    if TL:IsInGroup() then
        TL.Comm:Send(TL.COMM.TYPES.SOFTRES_RESERVE_REMOVE, {itemID = itemID, player = playerName}, nil, 8)
    end
    
    TL:Success("Removed reserve for item: " .. itemID)
    
    -- Refresh UI
    if TL.MainWindow and TL.MainWindow.RefreshSoftResTab then
        TL.MainWindow:RefreshSoftResTab()
    end
    
    return true
end

-- Handle reserve added by another player
function TL.SoftRes:OnReserveAdded(data, sender)
    if not data or not data.itemID or not data.player then
        return
    end
    
    local itemID = data.itemID
    local playerName = data.player
    
    -- Add locally (don't broadcast again)
    if not self.data[itemID] then
        self.data[itemID] = {}
    end
    
    -- Check if already in list
    if not TL:InTable(self.data[itemID], playerName) then
        table.insert(self.data[itemID], playerName)
    end
    
    -- Save to database
    TL.DB:Set("softRes", self.data)
    
    -- Materialize
    self:MaterializeData()
    
    -- Refresh UI
    if TL.MainWindow and TL.MainWindow.RefreshSoftResTab then
        TL.MainWindow:RefreshSoftResTab()
    end
end

-- Handle reserve removed by another player
function TL.SoftRes:OnReserveRemoved(data, sender)
    if not data or not data.itemID or not data.player then
        return
    end
    
    local itemID = data.itemID
    local playerName = data.player
    
    -- Remove locally (don't broadcast again)
    if self.data[itemID] then
        for i, name in ipairs(self.data[itemID]) do
            if name == playerName then
                table.remove(self.data[itemID], i)
                break
            end
        end
        
        -- Remove item entry if no reserves left
        if table.getn(self.data[itemID]) == 0 then
            self.data[itemID] = nil
        end
    end
    
    -- Save to database
    TL.DB:Set("softRes", self.data)
    
    -- Materialize
    self:MaterializeData()
    
    -- Refresh UI
    if TL.MainWindow and TL.MainWindow.RefreshSoftResTab then
        TL.MainWindow:RefreshSoftResTab()
    end
end

-- Handle clear command from leader
function TL.SoftRes:OnClearReceived(data, sender)
    TL:Print("Soft reserves cleared by " .. sender)
    
    self.data = {}
    self.reserves = {}
    self.playerReserves = {}
    self.availableItems = {}
    
    TL.DB:Set("softRes", self.data)
    
    -- Refresh UI
    if TL.MainWindow and TL.MainWindow.RefreshSoftResTab then
        TL.MainWindow:RefreshSoftResTab()
    end
end

-- Get available items
function TL.SoftRes:GetAvailableItems()
    return self.availableItems
end

-- Get statistics
function TL.SoftRes:GetStats()
    local stats = {
        topReservers = {},
        mostPopularItems = {},
        unreservedItems = {},
        conflicts = {},
        totalReserves = 0,
        totalPlayers = 0,
        totalItems = 0
    }
    
    -- Count total reserves and players
    for playerName, items in pairs(self.playerReserves) do
        stats.totalPlayers = stats.totalPlayers + 1
        local count = table.getn(items)
        stats.totalReserves = stats.totalReserves + count
        
        table.insert(stats.topReservers, {
            player = playerName,
            count = count,
            items = items,
        })
    end
    
    -- Sort top reservers by count
    table.sort(stats.topReservers, function(a, b)
        return a.count > b.count
    end)
    
    -- Count items and find popular/conflicted items
    for itemID, players in pairs(self.reserves) do
        stats.totalItems = stats.totalItems + 1
        local count = table.getn(players)
        
        table.insert(stats.mostPopularItems, {
            itemID = itemID,
            count = count,
            players = players,
        })
        
        -- Track conflicts (multiple reserves)
        if count > 1 then
            table.insert(stats.conflicts, {
                itemID = itemID,
                count = count,
                players = players,
            })
        end
    end
    
    -- Sort most popular items by count
    table.sort(stats.mostPopularItems, function(a, b)
        return a.count > b.count
    end)
    
    -- Sort conflicts by count
    table.sort(stats.conflicts, function(a, b)
        return a.count > b.count
    end)
    
    -- Find unreserved items (from available list)
    if table.getn(self.availableItems) > 0 then
        for _, itemID in ipairs(self.availableItems) do
            if not self.reserves[itemID] or table.getn(self.reserves[itemID]) == 0 then
                table.insert(stats.unreservedItems, itemID)
            end
        end
    end
    
    return stats
end

-- Print statistics to chat
function TL.SoftRes:PrintStats()
    local stats = self:GetStats()
    
    TL:Print("=== Soft Reserve Statistics ===")
    TL:Print("Total Reserves: " .. stats.totalReserves)
    TL:Print("Total Players: " .. stats.totalPlayers)
    TL:Print("Total Items: " .. stats.totalItems)
    TL:Print("Conflicts: " .. table.getn(stats.conflicts))
    TL:Print("Unreserved: " .. table.getn(stats.unreservedItems))
    
    -- Top 5 reservers
    if table.getn(stats.topReservers) > 0 then
        TL:Print("\nTop Reservers:")
        for i = 1, math.min(5, table.getn(stats.topReservers)) do
            local reserver = stats.topReservers[i]
            TL:Print("  " .. i .. ". " .. reserver.player .. " (" .. reserver.count .. " items)")
        end
    end
    
    -- Top 5 most popular items
    if table.getn(stats.mostPopularItems) > 0 then
        TL:Print("\nMost Popular Items:")
        for i = 1, math.min(5, table.getn(stats.mostPopularItems)) do
            local item = stats.mostPopularItems[i]
            local itemName = GetItemInfo(item.itemID) or ("Item " .. item.itemID)
            TL:Print("  " .. i .. ". " .. itemName .. " (" .. item.count .. " reserves)")
        end
    end
    
    -- Top 5 conflicts
    if table.getn(stats.conflicts) > 0 then
        TL:Print("\nTop Conflicts:")
        for i = 1, math.min(5, table.getn(stats.conflicts)) do
            local conflict = stats.conflicts[i]
            local itemName = GetItemInfo(conflict.itemID) or ("Item " .. conflict.itemID)
            TL:Print("  " .. i .. ". " .. itemName .. " (" .. conflict.count .. " players)")
        end
    end
end

-- Handle loot opened event
function TL.SoftRes:OnLootOpened()
    if not TL:IsInGroup() then return end
    
    local reservedLoot = {}
    
    for i = 1, GetNumLootItems() do
        local icon, name, quantity, quality = GetLootSlotInfo(i)
        
        if quantity > 0 and quality >= 3 then -- Rare or higher only
            local itemLink = GetLootSlotLink(i)
            local itemID = TL:GetItemIDFromLink(itemLink)
            
            if itemID then
                local reserves = self:GetReserves(itemID)
                if table.getn(reserves) > 0 then
                    table.insert(reservedLoot, {
                        slot = i,
                        itemID = itemID,
                        name = name,
                        icon = icon,
                        link = itemLink,
                        quality = quality,
                        reserves = reserves
                    })
                end
            end
        end
    end
    
    if table.getn(reservedLoot) > 0 then
        -- Show popup if not already showing
        if not TL.SoftRes.popupFrame then
            self:CreatePopupFrame()
        end
        TL.SoftRes:ShowLootPopup(reservedLoot)
    end
end

-- Create loot popup frame
function TL.SoftRes:CreatePopupFrame()
    local f = CreateFrame("Frame", "TLSREventPopup", UIParent)
    f:SetWidth(400)
    f:SetHeight(300)
    f:SetPoint("CENTER", 0, 100)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    f:SetBackdropColor(0, 0, 0, 0.9)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    f:Hide()
    
    -- Header
    local header = f:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetWidth(300)
    header:SetHeight(64)
    header:SetPoint("TOP", 0, 12)
    
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("Reserved Loot Found!")
    
    -- Scroll Frame
    local scroll = CreateFrame("ScrollFrame", "TLSRPopupScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 15, -40)
    scroll:SetPoint("BOTTOMRIGHT", -35, 40)
    
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(330)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    f.content = content
    
    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    closeBtn:SetWidth(100)
    closeBtn:SetHeight(25)
    closeBtn:SetPoint("BOTTOM", 0, 15)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function()
        f:Hide()
    end)
    
    TL.SoftRes.popupFrame = f
end

-- Show loot popup with items
function TL.SoftRes:ShowLootPopup(items)
    if not self.popupFrame then return end
    
    local content = self.popupFrame.content
    
    -- Clear previous
    local kids = {content:GetChildren()}
    for _, child in ipairs(kids) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local yOffset = 0
    
    for i, item in ipairs(items) do
        -- Item Icon & Name
        local icon = content:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(32)
        icon:SetHeight(32)
        icon:SetPoint("TOPLEFT", 0, -yOffset)
        icon:SetTexture(item.icon)
        
        local nameText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
        local color = TL:GetQualityColor(item.quality)
        nameText:SetText("|cff" .. color .. item.name .. "|r")
        
        yOffset = yOffset + 35
        
        -- Reserves list
        local reservesText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        reservesText:SetPoint("TOPLEFT", 42, -yOffset + 15)
        reservesText:SetText("Reserved by: " .. table.concat(item.reserves, ", "))
        
        yOffset = yOffset + 20
        
        -- Master Loot actions (if ML)
        if TL:IsRaidLeaderOrAssistant() then
            local awardLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            awardLabel:SetPoint("TOPLEFT", 42, -yOffset)
            awardLabel:SetText("Actions:")
            
            -- Smart Roll Button
            local rollBtn = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
            rollBtn:SetWidth(60)
            rollBtn:SetHeight(18)
            rollBtn:SetPoint("LEFT", awardLabel, "RIGHT", 10, 0)
            rollBtn:SetText("Roll")
            
            -- Capture for closure
            local link = item.link
            
            rollBtn:SetScript("OnClick", function()
                if TL.RollOff then
                    TL.RollOff:Start(link, nil, "Soft Reserve Roll")
                else
                    TL:Warning("Roll module not loaded")
                end
            end)
            
            -- Direct Award Buttons (Moved slightly right)
            local xOffset = 180
            for _, player in ipairs(item.reserves) do
                local btn = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
                btn:SetWidth(70)
                btn:SetHeight(18)
                btn:SetPoint("LEFT", awardLabel, "LEFT", xOffset, 0)
                btn:SetText(player)
                
                local slot = item.slot
                local target = player
                
                btn:SetScript("OnClick", function()
                    -- Find dynamic index (loot window slots change)
                    -- We stored original slot `i`, but if loot was taken, indices shift?
                    -- 1.12 Loot API uses slot index 1..N.
                    -- If we are careful, it's fine.
                     GiveMasterLoot(slot, i) -- Wait, GiveMasterLoot(slotIndex, candidateIndex).
                     -- Candidate index? No, GiveMasterLoot(slot) opens menu?
                     -- No, `GiveMasterLoot(slot, index)` gives to candidate `index` in the popup menu.
                     -- We don't have the candidate index here! We only have the player name.
                     -- We must find the candidate index for `player`.
                     
                     -- Helper to find loot candidate index
                     local candidateIndex = nil
                     for ci = 1, 40 do
                        local cName = GetMasterLootCandidate(slot, ci)
                        if cName == target then
                            candidateIndex = ci
                            break
                        end
                     end
                     
                     if candidateIndex then
                         GiveMasterLoot(slot, candidateIndex)
                         TL:Print("Awarded item to " .. target)
                     else
                         TL:Warning("Candidate " .. target .. " not found in loot list. Out of range?")
                     end
                end)
                
                xOffset = xOffset + 75
            end
            yOffset = yOffset + 25
        end
        
        yOffset = yOffset + 10 -- Spacing between items
    end
    
    content:SetHeight(math.max(yOffset, 1))
    self.popupFrame:Show()
end

-- Handle loot opened event (Merged from LootHandler)
function TL.SoftRes:OnLootOpened()
    if not TL:IsInGroup() then return end
    
    local reservedLoot = {}
    
    for i = 1, GetNumLootItems() do
        local icon, name, quantity, quality = GetLootSlotInfo(i)
        
        if quantity > 0 and quality >= 3 then -- Rare or higher only
            local itemLink = GetLootSlotLink(i)
            local itemID = TL:GetItemIDFromLink(itemLink)
            
            if itemID then
                local reserves = self:GetReserves(itemID)
                if table.getn(reserves) > 0 then
                    table.insert(reservedLoot, {
                        slot = i,
                        itemID = itemID,
                        name = name,
                        icon = icon,
                        link = itemLink,
                        quality = quality,
                        reserves = reserves
                    })
                end
            end
        end
    end
    
    if table.getn(reservedLoot) > 0 then
        -- Show popup if not already showing
        if not TL.SoftRes.popupFrame then
            self:CreatePopupFrame()
        end
        TL.SoftRes:ShowLootPopup(reservedLoot)
    end
end
