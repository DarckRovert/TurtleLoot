-- TurtleLoot Event System
-- Custom event system for addon-wide event handling

local TL = _G.TurtleLoot

-- Event registry
TL.Events = {
    listeners = {},
    gameEventListeners = {}
}

-- Initialize function called by bootstrap
function TL.Events:Initialize()
    TL:InitializeEvents()
end

-- Initialize event system
function TL:InitializeEvents()
    -- Create event frame if not exists
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame", "TurtleLootEventFrame")
    end
    
    -- Set up event handler
    self.eventFrame:SetScript("OnEvent", function()
        TL.Events:HandleGameEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    end)
end

-- Register a custom event listener
function TL.Events:Register(eventName, callback)
    if not self.listeners[eventName] then
        self.listeners[eventName] = {}
    end
    table.insert(self.listeners[eventName], callback)
end

-- Alias for Register (for compatibility)
function TL.Events:RegisterCallback(eventName, callback)
    return self:Register(eventName, callback)
end

-- Unregister a custom event listener
function TL.Events:Unregister(eventName, callback)
    if not self.listeners[eventName] then return end
    
    for i, cb in ipairs(self.listeners[eventName]) do
        if cb == callback then
            table.remove(self.listeners[eventName], i)
            return
        end
    end
end

-- Fire a custom event
function TL.Events:Fire(eventName, a1, a2, a3, a4, a5, a6, a7, a8, a9)
    if not self.listeners[eventName] then return end
    
    for _, callback in ipairs(self.listeners[eventName]) do
        local success, err = pcall(callback, a1, a2, a3, a4, a5, a6, a7, a8, a9)
        if not success then
            TL:Error("Event error (" .. eventName .. "): " .. tostring(err))
        end
    end
end

-- Register a game event listener
function TL.Events:RegisterGameEvent(eventName, callback)
    if not self.gameEventListeners[eventName] then
        self.gameEventListeners[eventName] = {}
        TL.eventFrame:RegisterEvent(eventName)
    end
    table.insert(self.gameEventListeners[eventName], callback)
end

-- Unregister a game event listener
function TL.Events:UnregisterGameEvent(eventName, callback)
    if not self.gameEventListeners[eventName] then return end
    
    for i, cb in ipairs(self.gameEventListeners[eventName]) do
        if cb == callback then
            table.remove(self.gameEventListeners[eventName], i)
            break
        end
    end
    
    -- If no more listeners, unregister the game event
    if table.getn(self.gameEventListeners[eventName]) == 0 then
        TL.eventFrame:UnregisterEvent(eventName)
        self.gameEventListeners[eventName] = nil
    end
end

-- Handle game events
function TL.Events:HandleGameEvent(eventName, a1, a2, a3, a4, a5, a6, a7, a8, a9)
    if not self.gameEventListeners[eventName] then return end
    
    for _, callback in ipairs(self.gameEventListeners[eventName]) do
        local success, err = pcall(callback, eventName, a1, a2, a3, a4, a5, a6, a7, a8, a9)
        if not success then
            TL:Error("Game event error (" .. eventName .. "): " .. tostring(err))
        end
    end
end

-- Helper methods on TL namespace
function TL:RegisterEvent(eventName, callback)
    self.Events:RegisterGameEvent(eventName, callback)
end

function TL:UnregisterEvent(eventName, callback)
    self.Events:UnregisterGameEvent(eventName, callback)
end

-- Convenience function to fire events from TL namespace
function TL:FireEvent(eventName, a1, a2, a3, a4, a5, a6, a7, a8, a9)
    self.Events:Fire(eventName, a1, a2, a3, a4, a5, a6, a7, a8, a9)
end

-- Duplicate function removed - already defined at line 102

-- Convenience function to register game events from TL namespace
function TL:RegisterGameEvent(eventName, callback)
    self.Events:RegisterGameEvent(eventName, callback)
end
