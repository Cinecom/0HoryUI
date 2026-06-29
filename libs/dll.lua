-- HoryUI :: optional DLL extensions -- SuperWoW + UnitXP_SP3 (see CLAUDE.md §3A)
-- Recommended, NOT required. Detect once; wrap raw calls so modules never touch
-- UnitXP / SetMouseoverUnit / SpellInfo directly. Nampower (libs/nampower.lua)
-- stays the hard dependency.

HoryUI.sw  = {}   -- SuperWoW wrappers
HoryUI.uxp = {}   -- UnitXP_SP3 wrappers

-- SuperWoW injects SUPERWOW_VERSION (and SetAutoloot + SpellInfo). Unit-
-- independent, so it's safe to detect at file load.
HoryUI.HasSuperWoW = (SUPERWOW_VERSION or (SetAutoloot and SpellInfo)) and true or false

-- UnitXP_SP3 overloads the global UnitXP with command strings. The reliable
-- feature-test (distanceBetween) needs "player" to exist in the world, so it is
-- confirmed on the first PLAYER_ENTERING_WORLD rather than at file load.
HoryUI.HasUnitXP = false

-- Don't call DLL functions during loading screens / logout (Error-132 safety).
local safe = false
local detected = false
local guard = CreateFrame("Frame")
guard:RegisterEvent("PLAYER_ENTERING_WORLD")
guard:RegisterEvent("PLAYER_LEAVING_WORLD")
guard:RegisterEvent("PLAYER_LOGOUT")
guard:SetScript("OnEvent", function()
  if event == "PLAYER_ENTERING_WORLD" then
    safe = true
    if not detected then
      detected = true
      local ok, v = pcall(UnitXP, "distanceBetween", "player", "player")
      HoryUI.HasUnitXP = (ok and type(v) == "number") and true or false
    end
  else
    safe = false   -- PLAYER_LEAVING_WORLD / PLAYER_LOGOUT
  end
end)

-- ---- UnitXP_SP3 ---------------------------------------------------------

-- distance in yards between two units, or nil if unavailable
function HoryUI.uxp.Distance(a, b)
  if not HoryUI.HasUnitXP or not safe then return nil end
  local ok, d = pcall(UnitXP, "distanceBetween", a, b)
  if ok and type(d) == "number" then return d end
  return nil
end

-- ---- SuperWoW -----------------------------------------------------------

-- set (or clear, when unit is nil) the mouseover unit, so [target=mouseover]
-- macros resolve while hovering our frames
function HoryUI.sw.SetMouseover(unit)
  if not HoryUI.HasSuperWoW or not safe or not SetMouseoverUnit then return end
  if unit then pcall(SetMouseoverUnit, unit) else pcall(SetMouseoverUnit) end
end

-- spell name, icon texture from a spellId via SuperWoW SpellInfo (or nils)
function HoryUI.sw.SpellInfo(spellId)
  if not HoryUI.HasSuperWoW or not SpellInfo then return nil end
  local ok, name, _, icon = pcall(SpellInfo, spellId)
  if ok then return name, icon end
  return nil
end
