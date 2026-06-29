-- HoryUI :: fonts
-- Stock 1.12 fonts for v0.1. To upgrade to PT Sans Narrow, drop the .ttf into
-- media\fonts\ and point HoryUI.font.normal at it -- nothing else changes.

HoryUI.font = {
  normal = "Fonts\\FRIZQT__.TTF",  -- UI / names
  number = "Fonts\\ARIALN.TTF",    -- tabular numbers
}

-- Always pass a flag; small HUD text needs OUTLINE to stay legible.
function HoryUI.SetFont(fs, font, size, flag)
  fs:SetFont(font or HoryUI.font.normal, size or 12, flag or "OUTLINE")
end
