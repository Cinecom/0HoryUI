-- HoryUI :: pixel / border helpers

-- A near-black panel with a crisp 1px black border, sitting 1px outside `f`.
function HoryUI.CreateBackdrop(f, inset)
  inset = inset or 1
  local b = CreateFrame("Frame", nil, f)
  b:SetPoint("TOPLEFT", f, "TOPLEFT", -inset, inset)
  b:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", inset, -inset)

  local lvl = f:GetFrameLevel() - 1
  if lvl < 0 then lvl = 0 end
  b:SetFrameLevel(lvl)

  b:SetBackdrop({
    bgFile = HoryUI.tex.white,
    edgeFile = HoryUI.tex.white,
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })

  local bg = HoryUI.color.bg
  b:SetBackdropColor(bg[1], bg[2], bg[3], HoryUI.bg_alpha)
  b:SetBackdropBorderColor(0, 0, 0, 1)

  f.backdrop = b
  return b
end

-- (pixel-perfect UIParent rescale option removed at user request)
