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
  m:SetScript("OnDragStart", function() this.target:StartMoving() end)
  m:SetScript("OnDragStop", function()
    this.target:StopMovingOrSizing()
    HoryUI.SavePosition(this.target, this.key)
  end)

  table.insert(HoryUI.panels, { frame = f, mover = m })
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