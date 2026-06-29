-- HoryUI :: compact raid frames (raid1-40).
-- 8 groups in 4 columns x 2 rows. Class-colored health, power bar, player name.

HoryUI:RegisterModule("raid", true, function()
  local C = HoryUI.color
  local CW, CH, GAP = 96, 20, 1       -- wider cells so longer names fit
  local NAMEMAX = 12                  -- vanilla names cap at 12 chars
  local RDMAX, RDSIZE = 3, 10         -- debuff icons per frame + their size
  local COLS = 4
  local HEADERH = 12
  local GX, GY = 6, 8
  local inCombat = false

  local blockW = CW
  local blockH = HEADERH + 5 * (CH + GAP)

  -- status icon textures: leader uses the stock star; assist reuses it tinted
  -- silver (mirrors Blizzard's gold-star-leader / silver-star-assist) so we
  -- never depend on an assistant texture that may not ship on this client.
  local TEX_LEADER = "Interface\\GroupFrame\\UI-Group-LeaderIcon"
  local TEX_ML     = "Interface\\GroupFrame\\UI-Group-MasterLooter"

  local LOOT_LABELS = {
    freeforall      = "Free For All",
    roundrobin      = "Round Robin",
    master          = "Master Loot",
    group           = "Group Loot",
    needbeforegreed = "Need Before Greed",
  }

  -- who controls loot right now: the master looter if one is assigned, else the
  -- raid leader (who owns the loot rules under group/round-robin/etc.).
  local function LootControllerName()
    local method, _, raidML = GetLootMethod()
    if method == "master" and raidML and raidML > 0 then
      return UnitName("raid" .. raidML)
    end
    for i = 1, GetNumRaidMembers() do
      local nm, rank = GetRaidRosterInfo(i)
      if rank == 2 then return nm end
    end
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

  local container = CreateFrame("Frame", "HoryUIRaid", UIParent)
  container:SetWidth(COLS * (blockW + GX) - GX)
  container:SetHeight(2 * (blockH + GY) - GY)
  container:SetFrameStrata("MEDIUM")

  -- always-visible loot header above the raid frames: icon + loot-type label,
  -- with a hover tooltip (looter + threshold). Sits above the container's top.
  local lootHeader = CreateFrame("Frame", "HoryUIRaidLoot", container)
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
    if not HoryUI.showAll and GetNumRaidMembers() == 0 then
      lootHeader:Hide()
      return
    end
    lootHeader:Show()
    local method = GetLootMethod()
    lootHeader.label:SetText(LOOT_LABELS[method] or method or "Loot")
  end

  local frames = {}
  local byunit = {}
  local headers = {}

  for g = 1, 8 do
    local gcol = math.mod(g - 1, COLS)
    local grow = math.floor((g - 1) / COLS)
    local bx = gcol * (blockW + GX)
    local by = -(grow * (blockH + GY))

    local header = container:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(header, HoryUI.font.normal, 10, "OUTLINE")
    header:SetPoint("TOPLEFT", container, "TOPLEFT", bx + 1, by)
    header:SetTextColor(C.text2[1], C.text2[2], C.text2[3])
    header:SetText("Group " .. g)
    headers[g] = header

    for m = 1, 5 do
      local i = (g - 1) * 5 + m
      local f = CreateFrame("Frame", "HoryUIRaid" .. i, container)
      f.unit = "raid" .. i
      f.rid = i                     -- raid roster index == raid unit number
      f:SetWidth(CW)
      f:SetHeight(CH)
      f:SetPoint("TOPLEFT", container, "TOPLEFT", bx, by - HEADERH - (m - 1) * (CH + GAP))
      HoryUI.CreateBackdrop(f)

      f.health = HoryUI.CreateStatusBar(f, C.health)
      f.health:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
      f.health:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
      f.health:SetHeight(13)

      f.power = HoryUI.CreateStatusBar(f, C.mana)
      f.power:SetPoint("TOPLEFT", f.health, "BOTTOMLEFT", 0, -1)
      f.power:SetPoint("TOPRIGHT", f.health, "BOTTOMRIGHT", 0, -1)
      f.power:SetHeight(3)

      -- name lives ON the health bar (its OVERLAY layer) -- a fontstring on `f`
      -- would be drawn behind the health bar child frame and hidden by the fill.
      f.name = f.health:CreateFontString(nil, "OVERLAY")
      HoryUI.SetFont(f.name, HoryUI.font.normal, 9, "OUTLINE")
      f.name:SetPoint("LEFT", f.health, "LEFT", 2, 0)
      f.name:SetPoint("RIGHT", f.health, "RIGHT", -2, 0)
      f.name:SetJustifyH("LEFT")
      f.name:SetTextColor(1, 1, 1, 1)

      -- left-click to target (mouse only reaches the frame while locked)
      f:EnableMouse(true)
      f:SetScript("OnMouseUp", function()
        if arg1 == "LeftButton" then TargetUnit(this.unit) end
      end)

      -- hover border: a border-only overlay (no fill) on a higher strata, so the
      -- garnet edge always draws ABOVE the neighbouring cells. Recolouring the base
      -- backdrop instead would hide the edge behind the next cell (frames overlap
      -- by 1px). Hidden until hovered.
      f.hl = CreateFrame("Frame", nil, f)
      f.hl:SetPoint("TOPLEFT", f, "TOPLEFT", -1, 1)
      f.hl:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 1, -1)
      f.hl:SetFrameStrata("HIGH")
      f.hl:SetBackdrop({ edgeFile = HoryUI.tex.white, edgeSize = 1 })
      f.hl:SetBackdropBorderColor(C.accent_hi[1], C.accent_hi[2], C.accent_hi[3], 1)
      f.hl:Hide()

      -- hover: brighten this cell (out-of-combat fade) + garnet border, matching
      -- the player frame's HookHover.
      f:SetScript("OnEnter", function()
        this.mouse = true
        if this.hl then this.hl:Show() end
      end)
      f:SetScript("OnLeave", function()
        this.mouse = false
        if this.hl then this.hl:Hide() end
      end)

      -- debuff icons (overlay row, right -> left), polled (no UNIT_AURA in 1.12)
      local dh = CreateFrame("Frame", nil, f)
      dh:SetAllPoints(f)
      dh:SetFrameLevel(f:GetFrameLevel() + 5)
      f.debuffs = {}
      for k = 1, RDMAX do
        local d = {}
        d.tex = dh:CreateTexture(nil, "ARTWORK")
        d.tex:SetWidth(RDSIZE); d.tex:SetHeight(RDSIZE)
        d.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        if k == 1 then
          d.tex:SetPoint("RIGHT", f, "RIGHT", -1, 0)
        else
          d.tex:SetPoint("RIGHT", f.debuffs[k - 1].tex, "LEFT", -1, 0)
        end
        d.count = dh:CreateFontString(nil, "OVERLAY")
        HoryUI.SetFont(d.count, HoryUI.font.number, 7, "OUTLINE")
        d.count:SetPoint("BOTTOMRIGHT", d.tex, "BOTTOMRIGHT", 0, 0)
        d.count:SetTextColor(C.text[1], C.text[2], C.text[3])
        d.tex:Hide()
        f.debuffs[k] = d
      end

      -- rank icon (leader gold star / assist silver star), top-left of the frame
      local sh = CreateFrame("Frame", nil, f)
      sh:SetAllPoints(f)
      sh:SetFrameLevel(f:GetFrameLevel() + 6)

      f.rankIcon = sh:CreateTexture(nil, "ARTWORK")
      f.rankIcon:SetWidth(9); f.rankIcon:SetHeight(9)
      f.rankIcon:SetTexture(TEX_LEADER)
      f.rankIcon:Hide()

      f:Hide()
      frames[i] = f
      byunit["raid" .. i] = f
    end
  end

  local function UpdateOne(f)
    local unit = f.unit
    if not UnitExists(unit) then
      if HoryUI.showAll then
        f:Show()
        f.health:SetMinMaxValues(0, 1); f.health:SetValue(1)
        f.health:SetStatusBarColor(C.health[1], C.health[2], C.health[3], 1)
        f.power:SetMinMaxValues(0, 1); f.power:SetValue(1)
        f.power:SetStatusBarColor(C.mana[1], C.mana[2], C.mana[3], 1)
        f.rankIcon:Hide()
        f.name:SetPoint("LEFT", f.health, "LEFT", 2, 0)
        f.name:SetText("Player")
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
    local cr, cg, cb = HoryUI.ClassColor(unit)
    f.health:SetStatusBarColor(cr, cg, cb, 1)

    local pc = HoryUI.PowerColor(unit)
    f.power:SetStatusBarColor(pc[1], pc[2], pc[3], 1)
    local pmax = UnitManaMax(unit)
    if pmax <= 0 then pmax = 1 end
    f.power:SetMinMaxValues(0, pmax)
    f.power:SetValue(UnitMana(unit))

    -- status icons: leader (gold star) / assist (silver star) + master looter,
    -- packed from the top-left; the name starts just after them.
    local _, rank = GetRaidRosterInfo(f.rid)
    rank = rank or 0
    local ix = 1
    if rank >= 1 then
      f.rankIcon:ClearAllPoints()
      f.rankIcon:SetPoint("TOPLEFT", f.health, "TOPLEFT", ix, -1)
      if rank == 2 then
        f.rankIcon:SetVertexColor(1, 1, 1, 1)            -- leader: gold star as-is
      else
        f.rankIcon:SetVertexColor(0.72, 0.73, 0.78, 1)   -- assist: silver tint
      end
      f.rankIcon:Show()
      ix = ix + 10
    else
      f.rankIcon:Hide()
    end

    f.name:SetPoint("LEFT", f.health, "LEFT", ix + 1, 0)
    f.name:SetText(string.sub(UnitName(unit) or "", 1, NAMEMAX))
  end

  local function UpdateDebuffs(f)
    if not f.debuffs then return end
    local di = 0
    if UnitExists(f.unit) and not HoryUI.showAll then
      local i = 1
      while di < RDMAX do
        local tex, stacks = UnitDebuff(f.unit, i)
        if not tex then break end          -- debuffs are contiguous from 1
        di = di + 1
        local d = f.debuffs[di]
        d.tex:SetTexture(tex); d.tex:Show()
        if stacks and stacks > 1 then d.count:SetText(stacks); d.count:Show()
        else d.count:Hide() end
        i = i + 1
      end
    end
    for k = di + 1, RDMAX do
      f.debuffs[k].tex:Hide(); f.debuffs[k].count:Hide()
    end
  end

  -- Lay frames out by SUBGROUP (GetRaidRosterInfo's 3rd return), NOT by raid
  -- index -- a player's raid index doesn't change when they're moved to another
  -- group, only their subgroup does, so an index-based grid never reflects the
  -- move. Members pack top-down within their group block.
  local groupCount = {}

  local function PlaceFrame(f, g, row)
    local gcol = math.mod(g - 1, COLS)
    local grow = math.floor((g - 1) / COLS)
    local bx = gcol * (blockW + GX)
    local by = -(grow * (blockH + GY))
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", container, "TOPLEFT", bx, by - HEADERH - row * (CH + GAP))
  end

  local function Layout()
    for g = 1, 8 do groupCount[g] = 0 end
    if HoryUI.showAll then
      -- preview: full grid by index, every header shown
      for i = 1, 40 do
        PlaceFrame(frames[i], math.floor((i - 1) / 5) + 1, math.mod(i - 1, 5))
      end
      for g = 1, 8 do groupCount[g] = 5 end
      return
    end
    for i = 1, 40 do
      if UnitExists("raid" .. i) then
        local _, _, subgroup = GetRaidRosterInfo(i)
        subgroup = subgroup or 1
        if subgroup < 1 then subgroup = 1 elseif subgroup > 8 then subgroup = 8 end
        PlaceFrame(frames[i], subgroup, groupCount[subgroup])
        groupCount[subgroup] = groupCount[subgroup] + 1
      end
    end
  end

  local function UpdateHeaders()
    for g = 1, 8 do
      if groupCount[g] and groupCount[g] > 0 then headers[g]:Show() else headers[g]:Hide() end
    end
  end

  local function UpdateAll()
    Layout()                              -- reposition by subgroup (handles moves)
    for i = 1, 40 do UpdateOne(frames[i]) end
    UpdateHeaders()
    UpdateLoot()
  end

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("RAID_ROSTER_UPDATE")
  ev:RegisterEvent("PARTY_LEADER_CHANGED")       -- leader/assist icons
  ev:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")  -- master-looter icon
  ev:RegisterEvent("UNIT_HEALTH")
  ev:RegisterEvent("UNIT_MAXHEALTH")
  ev:RegisterEvent("UNIT_MANA")
  ev:RegisterEvent("UNIT_RAGE")
  ev:RegisterEvent("UNIT_ENERGY")
  ev:RegisterEvent("PLAYER_REGEN_DISABLED")      -- out-of-combat fade
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
    if arg1 and byunit[arg1]
      and (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH"
        or event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY") then
      UpdateOne(byunit[arg1])
      return
    end
    UpdateAll()
  end)

  -- out-of-combat fade (per design sec.8.5) + debuff poll. The fade lerp runs
  -- every tick (smooth) but only touches shown cells; the debuff scan stays
  -- throttled (no UNIT_AURA in 1.12, and UpdateDebuffs early-outs on UnitExists).
  local dacc = 0
  ev:SetScript("OnUpdate", function()
    for i = 1, 40 do
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
    for i = 1, 40 do UpdateDebuffs(frames[i]) end
  end)

  HoryUI.RegisterPanel(container, "raid", "Raid", "LEFT", 20, -100)
  HoryUI.AddRefresher(UpdateAll)
  UpdateAll()
end)
