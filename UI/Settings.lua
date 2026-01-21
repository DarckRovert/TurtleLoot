-- TurtleLoot Settings UI
-- Settings interface

local TL = _G.TurtleLoot

TL.SettingsUI = {
    frame = nil,
    categories = {},
    currentCategory = 1,
}

-- Initialize function for bootstrap
function TL.SettingsUI:Initialize()
    TL:InitializeSettingsUI()
end

-- Initialize settings UI
function TL:InitializeSettingsUI()
    -- Create frame
    local frame = CreateFrame("Frame", "TurtleLootSettingsFrame", UIParent)
    frame:SetWidth(650)
    frame:SetHeight(500)
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
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("TurtleLoot Settings")
    
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
    
    -- Category List Background
    local catBg = CreateFrame("Frame", nil, frame)
    catBg:SetPoint("TOPLEFT", 20, -50)
    catBg:SetWidth(150)
    catBg:SetHeight(400)
    catBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    catBg:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    frame.categoryFrame = catBg
    
    -- Content area (right side)
    local contentFrame = CreateFrame("Frame", nil, frame)
    contentFrame:SetPoint("TOPLEFT", catBg, "TOPRIGHT", 10, 0)
    contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 60)
    contentFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    contentFrame:SetBackdropColor(0, 0, 0, 0.5)
    contentFrame.children = {}
    frame.contentFrame = contentFrame
    
    -- Create categories
    TL.SettingsUI:CreateCategories(frame)
    
    -- Save button
    local saveBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    saveBtn:SetWidth(100)
    saveBtn:SetHeight(25)
    saveBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20)
    saveBtn:SetText("Save")
    saveBtn:SetScript("OnClick", function()
        TL:Print("Settings saved")
        frame:Hide()
    end)
    
    -- Reset button
    local resetBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    resetBtn:SetWidth(100)
    resetBtn:SetHeight(25)
    resetBtn:SetPoint("RIGHT", saveBtn, "LEFT", -10, 0)
    resetBtn:SetText("Reset")
    resetBtn:SetScript("OnClick", function()
        TL.Settings:Reset()
        TL:Print("Settings reset to defaults")
    end)
    
    TL.SettingsUI.frame = frame
end

-- Create categories
function TL.SettingsUI:CreateCategories(parent)
    local categories = {
        { name = "General", func = function() TL.SettingsUI:ShowGeneral() end },
        { name = "Master Loot", func = function() TL.SettingsUI:ShowMasterLoot() end },
        { name = "Soft Reserves", func = function() TL.SettingsUI:ShowSoftRes() end },
        { name = "Plus Ones", func = function() TL.SettingsUI:ShowPlusOnes() end },
        { name = "GDKP", func = function() TL.SettingsUI:ShowGDKP() end },
    }
    
    for i, catData in ipairs(categories) do
        -- Capture loop variables in local scope
        local categoryIndex = i
        local categoryFunc = catData.func
        local categoryName = catData.name
        
        local btn = CreateFrame("Button", nil, parent.categoryFrame)
        btn:SetWidth(130)
        btn:SetHeight(24)
        btn:SetPoint("TOP", 0, -10 - (categoryIndex-1) * 28)
        
        -- Create font string manually (1.12 compatible)
        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btnText:SetText(categoryName)
        btn.text = btnText
        
        -- Active indicator texture
        local activeBg = btn:CreateTexture(nil, "BACKGROUND")
        activeBg:SetAllPoints()
        activeBg:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        activeBg:SetBlendMode("ADD")
        activeBg:SetAlpha(0)
        btn.activeBg = activeBg
        
        -- Click handler
        btn:SetScript("OnClick", function()
            TL.SettingsUI:ShowCategory(categoryIndex)
        end)
        
        btn.index = categoryIndex
        btn.func = categoryFunc
        self.categories[categoryIndex] = btn
    end
    
    -- Show first category by default
    TL.SettingsUI:ShowCategory(1)
end

-- Show specific category
function TL.SettingsUI:ShowCategory(index)
    if not self.frame or not self.frame.contentFrame then
        return
    end
    
    self.currentCategory = index
    
    -- Update button appearance
    if self.categories then
        for i, btn in ipairs(self.categories) do
            if i == index then
                if btn.text then
                    btn.text:SetTextColor(1, 1, 0)  -- Yellow for selected
                end
                if btn.activeBg then btn.activeBg:SetAlpha(1) end
            else
                if btn.text then
                    btn.text:SetTextColor(1, 0.82, 0)  -- GameFontNormal Color
                end
                if btn.activeBg then btn.activeBg:SetAlpha(0) end
            end
        end
    end
    
    -- Clear content - destroy all children manually
    if self.frame.contentFrame.children then
        for _, child in ipairs(self.frame.contentFrame.children) do
            child:Hide()
            child:SetParent(nil)
        end
    end
    self.frame.contentFrame.children = {}
    
    -- Show category content
    if self.categories and self.categories[index] and self.categories[index].func then
        self.categories[index].func()
    end
end

-- General settings
function TL.SettingsUI:ShowGeneral()
    local content = self.frame.contentFrame
    
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("TOP", content, "TOP", 0, -20)
    text:SetText("General Settings")
    text:Show()
    table.insert(content.children, text)
    
    local info = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -60)
    info:SetJustifyH("LEFT")
    info:SetWidth(350)
    
    local debugMode = "OFF"
    local welcomeMsg = "ON"
    if TL.Settings and TL.Settings.Get then
        debugMode = TL.Settings:Get("general.debugMode") and "ON" or "OFF"
        welcomeMsg = TL.Settings:Get("general.showWelcomeMessage") and "ON" or "OFF"
    end
    
    info:SetText(
        "Debug Mode: " .. debugMode .. "\n" ..
        "Welcome Message: " .. welcomeMsg
    )
    info:Show()
    table.insert(content.children, info)
end

-- Master loot settings
function TL.SettingsUI:ShowMasterLoot()
    local content = self.frame.contentFrame
    
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("TOP", content, "TOP", 0, -20)
    text:SetText("Master Loot Settings")
    text:Show()
    table.insert(content.children, text)
    
    local info = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetPoint("TOPLEFT", content, "TOPLEFT", 20, -60)
    info:SetJustifyH("LEFT")
    info:SetWidth(350)
    info:SetText(
        "Auto-open Dialog: " .. (TL.Settings:Get("masterLoot.autoOpenDialog") and "ON" or "OFF") .. "\n" ..
        "Default Roll Time: " .. TL.Settings:Get("masterLoot.defaultRollTime", 30) .. " seconds"
    )
    info:Show()
    table.insert(content.children, info)
end

-- Soft res settings
function TL.SettingsUI:ShowSoftRes()
    local content = self.frame.contentFrame
    
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("TOP", content, "TOP", 0, -20)
    text:SetText("Soft Reserve Settings")
    text:Show()
    table.insert(content.children, text)
    
    local yOffset = -60
    
    -- Max Reserves Per Player
    local maxReservesLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    maxReservesLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
    maxReservesLabel:SetText("Max Reserves Per Player:")
    maxReservesLabel:Show()
    table.insert(content.children, maxReservesLabel)
    
    -- Current value display
    local currentMax = TL.Settings:Get("softRes.maxReservesPerPlayer") or 2
    local maxReservesValue = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    maxReservesValue:SetPoint("LEFT", maxReservesLabel, "RIGHT", 10, 0)
    maxReservesValue:SetText("|cff00ff00" .. currentMax .. "|r")
    maxReservesValue:Show()
    table.insert(content.children, maxReservesValue)
    
    -- Decrease button
    local decreaseBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    decreaseBtn:SetWidth(30)
    decreaseBtn:SetHeight(25)
    decreaseBtn:SetPoint("LEFT", maxReservesValue, "RIGHT", 10, 0)
    decreaseBtn:SetText("-")
    decreaseBtn:SetScript("OnClick", function()
        local current = TL.Settings:Get("softRes.maxReservesPerPlayer") or 2
        if current > 1 then
            TL.Settings:Set("softRes.maxReservesPerPlayer", current - 1)
            maxReservesValue:SetText("|cff00ff00" .. (current - 1) .. "|r")
            TL:Print("Max reserves set to " .. (current - 1))
        end
    end)
    decreaseBtn:Show()
    table.insert(content.children, decreaseBtn)
    
    -- Increase button
    local increaseBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    increaseBtn:SetWidth(30)
    increaseBtn:SetHeight(25)
    increaseBtn:SetPoint("LEFT", decreaseBtn, "RIGHT", 5, 0)
    increaseBtn:SetText("+")
    increaseBtn:SetScript("OnClick", function()
        local current = TL.Settings:Get("softRes.maxReservesPerPlayer") or 2
        if current < 10 then
            TL.Settings:Set("softRes.maxReservesPerPlayer", current + 1)
            maxReservesValue:SetText("|cff00ff00" .. (current + 1) .. "|r")
            TL:Print("Max reserves set to " .. (current + 1))
        end
    end)
    increaseBtn:Show()
    table.insert(content.children, increaseBtn)
    
    -- Description
    local maxReservesDesc = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    maxReservesDesc:SetPoint("TOPLEFT", maxReservesLabel, "BOTTOMLEFT", 0, -5)
    maxReservesDesc:SetJustifyH("LEFT")
    maxReservesDesc:SetWidth(350)
    maxReservesDesc:SetText("|cffaaaaaa Maximum number of items each player can reserve. Recommended: 1-3|r")
    maxReservesDesc:Show()
    table.insert(content.children, maxReservesDesc)
    
    yOffset = yOffset - 60
    
    -- Show Tooltips
    local tooltipsLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tooltipsLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset)
    tooltipsLabel:SetText("Show Reserves in Tooltips:")
    tooltipsLabel:Show()
    table.insert(content.children, tooltipsLabel)
    
    local tooltipsStatus = TL.Settings:Get("softRes.showTooltips") and "|cff00ff00ON|r" or "|cffff0000OFF|r"
    local tooltipsValue = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    tooltipsValue:SetPoint("LEFT", tooltipsLabel, "RIGHT", 10, 0)
    tooltipsValue:SetText(tooltipsStatus)
    tooltipsValue:Show()
    table.insert(content.children, tooltipsValue)
    
    -- Toggle button
    local toggleBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    toggleBtn:SetWidth(80)
    toggleBtn:SetHeight(25)
    toggleBtn:SetPoint("LEFT", tooltipsValue, "RIGHT", 10, 0)
    toggleBtn:SetText("Toggle")
    toggleBtn:SetScript("OnClick", function()
        local current = TL.Settings:Get("softRes.showTooltips")
        TL.Settings:Set("softRes.showTooltips", not current)
        local newStatus = (not current) and "|cff00ff00ON|r" or "|cffff0000OFF|r"
        tooltipsValue:SetText(newStatus)
        TL:Print("Tooltip display " .. ((not current) and "enabled" or "disabled"))
    end)
    toggleBtn:Show()
    table.insert(content.children, toggleBtn)
end

-- Plus ones settings
function TL.SettingsUI:ShowPlusOnes()
    local content = self.frame.contentFrame
    
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("TOP", content, "TOP", 0, -20)
    text:SetText("Plus Ones Settings")
    text:Show()
    table.insert(content.children, text)

    local yOffset = -60

    local function CreateCheck(label, settingKey, y)
        TL.SettingsUI.checkCounter = (TL.SettingsUI.checkCounter or 0) + 1
        local frameName = "TL_Settings_Check_" .. TL.SettingsUI.checkCounter
        local check = CreateFrame("CheckButton", frameName, content, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", content, "TOPLEFT", 40, y)
        
        -- Native template text can be unreliable, create manual fontstring
        check.text = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        check.text:SetPoint("LEFT", check, "RIGHT", 5, 0)
        check.text:SetText(label)
        
        -- Expand HitRect to include the text label so clicking the text works
        local width = check.text:GetStringWidth() or 200
        check:SetHitRectInsets(0, -width - 20, 0, 0)
        
        check:SetChecked(TL.Settings:Get(settingKey))
        check:SetScript("OnClick", function()
            local isChecked = this:GetChecked() and true or false
            TL.Settings:Set(settingKey, isChecked)
            TL:Print("Set " .. settingKey .. " to " .. tostring(isChecked))
        end)
        check:Show()
        table.insert(content.children, check)
    end

    CreateCheck("Enable Whisper Commands (!p1)", "plusOnes.enableWhisperCommand", yOffset)
    yOffset = yOffset - 40
    CreateCheck("Show +1 in Tooltips", "plusOnes.showTooltips", yOffset)
    yOffset = yOffset - 40
    CreateCheck("Auto-share data with raid", "plusOnes.autoShareData", yOffset)
end

-- GDKP settings
function TL.SettingsUI:ShowGDKP()
    local content = self.frame.contentFrame
    
    local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    text:SetPoint("TOP", content, "TOP", 0, -20)
    text:SetText("GDKP Settings")
    text:Show()
    table.insert(content.children, text)

    local yOffset = -50
    
    -- Helper to create sliders
    local function CreateSlider(label, settingKey, minVal, maxVal, step, formatStr)
        local slider = CreateFrame("Slider", "TL_GDKP_Slider_"..settingKey, content, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", content, "TOPLEFT", 40, yOffset)
        slider:SetWidth(180)
        slider:SetHeight(16)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)

        
        local current = TL.Settings:Get(settingKey)
        slider:SetValue(current)
        
        getglobal(slider:GetName().."Text"):SetText(label)
        getglobal(slider:GetName().."Low"):SetText(minVal)
        getglobal(slider:GetName().."High"):SetText(maxVal)
        
        -- Value label
        local valLabel = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        valLabel:SetPoint("TOP", slider, "BOTTOM", 0, -2)
        valLabel:SetText(string.format(formatStr or "%d", current))
        
        slider:SetScript("OnValueChanged", function()
            local val = this:GetValue()
            TL.Settings:Set(settingKey, val)
            valLabel:SetText(string.format(formatStr or "%d", val))
        end)
        
        slider:Show()
        table.insert(content.children, slider)
        return slider
    end

    -- Sliders
    CreateSlider("Min Bid (Gold)", "gdkp.defaultMinBid", 10, 1000, 10)
    
    yOffset = yOffset - 50
    CreateSlider("Min Increment (Gold)", "gdkp.defaultIncrement", 5, 500, 5)
    
    yOffset = yOffset - 50
    CreateSlider("Auction Duration (Sec)", "gdkp.defaultAuctionTime", 10, 120, 5)
    
    yOffset = yOffset - 50
    CreateSlider("Anti-Snipe (Sec)", "gdkp.antiSnipeTime", 0, 60, 1)
    
    yOffset = yOffset - 50
    
    -- Announcements Checkboxes (Column 1)
    local function CreateCheck(label, settingKey, x, y)
        TL.SettingsUI.checkCounter = (TL.SettingsUI.checkCounter or 0) + 1
        local frameName = "TL_Settings_Check_" .. TL.SettingsUI.checkCounter
        local check = CreateFrame("CheckButton", frameName, content, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
        
        -- Native template text can be unreliable, create manual fontstring
        check.text = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        check.text:SetPoint("LEFT", check, "RIGHT", 5, 0)
        check.text:SetText(label)
        
        -- Expand HitRect to include the text label
        local width = check.text:GetStringWidth() or 200
        check:SetHitRectInsets(0, -width - 20, 0, 0)
        
        check:SetChecked(TL.Settings:Get(settingKey))
        check:SetScript("OnClick", function()
            local isChecked = this:GetChecked() and true or false
            TL.Settings:Set(settingKey, isChecked)
            TL:Print("Set " .. settingKey .. " to " .. tostring(isChecked))
        end)
        check:Show()
        table.insert(content.children, check)
    end
    
    CreateCheck("Announce Start", "gdkp.announceStart", 40, yOffset)
    CreateCheck("Announce Bids", "gdkp.announceNewBid", 200, yOffset)
    
    yOffset = yOffset - 30
    CreateCheck("Announce End", "gdkp.announceEnd", 40, yOffset)
    CreateCheck("Raid Warning", "gdkp.announceToRaid", 200, yOffset)
end



-- Show settings
function TL:ShowSettings()
    -- Initialize if not already done
    if not TL.SettingsUI.frame then
        TL:InitializeSettingsUI()
    end
    
    if TL.SettingsUI.frame then
        TL.SettingsUI.frame:Show()
        -- Show first category
        if TL.SettingsUI.ShowCategory then
            TL.SettingsUI:ShowCategory(1)
        end
    else
        TL:Warning("Could not initialize Settings window")
    end
end
