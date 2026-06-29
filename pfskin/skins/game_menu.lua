if HoryUI._pfuiActive then return end
pfSkin:RegisterSkin("Game Menu", "vanilla:tbc", function ()
  StripTextures(GameMenuFrame)
  CreateBackdrop(GameMenuFrame, nil, true, .75)
  CreateBackdropShadow(GameMenuFrame)

  GameMenuFrame:SetWidth(GameMenuFrame:GetWidth() - 30)
  if pfSkin.expansion == 'tbc' then
    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 10)
  elseif pfSkin.expansion == 'vanilla' then
    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 6)
  end

  local title = GetNoNameObject(GameMenuFrame, "FontString", "ARTWORK", MAIN_MENU)
  title:SetTextColor(1,1,1,1)
  title:ClearAllPoints()
  title:SetPoint("TOP", GameMenuFrame, "TOP", 0, 16)
  title:SetFont(pfSkin.font_default, C.global.font_size + 2, "OUTLINE")

  -- HoryUI customization (NOT verbatim pfUI): skin every button in the menu --
  -- including Turtle WoW's "Donation Rewards" button -- so they all match. The
  -- upstream skin instead added a "pfUI Config" button and skinned a fixed list;
  -- both removed (there is no pfUI config GUI in the standalone vendored engine).
  for _, button in pairs({ GameMenuFrame:GetChildren() }) do
    if button and button.GetObjectType and button:GetObjectType() == "Button" then
      SkinButton(button)
    end
  end
end)
