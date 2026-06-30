-- HoryUI :: movable panels + mover overlays + lock / show-all
-- Panels register here instead of being directly draggable. A translucent
-- "mover" overlay (shown only when unlocked) handles repositioning, so panels
-- never steal mouse clicks during normal play.

HoryUI.panels = HoryUI.panels or {}
HoryUI.refreshers = HoryUI.refreshers or {}
HoryUI.locked = true
HoryUI.showAll = false
-- grid overlay
HoryUI.gridShown = false
HoryUI.gridSpacing = 24
HoryUI.snapEnabled = false        -- magnetic snap while dragging (set by LoadConfig)

local floor = math.floor
local GetCursorPosition, UIParent = GetCursorPosition, UIParent
local SNAP_DIST = 10              -- magnetic pull radius, in px

-- keep the candidate nearest `ref` (running best/bestD; no per-frame allocations)
local function consider(best, bestD, c, ref)
  local d = c - ref
  if d < 0 then d = -d end
  if d < bestD then return c, d end
  return best, bestD
end

-- ALL snapping is done in UIParent-local coordinates so it lines up with the
-- on-screen grid even when a panel (e.g. the scaled minimap) has a different
-- effective scale than UIParent -- snapping in a frame's own (scaled) space made
-- it land beside the grid line, not on it. Every edge is normalised to UIParent
-- space via GetEffectiveScale()/Su (the same trick Bongos' Infield uses).

-- snap candidates come from the panels AND any registered extra targets (the
-- Bongos bars register themselves, so panels and bars snap to each other -- this
-- is what replaces Bongos' own removed "sticky bars" feature).
HoryUI.snapTargets = HoryUI.snapTargets or {}
HoryUI.selection   = HoryUI.selection or {}   -- panel entries in the active multi-select
local groupDrag = false                        -- true while moving a selection as a rigid group

-- a candidate is skipped if it's the dragged frame, hidden, or part of the moving group
local function skipTarget(o, f)
  if o == f or not o:IsShown() then return true end
  if groupDrag and HoryUI.IsSelected(o) then return true end
  return false
end

local function tryX(o, f, Su, leftUI, wUI, best, bestD)
  if skipTarget(o, f) then return best, bestD end
  local ol, orr = o:GetLeft(), o:GetRight()
  if not (ol and orr) then return best, bestD end
  local r = o:GetEffectiveScale() / Su                 -- their space -> UIParent space
  ol = ol * r; orr = orr * r
  best, bestD = consider(best, bestD, ol,        leftUI)   -- our left  -> their left
  best, bestD = consider(best, bestD, orr,       leftUI)   -- our left  -> their right
  best, bestD = consider(best, bestD, ol - wUI,  leftUI)   -- our right -> their left
  best, bestD = consider(best, bestD, orr - wUI, leftUI)   -- our right -> their right
  return best, bestD
end

local function tryY(o, f, Su, topUI, hUI, best, bestD)
  if skipTarget(o, f) then return best, bestD end
  local ot, ob = o:GetTop(), o:GetBottom()
  if not (ot and ob) then return best, bestD end
  local r = o:GetEffectiveScale() / Su
  ot = ot * r; ob = ob * r
  best, bestD = consider(best, bestD, ot,        topUI)   -- our top    -> their top
  best, bestD = consider(best, bestD, ob,        topUI)   -- our top    -> their bottom
  best, bestD = consider(best, bestD, ot + hUI,  topUI)   -- our bottom -> their top
  best, bestD = consider(best, bestD, ob + hUI,  topUI)   -- our bottom -> their bottom
  return best, bestD
end

-- snap a LEFT edge (width wUI, all UIParent-local) to grid lines + every other frame
local function SnapX(leftUI, wUI, f, Su)
  local best, bestD = leftUI, SNAP_DIST + 1
  if HoryUI.gridShown then
    local sp = HoryUI.gridSpacing
    if sp and sp > 0 then
      best, bestD = consider(best, bestD, floor(leftUI / sp + 0.5) * sp, leftUI)
      best, bestD = consider(best, bestD, floor((leftUI + wUI) / sp + 0.5) * sp - wUI, leftUI)
    end
  end
  local panels = HoryUI.panels
  for i = 1, table.getn(panels) do best, bestD = tryX(panels[i].frame, f, Su, leftUI, wUI, best, bestD) end
  local extra = HoryUI.snapTargets
  for i = 1, table.getn(extra) do best, bestD = tryX(extra[i], f, Su, leftUI, wUI, best, bestD) end
  if bestD <= SNAP_DIST then return best end
  return leftUI
end

-- snap a TOP edge (height hUI, from screen bottom, all UIParent-local) to grid + frames
local function SnapY(topUI, hUI, f, Su)
  local best, bestD = topUI, SNAP_DIST + 1
  if HoryUI.gridShown then
    local sp = HoryUI.gridSpacing
    if sp and sp > 0 then
      local H = UIParent:GetHeight()
      best, bestD = consider(best, bestD, H - floor((H - topUI) / sp + 0.5) * sp, topUI)
      best, bestD = consider(best, bestD, H - floor((H - (topUI - hUI)) / sp + 0.5) * sp + hUI, topUI)
    end
  end
  local panels = HoryUI.panels
  for i = 1, table.getn(panels) do best, bestD = tryY(panels[i].frame, f, Su, topUI, hUI, best, bestD) end
  local extra = HoryUI.snapTargets
  for i = 1, table.getn(extra) do best, bestD = tryY(extra[i], f, Su, topUI, hUI, best, bestD) end
  if bestD <= SNAP_DIST then return best end
  return topUI
end

-- frame edge <-> UIParent-local conversions -------------------------------------
local function FrameEdgeUI(f, Su)
  local s = f:GetEffectiveScale() / Su
  return (f:GetLeft() or 0) * s, (f:GetTop() or 0) * s
end

local function SetFrameEdgeUI(f, leftUI, topUI, Su)
  local k = Su / f:GetEffectiveScale()
  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
    (leftUI - UIParent:GetLeft()) * k, (topUI - UIParent:GetBottom()) * k)
end

local function SnapEdge(f, leftUI, topUI, Su)
  if not HoryUI.snapEnabled then return leftUI, topUI end
  local Sf = f:GetEffectiveScale()
  return SnapX(leftUI, f:GetWidth() * Sf / Su, f, Su),
         SnapY(topUI,  f:GetHeight() * Sf / Su, f, Su)
end

-- Reusable single-frame snap drag, used by the panel movers AND the Bongos bars.
-- Begin on mouse-down, Move each frame; the caller saves the position on stop.
function HoryUI.RegisterSnapTarget(frame)
  table.insert(HoryUI.snapTargets, frame)
end

function HoryUI.SnapDragBegin(frame)
  local Su = UIParent:GetEffectiveScale()
  local cx, cy = GetCursorPosition()
  local fl, ft = FrameEdgeUI(frame, Su)
  frame._snGrabX = cx / Su - fl
  frame._snGrabY = cy / Su - ft
end

function HoryUI.SnapDragMove(frame)
  local Su = UIParent:GetEffectiveScale()
  local cx, cy = GetCursorPosition()
  local leftUI = cx / Su - frame._snGrabX
  local topUI  = cy / Su - frame._snGrabY
  leftUI, topUI = SnapEdge(frame, leftUI, topUI, Su)
  SetFrameEdgeUI(frame, leftUI, topUI, Su)
end

-- multi-selection ---------------------------------------------------------------
function HoryUI.IsSelected(frame)
  for i = 1, table.getn(HoryUI.selection) do
    if HoryUI.selection[i].frame == frame then return true end
  end
  return false
end

local function SetMoverSelected(e, on)
  local a = on and HoryUI.color.accent_hi or HoryUI.color.accent
  e.mover:SetBackdropBorderColor(a[1], a[2], a[3], 1)
  e.mover:SetBackdropColor(a[1], a[2], a[3], on and 0.55 or 0.35)
end

function HoryUI.ClearSelection()
  for i = 1, table.getn(HoryUI.selection) do SetMoverSelected(HoryUI.selection[i], false) end
  HoryUI.selection = {}
end

local function AddToSelection(e)
  if HoryUI.IsSelected(e.frame) then return end
  table.insert(HoryUI.selection, e)
  SetMoverSelected(e, true)
end

-- drag handlers (`this` = the mover) --------------------------------------------
local groupStartX, groupStartY     -- cursor at group-drag start, UIParent-local

local function SingleMoverUpdate()
  HoryUI.SnapDragMove(this.target)
end

-- move the whole selection rigidly: snap the dragged (primary) frame, then shift
-- every selected frame by the same delta + the primary's snap correction
local function GroupMoverUpdate()
  local f = this.target
  local Su = UIParent:GetEffectiveScale()
  local cx, cy = GetCursorPosition()
  local dx = cx / Su - groupStartX
  local dy = cy / Su - groupStartY
  local sel = HoryUI.selection
  local pl, pt
  for i = 1, table.getn(sel) do
    if sel[i].frame == f then pl = sel[i].gsl; pt = sel[i].gst; break end
  end
  local rawL, rawT = pl + dx, pt + dy
  local snL, snT = SnapEdge(f, rawL, rawT, Su)
  local corrX, corrY = snL - rawL, snT - rawT
  for i = 1, table.getn(sel) do
    local e = sel[i]
    SetFrameEdgeUI(e.frame, e.gsl + dx + corrX, e.gst + dy + corrY, Su)
  end
end

-- marquee (click-drag in empty space to rubber-band select panels) --------------
local marquee
local function SelectInRect(left, bottom, right, top, Su)
  HoryUI.ClearSelection()
  local panels = HoryUI.panels
  for i = 1, table.getn(panels) do
    local e = panels[i]
    if e.frame:IsShown() and e.frame:GetLeft() then
      local s = e.frame:GetEffectiveScale() / Su
      local fl = e.frame:GetLeft()  * s
      local fr = e.frame:GetRight() * s
      local ft = e.frame:GetTop()   * s
      local fb = e.frame:GetBottom() * s
      if not (fr < left or fl > right or fb > top or ft < bottom) then   -- overlap?
        AddToSelection(e)
      end
    end
  end
end

local function EnsureMarquee()
  if marquee then return end
  marquee = CreateFrame("Frame", nil, UIParent)
  marquee:SetAllPoints(UIParent)
  marquee:SetFrameStrata("HIGH")          -- below the movers + bar handles, above the world
  marquee:EnableMouse(true)
  marquee:RegisterForDrag("LeftButton")
  marquee:Hide()

  local box = CreateFrame("Frame", nil, marquee)
  box:SetFrameStrata("DIALOG")
  box:SetBackdrop({ bgFile = HoryUI.tex.white, edgeFile = HoryUI.tex.white,
    tile = false, tileSize = 0, edgeSize = 1 })
  local a = HoryUI.color.accent_hi
  box:SetBackdropColor(a[1], a[2], a[3], 0.12)
  box:SetBackdropBorderColor(a[1], a[2], a[3], 0.9)
  box:Hide()

  local x0, y0
  local function BoxBounds()
    local Su = UIParent:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    local x1, y1 = cx / Su, cy / Su
    local l = (x0 < x1) and x0 or x1
    local r = (x0 < x1) and x1 or x0
    local b = (y0 < y1) and y0 or y1
    local t = (y0 < y1) and y1 or y0
    box:ClearAllPoints()
    box:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", l, b)
    box:SetWidth((r - l > 1) and (r - l) or 1)
    box:SetHeight((t - b > 1) and (t - b) or 1)
    return l, b, r, t
  end

  marquee:SetScript("OnMouseDown", function()        -- bare left-click on empty space clears
    if arg1 == "LeftButton" then HoryUI.ClearSelection() end
  end)
  marquee:SetScript("OnDragStart", function()
    local Su = UIParent:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    x0, y0 = cx / Su, cy / Su
    HoryUI.ClearSelection()
    box:Show()
    this:SetScript("OnUpdate", BoxBounds)
  end)
  marquee:SetScript("OnDragStop", function()
    this:SetScript("OnUpdate", nil)
    local l, b, r, t = BoxBounds()
    box:Hide()
    SelectInRect(l, b, r, t, UIParent:GetEffectiveScale())
  end)
end

function HoryUI.SetSnap(v)
  HoryUI.snapEnabled = v and true or false
  HoryUIDB.snapEnabled = HoryUI.snapEnabled
end

function HoryUI.AddRefresher(fn)
  table.insert(HoryUI.refreshers, fn)
end

function HoryUI.Refresh()
  for i = 1, table.getn(HoryUI.refreshers) do
    pcall(HoryUI.refreshers[i])
  end
end

function HoryUI.RegisterPanel(f, key, label, dpoint, dx, dy)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  HoryUI.RestorePosition(f, key, dpoint, dx, dy)

  local m = CreateFrame("Frame", nil, UIParent)
  m:SetAllPoints(f)
  m:SetFrameStrata("FULLSCREEN_DIALOG")
  m:EnableMouse(true)
  m:RegisterForDrag("LeftButton")
  m:SetClampedToScreen(true)
  m:Hide()

  m:SetBackdrop({
    bgFile = HoryUI.tex.white,
    edgeFile = HoryUI.tex.white,
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
  })
  local a = HoryUI.color.accent
  m:SetBackdropColor(a[1], a[2], a[3], 0.35)
  m:SetBackdropBorderColor(a[1], a[2], a[3], 1)

  m.label = m:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(m.label, HoryUI.font.normal, 11, "OUTLINE")
  m.label:SetPoint("CENTER", m, "CENTER", 0, 0)
  m.label:SetText(label or key)
  m.label:SetTextColor(1, 1, 1, 1)

  m.target = f
  m.key = key
  -- manual, scale-correct drag so snapping can intervene mid-move (StartMoving
  -- can't be intercepted). Dragging a mover that's part of a multi-selection moves
  -- the whole group; dragging any other mover drops the selection and moves one.
  m:SetScript("OnDragStart", function()
    local t = this.target
    local sel = HoryUI.selection
    if HoryUI.IsSelected(t) and table.getn(sel) > 1 then
      groupDrag = true
      local Su = UIParent:GetEffectiveScale()
      local cx, cy = GetCursorPosition()
      groupStartX, groupStartY = cx / Su, cy / Su
      for i = 1, table.getn(sel) do sel[i].gsl, sel[i].gst = FrameEdgeUI(sel[i].frame, Su) end
      this:SetScript("OnUpdate", GroupMoverUpdate)
    else
      HoryUI.ClearSelection()
      groupDrag = false
      HoryUI.SnapDragBegin(t)
      this:SetScript("OnUpdate", SingleMoverUpdate)
    end
  end)
  m:SetScript("OnDragStop", function()
    this:SetScript("OnUpdate", nil)
    if groupDrag then
      local sel = HoryUI.selection
      for i = 1, table.getn(sel) do HoryUI.SavePosition(sel[i].frame, sel[i].key) end
      groupDrag = false
    else
      HoryUI.SavePosition(this.target, this.key)
    end
  end)

  table.insert(HoryUI.panels, { frame = f, mover = m, key = key })
end

function HoryUI.SetLocked(v)
  HoryUI.locked = v and true or false
  -- unlocking also reveals every panel (with placeholders) for positioning;
  -- locking hides the extras again
  HoryUI.showAll = not HoryUI.locked
  for i = 1, table.getn(HoryUI.panels) do
    if HoryUI.locked then
      HoryUI.panels[i].mover:Hide()
    else
      HoryUI.panels[i].mover:Show()
    end
  end
  -- the marquee selector is only live while unlocked (positioning mode)
  if HoryUI.locked then
    if marquee then marquee:Hide() end
    HoryUI.ClearSelection()
  else
    EnsureMarquee()
    marquee:Show()
  end
  HoryUI.Refresh()
end

function HoryUI.SetShowGrid(v)
  HoryUI.gridShown = v and true or false
  HoryUIDB.gridShown = HoryUI.gridShown
  if HoryUI.gridShown then
    if HoryUI.gridFrame then HoryUI.gridFrame:Hide(); HoryUI.gridFrame = nil end
    HoryUI.gridFrame = CreateFrame("Frame", nil, UIParent)
    HoryUI.gridFrame:SetAllPoints(UIParent)
    HoryUI.gridFrame:SetFrameStrata("MEDIUM")
    local w = HoryUI.gridFrame:GetRight() - HoryUI.gridFrame:GetLeft()
    local h = HoryUI.gridFrame:GetTop() - HoryUI.gridFrame:GetBottom()
    local s = HoryUI.gridSpacing
    local a = HoryUI.color.accent
    local alpha = 0.5
    for x = 0, w, s do
      local line = CreateFrame("Frame", nil, HoryUI.gridFrame)
      line:SetWidth(1)
      line:SetHeight(h)
      line:SetPoint("TOPLEFT", HoryUI.gridFrame, "TOPLEFT", x, 0)
      line:SetBackdrop({
        bgFile = HoryUI.tex.white,
        edgeFile = nil,
        tile = false, tileSize = 0, edgeSize = 0,
      })
      line:SetBackdropColor(a[1], a[2], a[3], alpha)
    end
    for y = 0, h, s do
      local line = CreateFrame("Frame", nil, HoryUI.gridFrame)
      line:SetWidth(w)
      line:SetHeight(1)
      line:SetPoint("TOPLEFT", HoryUI.gridFrame, "TOPLEFT", 0, -y)
      line:SetBackdrop({
        bgFile = HoryUI.tex.white,
        edgeFile = nil,
        tile = false, tileSize = 0, edgeSize = 0,
      })
      line:SetBackdropColor(a[1], a[2], a[3], alpha)
    end
    -- emphasised centre cross: thicker + brighter, marks exact screen centre
    local ahi = HoryUI.color.accent_hi
    local function CenterLine(lw, lh)
      local ln = CreateFrame("Frame", nil, HoryUI.gridFrame)
      ln:SetWidth(lw); ln:SetHeight(lh)
      ln:SetPoint("CENTER", HoryUI.gridFrame, "CENTER", 0, 0)
      ln:SetBackdrop({ bgFile = HoryUI.tex.white, edgeFile = nil, tile = false, tileSize = 0, edgeSize = 0 })
      ln:SetBackdropColor(ahi[1], ahi[2], ahi[3], 0.9)
    end
    CenterLine(3, h)   -- vertical middle line
    CenterLine(w, 3)   -- horizontal middle line
    HoryUI.gridFrame:Show()
  else
    if HoryUI.gridFrame then
      HoryUI.gridFrame:Hide()
    end
  end
end

function HoryUI.HideGridVisual()
  if HoryUI.gridFrame then HoryUI.gridFrame:Hide() end
end

function HoryUI.ShowGridVisual()
  if HoryUI.gridShown then HoryUI.SetShowGrid(true) end
end