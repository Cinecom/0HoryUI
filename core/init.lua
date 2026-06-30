-- HoryUI :: core init
-- Namespace, theme tokens, and the central Init() entry point.
-- Lua 5.0 / WoW 1.12 only -- see CLAUDE.md before editing.

HoryUI = HoryUI or {}
HoryUI.version = "0.2.5"

-- A plain white texture that reliably exists on the 1.12 client.
-- Tinted via SetVertexColor / SetStatusBarColor / SetBackdropColor.
HoryUI.tex = { white = "Interface\\ChatFrame\\ChatFrameBackground" }

-- "RRGGBB" -> { r, g, b } in 0..1
local function hex(s)
  return {
    tonumber(string.sub(s, 1, 2), 16) / 255,
    tonumber(string.sub(s, 3, 4), 16) / 255,
    tonumber(string.sub(s, 5, 6), 16) / 255,
  }
end
HoryUI.hex = hex

-- Garnet design tokens (see CLAUDE.md section 8)
HoryUI.color = {
  bg           = hex("0D0E10"),
  bg_raised    = hex("16181B"),  -- raised surfaces (active tab, tooltips)
  border_soft  = hex("26282C"),  -- inner hairline / dividers
  text         = hex("F2F2F2"),
  text2        = hex("A8ACB3"),
  text3        = hex("6B7079"),
  accent       = hex("A12E39"),
  accent_hi    = hex("C24450"),
  health       = hex("3FB36E"),
  health_low   = hex("E0552F"),
  name_hostile = hex("C24450"),
  mana         = hex("3D6FB0"),
  rage         = hex("9A3535"),
  energy       = hex("C8A93E"),
  cast         = hex("C9B154"),
  threat       = hex("D98A2E"),
  tick         = hex("A12E39"),
  tapped       = hex("7E8084"),  -- health bar when tapped by another player (grey)
  react_neutral  = hex("E5C84E"), -- neutral NPC name (yellow)
  react_friendly = hex("5BC46E"), -- friendly NPC name (green)
}

-- Combo point ramp: green -> yellow -> red. The 5th is a vivid, saturated red
-- (plus a glow, see modules/unitframes) so a full combo screams "finisher ready".
HoryUI.color.combo = {
  hex("4CC15E"),  -- 1 green
  hex("9DC83F"),  -- 2 lime
  hex("E3C53C"),  -- 3 yellow
  hex("E6862E"),  -- 4 orange
  hex("F0202E"),  -- 5 saturated red (glows)
}
HoryUI.color.combo_empty = hex("2A2A2C")

HoryUI.bg_alpha = 0.9

-- Run on PLAYER_LOGIN (fired from core\modulesystem.lua, after saved vars load).
function HoryUI:Init()
  HoryUI:LoadConfig()

  if HoryUI.np and HoryUI.np.EnableEvents then HoryUI.np.EnableEvents() end
  if not (HoryUI.np and HoryUI.np.OK()) then
    DEFAULT_CHAT_FRAME:AddMessage("|cffC24450HoryUI:|r Nampower not detected. Install Nampower 3.0.0+ for full performance.")
  end

  local list = HoryUI.modules or {}
  for i = 1, table.getn(list) do
    local m = list[i]
    if HoryUI:IsModuleEnabled(m.name, m.default) then
      local ok, err = pcall(m.loader)
      if not ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cffC24450HoryUI:|r module '" .. m.name .. "' failed: " .. tostring(err))
      end
    end
  end

  DEFAULT_CHAT_FRAME:AddMessage("|cffC8A93EHoryUI|r v" .. HoryUI.version .. " loaded.")
end
