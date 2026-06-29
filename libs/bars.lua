-- HoryUI :: status bar factory
-- Flat fill + a faint same-color track. No gradients (see CLAUDE.md section 8).

function HoryUI.CreateStatusBar(parent, color)
  local bar = CreateFrame("StatusBar", nil, parent)
  bar:SetStatusBarTexture(HoryUI.tex.white)

  local c = color or HoryUI.color.health
  bar:SetStatusBarColor(c[1], c[2], c[3], 1)
  bar:SetMinMaxValues(0, 1)
  bar:SetValue(1)

  local bg = bar:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture(HoryUI.tex.white)
  bg:SetAllPoints(bar)
  bg:SetVertexColor(c[1], c[2], c[3], 0.16)
  bar.bg = bg

  return bar
end
