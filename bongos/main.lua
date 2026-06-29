--[[
	Bongos\main.lua
		Intializes and updates global Bongos settings
--]]

local function LoadDefaults(currentVersion)
	BongosSets = {
		sticky = 1,
		locked = 1,
		version = currentVersion,
		dontReuse = 1,
	}
	BMsg(BONGOS_NEW_USER)
	if BongosOptions then BongosOptions:Show() end
end

local function UpdateSettings(currentVersion)
	BongosSets.dontReuse = 1
	BongosSets.version = currentVersion
	BStatsSets = nil
	BStanceSets = nil
	BMsg(format(BONGOS_UPDATED, currentVersion))
	if BongosOptions then BongosOptions:Show() end
end

local function LoadVariables()
	local version = TLib.VToN(HoryUI._bongosVersion)
	if not(BongosSets and BongosSets.version) or TLib.VToN(BongosSets.version) > version then
		LoadDefaults(version)
	elseif BongosSets.version and TLib.VToN(BongosSets.version) < version then
		UpdateSettings(version)
	end
end

BProfile.RegisterForSave("BongosSets")
BProfile.AddStartup(function() 
	LoadVariables()
	if IsAddOnLoaded("CT_BottomBar") then
		message(BONGOS_BOTTOMBAR_LOADED)
	end
end)