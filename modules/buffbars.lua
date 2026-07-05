-- HoryUI :: buff bars -- castbar-style COUNTDOWN bars for a user-chosen set of
-- buffs, so their remaining duration reads at a glance (Slice and Dice, poisons'
-- sharpening stones, potions, ...). The tracked names live in
-- HoryUIDB.buffbars (edited in Settings -> Buff Bars); every tracked buff that
-- is currently on the player gets one gold bar (icon + name + seconds) that
-- drains to empty, stacked in one draggable container (RegisterPanel).
--
-- Buff identification: 1.12 has NO API for a player buff's NAME, so each scan
-- reads it from a hidden WorldFrame-owned tooltip (SetPlayerBuff -> line 1) --
-- the durability/autodismount technique. The scan is EVENT-driven
-- (PLAYER_AURAS_CHANGED fires on every player aura change), not polled; between
-- scans the bars count down on their own from the scanned
-- GetPlayerBuffTimeLeft. A bar's MAX (the full duration) is learned when the
-- buff appears or is refreshed (timeleft jumping UP = a fresh application, and
-- that fresh timeleft IS the full duration); a buff already ticking at login
-- uses its first-seen timeleft as max until the next refresh.
--
-- Lua 5.0 / WoW 1.12 -- handlers use this/event/arg1; see CLAUDE.md.

HoryUI:RegisterModule("buffbars", true, function()
  local C = HoryUI.color
  local getn, floor, ceil = table.getn, math.floor, math.ceil
  local GetTime = GetTime
  local BARW, BARH, ICON, GAP = 180, 16, 16, 4
  local MAXBARS = 8

  HoryUIDB.buffbars = HoryUIDB.buffbars or {}

  -- hidden tooltip: the only way to read a player buff's NAME in 1.12
  local scan = CreateFrame("GameTooltip", "HoryUIBuffBarScan", WorldFrame, "GameTooltipTemplate")
  scan:SetOwner(WorldFrame, "ANCHOR_NONE")
  local function BuffName(bid)
    scan:SetOwner(WorldFrame, "ANCHOR_NONE")   -- re-own: SetOwner clears lines
    scan:SetPlayerBuff(bid)
    local fs = HoryUIBuffBarScanTextLeft1
    return fs and fs:GetText()
  end

  ----------------------------------------------------------------------------
  -- container + bar pool
  ----------------------------------------------------------------------------
  local box = CreateFrame("Frame", "HoryUIBuffBars", UIParent)
  box:SetWidth(BARW)
  box:SetHeight(BARH)
  box:SetFrameStrata("MEDIUM")

  local bars = {}
  local function MakeBar(i)
    local b = CreateFrame("Frame", nil, box)
    b:SetWidth(BARW); b:SetHeight(BARH)
    HoryUI.CreateBackdrop(b)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetWidth(ICON - 2); b.icon:SetHeight(BARH - 2)
    b.icon:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    b.bar = HoryUI.CreateStatusBar(b, C.cast)
    b.bar:SetPoint("TOPLEFT", b, "TOPLEFT", ICON, -1)
    b.bar:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)

    b.label = b.bar:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(b.label, HoryUI.font.normal, 10, "OUTLINE")
    b.label:SetPoint("LEFT", b.bar, "LEFT", 3, 0)
    b.label:SetJustifyH("LEFT")
    b.label:SetTextColor(C.text[1], C.text[2], C.text[3])

    b.time = b.bar:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(b.time, HoryUI.font.number, 10, "OUTLINE")
    b.time:SetPoint("RIGHT", b.bar, "RIGHT", -3, 0)
    b.time:SetTextColor(C.text[1], C.text[2], C.text[3])
    b.label:SetPoint("RIGHT", b.time, "LEFT", -4, 0)

    b:Hide()
    bars[i] = b
    return b
  end

  -- compact the live bars top-down; size + show/hide the container
  local function Relayout()
    local n = 0
    for i = 1, MAXBARS do
      local b = bars[i]
      if b and b:IsShown() then
        n = n + 1
        b:ClearAllPoints()
        b:SetPoint("TOP", box, "TOP", 0, -((n - 1) * (BARH + GAP)))
      end
    end
    box:SetHeight(n > 0 and (n * (BARH + GAP) - GAP) or BARH)
    if n > 0 or HoryUI.showAll then box:Show() else box:Hide() end
  end

  local function TimeText(rem)
    if rem >= 60 then return floor(rem / 60 + 0.5) .. "m" end
    return tostring(ceil(rem))            -- ceil: the last displayed second is 1
  end

  ----------------------------------------------------------------------------
  -- scan: match the player's buffs against the tracked names
  ----------------------------------------------------------------------------
  local function Scan()
    if HoryUI.showAll then return end     -- preview owns the bars while unlocked
    local list = HoryUIDB.buffbars
    local want = {}                       -- name -> tracked-list order (bar slot)
    for i = 1, getn(list) do want[list[i]] = i end

    -- collect the live tracked buffs: name -> { timeleft, texture }
    local found = {}
    for i = 0, 31 do
      local bid = GetPlayerBuff(i, "HELPFUL")
      if not bid or bid < 0 then break end
      local name = BuffName(bid)
      if name and want[name] then
        local left = GetPlayerBuffTimeLeft(bid) or 0
        -- same buff twice (rare): keep the longer one
        if left > 0 and (not found[name] or left > found[name].left) then
          found[name] = { left = left, tex = GetPlayerBuffTexture(bid) }
        end
      end
    end

    -- one bar per tracked name, in tracked-list order
    local slot = 0
    for i = 1, getn(list) do
      local name = list[i]
      local hit = found[name]
      if hit and slot < MAXBARS then
        slot = slot + 1
        local b = bars[slot] or MakeBar(slot)
        local now = GetTime()
        local expires = now + hit.left
        -- a fresh application (new bar, or timeleft jumped up) defines the max
        if b.name ~= name or not b.expires or expires > b.expires + 1 then
          b.duration = hit.left
        end
        b.name = name
        b.expires = expires
        b.icon:SetTexture(hit.tex)
        b.label:SetText(name)
        b.bar:SetMinMaxValues(0, b.duration or hit.left)
        b:Show()
      end
    end
    for i = slot + 1, MAXBARS do
      if bars[i] then bars[i]:Hide(); bars[i].name = nil end
    end
    Relayout()
  end
  HoryUI.BuffBarsRescan = Scan            -- the settings tab calls this on add/remove

  ----------------------------------------------------------------------------
  -- driver: event-driven scan, per-frame drain (throttled paint)
  ----------------------------------------------------------------------------
  local drv = CreateFrame("Frame")
  drv.acc = 0
  drv:RegisterEvent("PLAYER_AURAS_CHANGED")
  drv:RegisterEvent("PLAYER_ENTERING_WORLD")
  drv:RegisterEvent("PLAYER_LOGOUT")
  drv:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      this:SetScript("OnUpdate", nil)
      return
    end
    Scan()
  end)

  drv:SetScript("OnUpdate", function()
    this.acc = this.acc + arg1
    if this.acc < 0.05 then return end
    this.acc = 0
    if HoryUI.showAll then return end
    local now = GetTime()
    local died = false
    for i = 1, MAXBARS do
      local b = bars[i]
      if b and b:IsShown() and b.expires then
        local rem = b.expires - now
        if rem <= 0 then
          b:Hide(); b.name = nil
          died = true
        else
          b.bar:SetValue(rem)
          b.time:SetText(TimeText(rem))
        end
      end
    end
    if died then Relayout() end
  end)

  ----------------------------------------------------------------------------
  -- unlocked preview (position it with nothing tracked/active)
  ----------------------------------------------------------------------------
  HoryUI.AddRefresher(function()
    if HoryUI.showAll then
      for i = 1, 2 do
        local b = bars[i] or MakeBar(i)
        b.name = nil; b.expires = nil
        b.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        b.label:SetText("Buff bar " .. i)
        b.time:SetText(i == 1 and "12" or "3m")
        b.bar:SetMinMaxValues(0, 1); b.bar:SetValue(i == 1 and 0.7 or 0.35)
        b:Show()
      end
      for i = 3, MAXBARS do if bars[i] then bars[i]:Hide(); bars[i].name = nil end end
      Relayout()
    else
      Scan()
    end
  end)

  HoryUI.RegisterPanel(box, "buffbars", "Buff Bars", "CENTER", -200, -60)
  Scan()
end)
