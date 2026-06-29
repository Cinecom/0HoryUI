-- HoryUI :: hide default Blizzard frames we replace
-- Each module calls HoryUI.HideBlizzard() for the frames it supersedes, so a
-- disabled module leaves its Blizzard counterpart intact.

HoryUI.hiddenParent = CreateFrame("Frame")
HoryUI.hiddenParent:Hide()

function HoryUI.HideBlizzard(frame)
  if not frame then return end
  frame:UnregisterAllEvents()
  frame:Hide()
  -- Reparent to a permanently-hidden frame so Blizzard's :Show() calls (e.g.
  -- on target change) can't bring it back.
  frame:SetParent(HoryUI.hiddenParent)
end
