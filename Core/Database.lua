-- TurtleLoot Database
-- Persistent data storage using SavedVariables

local TL = _G.TurtleLoot

TL.DB = {}

-- Initialize function called by bootstrap
function TL.DB:Initialize()
    TL:InitializeDatabase()
end

-- Initialize database
function TL:InitializeDatabase()
    -- Create or load saved variables
    if not TurtleLootDB then
        TurtleLootDB = {
            version = TL.version,
            settings = {},
            softRes = {},
            plusOnes = {},
            gdkp = {
                sessions = {},
                history = {},
            },
            awardHistory = {},
            rollHistory = {},
        }
    end
    
    -- Migrate old data if version changed
    if TurtleLootDB.version ~= TL.version then
        self:MigrateDatabase(TurtleLootDB.version, TL.version)
        TurtleLootDB.version = TL.version
    end
    
    self.db = TurtleLootDB
end

-- Migrate database between versions
function TL:MigrateDatabase(oldVersion, newVersion)
    -- Future migration logic here
    self:Print("Database migrated from " .. (oldVersion or "unknown") .. " to " .. newVersion)
end

-- Get a value from the database
function TL.DB:Get(key, default)
    local keys = {}
    for k in string.gfind(key, "[^.]+") do
        table.insert(keys, k)
    end
    
    local value = TurtleLootDB
    for _, k in ipairs(keys) do
        if type(value) ~= "table" then
            return default
        end
        value = value[k]
        if value == nil then
            return default
        end
    end
    
    return value
end

-- Set a value in the database
function TL.DB:Set(key, value)
    local keys = {}
    for k in string.gfind(key, "[^.]+") do
        table.insert(keys, k)
    end
    
    local current = TurtleLootDB
    for i = 1, table.getn(keys) - 1 do
        local k = keys[i]
        if type(current[k]) ~= "table" then
            current[k] = {}
        end
        current = current[k]
    end
    
    current[keys[table.getn(keys)]] = value
end

-- Delete a value from the database
function TL.DB:Delete(key)
    local keys = {}
    for k in string.gfind(key, "[^.]+") do
        table.insert(keys, k)
    end
    
    local current = TurtleLootDB
    for i = 1, table.getn(keys) - 1 do
        local k = keys[i]
        if type(current[k]) ~= "table" then
            return
        end
        current = current[k]
    end
    
    current[keys[table.getn(keys)]] = nil
end

-- Clear all data (with confirmation)
function TL.DB:Clear()
    TurtleLootDB = {
        version = TL.version,
        settings = {},
        softRes = {},
        plusOnes = {},
        gdkp = {
            sessions = {},
            history = {},
        },
        awardHistory = {},
        rollHistory = {},
    }
    TL.db = TurtleLootDB
    TL:Print("Database cleared")
end

-- Export database to string (for backup)
function TL.DB:Export()
    -- Simple serialization (can be improved)
    return "TurtleLootDB Export - Not yet implemented"
end

-- Import database from string
function TL.DB:Import(data)
    -- Simple deserialization (can be improved)
    TL:Warning("Import not yet implemented")
end
