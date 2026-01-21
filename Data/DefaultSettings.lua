-- TurtleLoot Default Settings
-- Default configuration values for all features

local TL = _G.TurtleLoot

TL.DefaultSettings = {
    -- General Settings
    general = {
        enabled = true,
        debugMode = false,
        showWelcomeMessage = true,
        fontSize = 12
    },
    
    -- Minimap Button
    minimapButton = {
        enabled = true,
        position = 225
    },
    
    -- Master Looting
    masterLoot = {
        autoOpenDialog = true,
        announceRollStart = true,
        announceRollEnd = true,
        defaultRollTime = 30,
        defaultRollNote = "/roll for MS or /roll 99 for OS",
        doCountdown = true,
        countdownSeconds = 5
    },
    
    -- Roll Tracking
    rollTracking = {
        trackAllRolls = false,
        sortBySoftRes = true,
        sortByPlusOne = true,
        showRollWindow = true,
        closeAfterRoll = false,
        rollEndLeeway = 1
    },
    
    -- Awarding Loot
    awardLoot = {
        announceAwards = true,
        announceToRaid = false,
        announceToGuild = false,
        autoTradeAfterAward = true,
        skipConfirmation = false,
        minimumQuality = 3 -- Rare (Blue)
    },
    
    -- Soft Reserves
    softRes = {
        enabled = true,
        showTooltips = true,
        announceOnRoll = true,
        announceReservedLoot = true,
        enableWhisperCommand = true,
        hideNonGroupMembers = true,
        maxReservesPerPlayer = 2, -- Maximum items each player can reserve
        defaultQuality = 4 -- Default quality filter for Atlas generation (4 = Epic)
    },
    
    lootPriority = {
        enabled = true,
        showTooltips = true,
        enableAutoAssign = false, -- Auto-assign if clear winner
        autoAssignMinDifference = 20, -- Minimum score difference for auto-assign
        announceTopPriority = true -- Announce top priority to raid
    },
    
    -- Plus Ones
    plusOnes = {
        enabled = true,
        enableWhisperCommand = true,
        autoShareData = false,
        defaultPoints = 0
    },
    
    -- GDKP
    gdkp = {
        enabled = true,
        defaultMinBid = 100,
        defaultIncrement = 50,
        defaultAuctionTime = 30,
        antiSnipeTime = 10,
        announceStart = true,
        announceNewBid = true,
        announceFinalCall = true,
        announceEnd = true,
        announceToRaid = true,
        showBidWindow = true,
        precision = 0 -- Gold precision (0 = whole gold)
    },
    
    -- Pack Mule (Auto Loot)
    packMule = {
        enabled = false,
        lootGold = true,
        autoConfirmSolo = false,
        autoConfirmGroup = false,
        announceDisenchants = true
    },
    
    -- Trade Timer
    tradeTimer = {
        enabled = true,
        showOnlyWhenMasterLooting = true,
        hideAwarded = false,
        maximumBars = 5,
        maximumTimeLeft = 120, -- 2 hours in minutes
        scale = 1.0
    },
    
    -- Dropped Loot
    droppedLoot = {
        announceToChat = true,
        announceToRaid = false,
        minimumQuality = 4 -- Epic
    },
    
    -- Hotkeys
    hotkeys = {
        enabled = true,
        rollOrAuction = "ALT_CLICK",
        award = "ALT_SHIFT_CLICK",
        disenchant = "CTRL_SHIFT_CLICK",
        onlyInGroup = false
    },
    
    -- Tooltip Highlighting
    tooltips = {
        enabled = true,
        highlightSoftRes = true,
        highlightPlusOnes = true,
        highlightMyItemsOnly = false
    },
    
    -- Loot Priority System
    lootPriority = {
        enabled = true,
        showInTooltips = true,
        announceOnDrop = true,
        weightSoftReserve = 50,
        weightRecentLoot = 30,
        weightTodayLoot = 20,
        recentLootDays = 14
    },
    
    -- Loot Council
    lootCouncil = {
        enabled = false,
        voteTimeout = 15,
        minVotesRequired = 2,
        allowVeto = true,
        showRecommendation = true,
        autoAssignWinner = true
    },
    
    -- Wishlist
    wishlist = {
        enabled = true,
        maxItems = 10,
        showInTooltips = true,
        notifyOnDrop = true,
        syncWithRaid = true
    },
    
    -- Upgrade Analyzer
    upgradeAnalyzer = {
        enabled = true,
        showTooltips = true,
        announceTopUpgrades = true,
        showTop3 = true,
        minUpgradePercent = 5
    },
    
    -- Loot Karma
    lootKarma = {
        enabled = true,
        showInTooltips = true,
        affectPriority = true,
        priorityWeight = 15,
        decayEnabled = true,
        decayRate = 1,
        announceChanges = true
    }
}
