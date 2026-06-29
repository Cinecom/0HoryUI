-- HoryUI :: compact raid frames (raid1-40).
-- 8 groups in 4 columns x 2 rows. Class-colored health, power bar, player name.

HoryUI:RegisterModule("raid", true, function()
  local C = HoryUI.color
  local CW, CH, GAP = 66, 20, 1
  local COLS = 4
  local HEADERH = 12
  local GX, GY = 6, 8

  local blockW = CW
  local blockH = HEADERH + 5 * (CH + GAP)

  local container = CreateFrame("Frame", "HoryUIRaid", UIParent)
  container:SetWidth(COLS * (blockW + GX) - GX)
  container:SetHeight(2 * (blockH + GY) - GY)
  container:SetFrameStrata("MEDIUM")

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

      f.name = f:CreateFontString(nil, "OVERLAY")
      HoryUI.SetFont(f.name, HoryUI.font.normal, 9, "OUTLINE")
      f.name:SetPoint("LEFT", f.health, "LEFT", 2, 0)
      f.name:SetPoint("RIGHT", f.health, "RIGHT", -2, 0)
      f.name:SetJustifyH("LEFT")
      f.name:SetTextColor(1, 1, 1, 1)

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

    f.name:SetText(string.sub(UnitName(unit) or "", 1, 7))
  end

  local function UpdateHeaders()
    for g = 1, 8 do
      local any = HoryUI.showAll
      if not any then
        for m = 1, 5 do
          if UnitExists("raid" .. ((g - 1) * 5 + m)) then any = true end
        end
      end
      if any then headers[g]:Show() else headers[g]:Hide() end
    end
  end

  local function UpdateAll()
    for i = 1, 40 do UpdateOne(frames[i]) end
    UpdateHeaders()
  end

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("RAID_ROSTER_UPDATE")
  ev:RegisterEvent("UNIT_HEALTH")
  ev:RegisterEvent("UNIT_MAXHEALTH")
  ev:RegisterEvent("UNIT_MANA")
  ev:RegisterEvent("UNIT_RAGE")
  ev:RegisterEvent("UNIT_ENERGY")
  ev:RegisterEvent("PLAYER_LOGOUT")
  ev:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      return
    end
    if arg1 and byunit[arg1]
      and (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH"
        or event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY") then
      UpdateOne(byunit[arg1])
      return
    end
    UpdateAll()
  end)

  HoryUI.RegisterPanel(container, "raid", "Raid", "LEFT", 20, -100)
  HoryUI.AddRefresher(UpdateAll)
  UpdateAll()
end)
