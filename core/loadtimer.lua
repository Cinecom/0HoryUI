-- HoryUI :: per-addon load timing (built in)
--
-- 0HoryUI loads early -- a leading "0" sorts its folder ahead of every letter-named
-- addon -- so this file (the first one in the .toc) registers ADDON_LOADED before
-- those addons and can time them. (When the addon was plain "HoryUI" it loaded at "H"
-- and missed everything before it, which is why a separate "HoryUILoadTimer"
-- companion used to exist; folding the timer in here removed that second addon.)
-- Note: addons whose folder begins with "!" still load before this one; "0" was
-- chosen over "!" so the GitHub repo name can match the folder name.
--
-- HOW: debugprofilestop() is a high-resolution millisecond wall clock that keeps
-- advancing during the synchronous load (unlike GetTime(), which is the frame clock
-- and is frozen/coarse on the loading screen). The delta between two consecutive
-- ADDON_LOADED events is the time it took to read + parse + execute that addon's
-- files. NOTE: this is the load-screen FILE cost only -- work an addon defers to
-- PLAYER_LOGIN is not (and cannot be) attributed per-addon.
--
-- Results are written to plain globals; the "Load Times" tab reads them. They
-- regenerate every load, so no SavedVariables are needed. This file is deliberately
-- self-contained (no HoryUI namespace) so it can load before core/init.lua.

HoryUILoadTimes = {}                                            -- { { name, ms }, ... }
HoryUILoadInfo  = { done = false, reset = false, missing = false, total = 0 }

local prof = debugprofilestop
if not prof then
  -- No high-res timer on this client -> we cannot measure accurately. Say so;
  -- never fabricate numbers.
  HoryUILoadInfo.missing = true
  HoryUILoadInfo.done = true
  return
end

local SELF = "0HoryUI"
local prev = prof()                                            -- our own load = the baseline

local f = CreateFrame("Frame", "HoryUILoadTimerFrame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")
f:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" then
    -- only the startup burst is meaningful; ignore on-demand loads after login
    -- (their delta would just be idle time since the last addon loaded)
    if HoryUILoadInfo.done then return end
    local now = prof()
    if arg1 == SELF then prev = now; return end                 -- don't time ourselves
    local dt = now - prev
    prev = now
    if dt < 0 then HoryUILoadInfo.reset = true; dt = 0 end       -- someone called debugprofilestart()
    table.insert(HoryUILoadTimes, { name = arg1 or "?", ms = dt })
  elseif event == "PLAYER_LOGIN" then
    HoryUILoadInfo.done = true
    HoryUILoadInfo.total = table.getn(HoryUILoadTimes)
  elseif event == "PLAYER_LOGOUT" then
    this:UnregisterAllEvents()
    this:SetScript("OnEvent", nil)
  end
end)
