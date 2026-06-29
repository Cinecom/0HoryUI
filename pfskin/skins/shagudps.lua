if HoryUI._pfuiActive then return end
-- ShaguDPS damage-meter skin -- ported from pfUI's modules/thirdparty.lua (the
-- ShaguDPS block). Unlike the other files in pfskin/ this is NOT a verbatim copy:
-- it is a hand-adapted port, so re-applying a pfUI re-copy won't touch it.
--
-- Kept: the visual skin (flat backdrop + shadow, hidden title bar + border, flat
-- toolbar buttons), applied on every meter refresh.
-- Dropped: pfUI's docking of the meter into its chat panel (pfUI.chat.right /
-- RegisterMeter -- HoryUI has no such panel) and the pfUI chat-background tint
-- (depends on pfUI's chat config). Applied unconditionally (the user opted in),
-- where pfUI gates it behind thirdparty.shagudps.skin (off by default). It is
-- still covered by HoryUI's master "pfUI window skins" toggle (boot.lua).

pfSkin:RegisterSkin("ShaguDPS", "vanilla:tbc", function()
  HookAddonOrVariable("ShaguDPS", function()
    if not ShaguDPS or not ShaguDPS.window or not ShaguDPS.window.Refresh then return end

    -- hook the meter's master Refresh; re-skin its windows after each redraw
    local hookRefresh = ShaguDPS.window.Refresh
    ShaguDPS.window.Refresh = function(arg1, arg2)
      hookRefresh(arg1, arg2)

      for wid = 1, 10 do
        local window = ShaguDPS.window[wid]

        -- legacy single-window support
        if wid == 1 and not window then
          window = ShaguDPS.window
        end

        if window and window.title then
          local _, chat_border = GetBorderSize("chat")

          window.title:Hide()
          window.title:SetPoint("TOPLEFT", 1, -1)
          window.title:SetPoint("TOPRIGHT", -1, -1)

          CreateBackdrop(window, chat_border, nil, .8)
          CreateBackdropShadow(window)

          -- keep ShaguDPS's own backdrop/border hidden under ours on every redraw
          if not window.pfRefreshHook then
            window.pfRefreshHook = window.Refresh
            window.Refresh = function(self, a1, a2)
              window.pfRefreshHook(self, a1, a2)
              window:SetBackdrop(nil)
              if window.border then window.border:SetBackdrop(nil) end
            end
          end

          -- flatten the toolbar buttons (those that exist on this version)
          local buttons = {
            window.btnAnnounce, window.btnReset, window.btnSegment, window.btnMode,
            window.btnDamage, window.btnDPS, window.btnHeal, window.btnHPS,
            window.btnCurrent, window.btnOverall, window.btnWindow, window.btnSettings,
          }
          for _, button in pairs(buttons) do
            if button then
              button:SetHeight(14)
              CreateBackdrop(button, -1, true, .75)
              button:SetBackdropBorderColor(.4, .4, .4, 1)
              if button:GetWidth() == 16 then button:SetWidth(14) end
            end
          end

          if window.border then window.border:Hide() end
        end
      end
    end

    -- apply immediately (ShaguDPS would otherwise re-skin only on its next redraw)
    ShaguDPS.window.Refresh()
  end)
end)
