--[[
	hoverbind.lua
		A "hover to bind" keybinding mode for Bongos, inspired by pfUI's hoverbind.

		While the mode is active you can:
			- hover any action / pet / stance button and press a key, mouse button,
			  or mouse wheel direction to bind it to that button
			- hold ALT / CTRL / SHIFT while pressing to bind a modified key
			- press ESCAPE while hovering a button to clear its binding
			- press ESCAPE over empty space, or click an empty area, to leave the mode

		Toggle it with "/bongos keybind" or the "Toggle Keybind Mode" keybinding.
--]]

--[[ Lookup tables ]]--

--mouse button names (from OnMouseUp's arg1) to binding tokens
local mousebuttonmap = {
	["LeftButton"]   = "BUTTON1",
	["RightButton"]  = "BUTTON2",
	["MiddleButton"] = "BUTTON3",
	["Button4"]      = "BUTTON4",
	["Button5"]      = "BUTTON5",
}

--mouse wheel directions (from OnMouseWheel's arg1) to binding tokens
local mousewheelmap = {
	[1]  = "MOUSEWHEELUP",
	[-1] = "MOUSEWHEELDOWN",
}

--lone modifier keyups we want to ignore (they only make a prefix)
local modifiers = {
	["LALT"] = true, ["RALT"] = true,
	["LCTRL"] = true, ["RCTRL"] = true,
	["LSHIFT"] = true, ["RSHIFT"] = true,
}

--each bar type maps a button to its binding command prefix; the binding command
--is prefix .. button:GetID(), which is exactly what the hotkey display looks up
local barTypes = {
	{forAll = "BActionMain_ForAllButtons", prefix = "ACTIONBUTTON"},
	{forAll = "BPetBar_ForAllButtons", prefix = "BONUSACTIONBUTTON"},
	{forAll = "BClassBar_ForAllButtons", prefix = "SHAPESHIFTBUTTON"},
}

--[[ Helper functions ]]--

--run an action over every bindable button, passing the bar's binding prefix as arg1
local function ForAllBindButtons(action)
	for _, bar in ipairs(barTypes) do
		local forAll = getglobal(bar.forAll)
		if forAll then
			forAll(action, bar.prefix)
		end
	end
end

--rebuild the shortened hotkey text on every button after a binding change
local function RefreshHotkeys()
	if BActionMain_ForAllButtons then BActionMain_ForAllButtons(BActionButton.UpdateHotkey) end
	if BPetBar_ForAllButtons then BPetBar_ForAllButtons(BPetButton.UpdateHotkey) end
	if BClassBar_ForAllButtons then BClassBar_ForAllButtons(BClassButton.UpdateHotkey) end
end

--the standard "ALT-CTRL-SHIFT-" binding prefix for whatever modifiers are held
local function GetModifierPrefix()
	return (IsAltKeyDown() and "ALT-" or "")
		.. (IsControlKeyDown() and "CTRL-" or "")
		.. (IsShiftKeyDown() and "SHIFT-" or "")
end

--the bind overlay currently under the mouse, if any
local function GetHoveredOverlay()
	local focus = GetMouseFocus()
	if focus and focus.isBindOverlay then
		return focus
	end
	return nil
end

--remove every key bound to the given overlay's button
local function ClearOverlayBinding(overlay)
	local key1, key2 = GetBindingKey(overlay.binding)
	if key1 then SetBinding(key1) end
	if key2 then SetBinding(key2) end
	SaveBindings(GetCurrentBindingSet())
	RefreshHotkeys()
end

--core handler: token is a key name, mouse button, or wheel direction; map (optional)
--translates mouse/wheel tokens into binding tokens
local function DoBind(token, map)
	if token == nil or modifiers[token] then return end

	local overlay = GetHoveredOverlay()

	--escape clears the hovered binding, or leaves the mode when over empty space
	if token == "ESCAPE" then
		if overlay then
			ClearOverlayBinding(overlay)
		else
			BongosHoverBind:Hide()
		end
		return
	end

	if not overlay then return end

	local prefix = GetModifierPrefix()

	--keep plain left/right clicks usable for the UI; require a modifier for those
	if prefix == "" and (token == "LeftButton" or token == "RightButton") then
		return
	end

	if map then
		token = map[token]
	end
	if not token then return end

	if SetBinding(prefix .. token, overlay.binding) then
		SaveBindings(GetCurrentBindingSet())
		RefreshHotkeys()
	end
end

--[[ Overlay frames ]]--

--lazily create the invisible capture frame that sits on top of an action button
local function CreateOverlay(button)
	local overlay = CreateFrame("Frame", button:GetName() .. "HoverBind", button)
	overlay:SetAllPoints(button)
	overlay:SetFrameLevel(button:GetFrameLevel() + 5)
	overlay:EnableMouse(true)
	overlay:EnableKeyboard(true)
	overlay:EnableMouseWheel(true)
	overlay.isBindOverlay = true

	local highlight = overlay:CreateTexture(nil, "OVERLAY")
	highlight:SetAllPoints(overlay)
	highlight:SetTexture(0, 1, 0, 0.25)
	highlight:Hide()
	overlay.highlight = highlight

	overlay:SetScript("OnEnter", function() this.highlight:Show() end)
	overlay:SetScript("OnLeave", function() this.highlight:Hide() end)
	overlay:SetScript("OnKeyUp", function() DoBind(arg1, nil) end)
	overlay:SetScript("OnMouseUp", function() DoBind(arg1, mousebuttonmap) end)
	overlay:SetScript("OnMouseWheel", function() DoBind(arg1, mousewheelmap) end)
	overlay:Hide()

	return overlay
end

--create (if needed) and show the overlay for a button, tagging it with its binding
local function ShowOverlay(button, prefix)
	if not button then return end

	local overlay = button.bindOverlay
	if not overlay then
		overlay = CreateOverlay(button)
		button.bindOverlay = overlay
	end
	overlay.binding = prefix .. button:GetID()
	overlay:Show()
end

local function HideOverlay(button)
	if button and button.bindOverlay then
		button.bindOverlay:Hide()
	end
end

--[[ The bind-mode controller ]]--

BongosHoverBind = CreateFrame("Frame", "BongosHoverBind", UIParent)
BongosHoverBind:Hide()
BongosHoverBind:RegisterEvent("PLAYER_REGEN_DISABLED")

--leave bind mode when entering combat so the player keeps control of the keyboard
BongosHoverBind:SetScript("OnEvent", function()
	BongosHoverBind:Hide()
end)

--build the dim, click-to-exit shade and the instruction text the first time we show
local function CreateShade()
	local shade = CreateFrame("Button", "BongosHoverBindShade", BongosHoverBind)
	shade:SetFrameStrata("BACKGROUND")
	shade:SetAllPoints(UIParent)
	shade:EnableMouse(true)
	shade:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	shade:SetScript("OnClick", function() BongosHoverBind:Hide() end)

	local tex = shade:CreateTexture(nil, "BACKGROUND")
	tex:SetAllPoints(shade)
	tex:SetTexture(0, 0, 0, 0.5)

	--keep the instructions readable above the rest of the UI
	local info = CreateFrame("Frame", nil, shade)
	info:SetFrameStrata("DIALOG")
	info:SetAllPoints(shade)
	local text = info:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	text:SetPoint("TOP", info, "TOP", 0, -150)
	text:SetJustifyH("CENTER")
	text:SetText(BONGOS_KEYBIND_HELP)

	return shade
end

local shade

BongosHoverBind:SetScript("OnShow", function()
	if not shade then
		shade = CreateShade()
	end
	shade:Show()

	--show empty buttons so every slot can be bound
	bg_showGrid = 1
	if BActionMain_ForAllButtons then BActionMain_ForAllButtons(BActionButton.ShowGrid) end
	bg_showGridPet = 1
	if BPetBar_ForAllButtons then BPetBar_ForAllButtons(BPetButton.ShowGrid) end

	ForAllBindButtons(ShowOverlay)
end)

BongosHoverBind:SetScript("OnHide", function()
	if shade then shade:Hide() end

	ForAllBindButtons(HideOverlay)

	--restore the empty-button visibility to whatever the user normally uses
	bg_showGrid = nil
	if not BActionSets_ShowGrid() and BActionMain_ForAllButtons then
		BActionMain_ForAllButtons(BActionButton.HideGrid)
	end
	bg_showGridPet = nil
	if not BActionSets_ShowGrid() and BPetBar_ForAllButtons then
		BPetBar_ForAllButtons(BPetButton.HideGrid)
	end
end)

--[[ Public toggle ]]--

function Bongos_ToggleKeyBindMode()
	if BongosHoverBind:IsShown() then
		BongosHoverBind:Hide()
	else
		BongosHoverBind:Show()
	end
end
