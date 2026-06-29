-- HoryUI :: range tracker (functionality ported from EnemyRangeTracker)
-- A compact panel: exact yards to target + a closing/opening-rate slider, with a
-- melee "safe zone" highlight. UnitXP_SP3 gives exact distance; without it, falls
-- back to CheckInteractDistance bands. Styled in the Garnet language.

HoryUI:RegisterModule("rangetracker", true, function()
  local C = HoryUI.color
  local format = string.format

  local SAFE_MIN, SAFE_MAX = 2.0, 8.0    -- melee sweet spot (yards)
  local SENS = 0.8                        -- slider yards/sec -> pixels
  local MAXOFF = 14                       -- slider travel from centre
  local RATE_TAU = 0.15                   -- rate smoothing time constant (s)
  local TICK = 0.03                       -- update interval (s); ~30Hz for smooth motion

  -- exact distance via UnitXP_SP3, else coarse interaction bands
  local function Distance()
    if not UnitExists("target") then return nil end
    local d = HoryUI.uxp.Distance("player", "target")
    if d then return d end
    if CheckInteractDistance("target", 3) then return 1.5
    elseif CheckInteractDistance("target", 2) then return 5.0
    elseif CheckInteractDistance("target", 1) then return 15.0 end
    return 30.0
  end

  -- ---- panel --------------------------------------------------------------
  local f = CreateFrame("Frame", "HoryUIRange", UIParent)
  f:SetWidth(84)
  f:SetHeight(34)
  f:SetFrameStrata("MEDIUM")
  HoryUI.CreateBackdrop(f)
  HoryUI.RegisterPanel(f, "rangetracker", "Range", "CENTER", 0, 160)

  -- vertical slider track (left)
  local track = CreateFrame("Frame", nil, f)
  track:SetWidth(6)
  track:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -5)
  track:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 5, 5)
  HoryUI.CreateBackdrop(track)

  local mid = track:CreateTexture(nil, "ARTWORK")   -- centre reference line
  mid:SetTexture(HoryUI.tex.white)
  mid:SetVertexColor(C.text3[1], C.text3[2], C.text3[3], 0.8)
  mid:SetHeight(1)
  mid:SetPoint("LEFT", track, "LEFT", 1, 0)
  mid:SetPoint("RIGHT", track, "RIGHT", -1, 0)

  local ind = track:CreateTexture(nil, "OVERLAY")   -- moving indicator
  ind:SetTexture(HoryUI.tex.white)
  ind:SetWidth(6)
  ind:SetHeight(3)
  ind:SetPoint("CENTER", track, "CENTER", 0, 0)
  ind:SetVertexColor(C.energy[1], C.energy[2], C.energy[3], 1)

  local txt = f:CreateFontString(nil, "OVERLAY")    -- distance readout
  HoryUI.SetFont(txt, HoryUI.font.number, 15, "OUTLINE")
  txt:SetPoint("LEFT", track, "RIGHT", 5, 0)
  txt:SetPoint("RIGHT", f, "RIGHT", -4, 0)
  txt:SetJustifyH("CENTER")
  txt:SetTextColor(C.text[1], C.text[2], C.text[3])
  txt:SetText("--")

  -- ---- state --------------------------------------------------------------
  -- Rate smoothing is time-based (see Update): no history buffer, so it neither
  -- allocates per tick nor stretches its window when the tick rate changes -- the
  -- old 5-sample buffer spanned ~0.5s at the 0.1s throttle, which felt sluggish.
  local lastD = nil
  local smoothed = 0
  local lastTxt = nil

  local function Reset()
    lastD = nil
    smoothed = 0
    lastTxt = nil
    ind:ClearAllPoints()
    ind:SetPoint("CENTER", track, "CENTER", 0, 0)
    ind:SetVertexColor(C.energy[1], C.energy[2], C.energy[3], 1)
  end

  local function Border(safe)
    if safe then
      f.backdrop:SetBackdropBorderColor(C.health[1], C.health[2], C.health[3], 1)
    else
      f.backdrop:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end
  end

  local function Update(dt)
    if HoryUI.showAll and not UnitExists("target") then
      f:Show(); txt:SetText("5.0"); lastTxt = "5.0"; Border(true)
      return
    end

    local d = Distance()
    if not d then f:Hide(); Reset(); return end
    f:Show()
    local s = format("%.1f", d)
    if s ~= lastTxt then txt:SetText(s); lastTxt = s end

    -- instantaneous closing/opening rate (yd/s, negative = closing), folded into
    -- `smoothed` with a weight derived from dt so responsiveness is the same at any
    -- frame rate (frame-rate-independent exponential smoothing; no history buffer).
    if dt and dt > 0 and lastD then
      local rate = (d - lastD) / dt
      local a = dt / RATE_TAU
      if a > 1 then a = 1 end
      smoothed = smoothed + (rate - smoothed) * a
    end
    lastD = d

    -- indicator: closing moves up, opening moves down
    local off = smoothed * SENS
    if off > MAXOFF then off = MAXOFF elseif off < -MAXOFF then off = -MAXOFF end
    ind:ClearAllPoints()
    ind:SetPoint("CENTER", track, "CENTER", 0, -off)

    if smoothed < -0.5 then
      ind:SetVertexColor(C.health[1], C.health[2], C.health[3], 1)         -- closing
    elseif smoothed > 0.5 then
      ind:SetVertexColor(C.health_low[1], C.health_low[2], C.health_low[3], 1) -- fleeing
    else
      ind:SetVertexColor(C.energy[1], C.energy[2], C.energy[3], 1)         -- steady
    end

    Border(d >= SAFE_MIN and d < SAFE_MAX)
  end

  -- ---- driver -------------------------------------------------------------
  local acc = 0
  local driver = CreateFrame("Frame")
  driver:RegisterEvent("PLAYER_TARGET_CHANGED")
  driver:RegisterEvent("PLAYER_ENTERING_WORLD")
  driver:RegisterEvent("PLAYER_LOGOUT")
  driver:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      this:SetScript("OnUpdate", nil)
      return
    end
    Reset()
    Update()
  end)
  driver:SetScript("OnUpdate", function()
    acc = acc + arg1
    if acc < TICK then return end
    Update(acc)
    acc = 0
  end)

  HoryUI.AddRefresher(Update)
  Update()
end)
