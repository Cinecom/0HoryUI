-- HoryUI :: weapon poison / temporary enchant element (main-hand + off-hand).
-- Shows the weapon icon, remaining time and charges while a temp enchant is up.

HoryUI:RegisterModule("weaponpoison", true, function()
  local C = HoryUI.color
  local SIZE = 28

  local f = CreateFrame("Frame", "HoryUIWeaponBuffs", UIParent)
  f:SetWidth(SIZE * 2 + 4)
  f:SetHeight(SIZE)
  f:SetFrameStrata("MEDIUM")

  local function MakeIcon(invSlot, x)
    local b = CreateFrame("Frame", nil, f)
    b:SetWidth(SIZE)
    b:SetHeight(SIZE)
    b:SetPoint("LEFT", f, "LEFT", x, 0)
    HoryUI.CreateBackdrop(b)

    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
    b.tex:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    b.time = b:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(b.time, HoryUI.font.number, 9, "OUTLINE")
    b.time:SetPoint("BOTTOM", b, "BOTTOM", 0, 1)
    b.time:SetTextColor(C.text[1], C.text[2], C.text[3])

    b.charges = b:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(b.charges, HoryUI.font.number, 9, "OUTLINE")
    b.charges:SetPoint("TOPRIGHT", b, "TOPRIGHT", -1, -1)
    b.charges:SetTextColor(C.energy[1], C.energy[2], C.energy[3])

    b.slot = invSlot
    b:Hide()
    return b
  end

  local mh = MakeIcon(16, 0)
  local oh = MakeIcon(17, SIZE + 4)

  local function FmtTime(sec)
    if sec >= 3600 then return math.floor(sec / 3600) .. "h"
    elseif sec >= 60 then return math.floor(sec / 60) .. "m"
    else return math.floor(sec) .. "s" end
  end

  local function Apply(icon, has, exp, charges)
    if has then
      icon.tex:SetTexture(GetInventoryItemTexture("player", icon.slot) or "Interface\\Icons\\INV_Misc_QuestionMark")
      icon.time:SetText(FmtTime((exp or 0) / 1000))
      if charges and charges > 0 then icon.charges:SetText(charges) else icon.charges:SetText("") end
      icon:Show()
    elseif HoryUI.showAll then
      icon.tex:SetTexture("Interface\\Icons\\Ability_Poisons")
      icon.time:SetText("30m")
      icon.charges:SetText("")
      icon:Show()
    else
      icon:Hide()
    end
  end

  local function Update()
    local hasMH, mhExp, mhCharges, hasOH, ohExp, ohCharges = GetWeaponEnchantInfo()
    Apply(mh, hasMH, mhExp, mhCharges)
    Apply(oh, hasOH, ohExp, ohCharges)
  end

  local acc = 0
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("UNIT_INVENTORY_CHANGED")
  ev:RegisterEvent("PLAYER_LOGOUT")
  ev:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      this:SetScript("OnUpdate", nil)
      return
    end
    Update()
  end)
  ev:SetScript("OnUpdate", function()
    acc = acc + arg1
    if acc < 1 then return end
    acc = 0
    Update()
  end)

  HoryUI.RegisterPanel(f, "weaponpoison", "Poison", "CENTER", 0, -230)
  HoryUI.AddRefresher(Update)
  HoryUI.HideBlizzard(TemporaryEnchantFrame)  -- kill the default top-right poison display
  Update()
end)
