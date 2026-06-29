-- HoryUI :: module system
-- Modules register at file load; enabled ones run on PLAYER_LOGIN.

HoryUI.modules = HoryUI.modules or {}

-- name   [string]   unique module id (also the saved-var key)
-- default[boolean]  enabled when the player has no saved preference
-- loader [function] builds the module; called once, in pcall, at login
function HoryUI:RegisterModule(name, default, loader)
  table.insert(HoryUI.modules, { name = name, default = default, loader = loader })
end

local boot = CreateFrame("Frame")
boot:RegisterEvent("PLAYER_LOGIN")
boot:SetScript("OnEvent", function()
  this:UnregisterAllEvents()
  this:SetScript("OnEvent", nil)
  HoryUI:Init()
end)
