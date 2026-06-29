-- HoryUI :: XP / reputation line across the top of the minimap.
-- Right-click for a dropdown to choose Experience or a watched reputation.
-- Loads after the minimap module so it anchors to the squared frame.

HoryUI:RegisterModule("xprep", true, function()
  local C = HoryUI.color
  if not Minimap then return end

  local line = CreateFrame("Frame", "HoryUIXPBar", Minimap)
  line:SetPoint("BOTTOMLEFT", Minimap, "TOPLEFT", 0, 1)
  line:SetPoint("BOTTOMRIGHT", Minimap, "TOPRIGHT", 0, 1)
  line:SetHeight(14)
  line:SetFrameStrata("MEDIUM")
  HoryUI.CreateBackdrop(line)
  line:EnableMouse(true)

  local fill = HoryUI.CreateStatusBar(line, C.accent)
  fill:SetPoint("TOPLEFT", line, "TOPLEFT", 1, -1)
  fill:SetPoint("BOTTOMRIGHT", line, "BOTTOMRIGHT", -1, 1)
  fill:SetMinMaxValues(0, 1)
  fill:SetValue(0)

  local rested = fill:CreateTexture(nil, "ARTWORK")
  rested:SetTexture(HoryUI.tex.white)
  -- Rested = solid gold (energy token), the same gold the tooltip uses for
  -- "Rested" and clearly distinct from the red XP fill. Drawn opaque (not a
  -- faint tint) so it reads at a glance over the minimap. The bar caps at one
  -- level, so when rested exceeds the XP left this level the whole remaining
  -- bar is gold = "fully rested".
  local en = C.energy
  rested:SetVertexColor(en[1], en[2], en[3], 1)
  rested:Hide()

  -- "current / total", centred ON TOP of the fill. The label is parented to the
  -- fill (a child StatusBar) so it draws above the bar texture; on the container
  -- frame it sat behind the fill.
  local label = fill:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(label, HoryUI.font.number, 11, "OUTLINE")
  label:SetPoint("CENTER", fill, "CENTER", 0, 0)
  label:SetTextColor(C.text[1], C.text[2], C.text[3])

  local function SetText(cur, total)
    if total <= 0 then total = 1 end
    label:SetText(cur .. " / " .. total)
  end

  local function SetFillColor(c)
    fill:SetStatusBarColor(c[1], c[2], c[3], 1)
    if fill.bg then fill.bg:SetVertexColor(c[1], c[2], c[3], 0.16) end
  end

  local function Update()
    local mode = HoryUIDB.xprepMode or "xp"

    if mode == "rep" then
      local name, _, repmin, repmax, repvalue = GetWatchedFactionInfo()
      if name then
        local cur = repvalue - repmin
        local total = repmax - repmin
        if total <= 0 then total = 1 end
        fill:SetMinMaxValues(0, total)
        fill:SetValue(cur)
        SetFillColor(C.cast)
        rested:Hide()
        SetText(cur, total)
        line.tip = name .. ":  " .. cur .. " / " .. total
        return
      end
    end

    -- experience
    local xp = UnitXP("player")
    local xpmax = UnitXPMax("player")
    if xpmax <= 0 then xpmax = 1 end
    fill:SetMinMaxValues(0, xpmax)
    fill:SetValue(xp)
    SetFillColor(C.accent)

    local exhaustion = GetXPExhaustion and GetXPExhaustion()
    local w = fill:GetWidth()
    if exhaustion and exhaustion > 0 and w and w > 0 then
      local restEnd = xp + exhaustion
      if restEnd > xpmax then restEnd = xpmax end
      rested:ClearAllPoints()
      rested:SetPoint("TOPLEFT", fill, "TOPLEFT", (xp / xpmax) * w, 0)
      rested:SetPoint("BOTTOMLEFT", fill, "BOTTOMLEFT", (xp / xpmax) * w, 0)
      rested:SetWidth(((restEnd - xp) / xpmax) * w)
      rested:Show()
    else
      rested:Hide()
    end

    SetText(xp, xpmax)
    line.tip = "Experience:  " .. xp .. " / " .. xpmax .. "  (" .. math.floor(xp / xpmax * 100 + 0.5) .. "%)"
  end

  -- right-click dropdown: Experience or any reputation
  local menu = CreateFrame("Frame", "HoryUIXPMenu", UIParent, "UIDropDownMenuTemplate")
  local function InitMenu()
    local info = {}
    info.text = "Experience"
    info.checked = (HoryUIDB.xprepMode or "xp") == "xp"
    info.func = function() HoryUIDB.xprepMode = "xp"; Update() end
    UIDropDownMenu_AddButton(info)

    local watched = GetWatchedFactionInfo()
    for i = 1, GetNumFactions() do
      local name, _, _, _, _, _, _, _, isHeader = GetFactionInfo(i)
      if name and not isHeader then
        local idx = i
        local fname = name
        local binfo = {}
        binfo.text = fname
        binfo.checked = (HoryUIDB.xprepMode == "rep" and watched == fname)
        binfo.func = function()
          SetWatchedFactionIndex(idx)
          HoryUIDB.xprepMode = "rep"
          Update()
        end
        UIDropDownMenu_AddButton(binfo)
      end
    end
  end

  line:SetScript("OnMouseUp", function()
    if arg1 == "RightButton" and UIDropDownMenu_Initialize and ToggleDropDownMenu then
      UIDropDownMenu_Initialize(menu, InitMenu)
      ToggleDropDownMenu(1, nil, menu, "cursor", 0, 0)
    end
  end)

  -- Hover tooltip: full XP + rested breakdown, or watched-reputation detail.
  -- Colours pulled from §8 tokens (white title, text2 = secondary value).
  local function Pct(num, den)
    if not den or den <= 0 then return 0 end
    return math.floor(num / den * 100 + 0.5)
  end

  line:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
    local t2 = C.text2

    local mode = HoryUIDB.xprepMode or "xp"
    local name, _, repmin, repmax, repvalue, _, _, _, _, _, _, standingID
    if mode == "rep" then
      name, _, repmin, repmax, repvalue = GetWatchedFactionInfo()
      -- GetWatchedFactionInfo doesn't return the standingID, so find the watched
      -- faction in the list and read it (3rd return of GetFactionInfo).
      if name then
        local watched = name
        for i = 1, GetNumFactions() do
          local fname, _, sid, _, _, _, _, _, isHeader, _, isWatched = GetFactionInfo(i)
          if isWatched and fname == watched then standingID = sid; break end
        end
      end
    end

    if mode == "rep" and name then
      GameTooltip:SetText("Reputation", 1, 1, 1)
      local standing = standingID and getglobal("FACTION_STANDING_LABEL" .. standingID)
      local cur = repvalue - repmin
      local total = repmax - repmin
      if total <= 0 then total = 1 end
      if standing then
        GameTooltip:AddDoubleLine(name, standing, t2[1], t2[2], t2[3], 1, 1, 1)
      else
        GameTooltip:AddLine(name, t2[1], t2[2], t2[3])
      end
      GameTooltip:AddDoubleLine("Standing", cur .. " / " .. total .. "  (" .. Pct(cur, total) .. "%)",
        t2[1], t2[2], t2[3], 1, 1, 1)
    else
      -- Experience
      GameTooltip:SetText("Experience", 1, 1, 1)
      local xp = UnitXP("player")
      local xpmax = UnitXPMax("player")
      if xpmax <= 0 then xpmax = 1 end
      local remaining = xpmax - xp
      GameTooltip:AddDoubleLine("XP", xp .. " / " .. xpmax .. "  (" .. Pct(xp, xpmax) .. "%)",
        t2[1], t2[2], t2[3], 1, 1, 1)
      GameTooltip:AddDoubleLine("To next level", remaining .. "  (" .. Pct(remaining, xpmax) .. "%)",
        t2[1], t2[2], t2[3], 1, 1, 1)

      -- Rested: GetXPExhaustion returns the bonus pool, nil/0 when not rested.
      local exhaustion = GetXPExhaustion and GetXPExhaustion()
      local resting = IsResting and IsResting()
      GameTooltip:AddLine(" ")
      if exhaustion and exhaustion > 0 then
        local en = C.energy
        GameTooltip:AddDoubleLine("Rested", "+" .. exhaustion .. "  (" .. Pct(exhaustion, xpmax) .. "% of a level)",
          en[1], en[2], en[3], 1, 1, 1)
        GameTooltip:AddLine("Grants double XP from kills until spent.", t2[1], t2[2], t2[3])
      else
        GameTooltip:AddDoubleLine("Rested", "Not rested", t2[1], t2[2], t2[3], 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Normal XP gain.", C.text3[1], C.text3[2], C.text3[3])
      end
      if resting then
        GameTooltip:AddLine("Resting (in a rest area).", C.text3[1], C.text3[2], C.text3[3])
      end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Right-click: choose XP / reputation", 0.6, 0.6, 0.6)
    GameTooltip:Show()
  end)
  line:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("PLAYER_XP_UPDATE")
  ev:RegisterEvent("PLAYER_LEVEL_UP")
  ev:RegisterEvent("UPDATE_FACTION")
  ev:RegisterEvent("UPDATE_EXHAUSTION")
  ev:RegisterEvent("PLAYER_LOGOUT")
  ev:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      return
    end
    Update()
  end)

  HoryUI.AddRefresher(Update)
  Update()
end)
