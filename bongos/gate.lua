-- HoryUI :: Bongos engine gate (loads FIRST in the bongos block)
-- The Bongos action bar engine is vendored into HoryUI. To avoid duplicate globals
-- and "barID already in use" errors, the vendored copy stays DORMANT while the
-- standalone Bongos addon is still enabled -- exactly like pfskin/ defers to real
-- pfUI. Disable Bongos in /hui -> Addons and /reload to hand the bars to HoryUI.
-- Lua 5.0 / WoW 1.12.

HoryUI = HoryUI or {}

do
  -- 1.12 GetAddOnInfo: name, title, notes, enabled, loadable, reason, security
  local _, _, _, enabled = GetAddOnInfo("Bongos")
  HoryUI._bongosActive = (enabled and enabled ~= 0) and true or false
end

-- The engine reads the Bongos toc version for saved-var migration. If the user
-- deletes the Bongos folder, GetAddOnMetadata returns nil -- keep a stable fallback
-- so VToN() never gets nil (the version is only used to gate Bongos's own migrations).
HoryUI._bongosVersion = (GetAddOnMetadata and GetAddOnMetadata("Bongos", "Version")) or "6.10.29"
