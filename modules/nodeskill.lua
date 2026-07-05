-- HoryUI :: node skill -- shows the profession skill level required to gather a
-- world node (mining veins, herbs) in its hover tooltip. 1.12 exposes no API for
-- a node's required skill, so the requirement is looked up in the static
-- HoryUI.nodeSkills table (data/nodeskills.lua). The line is colour-coded with
-- WoW's gathering skill-up tiers vs the player's own skill (SkillColor):
-- red = can't gather (or profession not learned), then orange / yellow / green /
-- grey by margin -- the same tiers the trade-skill window uses. ONE function
-- colours BOTH the world-node line and the minimap-pin line, so they always read
-- identically.
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
  -- WoW's gathering skill-up colour tiers, vs your own skill:
  --   red    = below the requirement (can't gather; "not learned" reads red too)
  --   orange = req .. +24        yellow = +25 .. +49
  --   green  = +50 .. +99        grey   = +100 and up (trivial, no skill-up)
  -- The same tiering the trade-skill window / Gatherer use. Red matches
  -- RED_FONT_COLOR -- the exact red on the game's native "Requires" line.
  ----------------------------------------------------------------------------
  local function SkillColor(prof, req)
    local have = skill[prof]
    if not have or have < req then return 1.00, 0.10, 0.10 end   -- red
    local diff = have - req
    if diff < 25 then return 1.00, 0.50, 0.25 end                -- orange
    if diff < 50 then return 1.00, 1.00, 0.00 end                -- yellow
    if diff < 100 then return 0.25, 0.75, 0.25 end               -- green
    return 0.50, 0.50, 0.50                                      -- grey
  end

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

    local r, g, b = SkillColor(prof, req)

    for i = 2, GameTooltip:NumLines() do
      local line = getglobal("GameTooltipTextLeft" .. i)
      local t = line and line:GetText()
      if t and string.find(t, needle, 1, true) then
        if not string.find(t, tag, 1, true) then
          line:SetText(t .. " " .. tag)        -- fold the number into the existing line
        end
        -- recolour the existing line too (the game's native red line, or our own
        -- from an earlier show) so world node and minimap pin ALWAYS use the same
        -- SkillColor tier -- this is what keeps the two readouts consistent.
        line:SetTextColor(r, g, b)
        GameTooltip:Show()
        return
      end
    end

    -- No requires line yet (you meet it, or it's a minimap pin with none) -> add
    -- our own, in the same SkillColor tier.
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
