-- HoryUI :: Garnet right-click bar menu
-- Replaces Bongos's XML "BongosRightClickMenu" + per-bar-type CreateConfigMenu.
-- ONE reusable menu frame, reconfigured per bar via HoryUI.ShowBarMenu(bar, opts).
-- Each bar type's ShowMenu builds an `opts` table; this file owns the look + layout.
--
-- opts = {
--   title   = "Action Bar 1",
--   size    = sliderOpt,   -- optional (action bars)
--   rows    = sliderOpt,   -- optional (action / class / pet)
--   spacing = sliderOpt,   -- optional (most types)
--   checks  = { { label=, get=, set= }, ... },  -- 0..2 (bag: One Bag / Vertical)
-- }
-- sliderOpt = { min, max, step, get, set }  -- min/max may be a number OR a function.
-- Scale + Opacity are always shown and handled generically from `bar` itself.
-- Lua 5.0 / WoW 1.12 -- handlers use this/arg1.

local function resolve(v)        -- number or function -> number
  if type(v) == "function" then return v() end
  return v
end

local menu               -- the single reusable frame (built lazily)

local function Build()
  local C = HoryUI.color
  local m = CreateFrame("Frame", "HoryUIBarMenu", UIParent)
  m:SetWidth(190)
  m:SetFrameStrata("DIALOG")
  m:SetClampedToScreen(true)
  m:EnableMouse(true)
  HoryUI.CreateBackdrop(m)
  tinsert(UISpecialFrames, "HoryUIBarMenu")     -- Esc closes

  m.title = m:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(m.title, HoryUI.font.normal, 13, "OUTLINE")
  m.title:SetPoint("TOPLEFT", m, "TOPLEFT", 12, -10)
  m.title:SetTextColor(C.accent_hi[1], C.accent_hi[2], C.accent_hi[3])

  m.close = HoryUI.CreateButton(m, "x", function() m:Hide() end)
  m.close:SetWidth(16); m.close:SetHeight(16)
  m.close:SetPoint("TOPRIGHT", m, "TOPRIGHT", -6, -6)

  local rule = m:CreateTexture(nil, "ARTWORK")
  rule:SetTexture(HoryUI.tex.white)
  rule:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
  rule:SetHeight(1)
  rule:SetPoint("TOPLEFT", m, "TOPLEFT", 10, -28)
  rule:SetPoint("TOPRIGHT", m, "TOPRIGHT", -10, -28)

  -- 3 checkbox slots: [1] = Hide bar (always), [2..3] = type-specific.
  -- get/set indirect through m.opts so the rows are reusable across bars.
  m.checks = {}
  for i = 1, 3 do
    local idx = i
    local chk = HoryUI.CreateCheckbox(m, "",
      function()
        if idx == 1 then return m.bar and (not m.bar.sets.vis) end
        local c = m.opts and m.opts.checks and m.opts.checks[idx - 1]
        return c and c.get() and true or false
      end,
      function(v)
        if idx == 1 then
          if v then BBar.Hide(m.bar, 1) else BBar.Show(m.bar, 1) end
        else
          local c = m.opts and m.opts.checks and m.opts.checks[idx - 1]
          if c then c.set(v) end
        end
        m.Refresh()
      end)
    chk:SetWidth(166)
    m.checks[i] = chk
  end

  -- 5 reconfigurable sliders.  size/rows/spacing come from opts; scale/opacity
  -- are generic.  onChange relayouts then refreshes (size can change rows' max).
  m.sliders = {}
  local function mkSlider(key)
    local s = HoryUI.CreateSlider(m, 166)
    m.sliders[key] = s
    return s
  end
  mkSlider("size"); mkSlider("rows"); mkSlider("spacing")
  mkSlider("scale"); mkSlider("opacity")

  -- ordered control list for vertical stacking
  m.order = {
    { f = m.checks[1], h = 14 },
    { f = m.checks[2], h = 14 },
    { f = m.checks[3], h = 14 },
    { f = m.sliders.size,    h = 28 },
    { f = m.sliders.rows,    h = 28 },
    { f = m.sliders.spacing, h = 28 },
    { f = m.sliders.scale,   h = 28 },
    { f = m.sliders.opacity, h = 28 },
  }

  -- (re)read live values into every visible control; called on show + after a change
  m.Refresh = function()
    if not m.bar then return end
    m.checks[1].Refresh()
    if m.opts.checks then
      for i = 1, 2 do
        local c = m.opts.checks[i]
        if c then m.checks[i + 1].text:SetText(c.label); m.checks[i + 1].Refresh() end
      end
    end
    local function cfgSlider(key, opt, label, mn, mx, step, value, suffix)
      local s = m.sliders[key]
      s.Configure(label, mn, mx, step, value,
        function(v) opt.set(v); m.Refresh() end, suffix)
    end
    if m.opts.size then
      local o = m.opts.size
      cfgSlider("size", o, "Size", resolve(o.min), resolve(o.max), o.step or 1, o.get())
    end
    if m.opts.rows then
      local o = m.opts.rows
      cfgSlider("rows", o, "Rows", resolve(o.min), resolve(o.max), o.step or 1, o.get())
    end
    if m.opts.spacing then
      local o = m.opts.spacing
      cfgSlider("spacing", o, "Spacing", resolve(o.min), resolve(o.max), o.step or 2, o.get())
    end
    -- generic scale/opacity (percent)
    local bar = m.bar
    m.sliders.scale.Configure("Scale", 50, 150, 5, math.floor(bar:GetScale() * 100 + 0.5),
      function(v) BBar.SetScale(bar, v / 100, 1) end, "%")
    m.sliders.opacity.Configure("Opacity", 0, 100, 5, math.floor(bar:GetAlpha() * 100 + 0.5),
      function(v) BBar.SetAlpha(bar, v / 100, 1) end, "%")
  end

  -- show only the controls this bar uses, stack them, size the frame
  m.LayoutControls = function()
    -- build the visible list with no nil holes (table.getn is unreliable with holes)
    local visible = {}
    tinsert(visible, m.checks[1])                              -- Hide bar (always)
    if m.opts.checks and m.opts.checks[1] then tinsert(visible, m.checks[2]) end
    if m.opts.checks and m.opts.checks[2] then tinsert(visible, m.checks[3]) end
    if m.opts.size    then tinsert(visible, m.sliders.size) end
    if m.opts.rows    then tinsert(visible, m.sliders.rows) end
    if m.opts.spacing then tinsert(visible, m.sliders.spacing) end
    tinsert(visible, m.sliders.scale)                          -- generic
    tinsert(visible, m.sliders.opacity)                        -- generic

    -- hide everything first
    for i = 1, table.getn(m.order) do m.order[i].f:Hide() end

    local y = -36
    for i = 1, table.getn(visible) do
      local f = visible[i]
      f:ClearAllPoints()
      f:SetPoint("TOPLEFT", m, "TOPLEFT", 12, y)
      f:Show()
      -- sliders are 28 tall, checkboxes ~16; detect by presence of .slider
      if f.slider then y = y - 34 else y = y - 20 end
    end
    m:SetHeight(-y + 8)
  end

  menu = m
  return m
end

-- Position the menu up-left of the bar's drag handle (Bongos BMenu.ShowForBar math).
local function Position(m, bar)
  local db = getglobal(bar:GetName() .. "DragButton")
  m:ClearAllPoints()
  if db then
    local ratio = UIParent:GetScale() / db:GetEffectiveScale()
    m:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", db:GetLeft() / ratio, db:GetTop() / ratio)
  else
    m:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
end

function HoryUI.ShowBarMenu(bar, opts)
  local m = menu or Build()
  m.bar = bar
  m.opts = opts or {}
  m.title:SetText(opts and opts.title or "Bar")
  m.LayoutControls()
  m.Refresh()
  Position(m, bar)
  m:Show()
end
