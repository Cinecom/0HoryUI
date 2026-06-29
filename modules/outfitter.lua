-- HoryUI :: Outfitter UI (HoryUI-style skin + Character-panel integration)
-- The `character` module rebuilds + hides Blizzard's CharacterFrame. Outfitter hangs
-- its UI off PaperDollFrame (OutfitterButton + OutfitterFrame, the latter nested
-- OutfitterButtonFrame -> PaperDollFrame -> CharacterFrame), so both vanish once the
-- rebuild hides CharacterFrame. This module restores + restyles all of it:
--   * launcher BUTTON  -> reparented onto the HoryUI Character window, bottom-left
--   * PANEL            -> reparented to UIParent but ANCHORED to the Character window
--                         so it stays stuck to the panel's right edge (and moves with it)
--   * full chrome skin -> HoryUI/Garnet flat look
--
-- The skin recipe mirrors Outfitter's own built-in pfUI skin (Outfitter_pfUISkin in
-- Outfitter.lua), mapping pfUI.api.* -> HoryUI.* (libs/skin.lua). Gated on the
-- character rebuild being active (HoryUI.characterFrame); no-ops if Outfitter isn't
-- installed. Lua 5.0 / WoW 1.12.

HoryUI:RegisterModule("outfitter", true, function()
  HoryUI.OnBlizzardLoaded("Outfitter", function()
    local charWin = HoryUI.characterFrame
    if not charWin or not OutfitterFrame or OutfitterFrame.horySkinned then return end
    OutfitterFrame.horySkinned = true
    local C = HoryUI.color
    local getglobal, getn = getglobal, table.getn

    -- ---- launcher button -> bottom-left of the Character window -------------
    if OutfitterButton then
      OutfitterButton:SetParent(charWin)
      OutfitterButton:SetFrameLevel(charWin:GetFrameLevel() + 10)
      OutfitterButton:SetNormalTexture("Interface\\Addons\\Outfitter\\Textures\\Outfitter-Button-pfUI")
      OutfitterButton:SetPushedTexture("Interface\\Addons\\Outfitter\\Textures\\Outfitter-Button-pfUI")
      OutfitterButton:ClearAllPoints()
      OutfitterButton:SetPoint("BOTTOMLEFT", charWin, "BOTTOMLEFT", 10, 10)
      OutfitterButton:Show()
    end

    -- ---- panel: reparent, stick to the Character window, flat backdrop -----
    OutfitterFrame:SetParent(UIParent)                 -- independent of the hidden CharacterFrame
    HoryUI.StripTextures(OutfitterFrame)
    HoryUI.CreateBackdrop(OutfitterFrame)
    -- the 3 tabs sit BELOW the frame -- extend the backdrop down so they have a
    -- HoryUI backing instead of floating bare-text over the game world.
    if OutfitterFrame.backdrop then
      OutfitterFrame.backdrop:SetPoint("BOTTOMRIGHT", OutfitterFrame, "BOTTOMRIGHT", 1, -32)
    end
    OutfitterFrame:ClearAllPoints()
    OutfitterFrame:SetPoint("TOPLEFT", charWin, "TOPRIGHT", -5, 0)   -- stuck to the char window
    if OutfitterFrameTitle then
      OutfitterFrameTitle:ClearAllPoints()
      OutfitterFrameTitle:SetPoint("TOP", OutfitterFrame, "TOP", 0, -6)
      OutfitterFrameTitle:SetTextColor(C.accent_hi[1], C.accent_hi[2], C.accent_hi[3])
    end
    if OutfitterMainFrameButtonBarBackground then OutfitterMainFrameButtonBarBackground:SetTexture(nil) end

    HoryUI.SkinCloseButton(OutfitterCloseButton)
    if OutfitterCloseButton then
      OutfitterCloseButton:ClearAllPoints()
      OutfitterCloseButton:SetPoint("TOPRIGHT", OutfitterFrame, "TOPRIGHT", -4, -4)
    end

    HoryUI.SkinButton(OutfitterNewButton)
    HoryUI.SkinButton(OutfitterEnableAll)
    HoryUI.SkinButton(OutfitterEnableNone)

    if OutfitterMainFrameScrollbarTrench then HoryUI.StripTextures(OutfitterMainFrameScrollbarTrench) end
    HoryUI.SkinScrollBar(OutfitterMainFrameScrollFrameScrollBar)

    HoryUI.SkinTab(OutfitterFrameTab1)
    HoryUI.SkinTab(OutfitterFrameTab2)
    HoryUI.SkinTab(OutfitterFrameTab3)

    -- name-outfit dialog (editbox + "create using" dropdown + done/cancel)
    if OutfitterNameOutfitDialog then
      HoryUI.StripTextures(OutfitterNameOutfitDialog)
      HoryUI.CreateBackdrop(OutfitterNameOutfitDialog)
    end
    if OutfitterNameOutfitDialogName then
      HoryUI.StripTextures(OutfitterNameOutfitDialogName, nil, "BACKGROUND")
      HoryUI.CreateBackdrop(OutfitterNameOutfitDialogName)
    end
    HoryUI.SkinDropDown(OutfitterNameOutfitDialogCreateUsing)
    HoryUI.SkinButton(OutfitterNameOutfitDialogDoneButton)
    HoryUI.SkinButton(OutfitterNameOutfitDialogCancelButton)

    -- the floating "current outfit" indicator
    if OutfitterCurrentOutfit then
      HoryUI.StripTextures(OutfitterCurrentOutfit)
      HoryUI.CreateBackdrop(OutfitterCurrentOutfit)
    end

    -- per-item rows: dropdown caret + select checkbox + category +/- toggle
    for i = 0, 13 do
      HoryUI.SkinArrowButton(getglobal("OutfitterItem" .. i .. "OutfitMenu"), "down")
      HoryUI.SkinCheckbox(getglobal("OutfitterItem" .. i .. "OutfitSelected"))
      HoryUI.SkinCollapseButton(getglobal("OutfitterItem" .. i .. "CategoryExpand"))
    end

    -- options-tab checkboxes
    local opts = { "ShowMinimapButton", "RememberVisibility", "ShowHotkeyMessages",
                   "ShowCurrentOutfit", "HideDisabledOutfits" }
    for i = 1, getn(opts) do HoryUI.SkinCheckbox(getglobal("Outfitter" .. opts[i])) end

    -- slot-enable checkboxes
    local slots = { "Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard",
                    "Wrist", "Hands", "Waist", "Legs", "Feet", "Finger0", "Finger1",
                    "Trinket0", "Trinket1", "MainHand", "SecondaryHand", "Ranged", "Ammo" }
    for i = 1, getn(slots) do HoryUI.SkinCheckbox(getglobal("OutfitterEnable" .. slots[i] .. "Slot")) end
  end)
end)
