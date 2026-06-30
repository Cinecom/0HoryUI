-- HoryUI :: GM ticket -- compact open-ticket indicator (icon + gold label).
-- Shows only while you have an open GM ticket (and as a placeholder while panels
-- are unlocked, so it can be positioned). Left-click opens the help / ticket UI;
-- hover shows the ticket text.
--
-- API (verified against FrameXML/HelpFrame.lua): GetGMTicket() queries the server
-- asynchronously and the answer arrives via the UPDATE_TICKET event -- arg1 = the
-- ticket type (0 = no open ticket), arg2 = the ticket text. The query is fired on
-- PLAYER_ENTERING_WORLD; submitting / editing / cancelling a ticket through the
-- normal UI re-fires GetGMTicket itself, so the indicator stays current without
-- polling.

HoryUI:RegisterModule("gmticket", true, function()
  local C = HoryUI.color
  local gold = C.energy

  local SIZE = 18
  local f = CreateFrame("Frame", "HoryUIGMTicket", UIParent)
  f:SetWidth(SIZE + 4 + 60)
  f:SetHeight(SIZE)
  f:SetFrameStrata("MEDIUM")
  f:EnableMouse(true)

  -- gold-tinted note icon (matches the gold label)
  local box = CreateFrame("Frame", nil, f)
  box:SetWidth(SIZE)
  box:SetHeight(SIZE)
  box:SetPoint("LEFT", f, "LEFT", 0, 0)
  HoryUI.CreateBackdrop(box)
  box.tex = box:CreateTexture(nil, "ARTWORK")
  box.tex:SetPoint("TOPLEFT", box, "TOPLEFT", 1, -1)
  box.tex:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -1, 1)
  box.tex:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
  box.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  box.tex:SetVertexColor(gold[1], gold[2], gold[3])

  local label = f:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(label, HoryUI.font.normal, 11, "OUTLINE")
  label:SetPoint("LEFT", box, "RIGHT", 4, 0)
  label:SetText("GM Ticket")
  label:SetTextColor(gold[1], gold[2], gold[3])

  local hasTicket, ticketText = false, nil

  local function Update()
    if hasTicket or HoryUI.showAll then f:Show() else f:Hide() end
  end

  f:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetText("GM Ticket", gold[1], gold[2], gold[3])
    if hasTicket then
      GameTooltip:AddLine("You have an open ticket.", C.text[1], C.text[2], C.text[3])
      if ticketText and ticketText ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(ticketText, C.text2[1], C.text2[2], C.text2[3], 1)
      end
    else
      GameTooltip:AddLine("No open ticket.", C.text3[1], C.text3[2], C.text3[3])
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: open help / ticket", 0.6, 0.6, 0.6)
    GameTooltip:Show()
  end)
  f:SetScript("OnLeave", function() GameTooltip:Hide() end)
  f:SetScript("OnMouseUp", function()
    if arg1 == "LeftButton" and ToggleHelpFrame then ToggleHelpFrame() end
  end)

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("UPDATE_TICKET")
  ev:RegisterEvent("PLAYER_LOGOUT")
  ev:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      return
    end
    if event == "PLAYER_ENTERING_WORLD" then
      if GetGMTicket then GetGMTicket() end
      Update()
      return
    end
    -- UPDATE_TICKET: arg1 = ticket type (0 = none), arg2 = ticket text
    if arg1 and arg1 ~= 0 then
      hasTicket = true
      ticketText = arg2
    else
      hasTicket = false
      ticketText = nil
    end
    Update()
  end)

  -- Suppress the stock TicketStatusFrame so we don't show two indicators.
  HoryUI.HideBlizzard(TicketStatusFrame)

  HoryUI.RegisterPanel(f, "gmticket", "GM Ticket", "CENTER", 0, -180)
  HoryUI.AddRefresher(Update)
  Update()
end)
