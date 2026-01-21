-- TurtleLoot Constants
-- Global constants and configuration values

local TL = _G.TurtleLoot

-- Debug: Confirm Constants loaded
DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TurtleLoot]|r Constants.lua loaded")

-- Colors
TL.COLORS = {
    PRIMARY = "00ff00",
    SECONDARY = "8aecff",
    WARNING = "ffaa00",
    ERROR = "ff0000",
    SUCCESS = "00ff00",
    
    -- Item quality colors
    QUALITY = {
        [0] = "9d9d9d", -- Poor (Gray)
        [1] = "ffffff", -- Common (White)
        [2] = "1eff00", -- Uncommon (Green)
        [3] = "0070dd", -- Rare (Blue)
        [4] = "a335ee", -- Epic (Purple)
        [5] = "ff8000" -- Legendary (Orange)
    }
}

-- Communication
TL.COMM = {
    PREFIX = "TurtleLoot",
    VERSION = 1,
    
    -- Message types
    TYPES = {
        -- Soft Reserve messages
        SOFTRES_BROADCAST = "SR_BC",        -- Full data sync (legacy)
        SOFTRES_REQUEST = "SR_REQ",         -- Request current data
        SOFTRES_LIST_BROADCAST = "SR_LIST", -- Leader sends available items list
        SOFTRES_RESERVE_ADD = "SR_ADD",     -- Player adds a reserve
        SOFTRES_RESERVE_REMOVE = "SR_REM",  -- Player removes a reserve
        SOFTRES_CLEAR = "SR_CLR",           -- Leader clears all reserves
        
        -- Plus One messages
        PLUSONE_BROADCAST = "P1_BC",
        PLUSONE_REQUEST = "P1_REQ",
        PLUSONE_UPDATE = "P1_UP",
        
        -- GDKP messages
        GDKP_BID = "GDKP_BID",
        GDKP_START = "GDKP_START",
        GDKP_END = "GDKP_END",
        
        -- Roll messages
        ROLL_START = "ROLL_START",
        ROLL_END = "ROLL_END",
        
        -- General messages
        VERSION_CHECK = "VER_CHK",
        AWARD_ANNOUNCE = "AWARD"
    }
}

-- Loot quality thresholds
TL.QUALITY = {
    POOR = 0,
    COMMON = 1,
    UNCOMMON = 2,
    RARE = 3,
    EPIC = 4,
    LEGENDARY = 5,
}

-- Roll brackets
TL.ROLL_BRACKETS = {
    MS = { name = "MS", min = 1, max = 100, priority = 1 },
    OS = { name = "OS", min = 1, max = 99, priority = 2 }
}

-- Slash commands
TL.COMMANDS = {
    MAIN = { "/tl", "/turtleloot" },
    GDKP = { "/gdkp" },
    SOFTRES = { "/sr" },
    PLUSONE = { "/p1" }
}

-- UI Constants
TL.UI = {
    FRAME_WIDTH = 600,
    FRAME_HEIGHT = 400,
    BUTTON_HEIGHT = 25,
    PADDING = 10,
    FONT = "Fonts\\FRIZQT__.TTF",
    FONT_SIZE = 12
}

-- Item slots (for filtering)
TL.ITEM_SLOTS = {
    INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2,
    INVTYPE_SHOULDER = 3,
    INVTYPE_BODY = 4,
    INVTYPE_CHEST = 5,
    INVTYPE_WAIST = 6,
    INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8,
    INVTYPE_WRIST = 9,
    INVTYPE_HAND = 10,
    INVTYPE_FINGER = 11,
    INVTYPE_TRINKET = 13,
    INVTYPE_CLOAK = 15,
    INVTYPE_WEAPON = 16,
    INVTYPE_SHIELD = 17,
    INVTYPE_RANGED = 18,
    INVTYPE_TABARD = 19
}
