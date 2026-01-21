-- TurtleLoot Statistics Window
-- Display loot history and statistics for transparency

local TL = _G.TurtleLoot

TL.StatsWindow = {
    frame = nil,
    isOpen = false,
    currentTab = "history", -- "history" or "stats"
    historyData = {},
    statsData = {},
    filterDays = 14 -- Default: last 14 days
}

-- Initialize
function TL.StatsWindow:Initialize()
    if self.frame then
        return
    end
    
    self:CreateFrame()
end

-- Create main frame
function TL.StatsWindow:CreateFrame()
    local frame = CreateFrame("Frame", "TurtleLootStatsWindow", UIParent)
    frame:SetWidth(700)
    frame:SetHeight(550)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0, 0, 0, 1)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:Hide()
    
    self.frame = frame
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Loot Statistics & History")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        TL.StatsWindow:Hide()
    end)
    
    -- Tab buttons
    local historyTab = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    historyTab:SetWidth(150)
    historyTab:SetHeight(25)
    historyTab:SetPoint("TOPLEFT", 20, -50)
    historyTab:SetText("Loot History")
    historyTab:SetScript("OnClick", function()
        TL.StatsWindow:ShowTab("history")
    end)
    self.historyTab = historyTab
    
    local statsTab = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    statsTab:SetWidth(150)
    statsTab:SetHeight(25)
    statsTab:SetPoint("LEFT", historyTab, "RIGHT", 5, 0)
    statsTab:SetText("Statistics")
    statsTab:SetScript("OnClick", function()
        TL.StatsWindow:ShowTab("stats")
    end)
    self.statsTab = statsTab
    
    -- Filter dropdown
    local filterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterLabel:SetPoint("TOPRIGHT", -150, -55)
    filterLabel:SetText("Period:")
    
    local filterDropdown = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    filterDropdown:SetWidth(120)
    filterDropdown:SetHeight(25)
    filterDropdown:SetPoint("LEFT", filterLabel, "RIGHT", 5, 0)
    filterDropdown:SetText("Last 14 days")
    filterDropdown:SetScript("OnClick", function()
        TL.StatsWindow:ShowFilterMenu()
    end)
    self.filterDropdown = filterDropdown
    
    -- Content frame (for history)
    local historyFrame = CreateFrame("Frame", nil, frame)
    historyFrame:SetPoint("TOPLEFT", 20, -85)
    historyFrame:SetPoint("BOTTOMRIGHT", -20, 50)
    self.historyFrame = historyFrame
    
    -- Scroll frame for history
    local scrollFrame = CreateFrame("ScrollFrame", "TLStatsHistoryScroll", historyFrame, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT")
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 0)
    scrollFrame:SetScript("OnVerticalScroll", function()
        FauxScrollFrame_OnVerticalScroll(20, function() TL.StatsWindow:UpdateHistory() end)
    end)
    self.scrollFrame = scrollFrame
    
    -- Create history item buttons
    scrollFrame.buttons = {}
    for i = 1, 20 do
        local btn = self:CreateHistoryButton(scrollFrame, i)
        btn:SetPoint("TOPLEFT", 5, -(i-1) * 20)
        scrollFrame.buttons[i] = btn
    end
    
    -- Content frame (for stats)
    local statsFrame = CreateFrame("Frame", nil, frame)
    statsFrame:SetPoint("TOPLEFT", 20, -85)
    statsFrame:SetPoint("BOTTOMRIGHT", -20, 50)
    statsFrame:Hide()
    self.statsFrame = statsFrame
    
    -- Stats content
    self:CreateStatsContent(statsFrame)
    
    -- Bottom buttons
    local refreshBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    refreshBtn:SetWidth(120)
    refreshBtn:SetHeight(25)
    refreshBtn:SetPoint("BOTTOMLEFT", 20, 15)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function()
        TL.StatsWindow:Refresh()
    end)
    
    local exportBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    exportBtn:SetWidth(120)
    exportBtn:SetHeight(25)
    exportBtn:SetPoint("BOTTOM", 0, 15)
    exportBtn:SetText("Export CSV")
    exportBtn:SetScript("OnClick", function()
        TL.StatsWindow:ExportCSV()
    end)
    
    local clearBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    clearBtn:SetWidth(120)
    clearBtn:SetHeight(25)
    clearBtn:SetPoint("BOTTOMRIGHT", -20, 15)
    clearBtn:SetText("Clear History")
    clearBtn:SetScript("OnClick", function()
        TL.StatsWindow:ConfirmClear()
    end)
    self.clearBtn = clearBtn
end

-- Create history button
function TL.StatsWindow:CreateHistoryButton(parent, index)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(630)
    btn:SetHeight(18)
    btn:SetNormalFontObject("GameFontNormalSmall")
    btn:SetHighlightFontObject("GameFontHighlightSmall")
    
    -- Background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    if math.mod(index, 2) == 0 then
        bg:SetTexture(0.1, 0.1, 0.1, 0.3)
    else
        bg:SetTexture(0.15, 0.15, 0.15, 0.3)
    end
    
    -- Highlight
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture(0.3, 0.3, 0.3, 0.5)
    
    -- Time
    local time = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    time:SetPoint("LEFT", 5, 0)
    time:SetWidth(80)
    time:SetJustifyH("LEFT")
    btn.time = time
    
    -- Player
    local player = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    player:SetPoint("LEFT", time, "RIGHT", 5, 0)
    player:SetWidth(120)
    player:SetJustifyH("LEFT")
    btn.player = player
    
    -- Item
    local item = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    item:SetPoint("LEFT", player, "RIGHT", 5, 0)
    item:SetWidth(300)
    item:SetJustifyH("LEFT")
    btn.item = item
    
    -- Method
    local method = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    method:SetPoint("LEFT", item, "RIGHT", 5, 0)
    method:SetWidth(100)
    method:SetJustifyH("LEFT")
    btn.method = method
    
    return btn
end

-- Create stats content
function TL.StatsWindow:CreateStatsContent(parent)
    -- Summary section
    local summaryTitle = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    summaryTitle:SetPoint("TOPLEFT", 10, -10)
    summaryTitle:SetText("Summary")
    
    local summaryText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summaryText:SetPoint("TOPLEFT", summaryTitle, "BOTTOMLEFT", 0, -10)
    summaryText:SetWidth(650)
    summaryText:SetJustifyH("LEFT")
    self.summaryText = summaryText
    
    -- Loot by player section
    local playerTitle = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    playerTitle:SetPoint("TOPLEFT", summaryText, "BOTTOMLEFT", 0, -20)
    playerTitle:SetText("Loot by Player")
    
    -- Scroll frame for player stats
    local playerScroll = CreateFrame("ScrollFrame", "TLStatsPlayerScroll", parent, "FauxScrollFrameTemplate")
    playerScroll:SetPoint("TOPLEFT", playerTitle, "BOTTOMLEFT", 0, -10)
    playerScroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -25, 10)
    playerScroll:SetScript("OnVerticalScroll", function()
        FauxScrollFrame_OnVerticalScroll(20, function() TL.StatsWindow:UpdatePlayerStats() end)
    end)
    self.playerScroll = playerScroll
    
    -- Create player stat buttons
    playerScroll.buttons = {}
    for i = 1, 15 do
        local btn = self:CreatePlayerStatButton(playerScroll, i)
        btn:SetPoint("TOPLEFT", 5, -(i-1) * 20)
        playerScroll.buttons[i] = btn
    end
end

-- Create player stat button
function TL.StatsWindow:CreatePlayerStatButton(parent, index)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(630)
    btn:SetHeight(18)
    btn:SetNormalFontObject("GameFontNormalSmall")
    
    -- Background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    if math.mod(index, 2) == 0 then
        bg:SetTexture(0.1, 0.1, 0.1, 0.3)
    else
        bg:SetTexture(0.15, 0.15, 0.15, 0.3)
    end
    
    -- Rank
    local rank = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rank:SetPoint("LEFT", 5, 0)
    rank:SetWidth(30)
    rank:SetJustifyH("LEFT")
    btn.rank = rank
    
    -- Player name
    local player = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    player:SetPoint("LEFT", rank, "RIGHT", 5, 0)
    player:SetWidth(150)
    player:SetJustifyH("LEFT")
    btn.player = player
    
    -- Item count
    local count = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    count:SetPoint("LEFT", player, "RIGHT", 5, 0)
    count:SetWidth(80)
    count:SetJustifyH("LEFT")
    btn.count = count
    
    -- Bar
    local bar = btn:CreateTexture(nil, "ARTWORK")
    bar:SetHeight(12)
    bar:SetPoint("LEFT", count, "RIGHT", 5, 0)
    bar:SetTexture(0, 0.7, 0, 0.8)
    btn.bar = bar
    
    return btn
end

-- Show window
function TL.StatsWindow:Show()
    if not self.frame then
        self:Initialize()
    end
    
    self.frame:Show()
    self.isOpen = true
    self:Refresh()
end

-- Hide window
function TL.StatsWindow:Hide()
    if self.frame then
        self.frame:Hide()
    end
    self.isOpen = false
end

-- Toggle window
function TL.StatsWindow:Toggle()
    if self.isOpen then
        self:Hide()
    else
        self:Show()
    end
end

-- Show tab
function TL.StatsWindow:ShowTab(tab)
    self.currentTab = tab
    
    if tab == "history" then
        self.historyFrame:Show()
        self.statsFrame:Hide()
        self.historyTab:Disable()
        self.statsTab:Enable()
    else
        self.historyFrame:Hide()
        self.statsFrame:Show()
        self.historyTab:Enable()
        self.statsTab:Disable()
    end
    
    self:Refresh()
end

-- Refresh data
function TL.StatsWindow:Refresh()
    self:LoadData()
    
    if self.currentTab == "history" then
        self:UpdateHistory()
    else
        self:UpdateStats()
    end
end

-- Load data from AwardedLoot
function TL.StatsWindow:LoadData()
    if not TL.AwardedLoot then
        self.historyData = {}
        return
    end
    
    local allHistory = TL.AwardedLoot:GetHistory() or {}
    local cutoffTime = time() - (self.filterDays * 24 * 60 * 60)
    
    -- Filter by time period
    self.historyData = {}
    for _, award in ipairs(allHistory) do
        if award.timestamp >= cutoffTime then
            table.insert(self.historyData, award)
        end
    end
    
    -- Sort by timestamp (newest first)
    table.sort(self.historyData, function(a, b)
        return a.timestamp > b.timestamp
    end)
end

-- Update history display
function TL.StatsWindow:UpdateHistory()
    if not self.scrollFrame then
        return
    end
    
    local numItems = table.getn(self.historyData)
    local buttons = self.scrollFrame.buttons
    
    FauxScrollFrame_Update(self.scrollFrame, numItems, 20, 20)
    
    local offset = FauxScrollFrame_GetOffset(self.scrollFrame)
    
    for i = 1, 20 do
        local btn = buttons[i]
        local index = offset + i
        
        if index <= numItems then
            local award = self.historyData[index]
            
            -- Format time
            local timeStr = date("%H:%M", award.timestamp)
            btn.time:SetText(timeStr)
            
            -- Player name
            btn.player:SetText(award.player or "Unknown")
            
            -- Item link
            btn.item:SetText(award.itemLink or "Unknown Item")
            
            -- Method
            local methodStr = award.method or "Manual"
            btn.method:SetText(methodStr)
            
            btn:Show()
        else
            btn:Hide()
        end
    end
end

-- Update stats display
function TL.StatsWindow:UpdateStats()
    -- Calculate stats
    local playerStats = {}
    local totalItems = 0
    
    for _, award in ipairs(self.historyData) do
        local player = award.player or "Unknown"
        if not playerStats[player] then
            playerStats[player] = 0
        end
        playerStats[player] = playerStats[player] + 1
        totalItems = totalItems + 1
    end
    
    -- Convert to sorted array
    local sortedStats = {}
    for player, count in pairs(playerStats) do
        table.insert(sortedStats, {player = player, count = count})
    end
    
    table.sort(sortedStats, function(a, b)
        return a.count > b.count
    end)
    
    self.statsData = sortedStats
    
    -- Update summary
    local numPlayers = table.getn(sortedStats)
    local avgPerPlayer = numPlayers > 0 and (totalItems / numPlayers) or 0
    
    local summaryStr = string.format(
        "Total Items: %d\nUnique Players: %d\nAverage per Player: %.1f\nPeriod: Last %d days",
        totalItems, numPlayers, avgPerPlayer, self.filterDays
    )
    
    if self.summaryText then
        self.summaryText:SetText(summaryStr)
    end
    
    -- Update player stats list
    self:UpdatePlayerStats()
end

-- Update player stats list
function TL.StatsWindow:UpdatePlayerStats()
    if not self.playerScroll then
        return
    end
    
    local numItems = table.getn(self.statsData)
    local buttons = self.playerScroll.buttons
    
    FauxScrollFrame_Update(self.playerScroll, numItems, 15, 20)
    
    local offset = FauxScrollFrame_GetOffset(self.playerScroll)
    
    -- Find max count for bar scaling
    local maxCount = 0
    for _, stat in ipairs(self.statsData) do
        if stat.count > maxCount then
            maxCount = stat.count
        end
    end
    
    for i = 1, 15 do
        local btn = buttons[i]
        local index = offset + i
        
        if index <= numItems then
            local stat = self.statsData[index]
            
            -- Rank
            btn.rank:SetText("#" .. index)
            
            -- Player
            btn.player:SetText(stat.player)
            
            -- Count
            btn.count:SetText(stat.count .. " items")
            
            -- Bar
            local barWidth = maxCount > 0 and (stat.count / maxCount) * 300 or 0
            btn.bar:SetWidth(barWidth)
            
            btn:Show()
        else
            btn:Hide()
        end
    end
end

-- Show filter menu
function TL.StatsWindow:ShowFilterMenu()
    local menu = {
        {text = "Last 7 days", func = function() TL.StatsWindow:SetFilter(7) end},
        {text = "Last 14 days", func = function() TL.StatsWindow:SetFilter(14) end},
        {text = "Last 30 days", func = function() TL.StatsWindow:SetFilter(30) end},
        {text = "All time", func = function() TL.StatsWindow:SetFilter(365) end}
    }
    
    -- Show dropdown menu (simplified)
    for _, item in ipairs(menu) do
        item.func()
        break -- Just use first for now, proper dropdown needs more code
    end
end

-- Set filter
function TL.StatsWindow:SetFilter(days)
    self.filterDays = days
    
    local text = "Last " .. days .. " days"
    if days >= 365 then
        text = "All time"
    end
    
    if self.filterDropdown then
        self.filterDropdown:SetText(text)
    end
    
    self:Refresh()
end

-- Export to CSV
function TL.StatsWindow:ExportCSV()
    local lines = {"Timestamp,Player,Item,Method"}
    
    for _, award in ipairs(self.historyData) do
        local timeStr = date("%Y-%m-%d %H:%M:%S", award.timestamp)
        local player = award.player or "Unknown"
        local item = award.itemLink or "Unknown"
        local method = award.method or "Manual"
        
        table.insert(lines, timeStr .. "," .. player .. "," .. item .. "," .. method)
    end
    
    local csv = table.concat(lines, "\n")
    
    -- Show export dialog
    StaticPopupDialogs["TURTLELOOT_EXPORT_CSV"] = {
        text = "Copy this CSV data:",
        button1 = "Close",
        hasEditBox = 1,
        maxLetters = 0,
        OnShow = function()
            getglobal(this:GetName().."EditBox"):SetText(csv)
            getglobal(this:GetName().."EditBox"):HighlightText()
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1
    }
    StaticPopup_Show("TURTLELOOT_EXPORT_CSV")
end

-- Confirm clear
function TL.StatsWindow:ConfirmClear()
    StaticPopupDialogs["TURTLELOOT_CLEAR_HISTORY"] = {
        text = "Clear all loot history?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            if TL.AwardedLoot then
                TL.AwardedLoot:ClearHistory()
                TL.StatsWindow:Refresh()
            end
        end,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1
    }
    StaticPopup_Show("TURTLELOOT_CLEAR_HISTORY")
end

-- Slash command
SLASH_TLSTATS1 = "/tlstats"
SLASH_TLSTATS2 = "/tlhistory"
SlashCmdList["TLSTATS"] = function(msg)
    TL.StatsWindow:Toggle()
end
