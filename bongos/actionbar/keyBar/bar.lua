--[[
	BKeyBar
		Makes the keyring button movable

	Saved Variables:
		Bongos.keys = {
			<All variables from BBar>
			space
				The spacing between action buttons, in pixels.  A nil value means that the bar is using default spacing
			rows
				How many rows the bar is organized into.
		}
--]]

--[[ Rightclick Menu (HoryUI Garnet) ]]--

-- Key bar has only scale + opacity (handled generically by the menu).
local function ShowMenu(bar)
	HoryUI.ShowBarMenu(bar, { title = "Key Bar" })
end

BProfile.AddStartup(function()
	local bar = BBar.Create("key", "BKeyBar", "BActionSets.key", ShowMenu)
	bar:SetWidth(19); bar:SetHeight(37)
	if not bar:IsUserPlaced() then
		bar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -210, 0)
	end

	KeyRingButton:ClearAllPoints()
	KeyRingButton:SetPoint("TOPLEFT", bar)
	KeyRingButton:SetParent(bar)
	KeyRingButton:SetAlpha(bar:GetAlpha())
	KeyRingButton:Show()
end)