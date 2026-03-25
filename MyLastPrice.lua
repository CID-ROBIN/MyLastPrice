-- SavedVariables init
MyLastPriceDB = MyLastPriceDB or {}

-- Money formatting
local function MLP_FormatMoney(copper)
    if not copper or copper <= 0 then
        return "|cffffffff0|r |TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
    end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100

    local goldStr = tostring(gold):reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^ ", "")
    local out = ""
    if gold > 0 then
        out = out .. "|cffffffff" .. goldStr .. "|r |TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t "
    end
    if silver > 0 or gold > 0 then
        out = out .. "|cffffffff" .. silver .. "|r |TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t "
    end
    out = out .. "|cffffffff" .. cop .. "|r |TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
    return out
end

-- Add price to tooltip
local function MLP_AddPriceToTooltip(tooltip)
    if not tooltip or not tooltip.GetTooltipData then return end
    local tdata = tooltip:GetTooltipData()
    if not tdata then return end

    if tdata.battlePetSpeciesID and tdata.battlePetSpeciesID > 0 then return end

    local key
    if tdata.id then
        key = tdata.id
    elseif tdata.hyperlink then
        local itemID = GetItemInfoInstant(tdata.hyperlink)
        if itemID then key = itemID end
    end

    if not key then return end

    local price = MyLastPriceDB[key]
    if not price then return end

    -- Create background
    if not tooltip.MyLastPriceBG then
        tooltip.MyLastPriceBG = CreateFrame("Frame", nil, tooltip, "BackdropTemplate")
        tooltip.MyLastPriceBG:SetPoint("TOPLEFT", tooltip, "BOTTOMLEFT", 0, -2)
        tooltip.MyLastPriceBG:SetHeight(18)

        tooltip.MyLastPriceBG:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        tooltip.MyLastPriceBG:SetBackdropColor(0, 0, 0, 0.85)

        tooltip.MyLastPriceBG:SetFrameLevel(tooltip:GetFrameLevel() - 1)
    end

    -- Create text
    if not tooltip.MyLastPriceLine then
        tooltip.MyLastPriceLine = tooltip:CreateFontString(nil, "OVERLAY", "GameTooltipText")
        tooltip.MyLastPriceLine:SetPoint("LEFT", tooltip.MyLastPriceBG, "LEFT", 6, 0)
        tooltip.MyLastPriceLine:SetJustifyH("LEFT")
    end

    -- Set text
    local text = "|cffff8000Moje poslední cena:|r " .. MLP_FormatMoney(price)
    tooltip.MyLastPriceLine:SetText(text)

    -- Resize background to match text width
    local width = tooltip.MyLastPriceLine:GetStringWidth() + 12
    tooltip.MyLastPriceBG:SetWidth(width)

    tooltip.MyLastPriceBG:Show()
    tooltip.MyLastPriceLine:Show()
end

-- Register processors
if TooltipDataProcessor and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, MLP_AddPriceToTooltip)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.ItemKey, MLP_AddPriceToTooltip)
end

-- Battle pet cages
hooksecurefunc(GameTooltip, "SetBagItem", function(tooltip, bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if not info or not info.hyperlink then return end

    local speciesID = info.hyperlink:match("battlepet:(%d+)")
    if not speciesID then return end

    local key = "pet:" .. speciesID
    local price = MyLastPriceDB[key]
    if not price then return end

    if not BattlePetTooltip.MyLastPriceLine then
        BattlePetTooltip.MyLastPriceLine = BattlePetTooltip:CreateFontString(nil, "OVERLAY", "GameTooltipText")
        BattlePetTooltip.MyLastPriceLine:SetPoint("TOPLEFT", BattlePetTooltip, "BOTTOMLEFT", 0, -2)
    end

    BattlePetTooltip.MyLastPriceLine:SetText("|cffff8000Moje poslední cena:|r " .. MLP_FormatMoney(price))
    BattlePetTooltip.MyLastPriceLine:Show()
end)

-- Slash: /mlp reset
SLASH_MYLASTPRICE1 = "/mlp"
SlashCmdList.MYLASTPRICE = function(msg)
    msg = msg and msg:lower() or ""
    if msg == "reset" then
        MyLastPriceDB = {}
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd000[MyLastPrice]|r Databáze cen vymazána.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd000[MyLastPrice]|r Příkazy: /mlp reset")
    end
end

-- Save prices when posting to Auction House
if C_AuctionHouse then
    if C_AuctionHouse.PostItem then
        hooksecurefunc(C_AuctionHouse, "PostItem", function(itemLocation, duration, quantity, bid, buyout, auctionType)
            if not buyout or buyout <= 0 then return end
            if not itemLocation or not C_Item.IsItemDataCached(itemLocation) then return end

            local itemID = C_Item.GetItemID(itemLocation)
            if not itemID then return end
            local link = C_Item.GetItemLink(itemLocation) or ("item:"..itemID)

            if itemID == 82800 then
                local speciesID = link:match("battlepet:(%d+)")
                if not speciesID then return end
                local key = "pet:" .. speciesID
                MyLastPriceDB[key] = buyout
            else
                MyLastPriceDB[itemID] = buyout
            end

            DEFAULT_CHAT_FRAME:AddMessage("|cffffd000[MyLastPrice]|r Cena uložena pro: " .. link .. " (" .. MLP_FormatMoney(buyout) .. ")")
        end)
    end

    if C_AuctionHouse.PostCommodity then
        hooksecurefunc(C_AuctionHouse, "PostCommodity", function(itemLocation, duration, quantity, unitPrice)
            if not unitPrice or unitPrice <= 0 then return end
            if not itemLocation then return end

            local itemID = C_Item.GetItemID(itemLocation)
            if not itemID then return end
            local link = C_Item.GetItemLink(itemLocation) or ("item:"..itemID)

            MyLastPriceDB[itemID] = unitPrice
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd000[MyLastPrice]|r Cena uložena pro: " .. link .. " (" .. MLP_FormatMoney(unitPrice) .. ")")
        end)
    end
end