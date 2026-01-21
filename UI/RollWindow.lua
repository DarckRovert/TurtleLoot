-- TurtleLoot Roll Window
-- Roll tracking window

local TL = _G.TurtleLoot

TL.RollWindow = {
    frame = nil,
    rollBars = {},
}

-- Initialize roll window
function TL:InitializeRollWindow()
    -- Create frame
    local frame = CreateFrame("Frame", "TurtleLootRollFrame", UIParent)
    frame:SetWidth(400)
    frame:SetHeight(300)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    -- Background
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.9) -- Dark styling
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Roll Tracking")
    frame.title = title
    
    -- Item display
    local itemText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemText:SetPoint("TOP", frame, "TOP", 0, -40)
    itemText:SetText("No active roll")
    frame.itemText = itemText
    
    -- Timer
    local timerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timerText:SetPoint("TOP", frame, "TOP", 0, -60)
    timerText:SetText("")
    frame.timerText = timerText
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Make draggable
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)
    
    -- Scroll frame for rolls
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame)
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 50)
    frame.scrollFrame = scrollFrame
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(340)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    frame.scrollChild = scrollChild
    
    -- End roll button
    local endBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    endBtn:SetWidth(120)
    endBtn:SetHeight(25)
    endBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
    endBtn:SetText("End Roll")
    endBtn:SetScript("OnClick", function()
        TL.RollOff:End()
    end)
    frame.endBtn = endBtn
    
    -- Update timer
    frame:SetScript("OnUpdate", function()
        TL.RollWindow:OnUpdate()
    end)
    
    TL.RollWindow.frame = frame
    
    -- Listen for roll events
    TL:RegisterEvent("ROLL_STARTED", function(rollData)
        TL.RollWindow:OnRollStarted(rollData)
    end)
    
    TL:RegisterEvent("ROLL_ENDED", function(rollData, rolls, winner)
        TL.RollWindow:OnRollEnded(rollData, rolls, winner)
    end)
    
    TL:RegisterEvent("ROLL_RECORDED", function(rollData)
        TL.RollWindow:OnRollRecorded(rollData)
    end)
end

-- Handle roll started
function TL.RollWindow:OnRollStarted(rollData)
    if not self.frame then return end
    
    self.frame.itemText:SetText(rollData.itemLink)
    self.frame:Show()
    
    -- Clear previous rolls
    for _, bar in ipairs(self.rollBars) do
        bar:Hide()
    end
    self.rollBars = {}
    
    -- Reset scroll child height
    self.frame.scrollChild:SetHeight(1)
end

-- Handle roll ended
function TL.RollWindow:OnRollEnded(rollData, rolls, winner)
    if not self.frame then return end
    
    self.frame.timerText:SetText("Roll ended")
    
    -- Display winner
    if winner then
        TL:Success("Winner: " .. winner.player .. " (" .. winner.roll .. ")")
    end
end

-- Update timer
function TL.RollWindow:OnUpdate()
    if not TL.RollOff.active or not TL.RollOff.currentRoll then
        return
    end
    
    local timeLeft = TL.RollOff.currentRoll.endTime - GetTime()
    if timeLeft > 0 then
        self.frame.timerText:SetText(string.format("Time left: %d seconds", timeLeft))
    else
        self.frame.timerText:SetText("Ending...")
    end
end

-- Handle roll recorded
function TL.RollWindow:OnRollRecorded(rollData)
    if not self.frame or not self.frame:IsVisible() then return end
    
    -- Create roll bar
    local bar = self:CreateRollBar(rollData)
    table.insert(self.rollBars, bar)
    
    -- Update scroll child height
    local totalHeight = table.getn(self.rollBars) * 30 + 10
    self.frame.scrollChild:SetHeight(totalHeight)
end

-- Create a roll bar for a player
function TL.RollWindow:CreateRollBar(rollData)
    local bar = CreateFrame("Frame", nil, self.frame.scrollChild)
    bar:SetWidth(340)
    bar:SetHeight(25)
    
    -- Position
    local yOffset = -10 - (table.getn(self.rollBars) * 30)
    bar:SetPoint("TOPLEFT", self.frame.scrollChild, "TOPLEFT", 0, yOffset)
    
    -- Background
    bar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Color by bracket
    if rollData.bracket == "MS" then
        bar:SetBackdropColor(0.2, 0.3, 0.5, 0.8) -- Blue for MS
    else
        bar:SetBackdropColor(0.3, 0.5, 0.2, 0.8) -- Green for OS
    end
    
    -- Player name
    local nameText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", bar, "LEFT", 8, 0)
    nameText:SetText(rollData.player)
    bar.nameText = nameText
    
    -- Roll value
    local rollText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    rollText:SetPoint("RIGHT", bar, "RIGHT", -8, 0)
    rollText:SetText(rollData.roll)
    bar.rollText = rollText
    
    -- Bracket indicator
    local bracketText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bracketText:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bracketText:SetText(rollData.bracket)
    bar.bracketText = bracketText
    
    -- SR indicator
    if rollData.hasSoftRes then
        local srIcon = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        srIcon:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
        srIcon:SetText("|cffff8000[SR]|r")
        bar.srIcon = srIcon
    end
    
    -- Plus ones indicator
    if rollData.plusOnes and rollData.plusOnes > 0 then
        local p1Text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        p1Text:SetPoint("LEFT", nameText, "RIGHT", rollData.hasSoftRes and 40 or 5, 0)
        p1Text:SetText("|cff00ff00+" .. rollData.plusOnes .. "|r")
        bar.p1Text = p1Text
    end
    
    bar:Show()
    return bar
end

-- Show roll window
function TL:ShowRollWindow()
    if TL.RollWindow.frame then
        TL.RollWindow.frame:Show()
    end
end
