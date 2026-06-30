--[[
	BBar (Sage Bar) - The container part of a Sage unitbar

	BBar has two parts:
		The dragbutton, which is what you see when dragging around stuff
		The container bar. which is the bar that holds all the stuff (statuBBars, name, etc)
--]]

--[[ Local Functions ]]--

--updates the drag button color of a given bar if its attached to another bar
local function UpdateDragButtonColor(bar)
	local db = getglobal(bar:GetName() .. "DragButton")
	-- garnet language: muted when stuck to another bar, bright garnet when free
	local c = bar.sets.anchor and HoryUI.color.text2 or HoryUI.color.accent_hi
	db:SetTextColor(c[1], c[2], c[3])
end

--[[ Drag Button Functions ]]--

local function DragButton_OnMouseDown()
	local bar = this:GetParent()
	-- HoryUI snap-aware drag (replaces Bongos' own sticky/FlyPaper positioning);
	-- bars now snap to the grid + other bars + HoryUI panels via the shared engine
	if HoryUI.SnapDragBegin then
		HoryUI.SnapDragBegin(bar)
		this:SetScript("OnUpdate", function() HoryUI.SnapDragMove(bar) end)
	else
		bar:StartMoving()
	end
	GameTooltip:Hide()
end

local function DragButton_OnMouseUp()
	local bar = this:GetParent()
	this:SetScript("OnUpdate", nil)
	if not HoryUI.SnapDragBegin then bar:StopMovingOrSizing() end
	BBar.TryToStick(bar)
end

local function DragButton_OnEnter()
	if this:GetScript("OnClick") then
		GameTooltip:SetOwner(this, "ANCHOR_LEFT")
		if not tonumber(this:GetText()) then
			GameTooltip:SetText(this:GetText() .. " bar", 1, 1, 1)
		else
			GameTooltip:SetText("actionbar " .. this:GetText(), 1, 1, 1)
		end
		GameTooltip:AddLine(BONGOS_SHOW_CONFIG)
		GameTooltip:Show()
	end
end

local function DragButton_OnLeave()
	GameTooltip:Hide()
end

local function DragButton_Create(parent, id, ShowMenu)
	local button = CreateFrame("Button", parent:GetName() .. "DragButton", parent)

	button:SetPoint("TOPLEFT", parent, "TOPLEFT", -2, 2)
	button:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 2, -2)
	button:SetFrameLevel(parent:GetFrameLevel() + 3)
	-- sit above HoryUI's marquee catcher (HIGH) so the handle stays grabbable while
	-- unlocked; the handle only shows when unlocked, so this strata is harmless
	button:SetFrameStrata("FULLSCREEN_DIALOG")
	button:SetClampedToScreen(true)

	button:SetTextFontObject(GameFontNormalLarge)
	button:SetHighlightTextColor(1, 1, 1)
	button:SetText(id)
	local fs = button:GetFontString()
	if fs then HoryUI.SetFont(fs, HoryUI.font.normal, 14, "OUTLINE") end

	-- Garnet mover wash: translucent accent fill + crisp 1px garnet border
	local normalTexture = button:CreateTexture(nil, "BACKGROUND")
	normalTexture:SetTexture(HoryUI.tex.white)
	local a = HoryUI.color.accent
	normalTexture:SetVertexColor(a[1], a[2], a[3], 0.35)
	normalTexture:SetAllPoints(button)

	local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
	highlightTexture:SetTexture(HoryUI.tex.white)
	local ah = HoryUI.color.accent_hi
	highlightTexture:SetVertexColor(ah[1], ah[2], ah[3], 0.30)
	highlightTexture:SetAllPoints(button)
	button:SetHighlightTexture(highlightTexture)

	button:SetBackdrop({ edgeFile = HoryUI.tex.white, edgeSize = 1 })
	button:SetBackdropBorderColor(a[1], a[2], a[3], 1)

	button:SetScale(1/parent:GetScale())
	button:RegisterForClicks("LeftButtonDown", "LeftButtonUp", "RightButtonUp")
	button:SetScript("OnMouseDown", DragButton_OnMouseDown)
	button:SetScript("OnMouseUp", DragButton_OnMouseUp)
	button:SetScript("OnEnter", DragButton_OnEnter)
	button:SetScript("OnLeave", DragButton_OnLeave)
	button:Hide()

	if ShowMenu then
		button:SetScript("OnClick", function()
			if arg1 == "RightButton" then
				ShowMenu(parent)
			end
		end)
	end
end

--[[ Bar Retrieval ]]--

local STICKY_TOLERANCE = 16 --how close one bar has to be to another in order to attempt auto anchoring
local barList = {} --indexed by id, any bongos bars currently in use
local deletedBars = {} --indexed by name, any bongos bars we've deleted

local function GetDeletedBar(barName)
	if deletedBars[barName] then
		deletedBars[barName] = nil
		local bar = getglobal(barName)
		bar:SetParent(UIParent)
		return bar
	end
end

--[[ Usable Bar Functions ]]--

BBar = {
	Create = function(id, name, settingsVar, ShowMenu, alwaysShow, OnDelete, OnCreate)
		assert(id and id ~= "", "No barID given")
		assert(not barList[id], "barID: " .. id .. " already in use")
		if tonumber(id) then id = tonumber(id) end

		local bar, created
		if getglobal(name) then
			--reusing a previously created bar
			bar = GetDeletedBar(name)
			assert(bar, "Attempted to create preexisting bar '" .. name .. "'")
		else
			--creating a new bar
			bar = CreateFrame("Frame", name, UIParent)
			DragButton_Create(bar, id, ShowMenu)
			created = true
		end
		bar.id = id
		bar.alwaysShow = alwaysShow
		bar.OnDelete = OnDelete
		bar:SetClampedToScreen(true)
		bar:SetMovable(true)

		local sets
		if settingsVar then
			bar.setsGlobal = settingsVar
			sets = TLib.GetField(settingsVar)
		end
		if not sets then
			bar.sets = BProfile.GetDefaultValue(bar.setsGlobal) or {vis = 1}
			if bar.setsGlobal then 
				TLib.SetField(bar.setsGlobal, bar.sets) 
			end
		else
			bar.sets = sets
		end

		barList[id] = bar
		BBar.LoadSettings(bar)
		if created then
			-- let HoryUI's snap engine treat this bar as a snap target (and let the
			-- bar snap to others). Reused (un-deleted) bars are already registered.
			if HoryUI.RegisterSnapTarget then HoryUI.RegisterSnapTarget(bar) end
			if OnCreate then OnCreate(bar) end
		end

		return bar
	end,

	Delete = function(id)
		assert(id and id ~="", "Invalid barID")

		local bar = barList[id]
		if bar then
			if bar.OnDelete then bar:OnDelete() end

			--delete all bar saved settings, remove it from the list of used IDs
			barList[id] = nil
			TLib.SetField(bar.setsGlobal, nil)
			bar.setsGlobal = nil
			bar.sets = nil
			bar.id = nil
			bar.alwaysShow = nil
			bar:UnregisterAllEvents()

			--hide the bar, then reanchor all bars
			bar:SetParent(nil)
			bar:ClearAllPoints()
			bar:SetUserPlaced(false)
			bar:Hide()
			BBar.ForAll(BBar.Reanchor)

			--add the bar to the deleted bars list
			deletedBars[bar:GetName()] = true
		end
	end,

	--[[ Movement ]]--

	Lock = function(bar) getglobal(bar:GetName() .. "DragButton"):Hide() end,

	Unlock = function(bar) getglobal(bar:GetName() .. "DragButton"):Show() end,

	--[[ Visibility ]]--

	Show = function(bar, save)
		bar:Show()
		if save then
			bar.sets.vis = 1
		end
	end,

	Hide = function(bar, save)
		if not bar.alwaysShow then
			bar:Hide()
			if save then
				bar.sets.vis = nil
			end
		end
	end,

	Toggle = function(bar, save)
		if bar:IsShown() then
			BBar.Hide(bar, save)
		else
			BBar.Show(bar, save)
		end
	end,

	--[[ Configuration ]]--

	--set bar scale
	SetScale = function(bar, scale, save)
		Infield.Scale(bar, scale or 1)
		BBar.Reanchor(bar)
		if save then
			BBar.SavePosition(bar)
		end
		getglobal(bar:GetName() .. 'DragButton'):SetScale(1)
	end,

	--set bar opacity
	SetAlpha = function(bar, alpha, save)
		bar:SetAlpha(alpha or 1)
		if save then
			if alpha == 1 then
				bar.sets.alpha = nil
			else
				bar.sets.alpha = alpha
			end
		end
		getglobal(bar:GetName() .. 'DragButton'):SetAlpha(1)
	end,

	--save the bar's position after a drag. (Bongos' bar-to-bar "sticky" anchoring
	--was removed -- HoryUI's snap engine now handles bars sticking to the grid /
	--each other / panels, driven from the drag button's OnUpdate.)
	TryToStick = function(bar)
		BBar.SavePosition(bar)
		UpdateDragButtonColor(bar)
	end,

	--[[ Load Settings  ]]--

	--load all default bar settings
	LoadSettings = function(bar)
		if bar.alwaysShow or bar.sets.vis then
			BBar.Show(bar)
		else
			BBar.Hide(bar)
		end

		BBar.SetAlpha(bar, bar.sets.alpha)
		BBar.Reposition(bar)

		if BongosSets.locked then
			BBar.Lock(bar)
		else
			BBar.Unlock(bar)
		end
	end,

	--place the bar at it's save'd position.  bar is ment to be used in combination with BProfile
	Reposition = function(bar)
		local x = bar.sets.x
		local y = bar.sets.y
		local scale = bar.sets.scale

		if x and y then
			bar:ClearAllPoints()
			bar:SetScale(scale or 1)
			bar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
			bar:SetUserPlaced(true)
		end
	end,

	Rescale = function(bar)
		bar:SetScale(bar.sets.scale or 1)
	end,

	--bars are positioned purely by Reposition (x/y) now that sticky anchoring is gone
	Reanchor = function(bar)
		bar.sets.anchor = nil
		UpdateDragButtonColor(bar)
	end,

	SavePosition = function(bar)
		bar.sets.x = bar:GetLeft()
		bar.sets.y = bar:GetTop()

		local scale = bar:GetScale()
		if scale == 1 then
			bar.sets.scale = nil
		else
			bar.sets.scale = scale
		end
	end,

	--[[ Utility Functions ]]--

	GetID = function(bar) return bar.id end,

	GetSettings = function(id)
		local bar = barList[tonumber(id) or id]
		if bar then return bar.sets end
	end,

	GetAnchor = function(bar)
		local anchorString = bar.sets.anchor
		if anchorString then
			local pointStart = strlen(anchorString) - 1
			return BBar.IDToBar(strsub(anchorString, 1, pointStart - 1)), strsub(anchorString, pointStart)
		end
	end,

	--takes a id, and returns
	IDToBar = function(id) return barList[tonumber(id) or id] end,

	--performs action(bar, button, arg2, ...) to every bongos bar
	ForAll = function(action, ...)
		for _,bar in pairs(barList) do
			action(bar, unpack(arg))
		end
	end,

	--performs action(id, button, arg2, ...) to every bongos bar ID
	ForAllIDs = function(action, ...)
		for id in pairs(barList) do
			action(id, unpack(arg))
		end
	end,

	GetAll = function() return pairs(barList) end,
}

Infield.AddRescaleAction(function() BBar.ForAll(BBar.Rescale) BBar.ForAll(BBar.Reanchor) end)

-- HoryUI integration: drive Bongos's lock from /hui unlock, so the garnet drag
-- handles reveal/hide alongside every other HoryUI mover (one consistent unlock).
if HoryUI and HoryUI.AddRefresher then
	HoryUI.AddRefresher(function()
		if HoryUI._bongosActive then return end   -- dormant: standalone Bongos owns the bars
		if HoryUI.locked then
			if BongosSets then BongosSets.locked = 1 end
			BBar.ForAll(BBar.Lock)
		else
			if BongosSets then BongosSets.locked = nil end
			BBar.ForAll(BBar.Unlock)
		end
	end)
end