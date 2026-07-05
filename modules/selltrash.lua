-- HoryUI :: selltrash -- a "Sell Trash" button on the merchant window that
-- vendors every grey (poor-quality) item in your bags in one click.
--
-- Grey detection uses the item LINK's colour hex (|cff9d9d9d) -- the same reliable
-- source bags.lua / vendorprice.lua use, since 1.12 (Turtle) leaves
-- GetContainerItemInfo's quality return unset. Selling is UseContainerItem while
-- the merchant window is open (vanilla treats that as a sell, not a use). The
-- reported total is summed from the vendored sell-price DB (HoryUI.sellData) when
-- the item is present; unknown items still sell, they just don't add to the total.
--
-- Sells are STAGGERED -- one item per 0.1s tick, pfUI autovendor's technique
-- (pfUI/modules/autovendor.lua). Firing every UseContainerItem in one synchronous
-- burst made the server drop one request WITHOUT replying, and that slot then
-- stayed locked until a full client restart (item locks are client-engine state;
-- a /reload can't clear them). One sell per tick lets each lock/unlock round-trip
-- resolve between requests. The seller frame is hidden while idle (its OnUpdate
-- only runs during a sale), aborts when the merchant closes, and defuses on
-- PLAYER_LOGOUT.

HoryUI:RegisterModule("selltrash", true, function()
  if not MerchantFrame then return end
  local C = HoryUI.color
  local strfind, strlower, tonumber = string.find, string.lower, tonumber
  local floor, mod = math.floor, math.mod
  local GetTime = GetTime
  local GetContainerNumSlots = GetContainerNumSlots
  local GetContainerItemLink, GetContainerItemInfo = GetContainerItemLink, GetContainerItemInfo
  local UseContainerItem = UseContainerItem
  local sellData = HoryUI.sellData

  local function Money(c)
    local g = floor(c / 10000)
    local s = floor(mod(c, 10000) / 100)
    local cop = mod(c, 100)
    local out = ""
    if g > 0 then out = out .. g .. "g " end
    if g > 0 or s > 0 then out = out .. s .. "s " end
    return out .. cop .. "c"
  end

  -- sell price (copper) for an item link from the vendored DB; 0 if unknown/none
  local function SellValue(link)
    if not sellData then return 0 end
    local _, _, id = strfind(link, "item:(%d+):")
    id = id and tonumber(id)
    local data = id and sellData[id]
    if not data then return 0 end
    local _, _, sell = strfind(data, "(%d+),")       -- "sell,buy" -> sell copper
    return (sell and tonumber(sell)) or 0
  end

  -- ==========================================================================
  -- the seller: shown = a run is active; one item per tick, then summary ------
  -- ==========================================================================
  local seller = CreateFrame("Frame")
  seller:Hide()

  seller:SetScript("OnShow", function()
    this.processed = {}      -- slots already sent this run (never re-sent)
    this.count = 0
    this.value = 0
    this.tick = 0
  end)

  -- next unprocessed grey slot; marks it processed so a slot is sent AT MOST
  -- once per run even if the server never empties it (matches pfUI autovendor)
  local function NextTrash()
    for bag = 0, 4 do
      local slots = GetContainerNumSlots(bag) or 0
      for slot = 1, slots do
        local key = bag .. "x" .. slot
        if not seller.processed[key] then
          local link = GetContainerItemLink(bag, slot)
          -- poor quality (grey) = the |cff9d9d9d colour prefix on the link
          if link and strfind(strlower(link), "|cff9d9d9d") then
            seller.processed[key] = true
            return bag, slot, link
          end
        end
      end
    end
  end

  seller:SetScript("OnUpdate", function()
    if this.tick > GetTime() then return end
    this.tick = GetTime() + 0.1

    if not MerchantFrame:IsShown() then this:Hide() return end

    local bag, slot, link = NextTrash()
    if not bag then
      this:Hide()                              -- drained; OnHide prints the summary
      return
    end
    local _, itemCount, locked = GetContainerItemInfo(bag, slot)
    if locked then return end                  -- in flight; skip (stays processed)
    this.count = this.count + 1
    this.value = this.value + SellValue(link) * (itemCount or 1)
    ClearCursor()
    UseContainerItem(bag, slot)                -- sells at an open merchant
  end)

  seller:SetScript("OnHide", function()
    if this.count > 0 then
      local msg = "HoryUI: sold " .. this.count .. " trash item" .. (this.count == 1 and "" or "s")
      if this.value > 0 then msg = msg .. " for " .. Money(this.value) end
      DEFAULT_CHAT_FRAME:AddMessage(msg, C.accent_hi[1], C.accent_hi[2], C.accent_hi[3])
    else
      DEFAULT_CHAT_FRAME:AddMessage("HoryUI: no trash to sell.", C.text2[1], C.text2[2], C.text2[3])
    end
  end)

  seller:RegisterEvent("PLAYER_LOGOUT")
  seller:SetScript("OnEvent", function()
    this:UnregisterAllEvents()
    this:SetScript("OnEvent", nil)
    this:SetScript("OnUpdate", nil)
    this:SetScript("OnHide", nil)
  end)

  -- above the merchant window's top-left corner, so it never overlaps the item
  -- grid, page buttons, or the money frame regardless of the (pfskin) skin.
  local btn = HoryUI.CreateButton(MerchantFrame, "Sell Trash", function()
    if MerchantFrame:IsShown() then seller:Show() end    -- Show on a running seller is a no-op
  end)
  btn:SetWidth(90)
  btn:SetPoint("BOTTOMLEFT", MerchantFrame, "TOPLEFT", 12, 4)

  -- CreateButton wires a border-hover; re-wire it here to also carry a tooltip
  btn:SetScript("OnEnter", function()
    local a = C.accent_hi
    if this.backdrop then this.backdrop:SetBackdropBorderColor(a[1], a[2], a[3], 1) end
    GameTooltip:SetOwner(this, "ANCHOR_TOP")
    GameTooltip:SetText("Sell Trash")
    GameTooltip:AddLine("Sell every grey (poor) item in your bags.", C.text2[1], C.text2[2], C.text2[3], 1)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function()
    if this.backdrop then this.backdrop:SetBackdropBorderColor(0, 0, 0, 1) end
    GameTooltip:Hide()
  end)
end)
