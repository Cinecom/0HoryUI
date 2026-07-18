-- HoryUI :: party frames (party1-4). No pet frames (rogue UI).

HoryUI:RegisterModule("party", true, function()
  local C = HoryUI.color
  local WIDTH, ROW = 150, 36
  local DMAX, DSIZE = 4, 12          -- debuff icons per frame + their size
  local inCombat = false

  -- status/loot assets, mirroring the raid module (party has no assist rank,
  -- so only the leader star applies per-frame).
  local TEX_LEADER = "Interface\\GroupFrame\\UI-Group-LeaderIcon"
  local TEX_ML     = "Interface\\GroupFrame\\UI-Group-MasterLooter"

  local LOOT_LABELS = {
    freeforall      = "Free For All",
    roundrobin      = "Round Robin",
    master          = "Master Loot",
    group           = "Group Loot",
    needbeforegreed = "Need Before Greed",
  }

  local container = CreateFrame("Frame", "HoryUIParty", UIParent)
  container:SetWidth(WIDTH)
  container:SetHeight(4 * ROW)
  container:SetFrameStrata("MEDIUM")

  -- who controls loot right now: the master looter if one is assigned (2nd
  -- return of GetLootMethod is the PARTY index, 0 = the player), else the
  -- party leader (GetPartyLeaderIndex, 0 = the player).
  local function LootControllerName()
    local method, partyML = GetLootMethod()
    if method == "master" and partyML then
      if partyML == 0 then return UnitName("player") end
      return UnitName("party" .. partyML)
    end
    local li = GetPartyLeaderIndex()
    if li == 0 then return UnitName("player") end
    if li then return UnitName("party" .. li) end
    return nil
  end

  -- loot-header tooltip: loot type, who holds it, and the threshold (read live).
  local function LootOnEnter()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
    local method = GetLootMethod()
    GameTooltip:AddLine(LOOT_LABELS[method] or method or "Loot")
    local who = LootControllerName()
    if who then GameTooltip:AddLine("Looter: " .. who, 1, 1, 1) end
    local th = GetLootThreshold and GetLootThreshold()
    if th then
      local q = getglobal("ITEM_QUALITY" .. th .. "_DESC") or tostring(th)
      local col = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[th]
      if col then
        GameTooltip:AddLine("Threshold: " .. q .. "+", col.r, col.g, col.b)
      else
        GameTooltip:AddLine("Threshold: " .. q .. "+", 1, 1, 1)
      end
    end
    GameTooltip:Show()
  end
  local function LootOnLeave() GameTooltip:Hide() end

  -- always-visible loot header above the party frames: icon + loot-type label
  -- with the hover tooltip -- the raid module's header, shown only while the
  -- party frames themselves are (raid XOR party).
  local lootHeader = CreateFrame("Frame", "HoryUIPartyLoot", container)
  lootHeader:SetHeight(10)
  lootHeader:SetWidth(120)
  lootHeader:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 1, 2)
  lootHeader:EnableMouse(true)
  lootHeader:SetScript("OnEnter", LootOnEnter)
  lootHeader:SetScript("OnLeave", LootOnLeave)
  lootHeader.icon = lootHeader:CreateTexture(nil, "ARTWORK")
  lootHeader.icon:SetWidth(9); lootHeader.icon:SetHeight(9)
  lootHeader.icon:SetPoint("LEFT", lootHeader, "LEFT", 0, 0)
  lootHeader.icon:SetTexture(TEX_ML)
  lootHeader.label = lootHeader:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(lootHeader.label, HoryUI.font.normal, 8, "OUTLINE")
  lootHeader.label:SetPoint("LEFT", lootHeader.icon, "RIGHT", 2, 0)
  lootHeader.label:SetTextColor(C.text[1], C.text[2], C.text[3])

  local function UpdateLoot()
    if not HoryUI.showAll
      and (GetNumPartyMembers() == 0 or GetNumRaidMembers() > 0) then
      lootHeader:Hide()
      return
    end
    lootHeader:Show()
    local method = GetLootMethod()
    lootHeader.label:SetText(LOOT_LABELS[method] or method or "Loot")
  end

  local byunit = {}
  local frames = {}

  local function PowerColor(unit)
    local pt = UnitPowerType(unit)
    if pt == 1 then return C.rage elseif pt == 3 then return C.energy end
    return C.mana
  end

  local function Build(i)
    local f = CreateFrame("Frame", "HoryUIParty" .. i, container)
    f.unit = "party" .. i
    f.pid = i                          -- party index (GetPartyLeaderIndex compares)
    f:SetWidth(WIDTH)
    f:SetHeight(32)
    f:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -(i - 1) * ROW)
    HoryUI.CreateBackdrop(f)

    f.name = f:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(f.name, HoryUI.font.normal, 11, "OUTLINE")
    f.name:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -3)
    f.name:SetTextColor(C.text[1], C.text[2], C.text[3])

    -- leader star before the name (gold, like the raid cells; the name shifts
    -- right while it shows). Party has no assist rank, so leader only.
    f.leadIcon = f:CreateTexture(nil, "OVERLAY")
    f.leadIcon:SetWidth(10); f.leadIcon:SetHeight(10)
    f.leadIcon:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4)
    f.leadIcon:SetTexture(TEX_LEADER)
    f.leadIcon:Hide()

    f.health = HoryUI.CreateStatusBar(f, C.health)
    f.health:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -15)
    f.health:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -15)
    f.health:SetHeight(8)
    HoryUI.CreateBackdrop(f.health)
    -- incoming-heal ghost fill; layout width (4px insets each side), never GetWidth()
    HoryUI.AttachIncHeal(f.health, WIDTH - 8)

    f.power = HoryUI.CreateStatusBar(f, C.mana)
    f.power:SetPoint("TOPLEFT", f.health, "BOTTOMLEFT", 0, -2)
    f.power:SetPoint("TOPRIGHT", f.health, "BOTTOMRIGHT", 0, -2)
    f.power:SetHeight(4)
    HoryUI.CreateBackdrop(f.power)

    -- left-click to target; a cursor item dropped on the frame trades it to
    -- that member (DropItemOnUnit -- the native world-drop path). Mouse only
    -- reaches the frame while locked -- the panel mover overlay sits above
    -- these frames when unlocked.
    f:EnableMouse(true)
    f:SetScript("OnMouseUp", function()
      if arg1 == "LeftButton" then
        if CursorHasItem() then
          DropItemOnUnit(this.unit)
          return
        end
        TargetUnit(this.unit)
      end
    end)

    -- hover border: a border-only overlay (no fill) on a higher strata, so the
    -- garnet edge always draws ABOVE the neighbouring frames. Recolouring the base
    -- backdrop instead would hide the edge behind the next cell (frames overlap by
    -- 1px). Hidden until hovered.
    f.hl = CreateFrame("Frame", nil, f)
    f.hl:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1)
    f.hl:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, -1)
    f.hl:SetFrameStrata("HIGH")
    f.hl:SetBackdrop({ edgeFile = HoryUI.tex.white, edgeSize = 1 })
    f.hl:SetBackdropBorderColor(C.accent_hi[1], C.accent_hi[2], C.accent_hi[3], 1)
    f.hl:Hide()

    -- hover: brighten this frame (out-of-combat fade) + garnet border, matching
    -- the player frame's HookHover.
    f:SetScript("OnEnter", function()
      this.mouse = true
      if this.hl then this.hl:Show() end
    end)
    f:SetScript("OnLeave", function()
      this.mouse = false
      if this.hl then this.hl:Hide() end
    end)

    -- debuff icons: a row just OUTSIDE the frame's right edge, growing outward
    -- (they used to overlay the health/power bars, which hid the bars under a
    -- full debuff row). Each icon is a small MOUSE-ENABLED frame so hovering it
    -- shows the debuff's tooltip (SetUnitDebuff with the index stored at paint
    -- time) and lights the owner frame's highlight; hidden icons don't capture
    -- the mouse. Scanned on a throttle since 1.12 has no UNIT_AURA event;
    -- UnitDebuff(unit, i) -> texture, stacks.
    local dh = CreateFrame("Frame", nil, f)
    dh:SetAllPoints(f)
    dh:SetFrameLevel(f:GetFrameLevel() + 5)
    f.debuffs = {}
    for k = 1, DMAX do
      local d = CreateFrame("Frame", nil, dh)
      d:SetWidth(DSIZE); d:SetHeight(DSIZE)
      d:EnableMouse(true)
      d.owner = f
      d.unit = f.unit
      if k == 1 then
        d:SetPoint("LEFT", f, "RIGHT", 3, 0)
      else
        d:SetPoint("LEFT", f.debuffs[k - 1], "RIGHT", 1, 0)
      end
      d.tex = d:CreateTexture(nil, "ARTWORK")
      d.tex:SetAllPoints(d)
      d.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      d.count = d:CreateFontString(nil, "OVERLAY")
      HoryUI.SetFont(d.count, HoryUI.font.number, 8, "OUTLINE")
      d.count:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", 0, 0)
      d.count:SetTextColor(C.text[1], C.text[2], C.text[3])
      d:SetScript("OnEnter", function()
        if this.owner then
          this.owner.mouse = true
          if this.owner.hl then this.owner.hl:Show() end
        end
        if this.index then
          GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
          GameTooltip:SetUnitDebuff(this.unit, this.index)
          GameTooltip:Show()
        end
      end)
      d:SetScript("OnLeave", function()
        if this.owner then
          this.owner.mouse = false
          if this.owner.hl then this.owner.hl:Hide() end
        end
        GameTooltip:Hide()
      end)
      d:Hide()
      f.debuffs[k] = d
    end

    return f
  end

  local function UpdateDebuffs(f)
    if not f.debuffs then return end
    local di = 0
    if UnitExists(f.unit) and not HoryUI.showAll then
      local i = 1
      while di < DMAX do
        local tex, stacks = UnitDebuff(f.unit, i)
        if not tex then break end          -- debuffs are contiguous from 1
        di = di + 1
        local d = f.debuffs[di]
        d.tex:SetTexture(tex)
        d.index = i                        -- hover: SetUnitDebuff(unit, index)
        d:Show()
        if stacks and stacks > 1 then d.count:SetText(stacks); d.count:Show()
        else d.count:Hide() end
        i = i + 1
      end
    end
    for k = di + 1, DMAX do
      f.debuffs[k]:Hide(); f.debuffs[k].index = nil
    end
  end

  local function UpdateOne(f)
    local unit = f.unit
    -- raid XOR party: while in a raid the raid frames take over, so hide party
    -- entirely. Still show placeholders while unlocked so the panel stays
    -- positionable (matches the "reveal panels on unlock" rule).
    if GetNumRaidMembers() > 0 and not HoryUI.showAll then
      f:Hide()
      return
    end
    if not UnitExists(unit) then
      if HoryUI.showAll then
        f:Show()
        f.leadIcon:Hide()
        f.name:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -3)
        f.name:SetText(unit)
        f.health:SetMinMaxValues(0, 1); f.health:SetValue(1)
        f.health:SetStatusBarColor(C.health[1], C.health[2], C.health[3], 1)
        f.power:SetMinMaxValues(0, 1); f.power:SetValue(1)
      else
        f:Hide()
      end
      return
    end
    f:Show()

    local hp, max = HoryUI.UnitHP(unit)
    if max <= 0 then max = 1 end
    f.health:SetMinMaxValues(0, max)
    f.health:SetValue(hp)
    local pct = math.floor(hp / max * 100 + 0.5)
    local hc = C.health
    if pct <= 25 then hc = C.health_low end
    f.health:SetStatusBarColor(hc[1], hc[2], hc[3], 1)

    -- leader star before the name; re-SetPoint of the same point replaces it
    -- (the raid module's name anchor does the same).
    if GetPartyLeaderIndex() == f.pid then
      f.leadIcon:Show()
      f.name:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -3)
    else
      f.leadIcon:Hide()
      f.name:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -3)
    end

    f.name:SetText(UnitName(unit) or "")
    local nr, ng, nb = HoryUI.ClassColor(unit)
    f.name:SetTextColor(nr, ng, nb)

    local pc = PowerColor(unit)
    f.power:SetStatusBarColor(pc[1], pc[2], pc[3], 1)
    local pmax = UnitManaMax(unit)
    if pmax <= 0 then pmax = 1 end
    f.power:SetMinMaxValues(0, pmax)
    f.power:SetValue(UnitMana(unit))

    if f.health.UpdateIncHeal then f.health.UpdateIncHeal(unit) end
  end

  local function UpdateAll()
    for i = 1, 4 do UpdateOne(frames[i]) end
    UpdateLoot()
  end

  for i = 1, 4 do
    frames[i] = Build(i)
    byunit["party" .. i] = frames[i]
  end

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("PARTY_MEMBERS_CHANGED")
  ev:RegisterEvent("RAID_ROSTER_UPDATE")     -- party<->raid conversion hides/shows party
  ev:RegisterEvent("PARTY_LEADER_CHANGED")       -- leader star
  ev:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")  -- loot header
  ev:RegisterEvent("UNIT_HEALTH")
  ev:RegisterEvent("UNIT_MAXHEALTH")
  ev:RegisterEvent("UNIT_MANA")
  ev:RegisterEvent("UNIT_ENERGY")
  ev:RegisterEvent("UNIT_RAGE")
  ev:RegisterEvent("PLAYER_REGEN_DISABLED")     -- out-of-combat fade
  ev:RegisterEvent("PLAYER_REGEN_ENABLED")
  ev:RegisterEvent("PLAYER_LOGOUT")
  ev:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      this:SetScript("OnUpdate", nil)
      return
    end
    if event == "PLAYER_REGEN_DISABLED" then inCombat = true; return end
    if event == "PLAYER_REGEN_ENABLED" then inCombat = false; return end
    if event == "PLAYER_ENTERING_WORLD" then
      inCombat = UnitAffectingCombat("player") and true or false
    end
    if arg1 and byunit[arg1] then
      UpdateOne(byunit[arg1])
      return
    end
    UpdateAll()
  end)

  -- out-of-combat fade (per design sec.8.5) + debuff poll. The fade lerp runs
  -- every tick (smooth); the debuff scan stays throttled (no UNIT_AURA in 1.12).
  local dacc = 0
  ev:SetScript("OnUpdate", function()
    for i = 1, 4 do
      local f = frames[i]
      if f:IsShown() then
        local want = 0.6
        if HoryUI.showAll or inCombat or f.mouse then want = 1.0 end
        local a = f:GetAlpha()
        if a < want then
          a = a + arg1 / 0.18; if a > want then a = want end; f:SetAlpha(a)
        elseif a > want then
          a = a - arg1 / 0.18; if a < want then a = want end; f:SetAlpha(a)
        end
      end
    end

    dacc = dacc + arg1
    if dacc < 0.3 then return end
    dacc = 0
    for i = 1, 4 do
      local f = frames[i]
      UpdateDebuffs(f)
      -- incoming heals appear/expire without a unit event -- same throttled tick
      if f:IsShown() and f.health.UpdateIncHeal then f.health.UpdateIncHeal(f.unit) end
    end
  end)

  HoryUI.RegisterPanel(container, "party", "Party", "LEFT", 20, 100)
  HoryUI.AddRefresher(UpdateAll)
  UpdateAll()

  for i = 1, 4 do HoryUI.HideBlizzard(getglobal("PartyMemberFrame" .. i)) end
end)
