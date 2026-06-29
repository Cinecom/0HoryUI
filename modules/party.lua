-- HoryUI :: party frames (party1-4). No pet frames (rogue UI).

HoryUI:RegisterModule("party", true, function()
  local C = HoryUI.color
  local WIDTH, ROW = 150, 36

  local container = CreateFrame("Frame", "HoryUIParty", UIParent)
  container:SetWidth(WIDTH)
  container:SetHeight(4 * ROW)
  container:SetFrameStrata("MEDIUM")

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
    f:SetWidth(WIDTH)
    f:SetHeight(32)
    f:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -(i - 1) * ROW)
    HoryUI.CreateBackdrop(f)

    f.name = f:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(f.name, HoryUI.font.normal, 11, "OUTLINE")
    f.name:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -3)
    f.name:SetTextColor(C.text[1], C.text[2], C.text[3])

    f.health = HoryUI.CreateStatusBar(f, C.health)
    f.health:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -15)
    f.health:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -15)
    f.health:SetHeight(8)
    HoryUI.CreateBackdrop(f.health)

    f.power = HoryUI.CreateStatusBar(f, C.mana)
    f.power:SetPoint("TOPLEFT", f.health, "BOTTOMLEFT", 0, -2)
    f.power:SetPoint("TOPRIGHT", f.health, "BOTTOMRIGHT", 0, -2)
    f.power:SetHeight(4)
    HoryUI.CreateBackdrop(f.power)

    return f
  end

  local function UpdateOne(f)
    local unit = f.unit
    if not UnitExists(unit) then
      if HoryUI.showAll then
        f:Show()
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

    f.name:SetText(UnitName(unit) or "")
    local nr, ng, nb = HoryUI.ClassColor(unit)
    f.name:SetTextColor(nr, ng, nb)

    local pc = PowerColor(unit)
    f.power:SetStatusBarColor(pc[1], pc[2], pc[3], 1)
    local pmax = UnitManaMax(unit)
    if pmax <= 0 then pmax = 1 end
    f.power:SetMinMaxValues(0, pmax)
    f.power:SetValue(UnitMana(unit))
  end

  local function UpdateAll()
    for i = 1, 4 do UpdateOne(frames[i]) end
  end

  for i = 1, 4 do
    frames[i] = Build(i)
    byunit["party" .. i] = frames[i]
  end

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("PARTY_MEMBERS_CHANGED")
  ev:RegisterEvent("UNIT_HEALTH")
  ev:RegisterEvent("UNIT_MAXHEALTH")
  ev:RegisterEvent("UNIT_MANA")
  ev:RegisterEvent("UNIT_ENERGY")
  ev:RegisterEvent("UNIT_RAGE")
  ev:RegisterEvent("PLAYER_LOGOUT")
  ev:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      return
    end
    if arg1 and byunit[arg1] then
      UpdateOne(byunit[arg1])
      return
    end
    UpdateAll()
  end)

  HoryUI.RegisterPanel(container, "party", "Party", "LEFT", 20, 100)
  HoryUI.AddRefresher(UpdateAll)
  UpdateAll()

  for i = 1, 4 do HoryUI.HideBlizzard(getglobal("PartyMemberFrame" .. i)) end
end)
