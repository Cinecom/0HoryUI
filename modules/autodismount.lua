-- HoryUI :: autodismount -- when a skill can't be used because you're mounted,
-- cancel the mount buff so the ability goes through on the next press.
--
-- Mechanism (verified against pfUI modules/autoshift.lua): there is no reliable
-- IsMounted() in 1.12, so this is error-driven, not a hook on every cast. When
-- you use a skill while mounted the client fires UI_ERROR_MESSAGE with a "can't
-- do that mounted" text (SPELL_FAILED_NOT_MOUNTED / ERR_ATTACK_MOUNTED / ...).
-- On one of those we scan the player buffs, find the mount buff by its tooltip
-- text ("Increases speed by X%" + the Turtle riding-skill wording) and
-- CancelPlayerBuff() it -- that dismounts. Rogue-only, so pfUI's shapeshift /
-- stance handling is dropped: mounts only. Dormant while real pfUI is active,
-- since its autoshift module already does this.

HoryUI:RegisterModule("autodismount", true, function()
  if HoryUI._pfuiActive then return end          -- pfUI's autoshift handles it

  -- Errors that mean "you tried to do this while mounted". Guard each global so
  -- a constant missing on this client just isn't watched (a nil never == arg1).
  local errors = {}
  local function AddErr(s) if s then errors[s] = true end end
  AddErr(SPELL_FAILED_NOT_MOUNTED)
  AddErr(ERR_ATTACK_MOUNTED)
  AddErr(ERR_TAXIPLAYERALREADYMOUNTED)
  AddErr(ERR_NOT_WHILE_MOUNTED)

  -- A mount reads as a movement-speed buff; these tooltip patterns cover enUS
  -- plus Turtle's riding-skill wording (lifted verbatim from pfUI autoshift so
  -- they stay correct). string.find with these matches the mount aura's tooltip.
  local mounts = {
    "^Increases speed by (.+)%%",
    "speed based on", "Slow and steady...", "Riding",
  }

  -- Hidden, WorldFrame-owned buff-scanning tooltip (same technique as
  -- modules/durability.lua). Reused for every buff slot.
  local scan = CreateFrame("GameTooltip", "HoryUIDismountScan", UIParent, "GameTooltipTemplate")

  local function BuffIsMount(i)
    scan:SetOwner(WorldFrame, "ANCHOR_NONE")
    scan:ClearLines()
    scan:SetPlayerBuff(i)
    for line = 1, scan:NumLines() do
      local fs = getglobal("HoryUIDismountScanTextLeft" .. line)
      local txt = fs and fs:GetText()
      if txt then
        for _, pat in pairs(mounts) do
          if string.find(txt, pat) then return true end
        end
      end
    end
    return false
  end

  local f = CreateFrame("Frame")
  f:RegisterEvent("UI_ERROR_MESSAGE")
  f:RegisterEvent("PLAYER_LOGOUT")
  f:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      return
    end
    if not errors[arg1] then return end
    -- buff slots are 0..31 in 1.12 (pfUI loops the same range for SetPlayerBuff)
    for i = 0, 31 do
      if BuffIsMount(i) then
        CancelPlayerBuff(i)
        return
      end
    end
  end)
end)
