-- SavedVariables init
if not MyLastPriceDB then
    MyLastPriceDB = {}
end

-- Pomocné: formátování měny s ikonami gold/silver/copper
local function MLP_FormatMoney(copper)
    if not copper or copper <= 0 then
        return "0 |TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"
    end

    local gold  = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperOnly = copper % 100

    -- Oddělovače tisíců pro goldy
    local goldStr = tostring(gold):reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^ ", "")

    local text = ""
    if gold > 0 then
        text = text .. goldStr .. " |TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t "
    end
    if silver > 0 or gold > 0 then
        text = text .. silver .. " |TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t "
    end
    text = text .. copperOnly .. " |TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t"

    return text
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
        if arg.itemID and type(arg.itemID) == "number" then
            return arg.itemID
        end
        if arg.bagID ~= nil and arg.slotIndex ~= nil and ItemLocation then
            local loc = ItemLocation:CreateFromBagAndSlot(arg.bagID, arg.slotIndex)
            if C_Item and C_Item.DoesItemExist(loc) then
                local id = C_Item.GetItemID(loc)
                if id then return id end
            end
        end
        if arg.id and type(arg.id) == "number" then
            return arg.id
        end
    elseif type(arg) == "string" then
        local id = GetItemInfoInstant(arg)
        if id then return id end
    end
    return nil
end

-- Uložení ceny do DB (za kus)
local function MLP_SavePrice(key, perItemBuyout)
    if not key or not perItemBuyout or perItemBuyout <= 0 then return end
    MyLastPriceDB[key] = perItemBuyout
    MLP_Print("Uloženo pro ", tostring(key), ": ", MLP_FormatMoney(perItemBuyout))
end

-- Hook: postování klasických itemů a battle petů v kleci
if C_AuctionHouse and C_AuctionHouse.PostItem then
    hooksecurefunc(C_AuctionHouse, "PostItem", function(itemKey, duration, quantity, bid, buyout, auctionType)
        if not buyout or buyout <= 0 then return end
        local itemID = MLP_ResolveItemID(itemKey)
        local link = itemID and select(2, GetItemInfo(itemID))
        if link and link:match("^battlepet:") then
            local _, speciesID = strsplit(":", link)
            if speciesID then
                MLP_SavePrice("pet:"..speciesID, buyout)
                return
            end
        end
        if itemID then
            MLP_SavePrice(itemID, buyout)
        end
    end)
end

-- Hook: postování commodities (unitPrice je už za kus)
if C_AuctionHouse and C_AuctionHouse.PostCommodity then
    hooksecurefunc(C_AuctionHouse, "PostCommodity", function(itemArg, duration, quantity, unitPrice)
        if not unitPrice or unitPrice <= 0 then return end
        local itemID = MLP_ResolveItemID(itemArg)
        if itemID then
            MLP_SavePrice(itemID, unitPrice)
        end
    end)
end

-- Tooltip: přidání řádku s poslední cenou
local function MLP_AddPriceToTooltip(tooltip, data)
    if not tooltip or not data then return end
    local key

    if data.type == Enum.TooltipDataType.Item then
        key = data.id or (data.hyperlink and GetItemInfoInstant(data.hyperlink))
        -- Pokud je to battlepet v kleci, použij speciesID
        if data.hyperlink and data.hyperlink:match("^battlepet:") then
            local _, speciesID = strsplit(":", data.hyperlink)
            if speciesID then
                key = "pet:"..speciesID
            end
        end
    elseif data.type == Enum.TooltipDataType.BattlePet then
        if data.hyperlink then
            local linkType, speciesID = strsplit(":", data.hyperlink)
            if linkType == "battlepet" and speciesID then
                key = "pet:"..speciesID
            end
        end
    end

    if key and MyLastPriceDB[key] then
        tooltip:AddLine("|cffffd000Moje poslední cena:|r " .. MLP_FormatMoney(MyLastPriceDB[key]))
        tooltip:Show()
    end
end

if TooltipDataProcessor and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, MLP_AddPriceToTooltip)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.BattlePet, MLP_AddPriceToTooltip)
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
