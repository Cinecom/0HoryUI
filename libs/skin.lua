-- HoryUI :: Blizzard frame skinning toolkit (Garnet)
-- Minimal equivalents of pfUI's skin helpers (technique borrowed, see CLAUDE.md
-- §0B). Reskin modules reuse these so the whole Blizzard UI keeps one look.
-- This file grows only as panels need new helpers -- no speculative primitives.

local getn = table.getn

-- a small garnet glyph centred on a button (the HoryUI idiom for the close "x",
-- scroll arrows, dropdown caret -- one tiny on-brand character instead of bronze
-- arrow art). Idempotent per button.
local function AddGlyph(btn, char, size)
  if not btn or btn.horyGlyph then return end
  local g = btn:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(g, HoryUI.font.normal, size or 11, "OUTLINE")
  g:SetPoint("CENTER", btn, "CENTER", 0, 0)
  g:SetText(char)
  local a = HoryUI.color.accent_hi
  g:SetTextColor(a[1], a[2], a[3])
  btn.horyGlyph = g
  return g
end

-- run fn now if the (optional) on-demand Blizzard addon is already loaded, else
-- when it loads. Pass addon = nil for always-present FrameXML frames.
function HoryUI.OnBlizzardLoaded(addon, fn)
  if not addon or (IsAddOnLoaded and IsAddOnLoaded(addon)) then
    fn()
    return
  end
  local w = CreateFrame("Frame")
  w:RegisterEvent("ADDON_LOADED")
  w:SetScript("OnEvent", function()
    if arg1 == addon then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      fn()
    end
  end)
end

-- Remove a frame's own texture regions (the Blizzard border/bevel art).
-- We `:Hide()` each region, not just `SetTexture(nil)` -- the panels re-apply
-- their art (and portraits) in OnShow/OnMouseDown via SetTexture, and Hide()
-- persists across that, whereas a nil texture gets overwritten. `rehook` also
-- re-strips on the frame's OnShow for the cases that re-Show() regions.
-- FontStrings and child *frames* are left untouched.
-- `layer` (optional): only strip textures on that draw layer (e.g. "BACKGROUND"),
-- matching pfUI's StripTextures(frame, hide, layer) -- used to drop an edit box's
-- border art while keeping a higher-layer icon (money coins, etc.).
function HoryUI.StripTextures(frame, rehook, layer)
  if not frame or not frame.GetRegions then return end
  local function strip()
    local regions = { frame:GetRegions() }
    for i = 1, getn(regions) do
      local r = regions[i]
      if r and r.GetObjectType and r:GetObjectType() == "Texture" then
        if not layer or (r.GetDrawLayer and r:GetDrawLayer() == layer) then
          r:SetTexture(nil)
          if r.Hide then r:Hide() end
        end
      end
    end
  end
  strip()
  if rehook and frame.SetScript and not frame.horyReStrip then
    frame.horyReStrip = true
    local old = frame:GetScript("OnShow")
    frame:SetScript("OnShow", function()
      if old then old() end
      strip()
    end)
  end
end

-- strip a Blizzard frame and give it the flat HoryUI backdrop. Frames carry
-- their border art as texture regions AND/OR a frame backdrop -- clear both, and
-- re-strip on show. NOTE: for panels whose border lives on a *child* content
-- frame (e.g. CharacterFrame's border is on PaperDollFrame), the skin module
-- must also StripTextures(thatChild, true) -- SkinPanel only touches `frame`.
function HoryUI.SkinPanel(frame, inset)
  if not frame or frame.horyPanel then return end
  frame.horyPanel = true
  HoryUI.StripTextures(frame, true)
  if frame.SetBackdrop then frame:SetBackdrop(nil) end
  HoryUI.CreateBackdrop(frame, inset)
end

-- reskin a Blizzard button: drop its art, flat backdrop, garnet hover (existing
-- OnEnter/OnLeave -- e.g. tooltips -- are preserved). `icon` (optional) is a
-- texture region to KEEP (repair / model-rotate / action buttons whose glyph is a
-- texture) -- it survives the strip, gets trimmed and framed by the backdrop.
function HoryUI.SkinButton(btn, icon)
  if not btn or btn.horyBtn then return end
  btn.horyBtn = true
  if btn.SetNormalTexture then btn:SetNormalTexture("") end
  if btn.SetPushedTexture then btn:SetPushedTexture("") end
  if btn.SetDisabledTexture then btn:SetDisabledTexture("") end
  if btn.SetHighlightTexture then btn:SetHighlightTexture("") end
  -- strip the button's own border/bevel art. With an icon, strip selectively so
  -- the icon texture isn't nil'd + hidden along with the chrome.
  if icon then
    local regions = { btn:GetRegions() }
    for i = 1, getn(regions) do
      local r = regions[i]
      if r ~= icon and r.GetObjectType and r:GetObjectType() == "Texture" then
        r:SetTexture(nil); if r.Hide then r:Hide() end
      end
    end
  else
    HoryUI.StripTextures(btn)
  end
  HoryUI.CreateBackdrop(btn)

  if icon then
    icon:Show()
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3, 3)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end

  -- primary-tier label (Blizzard buttons ship a yellow/gold font colour)
  local fs = btn.GetFontString and btn:GetFontString()
  if fs then local t = HoryUI.color.text; fs:SetTextColor(t[1], t[2], t[3]) end

  local a = HoryUI.color.accent_hi
  local onEnter, onLeave = btn:GetScript("OnEnter"), btn:GetScript("OnLeave")
  btn:SetScript("OnEnter", function()
    if this.backdrop then this.backdrop:SetBackdropBorderColor(a[1], a[2], a[3], 1) end
    if onEnter then onEnter() end
  end)
  btn:SetScript("OnLeave", function()
    if this.backdrop then this.backdrop:SetBackdropBorderColor(0, 0, 0, 1) end
    if onLeave then onLeave() end
  end)
end

-- a Blizzard close button (the X) -> small flat square with a HoryUI "x" glyph
function HoryUI.SkinCloseButton(btn)
  if not btn or btn.horyClose then return end
  btn.horyClose = true
  HoryUI.SkinButton(btn)            -- strip + backdrop + garnet hover
  btn:SetWidth(18); btn:SetHeight(18)
  local x = btn:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(x, HoryUI.font.normal, 13, "OUTLINE")
  x:SetPoint("CENTER", btn, "CENTER", 0, 0)
  x:SetText("x")
  local t2 = HoryUI.color.text2
  x:SetTextColor(t2[1], t2[2], t2[3])
end

-- a standalone arrow button (page prev/next, list scroll arrows used outside a
-- scrollbar): flat backdrop + a garnet caret glyph for the direction. pfUI uses
-- arrow art here; HoryUI uses the same tiny on-brand glyph idiom as the close "x".
local ARROW_GLYPH = { up = "^", down = "v", left = "<", right = ">" }
function HoryUI.SkinArrowButton(btn, dir, size)
  if not btn or btn.horyArrowBtn then return end
  btn.horyArrowBtn = true
  if btn.SetNormalTexture then btn:SetNormalTexture("") end
  if btn.SetPushedTexture then btn:SetPushedTexture("") end
  if btn.SetDisabledTexture then btn:SetDisabledTexture("") end
  if btn.SetHighlightTexture then btn:SetHighlightTexture("") end
  HoryUI.StripTextures(btn)
  HoryUI.CreateBackdrop(btn)
  if size then btn:SetWidth(size); btn:SetHeight(size) end
  AddGlyph(btn, ARROW_GLYPH[dir] or ">", 10)
end

-- a Blizzard +/- collapse/expand toggle (quest-log zone headers, reputation /
-- skill / faction headers): swap the bronze plus/minus art for a flat box with a
-- garnet +/- glyph, kept in sync by intercepting SetNormalTexture -- Blizzard
-- swaps the button's texture to a *PlusButton / *MinusButton to signal its state,
-- so we read that name on every call instead of chasing the *_Update.
function HoryUI.SkinCollapseButton(btn, all)
  if not btn or btn.horyCollapse then return end
  btn.horyCollapse = true
  if btn.SetHighlightTexture then btn:SetHighlightTexture("") end

  -- a small box + glyph pinned to the LEFT of the (often full-width) row, where
  -- the bronze +/- art sat. The same row is reused for plain quests AND zone
  -- headers, so the box is HIDDEN when Blizzard clears the texture (plain row) and
  -- shown with +/- when it sets a Plus/MinusButton texture (collapsible header).
  local sz = all and 14 or 12
  local box = CreateFrame("Frame", nil, btn)
  box:SetWidth(sz); box:SetHeight(sz)
  box:SetPoint("LEFT", btn, "LEFT", 2, 0)
  HoryUI.CreateBackdrop(box)
  local g = box:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(g, HoryUI.font.normal, all and 13 or 11, "OUTLINE")
  g:SetPoint("CENTER", box, "CENTER", 0, 0)
  local a = HoryUI.color.accent_hi
  g:SetTextColor(a[1], a[2], a[3])

  local function setState(tex)
    if not tex or tex == "" then
      box:Hide()                                       -- plain row: no toggle
    else
      local minus = type(tex) == "string" and strfind(tex, "MinusButton")
      g:SetText(minus and "-" or "+")
      box:Show()
    end
  end
  -- seed from the current texture, clear the art, then swallow future swaps (we
  -- render the glyph; we only care WHICH state Blizzard asks for: +, -, or none).
  local cur = btn.GetNormalTexture and btn:GetNormalTexture()
  setState(cur and cur.GetTexture and cur:GetTexture())
  btn:SetNormalTexture("")
  btn.SetNormalTexture = function(self, tex) setState(tex) end
end

-- a MoneyInputFrame (mail-send amount, trade amount): its three $parentGold /
-- Silver / Copper edit boxes carry a bronze border on the BACKGROUND layer plus a
-- coin icon on a higher layer. Strip just the border, keep the coin, flat backdrop.
function HoryUI.SkinMoneyInputFrame(frame)
  if not frame or not frame.GetName then return end
  local base = frame:GetName()
  local parts = { "Gold", "Silver", "Copper" }
  for p = 1, getn(parts) do
    local eb = getglobal(base .. parts[p])
    if eb and not eb.horyMoney then
      eb.horyMoney = true
      HoryUI.StripTextures(eb, nil, "BACKGROUND")   -- border art only; coin survives
      HoryUI.CreateBackdrop(eb)
    end
  end
end

-- COMPACT: a flat backdrop inset to the content area. Blizzard windows are
-- oversized (a fat ornate margin around the content); the default insets crop
-- that margin. Returns the backdrop so the caller can re-anchor close/tabs to it.
function HoryUI.InsetBackdrop(frame, l, t, r, b)
  if not frame then return end
  HoryUI.CreateBackdrop(frame)
  if frame.backdrop then
    frame.backdrop:ClearAllPoints()
    frame.backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", l or 8, -(t or 8))
    frame.backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -(r or 30), b or 72)
  end
  return frame.backdrop
end

-- post-hook a GLOBAL function (1.12 has no hooksecurefunc). The wrapped fn keeps
-- `this` and all args, so `after` can re-skin a frame the client just re-drew
-- (e.g. PaperDollItemSlotButton_Update re-applies slot art on every update).
function HoryUI.HookFunc(name, after)
  local orig = getglobal(name)
  if type(orig) ~= "function" then return end
  setglobal(name, function(...)
    orig(unpack(arg))
    after(unpack(arg))
  end)
end

-- a list scrollbar: flat arrow buttons carrying a garnet "^"/"v" caret (the
-- bronze arrow art is cleared) over a flat track with a garnet thumb.
function HoryUI.SkinScrollBar(slider)
  if not slider or slider.horyScroll then return end
  slider.horyScroll = true
  local nm = slider:GetName()
  local function skinArrow(b, ch)
    if not b then return end
    if b.SetNormalTexture then b:SetNormalTexture("") end
    if b.SetPushedTexture then b:SetPushedTexture("") end
    if b.SetDisabledTexture then b:SetDisabledTexture("") end
    if b.SetHighlightTexture then b:SetHighlightTexture("") end
    HoryUI.StripTextures(b)
    if not b.horyArrow then b.horyArrow = true; HoryUI.CreateBackdrop(b) end
    AddGlyph(b, ch, 10)
  end
  skinArrow(nm and getglobal(nm .. "ScrollUpButton"), "^")
  skinArrow(nm and getglobal(nm .. "ScrollDownButton"), "v")
  HoryUI.StripTextures(slider)
  HoryUI.CreateBackdrop(slider)
  -- StripTextures above hid the slider-managed thumb (it's a region), and a plain
  -- re-texture leaves it hidden. Instead overlay a garnet texture anchored to the
  -- original thumb -- WoW still moves the (now-blank) thumb, so the overlay tracks it.
  if not slider.horyThumb then
    local thumb = slider.GetThumbTexture and slider:GetThumbTexture()
    if thumb then
      thumb:SetTexture(nil)
      local t = slider:CreateTexture(nil, "OVERLAY")
      t:SetTexture(HoryUI.tex.white)
      local a = HoryUI.color.accent
      t:SetVertexColor(a[1], a[2], a[3], 1)
      t:SetPoint("TOPLEFT", thumb, "TOPLEFT", 1, -2)
      t:SetPoint("BOTTOMRIGHT", thumb, "BOTTOMRIGHT", -1, 2)
      slider.horyThumb = t
    end
  end
end

-- a checkbox: flat box, garnet-tinted tick
function HoryUI.SkinCheckbox(cb)
  if not cb or cb.horyCheck then return end
  cb.horyCheck = true
  if cb.SetNormalTexture then cb:SetNormalTexture("") end
  if cb.SetPushedTexture then cb:SetPushedTexture("") end
  if cb.SetHighlightTexture then cb:SetHighlightTexture("") end
  HoryUI.CreateBackdrop(cb)
  if cb.backdrop then
    cb.backdrop:ClearAllPoints()
    cb.backdrop:SetPoint("TOPLEFT", cb, "TOPLEFT", 4, -4)
    cb.backdrop:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", -4, 4)
  end
  if cb.GetCheckedTexture then
    local chk = cb:GetCheckedTexture()
    local a = HoryUI.color.accent
    if chk then chk:SetVertexColor(a[1], a[2], a[3], 1) end
  end
end

-- a UIDropDownMenu: strip the heavy art, flat backdrop, clear the arrow art
function HoryUI.SkinDropDown(dd)
  if not dd or dd.horyDD then return end
  dd.horyDD = true
  HoryUI.StripTextures(dd)
  HoryUI.CreateBackdrop(dd)
  if dd.backdrop then
    dd.backdrop:ClearAllPoints()
    dd.backdrop:SetPoint("TOPLEFT", dd, "TOPLEFT", 16, -2)
    dd.backdrop:SetPoint("BOTTOMRIGHT", dd, "BOTTOMRIGHT", -16, 6)
  end
  local nm = dd:GetName()
  local btn = nm and getglobal(nm .. "Button")
  if btn then
    if btn.SetNormalTexture then btn:SetNormalTexture("") end
    if btn.SetPushedTexture then btn:SetPushedTexture("") end
    if btn.SetHighlightTexture then btn:SetHighlightTexture("") end
    if btn.SetDisabledTexture then btn:SetDisabledTexture("") end
    AddGlyph(btn, "v", 10)
  end
end

-- an item / equipment SLOT button: strip every texture EXCEPT the item icon and the
-- hover highlight (so the bronze slot art goes, but the item shows and the button still
-- glows on mouseover -- the same glow the bags have), flat backdrop, trim the icon.
-- Idempotent + safe to call from an update hook (the client re-applies slot art).
function HoryUI.SkinItemButton(btn)
  if not btn or not btn.GetRegions then return end
  local nm = btn:GetName()
  local icon = nm and getglobal(nm .. "IconTexture")
  local hl = btn.GetHighlightTexture and btn:GetHighlightTexture()   -- keep the hover glow
  local regions = { btn:GetRegions() }
  for i = 1, getn(regions) do
    local r = regions[i]
    if r ~= icon and r ~= hl and r.GetObjectType and r:GetObjectType() == "Texture" then
      r:SetTexture(nil); r:Hide()
    end
  end
  if btn.SetNormalTexture then btn:SetNormalTexture("") end
  if not btn.horySlot then
    btn.horySlot = true
    HoryUI.CreateBackdrop(btn)
  end
  if icon then
    icon:Show()
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end
end

-- Skin a WIDE item button (QuestItemTemplate: a 147x41 button = a square icon at
-- the LEFT + a bronze $parentNameFrame plate to its right). SkinItemButton is for
-- SQUARE slots; on a wide button it would stretch the icon corner-to-corner and
-- smear it. Here we keep the icon square at the left, hide the bronze name-plate,
-- and frame just the icon with a flat 1px edge-only border (so the icon shows
-- through). The $parentName text + Blizzard's red unusable-item tint on the icon
-- are deliberately left alone (the caller whitens the name; the red tint is useful).
function HoryUI.SkinRewardButton(btn)
  if not btn or not btn.GetName then return end
  local nm = btn:GetName()
  if not nm then return end
  local icon = getglobal(nm .. "IconTexture")
  local nameFrame = getglobal(nm .. "NameFrame")
  if nameFrame then nameFrame:SetTexture(nil); nameFrame:Hide() end
  if btn.SetNormalTexture then btn:SetNormalTexture("") end
  if icon then
    local SLOT = 37
    icon:Show()
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    icon:SetWidth(SLOT); icon:SetHeight(SLOT)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if not btn.horyIconBorder then
      local b = CreateFrame("Frame", nil, btn)
      b:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
      b:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
      b:SetBackdrop({ edgeFile = HoryUI.tex.white, edgeSize = 1 })
      b:SetBackdropBorderColor(0, 0, 0, 1)
      btn.horyIconBorder = b
    end
  end
end

-- Blizzard tabs (CharacterFrameTab1, etc.): drop the chunky 3-slice art for a
-- flat tab carrying a garnet underline on the ACTIVE tab + text tiers
-- (muted -> primary) -- the same language as the settings-window nav. One global
-- hook on PanelTemplates_UpdateTabs keeps every skinned tab's state in sync as
-- the user switches tabs.
HoryUI._tabs = HoryUI._tabs or {}

function HoryUI.RefreshTab(tab)
  if not tab or not tab.horyBar then return end
  local parent = tab:GetParent()
  local active = parent and parent.selectedTab and tab.GetID and (tab:GetID() == parent.selectedTab)
  local fs = tab.horyFS
  local a = HoryUI.color.accent
  if active then
    tab.horyBar:Show()
    if tab.backdrop then tab.backdrop:SetBackdropBorderColor(a[1], a[2], a[3], 1) end
    if fs then local c = HoryUI.color.text;  fs:SetTextColor(c[1], c[2], c[3]) end
  else
    tab.horyBar:Hide()
    if tab.backdrop then tab.backdrop:SetBackdropBorderColor(0, 0, 0, 1) end
    if fs then local c = HoryUI.color.text3; fs:SetTextColor(c[1], c[2], c[3]) end
  end
end

function HoryUI.SkinTab(tab)
  if not tab or tab.horyTab then return end
  tab.horyTab = true
  local nm = tab:GetName()
  if nm then
    local suffix = { "Left", "Middle", "Right", "LeftDisabled", "MiddleDisabled",
                     "RightDisabled", "Highlight" }
    for i = 1, getn(suffix) do
      local t = getglobal(nm .. suffix[i])
      if t then t:SetTexture(nil); if t.Hide then t:Hide() end end
    end
  end
  HoryUI.StripTextures(tab)
  if tab.SetHighlightTexture then tab:SetHighlightTexture("") end

  -- flat tab: no box/chip -- just the label with a garnet underline on the active
  -- one (the same nav language as the Character/Settings window). The label is the
  -- anchor (Blizzard tab frames are wide with transparent overlapping side-caps).
  local lbl = tab.GetFontString and tab:GetFontString()

  -- garnet active-underline under the label (hidden until this tab is selected)
  local bar = tab:CreateTexture(nil, "OVERLAY")
  bar:SetTexture(HoryUI.tex.white)
  local a = HoryUI.color.accent
  bar:SetVertexColor(a[1], a[2], a[3], 1)
  bar:SetHeight(2)
  if lbl then
    bar:SetPoint("TOPLEFT",  lbl, "BOTTOMLEFT",  0, -4)
    bar:SetPoint("TOPRIGHT", lbl, "BOTTOMRIGHT", 0, -4)
  else
    bar:SetPoint("BOTTOMLEFT",  tab, "BOTTOMLEFT",   8, 7)
    bar:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -8, 7)
  end
  bar:Hide()
  tab.horyBar = bar
  tab.horyFS = tab.GetFontString and tab:GetFontString()

  table.insert(HoryUI._tabs, tab)

  -- one global hook refreshes every skinned tab whenever any tab strip updates
  if not HoryUI._tabHook then
    HoryUI._tabHook = true
    HoryUI.HookFunc("PanelTemplates_UpdateTabs", function()
      for i = 1, getn(HoryUI._tabs) do HoryUI.RefreshTab(HoryUI._tabs[i]) end
    end)
  end

  HoryUI.RefreshTab(tab)
end

-- the signature garnet 1px rule under a panel title (as under the settings
-- header). Anchored across the inset backdrop so it lands inside the compact area.
function HoryUI.TitleRule(frame, yOffset)
  if not frame then return end
  local anchor = frame.backdrop or frame
  local rule = frame:CreateTexture(nil, "OVERLAY")
  rule:SetTexture(HoryUI.tex.white)
  local a = HoryUI.color.accent
  rule:SetVertexColor(a[1], a[2], a[3], 1)
  rule:SetHeight(1)
  rule:SetPoint("TOPLEFT",  anchor, "TOPLEFT",   8, yOffset or -24)
  rule:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", -8, yOffset or -24)
  return rule
end

-- make a Blizzard frame drag-movable (pfUI's EnableMovable technique). `blacklist`
-- is a list of child-frame names whose mouse we disable so they don't eat the drag
-- (e.g. CharacterFrame's paperdoll sub-frames). The frame stays in Blizzard's
-- panel system, so it opens at its default spot and can be dragged while open.
function HoryUI.MakeMovable(frame, blacklist)
  if type(frame) == "string" then frame = getglobal(frame) end
  if not frame or frame.horyMovable then return end
  frame.horyMovable = true
  if blacklist then
    for i = 1, getn(blacklist) do
      local sub = getglobal(blacklist[i])
      if sub and sub.EnableMouse then sub:EnableMouse(false) end
    end
  end
  frame:SetMovable(true)
  frame:EnableMouse(true)
  if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
  frame:RegisterForDrag("LeftButton")
  local oldStart, oldStop = frame:GetScript("OnDragStart"), frame:GetScript("OnDragStop")
  frame:SetScript("OnDragStart", function() if oldStart then oldStart() end this:StartMoving() end)
  frame:SetScript("OnDragStop", function() if oldStop then oldStop() end this:StopMovingOrSizing() end)
end
