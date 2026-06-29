-- HoryUI :: settings window (rebuilt)
-- A single framed window: header (brand + version) / left category nav
-- (General, Modules, Addons) / content area / footer (author + Reload).
-- Lua 5.0 / WoW 1.12 -- handlers use this/event/arg1.

HoryUI:RegisterModule("config", true, function()
  local C = HoryUI.color
  local getn = table.getn
  local format = string.format
  local W, H = 420, 360

  -- =========================================================================
  -- window
  -- =========================================================================
  local win = CreateFrame("Frame", "HoryUIConfig", UIParent)
  win:SetWidth(W); win:SetHeight(H)
  win:SetFrameStrata("DIALOG")
  win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  win:EnableMouse(true)
  win:SetMovable(true)
  win:SetClampedToScreen(true)
  win:RegisterForDrag("LeftButton")
  win:SetScript("OnDragStart", function() this:StartMoving() end)
  win:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  HoryUI.CreateBackdrop(win)

  -- ---- header -------------------------------------------------------------
  local brand = win:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(brand, HoryUI.font.normal, 15, "OUTLINE")
  brand:SetPoint("TOPLEFT", win, "TOPLEFT", 14, -11)
  brand:SetText("HoryUI")
  brand:SetTextColor(C.accent_hi[1], C.accent_hi[2], C.accent_hi[3])

  local brandSub = win:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(brandSub, HoryUI.font.normal, 11, "OUTLINE")
  brandSub:SetPoint("BOTTOMLEFT", brand, "BOTTOMRIGHT", 6, 0)
  brandSub:SetText("settings")
  brandSub:SetTextColor(C.text3[1], C.text3[2], C.text3[3])

  local ver = (GetAddOnMetadata and GetAddOnMetadata("HoryUI", "Version")) or HoryUI.version
  local hver = win:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(hver, HoryUI.font.number, 10, "OUTLINE")
  hver:SetPoint("TOPRIGHT", win, "TOPRIGHT", -30, -13)
  hver:SetText("v" .. (ver or "?"))
  hver:SetTextColor(C.text3[1], C.text3[2], C.text3[3])

  local close = HoryUI.CreateButton(win, "x", function() win:Hide() end)
  close:SetWidth(18); close:SetHeight(18)
  close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -8, -8)

  local rule = win:CreateTexture(nil, "ARTWORK")
  rule:SetTexture(HoryUI.tex.white)
  rule:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
  rule:SetHeight(1)
  rule:SetPoint("TOPLEFT", win, "TOPLEFT", 12, -32)
  rule:SetPoint("TOPRIGHT", win, "TOPRIGHT", -12, -32)

  -- vertical divider between nav and content
  local vdiv = win:CreateTexture(nil, "ARTWORK")
  vdiv:SetTexture(HoryUI.tex.white)
  vdiv:SetVertexColor(0.16, 0.17, 0.19, 0.9)
  vdiv:SetWidth(1)
  vdiv:SetPoint("TOPLEFT", win, "TOPLEFT", 118, -40)
  vdiv:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 118, 38)

  -- =========================================================================
  -- left nav
  -- =========================================================================
  local ShowTab          -- forward declaration (nav handlers call it)

  local function MakeNav(label, which, y)
    local b = CreateFrame("Button", nil, win)
    b:SetWidth(100); b:SetHeight(24)
    b:SetPoint("TOPLEFT", win, "TOPLEFT", 12, y)

    b.bar = b:CreateTexture(nil, "OVERLAY")
    b.bar:SetTexture(HoryUI.tex.white)
    b.bar:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
    b.bar:SetWidth(2)
    b.bar:SetPoint("TOPLEFT", b, "TOPLEFT", 0, -3)
    b.bar:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 3)
    b.bar:Hide()

    b.text = b:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(b.text, HoryUI.font.normal, 12, "OUTLINE")
    b.text:SetPoint("LEFT", b, "LEFT", 10, 0)
    b.text:SetText(label)
    b.text:SetTextColor(C.text3[1], C.text3[2], C.text3[3])

    b:SetScript("OnClick", function() ShowTab(which) end)
    b:SetScript("OnEnter", function()
      if not this.active then this.text:SetTextColor(C.text2[1], C.text2[2], C.text2[3]) end
    end)
    b:SetScript("OnLeave", function()
      if not this.active then this.text:SetTextColor(C.text3[1], C.text3[2], C.text3[3]) end
    end)
    return b
  end

  local navGeneral = MakeNav("General", "general", -42)
  local navMods    = MakeNav("Modules", "modules", -70)
  local navAddons  = MakeNav("Addons",  "addons",  -98)
  local navPfui    = MakeNav("PfUI",    "pfui",    -126)
  local navLoad    = MakeNav("Load Times", "loadtimes", -154)

  local function HLNav(b, active)
    b.active = active
    if active then
      b.bar:Show()
      b.text:SetTextColor(C.text[1], C.text[2], C.text[3])
    else
      b.bar:Hide()
      b.text:SetTextColor(C.text3[1], C.text3[2], C.text3[3])
    end
  end

  -- =========================================================================
  -- content : General
  -- =========================================================================
  local general = CreateFrame("Frame", nil, win)
  general:SetPoint("TOPLEFT", win, "TOPLEFT", 132, -44)
  general:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -12, 42)

  local function Desc(text, anchorTo, dy, parent)
    local d = (parent or general):CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(d, HoryUI.font.normal, 10, "OUTLINE")
    d:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, dy)
    d:SetText(text)
    d:SetTextColor(C.text3[1], C.text3[2], C.text3[3])
    return d
  end

  local unlock = HoryUI.CreateToggle(general,
    function() return not HoryUI.locked end,
    function(v) HoryUI.SetLocked(not v) end)
  unlock:SetPoint("TOPLEFT", general, "TOPLEFT", 2, -8)

  local unlockLbl = general:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(unlockLbl, HoryUI.font.normal, 12, "OUTLINE")
  unlockLbl:SetPoint("LEFT", unlock, "RIGHT", 8, 0)
  unlockLbl:SetText("Unlock panels")
  unlockLbl:SetTextColor(C.text[1], C.text[2], C.text[3])
  Desc("Reveal the movers, drag panels into place, then toggle off.", unlock, -6)

  local reset = HoryUI.CreateButton(general, "Reset positions",
    function() HoryUIDB.pos = {}; ReloadUI() end)
  reset:SetWidth(130)
  reset:SetPoint("TOPLEFT", general, "TOPLEFT", 2, -56)
  Desc("Send every HoryUI panel back to its default spot (reloads).", reset, -6)

  -- =========================================================================
  -- content : Modules
  -- =========================================================================
  local mods = {
    { id = "unitframes",   name = "Unit Frames" },
    { id = "castbar",      name = "Cast Bars" },
    { id = "auras",        name = "Auras (buffs / debuffs)" },
    { id = "rangetracker", name = "Range Tracker" },
    { id = "party",        name = "Party Frames" },
    { id = "raid",         name = "Raid Frames" },
    { id = "xprep",        name = "XP / Reputation Bar" },
    { id = "weaponpoison", name = "Weapon Poison" },
    { id = "chat",         name = "Chat Tweaks" },
    { id = "minimap",      name = "Minimap" },
    { id = "bags",         name = "Bags (one-bag)" },
    { id = "character",    name = "Character Panel" },
    { id = "outfitter",    name = "Outfitter Integration" },
  }

  local modList = HoryUI.CreateScrollFrame(win, 278, 11, 23)
  modList:SetPoint("TOPLEFT", win, "TOPLEFT", 132, -44)
  modList.OnUpdateRow = function(row, idx)
    local m = mods[idx]
    row.label:SetText(m.name)
    row.SetOn(HoryUI:IsModuleEnabled(m.id, true))
  end
  modList.OnClickRow = function(idx)
    local m = mods[idx]
    HoryUI:SetModuleEnabled(m.id, not HoryUI:IsModuleEnabled(m.id, true))
    modList.Update()
  end

  -- =========================================================================
  -- content : Addons
  -- =========================================================================
  -- 1.12 signature: name, title, notes, enabled, loadable, reason, security
  local function AddonEnabled(i)
    local _, _, _, enabled = GetAddOnInfo(i)
    return enabled and enabled ~= 0
  end

  local addonList = HoryUI.CreateScrollFrame(win, 278, 11, 23)
  addonList:SetPoint("TOPLEFT", win, "TOPLEFT", 132, -44)
  addonList.OnUpdateRow = function(row, idx)
    local name, title = GetAddOnInfo(idx)
    row.label:SetText((title and title ~= "") and title or name)
    row.SetOn(AddonEnabled(idx))
  end
  addonList.OnClickRow = function(idx)
    if AddonEnabled(idx) then DisableAddOn(idx) else EnableAddOn(idx) end
    addonList.Update()
  end

  -- =========================================================================
  -- content : PfUI  (the vendored pfskin engine -- window skins + nameplates)
  -- =========================================================================
  local pfui = CreateFrame("Frame", nil, win)
  pfui:SetPoint("TOPLEFT", win, "TOPLEFT", 132, -44)
  pfui:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -12, 42)

  -- window skins. Toggling reloads so the skins apply/unapply cleanly.
  local skin = HoryUI.CreateToggle(pfui,
    function() return (not HoryUIDB) or HoryUIDB.pfskinEnabled ~= false end,
    function(v)
      if HoryUIDB then HoryUIDB.pfskinEnabled = v and true or false end
      ReloadUI()
    end)
  skin:SetPoint("TOPLEFT", pfui, "TOPLEFT", 2, -8)

  local skinLbl = pfui:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(skinLbl, HoryUI.font.normal, 12, "OUTLINE")
  skinLbl:SetPoint("LEFT", skin, "RIGHT", 8, 0)
  skinLbl:SetText("pfUI window skins")
  skinLbl:SetTextColor(C.text[1], C.text[2], C.text[3])
  Desc("Skin Blizzard windows in the pfUI style (reloads).", skin, -6, pfui)

  -- nameplates (ported pfUI nameplates module: castbars + debuff timers).
  local plates = HoryUI.CreateToggle(pfui,
    function() return (not HoryUIDB) or HoryUIDB.pfnameplatesEnabled ~= false end,
    function(v)
      if HoryUIDB then HoryUIDB.pfnameplatesEnabled = v and true or false end
      ReloadUI()
    end)
  plates:SetPoint("TOPLEFT", pfui, "TOPLEFT", 2, -56)

  local platesLbl = pfui:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(platesLbl, HoryUI.font.normal, 12, "OUTLINE")
  platesLbl:SetPoint("LEFT", plates, "RIGHT", 8, 0)
  platesLbl:SetText("pfUI nameplates")
  platesLbl:SetTextColor(C.text[1], C.text[2], C.text[3])
  Desc("Enemy castbars + debuff timers (reloads).", plates, -6, pfui)

  local pfnote = pfui:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(pfnote, HoryUI.font.normal, 10, "OUTLINE")
  pfnote:SetPoint("BOTTOMLEFT", pfui, "BOTTOMLEFT", 2, 4)
  pfnote:SetText("Both apply only when pfUI itself is not installed.")
  pfnote:SetTextColor(C.text3[1], C.text3[2], C.text3[3])

  -- =========================================================================
  -- content : Load Times  (per-addon startup file-load cost, ms)
  -- =========================================================================
  -- Data comes from the companion addon "!HoryUILoadTimer": it loads first and
  -- records debugprofilestop() at each ADDON_LOADED, so it can time every addon
  -- (HoryUI loads too late to see the ones before it). We only READ its globals --
  -- if it isn't loaded we say so rather than invent numbers.
  local loadtab = CreateFrame("Frame", nil, win)
  loadtab:SetPoint("TOPLEFT", win, "TOPLEFT", 132, -44)
  loadtab:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -12, 42)

  local measure = HoryUI.CreateButton(loadtab, "Reload & Measure", function() ReloadUI() end)
  measure:SetWidth(120)
  measure:SetPoint("TOPLEFT", loadtab, "TOPLEFT", 2, -2)

  local loadSum = loadtab:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(loadSum, HoryUI.font.number, 10, "OUTLINE")
  loadSum:SetPoint("TOPLEFT", loadtab, "TOPLEFT", 2, -28)
  loadSum:SetTextColor(C.text3[1], C.text3[2], C.text3[3])
  loadSum:SetText("")

  local loadMsg = loadtab:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(loadMsg, HoryUI.font.normal, 11, "OUTLINE")
  loadMsg:SetPoint("TOPLEFT", loadtab, "TOPLEFT", 2, -50)
  loadMsg:SetWidth(264); loadMsg:SetJustifyH("LEFT")
  loadMsg:SetTextColor(C.text2[1], C.text2[2], C.text2[3])
  loadMsg:Hide()

  local loadData = {}                                  -- sorted display copy
  local loadList = HoryUI.CreateScrollFrame(loadtab, 276, 9, 23)
  loadList:SetPoint("TOPLEFT", loadtab, "TOPLEFT", 0, -46)
  loadList.OnUpdateRow = function(row, idx)
    if not row.value then                              -- first use: repurpose the row (no toggle)
      row.toggle:Hide()
      row.value = row:CreateFontString(nil, "OVERLAY")
      HoryUI.SetFont(row.value, HoryUI.font.number, 11, "OUTLINE")
      row.value:SetPoint("RIGHT", row, "RIGHT", -2, 0)
      row.label:ClearAllPoints()
      row.label:SetPoint("LEFT", row, "LEFT", 2, 0)
      row.label:SetPoint("RIGHT", row.value, "LEFT", -8, 0)
    end
    local e = loadData[idx]
    if not e then return end
    row.label:SetText(e.name)
    row.value:SetText(format("%.1f", e.ms))
    local c = C.health                                 -- green fast / amber mid / red slow
    if e.ms >= 20 then c = C.health_low
    elseif e.ms >= 5 then c = C.threat end
    row.value:SetTextColor(c[1], c[2], c[3])
  end

  -- read the companion's globals, sort slowest-first, refresh list + summary
  local function RefreshLoad()
    loadData = {}
    local src = HoryUILoadTimes
    local info = HoryUILoadInfo
    if info and info.missing then
      loadMsg:SetText("This client has no high-res timer (debugprofilestop), so per-addon load times can't be measured.")
      loadMsg:Show(); loadSum:SetText(""); loadList.SetTotal(0)
      return
    end
    if not src or getn(src) == 0 then
      loadMsg:SetText("Companion addon \"!HoryUILoadTimer\" isn't loaded. Enable it in the Addons list (it must load first to time every addon), then Reload & Measure.")
      loadMsg:Show(); loadSum:SetText(""); loadList.SetTotal(0)
      return
    end
    loadMsg:Hide()
    local total = 0
    for i = 1, getn(src) do
      loadData[i] = { name = src[i].name, ms = src[i].ms }
      total = total + src[i].ms
    end
    table.sort(loadData, function(a, b) return a.ms > b.ms end)
    local note = ""
    if info and info.reset then note = "  (timer reset mid-load; values approximate)" end
    loadSum:SetText(format("%d addons  -  %.0f ms total, file load only", getn(loadData), total) .. note)
    loadList.SetTotal(getn(loadData))
  end

  -- =========================================================================
  -- footer
  -- =========================================================================
  local fdiv = win:CreateTexture(nil, "ARTWORK")
  fdiv:SetTexture(HoryUI.tex.white)
  fdiv:SetVertexColor(0.16, 0.17, 0.19, 0.9)
  fdiv:SetHeight(1)
  fdiv:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 12, 34)
  fdiv:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -12, 34)

  local auth = (GetAddOnMetadata and GetAddOnMetadata("HoryUI", "Author")) or "Horyoshi"
  local footer = win:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(footer, HoryUI.font.normal, 10, "OUTLINE")
  footer:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 14, 12)
  footer:SetTextColor(C.text3[1], C.text3[2], C.text3[3])
  footer:SetText("HoryUI v" .. (ver or "?") .. "   -   by " .. (auth or "?"))

  local reload = HoryUI.CreateButton(win, "Reload UI", function() ReloadUI() end)
  reload:SetWidth(90)
  reload:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -12, 9)

  -- =========================================================================
  -- tab switching
  -- =========================================================================
  win.tab = "general"
  ShowTab = function(which)
    win.tab = which
    general:Hide(); modList:Hide(); addonList:Hide(); pfui:Hide(); loadtab:Hide()
    HLNav(navGeneral, which == "general")
    HLNav(navMods, which == "modules")
    HLNav(navAddons, which == "addons")
    HLNav(navPfui, which == "pfui")
    HLNav(navLoad, which == "loadtimes")
    if which == "modules" then
      modList:Show(); modList.SetTotal(getn(mods))
    elseif which == "addons" then
      addonList:Show(); addonList.SetTotal(GetNumAddOns())
    elseif which == "pfui" then
      pfui:Show()
    elseif which == "loadtimes" then
      RefreshLoad(); loadtab:Show()
    else
      general:Show()
    end
  end

  win:SetScript("OnShow", function()
    if unlock.Refresh then unlock.Refresh() end
    if skin.Refresh then skin.Refresh() end
    if plates.Refresh then plates.Refresh() end
    ShowTab(this.tab)
  end)

  win:Hide()

  HoryUI.configFrame = win
  function HoryUI.ToggleConfig()
    if win:IsShown() then win:Hide() else win:Show() end
  end
end)
