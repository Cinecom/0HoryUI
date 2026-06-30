-- HoryUI :: cooldown count text
-- A numeric countdown drawn on top of every Blizzard cooldown swipe -- action
-- buttons, item buttons, anywhere CooldownFrame_SetTimer is called. Folded in
-- from the standalone OmniCC (Tuller / kebabstorm) so it ships by default.
--
-- Mechanism: a manual hook of the global CooldownFrame_SetTimer (1.12 has no
-- hooksecurefunc, sec. 2). A small text frame is parented to each cooldown's
-- button and throttles its own redraw to the next text-transition point.

HoryUI:RegisterModule("cooldowntext", true, function()
  -- Dormant while the standalone OmniCC is still installed+enabled, so the two
  -- don't both hook CooldownFrame_SetTimer and stack duplicate numbers
  -- (mirrors the bongos/pfskin dormancy gates).
  if IsAddOnLoaded and IsAddOnLoaded("!OmniCC") then
    DEFAULT_CHAT_FRAME:AddMessage("|cffC8A93EHoryUI|r cooldown text dormant -- disable/remove the OmniCC addon to use the built-in one.")
    return
  end

  local C = HoryUI.color

  -- text-formatting transition points (seconds)
  local DAY, HOUR, MINUTE = 86400, 3600, 60
  local DAYISH, HOURISH, MINUTEISH = HOUR * 23.5, MINUTE * 59.5, 59.5
  local HALFDAYISH, HALFHOURISH, HALFMINUTEISH = DAY / 2 + 0.5, HOUR / 2 + 0.5, MINUTE / 2 + 0.5

  local SIZE = 16          -- base font px (scaled up when urgent)
  local MIN_DURATION = 3   -- skip the GCD + other sub-3s flickers
  local SOONISH = 5.5      -- below this = urgent (alarm colour + larger)

  local floor = math.floor
  local GetTime = GetTime
  local function round(x) return floor(x + 0.5) end

  -- Module-wide kill switch flipped on logout (sec. 5, Error 132); each text
  -- frame's OnUpdate self-detaches on the next tick once this is set.
  local dead = false

  -- returns: display text, seconds until the displayed text next changes
  local function FormatTime(s)
    if s < MINUTEISH then
      local sec = round(s)
      if sec == 0 then return "", s end
      return sec, s - (sec - 0.51)
    elseif s < HOURISH then
      local m = round(s / MINUTE)
      return m .. "m", m > 1 and (s - (m * MINUTE - HALFMINUTEISH)) or (s - MINUTEISH)
    elseif s < DAYISH then
      local h = round(s / HOUR)
      return h .. "h", h > 1 and (s - (h * HOUR - HALFHOURISH)) or (s - HOURISH)
    else
      local d = round(s / DAY)
      return d .. "d", d > 1 and (s - (d * DAY - HALFDAYISH)) or (s - DAYISH)
    end
  end

  -- Garnet hierarchy: urgent = alarm orange + larger; <1m white; <1h secondary;
  -- longer muted. Returns scale, r, g, b.
  local function TimeStyle(s)
    if s < SOONISH then       return 1.4,  C.health_low[1], C.health_low[2], C.health_low[3]
    elseif s < MINUTEISH then return 1.0,  C.text[1],  C.text[2],  C.text[3]
    elseif s < HOURISH then   return 1.0,  C.text2[1], C.text2[2], C.text2[3]
    else                      return 0.85, C.text3[1], C.text3[2], C.text3[3] end
  end

  -- mirrors OmniCC's OnUpdate: recompute only when the throttle elapses or the
  -- icon visibility changes, otherwise just count the throttle down.
  local function OnUpdate()
    if dead then this:SetScript("OnUpdate", nil); return end
    if this.nextUpdate <= 0 or not this.icon:IsVisible() then
      local remain = this.duration - (GetTime() - this.start)
      if round(remain) > 0 and this.icon:IsVisible() then
        local txt, nextU = FormatTime(remain)
        local scale, r, g, b = TimeStyle(remain)
        HoryUI.SetFont(this.text, HoryUI.font.number, SIZE * scale, "OUTLINE")
        this.text:SetText(txt)
        this.text:SetTextColor(r, g, b)
        this.nextUpdate = nextU
      else
        this:Hide()
      end
    else
      this.nextUpdate = this.nextUpdate - arg1
    end
  end

  -- A separate text frame (sits above the swipe) is built lazily per cooldown.
  -- The icon reference lets us mirror the button's visibility exactly (OmniCC
  -- ties the text's life to whatever icon naming the host button uses).
  local function CreateCounter(cd)
    local parent = cd:GetParent()
    if not parent then return end
    local pname = parent:GetName()
    local icon = pname and (getglobal(pname .. "Icon")           -- $parentIcon (action buttons)
      or getglobal(pname .. "IconTexture")                       -- $parentIconTexture (item buttons)
      or getglobal(pname .. "_Icon"))                            -- $parent_Icon (some custom bars)
    if not icon then return end

    local tf = CreateFrame("Frame", nil, parent)
    tf:SetAllPoints(parent)
    tf:SetFrameLevel(tf:GetFrameLevel() + 5)

    tf.text = tf:CreateFontString(nil, "OVERLAY")
    tf.text:SetPoint("CENTER", 0, 0)
    tf.text:SetJustifyH("CENTER")
    HoryUI.SetFont(tf.text, HoryUI.font.number, SIZE, "OUTLINE")

    tf.icon = icon
    tf:SetAlpha(parent:GetAlpha())
    tf:Hide()
    tf:SetScript("OnUpdate", OnUpdate)

    cd.horyCounter = tf
    return tf
  end

  -- manual hook (save + replace the global; no hooksecurefunc in 1.12)
  local orig = CooldownFrame_SetTimer
  CooldownFrame_SetTimer = function(cd, start, duration, enable)
    if orig then orig(cd, start, duration, enable) end
    if start and start > 0 and duration and duration > MIN_DURATION and enable and enable > 0 then
      local counter = cd.horyCounter or CreateCounter(cd)
      if counter then
        counter.start = start
        counter.duration = duration
        counter.nextUpdate = 0
        counter:Show()
      end
    elseif cd.horyCounter then
      cd.horyCounter:Hide()
    end
  end

  local guard = CreateFrame("Frame")
  guard:RegisterEvent("PLAYER_LOGOUT")
  guard:SetScript("OnEvent", function() dead = true end)
end)
