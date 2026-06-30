-- HoryUI :: quest tracker -- a draggable, Garnet-styled panel mirroring the
-- shift-click quest watch (replaces the default right-side QuestWatchFrame).
-- Each objective is colour-coded by progress: green = complete, red = none yet
-- (0/x), orange = in progress. A quest title turns green once all its objectives
-- are done (ready to turn in). Left-click a title to collapse / expand it;
-- right-click to untrack it.
--
-- The Blizzard watch list (GetNumQuestWatches) is hard-capped at 5 by the engine,
-- so HoryUI keeps its OWN tracked set (HoryUIDB.questTracked, by title) and renders
-- by scanning the quest log directly -- no 5-quest limit. The set is fed by hooking
-- AddQuestWatch / RemoveQuestWatch (shift-click), seeded from the live watch list on
-- login, and editable via right-click in the panel.
--
-- API (1.12, verified against FrameXML/QuestLogFrame.lua + pfQuest on this client):
--   GetNumQuestLogEntries() -> numEntries, numQuests
--   GetQuestLogTitle(qi) -> title, level, questTag, isHeader, isCollapsed, isComplete
--   GetNumQuestLeaderBoards(qi) / GetQuestLogLeaderBoard(o, qi) -> text, type, finished

HoryUI:RegisterModule("questtracker", true, function()
  local C = HoryUI.color
  local GREEN  = C.health         -- objective complete
  local ORANGE = C.threat         -- objective in progress
  local RED    = C.name_hostile   -- objective not started (0 / x)

  local WIDTH, PAD, INDENT = 240, 8, 12
  HoryUIDB.questCollapsed = HoryUIDB.questCollapsed or {}
  HoryUIDB.questTracked   = HoryUIDB.questTracked or {}

  local Update   -- forward declaration (title-button clicks + hooks call it)

  -- resolve a quest-log index to its non-header title
  local function TitleOf(idx)
    if not idx or idx < 1 then return nil end
    local t, _, _, isHeader = GetQuestLogTitle(idx)
    if t and not isHeader then return t end
    return nil
  end

  local container = CreateFrame("Frame", "HoryUIQuestTracker", UIParent)
  container:SetWidth(WIDTH)
  container:SetHeight(40)
  container:SetFrameStrata("MEDIUM")
  HoryUI.CreateBackdrop(container)

  -- garnet header + a flat 1px garnet rule beneath it (the HoryUI §8.7 divider).
  local header = container:CreateFontString(nil, "OVERLAY")
  HoryUI.SetFont(header, HoryUI.font.normal, 12, "OUTLINE")
  header:SetPoint("TOPLEFT", container, "TOPLEFT", PAD, -PAD)
  header:SetTextColor(C.accent_hi[1], C.accent_hi[2], C.accent_hi[3])

  local rule = container:CreateTexture(nil, "ARTWORK")
  rule:SetTexture(HoryUI.tex.white)
  rule:SetHeight(1)
  rule:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 0.85)

  local function RowHeight(fs, minH)
    local h = fs:GetHeight()
    if not h or h < minH then return minH end
    return h
  end

  -- clickable title rows (collapse / untrack) and plain objective rows, two pools
  local titleRows, objRows = {}, {}

  local function GetTitleRow(i)
    if titleRows[i] then return titleRows[i] end
    local b = CreateFrame("Button", nil, container)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b.arrow = b:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(b.arrow, HoryUI.font.number, 12, "OUTLINE")
    b.arrow:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    b.arrow:SetTextColor(C.accent_hi[1], C.accent_hi[2], C.accent_hi[3])
    b.text = b:CreateFontString(nil, "OVERLAY")
    HoryUI.SetFont(b.text, HoryUI.font.normal, 12, "OUTLINE")
    b.text:SetPoint("TOPLEFT", b, "TOPLEFT", INDENT, 0)
    b.text:SetJustifyH("LEFT")
    b:SetScript("OnClick", function()
      if arg1 == "RightButton" then
        -- untrack (works for any quest, including ones past the engine's 5-cap)
        if this.qindex and RemoveQuestWatch then RemoveQuestWatch(this.qindex)
        elseif this.qtitle then HoryUIDB.questTracked[this.qtitle] = nil; Update() end
        return
      end
      local t = this.qtitle
      if not t then return end
      if HoryUIDB.questCollapsed[t] then HoryUIDB.questCollapsed[t] = nil
      else HoryUIDB.questCollapsed[t] = true end
      Update()
    end)
    titleRows[i] = b
    return b
  end

  local function GetObjRow(i)
    if objRows[i] then return objRows[i] end
    local fs = container:CreateFontString(nil, "OVERLAY")
    fs:SetJustifyH("LEFT")
    objRows[i] = fs
    return fs
  end

  local function PlaceObj(fs, w, x, y, col)
    HoryUI.SetFont(fs, HoryUI.font.normal, 11, "OUTLINE")
    fs:SetWidth(w)
    fs:SetTextColor(col[1], col[2], col[3])
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", container, "TOPLEFT", x, -y)
  end

  -- Colour an objective by its progress. "finished" wins; otherwise parse "x/y".
  local function ObjColor(text, finished)
    if finished then return GREEN end
    local _, _, a, b = string.find(text, "(%d+)/(%d+)")
    if a then
      a = tonumber(a); b = tonumber(b)
      if b and a >= b then return GREEN end
      if a == 0 then return RED end
      return ORANGE
    end
    return RED   -- non-counted objective, not yet finished
  end

  local function HideAll()
    header:Hide(); rule:Hide()
    for i = 1, table.getn(titleRows) do titleRows[i]:Hide() end
    for i = 1, table.getn(objRows) do objRows[i]:Hide() end
  end

  Update = function()
    if not GetNumQuestLogEntries then container:Hide(); return end
    local tracked   = HoryUIDB.questTracked
    local collapsed = HoryUIDB.questCollapsed
    local innerW = WIDTH - PAD * 2

    -- header + divider rule
    header:SetText("Quests")
    header:Show()
    local y = PAD + RowHeight(header, 12) + 4
    rule:ClearAllPoints()
    rule:SetPoint("TOPLEFT", container, "TOPLEFT", PAD, -y)
    rule:SetWidth(innerW)
    rule:Show()
    y = y + 1 + 6

    local ti, oi, shown = 0, 0, 0
    local _, numQuests = GetNumQuestLogEntries()
    local found = 0
    for qi = 1, 50 do
      local title, _, _, isHeader = GetQuestLogTitle(qi)
      if title and not isHeader then
        found = found + 1
        if tracked[title] then
          shown = shown + 1
          local isCol = collapsed[title] and true or false

          -- objectives drive both the title colour and the rows below it
          local numObj = GetNumQuestLeaderBoards(qi) or 0
          local allDone = true
          local objText, objCol = {}, {}
          for o = 1, numObj do
            local otext, otype, ofin = GetQuestLogLeaderBoard(o, qi)
            if not otext or otext == "" then otext = otype or "" end
            local col = ObjColor(otext, ofin)
            if col ~= GREEN then allDone = false end
            objText[o] = otext; objCol[o] = col
          end

          -- title row (left-click collapse, right-click untrack)
          ti = ti + 1
          local tb = GetTitleRow(ti)
          tb.qtitle = title
          tb.qindex = qi
          tb.arrow:SetText(isCol and "+" or "-")
          tb.text:SetWidth(innerW - INDENT)
          local tcol = allDone and GREEN or C.text
          tb.text:SetTextColor(tcol[1], tcol[2], tcol[3])
          tb.text:SetText(title)
          local th = RowHeight(tb.text, 13)
          tb:ClearAllPoints()
          tb:SetPoint("TOPLEFT", container, "TOPLEFT", PAD, -y)
          tb:SetWidth(innerW)
          tb:SetHeight(th)
          tb:Show()
          y = y + th + 2

          -- objectives (skipped while collapsed)
          if not isCol then
            for o = 1, numObj do
              oi = oi + 1
              local orow = GetObjRow(oi)
              PlaceObj(orow, innerW - INDENT, PAD + INDENT, y, objCol[o])
              orow:SetText(objText[o])
              orow:Show()
              y = y + RowHeight(orow, 12) + 1
            end
          end

          y = y + 6   -- gap between quests
        end
        if found >= (numQuests or 99) then break end
      end
    end

    if shown == 0 then
      if not HoryUI.showAll then
        HideAll()
        container:Hide()
        return
      end
      oi = oi + 1
      local ph = GetObjRow(oi)
      PlaceObj(ph, innerW, PAD, y, C.text3)
      ph:SetText("No quests tracked")
      ph:Show()
      y = y + RowHeight(ph, 12) + 2
    end

    for i = ti + 1, table.getn(titleRows) do titleRows[i]:Hide() end
    for i = oi + 1, table.getn(objRows) do objRows[i]:Hide() end
    container:SetHeight(y + PAD)
    container:Show()
  end

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("QUEST_LOG_UPDATE")
  ev:RegisterEvent("QUEST_WATCH_UPDATE")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("PLAYER_LOGOUT")
  ev:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
      this:UnregisterAllEvents()
      this:SetScript("OnEvent", nil)
      return
    end
    if event == "PLAYER_ENTERING_WORLD" then
      -- merge the live Blizzard watch list (the player's existing <=5 watches)
      -- into our set so they show up; from here our set is the source of truth.
      if GetNumQuestWatches and GetQuestIndexForWatch then
        for w = 1, GetNumQuestWatches() do
          local t = TitleOf(GetQuestIndexForWatch(w))
          if t then HoryUIDB.questTracked[t] = true end
        end
      end
    end
    Update()
  end)

  -- Tracking a quest fires no event, and the engine caps the watch list at 5 --
  -- so we hook the mutators (no hooksecurefunc in 1.12, save + replace) to keep
  -- OUR uncapped set in sync. orig() still runs so Blizzard's first 5 stay normal.
  if AddQuestWatch then
    local orig = AddQuestWatch
    AddQuestWatch = function(a1, a2, a3, a4, a5)
      local t = TitleOf(a1)
      if t then HoryUIDB.questTracked[t] = true end
      local r1, r2, r3 = orig(a1, a2, a3, a4, a5)
      Update()
      return r1, r2, r3
    end
  end
  if RemoveQuestWatch then
    local orig = RemoveQuestWatch
    RemoveQuestWatch = function(a1, a2, a3, a4, a5)
      local t = TitleOf(a1)
      if t then HoryUIDB.questTracked[t] = nil end
      local r1, r2, r3 = orig(a1, a2, a3, a4, a5)
      Update()
      return r1, r2, r3
    end
  end

  -- THE FIX for "they aren't actually checked in the quest log": make
  -- IsQuestWatched report OUR set. Both the quest-log checkmark AND the
  -- shift-click toggle read it -- the toggle calls RemoveQuestWatch when it's
  -- watched, AddQuestWatch when it isn't. The engine only marks the first 5 as
  -- watched, so without this a 6th+ quest reads "not watched" and shift-click
  -- always re-adds (never removes). Reporting our set makes shift-click untrack
  -- them and the quest log show them checked, exactly like the first 5.
  if IsQuestWatched then
    local orig = IsQuestWatched
    IsQuestWatched = function(qid)
      local t = TitleOf(qid)
      if t and HoryUIDB.questTracked[t] then return 1 end
      return orig(qid)
    end
  end

  -- Suppress the stock right-side QuestWatchFrame (reparented to a hidden frame,
  -- so the engine's QuestWatch_Update can't surface it).
  if QuestWatchFrame then HoryUI.HideBlizzard(QuestWatchFrame) end

  HoryUI.RegisterPanel(container, "questtracker", "Quest Tracker", "TOPRIGHT", -16, -220)

  -- Always draggable (like bags): drag the panel directly, not only via the
  -- unlock-mover. RegisterPanel already made it SetMovable; persist on stop.
  -- Quest-title clicks (collapse / untrack) still work -- grab the header or any
  -- empty area to drag, since a click without movement won't start a drag.
  container:EnableMouse(true)
  container:RegisterForDrag("LeftButton")
  container:SetScript("OnDragStart", function() this:StartMoving() end)
  container:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    HoryUI.SavePosition(this, "questtracker")
  end)

  HoryUI.AddRefresher(Update)
  Update()
end)
