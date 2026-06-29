-- HoryUI :: shared helpers

-- Insert thousands separators. Lua 5.0: no gsub-with-function tricks needed.
function HoryUI.Comma(n)
  n = math.floor(n + 0.5)
  if n < 0 then n = 0 end
  local s = tostring(n)
  local out = ""
  local c = 0
  local i = string.len(s)
  while i >= 1 do
    out = string.sub(s, i, i) .. out
    c = c + 1
    if math.mod(c, 3) == 0 and i > 1 then
      out = "," .. out
    end
    i = i - 1
  end
  return out
end

-- Name color by reaction: hostile reads red, everything else neutral.
-- Class color (r, g, b) for a unit; white if unknown.
function HoryUI.ClassColor(unit)
  local _, class = UnitClass(unit)
  if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
    local c = RAID_CLASS_COLORS[class]
    return c.r, c.g, c.b
  end
  return 1, 1, 1
end

-- Power-bar color for a unit's current power type.
function HoryUI.PowerColor(unit)
  local pt = UnitPowerType(unit)
  if pt == 1 then return HoryUI.color.rage
  elseif pt == 3 then return HoryUI.color.energy end
  return HoryUI.color.mana
end

-- Players read in class color; NPCs in their reaction color (hostile red /
-- neutral yellow / friendly green), matching the standard WoW convention.
function HoryUI.UnitNameColor(unit)
  if UnitIsPlayer(unit) then
    local r, g, b = HoryUI.ClassColor(unit)
    return { r, g, b }
  end
  local react = UnitReaction("player", unit)
  if react then
    if react <= 3 then return HoryUI.color.name_hostile
    elseif react == 4 then return HoryUI.color.react_neutral
    else return HoryUI.color.react_friendly end
  end
  -- no reaction data: fall back to attackability
  if UnitCanAttack("player", unit) then return HoryUI.color.name_hostile end
  return HoryUI.color.text
end

-- (frame dragging is handled by libs/panels.lua :: HoryUI.RegisterPanel)
