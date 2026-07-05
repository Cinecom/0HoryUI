-- HoryUI :: poisonapply -- a rogue poison sitting on an action bar applies
-- straight to a weapon: LEFT-click = main hand, RIGHT-click = off hand (no
-- glowing-hand cursor + click-the-weapon step).
--
-- Mechanism: wraps the global UseAction. Every bar engine (the vendored
-- bongos/, standalone Bongos, stock bars) funnels clicks through it, and the
-- widget-handler global arg1 still holds the mouse button during the
-- synchronous OnClick -> UseAction chain, so the wrapper knows left from
-- right (a keybind press has no mouse button and defaults to main hand).
-- 1.12 has no action->item API, so the action is recognized as a poison by
-- reading a hidden tooltip's first line (SetAction -- same technique as
-- durability/autodismount) for a name ending in "Poison [rank]". Applying
-- mirrors the stock FrameXML flow (verified in .fxref StaticPopup.lua +
-- UIParent.lua): using the item starts item-targeting, PickupInventoryItem
-- while targeting applies it to that slot, and the "replace existing
-- poison?" prompt's OnAccept is exactly ReplaceEnchant(), so calling it +
-- StaticPopup_Hide auto-confirms. enUS poison names only.

HoryUI:RegisterModule("poisonapply", true, function()
  local MAINHAND, OFFHAND = 16, 17

  -- hidden, WorldFrame-owned scanning tooltip (never shown)
  local scan = CreateFrame("GameTooltip", "HoryUIPoisonScan", UIParent, "GameTooltipTemplate")

  -- "Instant Poison VI", "Deadly Poison", ... -- a name ENDING in Poison plus
  -- an optional roman-numeral rank, so "Poison-Tipped ..." items and non-item
  -- actions can't false-positive.
  local function IsPoisonAction(id)
    if GetActionText(id) then return nil end   -- macro: it does its own thing
    scan:SetOwner(WorldFrame, "ANCHOR_NONE")
    scan:ClearLines()
    scan:SetAction(id)
    local fs = getglobal("HoryUIPoisonScanTextLeft1")
    local name = fs and fs:GetText()
    return name and string.find(name, "Poison%s*[IVX]*$")
  end

  local orig = UseAction
  UseAction = function(id, checkCursor, onSelf)
    -- pass through while dragging an item or already spell-targeting
    if not id or CursorHasItem() or SpellIsTargeting() or not IsPoisonAction(id) then
      return orig(id, checkCursor, onSelf)
    end

    local hand = (arg1 == "RightButton") and OFFHAND or MAINHAND
    if not GetInventoryItemLink("player", hand) then
      UIErrorsFrame:AddMessage(hand == OFFHAND and "No off-hand weapon to poison"
        or "No main-hand weapon to poison", 1, 0.1, 0.1)
      return
    end

    orig(id, checkCursor)          -- onSelf dropped: self-cast must not redirect the apply
    if SpellIsTargeting() then     -- the glowing-hand "apply to what?" state
      PickupInventoryItem(hand)
      ReplaceEnchant()             -- auto-confirm replacing the current poison
      StaticPopup_Hide("REPLACE_ENCHANT")
    end
  end
end)
