-- TurtleLoot Award Dialog
-- Dialog for awarding items

local TL = _G.TurtleLoot

TL.AwardDialog = {
    frame = nil,
    currentItem = nil,
    playerDropdown = nil,
    raidPlayers = {},
    classFilters = {
        WARRIOR = true,
        PALADIN = true,
        HUNTER = true,
        ROGUE = true,
        PRIEST = true,
        SHAMAN = true,
        MAGE = true,
        WARLOCK = true,
        DRUID = true,
    },
}

-- Initialize award dialog
function TL:InitializeAwardDialog()
    -- Create frame with backdrop template
    local frame = CreateFrame("Frame", "TurtleLootAwardFrame", UIParent)
    frame:SetWidth(500)
    frame:SetHeight(350)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
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
    title:SetText("Award Item")
    
    -- Item display
    local itemText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemText:SetPoint("TOP", frame, "TOP", 0, -50)
    itemText:SetText("Select an item")
    frame.itemText = itemText
    
    -- Class filters section
    local filterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -80)
    filterLabel:SetText("Class Filters:")
    
    -- Class filter checkboxes
    local classes = {
        {name = "Warrior", file = "WARRIOR", color = {r=0.78, g=0.61, b=0.43}},
        {name = "Paladin", file = "PALADIN", color = {r=0.96, g=0.55, b=0.73}},
        {name = "Hunter", file = "HUNTER", color = {r=0.67, g=0.83, b=0.45}},
        {name = "Rogue", file = "ROGUE", color = {r=1.00, g=0.96, b=0.41}},
        {name = "Priest", file = "PRIEST", color = {r=1.00, g=1.00, b=1.00}},
        {name = "Shaman", file = "SHAMAN", color = {r=0.00, g=0.44, b=0.87}},
        {name = "Mage", file = "MAGE", color = {r=0.41, g=0.80, b=0.94}},
        {name = "Warlock", file = "WARLOCK", color = {r=0.58, g=0.51, b=0.79}},
        {name = "Druid", file = "DRUID", color = {r=1.00, g=0.49, b=0.04}},
    }
    
    frame.classCheckboxes = {}
    
    for i = 1, table.getn(classes) do
        local class = classes[i]
        local checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        
        -- Position in 3 columns
        local col = math.mod(i - 1, 3)
        local row = math.floor((i - 1) / 3)
        checkbox:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", col * 150, -5 - (row * 25))
        checkbox:SetWidth(20)
        checkbox:SetHeight(20)
        checkbox:SetChecked(true)
        
        -- Label with class color
        local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText(class.name)
        label:SetTextColor(class.color.r, class.color.g, class.color.b)
        
        -- OnClick handler
        checkbox:SetScript("OnClick", function()
            TL.AwardDialog.classFilters[class.file] = this:GetChecked()
            TL.AwardDialog:RefreshDropdown()
        end)
        
        frame.classCheckboxes[class.file] = checkbox
    end
    
    -- Select All / Deselect All buttons
    local selectAllBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    selectAllBtn:SetWidth(80)
    selectAllBtn:SetHeight(20)
    selectAllBtn:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -85)
    selectAllBtn:SetText("All")
    selectAllBtn:SetScript("OnClick", function()
        for className, _ in pairs(TL.AwardDialog.classFilters) do
            TL.AwardDialog.classFilters[className] = true
            frame.classCheckboxes[className]:SetChecked(true)
        end
        TL.AwardDialog:RefreshDropdown()
    end)
    
    local deselectAllBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    deselectAllBtn:SetWidth(80)
    deselectAllBtn:SetHeight(20)
    deselectAllBtn:SetPoint("LEFT", selectAllBtn, "RIGHT", 5, 0)
    deselectAllBtn:SetText("None")
    deselectAllBtn:SetScript("OnClick", function()
        for className, _ in pairs(TL.AwardDialog.classFilters) do
            TL.AwardDialog.classFilters[className] = false
            frame.classCheckboxes[className]:SetChecked(false)
        end
        TL.AwardDialog:RefreshDropdown()
    end)
    
    -- Player name label
    local playerLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -195)
    playerLabel:SetText("Player:")
    
    -- Player dropdown
    local playerDropdown = CreateFrame("Frame", "TurtleLootAwardPlayerDropdown", frame, "UIDropDownMenuTemplate")
    playerDropdown:SetPoint("LEFT", playerLabel, "RIGHT", -10, -3)
    UIDropDownMenu_SetWidth(200, playerDropdown)
    
    -- Initialize dropdown
    UIDropDownMenu_Initialize(playerDropdown, function()
        local info = {}
        
        -- Add manual entry option
        info.text = "[Type manually...]"
        info.value = "__MANUAL__"
        info.func = function()
            UIDropDownMenu_SetSelectedValue(playerDropdown, "__MANUAL__")
            TL.AwardDialog:ShowManualInput()
        end
        UIDropDownMenu_AddButton(info)
        
        -- Add separator
        info = {}
        info.text = ""
        info.disabled = 1
        UIDropDownMenu_AddButton(info)
        
        -- Add raid/party members (with class filters applied)
        local players = TL.AwardDialog:GetRaidPlayers(true)
        for i = 1, table.getn(players) do
            local playerData = players[i]
            info = {}
            
            -- Build display text with SR and +1 info
            local displayText = playerData.name
            local extras = {}
            
            if playerData.srCount and playerData.srCount > 0 then
                table.insert(extras, "|cffff8000SR|r")
            end
            
            if playerData.plusOnes and playerData.plusOnes > 0 then
                table.insert(extras, "|cff00ff00+" .. playerData.plusOnes .. "|r")
            end
            
            if table.getn(extras) > 0 then
                displayText = displayText .. " (" .. table.concat(extras, ", ") .. ")"
            end
            
            info.text = displayText
            info.value = playerData.name
            info.func = function()
                UIDropDownMenu_SetSelectedValue(playerDropdown, playerData.name)
                TL.AwardDialog.selectedPlayer = playerData.name
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Set default text
    UIDropDownMenu_SetSelectedValue(playerDropdown, nil)
    UIDropDownMenu_SetText("Select player...", playerDropdown)
    
    frame.playerDropdown = playerDropdown
    TL.AwardDialog.playerDropdown = playerDropdown
    
    -- Manual input (hidden by default)
    local playerInput = CreateFrame("EditBox", nil, frame)
    playerInput:SetWidth(250)
    playerInput:SetHeight(25)
    playerInput:SetPoint("LEFT", playerLabel, "RIGHT", 10, 0)
    playerInput:SetAutoFocus(false)
    playerInput:SetFontObject("GameFontNormal")
    playerInput:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    playerInput:SetBackdropColor(0, 0, 0, 0.5)
    playerInput:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)
    playerInput:Hide()
    frame.playerInput = playerInput
    
    -- Note label
    local noteLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noteLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -235)
    noteLabel:SetText("Note:")
    
    -- Note input
    local noteInput = CreateFrame("EditBox", nil, frame)
    noteInput:SetWidth(250)
    noteInput:SetHeight(25)
    noteInput:SetPoint("LEFT", noteLabel, "RIGHT", 10, 0)
    noteInput:SetAutoFocus(false)
    noteInput:SetFontObject("GameFontNormal")
    noteInput:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    noteInput:SetBackdropColor(0, 0, 0, 0.5)
    noteInput:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)
    frame.noteInput = noteInput
    
    -- Award button
    local awardBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    awardBtn:SetWidth(100)
    awardBtn:SetHeight(25)
    awardBtn:SetPoint("BOTTOM", frame, "BOTTOM", -55, 15)
    awardBtn:SetText("Award")
    awardBtn:SetScript("OnClick", function()
        TL.AwardDialog:Award()
    end)
    
    -- Cancel button
    local cancelBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelBtn:SetWidth(100)
    cancelBtn:SetHeight(25)
    cancelBtn:SetPoint("BOTTOM", frame, "BOTTOM", 55, 15)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    
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
    
    TL.AwardDialog.frame = frame
end

-- Get raid/party players with class filtering
function TL.AwardDialog:GetRaidPlayers(applyFilters)
    local players = {}
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    if numRaid > 0 then
        -- In raid
        for i = 1, numRaid do
            local name, _, _, _, _, class = GetRaidRosterInfo(i)
            if name then
                -- Apply class filter if requested
                if not applyFilters or self.classFilters[class] then
                    -- Get SR and +1 data
                    local srCount = TL.AwardDialog:GetPlayerSRCount(name)
                    local plusOnes = TL.PlusOnes:Get(name)
                    
                    table.insert(players, {
                        name = name,
                        class = class,
                        srCount = srCount,
                        plusOnes = plusOnes
                    })
                end
            end
        end
    elseif numParty > 0 then
        -- In party
        for i = 1, numParty do
            local name = UnitName("party"..i)
            if name then
                local _, class = UnitClass("party"..i)
                if not applyFilters or self.classFilters[class] then
                    local srCount = TL.AwardDialog:GetPlayerSRCount(name)
                    local plusOnes = TL.PlusOnes:Get(name)
                    
                    table.insert(players, {
                        name = name,
                        class = class,
                        srCount = srCount,
                        plusOnes = plusOnes
                    })
                end
            end
        end
        -- Add player
        local playerName = UnitName("player")
        if playerName then
            local _, class = UnitClass("player")
            if not applyFilters or self.classFilters[class] then
                local srCount = TL.AwardDialog:GetPlayerSRCount(playerName)
                local plusOnes = TL.PlusOnes:Get(playerName)
                
                table.insert(players, {
                    name = playerName,
                    class = class,
                    srCount = srCount,
                    plusOnes = plusOnes
                })
            end
        end
    else
        -- Solo
        local playerName = UnitName("player")
        if playerName then
            local _, class = UnitClass("player")
            if not applyFilters or self.classFilters[class] then
                local srCount = TL.AwardDialog:GetPlayerSRCount(playerName)
                local plusOnes = TL.PlusOnes:Get(playerName)
                
                table.insert(players, {
                    name = playerName,
                    class = class,
                    srCount = srCount,
                    plusOnes = plusOnes
                })
            end
        end
    end
    
    -- Sort alphabetically by name
    table.sort(players, function(a, b)
        return a.name < b.name
    end)
    
    return players
end

-- Get player's SR count for current item
function TL.AwardDialog:GetPlayerSRCount(playerName)
    if not self.currentItem or not playerName then return 0 end
    
    -- Extract itemID from item link
    local itemID = TL.AwardDialog:ExtractItemID(self.currentItem)
    if not itemID then return 0 end
    
    -- Check if player has SR on this item
    if TL.SoftRes.playerReserves and TL.SoftRes.playerReserves[playerName] then
        local reserves = TL.SoftRes.playerReserves[playerName]
        for i = 1, table.getn(reserves) do
            if reserves[i] == itemID then
                return 1
            end
        end
    end
    
    return 0
end

-- Extract itemID from item link
function TL.AwardDialog:ExtractItemID(itemLink)
    if not itemLink then return nil end
    
    -- Item link format: |cffffffff|Hitem:12345:0:0:0|h[Item Name]|h|r
    local _, _, itemID = string.find(itemLink, "item:(%d+)")
    return tonumber(itemID)
end

-- Show manual input
function TL.AwardDialog:ShowManualInput()
    if not self.frame then return end
    self.frame.playerDropdown:Hide()
    self.frame.playerInput:Show()
    self.frame.playerInput:SetFocus()
    self.selectedPlayer = nil
end

-- Show dropdown
function TL.AwardDialog:ShowDropdown()
    if not self.frame then return end
    self.frame.playerInput:Hide()
    self.frame.playerDropdown:Show()
end

-- Refresh dropdown (when filters change)
function TL.AwardDialog:RefreshDropdown()
    if not self.frame or not self.playerDropdown then return end
    
    -- Reinitialize dropdown with new filters
    UIDropDownMenu_Initialize(self.playerDropdown, function()
        local info = {}
        
        -- Add manual entry option
        info.text = "[Type manually...]"
        info.value = "__MANUAL__"
        info.func = function()
            UIDropDownMenu_SetSelectedValue(TL.AwardDialog.playerDropdown, "__MANUAL__")
            TL.AwardDialog:ShowManualInput()
        end
        UIDropDownMenu_AddButton(info)
        
        -- Add separator
        info = {}
        info.text = ""
        info.disabled = 1
        UIDropDownMenu_AddButton(info)
        
        -- Add raid/party members (with class filters applied)
        local players = TL.AwardDialog:GetRaidPlayers(true)
        for i = 1, table.getn(players) do
            local playerData = players[i]
            info = {}
            
            -- Build display text with SR and +1 info
            local displayText = playerData.name
            local extras = {}
            
            if playerData.srCount and playerData.srCount > 0 then
                table.insert(extras, "|cffff8000SR|r")
            end
            
            if playerData.plusOnes and playerData.plusOnes > 0 then
                table.insert(extras, "|cff00ff00+" .. playerData.plusOnes .. "|r")
            end
            
            if table.getn(extras) > 0 then
                displayText = displayText .. " (" .. table.concat(extras, ", ") .. ")"
            end
            
            info.text = displayText
            info.value = playerData.name
            info.func = function()
                UIDropDownMenu_SetSelectedValue(TL.AwardDialog.playerDropdown, playerData.name)
                TL.AwardDialog.selectedPlayer = playerData.name
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Reset selection
    UIDropDownMenu_SetSelectedValue(self.playerDropdown, nil)
    UIDropDownMenu_SetText("Select player...", self.playerDropdown)
    self.selectedPlayer = nil
end

-- Show award dialog
function TL.AwardDialog:Show(itemLink)
    if not self.frame then return end
    
    self.currentItem = itemLink
    self.selectedPlayer = nil
    self.frame.itemText:SetText(itemLink or "No item")
    self.frame.playerInput:SetText("")
    self.frame.noteInput:SetText("")
    
    -- Reset dropdown
    UIDropDownMenu_SetSelectedValue(self.playerDropdown, nil)
    UIDropDownMenu_SetText("Select player...", self.playerDropdown)
    
    -- Show dropdown by default
    self:ShowDropdown()
    
    self.frame:Show()
end

-- Award the item
function TL.AwardDialog:Award()
    if not self.currentItem then
        TL:Error("No item selected")
        return
    end
    
    -- Get player name from dropdown or manual input
    local playerName
    if self.selectedPlayer then
        playerName = self.selectedPlayer
    else
        playerName = self.frame.playerInput:GetText()
    end
    
    local note = self.frame.noteInput:GetText()
    
    if not playerName or playerName == "" then
        TL:Error("Please select or enter a player name")
        return
    end
    
    -- Award the item
    TL.AwardedLoot:Award(self.currentItem, playerName, note)
    
    -- Close dialog
    self.frame:Hide()
end

-- Show award dialog (global function)
function TL:ShowAwardDialog(itemLink)
    if TL.AwardDialog.frame then
        TL.AwardDialog:Show(itemLink)
    end
end
