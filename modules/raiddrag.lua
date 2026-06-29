-- HoryUI :: scale-correct raid-member drag (Blizzard raid panel fix).
--
-- The native raid panel (Friends -> Raid tab) moves a dragged member with
-- `StartMoving()`. That engine call mis-maps the cursor whenever UIParent's
-- effective scale is not 1.0 (e.g. a pfUI / custom uiScale), so the dragged chip
-- drifts by an amount proportional to its screen position -- it follows fine near
-- the left edge but flies off to the right as the window moves right.
--
-- We don't touch any of Blizzard's selection / drop / right-click-menu logic and
-- we make NO assumption about its (compiled, unreadable on Turtle) function or
-- frame names. We only watch Blizzard's own state global `MOVING_RAID_MEMBER`:
-- while a member is being dragged we cancel the broken native move and position
-- the chip ourselves with explicit, scale-corrected cursor tracking. On drop we
-- strip our anchor so Blizzard's slot layout is left clean.

HoryUI:RegisterModule("raiddrag", true, function()
  local GetCursorPosition, UIParent, getglobal = GetCursorPosition, UIParent, getglobal
  local grabX, grabY = 0, 0
  local active = nil               -- the button we're currently driving (nil = idle)

  -- pin b's TOPLEFT under the cursor, holding the original grab offset, in
  -- UIParent space divided by the button's effective scale (the actual fix).
  local function Track(b)
    local s = b:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cx / s - grabX, cy / s - grabY)
  end

  -- a drag just started on b: cancel the native move and capture the grab offset.
  -- Measure from b's *slot* (which never moves) -- StartMoving may already have
  -- displaced the button by the time we notice it a frame later.
  local function Begin(b)
    if b.StopMovingOrSizing then b:StopMovingOrSizing() end
    local s = b:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    local slot = b.slot and getglobal(b.slot)
    local L = slot and slot:GetLeft() or b:GetLeft()
    local T = slot and slot:GetTop()  or b:GetTop()
    if not L then L = cx / s end     -- last resort: snap TOPLEFT to the cursor
    if not T then T = cy / s end
    grabX = cx / s - L
    grabY = cy / s - T
  end

  -- drag ended: our per-frame Track left a TOPLEFT->UIParent point. Blizzard's
  -- RaidGroupFrame_Update re-SetPoints TOPLEFT *without* clearing, so a stray
  -- UIParent anchor would over-constrain the button. Keep only the slot anchor
  -- Blizzard intended (a real group move repositions it authoritatively next).
  local function Finish(b)
    if not b or not b.GetNumPoints then return end
    local keepRel, keepRelPt, keepX, keepY
    for i = 1, b:GetNumPoints() do
      local pt, rel, relPt, x, y = b:GetPoint(i)
      if pt == "TOPLEFT" and rel ~= UIParent then
        keepRel, keepRelPt, keepX, keepY = rel, relPt, x, y
      end
    end
    b:ClearAllPoints()
    if keepRel then
      b:SetPoint("TOPLEFT", keepRel, keepRelPt, keepX, keepY)
    elseif b.slot and getglobal(b.slot) then
      b:SetPoint("TOPLEFT", b.slot, "TOPLEFT", 0, 0)
    end
  end

  local drag = CreateFrame("Frame")
  drag:RegisterEvent("PLAYER_LOGOUT")
  drag:SetScript("OnUpdate", function()
    local cur = MOVING_RAID_MEMBER
    if cur then
      if cur ~= active then active = cur; Begin(cur) end
      Track(cur)
    elseif active then
      Finish(active)
      active = nil
    end
  end)
  drag:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnUpdate", nil)
      this:SetScript("OnEvent", nil)
    end
  end)

  -- status probe: `/run DEFAULT_CHAT_FRAME:AddMessage(tostring(HoryUI._raiddrag))`
  -- prints "watching" only if this module actually loaded (a new .toc line needs a
  -- full client restart, not just /reload).
  HoryUI._raiddrag = "watching"
end)
