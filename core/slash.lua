-- HoryUI :: slash commands

SLASH_HORYUI1 = "/hui"
SLASH_HORYUI2 = "/horyui"
SlashCmdList["HORYUI"] = function(msg)
  msg = string.lower(msg or "")
  local chat = DEFAULT_CHAT_FRAME

  if string.find(msg, "reset") then
    HoryUIDB.pos = {}
    chat:AddMessage("|cffC8A93EHoryUI:|r positions reset. Type /reload to apply.")
  elseif string.find(msg, "config") or string.find(msg, "settings") then
    if HoryUI.ToggleConfig then HoryUI.ToggleConfig() end
  elseif string.find(msg, "unlock") then
    HoryUI.SetLocked(false)
    chat:AddMessage("|cffC8A93EHoryUI:|r panels unlocked - drag the labelled boxes, then lock again.")
  elseif string.find(msg, "lock") then
    HoryUI.SetLocked(true)
    chat:AddMessage("|cffC8A93EHoryUI:|r panels locked.")
  else
    chat:AddMessage("|cffC8A93EHoryUI|r v" .. HoryUI.version)
    chat:AddMessage("  Nampower: " .. ((HoryUI.np and HoryUI.np.OK()) and "|cff3FB36Edetected|r" or "|cffE0552Fmissing|r"))
    chat:AddMessage("  /hui config  - open settings")
    chat:AddMessage("  /hui unlock  - show movers to position panels")
    chat:AddMessage("  /hui lock    - lock panels")
    chat:AddMessage("  /hui reset   - reset panel positions")
  end
end
