-- TurtleLoot Settings
-- Settings management system

local TL = _G.TurtleLoot

TL.Settings = {
    cache = {},
    callbacks = {},
}

-- Initialize function called by bootstrap
function TL.Settings:Initialize()
    TL:InitializeSettings()
end

-- Initialize settings
function TL:InitializeSettings()
    -- Load settings from database or use defaults
    local savedSettings = self.DB:Get("settings", {})
    
    -- Merge with defaults
    self.Settings.cache = self:MergeTables(
        self:DeepCopy(self.DefaultSettings),
        savedSettings
    )
    
    -- Save merged settings back to database
    self.DB:Set("settings", self.Settings.cache)
end

-- Get a setting value
function TL.Settings:Get(key, default)
    local keys = {}
    for k in string.gfind(key, "[^.]+") do
        table.insert(keys, k)
    end
    
    local value = self.cache
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

-- Set a setting value
function TL.Settings:Set(key, value)
    local keys = {}
    for k in string.gfind(key, "[^.]+") do
        table.insert(keys, k)
    end
    
    local current = self.cache
    for i = 1, table.getn(keys) - 1 do
        local k = keys[i]
        if type(current[k]) ~= "table" then
            current[k] = {}
        end
        current = current[k]
    end
    
    local oldValue = current[keys[table.getn(keys)]]
    current[keys[table.getn(keys)]] = value
    
    -- Save to database
    TL.DB:Set("settings", self.cache)
    
    -- Fire callbacks
    self:FireCallbacks(key, value, oldValue)
end

-- Register a callback for when a setting changes
function TL.Settings:OnChange(key, callback)
    if not self.callbacks[key] then
        self.callbacks[key] = {}
    end
    table.insert(self.callbacks[key], callback)
end

-- Fire callbacks for a setting change
function TL.Settings:FireCallbacks(key, newValue, oldValue)
    if not self.callbacks[key] then return end
    
    for _, callback in ipairs(self.callbacks[key]) do
        local success, err = pcall(callback, newValue, oldValue)
        if not success then
            TL:Error("Settings callback error (" .. key .. "): " .. tostring(err))
        end
    end
end

-- Reset settings to defaults
function TL.Settings:Reset()
    self.cache = TL:DeepCopy(TL.DefaultSettings)
    TL.DB:Set("settings", self.cache)
    TL:Print("Settings reset to defaults")
end

-- Reset a specific setting category
function TL.Settings:ResetCategory(category)
    if TL.DefaultSettings[category] then
        self.cache[category] = TL:DeepCopy(TL.DefaultSettings[category])
        TL.DB:Set("settings", self.cache)
        TL:Print("Settings category '" .. category .. "' reset to defaults")
    end
end
