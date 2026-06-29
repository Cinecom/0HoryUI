-- HoryUI :: minimal themed widgets (button, checkbox, window, scroll list)

function HoryUI.CreateButton(parent, label, onclick)
  local b = CreateFrame("Button", nil, parent)
  b:SetWidth(80)
  b:SetHeight(20)
  HoryUI.CreateBackdrop(b)

  b.text = b:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(b.text, HoryUI.font.normal, 11, "OUTLINE")
  b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
  b.text:SetText(label)
  local t = HoryUI.color.text
  b.text:SetTextColor(t[1], t[2], t[3])

  b:SetScript("OnEnter", function()
    local a = HoryUI.color.accent_hi
    if this.backdrop then this.backdrop:SetBackdropBorderColor(a[1], a[2], a[3], 1) end
  end)
  b:SetScript("OnLeave", function()
    if this.backdrop then this.backdrop:SetBackdropBorderColor(0, 0, 0, 1) end
  end)
  if onclick then b:SetScript("OnClick", onclick) end
  return b
end

function HoryUI.CreateCheckbox(parent, label, getfn, setfn)
  local row = CreateFrame("Button", nil, parent)
  row:SetHeight(16)
  row:SetWidth(210)

  local box = CreateFrame("Frame", nil, row)
  box:SetWidth(12)
  box:SetHeight(12)
  box:SetPoint("LEFT", row, "LEFT", 0, 0)
  HoryUI.CreateBackdrop(box)

  box.fill = box:CreateTexture(nil, "ARTWORK")
  box.fill:SetTexture(HoryUI.tex.white)
  box.fill:SetPoint("TOPLEFT", box, "TOPLEFT", 3, -3)
  box.fill:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3, 3)
  local a = HoryUI.color.accent
  box.fill:SetVertexColor(a[1], a[2], a[3], 1)

  row.text = row:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(row.text, HoryUI.font.normal, 11, "OUTLINE")
  row.text:SetPoint("LEFT", box, "RIGHT", 6, 0)
  row.text:SetText(label)
  local t = HoryUI.color.text2
  row.text:SetTextColor(t[1], t[2], t[3])

  row.get = getfn
  row.set = setfn
  row.box = box
  row.Refresh = function()
    if row.get() then box.fill:Show() else box.fill:Hide() end
  end
  row:SetScript("OnClick", function()
    row.set(not row.get())
    row.Refresh()
  end)
  row.Refresh()
  return row
end

-- A flat pill toggle (square corners, garnet knob when on, grey when off).
-- With getfn/setfn it is interactive; without, it is a passive indicator the
-- caller drives via t.SetOn(bool) (mouse disabled so clicks fall through).
function HoryUI.CreateToggle(parent, getfn, setfn)
  local t = CreateFrame("Button", nil, parent)
  t:SetWidth(26)
  t:SetHeight(12)
  HoryUI.CreateBackdrop(t)

  t.knob = t:CreateTexture(nil, "OVERLAY")
  t.knob:SetTexture(HoryUI.tex.white)
  t.knob:SetWidth(10)
  t.knob:SetHeight(8)

  t.SetOn = function(on)
    local c = on and HoryUI.color.accent or HoryUI.color.text3
    t.knob:SetVertexColor(c[1], c[2], c[3], 1)
    t.knob:ClearAllPoints()
    if on then
      t.knob:SetPoint("RIGHT", t, "RIGHT", -2, 0)
    else
      t.knob:SetPoint("LEFT", t, "LEFT", 2, 0)
    end
  end

  if getfn and setfn then
    t.Refresh = function() t.SetOn(getfn() and true or false) end
    t:SetScript("OnEnter", function()
      local a = HoryUI.color.accent_hi
      if this.backdrop then this.backdrop:SetBackdropBorderColor(a[1], a[2], a[3], 1) end
    end)
    t:SetScript("OnLeave", function()
      if this.backdrop then this.backdrop:SetBackdropBorderColor(0, 0, 0, 1) end
    end)
    t:SetScript("OnClick", function() setfn(not getfn()); t.Refresh() end)
    t.Refresh()
  else
    t:EnableMouse(false)   -- passive: let clicks reach the parent row
    t.SetOn(false)
  end
  return t
end

-- THE native window factory -- every rebuilt HoryUI window is built on this so they
-- are coherent with the settings window and the Character panel. Builds: flat
-- backdrop, garnet top-LEFT title + garnet rule, close (top-right, -6/-6), drag,
-- Esc-close (UISpecialFrames). `nav` (optional) = a list of { key=, label= }: when
-- given, a left nav column (garnet active left-bar, muted->primary text) + a vertical
-- divider are built and `f.content` is the area to the RIGHT of the divider; set
-- `f.onTab = function(key) ... end` and the nav drives `f.ShowTab(key)`. Without nav,
-- `f.content` fills the area below the header. Fill `f.content` (reparent Blizzard
-- pieces into it). Logout-defuse stays the caller's job (its own event driver).
function HoryUI.CreateWindow(name, title, w, h, nav)
  local C = HoryUI.color
  local getn = table.getn
  local f = CreateFrame("Frame", name, UIParent)
  f:SetWidth(w); f:SetHeight(h)
  f:SetFrameStrata("DIALOG")
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() this:StartMoving() end)
  f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  HoryUI.CreateBackdrop(f)
  if name then tinsert(UISpecialFrames, name) end          -- Esc closes

  -- header: garnet top-left title + garnet rule
  f.title = f:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(f.title, HoryUI.font.normal, 14, "OUTLINE")
  f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -11)
  f.title:SetJustifyH("LEFT")
  f.title:SetTextColor(C.accent_hi[1], C.accent_hi[2], C.accent_hi[3])
  f.title:SetText(title or "")

  local rule = f:CreateTexture(nil, "OVERLAY")
  rule:SetTexture(HoryUI.tex.white)
  rule:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
  rule:SetHeight(1)
  rule:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -32)
  rule:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -32)

  f.close = HoryUI.CreateButton(f, "x", function() f:Hide() end)
  f.close:SetWidth(18); f.close:SetHeight(18)
  f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)

  f.content = CreateFrame("Frame", nil, f)

  if nav then
    local NAVW = 118
    local vdiv = f:CreateTexture(nil, "OVERLAY")
    vdiv:SetTexture(HoryUI.tex.white)
    vdiv:SetVertexColor(0.16, 0.17, 0.19, 0.9)
    vdiv:SetWidth(1)
    vdiv:SetPoint("TOPLEFT", f, "TOPLEFT", NAVW, -40)
    vdiv:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", NAVW, 12)
    f.content:SetPoint("TOPLEFT", f, "TOPLEFT", NAVW + 14, -42)
    f.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 12)

    f.nav, f.navList = {}, {}
    for i = 1, getn(nav) do
      local item = nav[i]
      local b = CreateFrame("Button", nil, f)
      b:SetWidth(100); b:SetHeight(24)
      b:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -42 - (i - 1) * 28)
      b.bar = b:CreateTexture(nil, "OVERLAY")
      b.bar:SetTexture(HoryUI.tex.white)
      b.bar:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
      b.bar:SetWidth(2)
      b.bar:SetPoint("TOPLEFT", b, "TOPLEFT", 0, -3)
      b.bar:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 3)
      b.bar:Hide()
      b.text = b:CreateFontString(nil, "OVERLAY")
      HoryUI.SetFont(b.text, HoryUI.font.normal, 12, "OUTLINE")
      b.text:SetPoint("LEFT", b, "LEFT", 10, 0)
      b.text:SetText(item.label)
      b.text:SetTextColor(C.text3[1], C.text3[2], C.text3[3])
      b.key = item.key
      b:SetScript("OnClick", function() f.ShowTab(this.key) end)
      b:SetScript("OnEnter", function() if not this.active then this.text:SetTextColor(C.text2[1], C.text2[2], C.text2[3]) end end)
      b:SetScript("OnLeave", function() if not this.active then this.text:SetTextColor(C.text3[1], C.text3[2], C.text3[3]) end end)
      f.nav[item.key] = b
      f.navList[i] = b
    end

    f.ShowTab = function(key)
      for i = 1, getn(f.navList) do
        local b = f.navList[i]
        b.active = (b.key == key)
        if b.active then b.bar:Show(); b.text:SetTextColor(C.text[1], C.text[2], C.text[3])
        else b.bar:Hide(); b.text:SetTextColor(C.text3[1], C.text3[2], C.text3[3]) end
      end
      f.current = key
      if f.onTab then f.onTab(key) end
    end
  else
    f.content:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -42)
    f.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 12)
  end

  f:Hide()
  return f
end

-- A scrolling checkbox list. Each row is a box (toggle) + label.
-- Caller sets:  sf.OnUpdateRow(row, dataIndex)  and  sf.OnClickRow(dataIndex)
-- then calls    sf.SetTotal(n)  to (re)populate.
function HoryUI.CreateScrollFrame(parent, width, visibleRows, rowHeight)
  local sf = CreateFrame("Frame", nil, parent)
  sf:SetWidth(width)
  sf:SetHeight(visibleRows * rowHeight)
  sf.offset = 0
  sf.total = 0
  sf.rows = {}

  local t2 = HoryUI.color.text2
  local t1 = HoryUI.color.text
  for i = 1, visibleRows do
    local row = CreateFrame("Button", nil, sf)
    row:SetHeight(rowHeight - 2)
    row:SetPoint("TOPLEFT", sf, "TOPLEFT", 0, -(i - 1) * rowHeight)
    row:SetPoint("RIGHT", sf, "RIGHT", -12, 0)

    row.toggle = HoryUI.CreateToggle(row)               -- passive pill (row drives it)
    row.toggle:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    row.SetOn = row.toggle.SetOn

    row.label = row:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(row.label, HoryUI.font.normal, 11, "OUTLINE")
    row.label:SetPoint("LEFT", row, "LEFT", 2, 0)
    row.label:SetPoint("RIGHT", row.toggle, "LEFT", -8, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetTextColor(t2[1], t2[2], t2[3])

    row:SetScript("OnEnter", function() this.label:SetTextColor(t1[1], t1[2], t1[3]) end)
    row:SetScript("OnLeave", function() this.label:SetTextColor(t2[1], t2[2], t2[3]) end)
    row:SetScript("OnClick", function()
      if sf.OnClickRow and this.dataIndex then sf.OnClickRow(this.dataIndex) end
    end)
    sf.rows[i] = row
  end

  local slider = CreateFrame("Slider", nil, sf)
  slider:SetWidth(8)
  slider:SetPoint("TOPRIGHT", sf, "TOPRIGHT", 0, 0)
  slider:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", 0, 0)
  slider:SetOrientation("VERTICAL")
  slider:SetMinMaxValues(0, 0)
  slider:SetValueStep(1)
  slider:SetValue(0)
  HoryUI.CreateBackdrop(slider)
  local thumb = slider:CreateTexture(nil, "ARTWORK")
  thumb:SetTexture(HoryUI.tex.white)
  local ac = HoryUI.color.accent
  thumb:SetVertexColor(ac[1], ac[2], ac[3], 1)
  thumb:SetWidth(8)
  thumb:SetHeight(24)
  slider:SetThumbTexture(thumb)
  sf.slider = slider

  sf.Update = function()
    local maxoff = sf.total - visibleRows
    if maxoff < 0 then maxoff = 0 end
    if sf.offset > maxoff then sf.offset = maxoff end
    if sf.offset < 0 then sf.offset = 0 end
    for i = 1, visibleRows do
      local row = sf.rows[i]
      local dataIndex = sf.offset + i
      if dataIndex <= sf.total then
        row.dataIndex = dataIndex
        row:Show()
        if sf.OnUpdateRow then sf.OnUpdateRow(row, dataIndex) end
      else
        row.dataIndex = nil
        row:Hide()
      end
    end
  end

  slider:SetScript("OnValueChanged", function()
    sf.offset = math.floor(arg1 + 0.5)
    sf.Update()
  end)

  sf:EnableMouseWheel(true)
  sf:SetScript("OnMouseWheel", function()
    slider:SetValue(slider:GetValue() - arg1)
  end)

  sf.SetTotal = function(total)
    sf.total = total
    local maxoff = total - visibleRows
    if maxoff < 0 then maxoff = 0 end
    slider:SetMinMaxValues(0, maxoff)
    if maxoff <= 0 then slider:Hide() else slider:Show() end
    sf.Update()
  end

  return sf
end

-- A flat dropdown: a value button + a popup list of options. `options` is a list
-- of { text = "...", value = ... }. onSelect(value) fires on pick. Exposes
-- dd.SetValue(value) / dd.GetValue(). No nested submenus -- one flat list.
function HoryUI.CreateDropDown(parent, width, options, onSelect)
  local C = HoryUI.color
  local n = table.getn(options)

  local dd = CreateFrame("Button", nil, parent)
  dd:SetWidth(width); dd:SetHeight(18)
  HoryUI.CreateBackdrop(dd)

  dd.text = dd:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(dd.text, HoryUI.font.normal, 11, "OUTLINE")
  dd.text:SetPoint("LEFT", dd, "LEFT", 6, 0)
  dd.text:SetTextColor(C.text[1], C.text[2], C.text[3])

  local caret = dd:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(caret, HoryUI.font.normal, 10, "OUTLINE")
  caret:SetPoint("RIGHT", dd, "RIGHT", -5, 0)
  caret:SetText("v")
  caret:SetTextColor(C.accent_hi[1], C.accent_hi[2], C.accent_hi[3])

  local rowH = 16
  local list = CreateFrame("Frame", nil, dd)
  list:SetWidth(width)
  list:SetHeight(n * rowH + 4)
  list:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
  list:SetFrameStrata("FULLSCREEN_DIALOG")
  HoryUI.CreateBackdrop(list)
  list:Hide()

  for i = 1, n do
    local opt = options[i]
    local e = CreateFrame("Button", nil, list)
    e:SetWidth(width); e:SetHeight(rowH)
    e:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -(i - 1) * rowH - 2)
    e.text = e:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(e.text, HoryUI.font.normal, 11, "OUTLINE")
    e.text:SetPoint("LEFT", e, "LEFT", 6, 0)
    e.text:SetText(opt.text)
    e.text:SetTextColor(C.text2[1], C.text2[2], C.text2[3])
    e:SetScript("OnEnter", function() this.text:SetTextColor(C.text[1], C.text[2], C.text[3]) end)
    e:SetScript("OnLeave", function() this.text:SetTextColor(C.text2[1], C.text2[2], C.text2[3]) end)
    e:SetScript("OnClick", function()
      dd.value = opt.value
      dd.text:SetText(opt.text)
      list:Hide()
      if onSelect then onSelect(opt.value) end
    end)
  end

  dd:SetScript("OnClick", function()
    if list:IsShown() then list:Hide() else list:Show() end
  end)

  dd.SetValue = function(v)
    for i = 1, n do
      if options[i].value == v then
        dd.value = v; dd.text:SetText(options[i].text); return
      end
    end
  end
  dd.GetValue = function() return dd.value end

  dd.SetValue(options[1].value)
  return dd
end
