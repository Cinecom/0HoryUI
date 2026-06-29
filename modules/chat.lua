-- HoryUI :: chat -- a full chat rework ported from pfUI's chat module, trimmed
-- to HoryUI's lean scope and to ONE window (the left). Technique (history
-- store, URL detection, tab/dock handling, channel shortening) follows pfUI's
-- modules/chat.lua; the look uses HoryUI helpers (CreateBackdrop, RegisterPanel,
-- Garnet tokens), not pfUI's config system.
--
-- Features: persistent chat history (per realm+char), a movable bordered panel
-- the chat docks into, URL detection + copy box, class-coloured player names
-- (persistent name->class DB) and class-coloured tabs, mouse-wheel scroll,
-- skinned edit box, killed scroll/menu buttons, timestamps, short channel tags,
-- and mouseover item-link tooltips.
--
-- Dormant while real pfUI is active (_pfuiActive) -- pfUI runs its own chat, so
-- we stay out of its way. Core chat behaviour (typing, channels, tabs) is
-- Blizzard's; message text processing is wrapped in pcall so a bad message can
-- never blank a line.

HoryUI:RegisterModule("chat", true, function()
  if HoryUI._pfuiActive then return end
  if type(HoryUIDB.classdb) ~= "table" then HoryUIDB.classdb = {} end
  local db = HoryUIDB.classdb
  local C = HoryUI.color
  local floor = math.floor
  local NUMWIN = NUM_CHAT_WINDOWS or 10

  ----------------------------------------------------------------------------
  -- class DB (persists across sessions, grows as you see players)
  ----------------------------------------------------------------------------
  local function Remember(name, class)
    if name and class and class ~= "" then db[string.lower(name)] = class end
  end

  local function Scan()
    local n = GetNumRaidMembers()
    if n and n > 0 then
      for i = 1, n do
        local rname, _, _, _, _, fileName = GetRaidRosterInfo(i)
        Remember(rname, fileName)
      end
    else
      for i = 1, GetNumPartyMembers() do
        local u = "party" .. i
        if UnitExists(u) then
          local _, fc = UnitClass(u)
          Remember(UnitName(u), fc)
        end
      end
    end
    local _, sc = UnitClass("player")
    Remember(UnitName("player"), sc)
  end

  local function RememberUnit(unit)
    if UnitExists(unit) and UnitIsPlayer(unit) then
      local _, fc = UnitClass(unit)
      Remember(UnitName(unit), fc)
    end
  end

  ----------------------------------------------------------------------------
  -- chat history (SavedVariable HoryUIDB.chathistory[realm][player][id])
  ----------------------------------------------------------------------------
  local realm = GetRealmName() or "Realm"
  local player = UnitName("player") or "Player"
  local HISTMAX = 50

  local function HistTable(id)
    if type(HoryUIDB.chathistory) ~= "table" then HoryUIDB.chathistory = {} end
    local h = HoryUIDB.chathistory
    if type(h[realm]) ~= "table" then h[realm] = {} end
    if type(h[realm][player]) ~= "table" then h[realm][player] = {} end
    if type(h[realm][player][id]) ~= "table" then h[realm][player][id] = {} end
    return h[realm][player][id]
  end

  local function SaveHistory(id, msg)
    local h = HistTable(id)
    table.insert(h, 1, msg)                  -- newest first
    if h[HISTMAX + 1] then table.remove(h, HISTMAX + 1) end
  end

  ----------------------------------------------------------------------------
  -- colour helpers (inline hex codes built from Garnet tokens)
  ----------------------------------------------------------------------------
  local function Hex(tok)
    return string.format("|cff%02x%02x%02x",
      floor(tok[1] * 255 + 0.5), floor(tok[2] * 255 + 0.5), floor(tok[3] * 255 + 0.5))
  end
  local DEFAULT_HEX = Hex(C.text2)          -- player name when class unknown
  local LINK_HEX = Hex(C.mana)              -- URL links (blue)
  local TIME_HEX = Hex(C.text3)             -- timestamp (muted)

  local function ClassHex(class)
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if not c then return DEFAULT_HEX end
    return string.format("|cff%02x%02x%02x",
      floor(c.r * 255 + 0.5), floor(c.g * 255 + 0.5), floor(c.b * 255 + 0.5))
  end

  -- recolour player hyperlinks: known class -> class colour, else default
  local function ColorNames(text)
    for link in string.gfind(text, "|Hplayer:(.-)|h") do
      local real = link
      local cpos = string.find(link, ":")
      if cpos then real = string.sub(link, 1, cpos - 1) end
      local class = db[string.lower(real)]
      local hex = class and ClassHex(class) or DEFAULT_HEX
      text = string.gsub(text,
        "|Hplayer:" .. link .. "|h%[" .. real .. "%]|h",
        hex .. "|Hplayer:" .. link .. "|h[" .. real .. "]|h|r")
    end
    return text
  end

  ----------------------------------------------------------------------------
  -- URL detection (ported from pfUI's URLPattern/FormatLink/HandleLink). Each
  -- match becomes a clickable |Hhoryurl:..| link routed to the copy box.
  ----------------------------------------------------------------------------
  local URLPattern = {
    { rx = " (www%d-)%.([_A-Za-z0-9-]+)%.(%S+)%s?",                                   fm = "%s.%s.%s" },
    { rx = " (%a+)://(%S+)%s?",                                                       fm = "%s://%s" },
    { rx = " ([_A-Za-z0-9-%.:]+)@([_A-Za-z0-9-]+)(%.)([_A-Za-z0-9-]+%.?[_A-Za-z0-9-]*)%s?", fm = "%s@%s%s%s" },
    { rx = " (%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?):(%d%d?%d?%d?%d?)%s?",      fm = "%s.%s.%s.%s:%s" },
    { rx = " (%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%s?",                       fm = "%s.%s.%s.%s" },
    { rx = " (%a+)%.(%a+)/(%S+)%s?",                                                  fm = "%s.%s/%s" },
    { rx = " ([_A-Za-z0-9-]+)%.([_A-Za-z0-9-]+)%.(%S+)%:([_0-9-]+)%s?",               fm = "%s.%s.%s:%s" },
    { rx = " ([_A-Za-z0-9-]+)%.([_A-Za-z0-9-]+)%.(%S+)%s?",                           fm = "%s.%s.%s" },
  }

  local function FormatLink(fm, a1, a2, a3, a4, a5)
    if not (fm and a1) then return end
    local newtext = string.format(fm, a1 or "", a2 or "", a3 or "", a4 or "", a5 or "")
    -- a trailing/double dot means an invalid top-level domain: leave it unlinked
    if string.find(newtext, "%.%.", 1, true) then return " " .. newtext .. " " end
    return " " .. LINK_HEX .. "|Hhoryurl:" .. newtext .. "|h[" .. newtext .. "]|h|r "
  end

  -- one closure per pattern, built once (local `p` is fresh each iteration)
  local URLFuncs = {}
  for i = 1, table.getn(URLPattern) do
    local p = URLPattern[i]
    URLFuncs[i] = function(a1, a2, a3, a4, a5) return FormatLink(p.fm, a1, a2, a3, a4, a5) end
  end

  local function HandleLink(text)
    for i = 1, table.getn(URLPattern) do
      text = string.gsub(text, URLPattern[i].rx, URLFuncs[i])
    end
    return text
  end

  -- short channel tag for numbered channels: "[1. General]" -> "[1]"
  local function ShortenChannel(text)
    local channel = string.gsub(text, ".*%[(.-)%]%s+(.*|Hplayer).+", "%1")
    if string.find(channel, "%d+%. ") then
      channel = string.gsub(channel, "(%d+)%..*", "%1")
      text = string.gsub(text, "%[%d+%..-%]%s+(.*|Hplayer)", "[" .. channel .. "] %1")
    end
    return text
  end

  ----------------------------------------------------------------------------
  -- copy box (shared with URL links)
  ----------------------------------------------------------------------------
  local copybox
  local function ShowCopyBox(txt)
    if not copybox then
      copybox = CreateFrame("Frame", "HoryUICopyBox", UIParent)
      copybox:SetWidth(340)
      copybox:SetHeight(40)
      copybox:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
      copybox:SetFrameStrata("FULLSCREEN_DIALOG")
      copybox:EnableMouse(true)
      HoryUI.CreateBackdrop(copybox)
      local eb = CreateFrame("EditBox", "HoryUICopyEdit", copybox)
      eb:SetPoint("TOPLEFT", copybox, "TOPLEFT", 6, -6)
      eb:SetPoint("BOTTOMRIGHT", copybox, "BOTTOMRIGHT", -6, 6)
      eb:SetAutoFocus(false)
      eb:SetFont(HoryUI.font.normal, 12, "")
      eb:SetTextColor(1, 1, 1, 1)
      eb:SetScript("OnEscapePressed", function() copybox:Hide() end)
      eb:SetScript("OnEnterPressed", function() copybox:Hide() end)
      copybox.eb = eb
    end
    copybox.eb:SetText(txt or "")
    copybox.eb:SetFocus()
    copybox.eb:HighlightText()
    copybox:Show()
  end

  local origSetItemRef = SetItemRef
  SetItemRef = function(link, text, button)
    if link and string.find(link, "^horyurl:") then
      ShowCopyBox(string.sub(link, 9))       -- drop "horyurl:"
      return
    end
    if origSetItemRef then return origSetItemRef(link, text, button) end
  end

  ----------------------------------------------------------------------------
  -- message processing + AddMessage hook (pfUI style: store HookAddMessage)
  ----------------------------------------------------------------------------
  local function ProcessRaw(text)
    text = HandleLink(text)
    text = ColorNames(text)
    text = ShortenChannel(text)
    text = TIME_HEX .. "[" .. date("%H:%M") .. "]|r " .. text
    return text
  end

  local function Process(frame, text)
    if type(text) ~= "string" then return text end
    if frame.horyCombat then return text end          -- don't parse combat-log spam
    local ok, res = pcall(ProcessRaw, text)
    if ok and res then return res end
    return text
  end

  local function AddMessage(frame, text, a1, a2, a3, a4, a5)
    local out = Process(frame, text)
    if type(out) == "string" and not frame.horyCombat then
      SaveHistory(frame:GetID(), out)
    end
    return frame:HookAddMessage(out, a1, a2, a3, a4, a5)
  end

  ----------------------------------------------------------------------------
  -- short channel-prefix globals (G/P/R/... brackets)
  ----------------------------------------------------------------------------
  local tail = " %s|r:" .. "\32"            -- " <name>: "
  CHAT_CHANNEL_GET           = "%s|r:" .. "\32"
  CHAT_GUILD_GET             = "[G]" .. tail
  CHAT_OFFICER_GET           = "[O]" .. tail
  CHAT_PARTY_GET             = "[P]" .. tail
  CHAT_RAID_GET              = "[R]" .. tail
  CHAT_RAID_LEADER_GET       = "[RL]" .. tail
  CHAT_RAID_WARNING_GET      = "[RW]" .. tail
  CHAT_BATTLEGROUND_GET      = "[BG]" .. tail
  CHAT_BATTLEGROUND_LEADER_GET = "[BL]" .. tail
  CHAT_SAY_GET               = "[S]" .. tail
  CHAT_YELL_GET              = "[Y]" .. tail

  ----------------------------------------------------------------------------
  -- frame skin helpers
  ----------------------------------------------------------------------------
  -- permanently hide a Blizzard control (Hide + no-op Show so FCF can't restore)
  local function Kill(f)
    if not f then return end
    f:Hide()
    f.Show = function() end
  end

  local function SkinEditBox(eb)
    if not eb or eb.horySkinned then return end
    eb.horySkinned = true
    local nm = eb:GetName()
    if nm then
      local function strip(suffix)
        local t = getglobal(nm .. suffix)
        if t then t:Hide(); t:SetAlpha(0) end
      end
      strip("Left"); strip("Mid"); strip("Right")     -- default border art
    end
    eb:SetFont(HoryUI.font.normal, 13, "")
    eb:SetTextColor(C.text[1], C.text[2], C.text[3])
    HoryUI.CreateBackdrop(eb)
  end

  local function IsCombatFrame(frame)
    local combat = 0
    if frame.messageTypeList then
      for _, msg in pairs(frame.messageTypeList) do
        if strfind(msg, "SPELL", 1) or strfind(msg, "COMBAT", 1) then combat = combat + 1 end
      end
    end
    return combat > 5
  end

  local SCROLL = 3
  local function ChatWheel()
    if arg1 > 0 then
      if IsShiftKeyDown() then this:ScrollToTop() else
        for n = 1, SCROLL do this:ScrollUp() end
      end
    else
      if IsShiftKeyDown() then this:ScrollToBottom() else
        for n = 1, SCROLL do this:ScrollDown() end
      end
    end
  end

  -- mouseover item tooltips on chat hyperlinks
  local function HyperEnter()
    local _, _, linktype = string.find(arg1, "^(.-):(.+)$")
    if linktype == "item" then
      GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
      GameTooltip:SetHyperlink(arg1)
      GameTooltip:Show()
    end
  end
  local function HyperLeave() GameTooltip:Hide() end

  local function StyleTab(i)
    local tabText = getglobal("ChatFrame" .. i .. "TabText")
    if tabText then
      local _, class = UnitClass("player")
      local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
      if c then tabText:SetTextColor((c.r + .3) * .5, (c.g + .3) * .5, (c.b + .3) * .5, 1) end
      HoryUI.SetFont(tabText, HoryUI.font.normal, 12, "OUTLINE")
    end
    local l = getglobal("ChatFrame" .. i .. "TabLeft")
    local m = getglobal("ChatFrame" .. i .. "TabMiddle")
    local r = getglobal("ChatFrame" .. i .. "TabRight")
    if l then l:SetAlpha(0) end
    if m then m:SetAlpha(0) end
    if r then r:SetAlpha(0) end
    local flash = getglobal("ChatFrame" .. i .. "TabFlash")
    if flash then flash.Show = function() return end end
  end

  local function HideChatTextures(i)
    if CHAT_FRAME_TEXTURES then
      for _, suffix in pairs(CHAT_FRAME_TEXTURES) do
        local t = getglobal("ChatFrame" .. i .. suffix)
        if t then t:SetTexture(); t:Hide() end
      end
    end
    local rb = getglobal("ChatFrame" .. i .. "ResizeBottom")
    if rb then rb:Hide() end
  end

  ----------------------------------------------------------------------------
  -- the one movable chat panel (left). ChatFrame1 + any docked tabs live in it.
  ----------------------------------------------------------------------------
  local panel = CreateFrame("Frame", "HoryUIChat", UIParent)
  panel:SetWidth(430)
  panel:SetHeight(175)
  panel:SetFrameStrata("BACKGROUND")
  HoryUI.CreateBackdrop(panel)
  HoryUI.RegisterPanel(panel, "chat", "Chat", "BOTTOMLEFT", 16, 30)

  local TOPPAD = 20            -- room for the tab strip across the panel top

  local function RefreshChat()
    for i = 1, NUMWIN do
      local frame = getglobal("ChatFrame" .. i)
      local tab = getglobal("ChatFrame" .. i .. "Tab")
      if frame then
        frame.horyCombat = IsCombatFrame(frame)

        if i == 1 or frame.isDocked then
          if i ~= 1 then FCF_DockFrame(frame) end
          if tab then tab:SetParent(panel) end
          frame:SetParent(panel)
          frame:ClearAllPoints()
          frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -TOPPAD)
          frame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -6, 6)
          HideChatTextures(i)
          StyleTab(i)
        else
          FCF_UnDockFrame(frame)
          frame:SetParent(UIParent)
          if tab then tab:SetParent(UIParent) end
        end

        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel", ChatWheel)
        frame:SetScript("OnHyperlinkEnter", HyperEnter)
        frame:SetScript("OnHyperlinkLeave", HyperLeave)
      end
    end
    if DOCKED_CHAT_FRAMES then
      for _, v in pairs(DOCKED_CHAT_FRAMES) do FCF_UpdateButtonSide(v) end
    end
    if FCF_DockUpdate then FCF_DockUpdate() end
  end

  ----------------------------------------------------------------------------
  -- one-time setup: restore history, hook AddMessage, skin/kill chrome, lock
  ----------------------------------------------------------------------------
  for i = 1, NUMWIN do
    local cf = getglobal("ChatFrame" .. i)
    if cf and not cf.HookAddMessage then
      if cf.SetMaxLines then cf:SetMaxLines(300) end
      -- restore history first, using the ORIGINAL AddMessage (no reprocessing)
      if not IsCombatFrame(cf) then
        local h = HistTable(i)
        for j = table.getn(h), 1, -1 do            -- oldest first, newest last
          cf:AddMessage(h[j])
        end
      end
      cf.HookAddMessage = cf.AddMessage
      cf.AddMessage = AddMessage
    end
    Kill(getglobal("ChatFrame" .. i .. "UpButton"))
    Kill(getglobal("ChatFrame" .. i .. "DownButton"))
    Kill(getglobal("ChatFrame" .. i .. "BottomButton"))
  end
  Kill(ChatFrameMenuButton)

  -- skin + dock the shared edit box across the bottom of the panel
  SkinEditBox(ChatFrameEditBox)
  if ChatFrameEditBox then
    ChatFrameEditBox:ClearAllPoints()
    ChatFrameEditBox:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 0, -3)
    ChatFrameEditBox:SetPoint("TOPRIGHT", panel, "BOTTOMRIGHT", 0, -3)
    ChatFrameEditBox:SetHeight(22)
    if ChatFrameEditBox.SetAltArrowKeyMode then ChatFrameEditBox:SetAltArrowKeyMode(false) end
  end

  -- lock + user-place the host frame so Blizzard's layout system doesn't reset
  -- it out from under the panel anchor (move via the HoryUI unlock instead)
  if FCF_SetLocked then FCF_SetLocked(ChatFrame1, 1) end
  if ChatFrame1.SetUserPlaced then ChatFrame1:SetUserPlaced(1) end

  -- re-anchor whenever docking changes (no hooksecurefunc in 1.12)
  local origSaveDock = FCF_SaveDock
  FCF_SaveDock = function()
    if origSaveDock then origSaveDock() end
    RefreshChat()
  end

  RefreshChat()

  ----------------------------------------------------------------------------
  -- keep the class DB fresh + re-anchor on world enter; defuse on logout
  ----------------------------------------------------------------------------
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("RAID_ROSTER_UPDATE")
  ev:RegisterEvent("PARTY_MEMBERS_CHANGED")
  ev:RegisterEvent("PLAYER_TARGET_CHANGED")
  ev:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
  ev:RegisterEvent("PLAYER_LOGOUT")
  ev:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      return
    end
    if event == "PLAYER_ENTERING_WORLD" then
      RefreshChat()
    elseif event == "PLAYER_TARGET_CHANGED" then
      RememberUnit("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
      RememberUnit("mouseover")
    else
      Scan()
    end
  end)

  Scan()
end)
