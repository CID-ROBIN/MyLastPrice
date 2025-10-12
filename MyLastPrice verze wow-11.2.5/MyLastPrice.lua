-- SavedVariables init
if not MyLastPriceDB then
    MyLastPriceDB = {}
end

-- Pomocné: formátování měny
local function MLP_FormatMoney(copper)
    if not copper or copper <= 0 then return "0g" end
    local gold  = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperOnly = copper % 100
    return string.format("%dg %ds %dc", gold, silver, copperOnly)
end

-- Pomocné: výpis do chatu
local function MLP_Print(...)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd000[MyLastPrice]|r " .. table.concat({...}, " "))
end

-- Bezpečné zjištění itemID z různých typů argumentů
local function MLP_ResolveItemID(arg)
    if not arg then return nil end
    if type(arg) == "number" then
        return arg
    elseif type(arg) == "table" then
        -- itemKey { itemID = number }
        if arg.itemID and type(arg.itemID) == "number" then
            return arg.itemID
        end
        -- itemLocation struktura (bagID/slotIndex) u PostCommodity
        if arg.bagID ~= nil and arg.slotIndex ~= nil and ItemLocation then
            local loc = ItemLocation:CreateFromBagAndSlot(arg.bagID, arg.slotIndex)
            if C_Item and C_Item.DoesItemExist(loc) then
                local id = C_Item.GetItemID(loc)
                if id then return id end
            end
        end
        -- některé Blizz struktury mohou mít .id
        if arg.id and type(arg.id) == "number" then
            return arg.id
        end
    elseif type(arg) == "string" then
        -- může být itemLink
        local id = GetItemInfoInstant(arg)
        if id then return id end
    end
    return nil
end

-- Uložení ceny do DB (za kus)
local function MLP_SavePrice(itemID, perItemBuyout)
    if not itemID or not perItemBuyout or perItemBuyout <= 0 then return end
    MyLastPriceDB[itemID] = perItemBuyout
    MLP_Print("Uloženo pro itemID ", tostring(itemID), ": ", MLP_FormatMoney(perItemBuyout))
end

-- Hook: postování klasických itemů (stack → přepočítáme na cenu za kus)
if C_AuctionHouse and C_AuctionHouse.PostItem then
    hooksecurefunc(C_AuctionHouse, "PostItem", function(itemKey, duration, quantity, bid, buyout, auctionType)
        local itemID = MLP_ResolveItemID(itemKey)
        if itemID and buyout and quantity and quantity > 0 then
            local perItem = math.floor(buyout / quantity)
            MLP_SavePrice(itemID, perItem)
        end
    end)
end

-- Hook: postování commodities (unitPrice je už za kus, item argument je itemLocation)
if C_AuctionHouse and C_AuctionHouse.PostCommodity then
    hooksecurefunc(C_AuctionHouse, "PostCommodity", function(itemArg, duration, quantity, unitPrice)
        local itemID = MLP_ResolveItemID(itemArg)
        if itemID and unitPrice and unitPrice > 0 then
            MLP_SavePrice(itemID, unitPrice)
        end
    end)
end

-- Tooltip: přidání řádku s poslední cenou (nový TooltipDataProcessor systém)
local function MLP_AddPriceToTooltip(tooltip, data)
    if not tooltip or not data then return end
    local itemID = data.id
    if not itemID and data.hyperlink then
        itemID = GetItemInfoInstant(data.hyperlink)
    end
    if itemID and MyLastPriceDB[itemID] then
        tooltip:AddLine("|cffffd000Moje poslední cena:|r " .. MLP_FormatMoney(MyLastPriceDB[itemID]))
        tooltip:Show()
    end
end

if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, MLP_AddPriceToTooltip)
end

-- Slash command: reset
SLASH_MYLASTPRICE1 = "/mlp"
SlashCmdList.MYLASTPRICE = function(msg)
    msg = msg and msg:lower() or ""
    if msg == "reset" then
        MyLastPriceDB = {}
        MLP_Print("Databáze cen vymazána.")
    else
        MLP_Print("Příkazy: /mlp reset")
    end
end
