-- HoryUI :: Nampower integration
-- Required dependency. GetUnitField/GetUnitGUID are the fast paths for unit data.

HoryUI.np = {}

function HoryUI.np.OK()
  if not GetNampowerVersion then return false end
  local ok, major = pcall(GetNampowerVersion)
  if not ok or type(major) ~= "number" then return false end
  return major >= 3
end

-- Enable the Nampower event CVars the data paths rely on.
function HoryUI.np.EnableEvents()
  if not SetCVar then return end
  local cvars = {
    "NP_EnableSpellStartEvents",
    "NP_EnableSpellGoEvents",
    "NP_EnableAuraCastEvents",
    "NP_EnableAutoAttackEvents",
    "NP_EnableSpellHealEvents",
  }
  for i = 1, table.getn(cvars) do
    pcall(SetCVar, cvars[i], "1")
  end
end

function HoryUI.np.GUID(unit)
  if GetUnitGUID then
    local ok, guid = pcall(GetUnitGUID, unit)
    if ok then return guid end
  end
  return nil
end

function HoryUI.np.Field(guid, field)
  if guid and GetUnitField then
    local ok, v = pcall(GetUnitField, guid, field)
    if ok then return v end
  end
  return nil
end

-- Health via Nampower memory read, with a plain Blizzard-API guard (NOT a
-- tooltip scan) so the HUD never errors if a field read comes back nil.
function HoryUI.UnitHP(unit)
  local guid = HoryUI.np.GUID(unit)
  local hp = HoryUI.np.Field(guid, "health")
  local max = HoryUI.np.Field(guid, "maxHealth")
  if type(hp) ~= "number" then hp = UnitHealth(unit) end
  if type(max) ~= "number" then max = UnitHealthMax(unit) end
  return hp or 0, max or 0
end
