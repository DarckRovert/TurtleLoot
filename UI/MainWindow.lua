-- TurtleLoot Main Window
-- Main UI window

local TL = _G.TurtleLoot

TL.MainWindow = {
    frame = nil,
    tabs = {},
    currentTab = 1,
}

-- Initialize function for bootstrap
function TL.MainWindow:Initialize()
    TL:InitializeMainWindow()
end

-- Initialize main window
function TL:InitializeMainWindow()
    -- Create main frame
    local frame = CreateFrame("Frame", "TurtleLootMainFrame", UIParent)
    frame:SetWidth(720) -- Slightly wider for better spacing
    frame:SetHeight(520)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    -- Modern Dark Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.9) -- Dark styling
    
    -- Standard Header
    local header = frame:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetWidth(400)
    header:SetHeight(64)
    header:SetPoint("TOP", 0, 12)

    -- Title bar
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("TurtleLoot v" .. TL.version)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Navigation Bar Background
    local navBar = frame:CreateTexture(nil, "ARTWORK")
    navBar:SetTexture(0.1, 0.1, 0.1, 0.5)
    navBar:SetPoint("TOPLEFT", 15, -30)
    navBar:SetPoint("TOPRIGHT", -15, -30)
    navBar:SetHeight(35)

    -- Make draggable
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)
    
    -- Create tabs
    TL.MainWindow:CreateTabs(frame)
    
    -- Create content area
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -80)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20)
    content:Show()  -- Explicitly show the content frame
    content.children = {}
    frame.content = content
    
    TL.MainWindow.frame = frame
    
    -- Show first tab
    TL.MainWindow:ShowTab(1)
end

-- Create tabs
function TL.MainWindow:CreateTabs(parent)
    local tabs = {
        { name = "Overview", func = function() TL.MainWindow:ShowOverview() end },
        { name = "Soft Res", func = function() TL.MainWindow:ShowSoftRes() end },
        { name = "Plus Ones", func = function() TL.MainWindow:ShowPlusOnes() end },
        { name = "GDKP", func = function() TL.MainWindow:ShowGDKP() end },
        { name = "Atlas", func = function() TL.MainWindow:ShowAtlasBrowser() end },
        { name = "History", func = function() TL.MainWindow:ShowHistory() end },
    }
    
    for i, tabData in ipairs(tabs) do
        -- Capture index in local variable to avoid closure issues
        local tabIndex = i
        local tabFunc = tabData.func
        
        local tab = CreateFrame("Button", nil, parent)
        tab:SetWidth(100)
        tab:SetHeight(30)
        tab:SetPoint("TOPLEFT", parent, "TOPLEFT", 20 + (i-1) * 105, -50)
        
        -- Background
        tab:SetNormalTexture("Interface\\ChatFrame\\ChatFrameTab")
        tab:SetHighlightTexture("Interface\\ChatFrame\\ChatFrameTab")
        
        -- Text
        local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER", tab, "CENTER", 0, 0)
        text:SetText(tabData.name)
        tab.text = text
        
        -- Click handler
        tab:SetScript("OnClick", function()
            TL.MainWindow:ShowTab(tabIndex)
        end)
        
        tab.index = tabIndex
        tab.func = tabFunc
        self.tabs[tabIndex] = tab
    end
end

-- Show specific tab
function TL.MainWindow:ShowTab(index)
    self.currentTab = index
    
    -- Update tab appearance
    for i, tab in ipairs(self.tabs) do
        if i == index then
            tab.text:SetTextColor(1, 1, 1)
        else
            tab.text:SetTextColor(0.7, 0.7, 0.7)
        end
    end
    
    -- Clear content - destroy all children manually
    if self.frame.content then
        if self.frame.content.children then
            for _, child in ipairs(self.frame.content.children) do
                child:Hide()
                child:SetParent(nil)
            end
        end
        self.frame.content.children = {}
    end
    
    -- Show tab content
    if self.tabs[index] and self.tabs[index].func then
        self.tabs[index].func()
    end
end

-- Overview tab
function TL.MainWindow:ShowOverview()
    local content = TL.MainWindow.frame.content
    
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("TOP", content, "TOP", 0, -20)
    text:SetText("TurtleLoot Overview")
    text:Show()
    table.insert(content.children, text)
    
    local info = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -60)
    info:SetJustifyH("LEFT")
    info:SetWidth(600)
    info:SetText(
        "Welcome to TurtleLoot!\n\n" ..
        "Features:\n" ..
        "- Master Looting with auto-open\n" ..
        "- Roll tracking (MS/OS)\n" ..
        "- Soft Reserves\n" ..
        "- Plus Ones (+1)\n" ..
        "- GDKP Auctions\n" ..
        "- Pack Mule auto-loot\n" ..
        "- Trade Timer\n\n" ..
        "Use the tabs above to access different features.\n" ..
        "Type /tl help for commands."
    )
    info:Show()
    table.insert(content.children, info)
end

-- Preload item data for Soft Res tab
function TL.MainWindow:PreloadSoftResItems()
    -- Create hidden tooltip if it doesn't exist
    if not TL.MainWindow.itemCacheTooltip then
        TL.MainWindow.itemCacheTooltip = CreateFrame("GameTooltip", "TLItemCacheTooltip", UIParent, "GameTooltipTemplate")
        TL.MainWindow.itemCacheTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        TL.MainWindow.itemCacheTooltip:Hide()
    end
    
    local tooltip = TL.MainWindow.itemCacheTooltip
    local itemsToLoad = {}
    local itemsLoaded = 0
    local totalItems = 0
    
    -- Collect all item IDs that need loading
    if TL.SoftRes.availableItems then
        for _, itemID in ipairs(TL.SoftRes.availableItems) do
            totalItems = totalItems + 1
            local itemName = GetItemInfo(itemID)
            if not itemName then
                table.insert(itemsToLoad, itemID)
            else
                itemsLoaded = itemsLoaded + 1
            end
        end
    end
    
    for itemID, _ in pairs(TL.SoftRes.data) do
        local itemName = GetItemInfo(itemID)
        if not itemName then
            local alreadyAdded = false
            for _, id in ipairs(itemsToLoad) do
                if id == itemID then
                    alreadyAdded = true
                    break
                end
            end
            if not alreadyAdded then
                totalItems = totalItems + 1
                table.insert(itemsToLoad, itemID)
            end
        else
            local alreadyCounted = false
            if TL.SoftRes.availableItems then
                for _, id in ipairs(TL.SoftRes.availableItems) do
                    if id == itemID then
                        alreadyCounted = true
                        break
                    end
                end
            end
            if not alreadyCounted then
                totalItems = totalItems + 1
                itemsLoaded = itemsLoaded + 1
            end
        end
    end
    
    -- Force load items using tooltip
    for _, itemID in ipairs(itemsToLoad) do
        tooltip:SetHyperlink("item:" .. itemID .. ":0:0:0")
        tooltip:Hide()
    end
    
    -- Schedule periodic refreshes to update UI as items load
    if table.getn(itemsToLoad) > 0 then
        local attempts = 0
        local maxAttempts = 10
        
        local function checkAndRefresh()
            attempts = attempts + 1
            local newItemsLoaded = 0
            
            -- Check how many items are now loaded
            for _, itemID in ipairs(itemsToLoad) do
                local itemName = GetItemInfo(itemID)
                if itemName then
                    newItemsLoaded = newItemsLoaded + 1
                end
            end
            
            -- If new items loaded or we haven't reached max attempts, refresh
            if newItemsLoaded > 0 and TL.MainWindow.currentTab == 2 and TL.MainWindow.frame and TL.MainWindow.frame:IsVisible() then
                TL.MainWindow:ShowTab(2)
            end
            
            -- Continue checking if not all items loaded and haven't exceeded max attempts
            if newItemsLoaded < table.getn(itemsToLoad) and attempts < maxAttempts then
                TL:ScheduleTimer(0.5, checkAndRefresh)
            end
        end
        
        TL:ScheduleTimer(0.3, checkAndRefresh)
    end
end

-- Refresh soft res tab when sync data arrives
function TL.MainWindow:RefreshSoftResTab()
    if self.currentTab == 2 and self.frame and self.frame:IsVisible() then
        self:ShowTab(2)
    end
end

-- Soft Res tab
function TL.MainWindow:ShowSoftRes()
    local content = TL.MainWindow.frame.content
    content:Show()
    
    -- Preload items
    TL.MainWindow:PreloadSoftResItems()
    
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetText("Soft Reserves")
    title:Show()
    table.insert(content.children, title)
    
    -- Status bar at top
    local statusBar = CreateFrame("Frame", nil, content)
    statusBar:SetWidth(640)
    statusBar:SetHeight(30)
    statusBar:SetPoint("TOP", content, "TOP", 0, -35)
    statusBar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    statusBar:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    statusBar:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)
    statusBar:Show()
    table.insert(content.children, statusBar)
    
    -- Status text
    local statusText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("CENTER", statusBar, "CENTER", 0, 0)
    statusText:SetJustifyH("LEFT")
    
    -- Determine status
    local inRaid = GetNumRaidMembers() > 0
    local inParty = GetNumPartyMembers() > 0
    local isLeader = TL:IsRaidLeaderOrAssistant()
    local playerName = UnitName("player")
    
    local statusStr = ""
    if inRaid then
        statusStr = "|cff00ff00In Raid|r"
        if isLeader then
            statusStr = statusStr .. " |cffffaa00(Leader/Assist)|r"
        end
    elseif inParty then
        statusStr = "|cffffff00In Party|r"
        if isLeader then
            statusStr = statusStr .. " |cffffaa00(Leader)|r"
        end
    else
        statusStr = "|cffff0000Not in Group|r"
    end
    
    statusText:SetText(statusStr)
    
    -- Sync status indicator (right side of status bar)
    local syncIndicator = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    syncIndicator:SetPoint("RIGHT", statusBar, "RIGHT", -10, 0)
    if TL.Comm and TL.Comm.GetSyncStatusText then
        syncIndicator:SetText(TL.Comm:GetSyncStatusText())
    else
        syncIndicator:SetText("|cff888888Sync: -|r")
    end
    TL.MainWindow.syncIndicator = syncIndicator
    
    -- Button row
    local btnY = -75
    
    -- Import button
    local importBtn = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
    importBtn:SetWidth(100)
    importBtn:SetHeight(25)
    importBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 10, btnY)
    importBtn:SetText("Import CSV")
    importBtn:SetScript("OnClick", function()
        TL.MainWindow:ShowImportDialog("softres")
    end)
    importBtn:Show()
    table.insert(content.children, importBtn)
    
    -- Export button
    local exportBtn = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
    exportBtn:SetWidth(100)
    exportBtn:SetHeight(25)
    exportBtn:SetPoint("LEFT", importBtn, "RIGHT", 5, 0)
    exportBtn:SetText("Export CSV")
    exportBtn:SetScript("OnClick", function()
        local csv = TL.SoftRes:Export()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TurtleLoot]|r CSV exported to chat:")
        DEFAULT_CHAT_FRAME:AddMessage(csv)
    end)
    exportBtn:Show()
    table.insert(content.children, exportBtn)
    
    -- Clear button (only for leader)
    local clearBtn = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
    clearBtn:SetWidth(100)
    clearBtn:SetHeight(25)
    clearBtn:SetPoint("LEFT", exportBtn, "RIGHT", 5, 0)
    clearBtn:SetText("Clear All")
    if not isLeader then
        clearBtn:Disable()
    end
    clearBtn:SetScript("OnClick", function()
        StaticPopup_Show("TURTLELOOT_SOFTRES_CLEAR")
    end)
    clearBtn:Show()
    table.insert(content.children, clearBtn)
    
    -- Refresh button
    local refreshBtn = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
    refreshBtn:SetWidth(80)
    refreshBtn:SetHeight(25)
    refreshBtn:SetPoint("LEFT", clearBtn, "RIGHT", 5, 0)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function()
        TL.MainWindow:ShowTab(2) -- Refresh
    end)
    refreshBtn:Show()
    table.insert(content.children, refreshBtn)
    
    -- Stats
    local itemCount = 0
    local playerCount = 0
    local myReserveCount = 0
    for _ in pairs(TL.SoftRes.data) do
        itemCount = itemCount + 1
    end
    for _ in pairs(TL.SoftRes.playerReserves) do
        playerCount = playerCount + 1
    end
    if TL.SoftRes.playerReserves[playerName] then
        myReserveCount = table.getn(TL.SoftRes.playerReserves[playerName])
    end
    
    local maxReserves = TL.Settings:Get("softRes.maxReservesPerPlayer") or 2
    local reserveColor = myReserveCount >= maxReserves and "|cffff8000" or "|cff00ff00"
    
    local statsText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsText:SetPoint("TOPLEFT", content, "TOPLEFT", 10, btnY - 35)
    statsText:SetJustifyH("LEFT")
    statsText:SetText("|cff00ff00Items:|r " .. itemCount .. "  |  |cff00ff00Players:|r " .. playerCount .. "  |  " .. reserveColor .. "My Reserves:|r " .. myReserveCount .. "/" .. maxReserves)
    statsText:Show()
    table.insert(content.children, statsText)
    
    -- FILTER ROW
    local filterY = btnY - 55
    
    -- Quality Filter Label
    local qualityLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qualityLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 10, filterY)
    qualityLabel:SetText("Quality:")
    table.insert(content.children, qualityLabel)
    
    -- Quality filter buttons (All, Epic, Legendary)
    local qualityFilters = {
        {name = "All", quality = 0, color = "|cffffffff"},
        {name = "Rare+", quality = 3, color = "|cff0070dd"},
        {name = "Epic+", quality = 4, color = "|cffa335ee"},
        {name = "Legendary", quality = 5, color = "|cffff8000"}
    }
    
    local currentQualityFilter = TL.MainWindow.qualityFilter or 0
    
    for i, filter in ipairs(qualityFilters) do
        local btnFilter = filter -- Capture for closures
        local qBtn = CreateFrame("Button", nil, content)
        qBtn:SetWidth(55)
        qBtn:SetHeight(18)
        qBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 50 + (i-1) * 60, filterY + 3)
        
        local qText = qBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        qText:SetPoint("CENTER", qBtn, "CENTER", 0, 0)
        qText:SetText(btnFilter.color .. btnFilter.name .. "|r")
        qBtn.text = qText
        
        -- Highlight if selected
        local qBg = qBtn:CreateTexture(nil, "BACKGROUND")
        qBg:SetAllPoints()
        qBg:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        qBg:SetBlendMode("ADD")
        qBg:SetAlpha(currentQualityFilter == btnFilter.quality and 0.5 or 0)
        qBtn.bg = qBg
        
        qBtn:SetScript("OnClick", function()
            TL.MainWindow.qualityFilter = btnFilter.quality
            TL.MainWindow:ShowTab(2)
        end)
        
        qBtn:SetScript("OnEnter", function()
            qBg:SetAlpha(0.3)
        end)
        qBtn:SetScript("OnLeave", function()
            qBg:SetAlpha(currentQualityFilter == btnFilter.quality and 0.5 or 0)
        end)
        
        table.insert(content.children, qBtn)
    end
    
    -- "My Reserves Only" checkbox
    local myResCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    myResCheck:SetWidth(24)
    myResCheck:SetHeight(24)
    myResCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 300, filterY + 5)
    myResCheck:SetChecked(TL.MainWindow.showMyReservesOnly or false)
    myResCheck:SetScript("OnClick", function()
        TL.MainWindow.showMyReservesOnly = this:GetChecked()
        TL.MainWindow:ShowTab(2)
    end)
    table.insert(content.children, myResCheck)
    
    local myResLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    myResLabel:SetPoint("LEFT", myResCheck, "RIGHT", 2, 0)
    myResLabel:SetText("My Reserves Only")
    table.insert(content.children, myResLabel)
    
    -- Two column layout: Available Items (left) and All Reserves (right)
    local leftPanel = CreateFrame("Frame", nil, content)
    leftPanel:SetWidth(320)
    leftPanel:SetPoint("TOPLEFT", content, "TOPLEFT", 5, btnY - 65)
    leftPanel:SetPoint("BOTTOM", content, "BOTTOM", 0, 5)
    leftPanel:Show()
    table.insert(content.children, leftPanel)
    
    local rightPanel = CreateFrame("Frame", nil, content)
    rightPanel:SetWidth(320)
    rightPanel:SetPoint("TOPRIGHT", content, "TOPRIGHT", -5, btnY - 65)
    rightPanel:SetPoint("BOTTOM", content, "BOTTOM", 0, 5)
    rightPanel:Show()
    table.insert(content.children, rightPanel)
    
    -- LEFT: Available Items
    local leftTitle = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftTitle:SetPoint("TOP", leftPanel, "TOP", 0, 0)
    leftTitle:SetText("|cffffaa00Available Items|r")
    
    -- Search box for left panel
    local leftSearchBox = CreateFrame("EditBox", nil, leftPanel, "InputBoxTemplate")
    leftSearchBox:SetWidth(200)
    leftSearchBox:SetHeight(20)
    leftSearchBox:SetPoint("TOP", leftPanel, "TOP", 0, -20)
    leftSearchBox:SetAutoFocus(false)
    leftSearchBox:SetText("Search...")
    leftSearchBox:SetTextInsets(5, 5, 0, 0)
    leftSearchBox:SetScript("OnEnterPressed", function()
        this:ClearFocus()
        TL.MainWindow:ShowTab(2) -- Refresh with filter
    end)
    leftSearchBox:SetScript("OnEscapePressed", function()
        this:ClearFocus()
        this:SetText("Search...")
        TL.MainWindow:ShowTab(2) -- Refresh
    end)
    leftSearchBox:SetScript("OnEditFocusGained", function()
        if this:GetText() == "Search..." then
            this:SetText("")
        end
    end)
    leftSearchBox:SetScript("OnEditFocusLost", function()
        if this:GetText() == "" then
            this:SetText("Search...")
        end
    end)
    leftSearchBox:Show()
    table.insert(content.children, leftSearchBox)
    
    -- Store search box reference for filtering
    TL.MainWindow.leftSearchBox = leftSearchBox
    
    local leftScroll = CreateFrame("ScrollFrame", nil, leftPanel)
    leftScroll:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 0, -20)
    leftScroll:SetPoint("BOTTOMRIGHT", leftPanel, "BOTTOMRIGHT", -20, 0)
    leftScroll:EnableMouseWheel(true)
    leftScroll:SetScript("OnMouseWheel", function()
        local current = this:GetVerticalScroll()
        local maxScroll = this:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(maxScroll, current - (arg1 * 20)))
        this:SetVerticalScroll(newScroll)
        if this.scrollBar then
            this.scrollBar:SetValue(newScroll)
        end
    end)
    leftScroll:Show()
    
    local leftChild = CreateFrame("Frame", nil, leftScroll)
    leftChild:SetWidth(280)
    leftChild:SetHeight(1)
    leftScroll:SetScrollChild(leftChild)
    
    -- Add scrollbar
    local leftScrollBar = CreateFrame("Slider", nil, leftScroll)
    leftScrollBar:SetPoint("TOPRIGHT", leftPanel, "TOPRIGHT", -2, -22)
    leftScrollBar:SetPoint("BOTTOMRIGHT", leftPanel, "BOTTOMRIGHT", -2, 2)
    leftScrollBar:SetWidth(16)
    leftScrollBar:SetOrientation("VERTICAL")
    leftScrollBar:SetMinMaxValues(0, 1)
    leftScrollBar:SetValue(0)
    leftScrollBar:SetValueStep(1)
    leftScrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    leftScrollBar:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")
    leftScrollBar:SetScript("OnValueChanged", function(self, value)
        leftScroll:SetVerticalScroll(value)
    end)
    leftScrollBar:Show() -- Ensure scrollbar is visible
    leftScroll.scrollBar = leftScrollBar
    
    -- Enable mouse wheel scrolling
    leftScroll:EnableMouseWheel(true)
    leftScroll:SetScript("OnMouseWheel", function()
        local current = leftScroll:GetVerticalScroll()
        local step = 30  -- Pixels per scroll
        if arg1 > 0 then  -- Scroll up
            leftScroll:SetVerticalScroll(math.max(0, current - step))
        else  -- Scroll down
            local maxScroll = leftScroll:GetVerticalScrollRange()
            leftScroll:SetVerticalScroll(math.min(maxScroll, current + step))
        end
        -- Update scrollbar position
        if leftScroll.scrollBar then
            leftScroll.scrollBar:SetValue(leftScroll:GetVerticalScroll())
        end
    end)
    
    -- Store reference to container for refreshing
    local leftContainer = leftChild
    TL.MainWindow.softResContainer = leftContainer
    
    -- Create event frame OUTSIDE the container (parented to leftPanel so it survives cleanup)
    if not TL.MainWindow.softResEventFrame then
        local eventFrame = CreateFrame("Frame", nil, leftPanel)
        eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        eventFrame:SetScript("OnEvent", function()
            -- Refresh visible items when item info arrives
            if TL.MainWindow.softResContainer and TL.MainWindow.softResContainer:IsVisible() then
                local children = {TL.MainWindow.softResContainer:GetChildren()}
                for _, child in ipairs(children) do
                    if child.itemID then
                        local name, link, rarity, _, _, _, _, _, tex = GetItemInfo(child.itemID)
                        if name and child.name and child.icon then
                            local colorCode = TL:GetQualityColor(rarity or 1)
                            child.name:SetText("|cff" .. colorCode .. name .. "|r")
                            child.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
                        end
                    end
                end
            end
        end)
        TL.MainWindow.softResEventFrame = eventFrame
    end
    
    -- Clear previous items in the scroll child
    local existingChildren = {leftChild:GetChildren()}
    for _, child in ipairs(existingChildren) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Build available items list
    local availableItems = {}
    local searchText = ""
    if TL.MainWindow.leftSearchBox then
        searchText = string.lower(TL.MainWindow.leftSearchBox:GetText() or "")
        if searchText == "search..." then
            searchText = ""
        end
    end
    
            if TL.SoftRes.availableItems then
        local filterQuality = TL.MainWindow.qualityFilter or 0
        local filterMyRes = TL.MainWindow.showMyReservesOnly
        local myReserves = TL.SoftRes.playerReserves[UnitName("player")] or {}
        
        for _, itemID in ipairs(TL.SoftRes.availableItems) do
            -- Get item info from cache
            local itemName, itemLink, itemRarity, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
            
            -- If not in cache, create placeholder link and force cache
            if not itemLink then
                itemLink = TL:GetItemLinkFromID(itemID)
                -- Force item query using hidden tooltip
                if not TL.MainWindow.hiddenTooltip then
                    TL.MainWindow.hiddenTooltip = CreateFrame("GameTooltip", "TLHiddenTooltip", UIParent, "GameTooltipTemplate")
                    TL.MainWindow.hiddenTooltip:SetOwner(UIParent, "ANCHOR_NONE")
                end
                TL.MainWindow.hiddenTooltip:SetHyperlink("item:" .. itemID .. ":0:0:0")
            end
            
            -- Filter logic
            local shouldInclude = true
            
            -- 1. Search filter
            if searchText ~= "" then
                local itemNameLower = string.lower(itemName or "")
                local itemIDStr = tostring(itemID)
                if not string.find(itemNameLower, searchText, 1, true) and not string.find(itemIDStr, searchText, 1, true) then
                    shouldInclude = false
                end
            end
            
            -- 2. Quality filter
            if shouldInclude and filterQuality > 0 then
                local rarity = itemRarity or 1  -- Default to Common if unknown
                if rarity < filterQuality then
                    shouldInclude = false
                end
            end
            
            -- 3. My Reserves Only filter
            if shouldInclude and filterMyRes then
                if not TL:InTable(myReserves, itemID) then
                    shouldInclude = false
                end
            end
            
            if shouldInclude then
                table.insert(availableItems, {
                    itemID = itemID,
                    itemLink = itemLink,
                    itemName = itemName,
                    itemIcon = itemIcon,
                    itemRarity = itemRarity or 1
                })
            end
        end
    end
    
    local leftY = 0
    if table.getn(availableItems) == 0 then
        local noItems = leftChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noItems:SetPoint("TOP", leftChild, "TOP", 0, -10)
        noItems:SetText("|cffaaaaaa(No items available)|r\n\nLeader can generate list\nfrom Atlas tab")
        leftY = 60
    else
        for i, item in ipairs(availableItems) do
            -- Skip nil items
            if item and item.itemID then
                -- Capture item data in local variables for closures
                local currentItemID = item.itemID
                local currentItemLink = item.itemLink
                local currentItemName = item.itemName or "Loading Item..."
                local currentItemIcon = item.itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
                
                -- Make it a button so it's clickable
                local bar = CreateFrame("Button", nil, leftChild)
                bar:SetWidth(270)
                bar:SetHeight(24) -- Taller for icon
                bar:SetPoint("TOPLEFT", leftChild, "TOPLEFT", 0, -leftY)
                bar:SetBackdrop({
                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                    tile = true,
                    tileSize = 16,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 }
                })
                bar:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
                
                -- Store ID for refresh
                bar.itemID = currentItemID
            
                -- Icon
                local icon = bar:CreateTexture(nil, "ARTWORK")
                icon:SetWidth(20)
                icon:SetHeight(20)
                icon:SetPoint("LEFT", bar, "LEFT", 2, 0)
                icon:SetTexture(currentItemIcon)
                bar.icon = icon
                
                -- Name
                local nameText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
                nameText:SetWidth(230)
                nameText:SetJustifyH("LEFT")
                local colorCode = TL:GetQualityColor(item.itemRarity or 1)
                nameText:SetText("|cff" .. colorCode .. currentItemName .. "|r")
                bar.name = nameText
            
                -- Check if player already has this reserved
                local playerName = UnitName("player")
                local hasReserved = false
                if TL.SoftRes.data[currentItemID] then
                    for _, pName in ipairs(TL.SoftRes.data[currentItemID]) do
                        if pName == playerName then
                            hasReserved = true
                            break
                        end
                    end
                end
                
                -- Highlight if reserved
                if hasReserved then
                    bar:SetBackdropColor(0.2, 0.4, 0.2, 0.5)
                end
                
                -- Click handler
                bar:SetScript("OnClick", function()
                    if hasReserved then
                        TL.SoftRes:RemoveReserve(currentItemID)
                    else
                        TL.SoftRes:AddReserve(currentItemID)
                    end
                    -- Update UI
                    TL.MainWindow:ShowTab(2)
                end)
                
                -- Hover
                bar:SetScript("OnEnter", function()
                    bar:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
                    GameTooltip:SetOwner(bar, "ANCHOR_RIGHT")
                    -- Use hyperlink for tooltip (1.12 compatible)
                    GameTooltip:SetHyperlink("item:" .. currentItemID .. ":0:0:0")
                    GameTooltip:Show()
                end)
                bar:SetScript("OnLeave", function()
                    if hasReserved then
                        bar:SetBackdropColor(0.2, 0.4, 0.2, 0.5)
                    else
                        bar:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
                    end
                    GameTooltip:Hide()
                end)
                
                bar:Show()
                
                leftY = leftY + 25 -- Spacing
            end
        end
    end
    
    leftChild:SetHeight(math.max(leftY, 1))

    
    -- Update scrollbar range
    if leftScroll.scrollBar then
        local maxScroll = leftScroll:GetVerticalScrollRange()
        leftScroll.scrollBar:SetMinMaxValues(0, maxScroll)
        if maxScroll > 0 then
            leftScroll.scrollBar:Show()
        else
            leftScroll.scrollBar:Hide()
        end
    end
    
    -- RIGHT: All Reserves
    local rightTitle = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rightTitle:SetPoint("TOP", rightPanel, "TOP", 0, 0)
    rightTitle:SetText("|cffffaa00All Reserves|r")
    
    -- Sort buttons
    local sortByName = CreateFrame("Button", nil, rightPanel)
    sortByName:SetWidth(60)
    sortByName:SetHeight(18)
    sortByName:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, -20)
    sortByName.text = sortByName:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sortByName.text:SetPoint("CENTER", sortByName, "CENTER", 0, 0)
    sortByName.text:SetText("Name")
    sortByName:SetScript("OnClick", function()
        TL.MainWindow.sortMode = "name"
        TL.MainWindow:ShowTab(2)
    end)
    sortByName:Show()
    
    local sortByQuality = CreateFrame("Button", nil, rightPanel)
    sortByQuality:SetWidth(60)
    sortByQuality:SetHeight(18)
    sortByQuality:SetPoint("LEFT", sortByName, "RIGHT", 5, 0)
    sortByQuality.text = sortByQuality:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sortByQuality.text:SetPoint("CENTER", sortByQuality, "CENTER", 0, 0)
    sortByQuality.text:SetText("Quality")
    sortByQuality:SetScript("OnClick", function()
        TL.MainWindow.sortMode = "quality"
        TL.MainWindow:ShowTab(2)
    end)
    sortByQuality:Show()
    
    local sortByCount = CreateFrame("Button", nil, rightPanel)
    sortByCount:SetWidth(60)
    sortByCount:SetHeight(18)
    sortByCount:SetPoint("LEFT", sortByQuality, "RIGHT", 5, 0)
    sortByCount.text = sortByCount:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sortByCount.text:SetPoint("CENTER", sortByCount, "CENTER", 0, 0)
    sortByCount.text:SetText("Count")
    sortByCount:SetScript("OnClick", function()
        TL.MainWindow.sortMode = "count"
        TL.MainWindow:ShowTab(2)
    end)
    sortByCount:Show()
    
    -- Highlight active sort
    TL.MainWindow.sortMode = TL.MainWindow.sortMode or "count"
    if TL.MainWindow.sortMode == "name" then
        sortByName.text:SetFontObject("GameFontHighlightSmall")
    elseif TL.MainWindow.sortMode == "quality" then
        sortByQuality.text:SetFontObject("GameFontHighlightSmall")
    else
        sortByCount.text:SetFontObject("GameFontHighlightSmall")
    end
    
    local rightScroll = CreateFrame("ScrollFrame", nil, rightPanel)
    rightScroll:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, -42)
    rightScroll:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -20, 0)
    rightScroll:Show()
    
    local rightChild = CreateFrame("Frame", nil, rightScroll)
    rightChild:SetWidth(280)
    rightChild:SetHeight(1)
    rightScroll:SetScrollChild(rightChild)
    
    -- Build reserves list
    local reserves = {}
    for itemID, players in pairs(TL.SoftRes.data) do
        -- Get item info from cache
        local itemName, itemLink, itemRarity = GetItemInfo(itemID)
        
        -- If not in cache, use helper function to create proper link
        if not itemLink then
            itemLink = TL:GetItemLinkFromID(itemID)
        end
        
        local playerList = {}
        for _, pName in ipairs(players) do
            table.insert(playerList, pName)
        end
        table.insert(reserves, {
            itemID = itemID,
            itemLink = itemLink,
            itemName = itemName or ("Item " .. itemID),
            quality = itemRarity or 0,
            players = playerList,
            count = table.getn(playerList)
        })
    end
    
    -- Sort based on selected mode
    local sortMode = TL.MainWindow.sortMode or "count"
    if sortMode == "name" then
        table.sort(reserves, function(a, b)
            return a.itemName < b.itemName
        end)
    elseif sortMode == "quality" then
        table.sort(reserves, function(a, b)
            if a.quality == b.quality then
                return a.itemName < b.itemName
            end
            return a.quality > b.quality
        end)
    else -- count
        table.sort(reserves, function(a, b)
            if a.count == b.count then
                return a.itemName < b.itemName
            end
            return a.count > b.count
        end)
    end
    
    local rightY = 0
    if table.getn(reserves) == 0 then
        local noReserves = rightChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noReserves:SetPoint("TOP", rightChild, "TOP", 0, -10)
        noReserves:SetText("|cffaaaaaa(No reserves yet)|r")
        rightY = 30
    else
        for i, res in ipairs(reserves) do
            local bar = CreateFrame("Frame", nil, rightChild)
            bar:SetWidth(270)
            bar:SetHeight(20)
            bar:SetPoint("TOPLEFT", rightChild, "TOPLEFT", 0, -rightY)
            bar:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                tile = true,
                tileSize = 16,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            bar:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            bar:Show()
            
            -- Add item icon (larger and more visible)
            local iconTexture = bar:CreateTexture(nil, "ARTWORK")
            iconTexture:SetWidth(18)
            iconTexture:SetHeight(18)
            iconTexture:SetPoint("LEFT", bar, "LEFT", 2, 0)
            
            -- Try to get item info (may be nil if not cached)
            local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(res.itemID)
            
            -- If not cached, force query by creating a temporary tooltip
            if not itemName then
                -- Create hidden tooltip to force item query
                if not TL.MainWindow.hiddenTooltip then
                    TL.MainWindow.hiddenTooltip = CreateFrame("GameTooltip", "TLHiddenTooltip", UIParent, "GameTooltipTemplate")
                    TL.MainWindow.hiddenTooltip:SetOwner(UIParent, "ANCHOR_NONE")
                end
                TL.MainWindow.hiddenTooltip:SetHyperlink("item:" .. res.itemID .. ":0:0:0")
                TL.MainWindow.hiddenTooltip:Hide()
                
                -- Try again after forcing query
                itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(res.itemID)
            end
            
            -- Set icon
            if itemTexture then
                iconTexture:SetTexture(itemTexture)
            else
                -- Default icon if item not cached
                iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            
            -- Display item name with proper color
            local itemText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            itemText:SetPoint("LEFT", bar, "LEFT", 24, 0)
            itemText:SetWidth(175)
            itemText:SetJustifyH("LEFT")
            
            -- Get item info to display name with color
            local displayName = "Loading..."
            local r, g, b = 0.7, 0.7, 0.7
            
            if itemName then
                displayName = itemName
                -- Set color based on rarity
                if itemRarity then
                    local qualityColor = ITEM_QUALITY_COLORS[itemRarity]
                    if qualityColor then
                        r, g, b = qualityColor.r, qualityColor.g, qualityColor.b
                    end
                end
            else
                -- Item not cached, show ID
                displayName = "[Item " .. res.itemID .. "]"
            end
            
            itemText:SetText(displayName)
            itemText:SetTextColor(r, g, b)
            
            local countText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            countText:SetPoint("RIGHT", bar, "RIGHT", -5, 0)
            countText:SetJustifyH("RIGHT")
            countText:SetText("|cff00ff00" .. res.count .. "|r")
            
            rightY = rightY + 22
        end
    end
    rightChild:SetHeight(math.max(rightY, 1))
end

-- Plus Ones tab
function TL.MainWindow:ShowPlusOnes()
    DEFAULT_CHAT_FRAME:AddMessage("[TL DEBUG] ShowPlusOnes called")
    local content = TL.MainWindow.frame.content
    DEFAULT_CHAT_FRAME:AddMessage("[TL DEBUG] Content frame: " .. tostring(content))
    
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -20)
    title:SetText("Plus Ones")
    title:Show()
    table.insert(content.children, title)
    
    -- Import button
    local importBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    importBtn:SetWidth(100)
    importBtn:SetHeight(25)
    importBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -50)
    importBtn:SetText("Import CSV")
    importBtn:SetScript("OnClick", function()
        TL.MainWindow:ShowImportDialog("plusones")
    end)
    importBtn:Show()
    table.insert(content.children, importBtn)
    
    -- Export button
    local exportBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    exportBtn:SetWidth(100)
    exportBtn:SetHeight(25)
    exportBtn:SetPoint("LEFT", importBtn, "RIGHT", 5, 0)
    exportBtn:SetText("Export CSV")
    exportBtn:SetScript("OnClick", function()
        local csv = TL.PlusOnes:Export()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TurtleLoot]|r CSV exported to chat:")
        DEFAULT_CHAT_FRAME:AddMessage(csv)
    end)
    exportBtn:Show()
    table.insert(content.children, exportBtn)
    
    -- Clear button
    local clearBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    clearBtn:SetWidth(100)
    clearBtn:SetHeight(25)
    clearBtn:SetPoint("LEFT", exportBtn, "RIGHT", 5, 0)
    clearBtn:SetText("Clear All")
    clearBtn:SetScript("OnClick", function()
        TL.PlusOnes:Clear()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TurtleLoot]|r All plus ones cleared!")
        TL.MainWindow:ShowTab(3) -- Refresh
    end)
    clearBtn:Show()
    table.insert(content.children, clearBtn)
    
    -- Add points to all button
    local addAllBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    addAllBtn:SetWidth(120)
    addAllBtn:SetHeight(25)
    addAllBtn:SetPoint("LEFT", clearBtn, "RIGHT", 5, 0)
    addAllBtn:SetText("Add +1 to All")
    addAllBtn:SetScript("OnClick", function()
        -- Add 1 point to all raid members
        local count = 0
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                local name = GetRaidRosterInfo(i)
                if name then
                    TL.PlusOnes:Add(name, 1)
                    count = count + 1
                end
            end
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                local name = UnitName("party"..i)
                if name then
                    TL.PlusOnes:Add(name, 1)
                    count = count + 1
                end
            end
            -- Add player
            TL.PlusOnes:Add(TL:GetPlayerName(), 1)
            count = count + 1
        end
        TL:Success("Added +1 to " .. count .. " players")
        TL.MainWindow:ShowTab(3) -- Refresh
    end)
    addAllBtn:Show()
    table.insert(content.children, addAllBtn)
    
    -- ScrollFrame for player list
    local scrollFrame = CreateFrame("ScrollFrame", nil, content)
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -85)
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -30, 10)
    scrollFrame:Show()
    table.insert(content.children, scrollFrame)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(620)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Get all players with points
    local players = {}
    for playerName, points in pairs(TL.PlusOnes.data) do
        table.insert(players, {name = playerName, points = points})
    end
    
    -- Sort by points descending
    table.sort(players, function(a, b)
        if a.points == b.points then
            return a.name < b.name
        end
        return a.points > b.points
    end)
    
    local yOffset = 0
    for i, playerData in ipairs(players) do
        -- Capture values in local variables to avoid closure issues
        local playerName = playerData.name
        local playerPoints = playerData.points
        
        local bar = CreateFrame("Frame", nil, scrollChild)
        bar:SetWidth(600)
        bar:SetHeight(30)
        bar:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        
        -- Background
        bar:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        bar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        bar:Show()
        
        -- Player name
        local nameText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", bar, "LEFT", 10, 0)
        nameText:SetWidth(200)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(playerName)
        
        -- Points
        local pointsText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        pointsText:SetPoint("LEFT", nameText, "RIGHT", 20, 0)
        pointsText:SetWidth(80)
        pointsText:SetJustifyH("LEFT")
        pointsText:SetText("|cff00ff00+" .. playerPoints .. "|r")
        
        -- Minus button
        local minusBtn = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
        minusBtn:SetWidth(30)
        minusBtn:SetHeight(20)
        minusBtn:SetPoint("LEFT", pointsText, "RIGHT", 20, 0)
        minusBtn:SetText("-")
        minusBtn:SetScript("OnClick", function()
            TL.PlusOnes:Add(playerName, -1)
            TL.MainWindow:ShowTab(3) -- Refresh
        end)
        minusBtn:Show()
        
        -- Plus button
        local plusBtn = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
        plusBtn:SetWidth(30)
        plusBtn:SetHeight(20)
        plusBtn:SetPoint("LEFT", minusBtn, "RIGHT", 5, 0)
        plusBtn:SetText("+")
        plusBtn:SetScript("OnClick", function()
            TL.PlusOnes:Add(playerName, 1)
            TL.MainWindow:ShowTab(3) -- Refresh
        end)
        plusBtn:Show()
        
        -- Set to 0 button
        local zeroBtn = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
        zeroBtn:SetWidth(60)
        zeroBtn:SetHeight(20)
        zeroBtn:SetPoint("LEFT", plusBtn, "RIGHT", 5, 0)
        zeroBtn:SetText("Set 0")
        zeroBtn:SetScript("OnClick", function()
            TL.PlusOnes:Set(playerName, 0)
            TL.MainWindow:ShowTab(3) -- Refresh
        end)
        zeroBtn:Show()
        
        yOffset = yOffset + 35
    end
    
    scrollChild:SetHeight(math.max(yOffset, 1))
end

-- GDKP tab
function TL.MainWindow:ShowGDKP()
    local content = TL.MainWindow.frame.content
    
    -- Create title frame first, then add fontstring to it
    local titleFrame = CreateFrame("Frame", nil, content)
    titleFrame:SetWidth(600)
    titleFrame:SetHeight(30)
    titleFrame:SetPoint("TOP", content, "TOP", 0, -20)
    titleFrame:Show()
    
    local title = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", titleFrame, "CENTER", 0, 0)
    title:SetText("GDKP")
    title:Show()
    table.insert(content.children, titleFrame)
    
    -- Create session button
    local createBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    createBtn:SetWidth(120)
    createBtn:SetHeight(25)
    createBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -50)
    createBtn:SetText("Create Session")
    createBtn:SetScript("OnClick", function()
        TL.GDKP:CreateSession("GDKP " .. TL:FormatDate(TL:GetTimestamp()))
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TurtleLoot]|r GDKP session created!")
        TL.MainWindow:ShowTab(4) -- Refresh
    end)
    createBtn:Show()
    table.insert(content.children, createBtn)
    
    if TL.GDKP.activeSession then
        -- Close session button
        local closeBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        closeBtn:SetWidth(120)
        closeBtn:SetHeight(25)
        closeBtn:SetPoint("LEFT", createBtn, "RIGHT", 5, 0)
        closeBtn:SetText("Close Session")
        closeBtn:SetScript("OnClick", function()
            TL.GDKP:CloseSession()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TurtleLoot]|r GDKP session closed!")
            TL.MainWindow:ShowTab(4) -- Refresh
        end)
        closeBtn:Show()
        table.insert(content.children, closeBtn)
        
        -- Distribute gold button
        local distBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        distBtn:SetWidth(120)
        distBtn:SetHeight(25)
        distBtn:SetPoint("LEFT", closeBtn, "RIGHT", 5, 0)
        distBtn:SetText("Distribute Gold")
        distBtn:SetScript("OnClick", function()
            TL.GDKP:DistributeGold()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TurtleLoot]|r Gold distribution calculated!")
            TL.MainWindow:ShowTab(4) -- Refresh
        end)
        distBtn:Show()
        table.insert(content.children, distBtn)
        
        -- Export button
        local exportBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        exportBtn:SetWidth(120)
        exportBtn:SetHeight(25)
        exportBtn:SetPoint("LEFT", distBtn, "RIGHT", 5, 0)
        exportBtn:SetText("Export CSV")
        exportBtn:SetScript("OnClick", function()
            local csv = TL.GDKP:ExportSession(TL.GDKP.activeSession.id)
            TL:Print("CSV exported to chat:")
            TL:Print(csv)
        end)
        exportBtn:Show()
        table.insert(content.children, exportBtn)
        
        -- Session info
        local sessionInfo = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sessionInfo:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -85)
        sessionInfo:SetJustifyH("LEFT")
        sessionInfo:SetWidth(600)
        sessionInfo:SetText(
            "Session: " .. TL.GDKP.activeSession.name .. "\n" ..
            "Pot: |cffffd700" .. TL:FormatGold(TL.GDKP.activeSession.pot * 10000) .. "|r  |  " ..
            "Auctions: " .. table.getn(TL.GDKP.activeSession.auctions)
        )
        sessionInfo:Show()
        table.insert(content.children, sessionInfo)
        
        -- Distribution status if exists
        if TL.GDKP.activeSession.distribution then
            local distStatus = TL.GDKP:GetDistributionStatus()
            local distText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            distText:SetPoint("TOPLEFT", sessionInfo, "BOTTOMLEFT", 0, -10)
            distText:SetJustifyH("LEFT")
            distText:SetWidth(600)
            distText:SetText(
                "Distribution: " .. distStatus.paid .. "/" .. distStatus.total .. " paid  |  " ..
                "|cff00ff00" .. TL:FormatGold(distStatus.totalDistributed) .. "|r distributed  |  " ..
                "|cffff8000" .. TL:FormatGold(distStatus.totalRemaining) .. "|r remaining"
            )
            distText:Show()
            table.insert(content.children, distText)
        end
        
        -- === ACTIVE AUCTION PANEL ===
        local topY = -140
        
        if TL.GDKP.activeAuction then
            local aucFrame = CreateFrame("Frame", nil, content)
            aucFrame:SetWidth(620)
            aucFrame:SetHeight(100)
            aucFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 10, topY)
            aucFrame:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            aucFrame:SetBackdropColor(0, 0, 0, 0.8)
            aucFrame:SetBackdropBorderColor(1, 0.82, 0) -- Gold border
            
            -- Item Icon
            local icon = aucFrame:CreateTexture(nil, "ARTWORK")
            icon:SetWidth(48)
            icon:SetHeight(48)
            icon:SetPoint("LEFT", 15, 0)
            -- Async get item info
            local itemName, itemLink, itemRarity, _, _, _, _, _, itemIcon = GetItemInfo(TL.GDKP.activeAuction.itemID)
            icon:SetTexture(itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
            
            -- Item Name
            local nameText = aucFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 15, 5)
            nameText:SetText(itemLink or TL.GDKP.activeAuction.itemLink)
            
            -- Current Bid
            local bidText = aucFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
            bidText:SetPoint("TOPRIGHT", -20, -10)
            if TL.GDKP.activeAuction.currentBid > 0 then
                bidText:SetText(TL:FormatGold(TL.GDKP.activeAuction.currentBid * 10000))
            else
                bidText:SetText("No Bids")
            end
            
            local bidderText = aucFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            bidderText:SetPoint("TOPRIGHT", bidText, "BOTTOMRIGHT", 0, -5)
            bidderText:SetText(TL.GDKP.activeAuction.currentBidder or "")
            
            -- Min Bid Label
            local minBidText = aucFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            minBidText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 15, 5)
            minBidText:SetText("Min Bid: " .. TL:FormatGold(TL.GDKP.activeAuction.minBid * 10000))

            -- Actions
            if TL.GDKP.activeAuction.auctioneer == TL:GetPlayerName() then
                -- End Auction Button (ML)
                local endBtn = CreateFrame("Button", nil, aucFrame, "UIPanelButtonTemplate")
                endBtn:SetWidth(100)
                endBtn:SetHeight(25)
                endBtn:SetPoint("BOTTOMRIGHT", -15, 10)
                endBtn:SetText("End Auction")
                endBtn:SetScript("OnClick", function()
                    TL.GDKP:EndAuction()
                end)
            else
                -- Bid Button
                local bidBtn = CreateFrame("Button", nil, aucFrame, "UIPanelButtonTemplate")
                bidBtn:SetWidth(80)
                bidBtn:SetHeight(25)
                bidBtn:SetPoint("BOTTOMRIGHT", -15, 10)
                bidBtn:SetText("Bid Min")
                bidBtn:SetScript("OnClick", function()
                    local nextBid = math.max(TL.GDKP.activeAuction.minBid, TL.GDKP.activeAuction.currentBid + TL.GDKP.activeAuction.increment)
                    TL.GDKP:PlaceBid(nextBid)
                end)
                
                -- Custom Bid
                local customBid = CreateFrame("EditBox", nil, aucFrame, "InputBoxTemplate")
                customBid:SetWidth(60)
                customBid:SetHeight(20)
                customBid:SetPoint("RIGHT", bidBtn, "LEFT", -10, 0)
                customBid:SetAutoFocus(false)
                
                local customBtn = CreateFrame("Button", nil, aucFrame, "UIPanelButtonTemplate")
                customBtn:SetWidth(60)
                customBtn:SetHeight(25)
                customBtn:SetPoint("RIGHT", customBid, "LEFT", -5, 0)
                customBtn:SetText("Bid")
                customBtn:SetScript("OnClick", function()
                    local amount = tonumber(customBid:GetText())
                    if amount then TL.GDKP:PlaceBid(amount) end
                end)
            end
            
            table.insert(content.children, aucFrame)
            topY = topY - 110 -- Shift history down
        end
        
        -- ScrollFrame for auctions
        local scrollFrame = CreateFrame("ScrollFrame", nil, content)
        scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 10, topY - 10)
        scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -30, 10)
        scrollFrame:Show()
        table.insert(content.children, scrollFrame)
        

        
        -- Event listener for real-time updates
        local eventFrame = CreateFrame("Frame", nil, content)
        
        -- Register custom events (using TL.Events internally via RegisterEvent if mapped, but here we need to hook into TL.Events)
        -- Since TL.Events:Register stores callbacks, we register a callback that refreshing this tab
        
        local function RefreshGDKP()
            if TL.MainWindow.currentTab == 4 and TL.MainWindow.frame:IsVisible() then
                TL.MainWindow:ShowGDKP()
            end
        end
        
        -- We bind these to the content frame's OnHide to unregister? 
        -- Actually, TL.Events doesn't have easy unregister for anonymous functions.
        -- Let's use a named reference or just check visibility in the callback.
        
        TL.Events:Register("GDKP_BID_PLACED", RefreshGDKP)
        TL.Events:Register("GDKP_BID_RECEIVED", RefreshGDKP)
        TL.Events:Register("GDKP_AUCTION_STARTED", RefreshGDKP)
        TL.Events:Register("GDKP_AUCTION_ENDED", RefreshGDKP)
        TL.Events:Register("GDKP_AUCTION_START_RECEIVED", RefreshGDKP)
        
        -- Clean up checking
        -- Ideally we'd remove these listeners when tab changes, but checking visibility is safe enough for now.
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetWidth(620)
        scrollChild:SetHeight(1)
        scrollFrame:SetScrollChild(scrollChild)
        
        local yOffset = 0
        for i, auction in ipairs(TL.GDKP.activeSession.auctions) do
            local bar = CreateFrame("Frame", nil, scrollChild)
            bar:SetWidth(600)
            bar:SetHeight(25)
            bar:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
            
            -- Background
            bar:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            bar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            bar:Show()
            
            -- Item
            local itemText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            itemText:SetPoint("LEFT", bar, "LEFT", 8, 0)
            itemText:SetWidth(300)
            itemText:SetJustifyH("LEFT")
            itemText:SetText(auction.itemLink or "Unknown")
            
            -- Winner
            local winnerText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            winnerText:SetPoint("LEFT", itemText, "RIGHT", 10, 0)
            winnerText:SetWidth(120)
            winnerText:SetJustifyH("LEFT")
            winnerText:SetText(auction.winner or "No bids")
            
            -- Amount
            local amountText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            amountText:SetPoint("RIGHT", bar, "RIGHT", -8, 0)
            amountText:SetWidth(100)
            amountText:SetJustifyH("RIGHT")
            if auction.winningBid and auction.winningBid > 0 then
                amountText:SetText("|cffffd700" .. TL:FormatGold(auction.winningBid * 10000) .. "|r")
            else
                amountText:SetText("|cff808080No bids|r")
            end
            
            yOffset = yOffset + 30
        end
        
        scrollChild:SetHeight(math.max(yOffset, 1))
    else
        -- No active session
        local noSessionText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noSessionText:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -90)
        noSessionText:SetJustifyH("LEFT")
        noSessionText:SetText("No active GDKP session. Create one to get started.")
        noSessionText:Show()
        table.insert(content.children, noSessionText)
    end
end

-- History tab
function TL.MainWindow:ShowHistory()
    DEFAULT_CHAT_FRAME:AddMessage("[TL DEBUG] ShowHistory called")
    local content = TL.MainWindow.frame.content
    DEFAULT_CHAT_FRAME:AddMessage("[TL DEBUG] Content frame: " .. tostring(content))
    
    -- Create title frame first, then add fontstring to it
    local titleFrame = CreateFrame("Frame", nil, content)
    titleFrame:SetWidth(600)
    titleFrame:SetHeight(30)
    titleFrame:SetPoint("TOP", content, "TOP", 0, -20)
    titleFrame:Show()
    DEFAULT_CHAT_FRAME:AddMessage("[TL DEBUG] Title frame created")
    
    local title = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", titleFrame, "CENTER", 0, 0)
    title:SetText("Award History")
    title:Show()
    table.insert(content.children, titleFrame)
    DEFAULT_CHAT_FRAME:AddMessage("[TL DEBUG] Title added")
    
    -- Stats
    DEFAULT_CHAT_FRAME:AddMessage("[TL DEBUG] Getting stats...")
    local stats = TL.AwardedLoot:GetStats()
    DEFAULT_CHAT_FRAME:AddMessage("[TL DEBUG] Stats retrieved")
    
    local statsFrame = CreateFrame("Frame", nil, content)
    statsFrame:SetWidth(600)
    statsFrame:SetHeight(30)
    statsFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -50)
    statsFrame:Show()
    
    local statsText = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsText:SetPoint("LEFT", statsFrame, "LEFT", 0, 0)
    statsText:SetJustifyH("LEFT")
    statsText:SetText(
        "Total: " .. stats.totalAwards .. "  |  " ..
        "|cff00ff00Delivered: " .. stats.delivered .. "|r  |  " ..
        "|cffff8000Pending: " .. stats.pending .. "|r"
    )
    statsText:Show()
    table.insert(content.children, statsFrame)
    
    -- Export button
    local exportBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    exportBtn:SetWidth(120)
    exportBtn:SetHeight(25)
    exportBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", -20, -45)
    exportBtn:SetText("Export CSV")
    exportBtn:SetScript("OnClick", function()
        local csv = TL.AwardedLoot:Export()
        TL:Print("CSV exported to chat (copy from chat log)")
        TL:Print(csv)
    end)
    exportBtn:Show()
    table.insert(content.children, exportBtn)
    
    -- ScrollFrame for history
    local scrollFrame = CreateFrame("ScrollFrame", nil, content)
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -85)
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -30, 10)
    scrollFrame:Show()
    table.insert(content.children, scrollFrame)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(620)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Get recent history (last 50)
    local history = TL.AwardedLoot:GetHistory(50)
    local yOffset = 0
    
    for i, award in ipairs(history) do
        local bar = CreateFrame("Frame", nil, scrollChild)
        bar:SetWidth(600)
        bar:SetHeight(30)
        bar:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        
        -- Background
        bar:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        bar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        bar:Show()
        
        -- Item name
        local itemText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        itemText:SetPoint("LEFT", bar, "LEFT", 8, 0)
        itemText:SetWidth(200)
        itemText:SetJustifyH("LEFT")
        itemText:SetText(award.itemLink or "Unknown Item")
        
        -- Player name
        local playerText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        playerText:SetPoint("LEFT", itemText, "RIGHT", 10, 0)
        playerText:SetWidth(100)
        playerText:SetJustifyH("LEFT")
        playerText:SetText(award.player)
        
        -- Date
        local dateText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dateText:SetPoint("LEFT", playerText, "RIGHT", 10, 0)
        dateText:SetWidth(120)
        dateText:SetJustifyH("LEFT")
        dateText:SetText(TL:FormatDate(award.timestamp))
        
        -- Delivered status
        local statusText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        statusText:SetPoint("LEFT", dateText, "RIGHT", 10, 0)
        statusText:SetWidth(80)
        statusText:SetJustifyH("LEFT")
        if award.delivered then
            statusText:SetText("|cff00ff00Delivered|r")
        else
            statusText:SetText("|cffff8000Pending|r")
        end
        
        yOffset = yOffset + 35
    end
    
    scrollChild:SetHeight(math.max(yOffset, 1))
end

-- Show main window
function TL:ShowMainWindow()
    if TL.MainWindow.frame then
        TL.MainWindow.frame:Show()
    end
end

-- Atlas Browser tab
function TL.MainWindow:ShowAtlasBrowser()
    local content = TL.MainWindow.frame.content
    
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -20)
    title:SetText("Atlas-TW Instance Browser")
    title:Show()
    table.insert(content.children, title)
    
    -- Check if Atlas integration is available
    if not _G.AtlasTW then
        local errorText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        errorText:SetPoint("CENTER", content, "CENTER", 0, 0)
        errorText:SetText("|cffff0000Atlas-TW addon not found!|r\n\nPlease install Atlas-TW to use this feature.")
        errorText:Show()
        table.insert(content.children, errorText)
        return
    end

    if not TL.AtlasIntegration or not TL.AtlasIntegration:IsAvailable() then
        local loadingText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        loadingText:SetPoint("CENTER", content, "CENTER", 0, 0)
        loadingText:SetText("|cffFFFF00Initializing Atlas-TW data...|r\n\nPlease wait a moment and click the tab again.")
        loadingText:Show()
        table.insert(content.children, loadingText)
        
        -- Try to force init if not started
        if TL.AtlasIntegration and TL.AtlasIntegration.Initialize and not TL.AtlasIntegration.enabled then
             TL.AtlasIntegration:Initialize()
        end
        return
    end
    
    -- Instructions
    local instructions = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructions:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -50)
    instructions:SetJustifyH("LEFT")
    instructions:SetWidth(640)
    instructions:SetText("Select an instance to view its loot table and generate soft reserve lists.")
    instructions:Show()
    table.insert(content.children, instructions)
    
    -- Selected instance display
    local selectedInstance = nil
    local selectedQuality = TL.Settings:Get("softRes.defaultQuality") or 4
    
    local selectedInstanceText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectedInstanceText:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -80)
    selectedInstanceText:SetJustifyH("LEFT")
    selectedInstanceText:SetText("Selected: |cff808080None|r")
    selectedInstanceText:Show()
    table.insert(content.children, selectedInstanceText)
    
    -- Item count display
    local itemCountText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    itemCountText:SetPoint("TOPLEFT", selectedInstanceText, "BOTTOMLEFT", 0, -5)
    itemCountText:SetJustifyH("LEFT")
    itemCountText:SetText("")
    itemCountText:Show()
    table.insert(content.children, itemCountText)
    
    -- Function to update item count
    local function UpdateItemCount()
        if selectedInstance then
            local loot = TL.AtlasIntegration:GetInstanceLootByQuality(selectedInstance, selectedQuality)
            local count = table.getn(loot)
            if count > 0 then
                itemCountText:SetText("|cffaaaaaa" .. count .. " items will be generated|r")
            else
                itemCountText:SetText("|cffff8000No items found with selected quality|r")
            end
        else
            itemCountText:SetText("")
        end
    end
    
    -- Generate button
    local generateBtn = CreateFrame("Button", nil, content, "GameMenuButtonTemplate")
    generateBtn:SetWidth(150)
    generateBtn:SetHeight(25)
    generateBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -115)
    generateBtn:SetText("Generate SR List")
    generateBtn:Disable()
    generateBtn:SetScript("OnClick", function()
        if selectedInstance then
            local csv = TL.AtlasIntegration:GenerateSoftResCSV(selectedInstance, selectedQuality)
            TL.MainWindow:ShowImportDialog("softres")
            if TL.MainWindow.importDialog and TL.MainWindow.importDialog.editBox then
                TL.MainWindow.importDialog.editBox:SetText(csv)
            end
        end
    end)
    generateBtn:Show()
    table.insert(content.children, generateBtn)
    
    -- Quality selector label
    local qualityLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qualityLabel:SetPoint("LEFT", generateBtn, "RIGHT", 20, 0)
    qualityLabel:SetText("Min Quality:")
    qualityLabel:Show()
    table.insert(content.children, qualityLabel)
    
    -- Quality buttons
    local qualityOptions = {
        {name = "Uncommon", value = 2, color = "|cff1eff00"},
        {name = "Rare", value = 3, color = "|cff0070dd"},
        {name = "Epic", value = 4, color = "|cffa335ee"},
        {name = "Legendary", value = 5, color = "|cffff8000"},
    }
    
    local qualityButtons = {}
    for i, option in ipairs(qualityOptions) do
        -- Capture values for closures
        local currentValue = option.value
        local currentColor = option.color
        local currentName = option.name
        
        local btn = CreateFrame("Button", nil, content)
        btn:SetWidth(80)
        btn:SetHeight(20)
        btn:SetPoint("LEFT", qualityLabel, "RIGHT", 5 + (i-1) * 85, 0)
        
        -- Background
        btn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        
        -- Text
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.text:SetText(currentColor .. currentName .. "|r")
        
        -- Click handler
        btn:SetScript("OnClick", function()
            selectedQuality = currentValue
            TL.Settings:Set("softRes.defaultQuality", currentValue)
            -- Update buttons
            for j, qBtn in ipairs(qualityButtons) do
                if j == i then
                    qBtn:SetBackdropColor(0.3, 0.3, 0.3, 1)
                    qBtn:SetBackdropBorderColor(1, 1, 1, 1)
                else
                    qBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
                    qBtn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)
                end
            end
            UpdateItemCount()
        end)
        
        -- Hover
        btn:SetScript("OnEnter", function()
            if selectedQuality ~= currentValue then
                btn:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
            end
        end)
        btn:SetScript("OnLeave", function()
            if selectedQuality == currentValue then
                btn:SetBackdropColor(0.3, 0.3, 0.3, 1)
            else
                btn:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
            end
        end)
        
        -- Initial State
        if option.value == selectedQuality then
            btn:SetBackdropColor(0.3, 0.3, 0.3, 1)
            btn:SetBackdropBorderColor(1, 1, 1, 1)
        else
            btn:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
            btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)
        end
        
        btn:Show()
        table.insert(content.children, btn)
        table.insert(qualityButtons, btn)
    end
    
    -- Get instances from Atlas
    local instances = TL.AtlasIntegration:GetInstances()
    local numInstances = table.getn(instances)
    
    -- ScrollFrame for instance list
    -- ScrollFrame REPLACED by static container for Faux Scroll
    local buttonContainer = CreateFrame("Frame", nil, content)
    buttonContainer:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -150)
    buttonContainer:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -25, 10)
    buttonContainer:EnableMouseWheel(true)
    table.insert(content.children, buttonContainer)
    
    local NUM_VISIBLE = 9
    
    local scrollBar = CreateFrame("Slider", nil, content, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPRIGHT", content, "TOPRIGHT", -5, -166)
    scrollBar:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -5, 26)
    scrollBar:SetMinMaxValues(1, math.max(1, numInstances - NUM_VISIBLE + 1))
    scrollBar:SetValueStep(1)
    scrollBar:SetWidth(16)
    table.insert(content.children, scrollBar)
    
    -- Forward declare
    local UpdateList
    
    scrollBar:SetScript("OnValueChanged", function()
        if UpdateList then UpdateList() end
    end)
    
    buttonContainer:SetScript("OnMouseWheel", function()
        local current = scrollBar:GetValue()
        local delta = arg1
        local new = current - delta
        local min, max = scrollBar:GetMinMaxValues()
        if new < min then new = min end
        if new > max then new = max end
        scrollBar:SetValue(new)
    end)
    
    local BUTTON_HEIGHT = 32
    local NUM_VISIBLE = 9
    
    local buttons = {}
    for i = 1, NUM_VISIBLE do
         local btn = CreateFrame("Button", nil, buttonContainer)
         btn:SetWidth(650)
         btn:SetHeight(BUTTON_HEIGHT)
         btn:SetPoint("TOPLEFT", 0, -(i-1)*BUTTON_HEIGHT)
         
         -- Hover/Selection Texture
         local hl = btn:CreateTexture(nil, "BACKGROUND")
         hl:SetAllPoints()
         hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
         hl:SetBlendMode("ADD")
         hl:SetAlpha(0)
         btn.hl = hl
         
         -- Alternating row color
         local bg = btn:CreateTexture(nil, "BACKGROUND")
         bg:SetAllPoints()
         if math.mod(i, 2) == 0 then
             bg:SetTexture(0.1, 0.1, 0.1, 0.3)
         else
             bg:SetTexture(0.15, 0.15, 0.15, 0.3)
         end
         
         -- Info
         local name = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
         name:SetPoint("LEFT", 10, 0)
         btn.name = name
         
         local info = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
         info:SetPoint("RIGHT", -10, 0)
         btn.info = info
         
         btn:SetScript("OnClick", function()
             selectedInstance = this.key
             selectedInstanceText:SetText("Selected: |cff00ff00" .. this.name:GetText() .. "|r")
             generateBtn:Enable()
             UpdateItemCount()
             -- Refresh visuals
             for _, b in ipairs(buttons) do
                 if b.key == selectedInstance then
                     b.hl:SetAlpha(1)
                 else
                     b.hl:SetAlpha(0)
                 end
             end
         end)
         
         btn:SetScript("OnEnter", function()
             if this.key ~= selectedInstance then
                 this.hl:SetAlpha(0.5)
             end
         end)
         btn:SetScript("OnLeave", function()
             if this.key ~= selectedInstance then
                 this.hl:SetAlpha(0)
             end
         end)
         
         buttons[i] = btn
    end
    
    -- Update Loop
    -- Update Logic
    UpdateList = function()
        local offset = scrollBar:GetValue() - 1
        for i = 1, NUM_VISIBLE do
            local idx = offset + i
            local btn = buttons[i]
            if idx <= numInstances then
                local data = instances[idx]
                if data then
                    btn.key = data.key
                    btn.name:SetText(data.name)
                    btn.info:SetText("Lvl " .. (data.level or "??") .. " (" .. (data.maxPlayers or "5") .. "p)")
                    
                    if btn.key == selectedInstance then
                        btn.hl:SetAlpha(1)
                    else
                        btn.hl:SetAlpha(0)
                    end
                    btn:Show()
                else
                    btn:Hide()
                end
            else
                btn:Hide()
            end
        end
    end
    
    -- Initial update
    UpdateList()
end

-- Show import dialog
function TL.MainWindow:ShowImportDialog(importType)
    -- Create dialog frame if it doesn't exist
    if not TL.MainWindow.importDialog then
        local dialog = CreateFrame("Frame", "TurtleLootImportDialog", UIParent)
        dialog:SetWidth(500)
        dialog:SetHeight(400)
        dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        dialog:SetFrameStrata("FULLSCREEN_DIALOG")
        dialog:SetMovable(true)
        dialog:EnableMouse(true)
        dialog:SetClampedToScreen(true)
        
        -- Background
        dialog:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        
        -- Title
        local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", dialog, "TOP", 0, -15)
        title:SetText("Import CSV Data")
        dialog.title = title
        
        -- Close button
        local closeBtn = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -5, -5)
        closeBtn:SetScript("OnClick", function()
            dialog:Hide()
        end)
        
        -- Make draggable
        dialog:RegisterForDrag("LeftButton")
        dialog:SetScript("OnDragStart", function()
            this:StartMoving()
        end)
        dialog:SetScript("OnDragStop", function()
            this:StopMovingOrSizing()
        end)
        
        -- Instructions
        local instructions = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        instructions:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, -50)
        instructions:SetJustifyH("LEFT")
        instructions:SetWidth(460)
        instructions:SetText("Paste your CSV data below.\nFormat: itemID,playerName1,playerName2\nExample: 19019,PlayerA,PlayerB")
        dialog.instructions = instructions
        
        -- ScrollFrame for EditBox (without template to avoid nil concatenation error)
        local scrollFrame = CreateFrame("ScrollFrame", "TurtleLootImportScrollFrame", dialog)
        scrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, -100)
        scrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -40, 50)
        
        -- Background for scroll area
        scrollFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        scrollFrame:SetBackdropColor(0, 0, 0, 0.8)
        
        -- EditBox
        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetWidth(420)
        editBox:SetHeight(240)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject(GameFontNormal)
        editBox:SetScript("OnEscapePressed", function()
            this:ClearFocus()
        end)
        scrollFrame:SetScrollChild(editBox)
        dialog.editBox = editBox
        
        -- Import button
        local importBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        importBtn:SetWidth(100)
        importBtn:SetHeight(25)
        importBtn:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 20, 15)
        importBtn:SetText("Import")
        importBtn:SetScript("OnClick", function()
            local text = dialog.editBox:GetText()
            if dialog.importType == "softres" then
                local success = TL.SoftRes:Import(text)
                if success then
                    dialog:Hide()
                    TL.MainWindow:ShowTab(2) -- Refresh Soft Res tab
                end
            elseif dialog.importType == "plusones" then
                local success = TL.PlusOnes:Import(text)
                if success then
                    dialog:Hide()
                    TL.MainWindow:ShowTab(3) -- Refresh Plus Ones tab
                end
            end
        end)
        dialog.importBtn = importBtn
        
        -- Cancel button
        local cancelBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        cancelBtn:SetWidth(100)
        cancelBtn:SetHeight(25)
        cancelBtn:SetPoint("LEFT", importBtn, "RIGHT", 5, 0)
        cancelBtn:SetText("Cancel")
        cancelBtn:SetScript("OnClick", function()
            dialog:Hide()
        end)
        
        TL.MainWindow.importDialog = dialog
    end
    
    -- Set import type and show
    local dialog = TL.MainWindow.importDialog
    dialog.importType = importType
    dialog.editBox:SetText("")
    dialog.editBox:SetFocus()
    dialog:Show()
end
