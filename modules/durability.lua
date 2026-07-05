-- HoryUI :: durability -- compact, always-visible overall durability readout.
-- A colour-ramped armour icon (red 0% -> green 100%) plus the total durability
-- percentage; hovering lists every equipped slot's own durability in the same
-- colour code. Event-driven (no OnUpdate) -- durability only changes on hits,
-- repairs and equip swaps.
--
-- NOTE: vanilla 1.12 has NO numeric durability API. GetInventoryItemDurability
-- does not exist (it errors as nil), and the stock DurabilityFrame only reads
-- GetInventoryAlertStatus' coarse 5-band level -- not a percentage. The only way
-- to get exact numbers is to scan the item tooltip for the "Durability X / Y"
-- line; this is the same technique pfUI's panel uses (verified against pfUI
-- modules/panel.lua + libs/libtipscan.lua). A single hidden, WorldFrame-owned
-- scanning tooltip is reused for every slot.

HoryUI:RegisterModule("durability", true, function()
  local C = HoryUI.color

  -- Kill Blizzard's on-screen "damaged armour" figurine -- we show our own.
  HoryUI.HideBlizzard(DurabilityFrame)

  -- Inventory slots that can carry durability, head -> feet -> weapons.
  local SLOTS = {
    { 1,  "Head" },
    { 3,  "Shoulder" },
    { 5,  "Chest" },
    { 6,  "Waist" },
    { 7,  "Legs" },
    { 8,  "Feet" },
    { 9,  "Wrist" },
    { 10, "Hands" },
    { 16, "Main Hand" },
    { 17, "Off Hand" },
    { 18, "Ranged" },
  }

  -- Hidden scanner tooltip + the localized "Durability (.+) / (.+)" pattern
  -- (built from DURABILITY_TEMPLATE so it works on non-enUS clients).
  local scan = CreateFrame("GameTooltip", "HoryUIDurabilityScan", UIParent, "GameTooltipTemplate")
  scan:SetOwner(WorldFrame, "ANCHOR_NONE")
  local DURA_PATTERN = string.gsub(DURABILITY_TEMPLATE or "Durability %d / %d", "%%[^%s]+", "(.+)")

  local function SlotDurability(slot)
    scan:SetOwner(WorldFrame, "ANCHOR_NONE")
    scan:ClearLines()
    local hasItem = scan:SetInventoryItem("player", slot)
    if not hasItem then return nil end
    for i = 1, scan:NumLines() do
      local fs = getglobal("HoryUIDurabilityScanTextLeft" .. i)
      local txt = fs and fs:GetText()
      if txt then
        local _, _, cur, max = string.find(txt, DURA_PATTERN)
        cur = tonumber(cur)
        max = tonumber(max)
        if cur and max and max > 0 then return cur, max end
      end
    end
    return nil
  end

  -- Colour ramp for p in 0..1: red (0%) -> yellow (50%) -> green (100%).
  -- Two linear segments through an amber midpoint so low durability reads hot
  -- and full reads as the §8 health green.
  local function Ramp(p)
    if p < 0 then p = 0 elseif p > 1 then p = 1 end
    if p < 0.5 then
      local t = p / 0.5
      return 0.86 + (0.90 - 0.86) * t, 0.16 + (0.74 - 0.16) * t, 0.20 + (0.24 - 0.20) * t
    end
    local t = (p - 0.5) / 0.5
    return 0.90 + (0.25 - 0.90) * t, 0.74 + (0.70 - 0.74) * t, 0.24 + (0.43 - 0.24) * t
  end

  local function Pct(p) return math.floor(p * 100 + 0.5) .. "%" end

  local SIZE = 18
  local f = CreateFrame("Frame", "HoryUIDurability", UIParent)
  f:SetWidth(SIZE + 4 + 34)
  f:SetHeight(SIZE)
  f:SetFrameStrata("MEDIUM")
  f:EnableMouse(true)

  -- the colour-ramped armour icon = the at-a-glance indicator
  local box = CreateFrame("Frame", nil, f)
  box:SetWidth(SIZE)
  box:SetHeight(SIZE)
  box:SetPoint("LEFT", f, "LEFT", 0, 0)
  HoryUI.CreateBackdrop(box)
  box.tex = box:CreateTexture(nil, "ARTWORK")
  box.tex:SetPoint("TOPLEFT", box, "TOPLEFT", 1, -1)
  box.tex:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -1, 1)
  box.tex:SetTexture("Interface\\Icons\\INV_Chest_Plate01")
  box.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  -- total durability percentage, same colour as the icon
  local pct = f:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(pct, HoryUI.font.number, 12, "OUTLINE")
  pct:SetPoint("LEFT", box, "RIGHT", 4, 0)

  -- per-slot fractions (0..1) cached on each Update so the hover tooltip doesn't
  -- re-scan all 11 slots; data[i] is nil for an empty / durability-less slot.
  local data = {}

  local function Update()
    local cur, max = 0, 0
    for i = 1, table.getn(SLOTS) do
      local c, m = SlotDurability(SLOTS[i][1])
      if c and m then
        cur = cur + c
        max = max + m
        data[i] = c / m
      else
        data[i] = nil
      end
    end
    local p = (max > 0) and (cur / max) or 1
    local r, g, b = Ramp(p)
    box.tex:SetVertexColor(r, g, b)
    pct:SetText(Pct(p))
    pct:SetTextColor(r, g, b)
  end

  f:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetText("Durability", 1, 1, 1)
    local any = false
    for i = 1, table.getn(SLOTS) do
      local frac = data[i]
      if frac then
        any = true
        local r, g, b = Ramp(frac)
        GameTooltip:AddDoubleLine(SLOTS[i][2], Pct(frac),
          C.text2[1], C.text2[2], C.text2[3], r, g, b)
      end
    end
    if not any then
      GameTooltip:AddLine("No items with durability.", C.text3[1], C.text3[2], C.text3[3])
    end
    GameTooltip:Show()
  end)
  f:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
  ev:RegisterEvent("UNIT_INVENTORY_CHANGED")
  ev:RegisterEvent("PLAYER_LOGOUT")
  ev:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      return
    end
    if event == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player" then return end
    Update()
  end)

  HoryUI.RegisterPanel(f, "durability", "Durability", "CENTER", 0, -200)
  HoryUI.AddRefresher(Update)
  Update()
end)
