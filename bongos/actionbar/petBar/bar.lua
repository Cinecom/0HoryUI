--[[
	BPetBar
		Scripts used by the Bongos Pet Action Bar replacement

	Buttons:
		PetActionButton1 .. PetActionButton10

	Saved Variables:
		Bongos.pet = {
			<All variables from BBar>
			space
				The spacing between action buttons, in pixels.  A nil value means that the bar is using default spacing
			rows
				How many rows the bar is organized into.
		}

	TODO:
		Add the ability to specify the number of rows.
		Don't hide the bar itself, but hide its buttons.
		Code cleanup
--]]

--constants
local DEFAULT_SPACING = 3
local DEFAULT_ROWS = 1

--[[ Helper Functions ]]--

function BPetBar_ForAllButtons(action, arg1)
	for i=1, NUM_PET_ACTION_SLOTS do
		action(getglobal("BPetActionButton"..i), arg1)
	end
end

--[[ Layout Functions ]]--

local function SaveSettings(bar, rows, space)
	if not space or space == DEFAULT_SPACING then
		space = nil
	end
	bar.sets.space = space

	if not rows or rows == DEFAULT_ROWS then
		rows = nil
	end
	bar.sets.rows = rows

	return rows or DEFAULT_ROWS, space or DEFAULT_SPACING
end

local function Layout(bar, rows, space)
	rows, space = SaveSettings(bar, rows, space)
	local columns = math.ceil(NUM_PET_ACTION_SLOTS / rows)

	--resize the bar
	bar:SetWidth((30 + space) * columns - space)
	bar:SetHeight((30 + space) * math.ceil(NUM_PET_ACTION_SLOTS / columns) - space)

	--set the position of the first button of the bar
	local button = getglobal("BPetActionButton1")
	if not button or button:GetParent() ~= bar then
		for i=1, NUM_PET_ACTION_SLOTS do
			BPetButton.Create(i, bar)
		end
		button = getglobal("BPetActionButton1")
	end

	button:ClearAllPoints()
	button:SetPoint("TOPLEFT", bar)

	--set the positions of the remaining buttons
	local index = 1
	for i = 1, rows, 1 do
		for j = 1, columns, 1 do
			index = index + 1
			if index > NUM_PET_ACTION_SLOTS then return end
			button = getglobal("BPetActionButton" .. index)
			button:ClearAllPoints()
			button:SetPoint("LEFT", "BPetActionButton" .. index - 1, "RIGHT", space, 0)
		end
		if index > NUM_PET_ACTION_SLOTS then return end
		button = getglobal("BPetActionButton" .. index)
		button:ClearAllPoints()
		button:SetPoint("TOP", "BPetActionButton" .. index - columns, "BOTTOM", 0, -space)
	end
end
--[[ Event Functions ]]--

local function OnEvent()
	if event == "UPDATE_BINDINGS" then
		BPetBar_ForAllButtons(BPetButton.UpdateHotkey)
	elseif PetHasActionBar() then
		if (event == "UNIT_FLAGS" or event == "UNIT_AURA") and arg1 == "pet" then
			BPetBar_ForAllButtons(BPetButton.Update)
		elseif  event == "PET_BAR_UPDATE" then
			BPetBar_ForAllButtons(BPetButton.Update)
		elseif event =="PET_BAR_UPDATE_COOLDOWN" then
			BPetBar_ForAllButtons(BPetButton.UpdateCooldown)
		elseif event =="PET_BAR_SHOWGRID" then
			bg_showGridPet = 1
			BPetBar_ForAllButtons(BPetButton.ShowGrid)
		elseif event =="PET_BAR_HIDEGRID" then
			bg_showGridPet = nil
			if not BActionSets_ShowGrid() then
				BPetBar_ForAllButtons(BPetButton.HideGrid)
			end
		end
	else
		BPetBar_ForAllButtons(BPetButton.Hide)
	end
end

--[[ Rightclick Menu (HoryUI Garnet) ]]--
local function ShowMenu(bar)
	HoryUI.ShowBarMenu(bar, {
		title = "Pet Bar",
		rows = {
			min = 1, max = NUM_PET_ACTION_SLOTS, step = 1,
			get = function() return bar.sets.rows or DEFAULT_ROWS end,
			set = function(v) Layout(bar, v, bar.sets.space) end,
		},
		spacing = {
			min = 0, max = 36, step = 2,
			get = function() return bar.sets.space or DEFAULT_SPACING end,
			set = function(v) Layout(bar, bar.sets.rows, v) end,
		},
	})
end

--[[ Startup ]]--

BProfile.AddStartup(function()
	local bar = BBar.Create("pet", "BPetBar", "BActionSets.pet", ShowMenu)
	if not bar:IsUserPlaced() then
		bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 528)
	end

	bar:SetScript("OnEvent", OnEvent)
	bar:RegisterEvent("UNIT_FLAGS")
	bar:RegisterEvent("UNIT_AURA")
	bar:RegisterEvent("PET_BAR_UPDATE")
	bar:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
	bar:RegisterEvent("PET_BAR_SHOWGRID")
	bar:RegisterEvent("PET_BAR_HIDEGRID")
	bar:RegisterEvent("UPDATE_BINDINGS")

	Layout(bar, bar.sets.rows, bar.sets.space)
end)