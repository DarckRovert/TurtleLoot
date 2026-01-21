-- TurtleLoot Auction Monitor
-- Visual display for active auctions

local TL = _G.TurtleLoot

TL.AuctionMonitor = {
    frame = nil,
    endTime = 0,
    active = false
}

function TL.AuctionMonitor:Initialize()
    self:CreateFrame()
    self:RegisterEvents()
end

function TL.AuctionMonitor:CreateFrame()
    -- Main Frame
    local f = CreateFrame("Frame", "TurtleLootAuctionMonitor", UIParent)
    f:SetWidth(250)
    f:SetHeight(60)
    f:SetPoint("CENTER", 0, 150)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.8)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    f:Hide()
    
    self.frame = f
    
    -- Icon
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetWidth(40)
    f.icon:SetHeight(40)
    f.icon:SetPoint("LEFT", 10, 0)
    f.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    
    -- Item Name
    f.itemName = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.itemName:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 10, -2)
    f.itemName:SetText("Unknown Item")
    
    -- Bid Info
    f.bidInfo = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    f.bidInfo:SetPoint("TOPLEFT", f.itemName, "BOTTOMLEFT", 0, -4)
    f.bidInfo:SetText("100g (Pepe)")
    f.bidInfo:SetTextColor(1, 0.82, 0) -- Gold color
    
    -- Time Bar
    f.statusBar = CreateFrame("StatusBar", nil, f)
    f.statusBar:SetWidth(180)
    f.statusBar:SetHeight(10)
    f.statusBar:SetPoint("BOTTOMLEFT", f.icon, "BOTTOMRIGHT", 10, 0)
    f.statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    f.statusBar:SetMinMaxValues(0, 1)
    f.statusBar:SetValue(1)
    f.statusBar:SetStatusBarColor(0, 1, 0)
    
    -- Timer Text inside bar
    f.timerText = f.statusBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.timerText:SetPoint("CENTER", f.statusBar, "CENTER", 0, 0)
    f.timerText:SetText("30s")
    
    -- Update Script
    f:SetScript("OnUpdate", function()
        if not TL.AuctionMonitor.active then return end
        
        local remaining = TL.AuctionMonitor.endTime - GetTime()
        if remaining < 0 then remaining = 0 end
        
        -- Update Bar
        local total = TL.GDKP.activeAuction and TL.GDKP.activeAuction.duration or 30
        local pct = remaining / total
        f.statusBar:SetValue(pct)
        
        -- Color Gradient (Green -> Yellow -> Red)
        if pct > 0.5 then
            f.statusBar:SetStatusBarColor(0, 1, 0)
        elseif pct > 0.2 then
            f.statusBar:SetStatusBarColor(1, 1, 0)
        else
            f.statusBar:SetStatusBarColor(1, 0, 0)
        end
        
        f.timerText:SetText(string.format("%.1fs", remaining))
    end)
end

function TL.AuctionMonitor:RegisterEvents()
    TL:RegisterEvent("GDKP_AUCTION_START", function(data)
        self:ShowAuction(data)
    end)
    
    TL:RegisterEvent("GDKP_BID_UPDATE", function(data)
        self:UpdateBid(data)
    end)
    
    TL:RegisterEvent("GDKP_AUCTION_END", function()
        self:HideAuction()
    end)
end

function TL.AuctionMonitor:ShowAuction(auction)
    self.active = true
    self.endTime = auction.endTime
    
    local name, link, quality, _, _, _, _, _, _, texture = GetItemInfo(auction.itemID)
    
    self.frame.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    self.frame.itemName:SetText(link or name or "Item")
    self.frame.bidInfo:SetText(TL:FormatGold(auction.currentBid * 10000) .. " (" .. (auction.currentBidder or "No Bids") .. ")")
    
    self.frame:Show()
end

function TL.AuctionMonitor:UpdateBid(data)
    -- data contains {amount, bidder, endTime}
    self.frame.bidInfo:SetText(TL:FormatGold(data.amount * 10000) .. " (" .. data.bidder .. ")")
    if data.endTime then
        self.endTime = data.endTime -- Anti-snipe extension
    end
end

function TL.AuctionMonitor:HideAuction()
    self.active = false
    self.frame:Hide()
end
