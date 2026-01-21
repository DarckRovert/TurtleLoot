-- TurtleLoot Bootstrap
-- Creates the global addon object (Simple version without Ace2/Ace3)

-- Create global addon object
TurtleLoot = {};
local TL = TurtleLoot;

-- Initialize addon properties
TL.name = "TurtleLoot";
TL._initialized = false;
TL.version = "1.0.0";
TL.PREFIX = "TL";

-- Core objects (will be populated by other files)
TL.DB = nil;
TL.Settings = nil;
TL.Events = nil;
TL.Comm = nil;

-- Module objects
TL.AwardedLoot = nil;
TL.RollOff = nil;
TL.LootPriority = nil;
TL.LootCouncil = nil;
TL.Wishlist = nil;
TL.LootKarma = nil;
TL.PackMule = nil;
TL.MasterLoot = nil;
TL.SoftRes = nil;
TL.PlusOnes = nil;
TL.GDKP = nil;
TL.PackMule = nil;
TL.TradeTimer = nil;
TL.AtlasIntegration = nil;
TL.BossEncounter = nil;

-- Utility objects
TL.UpgradeAnalyzer = nil;
TL.Backup = nil;

-- UI objects
TL.MinimapButton = nil;
TL.MainWindow = nil;
TL.RollWindow = nil;
TL.AwardDialog = nil;
TL.SettingsUI = nil;
TL.SoftResWindow = nil;
TL.StatsWindow = nil;
TL.LootCouncilWindow = nil;
TL.WishlistWindow = nil;
TL.SyncIndicator = nil;
TL.AuctionMonitor = nil;

-- Bootstrap function
function TL:bootstrap(event, loadedAddonName)
    -- Only bootstrap once and only for our addon
    if self._initialized or loadedAddonName ~= self.name then
        return;
    end
    
    self._initialized = true;
    
    -- Initialize core systems
    if self.DB and self.DB.Initialize then
        self.DB:Initialize();
    end
    
    if self.Settings and self.Settings.Initialize then
        self.Settings:Initialize();
    end
    
    if self.Events and self.Events.Initialize then
        self.Events:Initialize();
    end
    
    -- Initialize tooltips
    if self.InitializeTooltips then
        self:InitializeTooltips();
    end
    
    -- Initialize communication first (needed by other modules)
    if self.Comm and self.Comm.Initialize then
        local success, err = pcall(self.Comm.Initialize, self.Comm);
        if not success then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TurtleLoot]|r Error initializing Comm: " .. tostring(err));
        end
    end
    
    -- Initialize utility modules
    if self.UpgradeAnalyzer and self.UpgradeAnalyzer.Initialize then
        -- self.UpgradeAnalyzer:Initialize();
    end
    
    if self.Backup and self.Backup.Initialize then
        self.Backup:Initialize();
    end
    
    -- Initialize modules
    local modules = {
        self.AwardedLoot,
        self.RollOff,
        -- self.LootPriority,
        -- self.LootCouncil,
        -- self.Wishlist,
        -- self.LootKarma,
        self.MasterLoot,
        self.SoftRes,
        self.PlusOnes,
        self.GDKP,
        -- self.PackMule,
        self.AtlasIntegration,
        self.BossEncounter
    }
    
    for _, module in ipairs(modules) do
        if module and module.Initialize then
            local success, err = pcall(module.Initialize, module);
            if not success then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TurtleLoot]|r Error initializing module: " .. tostring(err));
            end
        end
    end
    
    -- Initialize TradeTimer separately (has different init pattern)
    if self.InitializeTradeTimer then
        -- self.TradeTimer:InitializeTradeTimer();
    end
    
    -- Initialize RollWindow separately
    if self.InitializeRollWindow then
        self:InitializeRollWindow();
    end
    
    -- Initialize AwardDialog separately
    if self.InitializeAwardDialog then
        self:InitializeAwardDialog();
    end
    
    -- Initialize UI
    local uiModules = {
        self.MinimapButton,
        self.MainWindow,
        self.SettingsUI,
        self.SoftResWindow,
        self.StatsWindow,
        -- self.LootCouncilWindow,
        -- self.WishlistWindow,
        self.SyncIndicator,
        self.AuctionMonitor
    }
    
    for _, uiModule in ipairs(uiModules) do
        if uiModule and uiModule.Initialize then
            local success, err = pcall(uiModule.Initialize, uiModule);
            if not success then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TurtleLoot]|r Error initializing UI: " .. tostring(err));
            end
        end
    end
    
    -- Register slash commands
    self:RegisterSlashCommands();
    
    -- Success message
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TurtleLoot]|r v" .. self.version .. " loaded. Type /tl for commands.");
end

-- Register ADDON_LOADED event
local eventFrame = CreateFrame("Frame");
eventFrame:RegisterEvent("ADDON_LOADED");
eventFrame:SetScript("OnEvent", function()
    local event = event
    local arg1 = arg1
    TL:bootstrap(event, arg1)
end)

-- Debug: Confirm bootstrap loaded
DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TurtleLoot]|r Bootstrap loaded successfully");
