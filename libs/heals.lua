-- HoryUI :: incoming heals (receive-only HealComm listener)
-- Tracks heals OTHER players are casting on a unit, from the HealComm addon
-- protocol -- pfUI, HealComm and most vanilla healer addons broadcast it over
-- CHAT_MSG_ADDON. HoryUI is a rogue UI: we never CAST heals, so we only listen
-- and never broadcast. This is the whole slice of pfUI's libpredict we need
-- (message formats verified against pfUI/libs/libpredict.lua ParseComm):
--   "Heal/<target>/<amount>/<castms>/"           direct heal cast started
--   "GrpHeal/<amount>/<castms>/<t1>/.../<t5>/"   group heal (Prayer of Healing)
--   "HealStop" / "Healstop" / "GrpHealstop"      cast landed / cancelled
-- Not handled (deliberately lean): HoT packets (Reju/Renew/Regr -- not part of
-- the incoming-heal sum in pfUI either), resurrections, cast-pushback delay
-- packets (a pushed-back heal just expires a moment early), and the CTRA
-- prefix. Nampower/SuperWoW give no heal AMOUNTS without a learning cache, so
-- HealComm is the honest minimal source; with no HealComm-speaking healers
-- around the overlay simply never shows.
--
-- Heals live in [targetName][sender] = { amount, expires }; an entry dies on
-- the sender's stop message or its cast-time timeout, whichever comes first
-- (expiry is checked at read time -- no OnUpdate here).
--
--   HoryUI.IncHeal(unit)             -> summed pending heal for a unit (0 if none)
--   HoryUI.AttachIncHeal(bar, width) -> ghost-fill overlay on a HoryUI status
--     bar; sets bar.UpdateIncHeal(unit). `width` is the bar's true LAYOUT width
--     (never GetWidth() -- unreliable on anchor-sized bars, CLAUDE.md sec.2).
--     Readers call it from their existing update ticks/events.
--
-- Lua 5.0 / WoW 1.12 -- see CLAUDE.md before editing.

HoryUI = HoryUI or {}

do
  local heals = {}     -- [targetName][sender] = { amount, expires }
  local strfind, gfind, tonumber = string.find, string.gfind, tonumber
  local GetTime, UnitName, pairs = GetTime, UnitName, pairs

  local function Stop(sender)
    for _, byname in pairs(heals) do
      byname[sender] = nil
    end
  end

  local function Add(target, sender, amount, castms)
    if not target or not amount or amount <= 0 then return end
    heals[target] = heals[target] or {}
    -- +0.5s grace over the cast time so lag can't cut a real heal's ghost short
    heals[target][sender] = { amount, GetTime() + (castms or 0) / 1000 + 0.5 }
  end

  function HoryUI.IncHeal(unit)
    local name = UnitName(unit)
    if not name then return 0 end
    local byname = heals[name]
    if not byname then return 0 end
    if UnitIsDeadOrGhost(unit) then return 0 end
    local now, sum = GetTime(), 0
    for sender, h in pairs(byname) do
      if h[2] <= now then
        byname[sender] = nil       -- expired: clean up inline (pfUI does the same)
      else
        sum = sum + h[1]
      end
    end
    return sum
  end

  local rx = CreateFrame("Frame")
  rx:RegisterEvent("CHAT_MSG_ADDON")
  rx:RegisterEvent("PLAYER_LOGOUT")
  rx:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      return
    end
    -- CHAT_MSG_ADDON: arg1 prefix, arg2 message, arg3 channel, arg4 sender
    if arg1 ~= "HealComm" then return end
    local msg, sender = arg2, arg4
    if not msg or not sender then return end

    if msg == "HealStop" or msg == "Healstop" or msg == "GrpHealstop" then
      Stop(sender)
      return
    end

    local _, _, target, amount, castms = strfind(msg, "^Heal/([^/]+)/(%d+)/(%d+)")
    if target then
      Add(target, sender, tonumber(amount), tonumber(castms))
      return
    end

    local _, _, gamount, gcast, rest = strfind(msg, "^GrpHeal/(%d+)/(%d+)/(.*)$")
    if gamount then
      local amt, cast = tonumber(gamount), tonumber(gcast)
      for t in gfind(rest, "([^/]+)") do
        Add(t, sender, amt, cast)
      end
    end
  end)
end

-- ghost fill: the pending heal drawn as a faint health-coloured strip starting
-- at the end of the current health fill. BORDER layer = above the bar's bg
-- track (BACKGROUND), below the fill (statusbar texture) -- pfUI's layering.
function HoryUI.AttachIncHeal(bar, width)
  local hc = HoryUI.color.health
  local t = bar:CreateTexture(nil, "BORDER")
  t:SetTexture(HoryUI.tex.white)
  t:SetVertexColor(hc[1], hc[2], hc[3], 0.35)
  t:Hide()

  bar.UpdateIncHeal = function(unit)
    local heal = HoryUI.IncHeal(unit)
    if heal > 0 then
      local hp, max = HoryUI.UnitHP(unit)
      if max > 0 and hp < max then
        local fillW = width * hp / max
        local incW = width * heal / max
        if fillW + incW > width then incW = width - fillW end   -- clamp: no overheal spill
        if incW >= 1 then
          t:SetPoint("TOPLEFT", bar, "TOPLEFT", fillW, 0)
          t:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", fillW, 0)
          t:SetWidth(incW)
          t:Show()
          return
        end
      end
    end
    t:Hide()
  end
end
