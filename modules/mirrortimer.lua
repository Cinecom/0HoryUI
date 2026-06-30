-- HoryUI :: mirror timers -- breath / fatigue (exhaustion) / feign-death bars,
-- restyled flat in the Garnet language but keeping each timer's canonical colour
-- (breath blue, fatigue yellow, death orange). Up to 3 run at once; they stack
-- inside one draggable container (drag it when panels are unlocked).
--
-- API (verified against FrameXML/MirrorTimer.lua + UIParent.lua):
--   MIRROR_TIMER_START  arg1=type ("BREATH"/"EXHAUSTION"/"DEATH"/"FEIGNDEATH"),
--                       arg2=value(ms) arg3=max(ms) arg4=scale(/sec, <0 drains)
--                       arg5=paused arg6=label
--   MIRROR_TIMER_STOP   arg1=type
--   MIRROR_TIMER_PAUSE  arg1=paused (>0 = paused)
--   value/max are ms; scale is per-second (native advances value += scale*elapsed
--   with value already in seconds), so we divide value/max by 1000 and apply scale raw.

HoryUI:RegisterModule("mirrortimer", true, function()
  local C = HoryUI.color

  -- Canonical timer colours (close to FrameXML's MirrorTimerColors, lightly
  -- desaturated for the flat look). The user reads breath=blue, fatigue=yellow.
  local TYPECOLOR = {
    BREATH     = { 0.23, 0.55, 0.97 },  -- blue
    EXHAUSTION = { 0.95, 0.85, 0.22 },  -- yellow
    DEATH      = { 0.95, 0.60, 0.18 },  -- orange
    FEIGNDEATH = { 0.95, 0.60, 0.18 },  -- orange
  }
  local DEFCOLOR = { 0.55, 0.58, 0.62 }

  -- Unlocked-preview rows so the container can be positioned with nothing active.
  local PREVIEW = {
    { "BREATH",     "Breath",      0.70 },
    { "EXHAUSTION", "Exhausted",   0.45 },
    { "FEIGNDEATH", "Feign Death", 0.85 },
  }

  local BARW, BARH, GAP = 180, 16, 4

  local container = CreateFrame("Frame", "HoryUIMirrorTimers", UIParent)
  container:SetWidth(BARW)
  container:SetHeight(BARH)
  container:SetFrameStrata("MEDIUM")

  local bars = {}

  local function SetColor(b, timerType)
    local c = TYPECOLOR[timerType] or DEFCOLOR
    b.fill:SetStatusBarColor(c[1], c[2], c[3], 1)
    if b.fill.bg then b.fill.bg:SetVertexColor(c[1], c[2], c[3], 0.16) end
  end

  local function BarOnUpdate()
    local b = this
    if not b.active or b.paused then return end
    b.value = b.value + b.scale * arg1
    b.acc = (b.acc or 0) + arg1
    if b.acc < 0.05 then return end
    b.acc = 0
    local v = b.value
    if v < 0 then v = 0 end
    b.fill:SetValue(v)
    b.time:SetText(math.floor(v + 0.5) .. "s")
  end

  local function BuildBar(i)
    local b = CreateFrame("Frame", "HoryUIMirrorTimer" .. i, container)
    b:SetHeight(BARH)
    HoryUI.CreateBackdrop(b)

    b.fill = HoryUI.CreateStatusBar(b, DEFCOLOR)
    b.fill:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
    b.fill:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    b.fill:SetMinMaxValues(0, 1)
    b.fill:SetValue(1)

    b.text = b.fill:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(b.text, HoryUI.font.normal, 11, "OUTLINE")
    b.text:SetPoint("LEFT", b.fill, "LEFT", 4, 0)
    b.text:SetTextColor(C.text[1], C.text[2], C.text[3])

    b.time = b.fill:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(b.time, HoryUI.font.number, 11, "OUTLINE")
    b.time:SetPoint("RIGHT", b.fill, "RIGHT", -4, 0)
    b.time:SetTextColor(C.text[1], C.text[2], C.text[3])

    b.active = false
    b:SetScript("OnUpdate", BarOnUpdate)
    b:Hide()
    return b
  end

  for i = 1, 3 do bars[i] = BuildBar(i) end

  -- Stack the visible bars top-down with no gaps and size the container to fit
  -- (anchored by its TOP, so it grows downward from the saved position).
  local function Relayout()
    local y = 0
    for i = 1, 3 do
      local b = bars[i]
      local show = b.active or HoryUI.showAll
      if show then
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -y)
        b:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -y)
        b:Show()
        y = y + BARH + GAP
      else
        b:Hide()
      end
    end
    container:SetHeight((y > 0) and (y - GAP) or BARH)
  end

  -- Paint the unlocked-preview rows; clears once a timer goes live or on lock.
  local function ApplyPreview()
    for i = 1, 3 do
      local b = bars[i]
      if not b.active then
        local p = PREVIEW[i]
        SetColor(b, p[1])
        b.fill:SetMinMaxValues(0, 1)
        b.fill:SetValue(p[3])
        b.text:SetText(p[2])
        b.time:SetText("")
      end
    end
  end

  local function FindBar(timerType)
    for i = 1, 3 do
      if bars[i].active and bars[i].timerType == timerType then return bars[i] end
    end
    return nil
  end

  local function FreeBar()
    for i = 1, 3 do
      if not bars[i].active then return bars[i] end
    end
    return nil
  end

  local function Start(timerType, value, maxvalue, scale, paused, label)
    local b = FindBar(timerType) or FreeBar()
    if not b then return end
    b.active = true
    b.timerType = timerType
    b.scale = scale or 0
    b.paused = (paused and paused > 0) and true or nil
    b.value = (value or 0) / 1000
    b.acc = 0
    SetColor(b, timerType)
    b.fill:SetMinMaxValues(0, (maxvalue or 1000) / 1000)
    b.fill:SetValue(b.value)
    b.text:SetText(label or "")
    b.time:SetText(math.floor(b.value + 0.5) .. "s")
    Relayout()
  end

  local function Stop(timerType)
    local b = FindBar(timerType)
    if not b then return end
    b.active = false
    b.timerType = nil
    Relayout()
  end

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("MIRROR_TIMER_START")
  ev:RegisterEvent("MIRROR_TIMER_STOP")
  ev:RegisterEvent("MIRROR_TIMER_PAUSE")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("PLAYER_LOGOUT")
  ev:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      for i = 1, 3 do bars[i]:SetScript("OnUpdate", nil) end
      return
    end
    if event == "MIRROR_TIMER_START" then
      Start(arg1, arg2, arg3, arg4, arg5, arg6)
    elseif event == "MIRROR_TIMER_STOP" then
      Stop(arg1)
    elseif event == "MIRROR_TIMER_PAUSE" then
      local p = (arg1 and arg1 > 0) and true or nil
      for i = 1, 3 do if bars[i].active then bars[i].paused = p end end
    elseif event == "PLAYER_ENTERING_WORLD" then
      for i = 1, 3 do bars[i].active = false; bars[i].timerType = nil end
      Relayout()
    end
  end)

  -- Hide the stock mirror timers (MirrorTimer_Show still targets them, but they're
  -- reparented to a hidden frame so :Show() can't surface them).
  for i = 1, 3 do HoryUI.HideBlizzard(getglobal("MirrorTimer" .. i)) end

  -- Repaint preview / relayout on lock-unlock so the container reveals for dragging.
  HoryUI.AddRefresher(function() ApplyPreview(); Relayout() end)

  HoryUI.RegisterPanel(container, "mirrortimer", "Mirror Timers", "TOP", 0, -160)
  ApplyPreview()
  Relayout()
end)
