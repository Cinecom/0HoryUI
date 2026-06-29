-- HoryUI :: config / saved variables
-- HoryUIDB is declared in the .toc and only valid after VARIABLES_LOADED,
-- so everything here is called from Init() (PLAYER_LOGIN), never at file load.

function HoryUI:LoadConfig()
  if type(HoryUIDB) ~= "table" then HoryUIDB = {} end
  if type(HoryUIDB.modules) ~= "table" then HoryUIDB.modules = {} end
  if type(HoryUIDB.pos) ~= "table" then HoryUIDB.pos = {} end
end

function HoryUI:IsModuleEnabled(name, default)
  local v = HoryUIDB.modules[name]
  if v == nil then return default and true or false end
  return v and true or false
end

function HoryUI:SetModuleEnabled(name, state)
  HoryUIDB.modules[name] = state and true or false
end

-- Frame position persistence (relative to UIParent).
function HoryUI.SavePosition(f, key)
  local point, _, relPoint, x, y = f:GetPoint()
  HoryUIDB.pos[key] = { point, relPoint, x, y }
end

function HoryUI.RestorePosition(f, key, dpoint, dx, dy)
  local s = HoryUIDB.pos[key]
  f:ClearAllPoints()
  if s then
    f:SetPoint(s[1], UIParent, s[2], s[3], s[4])
  else
    f:SetPoint(dpoint, UIParent, dpoint, dx, dy)
  end
end
