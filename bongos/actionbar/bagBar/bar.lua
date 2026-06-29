--[[
	bar.lua
		Scripts used for the Bongos Bag bar

	Saved Variables:
		Bongos.bag = {
			<All variables from BBar>
			space
				The spacing between action buttons, in pixels.  A nil value means that the bar is using default spacing
			rows
				How many rows the bar is organized into.
			oneBag
				Flag for if we're only showing the main bag.
		}
--]]

--constants
local DEFAULT_SPACING = 4
local DEFAULT_ROWS = 1

--[[ UI Functions ]]--

local function Layout(bar, rows, space)
	if not rows or rows == DEFAULT_ROWS then
		rows = nil
	end
	bar.sets.rows = rows

	if not space or space == DEFAULT_SPACING then
		bar.sets.space = nil
		space = DEFAULT_SPACING
	else
		bar.sets.space = space
	end

	--clear all button positions
	for i = 0, 3 do
		getglobal("CharacterBag" .. i .. "Slot"):ClearAllPoints()
	end
	MainMenuBarBackpackButton:ClearAllPoints()

	if bar.sets.oneBag then
		--hide all bag buttons, show the main bag
		for i = 0, 3 do
			getglobal("CharacterBag" .. i .. "Slot"):Hide()
		end
		MainMenuBarBackpackButton:SetPoint("TOPLEFT", bar)

		bar:SetWidth(37)
		bar:SetHeight(37)
	else
		--arrange all bag buttons, and the backpack
		for i = 0, 3 do
			getglobal("CharacterBag" .. i .. "Slot"):Show()
		end
		CharacterBag3Slot:SetPoint("TOPLEFT", bar)

		--vertical alignment
		if rows then
			for i = 0, 2 do
				getglobal("CharacterBag" .. i .. "Slot"):SetPoint("TOP", "CharacterBag" .. i+1 .. "Slot", "BOTTOM", 0, -space)
			end
			MainMenuBarBackpackButton:SetPoint("TOP", CharacterBag0Slot, "BOTTOM", 0, -space)

			bar:SetWidth((37 + space) - space)
			bar:SetHeight((37 + space) * 5 - space)
		--horizontal alignment
		else
			for i = 0, 2 do
				getglobal("CharacterBag" .. i .. "Slot"):SetPoint("LEFT", "CharacterBag" .. i+1 .. "Slot", "RIGHT", space, 0)
			end
			MainMenuBarBackpackButton:SetPoint("LEFT", CharacterBag0Slot, "RIGHT", space, 0)

			bar:SetWidth((37 + space) * 5 - space)
			bar:SetHeight((37 + space) - space)
		end
	end
end

--[[ Config Functions ]]--

local function ShowAsOneBag(enable)
	if enable then
		BBagBar.sets.oneBag = 1
	else
		BBagBar.sets.oneBag = nil
	end
	Layout(BBagBar, BBagBar.sets.rows, BBagBar.sets.space)
end

local function SetVertical(enable)
	if enable then
		Layout(BBagBar, 5, BBagBar.sets.space)
	else
		Layout(BBagBar, nil, BBagBar.sets.space)
	end
end

--Called when the right click menu is shown (HoryUI Garnet menu)
local function ShowMenu(bar)
	HoryUI.ShowBarMenu(bar, {
		title = "Bag Bar",
		spacing = {
			min = 0, max = 36, step = 2,
			get = function() return bar.sets.space or DEFAULT_SPACING end,
			set = function(v) Layout(bar, bar.sets.rows, v) end,
		},
		checks = {
			{ label = "One Bag",  get = function() return bar.sets.oneBag end, set = function(v) ShowAsOneBag(v) end },
			{ label = "Vertical", get = function() return bar.sets.rows end,   set = function(v) SetVertical(v) end },
		},
	})
end

--[[ Startup ]]--

local function AddFrame(frame, parent)
	frame:SetParent(parent)
	frame:SetAlpha(parent:GetAlpha())
	frame:SetFrameLevel(0)
end

BProfile.AddStartup(function()
	local bar = BBar.Create("bags", "BBagBar", "BActionSets.bags", ShowMenu)
	if not bar:IsUserPlaced() then
		bar:SetPoint("BOTTOMRIGHT", UIParent)
	end

	for i = 0, 3 do
		AddFrame(getglobal("CharacterBag" .. i .. "Slot"), bar)
	end
	AddFrame(MainMenuBarBackpackButton, bar)
	MainMenuBarBackpackButton:Show()

	Layout(bar, bar.sets.rows, bar.sets.space)
end)