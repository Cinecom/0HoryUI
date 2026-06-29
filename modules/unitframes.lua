-- HoryUI :: unit frames (player + target + target-of-target)
-- Rogue energy ticks & combo points live here too (one concern: "the unit you
-- watch"). Lua 5.0 / WoW 1.12 -- handlers use this/event/arg1, never self/...
--
-- Verified 1.12 techniques (from pfUI):
--   level color   = GetDifficultyColor(level) -> {r,g,b}
--   2D portrait   = SetPortraitTexture(texture, unit)
--   right-click   = ToggleDropDownMenu(1, nil, <Player|Target>FrameDropDown, "cursor")
--   target-target = poll the "targettarget" unit (~0.2s; no event exists)

HoryUI:RegisterModule("unitframes", true, function()
  local C = HoryUI.color
  -- compact layout constants. PAD is the inner margin (the dark "border" the eye
  -- reads around the content); NAMEH is the name/level row; bars stack flush with
  -- a single 2px gap. Frame heights are derived so the portrait bottom lines up
  -- with the last bar -- no dead space below.
  local PAD = 2
  local NAMEH = 13
  local HEALTH_H = 18
  local BARGAP = 2
  local W = 220

  local floor = math.floor
  local inCombat = false

  ----------------------------------------------------------------------------
  -- small unit helpers
  ----------------------------------------------------------------------------
  local function StatusText(unit)
    if not UnitIsConnected(unit) then return "Offline" end
    if UnitIsDeadOrGhost(unit) then
      if UnitIsGhost(unit) then return "Ghost" end
      return "Dead"
    end
    return nil
  end

  -- level string (+ classification marker) and its difficulty color
  local function LevelInfo(unit)
    local cls = UnitClassification(unit)
    local mark = ""
    if cls == "worldboss" then mark = "+"
    elseif cls == "rareelite" then mark = "+r"
    elseif cls == "elite" then mark = "+"
    elseif cls == "rare" then mark = "r" end

    local lvl = UnitLevel(unit)
    if lvl and lvl > 0 then
      return lvl .. mark, GetDifficultyColor(lvl)
    end
    -- skull / "??" : much higher level or a boss
    return "??" .. mark, { r = C.health_low[1], g = C.health_low[2], b = C.health_low[3] }
  end

  local function HealthColor(unit, pct)
    if pct <= 25 then return C.health_low end
    -- tapped by another player -> grey (NPCs only)
    if not UnitIsPlayer(unit) and UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
      return C.tapped
    end
    return C.health
  end

  local function SetPortrait(f)
    if not f.portrait then return end
    if UnitExists(f.unit) then
      SetPortraitTexture(f.portrait.tex, f.unit)
    else
      f.portrait.tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    f.portrait.tex:SetTexCoord(0.12, 0.88, 0.12, 0.88)   -- trim (SetPortraitTexture resets coords)
  end

  -- hover: drives the fade flag, sets the SuperWoW mouseover unit (so
  -- [target=mouseover] macros resolve on our frames), and glows the border.
  local function HookHover(f)
    f:SetScript("OnEnter", function()
      this.mouse = true
      HoryUI.sw.SetMouseover(this.unit)
      if this.backdrop then this.backdrop:SetBackdropBorderColor(C.accent_hi[1], C.accent_hi[2], C.accent_hi[3], 1) end
    end)
    f:SetScript("OnLeave", function()
      this.mouse = false
      HoryUI.sw.SetMouseover(nil)
      if this.backdrop then this.backdrop:SetBackdropBorderColor(0, 0, 0, 1) end
    end)
  end

  ----------------------------------------------------------------------------
  -- shared paint: name / level / health
  ----------------------------------------------------------------------------
  local function UpdateHealth(f)
    local unit = f.unit
    if not UnitExists(unit) then
      if HoryUI.showAll then
        f:Show()
        f.name:SetText(f.placeholder or unit)
        f.name:SetTextColor(C.text[1], C.text[2], C.text[3])
        f.level:SetText("60"); f.level:SetTextColor(C.text2[1], C.text2[2], C.text2[3])
        f.health:SetMinMaxValues(0, 1); f.health:SetValue(1)
        f.health:SetStatusBarColor(C.health[1], C.health[2], C.health[3], 1)
        f.hpval:SetText("- / -"); f.hppct:SetText("100%")
        if f.power then f.power:SetMinMaxValues(0, 1); f.power:SetValue(1) end
        if f.pleft then f.pleft:SetText(""); f.pright:SetText("") end
        if f.portrait then f.portrait.tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
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
    local pct = floor(hp / max * 100 + 0.5)

    f.name:SetText(UnitName(unit) or "")
    local nc = HoryUI.UnitNameColor(unit)
    f.name:SetTextColor(nc[1], nc[2], nc[3])

    local ltext, lc = LevelInfo(unit)
    f.level:SetText(ltext)
    f.level:SetTextColor(lc.r, lc.g, lc.b)

    local hc = HealthColor(unit, pct)
    f.health:SetStatusBarColor(hc[1], hc[2], hc[3], 1)

    local status = StatusText(unit)
    if status then
      f.health:SetValue(0)
      f.hpval:SetText(status)
      f.hppct:SetText("")
    else
      f.hpval:SetText(hp .. " / " .. max)
      f.hppct:SetText(pct .. "%")
    end

    if unit == "player" then f.injured = (hp < max) end
  end

  -- generic power bar (target / tot); player energy is handled separately
  local function UpdatePower(f)
    if not f.power or not UnitExists(f.unit) then return end
    local unit = f.unit
    local pc = HoryUI.PowerColor(unit)
    f.power:SetStatusBarColor(pc[1], pc[2], pc[3], 1)
    if f.power.bg then f.power.bg:SetVertexColor(pc[1], pc[2], pc[3], 0.16) end
    local cur = UnitMana(unit)
    local pmax = UnitManaMax(unit)
    if pmax <= 0 then pmax = 1 end
    f.power:SetMinMaxValues(0, pmax)
    f.power:SetValue(cur)
    if f.pleft then
      if pmax > 1 then
        f.pleft:SetText(cur .. " / " .. pmax)
        f.pright:SetText(floor(cur / pmax * 100 + 0.5) .. "%")
      else
        f.pleft:SetText(""); f.pright:SetText("")
      end
    end
  end

  ----------------------------------------------------------------------------
  -- builders
  ----------------------------------------------------------------------------
  local function BuildPortrait(parent, sz)
    local p = CreateFrame("Frame", nil, parent)
    p:SetWidth(sz); p:SetHeight(sz)
    HoryUI.CreateBackdrop(p)
    p.tex = p:CreateTexture(nil, "ARTWORK")
    p.tex:SetPoint("TOPLEFT", p, "TOPLEFT", 1, -1)
    p.tex:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -1, 1)
    p.tex:SetTexCoord(0.12, 0.88, 0.12, 0.88)
    return p
  end

  -- bar2h = height of the second bar (energy/power) the caller stacks under
  -- health; the frame height is derived from it so the portrait ends flush with
  -- that bar (no empty gap below).
  local function BuildUnitFrame(name, unit, bar2h, leftpad)
    leftpad = leftpad or 0          -- reserved strip left of the portrait (combo)
    local height = PAD + NAMEH + HEALTH_H + BARGAP + bar2h + PAD
    local f = CreateFrame("Frame", name, UIParent)
    f:SetWidth(W); f:SetHeight(height)
    f:SetFrameStrata("MEDIUM")
    f:EnableMouse(true)
    f.unit = unit
    HoryUI.CreateBackdrop(f)

    local psz = height - 2 * PAD
    f.psz = psz
    f.portrait = BuildPortrait(f, psz)
    f.portrait:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + leftpad, -PAD)
    f.cx = PAD + leftpad + psz + PAD    -- left edge of the text/bar column

    f.level = f:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(f.level, HoryUI.font.number, 11, "OUTLINE")
    f.level:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -PAD)
    f.level:SetJustifyH("RIGHT")

    f.name = f:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(f.name, HoryUI.font.normal, 12, "OUTLINE")
    f.name:SetPoint("TOPLEFT", f, "TOPLEFT", f.cx, -PAD)
    f.name:SetPoint("RIGHT", f.level, "LEFT", -4, 0)
    f.name:SetJustifyH("LEFT")
    f.name:SetTextColor(C.text[1], C.text[2], C.text[3])

    f.health = HoryUI.CreateStatusBar(f, C.health)
    f.health:SetPoint("TOPLEFT", f, "TOPLEFT", f.cx, -(PAD + NAMEH))
    f.health:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -(PAD + NAMEH))
    f.health:SetHeight(HEALTH_H)
    HoryUI.CreateBackdrop(f.health)

    f.hpval = f.health:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(f.hpval, HoryUI.font.number, 11, "OUTLINE")
    f.hpval:SetPoint("LEFT", f.health, "LEFT", 4, 0)
    f.hpval:SetTextColor(C.text[1], C.text[2], C.text[3])

    f.hppct = f.health:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(f.hppct, HoryUI.font.number, 11, "OUTLINE")
    f.hppct:SetPoint("RIGHT", f.health, "RIGHT", -4, 0)
    f.hppct:SetTextColor(C.text[1], C.text[2], C.text[3])

    return f
  end

  ----------------------------------------------------------------------------
  -- PLAYER frame (+ energy bar + tick predictor line + out-of-combat fade)
  ----------------------------------------------------------------------------
  local ENERGY_H = 10
  local player = BuildUnitFrame("HoryUIPlayer", "player", ENERGY_H)

  player.energy = HoryUI.CreateStatusBar(player, C.energy)
  player.energy:SetPoint("TOPLEFT", player.health, "BOTTOMLEFT", 0, -BARGAP)
  player.energy:SetPoint("TOPRIGHT", player.health, "BOTTOMRIGHT", 0, -BARGAP)
  player.energy:SetHeight(ENERGY_H)
  HoryUI.CreateBackdrop(player.energy)

  -- The energy bar is sized only by two opposing anchors (no SetWidth). In 1.12,
  -- energy:GetWidth() on such a bar returns a stale/unresolved value (it read 154
  -- for a bar that renders 171 wide), so a tick line positioned from GetWidth()
  -- stopped at ~85%. Derive the true width from the same geometry that anchored
  -- the bar -- frameWidth minus the text column (cx) minus the right pad -- which
  -- is exactly what the health/energy TOPLEFT(cx)..TOPRIGHT(-PAD) anchors produce.
  -- (pfUI's energytick.lua uses a stored width for the same reason.)
  player.barW = W - player.cx - PAD

  player.eval = player.energy:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(player.eval, HoryUI.font.number, 9, "OUTLINE")
  player.eval:SetPoint("RIGHT", player.energy, "RIGHT", -3, 0)
  player.eval:SetTextColor(C.text2[1], C.text2[2], C.text2[3])

  -- regen-tick predictor: a single thin BLACK line sweeping left->right across
  -- the energy bar over the 2.0s tick cycle (high contrast on the gold fill).
  -- No 20-energy segment dividers.
  -- It MUST render above the energy number: in one draw layer a FontString draws
  -- on top of a Texture, so a line put straight on the bar disappears behind the
  -- "100" text and looks like it stops there. A child frame with a higher frame
  -- level draws its regions above all of the bar's regions, the number included.
  local tickholder = CreateFrame("Frame", nil, player.energy)
  tickholder:SetAllPoints(player.energy)
  tickholder:SetFrameLevel(player.energy:GetFrameLevel() + 3)
  player.tickline = tickholder:CreateTexture(nil, "OVERLAY")
  player.tickline:SetTexture(HoryUI.tex.white)
  local tk = C.bg
  player.tickline:SetVertexColor(tk[1], tk[2], tk[3], 1)
  player.tickline:SetWidth(2)
  player.tickline:SetHeight(ENERGY_H)
  player.tickline:SetPoint("TOPLEFT", player.energy, "TOPLEFT", 0, 0)

  local function UpdateEnergy()
    local cur = UnitMana("player")
    local max = UnitManaMax("player")
    if max <= 0 then max = 100 end
    player.energy:SetMinMaxValues(0, max)
    player.energy:SetValue(cur)
    player.eval:SetText(cur)
  end

  -- Energy ticks every ~2.0s (Turtle's Blade Rush talent shortens it, agility-
  -- scaled). We DON'T measure the live gap -- in-game readouts showed it jitters
  -- (a 2.5s combat-loot hiccup set period=2.5, so the next sweep ran too slow and
  -- the real 2.0s tick snapped the line back at ~78% -- right where the energy
  -- number sits). Instead we use the fixed analytic period, complete the sweep a
  -- touch early, and hold at the bar's end until the real tick resets it (see the
  -- OnUpdate sweep). Proc/talent energy (Relentless Strikes, Thistle Tea, ...)
  -- still must not reset the sweep; pfUI's energytick.lua filters it via the
  -- combat log ("You gain N Energy from <src>") -- we do the same (ignoreNextGain).
  local function TickPeriod()
    local period = 2.0
    local _, _, _, _, rank = GetTalentInfo(2, 16)   -- Combat tab, Blade Rush
    if rank and rank > 0 then
      period = period - UnitStat("player", 2) * 0.0006 * rank
    end
    return period
  end

  player.lastEnergy = UnitMana("player")
  player.tickStart = GetTime()
  player.tickPeriod = TickPeriod()

  -- click: target self / right-click menu; mouseover drives the fade
  player:SetScript("OnMouseUp", function()
    if arg1 == "LeftButton" then
      TargetUnit("player")
    elseif arg1 == "RightButton" and PlayerFrameDropDown then
      ToggleDropDownMenu(1, nil, PlayerFrameDropDown, "cursor")
    end
  end)
  HookHover(player)

  player:RegisterEvent("PLAYER_ENTERING_WORLD")
  player:RegisterEvent("PLAYER_LOGOUT")
  player:RegisterEvent("UNIT_HEALTH")
  player:RegisterEvent("UNIT_MAXHEALTH")
  player:RegisterEvent("UNIT_ENERGY")
  player:RegisterEvent("UNIT_MANA")
  player:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
  player:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
  player:RegisterEvent("PLAYER_REGEN_DISABLED")
  player:RegisterEvent("PLAYER_REGEN_ENABLED")
  player:RegisterEvent("UNIT_PORTRAIT_UPDATE")
  player:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      this:SetScript("OnUpdate", nil)
      return
    end
    if event == "PLAYER_REGEN_DISABLED" then inCombat = true; return end
    if event == "PLAYER_REGEN_ENABLED" then inCombat = false; return end
    if event == "UNIT_PORTRAIT_UPDATE" then
      if arg1 == "player" then SetPortrait(player) end
      return
    end
    -- combat-log filter: a "You gain N Energy from <src>" line means the *next*
    -- energy rise is a proc/talent gain (Relentless Strikes, Thistle Tea, ...),
    -- not a regen tick -- flag it so it doesn't re-anchor the tick line.
    if event == "CHAT_MSG_SPELL_SELF_BUFF" or event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
      if arg1 and string.find(arg1, "You gain") and string.find(arg1, "Energy from") then
        player.ignoreNextGain = true
      end
      return
    end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      if arg1 == "player" then UpdateHealth(player) end
      return
    end
    if event == "UNIT_ENERGY" or event == "UNIT_MANA" then
      if arg1 == "player" then
        local cur = UnitMana("player")
        if player.lastEnergy and cur > player.lastEnergy then
          -- Energy rose. If the combat log just flagged this as proc/talent
          -- energy, ignore it -- only regen ticks reset the sweep.
          if player.ignoreNextGain then
            player.ignoreNextGain = false
          else
            -- A genuine regen tick: restart the sweep from the left, synced to the
            -- moment energy actually arrived. Period stays fixed (TickPeriod), not
            -- measured -- see the note above TickPeriod.
            player.tickPeriod = TickPeriod()
            player.tickStart = GetTime()
          end
        end
        player.lastEnergy = cur
        UpdateEnergy()
      end
      return
    end
    -- PLAYER_ENTERING_WORLD
    inCombat = UnitAffectingCombat("player") and true or false
    UpdateHealth(player)
    UpdateEnergy()
    SetPortrait(player)
  end)

  player:SetScript("OnUpdate", function()
    -- out-of-combat fade (per design sec.8.5): full alpha in combat / mouseover
    -- / injured / while unlocked; dimmed at rest. Fades the whole frame (portrait
    -- included) -- the dimmed portrait at rest is intentional.
    local want = 0.6
    if HoryUI.showAll or inCombat or this.mouse or this.injured then want = 1.0 end
    local a = this:GetAlpha()
    if a < want then
      a = a + arg1 / 0.18
      if a > want then a = want end
      this:SetAlpha(a)
    elseif a > want then
      a = a - arg1 / 0.18
      if a < want then a = want end
      this:SetAlpha(a)
    end

    -- energy tick predictor: a single line sweeping across the energy bar,
    -- re-anchored to each real regen tick (above). The free-run wrap (pfUI
    -- energytick.lua does the same) restarts the sweep every full period even
    -- when NO energy event fires -- e.g. capped at 100 energy where UNIT_ENERGY
    -- is silent -- so the line keeps moving and never stalls. Width comes from the
    -- cached layout width (this.barW), NOT energy:GetWidth(), which under-reports
    -- (see the barW note above) and made the line stop short of the bar's end.
    if this.tickStart then
      local now = GetTime()
      local period = this.tickPeriod or 2.0
      if now - this.tickStart >= period then this.tickStart = now end
      local w = this.barW
      if w and w > 0 then
        local frac = (now - this.tickStart) / period
        if frac > 1 then frac = 1 end
        this.tickline:SetPoint("TOPLEFT", this.energy, "TOPLEFT", frac * (w - 2), 0)
      end
    end
  end)

  HoryUI.RegisterPanel(player, "player", "Player", "CENTER", -200, -150)

  ----------------------------------------------------------------------------
  -- TARGET frame (+ power bar + combo points + target-of-target)
  ----------------------------------------------------------------------------
  local COMBO_W = 7
  local POWER_H = ENERGY_H    -- match the player's energy bar so the frames are identical
  local target = BuildUnitFrame("HoryUITarget", "target", POWER_H)
  target.placeholder = "Target"

  target.power = HoryUI.CreateStatusBar(target, C.mana)
  target.power:SetPoint("TOPLEFT", target.health, "BOTTOMLEFT", 0, -BARGAP)
  target.power:SetPoint("TOPRIGHT", target.health, "BOTTOMRIGHT", 0, -BARGAP)
  target.power:SetHeight(POWER_H)
  HoryUI.CreateBackdrop(target.power)

  -- power text: current / max (left), percentage (right)
  target.pleft = target.power:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(target.pleft, HoryUI.font.number, 9, "OUTLINE")
  target.pleft:SetPoint("LEFT", target.power, "LEFT", 3, 0)
  target.pleft:SetTextColor(C.text2[1], C.text2[2], C.text2[3])

  target.pright = target.power:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(target.pright, HoryUI.font.number, 9, "OUTLINE")
  target.pright:SetPoint("RIGHT", target.power, "RIGHT", -3, 0)
  target.pright:SetTextColor(C.text2[1], C.text2[2], C.text2[3])

  -- combo points: 1-5 pips stacked vertically just OUTSIDE the target frame's
  -- left edge, the column matching the portrait's height. Sitting outside means
  -- no frame backdrop shows behind them -- so there's no black strip when the
  -- target has no combo points.
  local combo = CreateFrame("Frame", "HoryUICombo", target)
  combo:SetWidth(COMBO_W)
  combo:SetHeight(target.psz)
  combo:SetPoint("TOPRIGHT", target, "TOPLEFT", -2, -PAD)
  combo.pips = {}
  local cgap = 2
  local ph = floor((target.psz - cgap * 4) / 5)
  for i = 1, 5 do
    local t = combo:CreateTexture(nil, "ARTWORK")
    t:SetTexture(HoryUI.tex.white)
    t:SetWidth(COMBO_W); t:SetHeight(ph)
    if i == 1 then
      t:SetPoint("TOP", combo, "TOP", 0, 0)
    else
      t:SetPoint("TOP", combo.pips[i - 1], "BOTTOM", 0, -cgap)
    end
    local e = C.combo_empty
    t:SetVertexColor(e[1], e[2], e[3], 1)
    combo.pips[i] = t
  end

  -- full-combo glow: a soft red bloom hugging the 5th pip, shown only at 5 CP so
  -- a ready finisher is unmistakable. A deliberate exception to the flat look
  -- (CLAUDE.md sec.8), at the user's request.
  combo.glow = combo:CreateTexture(nil, "OVERLAY")
  combo.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  combo.glow:SetBlendMode("ADD")
  local g5 = C.combo[5]
  combo.glow:SetVertexColor(g5[1], g5[2], g5[3], 1)
  combo.glow:SetPoint("CENTER", combo.pips[5], "CENTER", 0, 0)
  combo.glow:SetWidth(COMBO_W + 8)
  combo.glow:SetHeight(ph + 8)
  combo.glow:Hide()

  local function GetCP()
    local ok, cp = pcall(GetComboPoints)
    if ok and type(cp) == "number" then return cp end
    return 0
  end

  local function UpdateCombo()
    if HoryUI.showAll then
      combo:Show()
      combo.glow:Hide()
      for i = 1, 5 do
        local c = (i <= 3) and C.combo[i] or C.combo_empty
        combo.pips[i]:SetVertexColor(c[1], c[2], c[3], 1)
      end
      return
    end
    if not UnitExists("target") or not UnitCanAttack("player", "target") then
      combo:Hide(); return
    end
    combo:Show()
    local cp = GetCP()
    for i = 1, 5 do
      local c = (i <= cp) and C.combo[i] or C.combo_empty
      combo.pips[i]:SetVertexColor(c[1], c[2], c[3], 1)
    end
    if cp >= 5 then combo.glow:Show() else combo.glow:Hide() end
  end

  -- target-of-target: portrait + name + health + power; an independent movable
  -- panel (default sits to the right of the target frame).
  local TOT_NAMEH, TOT_HEALTH, TOT_POWER = 12, 10, 6
  local tot = CreateFrame("Frame", "HoryUITargetTarget", UIParent)
  tot:SetWidth(120)
  tot:SetHeight(PAD + TOT_NAMEH + TOT_HEALTH + BARGAP + TOT_POWER + PAD)
  tot:SetFrameStrata("MEDIUM")
  tot:EnableMouse(true)
  tot.unit = "targettarget"
  HoryUI.CreateBackdrop(tot)

  local totpsz = tot:GetHeight() - 2 * PAD   -- portrait fills the frame height
  tot.portrait = BuildPortrait(tot, totpsz)
  tot.portrait:SetPoint("TOPLEFT", tot, "TOPLEFT", PAD, -PAD)
  local totcx = PAD + totpsz + PAD          -- text/bar column, right of portrait

  tot.name = tot:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(tot.name, HoryUI.font.normal, 10, "OUTLINE")
  tot.name:SetPoint("TOPLEFT", tot, "TOPLEFT", totcx, -PAD)
  tot.name:SetPoint("TOPRIGHT", tot, "TOPRIGHT", -PAD, -PAD)
  tot.name:SetJustifyH("LEFT")
  tot.name:SetTextColor(C.text[1], C.text[2], C.text[3])

  tot.health = HoryUI.CreateStatusBar(tot, C.health)
  tot.health:SetPoint("TOPLEFT", tot, "TOPLEFT", totcx, -(PAD + TOT_NAMEH))
  tot.health:SetPoint("TOPRIGHT", tot, "TOPRIGHT", -PAD, -(PAD + TOT_NAMEH))
  tot.health:SetHeight(TOT_HEALTH)
  HoryUI.CreateBackdrop(tot.health)

  tot.power = HoryUI.CreateStatusBar(tot, C.mana)
  tot.power:SetPoint("TOPLEFT", tot.health, "BOTTOMLEFT", 0, -BARGAP)
  tot.power:SetPoint("TOPRIGHT", tot.health, "BOTTOMRIGHT", 0, -BARGAP)
  tot.power:SetHeight(TOT_POWER)
  HoryUI.CreateBackdrop(tot.power)

  tot:SetScript("OnMouseUp", function()
    if arg1 == "LeftButton" then TargetUnit("targettarget") end
  end)
  HookHover(tot)

  HoryUI.RegisterPanel(tot, "tot", "ToT", "CENTER", 215, -150)

  local function UpdateToT()
    if HoryUI.showAll then
      tot:Show()
      tot.name:SetText("Tgt of Target")
      tot.name:SetTextColor(C.text[1], C.text[2], C.text[3])
      tot.health:SetMinMaxValues(0, 1); tot.health:SetValue(1)
      tot.health:SetStatusBarColor(C.health[1], C.health[2], C.health[3], 1)
      tot.power:SetMinMaxValues(0, 1); tot.power:SetValue(1)
      tot.portrait.tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
      tot.pname = nil      -- force a portrait refresh on the next real update
      return
    end
    if not UnitExists("target") or not UnitExists("targettarget") then
      tot:Hide(); tot.pname = nil; return
    end
    tot:Show()
    local hp, max = HoryUI.UnitHP("targettarget")
    if max <= 0 then max = 1 end
    tot.health:SetMinMaxValues(0, max); tot.health:SetValue(hp)
    local pct = floor(hp / max * 100 + 0.5)
    local hc = HealthColor("targettarget", pct)
    tot.health:SetStatusBarColor(hc[1], hc[2], hc[3], 1)
    local tname = UnitName("targettarget") or ""
    tot.name:SetText(tname)
    local nc = HoryUI.UnitNameColor("targettarget")
    tot.name:SetTextColor(nc[1], nc[2], nc[3])
    UpdatePower(tot)
    -- refresh the 2D portrait only when the unit changes (it's polled, no event)
    if tname ~= tot.pname then
      tot.pname = tname
      SetPortrait(tot)
    end
  end

  -- click: right-click menu / left re-selects (keeps the frame "live")
  target:SetScript("OnMouseUp", function()
    if arg1 == "LeftButton" then
      TargetUnit("target")
    elseif arg1 == "RightButton" and TargetFrameDropDown then
      ToggleDropDownMenu(1, nil, TargetFrameDropDown, "cursor")
    end
  end)
  HookHover(target)

  target.tacc = 0
  target:RegisterEvent("PLAYER_ENTERING_WORLD")
  target:RegisterEvent("PLAYER_LOGOUT")
  target:RegisterEvent("PLAYER_TARGET_CHANGED")
  target:RegisterEvent("UNIT_HEALTH")
  target:RegisterEvent("UNIT_MAXHEALTH")
  target:RegisterEvent("UNIT_MANA")
  target:RegisterEvent("UNIT_ENERGY")
  target:RegisterEvent("UNIT_RAGE")
  target:RegisterEvent("UNIT_FOCUS")
  target:RegisterEvent("PLAYER_COMBO_POINTS")
  target:RegisterEvent("UNIT_PORTRAIT_UPDATE")
  target:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      this:SetScript("OnUpdate", nil)
      return
    end
    if event == "PLAYER_COMBO_POINTS" then UpdateCombo(); return end
    if event == "UNIT_PORTRAIT_UPDATE" then
      if arg1 == "target" then SetPortrait(target) end
      return
    end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
      if arg1 == "target" then UpdateHealth(target) end
      return
    end
    if event == "UNIT_MANA" or event == "UNIT_ENERGY" or event == "UNIT_RAGE" or event == "UNIT_FOCUS" then
      if arg1 == "target" then UpdatePower(target) end
      return
    end
    -- PLAYER_TARGET_CHANGED / PLAYER_ENTERING_WORLD
    UpdateHealth(target)
    UpdatePower(target)
    SetPortrait(target)
    UpdateCombo()
    UpdateToT()
  end)

  -- target-of-target has no change event in 1.12 -- poll it lightly
  target:SetScript("OnUpdate", function()
    this.tacc = this.tacc + arg1
    if this.tacc < 0.2 then return end
    this.tacc = 0
    UpdateToT()
  end)

  HoryUI.RegisterPanel(target, "target", "Target", "CENTER", 40, -150)

  ----------------------------------------------------------------------------
  -- initial paint + lock/unlock repaint
  ----------------------------------------------------------------------------
  HoryUI.AddRefresher(function()
    UpdateHealth(player); UpdateEnergy(); SetPortrait(player)
    UpdateHealth(target); UpdatePower(target); SetPortrait(target)
    UpdateCombo(); UpdateToT()
  end)

  UpdateHealth(player); UpdateEnergy(); SetPortrait(player)
  UpdateHealth(target); UpdatePower(target); SetPortrait(target)
  UpdateCombo(); UpdateToT()

  -- hide the Blizzard frames this module replaces
  HoryUI.HideBlizzard(PlayerFrame)
  HoryUI.HideBlizzard(TargetFrame)
  HoryUI.HideBlizzard(ComboFrame)
end)
