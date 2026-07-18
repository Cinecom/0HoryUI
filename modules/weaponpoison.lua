-- HoryUI :: weapon poison / temporary enchant element (main-hand + off-hand).
-- Shows the weapon icon, remaining time and charges while a temp enchant is up.

HoryUI:RegisterModule("weaponpoison", true, function()
  local C = HoryUI.color
  local SIZE = 28
  local MINI = 16

  -- 1.12 exposes NO API for a temp enchant's identity (GetWeaponEnchantInfo is
  -- has/time/charges only), so the poison NAME is read from the weapon tooltip's
  -- enchant line ("Instant Poison V (28 min)") via a hidden scanner tooltip --
  -- the durability technique. Scanned only on inventory change / fresh apply.
  local scan = CreateFrame("GameTooltip", "HoryUIPoisonScan", UIParent, "GameTooltipTemplate")
  scan:SetOwner(WorldFrame, "ANCHOR_NONE")

  local function PoisonName(slot)
    scan:SetOwner(WorldFrame, "ANCHOR_NONE")
    scan:ClearLines()
    if not scan:SetInventoryItem("player", slot) then return nil end
    for i = 2, scan:NumLines() do -- skip the title so a weapon NAMED "...Poison..." can't match
      local fs = getglobal("HoryUIPoisonScanTextLeft" .. i)
      local txt = fs and fs:GetText()
      if txt then
        -- the enchant line is the one ending in a "(N min)"/"(N sec)" duration;
        -- this excludes "Chance on hit: Poisons..." proc text
        local low = string.lower(txt)
        if string.find(low, "%(%d+ min%)") or string.find(low, "%(%d+ sec%)") then
          local _, _, base = string.find(txt, "^(.-%sPoison)")
          if base then return base end
        end
      end
    end
    return nil
  end

  -- No API maps an enchant to an icon either: find the poison ITEM in the bags
  -- by name prefix ("Instant Poison" matches "Instant Poison V") and use its
  -- texture. Cached per base name; falls back to the generic poison bottle
  -- (uncached, so it self-heals once the item is seen in a bag).
  local texcache = {}
  local function PoisonTexture(base)
    if texcache[base] then return texcache[base] end
    for bag = 0, 4 do
      for slot = 1, GetContainerNumSlots(bag) do
        local link = GetContainerItemLink(bag, slot)
        if link then
          local _, _, name = string.find(link, "%[(.-)%]")
          if name and string.find(name, base, 1, true) == 1 then
            local tex = GetContainerItemInfo(bag, slot)
            if tex then texcache[base] = tex; return tex end
          end
        end
      end
    end
    return "Interface\\Icons\\Ability_Poisons"
  end

  local f = CreateFrame("Frame", "HoryUIWeaponBuffs", UIParent)
  f:SetWidth(SIZE * 2 + 4)
  f:SetHeight(SIZE)
  f:SetFrameStrata("MEDIUM")

  local function MakeIcon(invSlot, x)
    local b = CreateFrame("Frame", nil, f)
    b:SetWidth(SIZE)
    b:SetHeight(SIZE)
    b:SetPoint("LEFT", f, "LEFT", x, 0)
    HoryUI.CreateBackdrop(b)

    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
    b.tex:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    b.time = b:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(b.time, HoryUI.font.number, 9, "OUTLINE")
    b.time:SetPoint("BOTTOM", b, "BOTTOM", 0, 1)
    b.time:SetTextColor(C.text[1], C.text[2], C.text[3])

    b.charges = b:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(b.charges, HoryUI.font.number, 9, "OUTLINE")
    b.charges:SetPoint("TOPRIGHT", b, "TOPRIGHT", -1, -1)
    b.charges:SetTextColor(C.energy[1], C.energy[2], C.energy[3])

    -- poison identity: a small icon chip riding above the weapon icon
    -- (child of b, so it shows/hides with it)
    b.poison = CreateFrame("Frame", nil, b)
    b.poison:SetWidth(MINI)
    b.poison:SetHeight(MINI)
    b.poison:SetPoint("BOTTOMLEFT", b, "TOPLEFT", 0, 2)
    HoryUI.CreateBackdrop(b.poison)
    b.poison.tex = b.poison:CreateTexture(nil, "ARTWORK")
    b.poison.tex:SetPoint("TOPLEFT", b.poison, "TOPLEFT", 1, -1)
    b.poison.tex:SetPoint("BOTTOMRIGHT", b.poison, "BOTTOMRIGHT", -1, 1)
    b.poison.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- which hand this slot is: rides next to the poison chip above the icon
    b.label = b:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(b.label, HoryUI.font.number, 9, "OUTLINE")
    b.label:SetPoint("LEFT", b.poison, "RIGHT", 3, 0)
    b.label:SetTextColor(C.text2[1], C.text2[2], C.text2[3])
    b.label:SetText(invSlot == 16 and "MH" or "OH")

    b.slot = invSlot
    -- hover = the weapon's own tooltip; its green temp-enchant line carries the
    -- poison name + remaining time + charges (same call as the stock TemporaryEnchantFrame)
    b:EnableMouse(true)
    b:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
      GameTooltip:SetInventoryItem("player", this.slot)
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:Hide()
    return b
  end

  local mh = MakeIcon(16, 0)
  local oh = MakeIcon(17, SIZE + 4)

  local function FmtTime(sec)
    if sec >= 3600 then return math.floor(sec / 3600) .. "h"
    elseif sec >= 60 then return math.floor(sec / 60) .. "m"
    else return math.floor(sec) .. "s" end
  end

  -- forces a poison-identity rescan on the next Update; set by inventory events
  -- (weapon swap changes the enchant without the expiry ever jumping up)
  local needScan = true

  local function Apply(icon, has, exp, charges)
    if has then
      icon.tex:SetTexture(GetInventoryItemTexture("player", icon.slot) or "Interface\\Icons\\INV_Misc_QuestionMark")
      icon.time:SetText(FmtTime((exp or 0) / 1000))
      if charges and charges > 0 then icon.charges:SetText(charges) else icon.charges:SetText("") end
      -- identify the poison only when it can have changed: inventory event,
      -- first sight, or a fresh application (expiry only ever counts DOWN
      -- between updates, so any rise = a new poison was applied)
      if needScan or icon.pname == nil or (exp or 0) > (icon.lastExp or 0) then
        icon.pname = PoisonName(icon.slot) or false -- false = scanned, not a poison (don't rescan every tick)
      end
      icon.lastExp = exp or 0
      if icon.pname then
        icon.poison.tex:SetTexture(PoisonTexture(icon.pname))
        icon.poison:Show()
      else
        icon.poison:Hide()
      end
      icon:Show()
    elseif HoryUI.showAll then
      icon.tex:SetTexture("Interface\\Icons\\Ability_Poisons")
      icon.time:SetText("30m")
      icon.charges:SetText("")
      icon.poison.tex:SetTexture("Interface\\Icons\\Ability_Poisons")
      icon.poison:Show()
      icon:Show()
    else
      icon.pname = nil
      icon.lastExp = 0
      icon:Hide()
    end
  end

  local function Update()
    local hasMH, mhExp, mhCharges, hasOH, ohExp, ohCharges = GetWeaponEnchantInfo()
    Apply(mh, hasMH, mhExp, mhCharges)
    Apply(oh, hasOH, ohExp, ohCharges)
    needScan = false
    -- keep a hovered tooltip's remaining-time line current (vanilla BuffFrame technique)
    if mh:IsVisible() and GameTooltip:IsOwned(mh) then
      GameTooltip:SetInventoryItem("player", mh.slot)
    elseif oh:IsVisible() and GameTooltip:IsOwned(oh) then
      GameTooltip:SetInventoryItem("player", oh.slot)
    end
  end

  local acc = 0
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("UNIT_INVENTORY_CHANGED")
  ev:RegisterEvent("PLAYER_LOGOUT")
  ev:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      this:SetScript("OnUpdate", nil)
      return
    end
    needScan = true -- UNIT_INVENTORY_CHANGED / PLAYER_ENTERING_WORLD: the weapon may have changed
    Update()
  end)
  ev:SetScript("OnUpdate", function()
    acc = acc + arg1
    if acc < 1 then return end
    acc = 0
    Update()
  end)

  HoryUI.RegisterPanel(f, "weaponpoison", "Poison", "CENTER", 0, -230)
  HoryUI.AddRefresher(Update)
  HoryUI.HideBlizzard(TemporaryEnchantFrame)  -- kill the default top-right poison display
  Update()
end)
