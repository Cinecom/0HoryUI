-- HoryUI :: clock -- latency + server time + local time in one compact Garnet
-- chip. The ping row (GetNetStats, the same source castbar's lag compensation
-- reads) sits above a hairline divider; a small status dot + the ms value are
-- tinted on a green -> amber -> red ramp so connection quality reads at a
-- glance. Server time is GetGameTime() (hours/minutes, no seconds API in
-- 1.12); local time is the client's date("%H:%M"). Muted labels left, tabular
-- numbers right; hover shows the full date + all three values. A movable
-- RegisterPanel. Repaints on a 1s throttle and only touches the fontstrings
-- when a value actually changed (the client republishes GetNetStats' latency
-- periodically -- we pick each new value up on the next tick).
-- Lua 5.0 / WoW 1.12 -- handlers use this/event/arg1.

HoryUI:RegisterModule("clock", true, function()
  local C = HoryUI.color
  local format, date = string.format, date
  local W, H, PAD = 92, 48, 5

  -- Ping quality colour: calm pure green up to 60ms, then two linear segments
  -- green -> amber (60..150) -> hot red (150..300+). Token colours only.
  local function PingColor(ms)
    local g, a, r = C.health, C.threat, C.health_low
    if ms <= 60 then return g[1], g[2], g[3] end
    if ms <= 150 then
      local t = (ms - 60) / 90
      return g[1] + (a[1] - g[1]) * t, g[2] + (a[2] - g[2]) * t, g[3] + (a[3] - g[3]) * t
    end
    local t = (ms - 150) / 150
    if t > 1 then t = 1 end
    return a[1] + (r[1] - a[1]) * t, a[2] + (r[2] - a[2]) * t, a[3] + (r[3] - a[3]) * t
  end

  local f = CreateFrame("Frame", "HoryUIClock", UIParent)
  f:SetWidth(W); f:SetHeight(H)
  f:SetFrameStrata("MEDIUM")
  f:EnableMouse(true)
  HoryUI.CreateBackdrop(f)

  local function Label(y, txt, x)
    local l = f:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(l, HoryUI.font.normal, 9, "OUTLINE")
    l:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + (x or 0), y)
    l:SetText(txt)
    l:SetTextColor(C.text3[1], C.text3[2], C.text3[3])
    return l
  end
  local function TimeText(y)
    local t = f:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(t, HoryUI.font.number, 11, "OUTLINE")
    t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, y)
    t:SetJustifyH("RIGHT")
    t:SetTextColor(C.text[1], C.text[2], C.text[3])
    return t
  end

  -- latency row: status dot + muted label left, tinted ms value right
  local dot = f:CreateTexture(nil, "ARTWORK")
  dot:SetTexture(HoryUI.tex.white)
  dot:SetWidth(5); dot:SetHeight(5)
  dot:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -8)
  Label(-5, "Ping", 9)
  local ping = TimeText(-4)

  -- hairline divider between the latency row and the times (sec.8 border_soft)
  local rule = f:CreateTexture(nil, "ARTWORK")
  rule:SetTexture(HoryUI.tex.white)
  rule:SetVertexColor(C.border_soft[1], C.border_soft[2], C.border_soft[3])
  rule:SetHeight(1)
  rule:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -17)
  rule:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -17)

  Label(-21, "Server")
  Label(-34, "Local")
  local srv = TimeText(-20)
  local loc = TimeText(-33)

  local function Lag()
    local _, _, lag = GetNetStats()
    return lag or 0
  end

  local function Refresh()
    local h, m = GetGameTime()
    local stamp = (h or 0) * 60 + (m or 0)
    local ltext = date("%H:%M")
    local lag = Lag()
    if stamp == f.lastSrv and ltext == f.lastLoc and lag == f.lastLag then return end
    f.lastSrv = stamp
    f.lastLoc = ltext
    f.lastLag = lag
    srv:SetText(format("%02d:%02d", h or 0, m or 0))
    loc:SetText(ltext)
    ping:SetText(lag .. " ms")
    local r, g, b = PingColor(lag)
    ping:SetTextColor(r, g, b)
    dot:SetVertexColor(r, g, b)
  end

  -- hover: full local date + both times (title garnet, sec.8.7 language)
  f:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
    local a = C.accent_hi
    GameTooltip:SetText("Time", a[1], a[2], a[3])
    GameTooltip:AddLine(date("%A, %B %d"), C.text2[1], C.text2[2], C.text2[3])
    local h, m = GetGameTime()
    GameTooltip:AddDoubleLine("Server", format("%02d:%02d", h or 0, m or 0),
      C.text3[1], C.text3[2], C.text3[3], C.text[1], C.text[2], C.text[3])
    GameTooltip:AddDoubleLine("Local", date("%H:%M"),
      C.text3[1], C.text3[2], C.text3[3], C.text[1], C.text[2], C.text[3])
    local _, _, lag = GetNetStats()
    lag = lag or 0
    local r, g, b = PingColor(lag)
    GameTooltip:AddDoubleLine("Latency", lag .. " ms",
      C.text3[1], C.text3[2], C.text3[3], r, g, b)
    GameTooltip:Show()
  end)
  f:SetScript("OnLeave", function() GameTooltip:Hide() end)

  f.acc = 0
  f:SetScript("OnUpdate", function()
    this.acc = this.acc + arg1
    if this.acc < 1 then return end
    this.acc = 0
    Refresh()
  end)

  f:RegisterEvent("PLAYER_LOGOUT")
  f:SetScript("OnEvent", function()
    this:UnregisterAllEvents()
    this:SetScript("OnEvent", nil)
    this:SetScript("OnUpdate", nil)
  end)

  HoryUI.RegisterPanel(f, "clock", "Clock", "TOPRIGHT", -20, -230)
  Refresh()
end)
