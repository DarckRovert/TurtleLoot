-- TurtleLoot Initialization
-- Slash commands and UI helper functions

local TL = _G.TurtleLoot

-- Register slash commands
function TL:RegisterSlashCommands()
    -- Main commands
    SLASH_TURTLELOOT1 = "/tl"
    SLASH_TURTLELOOT2 = "/turtleloot"
    SlashCmdList["TURTLELOOT"] = function(msg)
        TL:HandleSlashCommand(msg)
    end
    
    -- GDKP command
    SLASH_TURTLELOOT_GDKP1 = "/gdkp"
    SlashCmdList["TURTLELOOT_GDKP"] = function(msg)
        TL:HandleGDKPCommand(msg)
    end
    
    -- Soft Res command
    SLASH_TURTLELOOT_SR1 = "/sr"
    SLASH_TURTLELOOT_SR2 = "/tlsr"
    SLASH_TURTLELOOT_SR3 = "/tlreserve"
    SlashCmdList["TURTLELOOT_SR"] = function(msg)
        TL:HandleSoftResCommand(msg)
    end
end

-- Handle main slash command
function TL:HandleSlashCommand(msg)
    msg = string.lower(msg or "")
    self:Print("[DEBUG] Received command: '" .. msg .. "'")
    
    if msg == "" or msg == "help" then
        self:ShowHelp()
    elseif msg == "config" or msg == "settings" then
        self:ShowSettings()
    elseif msg == "gdkp" then
        self:ShowGDKP()
    elseif msg == "sr" or msg == "softres" then
        self:ShowSoftRes()
    elseif msg == "p1" or msg == "plusones" then
        self:ShowPlusOnes()
    elseif msg == "atlas" then
        self:ShowAtlasBrowser()
    elseif msg == "award" then
        self:ShowAwardHistory()
    elseif msg == "version" then
        self:Print("Version: " .. self.version)
    elseif msg == "debug atlas" then
        -- Debug Atlas integration
        if not self.AtlasIntegration then
            self:Error("AtlasIntegration module not loaded")
            return
        end
        local instances = self.AtlasIntegration.cachedInstances
        if not instances then
            self:Error("No cached instances found")
            return
        end
        self:Print("=== Atlas Debug Info ===")
        self:Print("Total instances: " .. table.getn(instances))
        for i = 1, math.min(20, table.getn(instances)) do
            local inst = instances[i]
            if inst then
                self:Print(i .. ": " .. (inst.name or "NO NAME"))
            else
                self:Print(i .. ": NIL")
            end
        end
    elseif msg == "debug" then
        local debugMode = not self.Settings:Get("general.debugMode")
        self.Settings:Set("general.debugMode", debugMode)
        self:Print("Debug mode: " .. (debugMode and "ON" or "OFF"))
    else
        self:Warning("Unknown command: " .. msg)
        self:ShowHelp()
    end
end

-- Show help
function TL:ShowHelp()
    self:Print("Commands:")
    self:Print("/tl - Show this help")
    self:Print("/tl config - Open settings")
    self:Print("/tl gdkp - Open GDKP window")
    self:Print("/tl sr - Open Soft Reserves")
    self:Print("/tl p1 - Open Plus Ones")
    self:Print("/tl atlas - Open Atlas browser")
    self:Print("/tl award - Show award history")
    self:Print("/tl version - Show version")
    self:Print("/tl debug - Toggle debug mode")
end

-- Handle GDKP command
function TL:HandleGDKPCommand(msg)
    self:ShowGDKP()
end

-- Handle Soft Res command
function TL:HandleSoftResCommand(msg)
    self:ShowSoftRes()
end

-- UI functions
function TL:ShowSettings()
    if self.SettingsUI and self.SettingsUI.frame then
        self.SettingsUI.frame:Show()
        -- Show first category if none selected
        if self.SettingsUI.ShowCategory then
            self.SettingsUI:ShowCategory(1)
        end
    else
        self:Warning("Settings UI not initialized")
    end
end

function TL:ShowMainWindow()
    if self.MainWindow and self.MainWindow.frame then
        self.MainWindow.frame:Show()
    else
        self:Warning("Main window not initialized")
    end
end

function TL:ShowGDKP()
    if self.MainWindow and self.MainWindow.frame then
        self.MainWindow.frame:Show()
        self.MainWindow:ShowTab(4) -- GDKP is tab 4
    else
        self:Warning("Main window not initialized")
    end
end

function TL:ShowSoftRes()
    if self.MainWindow and self.MainWindow.frame then
        self.MainWindow.frame:Show()
        self.MainWindow:ShowTab(2) -- Soft Res is tab 2
    else
        self:Warning("Main window not initialized")
    end
end

function TL:ShowPlusOnes()
    if self.MainWindow and self.MainWindow.frame then
        self.MainWindow.frame:Show()
        self.MainWindow:ShowTab(3) -- Plus Ones is tab 3
    else
        self:Warning("Main window not initialized")
    end
end

function TL:ShowAtlasBrowser()
    if self.MainWindow and self.MainWindow.frame then
        self.MainWindow.frame:Show()
        self.MainWindow:ShowTab(5) -- Atlas is tab 5
    else
        self:Warning("Main window not initialized")
    end
end

function TL:ShowAwardHistory()
    if self.MainWindow and self.MainWindow.frame then
        self.MainWindow.frame:Show()
        self.MainWindow:ShowTab(6) -- History is tab 6
    else
        self:Warning("Main window not initialized")
    end
end

-- Slash commands will be registered in bootstrap.lua after initialization

-- Static Popup Definitions
StaticPopupDialogs["TURTLELOOT_SOFTRES_IMPORT"] = {
    text = "Paste item IDs (one per line) or CSV:",
    button1 = "Import",
    button2 = "Cancel",
    hasEditBox = 1,
    maxLetters = 8000,
    OnAccept = function()
        local text = getglobal(this:GetParent():GetName().."EditBox"):GetText()
        TL.SoftRes:Import(text)
        if TL.MainWindow and TL.MainWindow:IsVisible() then
            TL.MainWindow:ShowTab(2)
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}

StaticPopupDialogs["TURTLELOOT_SOFTRES_CLEAR"] = {
    text = "Are you sure you want to CLEAR ALL soft reserves?\nThis action cannot be undone.",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        TL.SoftRes:Clear()
        TL:Print("Soft reserves cleared.")
        if TL.MainWindow and TL.MainWindow:IsVisible() then
            TL.MainWindow:ShowTab(2)
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1
}
