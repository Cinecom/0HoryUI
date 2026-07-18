-- HoryUI :: one-bank (Garnet)
--
-- The bank analogue of modules/bags.lua: replaces Blizzard's BankFrame with a
-- single movable, styled grid showing the base bank container (-1) plus every
-- equipped bank bag (containers 5..10). Same techniques + look as the one-bag,
-- so the two frames read as one product.
--
-- TECHNIQUE (see modules/bags.lua): every slot is a real Button built from
-- "ContainerFrameItemButtonTemplate" parented to a per-bag holder whose
-- :SetID(bag) the template reads; the button's :SetID(slot) does the rest. The
-- container API (GetContainerItemInfo / PickupContainerItem / UseContainerItem /
-- SetBagItem) all accept the bank container -1 and the bank bags, so all native
-- click / drag / tooltip / cooldown behaviour comes for free.
--
-- The one bank-only piece is the purchasable bank BAG SLOTS: the options popup's
-- icon strip shows the base bank, each equipped/empty bank bag slot (equippable
-- like bags 1-4 via ContainerIDToInventoryID), and a "+" to buy the next slot.
--
-- Lua 5.0 / WoW 1.12 only -- see CLAUDE.md before editing.

HoryUI:RegisterModule("bank", true, function()
  local C = HoryUI.color
  local getn, floor, mod = table.getn, math.floor, math.mod
  local strfind, strlower, strsub = string.find, string.lower, string.sub

  -- bank container ids: -1 is the base bank; bank bags follow the backpack bags
  -- (5 .. 4+NUM_BANKBAGSLOTS). Constants are stock 1.12 globals; keep fallbacks.
  local BANK   = -1
  local NBAG   = NUM_BAG_SLOTS or 4
  local NBANK  = NUM_BANKBAGSLOTS or 6

  -- layout scale (CLAUDE.md spacing: 1/2/4/8/12/16) -- identical to the one-bag
  local SLOT   = 30          -- item button edge
  local GAP    = 2           -- gap between cells
  local PAD    = 8           -- frame inner padding
  local HEADER = 22          -- header strip height (search / controls)

  -- column clamp + default (own saved key so the bank grid is shaped independently)
  local MINCOL, MAXCOL, DEFCOL = 6, 20, 14
  if not HoryUIDB.bankCols then HoryUIDB.bankCols = DEFCOL end

  local function Cols()
    local n = HoryUIDB.bankCols or DEFCOL
    if n < MINCOL then n = MINCOL elseif n > MAXCOL then n = MAXCOL end
    return n
  end

  -- =========================================================================
  -- money formatting (shared look with the one-bag) --------------------------
  -- =========================================================================
  local GOLD, SILVER, COPPER = "ffffd700", "ffc7c7cf", "ffeda55f"
  local function MoneyString(copper)
    copper = copper or 0
    local g = floor(copper / 10000)
    local s = floor(mod(copper, 10000) / 100)
    local c = mod(copper, 100)
    local out = ""
    if g > 0 then out = out .. g .. "|c" .. GOLD .. "g|r " end
    if g > 0 or s > 0 then out = out .. s .. "|c" .. SILVER .. "s|r " end
    out = out .. c .. "|c" .. COPPER .. "c|r"
    return out
  end

  -- the containers we present, in display order: base bank then every bank bag.
  -- unpurchased / empty bank bags simply report 0 slots, so keeping them all in
  -- the list is harmless (EnsureSlots hides any cell beyond the live size).
  local containers = { BANK }
  for b = NBAG + 1, NBAG + NBANK do containers[getn(containers) + 1] = b end

  local function BagSize(b) return GetContainerNumSlots(b) or 0 end

  -- =========================================================================
  -- main frame ---------------------------------------------------------------
  -- =========================================================================
  local bank = CreateFrame("Frame", "HoryUIBank", UIParent)
  bank:SetWidth(Cols() * (SLOT + GAP) - GAP + PAD * 2)
  bank:SetHeight(120)
  bank:SetFrameStrata("HIGH")
  bank:EnableMouse(true)              -- swallow clicks so they don't fall through
  HoryUI.CreateBackdrop(bank)
  HoryUI.RegisterPanel(bank, "bank", "Bank", "TOPLEFT", 180, -120)
  tinsert(UISpecialFrames, "HoryUIBank")   -- Esc closes it (-> OnHide -> CloseBankFrame)

  -- tracks whether the banker is actually open, so hiding our frame (close button /
  -- Esc) tells the server via CloseBankFrame while a BANKFRAME_CLOSED-driven hide
  -- (already false) does not recurse. See the driver + OnHide below.
  local bankOpen = false

  -- direct drag: grab the frame body to move it (in addition to the unlock-mover)
  bank:RegisterForDrag("LeftButton")
  bank:SetScript("OnDragStart", function() this:StartMoving() end)
  bank:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    HoryUI.SavePosition(this, "bank")
  end)

  -- per-bag holders (carry the bag id via :SetID for the item template) -------
  local holders = {}      -- holders[bag] = Frame
  local slots = {}        -- slots[bag][slot] = Button
  for ci = 1, getn(containers) do
    local b = containers[ci]
    -- a negative id reads awkwardly in a frame name; spell the base bank out
    local suffix = (b == BANK) and "Bank" or b
    holders[b] = CreateFrame("Frame", "HoryUIBankHolder" .. suffix, bank)
    holders[b]:SetID(b)
    holders[b]:SetAllPoints(bank)
    slots[b] = {}
  end

  -- =========================================================================
  -- header: search + money + free + controls + close -------------------------
  -- =========================================================================
  local money = bank:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(money, HoryUI.font.number, 11, "OUTLINE")
  money:SetPoint("BOTTOMRIGHT", bank, "BOTTOMRIGHT", -PAD, 6)
  money:SetJustifyH("RIGHT")
  money:SetTextColor(C.text[1], C.text[2], C.text[3])

  local freetext = bank:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(freetext, HoryUI.font.number, 11, "OUTLINE")
  freetext:SetPoint("BOTTOMLEFT", bank, "BOTTOMLEFT", PAD, 6)
  freetext:SetJustifyH("LEFT")
  freetext:SetTextColor(C.text2[1], C.text2[2], C.text2[3])

  local close = HoryUI.CreateButton(bank, "x", function() bank:Hide() end)
  close:SetWidth(HEADER - 4); close:SetHeight(HEADER - 4)
  close:SetPoint("TOPRIGHT", bank, "TOPRIGHT", -PAD + 2, -PAD + 2)

  -- a tiny labelled square control (menu / sort / col steppers / buy) ---------
  local function MakeControl(label, tip, onclick, w, parent)
    local b = HoryUI.CreateButton(parent or bank, label, onclick)
    b:SetWidth(w or (HEADER - 4)); b:SetHeight(HEADER - 4)
    local oe, ol = b:GetScript("OnEnter"), b:GetScript("OnLeave")
    b:SetScript("OnEnter", function()
      if oe then oe() end
      if tip then GameTooltip:SetOwner(this, "ANCHOR_TOP"); GameTooltip:AddLine(tip); GameTooltip:Show() end
    end)
    b:SetScript("OnLeave", function()
      if ol then ol() end
      GameTooltip:Hide()
    end)
    return b
  end

  -- defined below; the header + popup-menu controls need forward references
  local Relayout, SortBags, PaintQuality
  local menu, RefreshBagIcons, HighlightBag, ClearHighlight
  local colDown, colNum, colUp

  local menuBtn = MakeControl("", "Bank options", function()
    if menu:IsShown() then
      menu:Hide()
    else
      if RefreshBagIcons then RefreshBagIcons() end
      menu:Show()
    end
  end)
  menuBtn:SetPoint("TOPLEFT", bank, "TOPLEFT", PAD, -PAD + 2)
  for i = 1, 3 do
    local ln = menuBtn:CreateTexture(nil, "OVERLAY")
    ln:SetTexture("Interface\\Buttons\\WHITE8X8")
    ln:SetVertexColor(C.text2[1], C.text2[2], C.text2[3], 1)
    ln:SetWidth(8); ln:SetHeight(2)
    ln:SetPoint("CENTER", menuBtn, "CENTER", 0, (2 - i) * 3)
  end

  -- search box (between the menu button and the close button)
  local searchBox = CreateFrame("EditBox", "HoryUIBankSearch", bank)
  searchBox:SetHeight(HEADER - 6)
  searchBox:SetAutoFocus(false)
  searchBox:SetFont(HoryUI.font.normal, 11, "OUTLINE")
  searchBox:SetTextColor(C.text[1], C.text[2], C.text[3])
  searchBox:SetTextInsets(4, 4, 0, 0)
  HoryUI.CreateBackdrop(searchBox)

  local searchHint = searchBox:CreateFontString(nil, "ARTWORK")
  HoryUI.SetFont(searchHint, HoryUI.font.normal, 11, "OUTLINE")
  searchHint:SetPoint("LEFT", searchBox, "LEFT", 5, 0)
  searchHint:SetText("Search")
  searchHint:SetTextColor(C.text3[1], C.text3[2], C.text3[3])

  searchBox:SetPoint("LEFT", menuBtn, "RIGHT", 6, 0)
  searchBox:SetPoint("RIGHT", close, "LEFT", -6, 0)
  searchBox:SetPoint("TOP", bank, "TOP", 0, -PAD + 1)

  -- =========================================================================
  -- search filter (dim non-matching items) -----------------------------------
  -- =========================================================================
  local function ApplySearch()
    local q = searchBox:GetText()
    if q == nil then q = "" end
    q = strlower(q)
    if q == "" and not searchBox.focused then searchHint:Show() else searchHint:Hide() end
    local filtering = (q ~= "")
    for ci = 1, getn(containers) do
      local b = containers[ci]
      local list = slots[b]
      for s = 1, getn(list) do
        local btn = list[s]
        if btn and btn:IsShown() then
          if not filtering then
            btn.icon:SetAlpha(1)
          else
            local link = GetContainerItemLink(b, s)
            local match = false
            if link then
              local _, _, nm = strfind(link, "%[(.+)%]")
              if nm and strfind(strlower(nm), q, 1, true) then match = true end
            end
            btn.icon:SetAlpha(match and 1 or 0.2)
          end
        end
      end
    end
  end

  searchBox:SetScript("OnTextChanged", function() ApplySearch() end)
  searchBox:SetScript("OnEscapePressed", function() this:SetText(""); this:ClearFocus() end)
  searchBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)
  searchBox:SetScript("OnEditFocusGained", function() searchBox.focused = true; searchHint:Hide() end)
  searchBox:SetScript("OnEditFocusLost", function() searchBox.focused = false; ApplySearch() end)

  -- =========================================================================
  -- options popup: columns + sort + the bank-bag icon strip ------------------
  -- =========================================================================
  local MENUPAD = 8
  local rowH = HEADER - 4
  local BAGICON = 24
  -- the strip can hold at most: base bank + every bank bag + a buy button. Size
  -- the popup to that maximum so it never resizes as slots are bought.
  local STRIPMAX = 1 + NBANK + 1
  local STRIPW = STRIPMAX * (BAGICON + GAP) - GAP
  local MENUW = STRIPW + MENUPAD * 2

  menu = CreateFrame("Frame", "HoryUIBankMenu", bank)
  menu:SetFrameStrata("DIALOG")
  menu:EnableMouse(true)
  menu:SetWidth(MENUW)
  menu:SetHeight(MENUPAD * 2 + (rowH + 6) * 2 + BAGICON)
  HoryUI.CreateBackdrop(menu)
  menu:SetPoint("BOTTOMLEFT", menuBtn, "TOPLEFT", 0, 4)
  menu:Hide()

  local r1 = -MENUPAD
  local r2 = -(MENUPAD + (rowH + 6))
  local r3 = -(MENUPAD + (rowH + 6) * 2)

  local colLabel = menu:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(colLabel, HoryUI.font.normal, 11, "OUTLINE")
  colLabel:SetPoint("TOPLEFT", menu, "TOPLEFT", MENUPAD, r1 - 3)
  colLabel:SetText("Columns")
  colLabel:SetTextColor(C.text2[1], C.text2[2], C.text2[3])

  colUp = MakeControl("+", "More columns", function()
    HoryUIDB.bankCols = Cols() + 1
    if HoryUIDB.bankCols > MAXCOL then HoryUIDB.bankCols = MAXCOL end
    if Relayout then Relayout() end
  end, nil, menu)
  colUp:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -MENUPAD, r1)

  colNum = menu:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(colNum, HoryUI.font.number, 11, "OUTLINE")
  colNum:SetPoint("RIGHT", colUp, "LEFT", -4, 0)
  colNum:SetTextColor(C.text[1], C.text[2], C.text[3])
  colNum:SetWidth(18); colNum:SetJustifyH("CENTER")

  colDown = MakeControl("-", "Fewer columns", function()
    HoryUIDB.bankCols = Cols() - 1
    if HoryUIDB.bankCols < MINCOL then HoryUIDB.bankCols = MINCOL end
    if Relayout then Relayout() end
  end, nil, menu)
  colDown:SetPoint("RIGHT", colNum, "LEFT", -4, 0)

  local sortBtn = MakeControl("Sort", "Compact the bank (remove gaps)", function()
    if SortBags then SortBags() end
  end, nil, menu)
  sortBtn:SetPoint("TOPLEFT", menu, "TOPLEFT", MENUPAD, r2)
  sortBtn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -MENUPAD, r2)

  local bagStrip = CreateFrame("Frame", nil, menu)
  bagStrip:SetWidth(STRIPW); bagStrip:SetHeight(BAGICON)
  bagStrip:SetPoint("TOPLEFT", menu, "TOPLEFT", MENUPAD, r3)

  local function ContainerActive(hb)
    for ci = 1, getn(containers) do
      if containers[ci] == hb then return true end
    end
    return false
  end

  -- highlight = focus one bank container (garnet border on its cells, dim the rest)
  HighlightBag = function(hb)
    if not ContainerActive(hb) then return end
    for ci = 1, getn(containers) do
      local b = containers[ci]
      local list = slots[b]
      for s = 1, getn(list) do
        local btn = list[s]
        if btn and btn:IsShown() then
          if b == hb then
            if btn.backdrop then btn.backdrop:SetBackdropBorderColor(C.accent_hi[1], C.accent_hi[2], C.accent_hi[3], 1) end
            if btn.icon then btn.icon:SetAlpha(1) end
          elseif btn.icon then
            btn.icon:SetAlpha(0.25)
          end
        end
      end
    end
  end
  ClearHighlight = function()
    for ci = 1, getn(containers) do
      local b = containers[ci]
      local list = slots[b]
      for s = 1, getn(list) do
        if list[s] then PaintQuality(list[s]) end
      end
    end
    ApplySearch()
  end

  -- how many bank bag slots are purchased (empty ones are still usable slots)
  local function NumBankSlots() return GetNumBankSlots and (GetNumBankSlots() or 0) or 0 end

  -- the strip's contents are dynamic (only purchased bank bags + one buy button),
  -- so it's rebuilt each time the popup opens / a slot is bought.
  local bagIcons = {}      -- bagIcons[id] = Button (id: BANK, a bank-bag container, or "buy")
  local buyBtn

  local function MakeBagIcon(id)
    local ib = CreateFrame("Button", nil, bagStrip)
    ib:SetWidth(BAGICON); ib:SetHeight(BAGICON)
    HoryUI.CreateBackdrop(ib)
    ib.tex = ib:CreateTexture(nil, "ARTWORK")
    ib.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    ib.tex:SetPoint("TOPLEFT", ib, "TOPLEFT", 1, -1)
    ib.tex:SetPoint("BOTTOMRIGHT", ib, "BOTTOMRIGHT", -1, 1)

    ib:SetScript("OnEnter", function()
      HighlightBag(id)
      if ib.backdrop then ib.backdrop:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1) end
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      if id == BANK then
        GameTooltip:SetText("Bank")
      else
        local inv = GetInventoryItemTexture("player", ContainerIDToInventoryID(id))
        if inv then GameTooltip:SetInventoryItem("player", ContainerIDToInventoryID(id))
        else GameTooltip:SetText("Empty Bank Bag Slot"); GameTooltip:AddLine("Drag a bag here", 0.7, 0.7, 0.7) end
      end
      GameTooltip:Show()
    end)
    ib:SetScript("OnLeave", function()
      ClearHighlight()
      if ib.backdrop then ib.backdrop:SetBackdropBorderColor(0, 0, 0, 1) end
      GameTooltip:Hide()
    end)

    -- a bank bag is an equippable slot (like bags 1-4), reached by its inventory id
    if id ~= BANK then
      local invID = ContainerIDToInventoryID(id)
      ib:SetID(invID)
      ib:RegisterForDrag("LeftButton")
      ib:SetScript("OnClick", function()
        if CursorHasItem() then PutItemInBag(invID) else PickupBagFromSlot(invID) end
      end)
      ib:SetScript("OnDragStart", function() PickupBagFromSlot(invID) end)
      ib:SetScript("OnReceiveDrag", function() PutItemInBag(invID) end)
    end
    return ib
  end

  -- the "+" buy button for the next bank bag slot (its own affordance, not a bag)
  local function MakeBuyIcon()
    local b = HoryUI.CreateButton(bagStrip, "+", function()
      StaticPopup_Show("CONFIRM_BUY_BANK_SLOT")
    end)
    b:SetWidth(BAGICON); b:SetHeight(BAGICON)
    local oe, ol = b:GetScript("OnEnter"), b:GetScript("OnLeave")
    b:SetScript("OnEnter", function()
      if oe then oe() end
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText("Buy Bank Bag Slot")
      if GetBankSlotCost then
        GameTooltip:AddLine("Cost: " .. MoneyString(GetBankSlotCost(NumBankSlots())), 1, 1, 1)
      end
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if ol then ol() end; GameTooltip:Hide() end)
    return b
  end

  RefreshBagIcons = function()
    local n = NumBankSlots()
    local i = 0   -- running strip position (0-based)

    -- base bank first
    if not bagIcons[BANK] then bagIcons[BANK] = MakeBagIcon(BANK) end
    local bankIcon = bagIcons[BANK]
    bankIcon:ClearAllPoints()
    bankIcon:SetPoint("LEFT", bagStrip, "LEFT", i * (BAGICON + GAP), 0)
    bankIcon.tex:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
    if bankIcon.backdrop then bankIcon.backdrop:SetBackdropBorderColor(0, 0, 0, 1) end
    bankIcon:Show()
    i = i + 1

    -- one icon per purchased bank bag slot (equipped bag art, else empty-slot art)
    for slot = 1, NBANK do
      local b = NBAG + slot
      local ib = bagIcons[b]
      if slot <= n then
        if not ib then ib = MakeBagIcon(b); bagIcons[b] = ib end
        ib:ClearAllPoints()
        ib:SetPoint("LEFT", bagStrip, "LEFT", i * (BAGICON + GAP), 0)
        ib.tex:SetTexture(GetInventoryItemTexture("player", ContainerIDToInventoryID(b))
          or "Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
        if ib.backdrop then ib.backdrop:SetBackdropBorderColor(0, 0, 0, 1) end
        ib:Show()
        i = i + 1
      elseif ib then
        ib:Hide()
      end
    end

    -- the buy button, only while there are still slots to purchase
    if n < NBANK then
      if not buyBtn then buyBtn = MakeBuyIcon() end
      buyBtn:ClearAllPoints()
      buyBtn:SetPoint("LEFT", bagStrip, "LEFT", i * (BAGICON + GAP), 0)
      buyBtn:Show()
    elseif buyBtn then
      buyBtn:Hide()
    end
  end

  menu:SetScript("OnHide", function() if ClearHighlight then ClearHighlight() end end)
  bank:SetScript("OnHide", function()
    menu:Hide()
    -- user-initiated close (button / Esc) while the banker is open: notify the
    -- server. A BANKFRAME_CLOSED-driven hide clears bankOpen first, so no recursion.
    if bankOpen then CloseBankFrame() end
  end)

  -- =========================================================================
  -- item buttons -------------------------------------------------------------
  -- =========================================================================
  local function MakeSlot(b, s)
    local name = "HoryUIBankItem" .. (b == BANK and "Bank" or b) .. "_" .. s
    local btn = CreateFrame("Button", name, holders[b], "ContainerFrameItemButtonTemplate")
    btn:SetID(s)
    btn:SetWidth(SLOT); btn:SetHeight(SLOT)
    btn:SetNormalTexture("")          -- drop the chunky default border art
    HoryUI.CreateBackdrop(btn)

    btn.icon = getglobal(name .. "IconTexture")
    if btn.icon then
      btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      btn.icon:ClearAllPoints()
      btn.icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
      btn.icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    end

    btn.count = getglobal(name .. "Count")
    if btn.count then
      HoryUI.SetFont(btn.count, HoryUI.font.number, 11, "OUTLINE")
      btn.count:ClearAllPoints()
      btn.count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    end

    btn.cd = getglobal(name .. "Cooldown")

    -- The base bank container (-1) needs its own tooltip: the template's native
    -- OnEnter calls GameTooltip:SetBagItem(bag, slot), and in 1.12 SetBagItem does
    -- NOT populate the bank container (-1) -- it comes up empty, so only appended
    -- rows (e.g. the vendorprice coin row) showed, with no name/description. Bank
    -- items must be shown by their inventory slot; fall back to the item link.
    -- (Bank bags 5-10 are ordinary containers, so their native SetBagItem works.)
    if b == BANK then
      btn:SetScript("OnEnter", function()
        local slot = this:GetID()
        local link = GetContainerItemLink(BANK, slot)
        if not link then GameTooltip:Hide(); return end
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        local shown
        if BankButtonIDToInvSlotID then
          shown = GameTooltip:SetInventoryItem("player", BankButtonIDToInvSlotID(slot))
        end
        if not shown then GameTooltip:SetHyperlink(link) end
        GameTooltip:Show()
      end)
      btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
      -- This client's ContainerFrame.lua (unlike stock 1.12) re-fires the GLOBAL
      -- ContainerFrameItemButton_OnEnter from the template's OnUpdate every 0.2s
      -- while the tooltip is owned by the button -- and that global calls
      -- SetBagItem(-1, slot), the exact call that comes up empty for the bank
      -- container. So our OnEnter built the correct tooltip and 0.2s later it was
      -- wiped to an empty one (only addon-appended rows survived). The template's
      -- OnUpdate does nothing else on this client; drop it for base-bank buttons.
      btn:SetScript("OnUpdate", nil)
    end

    return btn
  end

  -- colour a slot's border from the item LINK's quality hex (|cffRRGGBB); Turtle
  -- leaves GetContainerItemInfo's quality unset, so the link is the reliable source.
  PaintQuality = function(btn)
    if not btn or not btn.backdrop then return end
    local r, g, bl
    if btn.hasItem and btn.link then
      local _, _, hex = strfind(btn.link, "|c%x%x(%x%x%x%x%x%x)")
      if hex then
        hex = strlower(hex)
        if hex ~= "ffffff" and hex ~= "9d9d9d" then
          r  = tonumber(strsub(hex, 1, 2), 16) / 255
          g  = tonumber(strsub(hex, 3, 4), 16) / 255
          bl = tonumber(strsub(hex, 5, 6), 16) / 255
        end
      end
    end
    if r then btn.backdrop:SetBackdropBorderColor(r, g, bl, 1)
    else btn.backdrop:SetBackdropBorderColor(0, 0, 0, 1) end
  end

  local function EnsureSlots(b)
    local size = BagSize(b)
    for s = 1, size do
      if not slots[b][s] then slots[b][s] = MakeSlot(b, s) end
    end
    for s = size + 1, getn(slots[b]) do
      if slots[b][s] then slots[b][s]:Hide() end
    end
    return size
  end

  -- =========================================================================
  -- per-slot content update --------------------------------------------------
  -- =========================================================================
  local function UpdateSlot(b, s)
    local btn = slots[b][s]
    if not btn then return end
    local texture, count, locked, quality = GetContainerItemInfo(b, s)
    btn.quality = quality
    btn.link = GetContainerItemLink(b, s)
    SetItemButtonTexture(btn, texture)
    SetItemButtonCount(btn, count)
    SetItemButtonDesaturated(btn, locked, 0.5, 0.5, 0.5)
    btn.hasItem = texture and 1 or nil
    ContainerFrame_UpdateCooldown(b, btn)
    PaintQuality(btn)
    btn:Show()
  end

  local function UpdateBag(b)
    local size = EnsureSlots(b)
    for s = 1, size do UpdateSlot(b, s) end
  end

  -- =========================================================================
  -- layout: pack every shown slot into one Cols()-wide grid ------------------
  -- =========================================================================
  Relayout = function()
    local cols = Cols()
    colNum:SetText(cols)
    if menu and menu:IsShown() and RefreshBagIcons then RefreshBagIcons() end

    local index = 0
    for ci = 1, getn(containers) do
      local b = containers[ci]
      local size = EnsureSlots(b)
      for s = 1, size do
        local btn = slots[b][s]
        local col = mod(index, cols)
        local row = floor(index / cols)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", bank, "TOPLEFT",
          PAD + col * (SLOT + GAP),
          -(PAD + HEADER + row * (SLOT + GAP)))
        UpdateSlot(b, s)
        index = index + 1
      end
    end

    local rows = (index > 0) and (floor((index - 1) / cols) + 1) or 1
    local gridW = cols * (SLOT + GAP) - GAP
    local FOOTER = 18
    bank:SetWidth(gridW + PAD * 2)
    bank:SetHeight(PAD + HEADER + rows * (SLOT + GAP) - GAP + FOOTER + PAD)

    ApplySearch()
  end

  -- =========================================================================
  -- header readouts: money + free slots --------------------------------------
  -- =========================================================================
  local function UpdateMoney() money:SetText(MoneyString(GetMoney())) end

  local function UpdateFree()
    local free, total = 0, 0
    for ci = 1, getn(containers) do
      local b = containers[ci]
      local size = BagSize(b)
      total = total + size
      for s = 1, size do
        if not GetContainerItemInfo(b, s) then free = free + 1 end
      end
    end
    freetext:SetText(free .. " / " .. total .. " free")
  end

  -- =========================================================================
  -- sort: honest "compact" -- see modules/bags.lua for the full rationale.
  -- Pull each item toward the first empty cell across the whole bank; moving
  -- into a guaranteed-empty slot can never overwrite, so a locked item no-ops
  -- and the user re-clicks. Gap-removal, not type-grouping.
  -- =========================================================================
  SortBags = function()
    if not bank:IsShown() then return end
    local cells = {}
    for ci = 1, getn(containers) do
      local b = containers[ci]
      local size = BagSize(b)
      for s = 1, size do
        cells[getn(cells) + 1] = { b, s }
      end
    end
    local n = getn(cells)
    ClearCursor()

    local write = 1
    for read = 1, n do
      local br, sr = cells[read][1], cells[read][2]
      local texture, _, locked = GetContainerItemInfo(br, sr)
      if texture and not locked then
        local bw, sw = cells[write][1], cells[write][2]
        if write ~= read then
          local wtex, _, wlocked = GetContainerItemInfo(bw, sw)
          if not wtex and not wlocked then
            PickupContainerItem(br, sr)
            PickupContainerItem(bw, sw)
            ClearCursor()
          end
        end
        write = write + 1
      end
    end
  end

  -- =========================================================================
  -- hide Blizzard's BankFrame -- but keep it ALIVE ---------------------------
  -- =========================================================================
  -- We deliberately do NOT HideBlizzard() it (that unregisters its events):
  -- Blizzard's BankFrame still runs its own bank bookkeeping on BANKFRAME_OPENED.
  -- Instead we make it a sub-pixel, transparent, non-interactive speck in the
  -- top-left corner (pfUI's proven approach) so it's invisible but functional.
  -- Our own `driver` frame registers BANKFRAME_OPENED/CLOSED independently, so
  -- our frame opens regardless. Guard against ShowUIPanel re-anchoring/re-sizing it.
  if BankFrame then
    local function TuckBankFrame()
      BankFrame:SetAlpha(0)
      BankFrame:SetScale(0.0001)
      BankFrame:ClearAllPoints()
      BankFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
      BankFrame:EnableMouse(false)
    end
    TuckBankFrame()
    -- ShowUIPanel resets scale/anchor when Blizzard shows the panel on open;
    -- re-tuck on its OnShow so it never flashes into view.
    local oldShow = BankFrame:GetScript("OnShow")
    BankFrame:SetScript("OnShow", function()
      if oldShow then oldShow() end
      TuckBankFrame()
    end)
  end

  -- =========================================================================
  -- lock (grey-out) repaint -- runs IMMEDIATELY on ITEM_LOCK_CHANGED, not on
  -- the throttled tick (mirrors bags.lua: the delayed grey-out left a window
  -- where an in-flight slot still looked clickable). Skipped while the bank is
  -- closed -- BANKFRAME_OPENED's Relayout repaints everything on open anyway.
  -- =========================================================================
  local function PaintLocks()
    if not bank:IsShown() then return end
    for ci = 1, getn(containers) do
      local b = containers[ci]
      local size = BagSize(b)
      for s = 1, size do
        local btn = slots[b][s]
        if btn and btn:IsShown() then
          local _, _, locked = GetContainerItemInfo(b, s)
          SetItemButtonDesaturated(btn, locked, 0.5, 0.5, 0.5)
        end
      end
    end
  end

  -- =========================================================================
  -- driver: events + throttled relayout --------------------------------------
  -- =========================================================================
  local driver = CreateFrame("Frame")
  driver.dirty = false
  driver.cdDirty = false
  driver.acc = 0
  driver:RegisterEvent("PLAYER_LOGOUT")
  driver:RegisterEvent("BANKFRAME_OPENED")
  driver:RegisterEvent("BANKFRAME_CLOSED")
  driver:RegisterEvent("BAG_UPDATE")
  driver:RegisterEvent("BAG_CLOSED")
  -- base-bank content changes fire here (not BAG_UPDATE); bank-bag SLOT equip/
  -- purchase changes container sizes and fires PLAYERBANKBAGSLOTS_CHANGED.
  driver:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
  driver:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
  driver:RegisterEvent("BAG_UPDATE_COOLDOWN")
  driver:RegisterEvent("ITEM_LOCK_CHANGED")
  driver:RegisterEvent("PLAYER_MONEY")

  driver:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      this:SetScript("OnUpdate", nil)
      return
    elseif event == "BANKFRAME_OPENED" then
      bankOpen = true
      bank:Show()
      -- sizes are only valid once the banker is open; populate immediately so the
      -- grid isn't blank for a tick, then let follow-up events coalesce via dirty.
      Relayout(); UpdateMoney(); UpdateFree()
    elseif event == "BANKFRAME_CLOSED" then
      bankOpen = false           -- cleared BEFORE the hide so OnHide won't recurse
      bank:Hide()
    elseif event == "BAG_UPDATE" or event == "BAG_CLOSED"
        or event == "PLAYERBANKSLOTS_CHANGED" or event == "PLAYERBANKBAGSLOTS_CHANGED" then
      this.dirty = true
    elseif event == "BAG_UPDATE_COOLDOWN" then
      this.cdDirty = true
    elseif event == "ITEM_LOCK_CHANGED" then
      PaintLocks()
    elseif event == "PLAYER_MONEY" then
      UpdateMoney()
    end
  end)

  driver:SetScript("OnUpdate", function()
    this.acc = this.acc + arg1
    if this.acc < 0.1 then return end
    this.acc = 0

    -- nothing to do while the bank is closed (events still land but stay pending)
    if not bank:IsShown() then
      this.dirty = false; this.cdDirty = false
      return
    end

    if this.dirty then
      this.dirty = false
      this.cdDirty = false
      Relayout()
      UpdateMoney()
      UpdateFree()
      return
    end

    if this.cdDirty then
      this.cdDirty = false
      for ci = 1, getn(containers) do
        local b = containers[ci]
        local size = BagSize(b)
        for s = 1, size do
          local btn = slots[b][s]
          if btn and btn.hasItem then ContainerFrame_UpdateCooldown(b, btn) end
        end
      end
    end
  end)

  -- =========================================================================
  -- first build --------------------------------------------------------------
  -- =========================================================================
  for ci = 1, getn(containers) do UpdateBag(containers[ci]) end
  Relayout()
  UpdateMoney()
  UpdateFree()
  bank:Hide()         -- start closed; opens on BANKFRAME_OPENED (at a banker)
end)
