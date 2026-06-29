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
      copybox:SetHeight(30)
      copybox:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
      copybox:SetFrameStrata("FULLSCREEN_DIALOG")
      copybox:EnableMouse(true)
      HoryUI.CreateBackdrop(copybox)
      -- close button (right side) — same garnet "x" idiom as every HoryUI window
      local close = CreateFrame("Button", "HoryUICopyClose", copybox)
      close:SetPoint("TOPRIGHT", copybox, "TOPRIGHT", -6, -6)
      HoryUI.SkinCloseButton(close)
      close:SetScript("OnClick", function() copybox:Hide() end)
      local eb = CreateFrame("EditBox", "HoryUICopyEdit", copybox)
      eb:SetPoint("TOPLEFT", copybox, "TOPLEFT", 6, -6)
      -- leave room for the close button on the right
      eb:SetPoint("BOTTOMRIGHT", copybox, "BOTTOMRIGHT", -28, 6)
      eb:SetAutoFocus(false)
      eb:SetFont(HoryUI.font.normal, 12, "")
      eb:SetTextColor(1, 1, 1, 1)
      eb:SetScript("OnEscapePressed", function() copybox:Hide() end)
      eb:SetScript("OnEnterPressed", function() copybox:Hide() end)
      -- always re-select the whole URL whenever the box takes focus
      eb:SetScript("OnEditFocusGained", function() this:HighlightText() end)
      copybox.eb = eb
    end
    copybox.eb:SetText(txt or "")
    copybox.eb:Show()
    copybox:Show()
    copybox.eb:SetFocus()
    copybox.eb:HighlightText()
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
    -- wipe the default metallic border art. Region names vary, so hide every
    -- texture region directly (pfUI technique) -- the typed text + cursor are
    -- drawn by the editbox itself, and the "Say:" header is a FontString, so
    -- both survive. This is what the name-based strip missed (the leftover art
    -- on the right of the box).
    local regions = { eb:GetRegions() }
    for i = 1, table.getn(regions) do
      local r = regions[i]
      if r and r.GetObjectType and r:GetObjectType() == "Texture" then
        r:SetTexture(nil)
        r:Hide()
      end
    end
    eb:SetFont(HoryUI.font.normal, 13, "")
    eb:SetTextColor(C.text[1], C.text[2], C.text[3])
    HoryUI.CreateBackdrop(eb)
    -- garnet outline around the input
    if eb.backdrop then
      local a = C.accent
      eb.backdrop:SetBackdropBorderColor(a[1], a[2], a[3], 1)
    end
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

  -- Tabs follow the HoryUI nav language (see the settings window + character
  -- panel): flat text, no box/fill, with a 2px GARNET BAR marking the active tab
  -- -- a bottom-bar here, the horizontal analog of the nav's garnet left-bar.
  -- Idle text is muted (text3) and brightens to text2 on hover; the active tab's
  -- text is primary (text). Blizzard's blue hover highlight is removed. Tabs are
  -- also forced to stay visible: vanilla fades idle tabs out and then *Hides*
  -- them (FCF_ChatTabFadeFinished -> chatTab:Hide()), which is why they vanished
  -- after a reload -- we re-Show + re-assert alpha on every styling pass.
  local function TabActive(tab)
    return SELECTED_CHAT_FRAME and tab.GetID and tab:GetID() == SELECTED_CHAT_FRAME:GetID()
  end

  local function StyleTabState(tab)
    if not tab then return end
    if UIFrameFadeRemoveFrame then UIFrameFadeRemoveFrame(tab) end
    tab:Show()                                  -- recover from the fade-out Hide()
    if tab._SetAlpha then tab:_SetAlpha(1) end
    local active = TabActive(tab)
    if tab.horyBar then
      if active then tab.horyBar:Show() else tab.horyBar:Hide() end
    end
    local txt = getglobal(tab:GetName() .. "Text")
    if txt then
      local t = active and C.text or C.text3          -- active primary, idle muted
      txt:SetTextColor(t[1], t[2], t[3], 1)
    end
  end

  -- our SetAlpha replacement (called as tab:SetAlpha(a), so `self` is the tab):
  -- ignore the requested alpha and re-assert our visible styling instead.
  local function SkipFading(self) StyleTabState(self) end

  local function RefreshTabs()
    for i = 1, NUMWIN do
      local frame = getglobal("ChatFrame" .. i)
      if frame and (i == 1 or frame.isDocked) then
        StyleTabState(getglobal("ChatFrame" .. i .. "Tab"))
      end
    end
  end

  local function StyleTab(i)
    local tab = getglobal("ChatFrame" .. i .. "Tab")
    if not tab then return end
    tab:SetFrameStrata("LOW")                          -- above the BACKGROUND backdrop
    local tabText = getglobal("ChatFrame" .. i .. "TabText")
    if tabText then HoryUI.SetFont(tabText, HoryUI.font.normal, 12, "OUTLINE") end
    -- hide Blizzard tab art + new-message flash
    local l = getglobal("ChatFrame" .. i .. "TabLeft")
    local m = getglobal("ChatFrame" .. i .. "TabMiddle")
    local r = getglobal("ChatFrame" .. i .. "TabRight")
    if l then l:SetAlpha(0) end
    if m then m:SetAlpha(0) end
    if r then r:SetAlpha(0) end
    local flash = getglobal("ChatFrame" .. i .. "TabFlash")
    if flash then flash:Hide(); flash.Show = function() return end end

    -- kill Blizzard's blue hover highlight (HoryUI tabs hover via text colour)
    local hl = tab:GetHighlightTexture()
    if hl then hl:SetTexture(nil) end

    -- tab-drag drop indicator: replace Blizzard's tall additive glow bar
    -- (UI-ChatFrame-DockHighlight) with a clean flat 2px garnet line. Blizzard
    -- centres the indicator on the tab's RIGHT edge (template OnLoad anchors it
    -- to [Tab]Right with a -16 offset = half the old 32px texture width). We
    -- keep that intent -- anchor our thin line's CENTER to the same edge -- so
    -- it still marks the insertion point; only the look + size change.
    local dockHi = getglobal("ChatFrame" .. i .. "TabDockRegionHighlight")
    if dockHi and not dockHi.horyDock then
      dockHi.horyDock = true
      dockHi:SetTexture(HoryUI.tex.white)
      dockHi:SetBlendMode("BLEND")
      dockHi:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
      dockHi:ClearAllPoints()
      dockHi:SetPoint("CENTER", getglobal("ChatFrame" .. i .. "TabRight"), "RIGHT", 0, -3)
      dockHi:SetWidth(2)
      dockHi:SetHeight(20)                       -- fits the tab heading, not the 32px glow
    end

    if not tab.horyTab and tabText then
      tab.horyTab = true
      -- active cue: a 2px garnet bar UNDER the label -- the horizontal analog of
      -- the settings/character nav's garnet left-bar (flat text + bar, no box).
      local bar = tab:CreateTexture(nil, "OVERLAY")
      bar:SetTexture(HoryUI.tex.white)
      bar:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
      bar:SetHeight(2)
      bar:SetPoint("TOPLEFT", tabText, "BOTTOMLEFT", -2, -4)
      bar:SetPoint("TOPRIGHT", tabText, "BOTTOMRIGHT", 2, -4)
      bar:Hide()
      tab.horyBar = bar

      -- hover: brighten idle text muted -> secondary (nav language). Chain the
      -- native handlers (the newbie "Chat Options" tip) rather than replace them.
      local oldEnter = tab:GetScript("OnEnter")
      tab:SetScript("OnEnter", function()
        if oldEnter then oldEnter() end
        if not TabActive(this) then
          local t = getglobal(this:GetName() .. "Text")
          if t then t:SetTextColor(C.text2[1], C.text2[2], C.text2[3], 1) end
        end
      end)
      local oldLeave = tab:GetScript("OnLeave")
      tab:SetScript("OnLeave", function()
        if oldLeave then oldLeave() end
        if not TabActive(this) then
          local t = getglobal(this:GetName() .. "Text")
          if t then t:SetTextColor(C.text3[1], C.text3[2], C.text3[3], 1) end
        end
      end)

      -- never fade out: pin alpha + re-show on any fade attempt
      tab._SetAlpha = tab.SetAlpha
      tab.SetAlpha = SkipFading
      -- re-evaluate every tab's active state when one is clicked
      local oldClick = tab:GetScript("OnClick")
      tab:SetScript("OnClick", function()
        if oldClick then oldClick() end
        RefreshTabs()
      end)
    end
    StyleTabState(tab)
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
  -- the one movable chat panel (left). We do NOT reparent ChatFrame1 into a
  -- fixed rect -- that fought FCF docking and the text drifted out of the
  -- backdrop. Instead we lock + place ChatFrame1 and wrap a backdrop AROUND it
  -- (anchored to its corners), so the panel can never mismatch the chat. Docked
  -- tabs (combat log) ride along with ChatFrame1.
  ----------------------------------------------------------------------------
  local main = getglobal("ChatFrame1")
  local TOPPAD = 24                     -- strip above the chat for the tab row

  -- chat at LOW strata, backdrop at BACKGROUND, so the text always draws on top
  main:SetFrameStrata("LOW")

  local panel = CreateFrame("Frame", "HoryUIChat", UIParent)
  panel:SetFrameStrata("BACKGROUND")
  panel:SetPoint("TOPLEFT", main, "TOPLEFT", -6, TOPPAD)
  panel:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", 6, -6)
  HoryUI.CreateBackdrop(panel)

  -- 1px hairline dividing the tab strip from the message body -- same divider
  -- language as the settings / character window (border_soft, alpha 0.9).
  local divider = panel:CreateTexture(nil, "ARTWORK")
  divider:SetTexture(HoryUI.tex.white)
  local ds = HoryUI.color.border_soft
  divider:SetVertexColor(ds[1], ds[2], ds[3], 0.9)
  divider:SetHeight(1)
  divider:SetPoint("TOPLEFT", main, "TOPLEFT", 0, 1)
  divider:SetPoint("TOPRIGHT", main, "TOPRIGHT", 0, 1)

  -- restyle only (no reparenting, no FCF position calls): hide Blizzard chat
  -- art, rebuild tabs as HoryUI chips, wire wheel-scroll + hyperlink tooltips.
  local function Restyle()
    for i = 1, NUMWIN do
      local frame = getglobal("ChatFrame" .. i)
      if frame then
        frame.horyCombat = IsCombatFrame(frame)
        if i == 1 or frame.isDocked then
          HideChatTextures(i)
          StyleTab(i)
        end
        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel", ChatWheel)
        frame:SetScript("OnHyperlinkEnter", HyperEnter)
        frame:SetScript("OnHyperlinkLeave", HyperLeave)
      end
    end
    RefreshTabs()                                      -- settle active/idle states
  end

  ----------------------------------------------------------------------------
  -- one-time setup: restore history, hook AddMessage, kill scroll/menu buttons
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

  -- Geometry persistence. 1.12 does NOT save chat size/position itself, so we
  -- own it in HoryUIDB: position via RegisterPanel/SavePosition (the mover),
  -- size via HoryUIDB.chatSize (the resize grip below). Both are re-asserted on
  -- PLAYER_ENTERING_WORLD so nothing Blizzard does on load can reset them. (The
  -- old code hard-coded the size every load, which is why a resize never stuck.)
  local DEFAULT_W, DEFAULT_H = 420, 160
  local function RestoreChatSize()
    local w, h = DEFAULT_W, DEFAULT_H
    if type(HoryUIDB.chatSize) == "table" then
      w = tonumber(HoryUIDB.chatSize[1]) or DEFAULT_W
      h = tonumber(HoryUIDB.chatSize[2]) or DEFAULT_H
    end
    main:SetWidth(w)
    main:SetHeight(h)
  end
  local function RestoreChatGeom()
    RestoreChatSize()
    HoryUI.RestorePosition(main, "chat", "BOTTOMLEFT", 24, 44)
  end
  local function SaveChatGeom()
    HoryUIDB.chatSize = { main:GetWidth(), main:GetHeight() }
    HoryUI.SavePosition(main, "chat")
  end

  RestoreChatSize()
  if FCF_SetLocked then FCF_SetLocked(main, 1) end
  if main.SetUserPlaced then main:SetUserPlaced(1) end
  main:SetResizable(true)
  if main.SetMinResize then main:SetMinResize(220, 90) end
  if main.SetMaxResize then main:SetMaxResize(760, 520) end
  HoryUI.RegisterPanel(main, "chat", "Chat", "BOTTOMLEFT", 24, 44)

  -- resize grip at the panel's top-right, shown only while unlocked. The chat is
  -- bottom-anchored, so sizing from TOPRIGHT keeps BOTTOMLEFT fixed and grows the
  -- frame up/right (never down off-screen). It sits at TOOLTIP strata so it stays
  -- clickable above the move overlay (which covers the panel at FULLSCREEN_DIALOG).
  local grip = CreateFrame("Frame", nil, UIParent)
  grip:SetWidth(16); grip:SetHeight(16)
  grip:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
  grip:SetFrameStrata("TOOLTIP")
  grip:EnableMouse(true)
  grip:Hide()
  local gtex = grip:CreateTexture(nil, "OVERLAY")
  gtex:SetTexture(HoryUI.tex.white)
  gtex:SetPoint("TOPRIGHT", grip, "TOPRIGHT", -2, -2)
  gtex:SetWidth(10); gtex:SetHeight(10)
  local ga = HoryUI.color.accent
  gtex:SetVertexColor(ga[1], ga[2], ga[3], 0.7)
  grip:SetScript("OnMouseDown", function() main:StartSizing("TOPRIGHT") end)
  grip:SetScript("OnMouseUp", function()
    main:StopMovingOrSizing()
    SaveChatGeom()
  end)
  HoryUI.AddRefresher(function()
    if HoryUI.locked then grip:Hide() else grip:Show() end
  end)

  -- edit box: skin + sit just under the panel. FCF re-points it to its chat
  -- frame whenever it opens, so re-apply our anchor on show.
  SkinEditBox(ChatFrameEditBox)
  local function AnchorEdit()
    if not ChatFrameEditBox then return end
    ChatFrameEditBox:ClearAllPoints()
    ChatFrameEditBox:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 0, -3)
    ChatFrameEditBox:SetPoint("TOPRIGHT", panel, "BOTTOMRIGHT", 0, -3)
    ChatFrameEditBox:SetHeight(22)
  end
  if ChatFrameEditBox then
    if ChatFrameEditBox.SetAltArrowKeyMode then ChatFrameEditBox:SetAltArrowKeyMode(false) end
    AnchorEdit()
    local oldShow = ChatFrameEditBox:GetScript("OnShow")
    ChatFrameEditBox:SetScript("OnShow", function()
      if oldShow then oldShow() end
      AnchorEdit()
    end)
  end

  -- restyle when docking changes (no hooksecurefunc in 1.12)
  local origSaveDock = FCF_SaveDock
  FCF_SaveDock = function()
    if origSaveDock then origSaveDock() end
    Restyle()
  end

  Restyle()

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
      RestoreChatGeom()                          -- re-assert saved size + position
      Restyle()
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
