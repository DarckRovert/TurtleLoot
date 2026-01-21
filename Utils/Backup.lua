-- TurtleLoot Backup/Restore System
-- Automatic backup and restore of addon data

local TL = _G.TurtleLoot

TL.Backup = {
    backups = {}, -- {[timestamp] = {data, date}}
    maxBackups = 7,
    autoBackupEnabled = true,
    lastBackupTime = 0,
    backupInterval = 86400 -- 24 hours
}

local BK = TL.Backup

-- Initialize
function BK:Initialize()
    -- Load backups from DB
    if not TurtleLootDB then
        TurtleLootDB = {}
    end
    
    if not TurtleLootDB.backups then
        TurtleLootDB.backups = {}
    end
    
    self.backups = TurtleLootDB.backups
    self.lastBackupTime = TurtleLootDB.lastBackupTime or 0
    
    -- Auto-backup timer
    if self.autoBackupEnabled then
        if not self.backupFrame then
            self.backupFrame = CreateFrame("Frame")
            self.backupFrame.elapsed = 0
            self.backupFrame:SetScript("OnUpdate", function()
                this.elapsed = this.elapsed + arg1
                if this.elapsed >= 3600 then -- Check every hour
                    BK:CheckAutoBackup()
                    this.elapsed = 0
                end
            end)
        end
    end
    
    TL:Print("Backup system initialized")
end

-- Check if auto-backup is needed
function BK:CheckAutoBackup()
    local now = time()
    
    if (now - self.lastBackupTime) >= self.backupInterval then
        self:CreateBackup("Auto-backup")
    end
end

-- Create a backup
function BK:CreateBackup(description)
    local timestamp = time()
    local dateStr = date("%Y-%m-%d %H:%M:%S", timestamp)
    
    -- Collect all data to backup
    local backupData = {
        version = TL.version,
        timestamp = timestamp,
        date = dateStr,
        description = description or "Manual backup",
        
        -- Loot history
        lootHistory = self:CopyTable(TurtleLootDB.lootHistory or {}),
        
        -- Soft reserves
        softReserves = self:CopyTable(TurtleLootDB.softReserves or {}),
        
        -- Wishlists
        wishlists = self:CopyTable(TurtleLootDB.wishlists or {}),
        
        -- Karma
        karma = self:CopyTable(TurtleLootDB.karma or {}),
        karmaHistory = self:CopyTable(TurtleLootDB.karmaHistory or {}),
        
        -- Loot council
        lootCouncil = self:CopyTable(TurtleLootDB.lootCouncil or {}),
        
        -- Settings
        settings = self:CopyTable(TurtleLootDB.settings or {})
    }
    
    -- Store backup
    self.backups[timestamp] = backupData
    
    -- Clean old backups (keep only last N)
    self:CleanOldBackups()
    
    -- Save to DB
    TurtleLootDB.backups = self.backups
    TurtleLootDB.lastBackupTime = timestamp
    self.lastBackupTime = timestamp
    
    TL:Print("|cff00ff00Backup created:|r " .. dateStr .. " - " .. (description or "Manual backup"))
    
    return timestamp
end

-- Deep copy a table
function BK:CopyTable(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end
    
    local copy = {}
    
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = self:CopyTable(v)
        else
            copy[k] = v
        end
    end
    
    return copy
end

-- Clean old backups (keep only last N)
function BK:CleanOldBackups()
    -- Get all backup timestamps
    local timestamps = {}
    
    for timestamp in pairs(self.backups) do
        table.insert(timestamps, timestamp)
    end
    
    -- Sort by timestamp (oldest first)
    table.sort(timestamps)
    
    -- Remove oldest backups if we have too many
    while table.getn(timestamps) > self.maxBackups do
        local oldestTimestamp = table.remove(timestamps, 1)
        self.backups[oldestTimestamp] = nil
    end
end

-- Restore from backup
function BK:RestoreBackup(timestamp)
    if not timestamp then
        TL:Print("|cffff0000No backup timestamp specified|r")
        return false
    end
    
    local backup = self.backups[timestamp]
    
    if not backup then
        TL:Print("|cffff0000Backup not found|r")
        return false
    end
    
    -- Confirm with user
    TL:Print("|cffffff00WARNING:|r This will restore data from " .. backup.date)
    TL:Print("|cffffff00All current data will be overwritten!|r")
    TL:Print("Type |cff00ff00/tl backup restore confirm " .. timestamp .. "|r to confirm")
    
    return false
end

-- Restore from backup (confirmed)
function BK:RestoreBackupConfirmed(timestamp)
    local backup = self.backups[timestamp]
    
    if not backup then
        TL:Print("|cffff0000Backup not found|r")
        return false
    end
    
    -- Restore all data
    TurtleLootDB.lootHistory = self:CopyTable(backup.lootHistory or {})
    TurtleLootDB.softReserves = self:CopyTable(backup.softReserves or {})
    TurtleLootDB.wishlists = self:CopyTable(backup.wishlists or {})
    TurtleLootDB.karma = self:CopyTable(backup.karma or {})
    TurtleLootDB.karmaHistory = self:CopyTable(backup.karmaHistory or {})
    TurtleLootDB.lootCouncil = self:CopyTable(backup.lootCouncil or {})
    TurtleLootDB.settings = self:CopyTable(backup.settings or {})
    
    TL:Print("|cff00ff00Backup restored successfully!|r")
    TL:Print("|cffffff00Please /reload to apply changes|r")
    
    return true
end

-- List all backups
function BK:ListBackups()
    local timestamps = {}
    
    for timestamp in pairs(self.backups) do
        table.insert(timestamps, timestamp)
    end
    
    if table.getn(timestamps) == 0 then
        TL:Print("No backups found")
        return
    end
    
    -- Sort by timestamp (newest first)
    table.sort(timestamps, function(a, b) return a > b end)
    
    TL:Print("|cff00ff00Available Backups:|r")
    
    for i = 1, table.getn(timestamps) do
        local timestamp = timestamps[i]
        local backup = self.backups[timestamp]
        TL:Print(i .. ". " .. backup.date .. " - " .. backup.description .. " (ID: " .. timestamp .. ")")
    end
    
    TL:Print(" ")
    TL:Print("To restore: |cff00ff00/tl backup restore <ID>|r")
end

-- Delete a backup
function BK:DeleteBackup(timestamp)
    if not timestamp then
        TL:Print("|cffff0000No backup timestamp specified|r")
        return false
    end
    
    if not self.backups[timestamp] then
        TL:Print("|cffff0000Backup not found|r")
        return false
    end
    
    local backup = self.backups[timestamp]
    self.backups[timestamp] = nil
    
    TurtleLootDB.backups = self.backups
    
    TL:Print("|cff00ff00Backup deleted:|r " .. backup.date)
    
    return true
end

-- Export backup to string (for manual saving)
function BK:ExportBackup(timestamp)
    if not timestamp then
        -- Export current data
        timestamp = self:CreateBackup("Export")
    end
    
    local backup = self.backups[timestamp]
    
    if not backup then
        TL:Print("|cffff0000Backup not found|r")
        return nil
    end
    
    -- Serialize backup data
    local serialized = self:SerializeTable(backup)
    
    TL:Print("|cff00ff00Backup exported to chat|r")
    TL:Print("Copy the following text to save externally:")
    TL:Print("--- BEGIN TURTLELOOT BACKUP ---")
    
    -- Split into chunks (chat has line limits)
    local chunkSize = 200
    for i = 1, string.len(serialized), chunkSize do
        local chunk = string.sub(serialized, i, i + chunkSize - 1)
        DEFAULT_CHAT_FRAME:AddMessage(chunk)
    end
    
    TL:Print("--- END TURTLELOOT BACKUP ---")
    
    return serialized
end

-- Simple table serialization
function BK:SerializeTable(tbl, depth)
    depth = depth or 0
    
    if depth > 10 then
        return "{}"
    end
    
    local result = {}
    
    for k, v in pairs(tbl) do
        local key = tostring(k)
        local value
        
        if type(v) == "table" then
            value = self:SerializeTable(v, depth + 1)
        elseif type(v) == "string" then
            value = "\"" .. v .. "\""
        else
            value = tostring(v)
        end
        
        table.insert(result, "[" .. key .. "]=" .. value)
    end
    
    return "{" .. table.concat(result, ",") .. "}"
end

-- Get backup info
function BK:GetBackupInfo(timestamp)
    local backup = self.backups[timestamp]
    
    if not backup then
        return nil
    end
    
    return {
        date = backup.date,
        description = backup.description,
        version = backup.version,
        timestamp = backup.timestamp
    }
end
