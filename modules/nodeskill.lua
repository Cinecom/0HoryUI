-- HoryUI :: node skill -- shows the profession skill level required to gather a
-- world node (mining veins, herbs) in its hover tooltip. 1.12 exposes no API for
-- a node's required skill, so the requirement is looked up in the static
-- HoryUI.nodeSkills table (data/nodeskills.lua). The line is colour-coded by
-- whether the player's own skill meets it (green = can gather, red = too low,
-- muted = profession not learned).
--
-- Technique mirrors modules/tooltip.lua's guild-rank append: world mouseover
-- tooltips (nodes included) go through GameTooltip, and 1.12's
-- GameTooltip:GetUnit() is unreliable there, so we read the first line's text
-- (GameTooltipTextLeft1) and match it against the table. The append runs on
-- OnShow and is idempotent (it folds the number into an existing "Requires
-- <prof>" line rather than tracking state), so repeated shows never double up.
--
-- NOT gated on pfUI: the requirement is useful whether HoryUI or pfUI/pfskin
-- owns the tooltip look, so we just chain GameTooltip's current OnShow.

HoryUI:RegisterModule("nodeskill", true, function()
  local data = HoryUI.nodeSkills
  if not data then return end                 -- data file missing -> nothing to do
  local C = HoryUI.color

  ----------------------------------------------------------------------------
  -- player skill cache (profession name -> current rank), refreshed on change
  ----------------------------------------------------------------------------
  local skill = {}
  local function RefreshSkills()
    for i = 1, GetNumSkillLines() do
      local name, header, _, rank = GetSkillLineInfo(i)
      if not header and name then skill[name] = rank end
    end
  end

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("SKILL_LINES_CHANGED")
  ev:RegisterEvent("PLAYER_LOGOUT")
  ev:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      return
    end
    RefreshSkills()
  end)
  RefreshSkills()

  ----------------------------------------------------------------------------
  -- which tooltips may get the requirement line
  ----------------------------------------------------------------------------
  -- A world node under the cursor is parked at ANCHOR_NONE (bottom-right); a
  -- minimap gathering pin (pfQuest etc.) is a frame parented to Minimap, so the
  -- frame under the cursor (GetMouseFocus) walks up to Minimap. We allow both.
  -- (1.12 has no GameTooltip:GetOwner(); the frame-lineage check is more reliable
  -- than a MouseIsOver rect test against HoryUI's rescaled square minimap.)
  -- Everything else -- bag/merchant item tooltips, e.g. the herb ITEM whose name
  -- matches the node -- is anchored to its button, off the minimap, and excluded,
  -- so it never wrongly shows "Requires ...".
  local function OverMinimap()
    local f = GetMouseFocus and GetMouseFocus()
    while f do
      if f == Minimap then return true end
      if not f.GetParent then break end
      f = f:GetParent()
    end
    if Minimap and MouseIsOver and MouseIsOver(Minimap) then return true end
    return false
  end
  local function NodeTipAllowed()
    return GameTooltip:GetAnchorType() == "ANCHOR_NONE" or OverMinimap()
  end

  ----------------------------------------------------------------------------
  -- append the requirement to a node tooltip
  ----------------------------------------------------------------------------
  -- No per-show guard: instead the scan below is idempotent. It matches the line
  -- "Requires <prof>" -- which is BOTH the game's own native requires line (world
  -- node you can't gather) AND our own already-added line -- so on any re-show it
  -- finds an existing line and either folds the number in once or no-ops. (An
  -- earlier `horyNodeFor` guard blocked re-appends after the tooltip rebuilt
  -- without firing OnHide, leaving the bare "Requires Mining" with no number.)
  -- Matching "Requires <prof>" and not just "<prof>" avoids touching unrelated
  -- lines like pfQuest's "Type: Mining Vein".
  local function AppendNodeSkill()
    if not NodeTipAllowed() then return end
    local fs = GameTooltipTextLeft1
    local txt = fs and fs:GetText()
    if not txt or txt == "" then return end
    local info = data[txt]
    if not info then return end               -- not a known node -> leave alone

    local prof, req = info[1], info[2]
    local needle = "Requires " .. prof        -- native line + our own both contain this
    local tag = "(" .. req .. ")"

    for i = 2, GameTooltip:NumLines() do
      local line = getglobal("GameTooltipTextLeft" .. i)
      local t = line and line:GetText()
      if t and string.find(t, needle, 1, true) then
        if not string.find(t, tag, 1, true) then
          line:SetText(t .. " " .. tag)        -- fold the number into the existing line
          GameTooltip:Show()
        end
        return                                 -- already has (or now has) the number
      end
    end

    -- No requires line yet (you meet it, or it's a minimap pin with none) -> add
    -- our own. Colour to MATCH the world node exactly: green (C.health, same as
    -- the world can-gather line) when you meet it, else the game's own requirement
    -- red -- RED_FONT_COLOR is the precise red Blizzard puts on the world node's
    -- native "Requires" line, so world and minimap read identically (and, like the
    -- world node, "not learned" reads red too, not a separate muted tier).
    local have = skill[prof]
    local r, g, b
    if have and have >= req then
      r, g, b = C.health[1], C.health[2], C.health[3]
    else
      local red = RED_FONT_COLOR or { r = 1, g = 0.1, b = 0.1 }
      r, g, b = red.r, red.g, red.b
    end
    GameTooltip:AddLine(needle .. " " .. tag, r, g, b)
    GameTooltip:Show()                        -- recalc size for the new line
  end

  ----------------------------------------------------------------------------
  -- chain GameTooltip's OnShow / OnHide (no HookScript in 1.12; see CLAUDE.md 2)
  ----------------------------------------------------------------------------
  local oldShow = GameTooltip:GetScript("OnShow")
  GameTooltip:SetScript("OnShow", function()
    if oldShow then oldShow() end
    AppendNodeSkill()                         -- self-bails for non-node tooltips
  end)
end)
