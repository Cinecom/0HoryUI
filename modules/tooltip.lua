-- HoryUI :: movable tooltip anchor
-- The vendored pfskin only styles the tooltip; its position stays Blizzard's
-- default (bottom-right). This gives the default-anchored GameTooltip a movable
-- home so it drags like any other HoryUI panel when you unlock.
--
-- Dormant while real pfUI is active -- pfUI positions tooltips itself, and the
-- gate (_pfuiActive) is already resolved by the time module loaders run on
-- PLAYER_LOGIN (pfskin/boot.lua sets it at file load).
--
-- Technique mirrors pfUI's tooltip module: on show, re-anchor ANCHOR_NONE
-- tooltips (the ones Blizzard parks bottom-right) to a UIParent frame, picking
-- the attach corner by screen quadrant so the tooltip always grows inward.

HoryUI:RegisterModule("tooltip", true, function()
  if HoryUI._pfuiActive then return end
  local C = HoryUI.color
  local floor = math.floor

  local anchor = CreateFrame("Frame", "HoryUITooltipAnchor", UIParent)
  anchor:SetWidth(140)
  anchor:SetHeight(56)
  HoryUI.RegisterPanel(anchor, "tooltip", "Tooltip", "BOTTOMRIGHT", -220, 200)

  --------------------------------------------------------------------------
  -- Unit tooltips: show the hovered player's guild RANK. The default 1.12
  -- tooltip shows the guild name but not the rank. Like pfUI, we resolve the
  -- hovered unit by matching the tooltip's first line against known unit
  -- tokens (1.12's GameTooltip:GetUnit() is unreliable for world mouseover),
  -- then read GetGuildInfo(unit) -> guild, rankName.
  --------------------------------------------------------------------------
  local RANK_HEX = string.format("|cff%02x%02x%02x",
    floor(C.text2[1] * 255 + 0.5), floor(C.text2[2] * 255 + 0.5), floor(C.text2[3] * 255 + 0.5))

  local function MatchUnit(token, txt)
    if UnitExists(token)
      and (UnitName(token) == txt or (UnitPVPName and UnitPVPName(token) == txt)) then
      return token
    end
  end

  local function HoveredUnit()
    local fs = GameTooltipTextLeft1
    local txt = fs and fs:GetText()
    if not txt or txt == "" then return nil end
    local u = MatchUnit("mouseover", txt) or MatchUnit("target", txt)
           or MatchUnit("player", txt) or MatchUnit("pet", txt)
    if u then return u end
    if GetNumPartyMembers and GetNumPartyMembers() > 0 then
      for i = 1, 4 do u = MatchUnit("party" .. i, txt); if u then return u end end
    end
    if UnitInRaid and UnitInRaid("player") then
      for i = 1, 40 do u = MatchUnit("raid" .. i, txt); if u then return u end end
    end
    return nil
  end

  local function AppendGuildRank()
    local unit = HoveredUnit()
    if not unit or not UnitIsPlayer(unit) then return end
    local guild, rank = GetGuildInfo(unit)
    if not guild then return end
    -- Find the default guild line (vanilla shows "Guild" or "<Guild>", no rank)
    -- and append the rank. plain-text find (4th arg = true) so guild names with
    -- magic chars don't break the match; == 1 means it's the guild line, not a
    -- line that merely mentions the guild.
    for i = 2, GameTooltip:NumLines() do
      local line = getglobal("GameTooltipTextLeft" .. i)
      local t = line and line:GetText()
      if t and (string.find(t, guild, 1, true) == 1
             or string.find(t, "<" .. guild .. ">", 1, true) == 1) then
        if rank and rank ~= "" and not string.find(t, rank, 1, true) then
          line:SetText(t .. "  " .. RANK_HEX .. rank .. "|r")
          GameTooltip:Show()                 -- recalc size (no re-fire of OnShow while shown)
        end
        return
      end
    end
    -- client didn't add a guild line -> add our own (name + rank), green bracket
    local txt = "<" .. guild .. ">"
    if rank and rank ~= "" then txt = txt .. "  " .. RANK_HEX .. rank .. "|r" end
    GameTooltip:AddLine(txt, C.health[1], C.health[2], C.health[3])
    GameTooltip:Show()
  end

  local function AnchorPoint()
    local px, py = UIParent:GetCenter()
    local tx, ty = anchor:GetCenter()
    if not (px and tx) then return "BOTTOMRIGHT" end
    local v = (ty < py) and "BOTTOM" or "TOP"
    local h = (tx < px) and "LEFT" or "RIGHT"
    return v .. h
  end

  -- only default-positioned (ANCHOR_NONE) tooltips move; cursor- and
  -- frame-anchored tooltips stay where their owner put them. No HookScript in
  -- 1.12, so chain the old OnShow by hand (see CLAUDE.md sec.2).
  local old = GameTooltip:GetScript("OnShow")
  GameTooltip:SetScript("OnShow", function()
    if old then old() end
    if this:GetAnchorType() == "ANCHOR_NONE" then
      local p = AnchorPoint()
      this:ClearAllPoints()
      this:SetPoint(p, anchor, p, 0, 0)
    end
    AppendGuildRank()          -- self-bails for non-player / unguilded tooltips
  end)
end)
