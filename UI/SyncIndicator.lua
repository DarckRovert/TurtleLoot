-- TurtleLoot Sync Indicator
-- Visual indicator for sync status

local TL = _G.TurtleLoot

TL.SyncIndicator = {}

local indicator = nil

-- Initialize sync indicator
function TL.SyncIndicator:Initialize()
    self:CreateIndicator()
    
    -- Update every 2 seconds
    if not self.updateFrame then
        self.updateFrame = CreateFrame("Frame")
        self.updateFrame.elapsed = 0
        self.updateFrame:SetScript("OnUpdate", function()
            this.elapsed = this.elapsed + arg1
            if this.elapsed >= 2 then
                TL.SyncIndicator:Update()
                this.elapsed = 0
            end
        end)
    end
end

-- Create the indicator frame
function TL.SyncIndicator:CreateIndicator()
    if indicator then return end
    
    indicator = CreateFrame("Frame", "TurtleLootSyncIndicator", UIParent)
    indicator:SetWidth(120)
    indicator:SetHeight(20)
    indicator:SetPoint("TOP", UIParent, "TOP", 0, -5)
    indicator:SetFrameStrata("HIGH")
    indicator:Hide()
    
    -- Background
    local bg = indicator:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(indicator)
    bg:SetTexture(0, 0, 0, 0.7)
    indicator.bg = bg
    
    -- Text
    local text = indicator:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER")
    text:SetText("Syncing...")
    indicator.text = text
    
    -- Make draggable
    indicator:SetMovable(true)
    indicator:EnableMouse(true)
    indicator:RegisterForDrag("LeftButton")
    indicator:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    indicator:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)
    
    -- Tooltip
    indicator:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
        GameTooltip:SetText("TurtleLoot Sync Status")
        GameTooltip:AddLine(" ")
        
        if TL.Comm then
            for key, status in pairs(TL.Comm.syncStatus) do
                local statusText = status and "|cff00ff00Synced|r" or "|cffff0000Not Synced|r"
                local keyName = string.gsub(key, "(%l)(%w*)", function(a, b) return string.upper(a) .. b end)
                GameTooltip:AddDoubleLine(keyName, statusText)
            end
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff888888Click and drag to move|r", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    indicator:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- Update indicator
function TL.SyncIndicator:Update()
    if not indicator or not TL.Comm then return end
    
    -- Only show in raid/party
    if not TL:IsInRaid() and not TL:IsInParty() then
        indicator:Hide()
        return
    end
    
    local statusText = TL.Comm:GetSyncStatusText()
    indicator.text:SetText("TL: " .. statusText)
    
    local allSynced = TL.Comm:GetSyncStatus()
    
    -- Auto-hide after 10 seconds if fully synced
    if allSynced then
        if not indicator.hideTimer then
            indicator.hideTimer = 10
        else
            indicator.hideTimer = indicator.hideTimer - 2
            if indicator.hideTimer <= 0 then
                indicator:Hide()
                indicator.hideTimer = nil
            end
        end
    else
        indicator.hideTimer = nil
        indicator:Show()
    end
end

-- Show indicator
function TL.SyncIndicator:Show()
    if indicator then
        indicator:Show()
        indicator.hideTimer = nil
    end
end

-- Hide indicator
function TL.SyncIndicator:Hide()
    if indicator then
        indicator:Hide()
    end
end

-- Toggle indicator
function TL.SyncIndicator:Toggle()
    if indicator then
        if indicator:IsShown() then
            indicator:Hide()
        else
            indicator:Show()
        end
    end
end
