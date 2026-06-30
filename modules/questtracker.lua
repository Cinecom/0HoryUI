-- HoryUI :: quest tracker -- a draggable, Garnet-styled panel mirroring the
-- shift-click quest watch (replaces the default right-side QuestWatchFrame).
-- Each objective is colour-coded by progress: green = complete, red = none yet
-- (0/x), orange = in progress. A quest title turns green once all its objectives
-- are done (ready to turn in).
--
-- API (1.12, verified against FrameXML/QuestLogFrame.lua + pfQuest on this client):
--   GetNumQuestWatches() / GetQuestIndexForWatch(w) -> quest-log index
--   GetQuestLogTitle(qid) -> title, level, questTag, isHeader, isCollapsed, isComplete
--   GetNumQuestLeaderBoards(qid) / GetQuestLogLeaderBoard(o, qid) -> text, type, finished
--   (both leaderboard calls take the quest-log index, so we never SelectQuestLogEntry
--    and so never disturb an open quest log.)

HoryUI:RegisterModule("questtracker", true, function()
  local C = HoryUI.color
  local GREEN  = C.health         -- objective complete
  local ORANGE = C.threat         -- objective in progress
  local RED    = C.name_hostile   -- objective not started (0 / x)

  local WIDTH, PAD, INDENT = 240, 8, 12

  local container = CreateFrame("Frame", "HoryUIQuestTracker", UIParent)
  container:SetWidth(WIDTH)
  container:SetHeight(40)
  container:SetFrameStrata("MEDIUM")
  HoryUI.CreateBackdrop(container)

  local rows = {}
  local function GetRow(i)
    if rows[i] then return rows[i] end
    local fs = container:CreateFontString(nil, "OVERLAY")
    fs:SetJustifyH("LEFT")
    rows[i] = fs
    return fs
  end

  -- One row's font + width + (single) top-left anchor; height comes from the text.
  local function PlaceRow(fs, size, w, x, y, col)
    HoryUI.SetFont(fs, HoryUI.font.normal, size, "OUTLINE")
    fs:SetWidth(w)
    fs:SetTextColor(col[1], col[2], col[3])
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", container, "TOPLEFT", x, -y)
  end

  local function RowHeight(fs, minH)
    local h = fs:GetHeight()
    if not h or h < minH then return minH end
    return h
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

  local function Update()
    if not (GetNumQuestWatches and GetQuestIndexForWatch) then container:Hide(); return end
    local n = GetNumQuestWatches()
    local innerW = WIDTH - PAD * 2
    local y = PAD
    local r = 0

    -- garnet panel header
    r = r + 1
    local hdr = GetRow(r)
    PlaceRow(hdr, 11, innerW, PAD, y, C.accent_hi)
    hdr:SetText("Quests")
    hdr:Show()
    y = y + RowHeight(hdr, 12) + 4

    local shown = 0
    for w = 1, n do
      local qid = GetQuestIndexForWatch(w)
      if qid and qid > 0 then
        local title, _, _, isHeader = GetQuestLogTitle(qid)
        if title and not isHeader then
          shown = shown + 1

          -- gather objectives first so the title can reflect overall completion
          local numObj = GetNumQuestLeaderBoards(qid) or 0
          local allDone = true
          local objText, objCol = {}, {}
          for o = 1, numObj do
            local otext, otype, ofin = GetQuestLogLeaderBoard(o, qid)
            if not otext or otext == "" then otext = otype or "" end
            local col = ObjColor(otext, ofin)
            if col ~= GREEN then allDone = false end
            objText[o] = otext
            objCol[o] = col
          end

          -- title (green once the whole quest is complete)
          r = r + 1
          local tr = GetRow(r)
          PlaceRow(tr, 12, innerW, PAD, y, allDone and GREEN or C.text)
          tr:SetText(title)
          tr:Show()
          y = y + RowHeight(tr, 13) + 2

          -- objectives, indented and colour-coded
          for o = 1, numObj do
            r = r + 1
            local orow = GetRow(r)
            PlaceRow(orow, 11, innerW - INDENT, PAD + INDENT, y, objCol[o])
            orow:SetText(objText[o])
            orow:Show()
            y = y + RowHeight(orow, 12) + 1
          end

          y = y + 6   -- gap between quests
        end
      end
    end

    if shown == 0 then
      if not HoryUI.showAll then
        for i = 1, table.getn(rows) do rows[i]:Hide() end
        container:Hide()
        return
      end
      r = r + 1
      local ph = GetRow(r)
      PlaceRow(ph, 11, innerW, PAD, y, C.text3)
      ph:SetText("No quests tracked")
      ph:Show()
      y = y + RowHeight(ph, 12) + 2
    end

    for i = r + 1, table.getn(rows) do rows[i]:Hide() end
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
    Update()
  end)

  -- Suppress the stock right-side QuestWatchFrame (reparented to a hidden frame,
  -- so the engine's QuestWatch_Update can't surface it). Shift-click tracking is
  -- unaffected -- it only toggles the watch list, which we read.
  if QuestWatchFrame then HoryUI.HideBlizzard(QuestWatchFrame) end

  HoryUI.RegisterPanel(container, "questtracker", "Quest Tracker", "TOPRIGHT", -16, -220)
  HoryUI.AddRefresher(Update)
  Update()
end)
