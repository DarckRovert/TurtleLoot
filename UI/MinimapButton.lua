-- TurtleLoot Minimap Button
-- Minimap button for quick access

local TL = _G.TurtleLoot

TL.MinimapButton = {}

-- Initialize function called by bootstrap
function TL.MinimapButton:Initialize()
    TL:InitializeMinimapButton()
end

-- Initialize minimap button
function TL:InitializeMinimapButton()
    -- Always show button (ignore setting for now)
    -- if not self.Settings:Get("minimapButton.enabled") then
    --     return
    -- end
    
    -- Create button
    local button = CreateFrame("Button", "TurtleLootMinimapButton", Minimap)
    button:SetWidth(31)
    button:SetHeight(31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    -- Set icon
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
    button.icon = icon
    
    -- Set border
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetWidth(53)
    overlay:SetHeight(53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    
    -- Position (hardcoded for now)
    local angle = math.rad(225)
    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    
    -- Click handlers
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function()
        TL.MinimapButton:OnClick(arg1)
    end)
    
    -- Tooltip
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("TurtleLoot")
        GameTooltip:AddLine("Left-click: Open menu", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Settings", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Dragging
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function()
        this:LockHighlight()
        TL.MinimapButton.dragging = true
    end)
    
    button:SetScript("OnDragStop", function()
        this:UnlockHighlight()
        TL.MinimapButton.dragging = false
    end)
    
    button:SetScript("OnUpdate", function()
        if TL.MinimapButton.dragging then
            TL.MinimapButton:UpdatePosition(this)
        end
    end)
    
    self.MinimapButton.button = button
    button:Show()
    
    TL:Success("Minimap button created!")
end

-- Set button position
function TL.MinimapButton:SetPosition(button, position)
    local angle = math.rad(position)
    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Update position while dragging
function TL.MinimapButton:UpdatePosition(button)
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale
    
    local angle = math.deg(math.atan2(py - my, px - mx))
    if angle < 0 then
        angle = angle + 360
    end
    
    self:SetPosition(button, angle)
    TL.Settings:Set("minimapButton.position", angle)
end

-- Handle clicks
function TL.MinimapButton:OnClick(button)
    if button == "LeftButton" then
        TL:ShowMainWindow()
    elseif button == "RightButton" then
        TL:ShowSettings()
    end
end

-- Show/hide button
function TL.MinimapButton:Show()
    if self.button then
        self.button:Show()
    end
end

function TL.MinimapButton:Hide()
    if self.button then
        self.button:Hide()
    end
end

-- ShowMainWindow is now defined in Init.lua
