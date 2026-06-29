if HoryUI._pfuiActive then return end
-- load pfSkin environment
setfenv(1, pfSkin:GetEnvironment())

function pfSkin:UpdateConfig(group, subgroup, entry, value)
  -- create empty config if not existing
  if not pfSkin_config then
    _G.pfSkin_config = {}
  end

  -- check for missing config groups
  if not pfSkin_config[group] then
    pfSkin_config[group] = {}
  end

  -- update config
  if not subgroup and entry and value and not pfSkin_config[group][entry] then
    pfSkin_config[group][entry] = value
  end

  -- check for missing config subgroups
  if subgroup and not pfSkin_config[group][subgroup] then
    pfSkin_config[group][subgroup] = {}
  end

  -- update config in subgroup
  if subgroup and entry and value and not pfSkin_config[group][subgroup][entry] then
    pfSkin_config[group][subgroup][entry] = value
  end
end

function pfSkin:LoadConfig()
  --                MODULE        SUBGROUP       ENTRY               VALUE
  pfSkin:UpdateConfig("global",     nil,           "language",         GetLocale())
  pfSkin:UpdateConfig("global",     nil,           "profile",          "default")
  pfSkin:UpdateConfig("global",     nil,           "pixelperfect",     "0")
  pfSkin:UpdateConfig("global",     nil,           "offscreen",        "0")

  pfSkin:UpdateConfig("global",     nil,           "font_blizzard",    "0")
  pfSkin:UpdateConfig("global",     nil,           "font_default",     "Interface\\AddOns\\pfSkin\\fonts\\Myriad-Pro.ttf")
  pfSkin:UpdateConfig("global",     nil,           "font_size",        "12")
  pfSkin:UpdateConfig("global",     nil,           "font_unit",        "Interface\\AddOns\\pfSkin\\fonts\\BigNoodleTitling.ttf")
  pfSkin:UpdateConfig("global",     nil,           "font_unit_size",   "12")
  pfSkin:UpdateConfig("global",     nil,           "font_unit_style",  "OUTLINE")
  pfSkin:UpdateConfig("global",     nil,           "font_unit_name",   "Interface\\AddOns\\pfSkin\\fonts\\Myriad-Pro.ttf")
  pfSkin:UpdateConfig("global",     nil,           "font_combat",      "Interface\\AddOns\\pfSkin\\fonts\\Continuum.ttf")

  pfSkin:UpdateConfig("global",     nil,           "force_region",     "1")
  pfSkin:UpdateConfig("global",     nil,           "errors",           "1")
  pfSkin:UpdateConfig("global",     nil,           "errors_limit",     "1")
  pfSkin:UpdateConfig("global",     nil,           "errors_hide",      "0")
  pfSkin:UpdateConfig("global",     nil,           "hidebuff",         "0")
  pfSkin:UpdateConfig("global",     nil,           "hidewbuff",        "0")
  pfSkin:UpdateConfig("global",     nil,           "twentyfour",       "1")
  pfSkin:UpdateConfig("global",     nil,           "servertime",       "0")
  pfSkin:UpdateConfig("global",     nil,           "autosell",         "0")
  pfSkin:UpdateConfig("global",     nil,           "autorepair",       "0")
  pfSkin:UpdateConfig("global",     nil,           "libhealth",        "1")
  pfSkin:UpdateConfig("global",     nil,           "libhealth_hit",    "4")
  pfSkin:UpdateConfig("global",     nil,           "libhealth_dmg",    ".05")

  pfSkin:UpdateConfig("gui",        nil,           "reloadmarker",     "0")
  pfSkin:UpdateConfig("gui",        nil,           "showdisabled",     "0")

  pfSkin:UpdateConfig("buffs",      nil,           "buffs",            "1")
  pfSkin:UpdateConfig("buffs",      nil,           "debuffs",          "1")
  pfSkin:UpdateConfig("buffs",      nil,           "weapons",          "1")
  pfSkin:UpdateConfig("buffs",      nil,           "separateweapons",  "0")
  pfSkin:UpdateConfig("buffs",      nil,           "size",             "24")
  pfSkin:UpdateConfig("buffs",      nil,           "spacing",          "5")
  pfSkin:UpdateConfig("buffs",      nil,           "wepbuffrowsize",   "2")
  pfSkin:UpdateConfig("buffs",      nil,           "buffrowsize",      "16")
  pfSkin:UpdateConfig("buffs",      nil,           "debuffrowsize",    "16")
  pfSkin:UpdateConfig("buffs",      nil,           "textinside",       "0")
  pfSkin:UpdateConfig("buffs",      nil,           "fontsize",         "-1")

  pfSkin:UpdateConfig("buffbar",    "pbuff",       "enable",           "0")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "use_unitfonts",    "0")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "sort",             "asc")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "color",            ".5,.5,.5,1")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "bordercolor",      "0,0,0,0")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "textcolor",        "1,1,1,1")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "dtypebg",          "1")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "dtypeborder",      "0")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "dtypetext",        "0")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "colorstacks",      "0")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "width",            "-1")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "height",           "20")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "filter",           "blacklist")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "threshold",        "120")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "whitelist",        "")
  pfSkin:UpdateConfig("buffbar",    "pbuff",       "blacklist",        "")

  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "enable",           "0")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "use_unitfonts",    "0")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "sort",             "asc")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "color",            "8,.4,.4,1")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "bordercolor",      "0,0,0,0")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "textcolor",        "1,1,1,1")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "dtypebg",          "0")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "dtypeborder",      "1")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "dtypetext",        "0")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "colorstacks",      "0")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "width",            "-1")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "height",           "20")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "filter",           "blacklist")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "threshold",        "120")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "whitelist",        "")
  pfSkin:UpdateConfig("buffbar",    "pdebuff",     "blacklist",        "")

  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "enable",           "0")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "use_unitfonts",    "0")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "sort",             "asc")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "color",            ".8,.4,.4,1")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "bordercolor",      "0,0,0,0")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "textcolor",        "1,1,1,1")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "dtypebg",          "0")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "dtypeborder",      "1")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "dtypetext",        "0")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "colorstacks",      "0")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "width",            "-1")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "height",           "20")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "selfdebuff",       "0")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "filter",           "blacklist")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "threshold",        "120")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "whitelist",        "")
  pfSkin:UpdateConfig("buffbar",    "tdebuff",     "blacklist",        "")

  pfSkin:UpdateConfig("appearance", "border",      "background",       "0,0,0,1")
  pfSkin:UpdateConfig("appearance", "border",      "color",            "0.2,0.2,0.2,1")
  pfSkin:UpdateConfig("appearance", "border",      "shadow",           "0")
  pfSkin:UpdateConfig("appearance", "border",      "shadow_intensity", ".35")
  pfSkin:UpdateConfig("appearance", "border",      "pixelperfect",     "1")
  pfSkin:UpdateConfig("appearance", "border",      "force_blizz",      "0")
  pfSkin:UpdateConfig("appearance", "border",      "hidpi",            "1")
  pfSkin:UpdateConfig("appearance", "border",      "default",          "3")
  pfSkin:UpdateConfig("appearance", "border",      "nameplates",       "-1")
  pfSkin:UpdateConfig("appearance", "border",      "actionbars",       "-1")
  pfSkin:UpdateConfig("appearance", "border",      "unitframes",       "-1")
  pfSkin:UpdateConfig("appearance", "border",      "panels",           "-1")
  pfSkin:UpdateConfig("appearance", "border",      "chat",             "-1")
  pfSkin:UpdateConfig("appearance", "border",      "bags",             "-1")
  pfSkin:UpdateConfig("appearance", "cd",          "lowcolor",         "1,.2,.2,1")
  pfSkin:UpdateConfig("appearance", "cd",          "normalcolor",      "1,1,1,1")
  pfSkin:UpdateConfig("appearance", "cd",          "minutecolor",      ".2,1,1,1")
  pfSkin:UpdateConfig("appearance", "cd",          "hourcolor",        ".2,.5,1,1")
  pfSkin:UpdateConfig("appearance", "cd",          "daycolor",         ".2,.2,1,1")
  pfSkin:UpdateConfig("appearance", "cd",          "threshold",        "2")
  pfSkin:UpdateConfig("appearance", "cd",          "font_size",        "12")
  pfSkin:UpdateConfig("appearance", "cd",          "font_size_blizz",  "12")
  pfSkin:UpdateConfig("appearance", "cd",          "font_size_foreign","12")
  pfSkin:UpdateConfig("appearance", "cd",          "blizzard",         "1")
  pfSkin:UpdateConfig("appearance", "cd",          "foreign",          "0")
  pfSkin:UpdateConfig("appearance", "cd",          "milliseconds",     "1")
  pfSkin:UpdateConfig("appearance", "cd",          "hideanim",         "0")
  pfSkin:UpdateConfig("appearance", "cd",          "font",             "Interface\\AddOns\\pfSkin\\fonts\\BigNoodleTitling.ttf")
  pfSkin:UpdateConfig("appearance", "cd",          "dynamicsize",      "1")
  pfSkin:UpdateConfig("appearance", "castbar",     "castbarcolor",     ".7,.7,.9,.8")
  pfSkin:UpdateConfig("appearance", "castbar",     "channelcolor",     ".9,.9,.7,.8")
  pfSkin:UpdateConfig("appearance", "castbar",     "texture",          "Interface\\AddOns\\pfSkin\\img\\bar")
  pfSkin:UpdateConfig("appearance", "infight",     "screen",           "0")
  pfSkin:UpdateConfig("appearance", "infight",     "aggro",            "0")
  pfSkin:UpdateConfig("appearance", "infight",     "health",           "1")
  pfSkin:UpdateConfig("appearance", "infight",     "intensity",           "16")
  pfSkin:UpdateConfig("appearance", "bags",        "unusable",         "1")
  pfSkin:UpdateConfig("appearance", "bags",        "unusable_color",   ".9,.2,.2,1")
  pfSkin:UpdateConfig("appearance", "bags",        "borderlimit",      "1")
  pfSkin:UpdateConfig("appearance", "bags",        "borderonlygear",   "0")
  pfSkin:UpdateConfig("appearance", "bags",        "fulltext",         "1")
  pfSkin:UpdateConfig("appearance", "bags",        "movable",          "0")
  pfSkin:UpdateConfig("appearance", "bags",        "abovechat",        "0")
  pfSkin:UpdateConfig("appearance", "bags",        "hidechat",         "0")
  pfSkin:UpdateConfig("appearance", "bags",        "icon_size",        "-1")
  pfSkin:UpdateConfig("appearance", "bags",        "bagrowlength",     "10")
  pfSkin:UpdateConfig("appearance", "bags",        "bankrowlength",    "10")
  pfSkin:UpdateConfig("appearance", "minimap",     "size",             "140")
  pfSkin:UpdateConfig("appearance", "minimap",     "arrowscale",       "1")
  pfSkin:UpdateConfig("appearance", "minimap",     "zonetext",         "off")
  pfSkin:UpdateConfig("appearance", "minimap",     "coordstext",       "mouseover")
  pfSkin:UpdateConfig("appearance", "minimap",     "coordsloc",        "bottomleft")
  pfSkin:UpdateConfig("appearance", "minimap",     "tracking_size",    "16")
  pfSkin:UpdateConfig("appearance", "minimap",     "tracking_pulse",   "1")
  pfSkin:UpdateConfig("appearance", "minimap",     "addon_buttons",    "0")
  pfSkin:UpdateConfig("appearance", "worldmap",    "tooltipsize",      "0")
  pfSkin:UpdateConfig("appearance", "worldmap",    "autozoneswitch",   "1")
  pfSkin:UpdateConfig("appearance", "worldmap",    "mapreveal",        "0")
  pfSkin:UpdateConfig("appearance", "worldmap",    "mapreveal_color",  ".4,.4,.4,1")
  pfSkin:UpdateConfig("appearance", "worldmap",    "mapexploration",   "0")
  pfSkin:UpdateConfig("appearance", "worldmap",    "groupcircles",     "3")
  pfSkin:UpdateConfig("appearance", "worldmap",    "colornames",       "1")

  pfSkin:UpdateConfig("loot",       nil,           "autoresize",       "1")
  pfSkin:UpdateConfig("loot",       nil,           "autopickup",       "1")
  pfSkin:UpdateConfig("loot",       nil,           "mousecursor",      "1")
  pfSkin:UpdateConfig("loot",       nil,           "advancedloot",     "1")
  pfSkin:UpdateConfig("loot",       nil,           "rollannouncequal", "3")
  pfSkin:UpdateConfig("loot",       nil,           "rollannounce",     "0")
  pfSkin:UpdateConfig("loot",       nil,           "raritytimer",      "1")

  pfSkin:UpdateConfig("unitframes", nil,           "disable",          "0")
  pfSkin:UpdateConfig("unitframes", nil,           "pastel",           "1")
  pfSkin:UpdateConfig("unitframes", nil,           "custom",           "0")
  pfSkin:UpdateConfig("unitframes", nil,           "customfullhp",     "0")
  pfSkin:UpdateConfig("unitframes", nil,           "customfade",       "0")
  pfSkin:UpdateConfig("unitframes", nil,           "customcolor",      ".2,.2,.2,1")
  pfSkin:UpdateConfig("unitframes", nil,           "custombg",         "0")
  pfSkin:UpdateConfig("unitframes", nil,           "custombgcolor",    ".5,.2,.2,1")
  pfSkin:UpdateConfig("unitframes", nil,           "custompbg",        "0")
  pfSkin:UpdateConfig("unitframes", nil,           "custompbgcolor",   ".5,.2,.2,1")
  pfSkin:UpdateConfig("unitframes", nil,           "manacolor",        ".5,.5,1,1")
  pfSkin:UpdateConfig("unitframes", nil,           "energycolor",      "1,1,.5,1")
  pfSkin:UpdateConfig("unitframes", nil,           "ragecolor",        "1,.5,.5,1")
  pfSkin:UpdateConfig("unitframes", nil,           "focuscolor",       "1,1,.75,1")

  pfSkin:UpdateConfig("unitframes", nil,           "animation_speed",  "5")
  pfSkin:UpdateConfig("unitframes", nil,           "portraitalpha",    "0.1")
  pfSkin:UpdateConfig("unitframes", nil,           "always2dportrait", "0")
  pfSkin:UpdateConfig("unitframes", nil,           "portraittexture",  "1")
  pfSkin:UpdateConfig("unitframes", nil,           "layout",           "default")
  pfSkin:UpdateConfig("unitframes", nil,           "rangecheck",       "0")
  pfSkin:UpdateConfig("unitframes", nil,           "rangecheck_mode",  "vanilla")
  pfSkin:UpdateConfig("unitframes", nil,           "rangecheck_distance", "40")
  pfSkin:UpdateConfig("unitframes", nil,           "buffdetect",       "0")
  pfSkin:UpdateConfig("unitframes", nil,           "druidmanabar",     "1")
  pfSkin:UpdateConfig("unitframes", nil,           "druidmanaheight",  "10")
  pfSkin:UpdateConfig("unitframes", nil,           "druidmanawidth",   "-1")
  pfSkin:UpdateConfig("unitframes", nil,           "druidmanaoffx",    "0")
  pfSkin:UpdateConfig("unitframes", nil,           "druidmanaoffy",    "0")
  pfSkin:UpdateConfig("unitframes", nil,           "druidmanaspace",   "-3")
  pfSkin:UpdateConfig("unitframes", nil,           "druidmanatexture", "Interface\\AddOns\\pfSkin\\img\\bar")

  pfSkin:UpdateConfig("unitframes", nil,           "rangechecki",      "4")
  pfSkin:UpdateConfig("unitframes", nil,           "combowidth",       "6")
  pfSkin:UpdateConfig("unitframes", nil,           "comboheight",      "6")
  pfSkin:UpdateConfig("unitframes", nil,           "swingtimerwidth",  "200")
  pfSkin:UpdateConfig("unitframes", nil,           "swingtimerheight", "12")
  pfSkin:UpdateConfig("unitframes", nil,           "swingtimertexture", "Interface\\AddOns\\pfSkin\\img\\bar")
  pfSkin:UpdateConfig("unitframes", nil,           "swingtimertext",   "1")
  pfSkin:UpdateConfig("unitframes", nil,           "swingtimerlabel",  "1")
  pfSkin:UpdateConfig("unitframes", nil,           "swingtimeroffhand","1")
  pfSkin:UpdateConfig("unitframes", nil,           "swingtimerranged", "1")
  pfSkin:UpdateConfig("unitframes", nil,           "swingtimerfontsize","12")
  pfSkin:UpdateConfig("unitframes", nil,           "swingtimermhcolor",".8,.3,.3,1")
  pfSkin:UpdateConfig("unitframes", nil,           "swingtimerohcolor",".3,.8,.3,1")
  pfSkin:UpdateConfig("unitframes", nil,           "swingtimerrangedcolor",".3,.6,1,1")
  pfSkin:UpdateConfig("unitframes", nil,           "swingtimerrangedwarncolor",".9,0,0,1")
  pfSkin:UpdateConfig("unitframes", nil,           "swingtimerhsqueue","1")
  pfSkin:UpdateConfig("unitframes", nil,           "swingtimerattackspeed","0")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkerwidth",  "80")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkerheight", "14")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkergrow",   "down")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkertexture", "Interface\\AddOns\\pfSkin\\img\\bar")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkerfontsize","12")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkershowname","1")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkershowpct","1")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkershownumhp","0")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkershowportrait","0")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkercolor_star",     "1,.9,0,1")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkercolor_circle",   "1,.5,0,1")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkercolor_diamond",  ".8,0,.8,1")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkercolor_triangle", "0,.8,0,1")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkercolor_moon",     ".7,.7,.7,1")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkercolor_square",   "0,.4,.9,1")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkercolor_cross",    ".9,0,0,1")
  pfSkin:UpdateConfig("unitframes", nil,           "raidmarkercolor_skull",    "1,1,1,1")
  pfSkin:UpdateConfig("unitframes", nil,           "abbrevnum",        "1")
  pfSkin:UpdateConfig("unitframes", nil,           "castbardecimals",  "2")
  pfSkin:UpdateConfig("unitframes", nil,           "abbrevname",       "1")

  -- Nampower Settings
  pfSkin:UpdateConfig("unitframes", nil,           "spellqueue",       "1")
  pfSkin:UpdateConfig("unitframes", nil,           "spellqueuesize",   "24")
  pfSkin:UpdateConfig("unitframes", nil,           "gcd_indicator",    "0")
  pfSkin:UpdateConfig("unitframes", nil,           "gcd_size",         "4")
  pfSkin:UpdateConfig("unitframes", nil,           "reactive_indicator", "0")
  pfSkin:UpdateConfig("unitframes", nil,           "reactive_size",    "28")
  pfSkin:UpdateConfig("unitframes", nil,           "damage_tracking",  "0")

  -- UnitXP Settings
  pfSkin:UpdateConfig("unitframes", nil,           "unitxp_font_size",    "13")
  pfSkin:UpdateConfig("unitframes", nil,           "los_indicator",    "0")
  pfSkin:UpdateConfig("unitframes", nil,           "behind_indicator", "0")
  pfSkin:UpdateConfig("unitframes", nil,           "hide_distance_yd", "0")
  pfSkin:UpdateConfig("unitframes", nil,           "unitxp_notify",    "0")
  pfSkin:UpdateConfig("unitframes", nil,           "track_group",      "0")

  pfSkin:UpdateConfig("unitframes", nil,           "selfingroup",      "0")
  pfSkin:UpdateConfig("unitframes", nil,           "selfinraid",       "0")
  pfSkin:UpdateConfig("unitframes", nil,           "raidforgroup",     "0")
  pfSkin:UpdateConfig("unitframes", nil,           "maxraid",          "40")

  pfSkin:UpdateConfig("unitframes", nil,           "clickcast",        "target")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast_shift",  "")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast_alt",    "")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast_ctrl",   "")

  pfSkin:UpdateConfig("unitframes", nil,           "clickcast2",        "menu")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast2_shift",  "")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast2_alt",    "")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast2_ctrl",   "")

  pfSkin:UpdateConfig("unitframes", nil,           "clickcast3",        "")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast3_shift",  "")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast3_alt",    "")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast3_ctrl",   "")

  pfSkin:UpdateConfig("unitframes", nil,           "clickcast4",        "")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast4_shift",  "")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast4_alt",    "")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast4_ctrl",   "")

  pfSkin:UpdateConfig("unitframes", nil,           "clickcast5",        "")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast5_shift",  "")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast5_alt",    "")
  pfSkin:UpdateConfig("unitframes", nil,           "clickcast5_ctrl",   "")

  pfSkin:UpdateConfig("unitframes", "player",      "showPVPMinimap",          "0")
  pfSkin:UpdateConfig("unitframes", "player",      "showRest",                "0")
  pfSkin:UpdateConfig("unitframes", "player",      "energy",                  "1")
  pfSkin:UpdateConfig("unitframes", "player",      "manatick",                "0")
  pfSkin:UpdateConfig("unitframes", "player",      "display_haste",           "0")
  pfSkin:UpdateConfig("unitframes", "player",      "display_haste_color",     "1,1,1,1")
  pfSkin:UpdateConfig("unitframes", "player",      "display_spellpower",      "1")
  pfSkin:UpdateConfig("unitframes", "player",      "display_sp_color_override", "0")
  pfSkin:UpdateConfig("unitframes", "player",      "display_sp_color",        "")

  pfSkin:UpdateConfig("unitframes", "focus",       "width",            "120")
  pfSkin:UpdateConfig("unitframes", "focus",       "height",           "34")
  pfSkin:UpdateConfig("unitframes", "focus",       "pheight",          "4")
  pfSkin:UpdateConfig("unitframes", "focus",       "buffsize",         "12")
  pfSkin:UpdateConfig("unitframes", "focus",       "debuffsize",       "12")

  pfSkin:UpdateConfig("unitframes", "focustarget", "visible",          "0")
  pfSkin:UpdateConfig("unitframes", "focustarget", "width",            "80")
  pfSkin:UpdateConfig("unitframes", "focustarget", "height",           "12")
  pfSkin:UpdateConfig("unitframes", "focustarget", "pheight",          "-1")
  pfSkin:UpdateConfig("unitframes", "focustarget", "buffs",            "off")
  pfSkin:UpdateConfig("unitframes", "focustarget", "debuffs",          "off")
  pfSkin:UpdateConfig("unitframes", "focustarget", "txthpleft",        "none")
  pfSkin:UpdateConfig("unitframes", "focustarget", "txthpcenter",      "name")
  pfSkin:UpdateConfig("unitframes", "focustarget", "txthpright",       "none")

  pfSkin:UpdateConfig("unitframes", "group",       "portrait",         "off")
  pfSkin:UpdateConfig("unitframes", "group",       "width",            "164")
  pfSkin:UpdateConfig("unitframes", "group",       "height",           "32")
  pfSkin:UpdateConfig("unitframes", "group",       "pheight",          "4")
  pfSkin:UpdateConfig("unitframes", "group",       "buffs",            "BOTTOMLEFT")
  pfSkin:UpdateConfig("unitframes", "group",       "buffsize",         "8")
  pfSkin:UpdateConfig("unitframes", "group",       "debuffs",          "BOTTOMLEFT")
  pfSkin:UpdateConfig("unitframes", "group",       "debuffsize",       "8")
  pfSkin:UpdateConfig("unitframes", "group",       "debufflimit",      "8")
  pfSkin:UpdateConfig("unitframes", "group",       "buff_indicator",   "1")
  pfSkin:UpdateConfig("unitframes", "group",       "debuff_indicator", "2")
  pfSkin:UpdateConfig("unitframes", "group",       "faderange",        "1")
  pfSkin:UpdateConfig("unitframes", "group",       "glowcombat",       "0")
  pfSkin:UpdateConfig("unitframes", "group",       "hide_in_raid",     "0")
  pfSkin:UpdateConfig("unitframes", "group",       "txthpright",       "healthmiss")

  pfSkin:UpdateConfig("unitframes", "grouptarget", "portrait",         "off")
  pfSkin:UpdateConfig("unitframes", "grouptarget", "width",            "120")
  pfSkin:UpdateConfig("unitframes", "grouptarget", "height",           "16")
  pfSkin:UpdateConfig("unitframes", "grouptarget", "pheight",          "0")
  pfSkin:UpdateConfig("unitframes", "grouptarget", "buffs",            "off")
  pfSkin:UpdateConfig("unitframes", "grouptarget", "buffsize",         "16")
  pfSkin:UpdateConfig("unitframes", "grouptarget", "debuffs",          "off")
  pfSkin:UpdateConfig("unitframes", "grouptarget", "debuffsize",       "16")
  pfSkin:UpdateConfig("unitframes", "grouptarget", "faderange",        "1")
  pfSkin:UpdateConfig("unitframes", "grouptarget", "glowcombat",       "0")
  pfSkin:UpdateConfig("unitframes", "grouptarget", "txthpright",       "healthperc")

  pfSkin:UpdateConfig("unitframes", "grouppet",    "portrait",         "off")
  pfSkin:UpdateConfig("unitframes", "grouppet",    "width",            "100")
  pfSkin:UpdateConfig("unitframes", "grouppet",    "height",           "14")
  pfSkin:UpdateConfig("unitframes", "grouppet",    "pheight",          "0")
  pfSkin:UpdateConfig("unitframes", "grouppet",    "buffs",            "off")
  pfSkin:UpdateConfig("unitframes", "grouppet",    "buffsize",         "16")
  pfSkin:UpdateConfig("unitframes", "grouppet",    "debuffs",          "off")
  pfSkin:UpdateConfig("unitframes", "grouppet",    "debuffsize",       "16")
  pfSkin:UpdateConfig("unitframes", "grouppet",    "faderange",        "1")
  pfSkin:UpdateConfig("unitframes", "grouppet",    "glowcombat",       "0")
  pfSkin:UpdateConfig("unitframes", "grouppet",    "txthpright",       "healthperc")

  pfSkin:UpdateConfig("unitframes", "raid",        "portrait",         "off")
  pfSkin:UpdateConfig("unitframes", "raid",        "width",            "50")
  pfSkin:UpdateConfig("unitframes", "raid",        "height",           "26")
  pfSkin:UpdateConfig("unitframes", "raid",        "pheight",          "4")
  pfSkin:UpdateConfig("unitframes", "raid",        "buffs",            "off")
  pfSkin:UpdateConfig("unitframes", "raid",        "buffsize",         "16")
  pfSkin:UpdateConfig("unitframes", "raid",        "debuffs",          "off")
  pfSkin:UpdateConfig("unitframes", "raid",        "debuffsize",       "16")
  pfSkin:UpdateConfig("unitframes", "raid",        "buff_indicator",   "1")
  pfSkin:UpdateConfig("unitframes", "raid",        "debuff_indicator", "2")
  pfSkin:UpdateConfig("unitframes", "raid",        "faderange",        "1")
  pfSkin:UpdateConfig("unitframes", "raid",        "glowcombat",       "0")
  pfSkin:UpdateConfig("unitframes", "raid",        "txthpleft",        "name")
  pfSkin:UpdateConfig("unitframes", "raid",        "txthpright",       "healthmiss")
  pfSkin:UpdateConfig("unitframes", "raid",        "overhealperc",     "10")
  pfSkin:UpdateConfig("unitframes", "raid",        "raidlayout",       "8x5")
  pfSkin:UpdateConfig("unitframes", "raid",        "raidpadding",      "3")
  pfSkin:UpdateConfig("unitframes", "raid",        "raidfill",         "VERTICAL")
  pfSkin:UpdateConfig("unitframes", "raid",        "raidgrouplabel",   "0")
  pfSkin:UpdateConfig("unitframes", "raid",        "grouplabelxoff",   "0")
  pfSkin:UpdateConfig("unitframes", "raid",        "grouplabelyoff",   "8")
  pfSkin:UpdateConfig("unitframes", "raid",        "squareaggro",      "1")
  pfSkin:UpdateConfig("unitframes", "raid",        "squaresize",       "6")

  pfSkin:UpdateConfig("unitframes", "ttarget",     "width",            "100")
  pfSkin:UpdateConfig("unitframes", "ttarget",     "height",           "17")
  pfSkin:UpdateConfig("unitframes", "ttarget",     "pheight",          "3")
  pfSkin:UpdateConfig("unitframes", "ttarget",     "buffs",            "off")
  pfSkin:UpdateConfig("unitframes", "ttarget",     "buffsize",         "16")
  pfSkin:UpdateConfig("unitframes", "ttarget",     "debuffs",          "off")
  pfSkin:UpdateConfig("unitframes", "ttarget",     "debuffsize",       "16")
  pfSkin:UpdateConfig("unitframes", "ttarget",     "txthpleft",        "none")
  pfSkin:UpdateConfig("unitframes", "ttarget",     "txthpcenter",      "name")
  pfSkin:UpdateConfig("unitframes", "ttarget",     "txthpright",       "none")
  pfSkin:UpdateConfig("unitframes", "ttarget",     "overhealperc",     "10")

  pfSkin:UpdateConfig("unitframes", "tttarget",    "visible",          "0")
  pfSkin:UpdateConfig("unitframes", "tttarget",    "width",            "100")
  pfSkin:UpdateConfig("unitframes", "tttarget",    "height",           "17")
  pfSkin:UpdateConfig("unitframes", "tttarget",    "pheight",          "3")
  pfSkin:UpdateConfig("unitframes", "tttarget",    "buffs",            "off")
  pfSkin:UpdateConfig("unitframes", "tttarget",    "buffsize",         "16")
  pfSkin:UpdateConfig("unitframes", "tttarget",    "debuffs",          "off")
  pfSkin:UpdateConfig("unitframes", "tttarget",    "debuffsize",       "16")
  pfSkin:UpdateConfig("unitframes", "tttarget",    "txthpleft",        "none")
  pfSkin:UpdateConfig("unitframes", "tttarget",    "txthpcenter",      "name")
  pfSkin:UpdateConfig("unitframes", "tttarget",    "txthpright",       "none")
  pfSkin:UpdateConfig("unitframes", "tttarget",    "overhealperc",     "10")

  pfSkin:UpdateConfig("unitframes", "pet",         "happinessicon",    "2")
  pfSkin:UpdateConfig("unitframes", "pet",         "happinesssize",    "12")
  pfSkin:UpdateConfig("unitframes", "pet",         "width",            "100")
  pfSkin:UpdateConfig("unitframes", "pet",         "height",           "14")
  pfSkin:UpdateConfig("unitframes", "pet",         "pheight",          "4")
  pfSkin:UpdateConfig("unitframes", "pet",         "buffsize",         "12")
  pfSkin:UpdateConfig("unitframes", "pet",         "debuffsize",       "12")
  pfSkin:UpdateConfig("unitframes", "pet",         "txthpleft",        "none")
  pfSkin:UpdateConfig("unitframes", "pet",         "txthpcenter",      "name")
  pfSkin:UpdateConfig("unitframes", "pet",         "txthpright",       "none")

  pfSkin:UpdateConfig("unitframes", "ptarget",     "visible",          "0")
  pfSkin:UpdateConfig("unitframes", "ptarget",     "width",            "100")
  pfSkin:UpdateConfig("unitframes", "ptarget",     "height",           "4")
  pfSkin:UpdateConfig("unitframes", "ptarget",     "pheight",          "-1")
  pfSkin:UpdateConfig("unitframes", "ptarget",     "buffs",            "off")
  pfSkin:UpdateConfig("unitframes", "ptarget",     "buffsize",         "16")
  pfSkin:UpdateConfig("unitframes", "ptarget",     "debuffs",          "off")
  pfSkin:UpdateConfig("unitframes", "ptarget",     "debuffsize",       "16")
  pfSkin:UpdateConfig("unitframes", "ptarget",     "txthpleft",        "none")
  pfSkin:UpdateConfig("unitframes", "ptarget",     "txthpcenter",      "name")
  pfSkin:UpdateConfig("unitframes", "ptarget",     "txthpright",       "none")
  pfSkin:UpdateConfig("unitframes", "ptarget",     "overhealperc",     "10")

  local ufs = { "player", "target", "focus", "focustarget", "group", "grouptarget", "grouppet", "raid", "ttarget", "pet", "ptarget", "fallback", "tttarget" }
  for _, unit in pairs(ufs) do
    pfSkin:UpdateConfig("unitframes", unit,      "selfdebuff",       "0")
    pfSkin:UpdateConfig("unitframes", unit,      "visible",          "1")
    pfSkin:UpdateConfig("unitframes", unit,      "showPVP",          "0")
    pfSkin:UpdateConfig("unitframes", unit,      "pvpiconsize",      "16" )
    pfSkin:UpdateConfig("unitframes", unit,      "pvpiconalign",     "CENTER")
    pfSkin:UpdateConfig("unitframes", unit,      "pvpiconoffx",      "0")
    pfSkin:UpdateConfig("unitframes", unit,      "pvpiconoffy",      "0")
    pfSkin:UpdateConfig("unitframes", unit,      "raidicon",         "1")
    pfSkin:UpdateConfig("unitframes", unit,      "raidiconalign",    "CENTER")
    pfSkin:UpdateConfig("unitframes", unit,      "raidiconoffx",     "0")
    pfSkin:UpdateConfig("unitframes", unit,      "raidiconoffy",     "20")
    pfSkin:UpdateConfig("unitframes", unit,      "leadericon",       "1")
    pfSkin:UpdateConfig("unitframes", unit,      "looticon",         "1")
    pfSkin:UpdateConfig("unitframes", unit,      "raidiconsize",     "24")
    pfSkin:UpdateConfig("unitframes", unit,      "classiconsize",    "32")
    pfSkin:UpdateConfig("unitframes", unit,      "classiconoffx",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "classiconoffy",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "portrait",         "bar")
    pfSkin:UpdateConfig("unitframes", unit,      "bartexture",       "Interface\\AddOns\\pfSkin\\img\\bar")
    pfSkin:UpdateConfig("unitframes", unit,      "pbartexture",       "Interface\\AddOns\\pfSkin\\img\\bar")
    pfSkin:UpdateConfig("unitframes", unit,      "width",            "200")
    pfSkin:UpdateConfig("unitframes", unit,      "height",           "46")
    pfSkin:UpdateConfig("unitframes", unit,      "pheight",          "10")
    pfSkin:UpdateConfig("unitframes", unit,      "pwidth",           "-1")
    pfSkin:UpdateConfig("unitframes", unit,      "poffx",           "0")
    pfSkin:UpdateConfig("unitframes", unit,      "poffy",           "0")
    pfSkin:UpdateConfig("unitframes", unit,      "portraitheight",   "-1")
    pfSkin:UpdateConfig("unitframes", unit,      "portraitwidth",    "-1")
    pfSkin:UpdateConfig("unitframes", unit,      "panchor",          "TOP")
    pfSkin:UpdateConfig("unitframes", unit,      "pspace",           "-3")
    pfSkin:UpdateConfig("unitframes", unit,      "cooldown_text",    "1")
    pfSkin:UpdateConfig("unitframes", unit,      "cooldown_anim",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "buffs",            "TOPLEFT")
    pfSkin:UpdateConfig("unitframes", unit,      "buffsize",         "20")
    pfSkin:UpdateConfig("unitframes", unit,      "bufflimit",        "32")
    pfSkin:UpdateConfig("unitframes", unit,      "buffperrow",       "8")
    pfSkin:UpdateConfig("unitframes", unit,      "buffoffx",         "0")
    pfSkin:UpdateConfig("unitframes", unit,      "buffoffy",         "0")
    pfSkin:UpdateConfig("unitframes", unit,      "debuffs",          "TOPLEFT")
    pfSkin:UpdateConfig("unitframes", unit,      "debuffsize",       "20")
    pfSkin:UpdateConfig("unitframes", unit,      "debufflimit",      "32")
    pfSkin:UpdateConfig("unitframes", unit,      "debuffperrow",     "8")
    pfSkin:UpdateConfig("unitframes", unit,      "debuffoffx",       "0")
    pfSkin:UpdateConfig("unitframes", unit,      "debuffoffy",       "0")
    pfSkin:UpdateConfig("unitframes", unit,      "invert_healthbar", "0")
    pfSkin:UpdateConfig("unitframes", unit,      "verticalbar",      "0")
    pfSkin:UpdateConfig("unitframes", unit,      "buff_indicator",   "0")
    pfSkin:UpdateConfig("unitframes", unit,      "debuff_indicator", "0")
    pfSkin:UpdateConfig("unitframes", unit,      "custom_indicator", "")

    pfSkin:UpdateConfig("unitframes", unit,      "debuff_ind_pos",   "CENTER")
    pfSkin:UpdateConfig("unitframes", unit,      "debuff_ind_size",  ".65")
    pfSkin:UpdateConfig("unitframes", unit,      "debuff_ind_class", "1")

    pfSkin:UpdateConfig("unitframes", unit,      "show_buffs",       "1")
    pfSkin:UpdateConfig("unitframes", unit,      "show_hots",        "0")
    pfSkin:UpdateConfig("unitframes", unit,      "all_hots",         "0")
    pfSkin:UpdateConfig("unitframes", unit,      "show_procs",       "0")
    pfSkin:UpdateConfig("unitframes", unit,      "show_totems",      "0")
    pfSkin:UpdateConfig("unitframes", unit,      "all_procs",        "0")
    pfSkin:UpdateConfig("unitframes", unit,      "indicator_time",   "1")
    pfSkin:UpdateConfig("unitframes", unit,      "indicator_stacks", "1")
    pfSkin:UpdateConfig("unitframes", unit,      "indicator_size",   "10")
    pfSkin:UpdateConfig("unitframes", unit,      "indicator_spacing","1")
    pfSkin:UpdateConfig("unitframes", unit,      "indicator_pos",    "TOPLEFT")

    pfSkin:UpdateConfig("unitframes", unit,      "clickcast",        "0")
    pfSkin:UpdateConfig("unitframes", unit,      "faderange",        "0")
    pfSkin:UpdateConfig("unitframes", unit,      "alpha_visible",    "1")
    pfSkin:UpdateConfig("unitframes", unit,      "alpha_outrange",   ".50")
    pfSkin:UpdateConfig("unitframes", unit,      "alpha_offline",    ".25")
    pfSkin:UpdateConfig("unitframes", unit,      "squareaggro",      "0")
    pfSkin:UpdateConfig("unitframes", unit,      "squarecombat",     "0")
    pfSkin:UpdateConfig("unitframes", unit,      "squaresize",       "8")
    pfSkin:UpdateConfig("unitframes", unit,      "squarepos",        "TOPLEFT")

    pfSkin:UpdateConfig("unitframes", unit,      "glowaggro",        "1")
    pfSkin:UpdateConfig("unitframes", unit,      "glowcombat",       "1")
    pfSkin:UpdateConfig("unitframes", unit,      "showtooltip",      "1")
    pfSkin:UpdateConfig("unitframes", unit,      "healthcolor",      "1")
    pfSkin:UpdateConfig("unitframes", unit,      "powercolor",       "1")
    pfSkin:UpdateConfig("unitframes", unit,      "levelcolor",       "1")
    pfSkin:UpdateConfig("unitframes", unit,      "classcolor",       "1")
    pfSkin:UpdateConfig("unitframes", unit,      "txthpleft",        "unit")
    pfSkin:UpdateConfig("unitframes", unit,      "txthpleftsize",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txthpleftoffx",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txthpleftoffy",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txthpcenter",      "none")
    pfSkin:UpdateConfig("unitframes", unit,      "txthpcentersize",  "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txthpcenteroffx",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txthpcenteroffy",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txthpright",       "healthdyn")
    pfSkin:UpdateConfig("unitframes", unit,      "txthprightsize",   "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txthprightoffx",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txthprightoffy",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txtpowerleft",     "none")
    pfSkin:UpdateConfig("unitframes", unit,      "txtpowerleftsize",   "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txtpowerleftoffx",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txtpowerleftoffy",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txtpowercenter",   "none")
    pfSkin:UpdateConfig("unitframes", unit,      "txtpowercentersize", "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txtpowercenteroffx",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txtpowercenteroffy",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txtpowerright",    "none")
    pfSkin:UpdateConfig("unitframes", unit,      "txtpowerrightsize",  "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txtpowerrightoffx",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "txtpowerrightoffy",    "0")
    pfSkin:UpdateConfig("unitframes", unit,      "hitindicator",     "0")
    pfSkin:UpdateConfig("unitframes", unit,      "hitindicatorsize", "15")
    pfSkin:UpdateConfig("unitframes", unit,      "hitindicatorfont", "Interface\\AddOns\\pfSkin\\fonts\\Continuum.ttf")
    pfSkin:UpdateConfig("unitframes", unit,      "defcolor",         "1")
    pfSkin:UpdateConfig("unitframes", unit,      "custom",           "0")
    pfSkin:UpdateConfig("unitframes", unit,      "customfullhp",     "0")
    pfSkin:UpdateConfig("unitframes", unit,      "customfade",       "0")
    pfSkin:UpdateConfig("unitframes", unit,      "customcolor",      ".2,.2,.2,1")
    pfSkin:UpdateConfig("unitframes", unit,      "custombg",         "0")
    pfSkin:UpdateConfig("unitframes", unit,      "custombgcolor",    ".5,.2,.2,1")
    pfSkin:UpdateConfig("unitframes", unit,      "custompbg",        "0")
    pfSkin:UpdateConfig("unitframes", unit,      "custompbgcolor",   ".5,.2,.2,1")
    pfSkin:UpdateConfig("unitframes", unit,      "manacolor",        ".5,.5,1,1")
    pfSkin:UpdateConfig("unitframes", unit,      "energycolor",      "1,1,.5,1")
    pfSkin:UpdateConfig("unitframes", unit,      "ragecolor",        "1,.5,.5,1")
    pfSkin:UpdateConfig("unitframes", unit,      "focuscolor",       "1,1,.75,1")
    pfSkin:UpdateConfig("unitframes", unit,      "healcolor",        "0,1,0,0.6")
    pfSkin:UpdateConfig("unitframes", unit,      "overhealperc",     "20")
    pfSkin:UpdateConfig("unitframes", unit,      "customfont",       "0")
    pfSkin:UpdateConfig("unitframes", unit,      "customfont_name",  "Interface\\AddOns\\pfSkin\\fonts\\BigNoodleTitling.ttf")
    pfSkin:UpdateConfig("unitframes", unit,      "customfont_size",  "12")
    pfSkin:UpdateConfig("unitframes", unit,      "customfont_style", "OUTLINE")
  end

  pfSkin:UpdateConfig("bars",       "bar1",        "pageable",         "1")
  pfSkin:UpdateConfig("bars",       "bar2",        "pageable",         "1")

  pfSkin:UpdateConfig("bars",       "bar1",        "enable",           "1")
  pfSkin:UpdateConfig("bars",       "bar3",        "enable",           "1")
  pfSkin:UpdateConfig("bars",       "bar4",        "enable",           "1")
  pfSkin:UpdateConfig("bars",       "bar5",        "enable",           "1")
  pfSkin:UpdateConfig("bars",       "bar6",        "enable",           "1")
  pfSkin:UpdateConfig("bars",       "bar11",       "enable",           "1")
  pfSkin:UpdateConfig("bars",       "bar12",       "enable",           "1")

  pfSkin:UpdateConfig("bars",       "bar3",        "formfactor",       "6 x 2")
  pfSkin:UpdateConfig("bars",       "bar5",        "formfactor",       "6 x 2")
  pfSkin:UpdateConfig("bars",       "bar4",        "formfactor",       "1 x 12")
  pfSkin:UpdateConfig("bars",       "bar11",       "formfactor",       "10 x 1")
  pfSkin:UpdateConfig("bars",       "bar12",       "formfactor",       "10 x 1")

  pfSkin:UpdateConfig("bars",       "bar11",       "icon_size",        "18")
  pfSkin:UpdateConfig("bars",       "bar12",       "icon_size",        "18")

  for i=1,12 do
    pfSkin:UpdateConfig("bars",     "bar"..i,      "enable",           "0")
    pfSkin:UpdateConfig("bars",     "bar"..i,      "pageable",         "0")
    pfSkin:UpdateConfig("bars",     "bar"..i,      "icon_size",        "20")
    pfSkin:UpdateConfig("bars",     "bar"..i,      "spacing",          "1")
    pfSkin:UpdateConfig("bars",     "bar"..i,      "formfactor",       "12 x 1")
    pfSkin:UpdateConfig("bars",     "bar"..i,      "background",       "1")
    pfSkin:UpdateConfig("bars",     "bar"..i,      "showempty",        "1")
    pfSkin:UpdateConfig("bars",     "bar"..i,      "showmacro",        "1")
    pfSkin:UpdateConfig("bars",     "bar"..i,      "showkeybind",      "1")
    pfSkin:UpdateConfig("bars",     "bar"..i,      "showcount",        "1")
    pfSkin:UpdateConfig("bars",     "bar"..i,      "autohide",         "0")
    pfSkin:UpdateConfig("bars",     "bar"..i,      "hide_time",        "3")
    pfSkin:UpdateConfig("bars",     "bar"..i,      "hide_combat",      "1")
    if i ~= 11 and i ~= 12 then
      pfSkin:UpdateConfig("bars",     "bar"..i,      "buttons",           "12")
    end
  end

  pfSkin:UpdateConfig("bars",       nil,           "keydown",          "0")
  pfSkin:UpdateConfig("bars",       nil,           "altself",          "0")
  pfSkin:UpdateConfig("bars",       nil,           "rightself",        "0")
  pfSkin:UpdateConfig("bars",       nil,           "animation",        "zoomfade")
  pfSkin:UpdateConfig("bars",       nil,           "animmode",         "keypress")
  pfSkin:UpdateConfig("bars",       nil,           "animalways",       "0")
  pfSkin:UpdateConfig("bars",       nil,           "macroscan",        "1")
  pfSkin:UpdateConfig("bars",       nil,           "reagents",         "1")
  pfSkin:UpdateConfig("bars",       nil,           "hunterbar",        "0")
  pfSkin:UpdateConfig("bars",       nil,           "pagemasteralt",    "0")
  pfSkin:UpdateConfig("bars",       nil,           "pagemastershift",  "0")
  pfSkin:UpdateConfig("bars",       nil,           "pagemasterctrl",   "0")
  pfSkin:UpdateConfig("bars",       nil,           "druidstealth",     "0")
  pfSkin:UpdateConfig("bars",       nil,           "showcastable",     "1")
  pfSkin:UpdateConfig("bars",       nil,           "glowrange",        "1")
  pfSkin:UpdateConfig("bars",       nil,           "rangecolor",       "1,0.1,0.1,1")
  pfSkin:UpdateConfig("bars",       nil,           "showoom",          "1")
  pfSkin:UpdateConfig("bars",       nil,           "oomcolor",         ".2,.2,1,1")
  pfSkin:UpdateConfig("bars",       nil,           "showna",           "1")
  pfSkin:UpdateConfig("bars",       nil,           "nacolor",          ".3,.3,.3,1")
  pfSkin:UpdateConfig("bars",       nil,           "showequipped",     "1")
  pfSkin:UpdateConfig("bars",       nil,           "eqcolor",          ".2,.8,.2,.2")
  pfSkin:UpdateConfig("bars",       nil,           "shiftdrag",        "1")

  pfSkin:UpdateConfig("bars",       nil,           "font",             "Interface\\AddOns\\pfSkin\\fonts\\BigNoodleTitling.ttf")
  pfSkin:UpdateConfig("bars",       nil,           "font_offset",      "0")
  pfSkin:UpdateConfig("bars",       nil,           "macro_size",       "9")
  pfSkin:UpdateConfig("bars",       nil,           "macro_color",      "1,1,1,1")
  pfSkin:UpdateConfig("bars",       nil,           "count_size",       "11")
  pfSkin:UpdateConfig("bars",       nil,           "count_color",      ".2,1,.8,1")
  pfSkin:UpdateConfig("bars",       nil,           "bind_size",        "8")
  pfSkin:UpdateConfig("bars",       nil,           "bind_color",       "1,1,0,1")
  pfSkin:UpdateConfig("bars",       nil,           "cd_size",          "12")

  pfSkin:UpdateConfig("bars",       "gryphons",    "texture",          "None")
  pfSkin:UpdateConfig("bars",       "gryphons",    "color",            ".6,.6,.6,1")
  pfSkin:UpdateConfig("bars",       "gryphons",    "size",             "64")
  pfSkin:UpdateConfig("bars",       "gryphons",    "anchor_left",      "pfActionBarLeft")
  pfSkin:UpdateConfig("bars",       "gryphons",    "anchor_right",     "pfActionBarRight")
  pfSkin:UpdateConfig("bars",       "gryphons",    "offset_h",         "-48")
  pfSkin:UpdateConfig("bars",       "gryphons",    "offset_v",         "-4")

  pfSkin:UpdateConfig("totems",     nil,           "direction",        "HORIZONTAL")
  pfSkin:UpdateConfig("totems",     nil,           "iconsize",         "26")
  pfSkin:UpdateConfig("totems",     nil,           "spacing",          "3")
  pfSkin:UpdateConfig("totems",     nil,           "showbg",           "0")

  pfSkin:UpdateConfig("panel",      nil,           "use_unitfonts",    "0")
  pfSkin:UpdateConfig("panel",      nil,           "hide_leftchat",    "0")
  pfSkin:UpdateConfig("panel",      nil,           "hide_rightchat",   "0")
  pfSkin:UpdateConfig("panel",      nil,           "hide_minimap",     "0")
  pfSkin:UpdateConfig("panel",      nil,           "hide_microbar",    "0")
  pfSkin:UpdateConfig("panel",      nil,           "seconds",          "1")
  pfSkin:UpdateConfig("panel",      "left",        "left",             "guild")
  pfSkin:UpdateConfig("panel",      "left",        "center",           "durability")
  pfSkin:UpdateConfig("panel",      "left",        "right",            "friends")
  pfSkin:UpdateConfig("panel",      "right",       "left",             "fps")
  pfSkin:UpdateConfig("panel",      "right",       "center",           "time")
  pfSkin:UpdateConfig("panel",      "right",       "right",            "gold")
  pfSkin:UpdateConfig("panel",      "other",       "minimap",          "zone")
  pfSkin:UpdateConfig("panel",      "micro",       "enable",           "0")
  pfSkin:UpdateConfig("panel",      nil,           "fpscolors",        "1")

  pfSkin:UpdateConfig("panel",      "bag",         "ignorespecial",    "1")
  pfSkin:UpdateConfig("panel",      "xp",          "xp_always",        "0")
  pfSkin:UpdateConfig("panel",      "xp",          "xp_display",       "XPFLEX")
  pfSkin:UpdateConfig("panel",      "xp",          "xp_timeout",       "5")
  pfSkin:UpdateConfig("panel",      "xp",          "xp_width",         "5")
  pfSkin:UpdateConfig("panel",      "xp",          "xp_height",        "5")
  pfSkin:UpdateConfig("panel",      "xp",          "xp_mode",          "VERTICAL")
  pfSkin:UpdateConfig("panel",      "xp",          "xp_anchor",        "pfChatLeft")
  pfSkin:UpdateConfig("panel",      "xp",          "xp_position",      "RIGHT")
  pfSkin:UpdateConfig("panel",      "xp",          "xp_text",          "0")
  pfSkin:UpdateConfig("panel",      "xp",          "xp_text_off_y",    "0")
  pfSkin:UpdateConfig("panel",      "xp",          "xp_text_mouse",    "0")
  pfSkin:UpdateConfig("panel",      "xp",          "xp_color",         ".25,.25,1,1")
  pfSkin:UpdateConfig("panel",      "xp",          "rest_color",       "1,.25,1,.5")
  pfSkin:UpdateConfig("panel",      "xp",          "texture",          "Interface\\AddOns\\pfSkin\\img\\bar")

  pfSkin:UpdateConfig("panel",      "xp",          "rep_always",       "0")
  pfSkin:UpdateConfig("panel",      "xp",          "rep_display",      "REP")
  pfSkin:UpdateConfig("panel",      "xp",          "rep_timeout",      "5")
  pfSkin:UpdateConfig("panel",      "xp",          "rep_width",        "5")
  pfSkin:UpdateConfig("panel",      "xp",          "rep_height",       "5")
  pfSkin:UpdateConfig("panel",      "xp",          "rep_mode",         "VERTICAL")
  pfSkin:UpdateConfig("panel",      "xp",          "rep_anchor",       "pfChatRight")
  pfSkin:UpdateConfig("panel",      "xp",          "rep_position",     "LEFT")
  pfSkin:UpdateConfig("panel",      "xp",          "rep_text",         "0")
  pfSkin:UpdateConfig("panel",      "xp",          "rep_text_off_y",   "0")
  pfSkin:UpdateConfig("panel",      "xp",          "rep_text_mouse",   "0")
  pfSkin:UpdateConfig("panel",      "xp",          "dont_overlap",     "0")

  pfSkin:UpdateConfig("castbar",    "player",      "hide_blizz",       "1")
  pfSkin:UpdateConfig("castbar",    "player",      "hide_pfui",        "0")
  pfSkin:UpdateConfig("castbar",    "player",      "width",            "-1")
  pfSkin:UpdateConfig("castbar",    "player",      "height",           "-1")
  pfSkin:UpdateConfig("castbar",    "player",      "showicon",         "0")
  pfSkin:UpdateConfig("castbar",    "player",      "showname",         "1")
  pfSkin:UpdateConfig("castbar",    "player",      "showtimer",        "1")
  pfSkin:UpdateConfig("castbar",    "player",      "txtleftoffx",      "0")
  pfSkin:UpdateConfig("castbar",    "player",      "txtleftoffy",      "0")
  pfSkin:UpdateConfig("castbar",    "player",      "showlag",          "0")
  pfSkin:UpdateConfig("castbar",    "player",      "showrank",         "0")
  pfSkin:UpdateConfig("castbar",    "player",      "txtrightoffx",     "0")
  pfSkin:UpdateConfig("castbar",    "player",      "txtrightoffy",     "0")
  pfSkin:UpdateConfig("castbar",    "target",      "hide_pfui",        "0")
  pfSkin:UpdateConfig("castbar",    "target",      "width",            "-1")
  pfSkin:UpdateConfig("castbar",    "target",      "height",           "-1")
  pfSkin:UpdateConfig("castbar",    "target",      "showicon",         "0")
  pfSkin:UpdateConfig("castbar",    "target",      "showname",         "1")
  pfSkin:UpdateConfig("castbar",    "target",      "showtimer",        "1")
  pfSkin:UpdateConfig("castbar",    "target",      "txtleftoffx",      "0")
  pfSkin:UpdateConfig("castbar",    "target",      "txtleftoffy",      "0")
  pfSkin:UpdateConfig("castbar",    "target",      "showlag",          "0")
  pfSkin:UpdateConfig("castbar",    "target",      "showrank",         "0")
  pfSkin:UpdateConfig("castbar",    "target",      "txtrightoffx",     "0")
  pfSkin:UpdateConfig("castbar",    "target",      "txtrightoffy",     "0")
  pfSkin:UpdateConfig("castbar",    "focus",       "hide_pfui",        "0")
  pfSkin:UpdateConfig("castbar",    "focus",       "width",            "-1")
  pfSkin:UpdateConfig("castbar",    "focus",       "height",           "-1")
  pfSkin:UpdateConfig("castbar",    "focus",       "showicon",         "0")
  pfSkin:UpdateConfig("castbar",    "focus",       "showname",         "1")
  pfSkin:UpdateConfig("castbar",    "focus",       "showtimer",        "1")
  pfSkin:UpdateConfig("castbar",    "focus",       "txtleftoffx",      "0")
  pfSkin:UpdateConfig("castbar",    "focus",       "txtleftoffy",      "0")
  pfSkin:UpdateConfig("castbar",    "focus",       "showlag",          "0")
  pfSkin:UpdateConfig("castbar",    "focus",       "showrank",         "0")
  pfSkin:UpdateConfig("castbar",    "focus",       "txtrightoffx",     "0")
  pfSkin:UpdateConfig("castbar",    "focus",       "txtrightoffy",     "0")
  pfSkin:UpdateConfig("castbar",    nil,           "use_unitfonts",    "0")

  pfSkin:UpdateConfig("tooltip",    nil,           "position",         "chat")
  pfSkin:UpdateConfig("tooltip",    nil,           "cursoralign",      "native")
  pfSkin:UpdateConfig("tooltip",    nil,           "cursoroffset",     "20")
  pfSkin:UpdateConfig("tooltip",    nil,           "extguild",         "1")
  pfSkin:UpdateConfig("tooltip",    nil,           "itemid",           "0")
  pfSkin:UpdateConfig("tooltip",    nil,           "alpha",            "0.8")
  pfSkin:UpdateConfig("tooltip",    nil,           "alwaysperc",       "0")
  pfSkin:UpdateConfig("tooltip",    "compare",     "basestats",        "1")
  pfSkin:UpdateConfig("tooltip",    "compare",     "showalways",       "0")
  pfSkin:UpdateConfig("tooltip",    "vendor",      "showalways",       "0")
  pfSkin:UpdateConfig("tooltip",    "questitem",   "showquest",        "1")
  pfSkin:UpdateConfig("tooltip",    "questitem",   "showcount",        "0")
  pfSkin:UpdateConfig("tooltip",    "statusbar",   "texture",          "Interface\\AddOns\\pfSkin\\img\\bar")
  pfSkin:UpdateConfig("tooltip",     nil,          "font_tooltip",     "Interface\\AddOns\\pfSkin\\fonts\\Myriad-Pro.ttf")
  pfSkin:UpdateConfig("tooltip",     nil,          "font_tooltip_size", "12")

  -- Throttle Settings

  pfSkin:UpdateConfig("chat",       "text",        "input_width",      "0")
  pfSkin:UpdateConfig("chat",       "text",        "input_height",     "0")
  pfSkin:UpdateConfig("chat",       "text",        "outline",          "1")
  pfSkin:UpdateConfig("chat",       "text",        "history",          "1")
  pfSkin:UpdateConfig("chat",       "text",        "mouseover",        "0")
  pfSkin:UpdateConfig("chat",       "text",        "bracket",          "[]")
  pfSkin:UpdateConfig("chat",       "text",        "time",             "0")
  pfSkin:UpdateConfig("chat",       "text",        "timeformat",       "%H:%M:%S")
  pfSkin:UpdateConfig("chat",       "text",        "timebracket",      "[]")
  pfSkin:UpdateConfig("chat",       "text",        "timecolor",        ".8,.8,.8,1")
  pfSkin:UpdateConfig("chat",       "text",        "tintunknown",      "1")
  pfSkin:UpdateConfig("chat",       "text",        "unknowncolor",     ".7,.7,.7,1")
  pfSkin:UpdateConfig("chat",       "text",        "channelnumonly",   "1")
  pfSkin:UpdateConfig("chat",       "text",        "playerlinks",      "1")
  pfSkin:UpdateConfig("chat",       "text",        "detecturl",        "1")
  pfSkin:UpdateConfig("chat",       "text",        "classcolor",       "1")
  pfSkin:UpdateConfig("chat",       "text",        "whosearchunknown", "0")
  pfSkin:UpdateConfig("chat",       "text",        "playerlevel",      "0")
  pfSkin:UpdateConfig("chat",       "left",        "width",            "380")
  pfSkin:UpdateConfig("chat",       "left",        "height",           "180")
  pfSkin:UpdateConfig("chat",       "right",       "enable",           "0")
  pfSkin:UpdateConfig("chat",       "right",       "width",            "380")
  pfSkin:UpdateConfig("chat",       "right",       "height",           "180")
  pfSkin:UpdateConfig("chat",       "global",      "hidecombat",       "0")
  pfSkin:UpdateConfig("chat",       "global",      "tabdock",          "0")
  pfSkin:UpdateConfig("chat",       "global",      "tabmouse",         "0")
  pfSkin:UpdateConfig("chat",       "global",      "chatflash",        "1")
  pfSkin:UpdateConfig("chat",       "global",      "maxlines",         "128")
  pfSkin:UpdateConfig("chat",       "global",      "frameshadow",      "1")
  pfSkin:UpdateConfig("chat",       "global",      "custombg",         "0")
  pfSkin:UpdateConfig("chat",       "global",      "background",       ".2,.2,.2,.5")
  pfSkin:UpdateConfig("chat",       "global",      "border",           ".4,.4,.4,.5")
  pfSkin:UpdateConfig("chat",       "global",      "whispermod",       "1")
  pfSkin:UpdateConfig("chat",       "global",      "whisper",          "1,.7,1,1")
  pfSkin:UpdateConfig("chat",       "global",      "sticky",           "1")
  pfSkin:UpdateConfig("chat",       "global",      "fadeout",          "0")
  pfSkin:UpdateConfig("chat",       "global",      "fadetime",         "300")
  pfSkin:UpdateConfig("chat",       "global",      "scrollspeed",      "1")
  pfSkin:UpdateConfig("chat",       "bubbles",     "borders",          "1")
  pfSkin:UpdateConfig("chat",       "bubbles",     "alpha",            ".75")

  pfSkin:UpdateConfig("nameplates", nil,           "showhostile",                "1")
  pfSkin:UpdateConfig("nameplates", nil,           "showfriendly",               "0")
  pfSkin:UpdateConfig("nameplates", nil,           "disable_hostile_in_friendly", "0")
  pfSkin:UpdateConfig("nameplates", nil,           "disable_friendly_in_friendly", "0")
  pfSkin:UpdateConfig("nameplates", nil,           "use_unitfonts",              "0")
  pfSkin:UpdateConfig("nameplates", nil,           "legacy",           "0")
  pfSkin:UpdateConfig("nameplates", nil,           "overlap",          "0")
  pfSkin:UpdateConfig("nameplates", nil,           "verticalhealth",   "0")
  pfSkin:UpdateConfig("nameplates", nil,           "vertical_offset",  "0")
  pfSkin:UpdateConfig("nameplates", nil,           "showcastbar",      "1")
  pfSkin:UpdateConfig("nameplates", nil,           "targetcastbar",    "0")
  pfSkin:UpdateConfig("nameplates", nil,           "spellname",        "0")
  pfSkin:UpdateConfig("nameplates", nil,           "showdebuffs",      "1")
  pfSkin:UpdateConfig("nameplates", nil,           "selfdebuff",       "0")
  pfSkin:UpdateConfig("nameplates", nil,           "showdebuffs_hostile",  "1")
  pfSkin:UpdateConfig("nameplates", nil,           "showdebuffs_friendly", "0")
  pfSkin:UpdateConfig("nameplates", nil,           "guessdebuffs",     "1")
  pfSkin:UpdateConfig("nameplates", nil,           "clickthrough",     "0")
  pfSkin:UpdateConfig("nameplates", nil,           "rightclick",       "1")
  pfSkin:UpdateConfig("nameplates", nil,           "clickthreshold",   "0.5")
  pfSkin:UpdateConfig("nameplates", nil,           "enemyclassc",      "1")
  pfSkin:UpdateConfig("nameplates", nil,           "friendclassc",     "1")
  pfSkin:UpdateConfig("nameplates", nil,           "friendclassnamec", "0")
  pfSkin:UpdateConfig("nameplates", nil,           "raidiconsize",     "16")
  pfSkin:UpdateConfig("unitframes",  nil,           "blizzard_raidicons","1")
  pfSkin:UpdateConfig("nameplates", nil,           "raidiconpos",      "CENTER")
  pfSkin:UpdateConfig("nameplates", nil,           "raidiconoffx",     "0")
  pfSkin:UpdateConfig("nameplates", nil,           "raidiconoffy",     "-5")
  pfSkin:UpdateConfig("nameplates", nil,           "fullhealth",       "1")
  pfSkin:UpdateConfig("nameplates", nil,           "target",           "1")
  pfSkin:UpdateConfig("nameplates", nil,           "namefightcolor",   "1")
  pfSkin:UpdateConfig("nameplates", nil,           "enemynpc",         "0")
  pfSkin:UpdateConfig("nameplates", nil,           "enemyplayer",      "0")
  pfSkin:UpdateConfig("nameplates", nil,           "neutralnpc",       "0")
  pfSkin:UpdateConfig("nameplates", nil,           "friendlynpc",      "0")
  pfSkin:UpdateConfig("nameplates", nil,           "friendlyplayer",   "0")
  pfSkin:UpdateConfig("nameplates", nil,           "critters",         "1")
  pfSkin:UpdateConfig("nameplates", nil,           "totems",           "1")
  pfSkin:UpdateConfig("nameplates", nil,           "totemicons",       "0")
  pfSkin:UpdateConfig("nameplates", nil,           "showguildname",    "0")

  pfSkin:UpdateConfig("nameplates", nil,           "outcombatstate",   "1")
  pfSkin:UpdateConfig("nameplates", nil,           "barcombatstate",   "1")

  pfSkin:UpdateConfig("nameplates", nil,           "ccombatthreat",    "1")
  pfSkin:UpdateConfig("nameplates", nil,           "ccombatofftank",   "1")
  pfSkin:UpdateConfig("nameplates", nil,           "ccombatnothreat",  "1")
  pfSkin:UpdateConfig("nameplates", nil,           "ccombatstun",      "1")
  pfSkin:UpdateConfig("nameplates", nil,           "ccombatcasting",   "0")
  pfSkin:UpdateConfig("nameplates", nil,           "combatthreat",     ".7,.2,.2,1")
  pfSkin:UpdateConfig("nameplates", nil,           "combatofftank",    ".7,.4,.2,1")
  pfSkin:UpdateConfig("nameplates", nil,           "combatnothreat",   ".7,.7,.2,1")
  pfSkin:UpdateConfig("nameplates", nil,           "combatstun",       ".2,.7,.7,1")
  pfSkin:UpdateConfig("nameplates", nil,           "combatcasting",    ".7,.2,.7,1")
  pfSkin:UpdateConfig("nameplates", nil,           "combatofftanks",   "")

  pfSkin:UpdateConfig("nameplates", nil,           "outfriendly",      "0")
  pfSkin:UpdateConfig("nameplates", nil,           "outfriendlynpc",   "1")
  pfSkin:UpdateConfig("nameplates", nil,           "outneutral",       "1")
  pfSkin:UpdateConfig("nameplates", nil,           "outenemy",         "1")
  pfSkin:UpdateConfig("nameplates", nil,           "targethighlight",  "0")
  pfSkin:UpdateConfig("nameplates", nil,           "highlightcolor",   "1,1,1,1")

  pfSkin:UpdateConfig("nameplates", nil,           "showhp",           "0")
  pfSkin:UpdateConfig("nameplates", nil,           "hptextpos",        "RIGHT")
  pfSkin:UpdateConfig("nameplates", nil,           "hptextformat",     "curmaxs")
  pfSkin:UpdateConfig("nameplates", nil,           "vpos",             "-10")
  pfSkin:UpdateConfig("nameplates", nil,           "width",            "120")
  pfSkin:UpdateConfig("nameplates", nil,           "debuffsize",       "14")
  pfSkin:UpdateConfig("nameplates", nil,           "debuffoffset",     "4")
  pfSkin:UpdateConfig("nameplates", nil,           "heighthealth",     "8")
  pfSkin:UpdateConfig("nameplates", nil,           "heightcast",       "8")
  pfSkin:UpdateConfig("nameplates", nil,           "cpdisplay",        "0")
  pfSkin:UpdateConfig("nameplates", nil,           "targetglow",       "1")
  pfSkin:UpdateConfig("nameplates", nil,           "glowcolor",        "1,1,1,1")
  pfSkin:UpdateConfig("nameplates", nil,           "targetzoom",       "0")
  pfSkin:UpdateConfig("nameplates", nil,           "targetzoomval",    ".40")
  pfSkin:UpdateConfig("nameplates", nil,           "notargalpha",      ".75")
  pfSkin:UpdateConfig("nameplates", nil,           "healthtexture",    "Interface\\AddOns\\pfSkin\\img\\bar")
  pfSkin:UpdateConfig("nameplates", "name",        "fontstyle",        "OUTLINE")
  pfSkin:UpdateConfig("nameplates", "health",      "offset",           "-3")
  pfSkin:UpdateConfig("nameplates", "debuffs",     "filter",           "none")
  pfSkin:UpdateConfig("nameplates", "debuffs",     "whitelist",        "")
  pfSkin:UpdateConfig("nameplates", "debuffs",     "blacklist",        "")
  pfSkin:UpdateConfig("nameplates", "debuffs",     "showstacks",       "0")
  pfSkin:UpdateConfig("nameplates", "debuffs",     "position",         "BOTTOM")
  pfSkin:UpdateConfig("nameplates", nil,           "debufftimers",     "1")
  pfSkin:UpdateConfig("nameplates", nil,           "debufftext",       "1")
  pfSkin:UpdateConfig("nameplates", nil,           "debuffanim",       "0")

  pfSkin:UpdateConfig("abuttons",   nil,           "enable",           "1")
  pfSkin:UpdateConfig("abuttons",   nil,           "position",         "bottom")
  pfSkin:UpdateConfig("abuttons",   nil,           "showdefault",      "0")
  pfSkin:UpdateConfig("abuttons",   nil,           "rowsize",          "6")
  pfSkin:UpdateConfig("abuttons",   nil,           "spacing",          "2")
  pfSkin:UpdateConfig("abuttons",   nil,           "hideincombat",     "1")

  pfSkin:UpdateConfig("screenshot", nil,           "interval",         "0")
  pfSkin:UpdateConfig("screenshot", nil,           "levelup",          "0")
  pfSkin:UpdateConfig("screenshot", nil,           "pvprank",          "0")
  pfSkin:UpdateConfig("screenshot", nil,           "faction",          "0")
  pfSkin:UpdateConfig("screenshot", nil,           "battleground",     "0")
  pfSkin:UpdateConfig("screenshot", nil,           "hk",               "0")
  pfSkin:UpdateConfig("screenshot", nil,           "loot",             "0")
  pfSkin:UpdateConfig("screenshot", nil,           "hideui",           "0")
  pfSkin:UpdateConfig("screenshot", nil,           "caption",          "0")
  pfSkin:UpdateConfig("screenshot", nil,           "caption_font",     "Interface\\AddOns\\pfSkin\\fonts\\BigNoodleTitling.ttf")
  pfSkin:UpdateConfig("screenshot", nil,           "caption_size",     "22")

  pfSkin:UpdateConfig("gm",         nil,           "disable",          "1")
  pfSkin:UpdateConfig("gm",         nil,           "server",           "elysium")

  pfSkin:UpdateConfig("questlog",   nil,           "showQuestLevels",  "0")
  pfSkin:UpdateConfig("thirdparty", nil,           "chatbg",           "1")
  pfSkin:UpdateConfig("thirdparty", nil,           "showmeter",        "0")
  pfSkin:UpdateConfig("thirdparty", "dpsmate",     "skin",             "0")
  pfSkin:UpdateConfig("thirdparty", "dpsmate",     "dock",             "0")
  pfSkin:UpdateConfig("thirdparty", "shagudps",    "skin",             "0")
  pfSkin:UpdateConfig("thirdparty", "shagudps",    "dock",             "0")
  pfSkin:UpdateConfig("thirdparty", "swstats",     "skin",             "0")
  pfSkin:UpdateConfig("thirdparty", "swstats",     "dock",             "0")
  pfSkin:UpdateConfig("thirdparty", "ktm",         "skin",             "0")
  pfSkin:UpdateConfig("thirdparty", "ktm",         "dock",             "0")
  pfSkin:UpdateConfig("thirdparty", "twt",         "skin",             "0")
  pfSkin:UpdateConfig("thirdparty", "twt",         "dock",             "0")
  pfSkin:UpdateConfig("thirdparty", "wim",         "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "healcomm",    "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "sortbags",    "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "bag_sort",    "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "mrplow",      "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "bcs",         "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "crafty",      "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "clevermacro", "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "supercleveroidmacros", "enable",  "1")
  pfSkin:UpdateConfig("thirdparty", "flightmap",   "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "sheepwatch",  "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "totemtimers", "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "theorycraft", "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "supermacro",  "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "atlasloot",   "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "myroleplay",  "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "druidmana",   "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "druidbar",    "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "ackis",       "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "bcepgp",      "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "noteit",      "enable",           "1")
  pfSkin:UpdateConfig("thirdparty", "recount",     "skin",             "0")
  pfSkin:UpdateConfig("thirdparty", "recount",     "dock",             "0")
  pfSkin:UpdateConfig("thirdparty", "omen",        "skin",             "0")
  pfSkin:UpdateConfig("thirdparty", "omen",        "dock",             "0")

  pfSkin:UpdateConfig("position",   nil,           nil,                nil)
  pfSkin:UpdateConfig("disabled",   nil,           nil,                nil)
end

function pfSkin:MigrateConfig()
  -- migrating to new fonts (1.5 -> 1.6)
  if checkversion(1, 6, 0) then
    -- migrate font_default
    if pfSkin_config.global.font_default == "arial" then
      pfSkin_config.global.font_default = "Myriad-Pro"
    elseif pfSkin_config.global.font_default == "homespun" then
      pfSkin_config.global.font_default = "Homespun"
    elseif pfSkin_config.global.font_default == "diediedie" then
      pfSkin_config.global.font_default = "DieDieDie"
    end

    -- migrate font_square
    if pfSkin_config.global.font_square == "arial" then
      pfSkin_config.global.font_square = "Myriad-Pro"
    elseif pfSkin_config.global.font_square == "homespun" then
      pfSkin_config.global.font_square = "Homespun"
    elseif pfSkin_config.global.font_square == "diediedie" then
      pfSkin_config.global.font_square = "DieDieDie"
    end

    -- migrate font_combat
    if pfSkin_config.global.font_combat == "arial" then
      pfSkin_config.global.font_combat = "Myriad-Pro"
    elseif pfSkin_config.global.font_combat == "homespun" then
      pfSkin_config.global.font_combat = "Homespun"
    elseif pfSkin_config.global.font_combat == "diediedie" then
      pfSkin_config.global.font_combat = "DieDieDie"
    end
  end

  -- migrating to new loot config section (> 2.0.5)
  if checkversion(2, 0, 5) then
    if pfSkin_config.appearance.loot and pfSkin_config.appearance.loot.autoresize then
      pfSkin_config.loot.autoresize = pfSkin_config.appearance.loot.autoresize
      pfSkin_config.appearance.loot.autoresize = nil
      pfSkin_config.appearance.loot = nil
    end
  end

  -- migrating to new unitframes (> 2.5)
  if checkversion(2, 5, 0) then
    -- migrate clickcast settings
    if pfSkin_config.unitframes.raid.clickcast_ctrl then
      pfSkin_config.unitframes.clickcast = pfSkin_config.unitframes.raid.clickcast
      pfSkin_config.unitframes.clickcast_shift = pfSkin_config.unitframes.raid.clickcast_shift
      pfSkin_config.unitframes.clickcast_alt = pfSkin_config.unitframes.raid.clickcast_alt
      pfSkin_config.unitframes.clickcast_ctrl = pfSkin_config.unitframes.raid.clickcast_ctrl

      pfSkin_config.unitframes.raid.clickcast = "0"
      pfSkin_config.unitframes.raid.clickcast_shift = nil
      pfSkin_config.unitframes.raid.clickcast_alt = nil
      pfSkin_config.unitframes.raid.clickcast_ctrl = nil
    end

    -- migrate buffsizes
    if pfSkin_config.unitframes.buff_size then
      pfSkin_config.unitframes.player.buffsize = pfSkin_config.unitframes.buff_size
      pfSkin_config.unitframes.target.buffsize = pfSkin_config.unitframes.buff_size
      pfSkin_config.unitframes.buff_size = nil
    end

    -- migrate debuffsizes
    if pfSkin_config.unitframes.debuff_size then
      pfSkin_config.unitframes.player.debuffsize = pfSkin_config.unitframes.debuff_size
      pfSkin_config.unitframes.target.debuffsize = pfSkin_config.unitframes.debuff_size
      pfSkin_config.unitframes.debuff_size = nil
    end
  end

  -- migrating to new fontnames (> 2.6)
  if checkversion(2, 6, 0) then
    -- migrate font_combat
    if pfSkin_config.global.font_square then
      pfSkin_config.global.font_unit = pfSkin_config.global.font_square
      pfSkin_config.global.font_square = nil
    end
  end


  -- migrating old to new font layout (> 3.0.0)
  if checkversion(3, 0, 0) then
    -- migrate font_default
    if not strfind(pfSkin_config.global.font_default, "\\") then
      pfSkin_config.global.font_default = "Interface\\AddOns\\pfSkin\\fonts\\" .. pfSkin_config.global.font_default .. ".ttf"
    end

    -- migrate font_unit
    if not strfind(pfSkin_config.global.font_unit, "\\") then
      pfSkin_config.global.font_unit = "Interface\\AddOns\\pfSkin\\fonts\\" .. pfSkin_config.global.font_unit .. ".ttf"
    end

    -- migrate font_combat
    if not strfind(pfSkin_config.global.font_combat, "\\") then
      pfSkin_config.global.font_combat = "Interface\\AddOns\\pfSkin\\fonts\\" .. pfSkin_config.global.font_combat .. ".ttf"
    end
  end

  -- migrating old to new unitframe texts (> 3.0.0)
  if checkversion(3, 0, 0) then
    local unitframes = { "player", "target", "focus", "group", "grouptarget", "grouppet", "raid", "ttarget", "pet", "ptarget", "fallback" }

    for _, unitframe in pairs(unitframes) do
      if pfSkin_config.unitframes[unitframe].txtleft then
        pfSkin_config.unitframes[unitframe].txthpleft = pfSkin_config.unitframes[unitframe].txtleft
        pfSkin_config.unitframes[unitframe].txtleft = nil
      end
      if pfSkin_config.unitframes[unitframe].txtcenter then
        pfSkin_config.unitframes[unitframe].txthpcenter = pfSkin_config.unitframes[unitframe].txtcenter
        pfSkin_config.unitframes[unitframe].txtcenter = nil
      end
      if pfSkin_config.unitframes[unitframe].txtright then
        pfSkin_config.unitframes[unitframe].txthpright = pfSkin_config.unitframes[unitframe].txtright
        pfSkin_config.unitframes[unitframe].txtright = nil
      end
    end
  end

  -- migrating animation_speed (> 3.1.2)
  if checkversion(3, 1, 2) then
    if tonumber(pfSkin_config.unitframes.animation_speed) >= 13 then
      pfSkin_config.unitframes.animation_speed = "13"
    elseif tonumber(pfSkin_config.unitframes.animation_speed) >= 8 then
      pfSkin_config.unitframes.animation_speed = "8"
    elseif tonumber(pfSkin_config.unitframes.animation_speed) >= 5 then
      pfSkin_config.unitframes.animation_speed = "5"
    elseif tonumber(pfSkin_config.unitframes.animation_speed) >= 3 then
      pfSkin_config.unitframes.animation_speed = "3"
    elseif tonumber(pfSkin_config.unitframes.animation_speed) >= 2 then
      pfSkin_config.unitframes.animation_speed = "2"
    elseif tonumber(pfSkin_config.unitframes.animation_speed) >= 1 then
      pfSkin_config.unitframes.animation_speed = "1"
    else
      pfSkin_config.unitframes.animation_speed = "5"
    end
  end

  -- migrating rangecheck interval (> 3.2.2)
  if checkversion(3, 2, 2) then
    if tonumber(pfSkin_config.unitframes.rangechecki) <= 1 then
      pfSkin_config.unitframes.rangechecki = "2"
    end
  end

  -- migrating legacy buff/debuff naming (> 3.5.0)
  if checkversion(3, 5, 0) then
    local unitframes = { "player", "target", "focus", "group", "grouptarget", "grouppet", "raid", "ttarget", "pet", "ptarget", "fallback" }

    for _, unitframe in pairs(unitframes) do
      local entry = pfSkin_config.unitframes[unitframe]
      if entry.buffs and entry.buffs == "hide" then entry.buffs = "off" end
      if entry.debuffs and entry.debuffs == "hide" then entry.debuffs = "off" end
    end
  end

  -- migrating glow settings (> 3.5.1)
  if checkversion(3, 5, 0) then
    local common = { "player", "target", "ttarget", "pet", "ptarget", "tttarget"}
    for _, unitframe in pairs(common) do
      if pfSkin_config.appearance.infight.group == "1" then
        pfSkin_config.unitframes[unitframe].glowcombat = "1"
        pfSkin_config.unitframes[unitframe].glowaggro = "1"
      elseif pfSkin_config.appearance.infight.group == "0" then
        pfSkin_config.unitframes[unitframe].glowcombat = "0"
        pfSkin_config.unitframes[unitframe].glowaggro = "0"
      end
    end

    if pfSkin_config.appearance.infight.group == "1" then
      pfSkin_config.unitframes["group"].glowcombat = "1"
      pfSkin_config.unitframes["group"].glowaggro = "1"
    elseif pfSkin_config.appearance.infight.group == "0" then
      pfSkin_config.unitframes["group"].glowcombat = "0"
      pfSkin_config.unitframes["group"].glowaggro = "0"
    end
  end

  -- migrating old buff settings (> 3.6.1)
  if checkversion(3, 6, 1) then
    pfSkin_config.buffs.weapons =  pfSkin_config.global.hidewbuff == "1" and "0" or "1"
    pfSkin_config.buffs.buffs   =  pfSkin_config.global.hidebuff  == "1" and "0" or "1"
    pfSkin_config.buffs.debuffs =  pfSkin_config.global.hidebuff  == "1" and "0" or "1"
  end

  -- migrating default debuffbar color settings (> 3.16)
  if checkversion(3, 16, 0) then

    if pfSkin_config.buffbar.pdebuff.color == ".1,.1,.1,1" then
      pfSkin_config.buffbar.pdebuff.color = ".8,.4,.4,1"
    end

    if pfSkin_config.buffbar.tdebuff.color == ".1,.1,.1,1" then
      pfSkin_config.buffbar.tdebuff.color   =  ".8,.4,.4,1"
    end
  end

  -- migrate buff/debuff position settings (> 3.19)
  if checkversion(3, 19, 0) then
    local unitframes = { "player", "target", "focus", "group", "grouptarget", "grouppet", "raid", "ttarget", "pet", "ptarget", "fallback" }

    for _, unitframe in pairs(unitframes) do
      local entry = pfSkin_config.unitframes[unitframe]
      if entry.buffs and entry.buffs == "top" then entry.buffs = "TOPLEFT" end
      if entry.buffs and entry.buffs == "bottom" then entry.buffs = "BOTTOMLEFT" end
      if entry.debuffs and entry.debuffs == "top" then entry.debuffs = "TOPLEFT" end
      if entry.debuffs and entry.debuffs == "bottom" then entry.debuffs = "BOTTOMLEFT" end
    end
  end

  -- migrating actionbar settings (> 3.19)
  if checkversion(3, 19, 0) then

    local migratebars = {
      ["pfBarActionMain"] = "pfActionBarMain",
      ["pfBarBottomLeft"] = "pfActionBarTop",
      ["pfBarBottomRight"] = "pfActionBarLeft",
      ["pfBarTwoRight"] = "pfActionBarVertical",
      ["pfBarRight"] = "pfActionBarRight",
      ["pfBarShapeshift"] = "pfActionBarStances",
      ["pfBarPet"] = "pfActionBarPet",
    }

    -- migrate bar positions and scaling
    for oldname, newname in pairs(migratebars) do
      if pfSkin_config.position[oldname] then
        pfSkin_config.position[newname] = pfSkin.api.CopyTable(pfSkin_config.position[oldname])
        pfSkin_config.position[oldname] = nil
      end
    end

    -- migrate global settings to bar specifics
    for i=1,12 do
      if pfSkin_config.bars.icon_size then
        pfSkin_config.bars["bar"..i].icon_size = pfSkin_config.bars.icon_size
      end

      if pfSkin_config.bars.background then
        pfSkin_config.bars["bar"..i].background = pfSkin_config.bars.background
      end

      if pfSkin_config.bars.showmacro then
        pfSkin_config.bars["bar"..i].showmacro = pfSkin_config.bars.showmacro
      end

      if pfSkin_config.bars.showkeybind then
        pfSkin_config.bars["bar"..i].showkeybind = pfSkin_config.bars.showkeybind
      end

      if pfSkin_config.bars.hide_time then
        pfSkin_config.bars["bar"..i].hide_time = pfSkin_config.bars.hide_time
      end
    end

    pfSkin_config.bars.icon_size = nil
    pfSkin_config.bars.background = nil
    pfSkin_config.bars.showmacro = nil
    pfSkin_config.bars.showkeybind = nil
    pfSkin_config.bars.hide_time = nil

    if pfSkin_config.bars.hide_actionmain then
      pfSkin_config.bars.bar1.autohide = pfSkin_config.bars.hide_actionmain
      pfSkin_config.bars.hide_actionmain = nil
    end

    if pfSkin_config.bars.hide_bottomleft then
      pfSkin_config.bars.bar6.autohide = pfSkin_config.bars.hide_bottomleft
      pfSkin_config.bars.hide_bottomleft = nil
    end

    if pfSkin_config.bars.hide_bottomright then
      pfSkin_config.bars.bar5.autohide = pfSkin_config.bars.hide_bottomright
      pfSkin_config.bars.hide_bottomright = nil
    end

    if pfSkin_config.bars.hide_right then
      pfSkin_config.bars.bar3.autohide = pfSkin_config.bars.hide_right
      pfSkin_config.bars.hide_right = nil
    end

    if pfSkin_config.bars.hide_tworight then
      pfSkin_config.bars.bar4.autohide = pfSkin_config.bars.hide_tworight
      pfSkin_config.bars.hide_tworight = nil
    end

    if pfSkin_config.bars.hide_shapeshift then
      pfSkin_config.bars.bar11.autohide = pfSkin_config.bars.hide_shapeshift
      pfSkin_config.bars.hide_shapeshift = nil
    end

    if pfSkin_config.bars.hide_pet then
      pfSkin_config.bars.bar12.autohide = pfSkin_config.bars.hide_pet
      pfSkin_config.bars.hide_pet = nil
    end

    if pfSkin_config.bars.actionmain and pfSkin_config.bars.actionmain.formfactor then
      pfSkin_config.bars.bar1.formfactor = pfSkin_config.bars.actionmain.formfactor
      pfSkin_config.bars.actionmain.formfactor = nil
    end

    if pfSkin_config.bars.bottomleft and pfSkin_config.bars.bottomleft.formfactor then
      pfSkin_config.bars.bar6.formfactor = pfSkin_config.bars.bottomleft.formfactor
      pfSkin_config.bars.bottomleft.formfactor = nil
    end

    if pfSkin_config.bars.bottomright and pfSkin_config.bars.bottomright.formfactor then
      pfSkin_config.bars.bar5.formfactor = pfSkin_config.bars.bottomright.formfactor
      pfSkin_config.bars.bottomright.formfactor = nil
    end

    if pfSkin_config.bars.right and pfSkin_config.bars.right.formfactor then
      pfSkin_config.bars.bar3.formfactor = pfSkin_config.bars.right.formfactor
      pfSkin_config.bars.right.formfactor = nil
    end

    if pfSkin_config.bars.tworight and pfSkin_config.bars.tworight.formfactor then
      pfSkin_config.bars.bar4.formfactor = pfSkin_config.bars.tworight.formfactor
      pfSkin_config.bars.tworight.formfactor = nil
    end

    if pfSkin_config.bars.shapeshift and pfSkin_config.bars.shapeshift.formfactor then
      pfSkin_config.bars.bar11.formfactor = pfSkin_config.bars.shapeshift.formfactor
      pfSkin_config.bars.shapeshift.formfactor = nil
    end

    if pfSkin_config.bars.pet and pfSkin_config.bars.pet.formfactor then
      pfSkin_config.bars.bar12.formfactor = pfSkin_config.bars.pet.formfactor
      pfSkin_config.bars.pet.formfactor = nil
    end
  end

  -- migrate xp-showalways (> 4.0.2)
  if checkversion(4, 0, 2) and pfSkin_config.panel.xp.showalways then
    pfSkin_config.panel.xp.xp_always = pfSkin_config.panel.xp.showalways
    pfSkin_config.panel.xp.rep_always = pfSkin_config.panel.xp.showalways
    pfSkin_config.panel.xp.showalways = nil
  end

  -- migrate dispell indicators into seperate options (> 4.6.1)
  if checkversion(4, 6, 1) and pfSkin_config.unitframes.debuffs_class then
    local unitframes = { "player", "target", "focus", "group", "grouptarget", "grouppet", "raid", "ttarget", "pet", "ptarget", "fallback", "tttarget" }
    for _, unitframe in pairs(unitframes) do
      pfSkin_config.unitframes[unitframe].debuff_ind_class = pfSkin_config.unitframes.debuffs_class
    end
    pfSkin_config.unitframes.debuffs_class = nil
  end

  -- migrate buff indicators into seperate options (> 4.6.2)
  if checkversion(4, 6, 2) and pfSkin_config.unitframes.show_hots then
    local unitframes = { "player", "target", "focus", "group", "grouptarget", "grouppet", "raid", "ttarget", "pet", "ptarget", "fallback", "tttarget" }
    local options = { "show_hots", "all_hots", "show_procs", "show_totems", "all_procs", "indicator_time", "indicator_stacks", "indicator_size" }

    for _, unitframe in pairs(unitframes) do
      for _, option in pairs(options) do
        pfSkin_config.unitframes[unitframe][option] = pfSkin_config.unitframes[option]
      end
    end

    for _, option in pairs(options) do
      pfSkin_config.unitframes[option] = nil
    end
  end

  -- use same powerbar texture as for health (> 5.2.10)
  if checkversion(5, 2, 10) then
    local unitframes = { "player", "target", "focus", "group", "grouptarget", "grouppet", "raid", "ttarget", "pet", "ptarget", "fallback", "tttarget" }
    for _, unitframe in pairs(unitframes) do
      pfSkin_config.unitframes[unitframe].pbartexture = pfSkin_config.unitframes[unitframe].bartexture
    end
  end

  -- migrate minimap zone and coords changes
  if checkversion(5, 4, 11) then
    if pfSkin_config.appearance.minimap.mouseoverzone and not pfSkin_config.appearance.minimap.zonetext then
      pfSkin_config.appearance.minimap.zonetext = (pfSkin_config.appearance.minimap.mouseoverzone == "0") and "off" or "mouseover"
      pfSkin_config.appearance.minimap.mouseoverzone = nil
    end
    if pfSkin_config.appearance.minimap.coordsloc and not pfSkin_config.appearance.minimap.coordstext then
      if pfSkin_config.appearance.minimap.coordsloc == "off" then
        pfSkin_config.appearance.minimap.coordsloc = "bottomleft"
        pfSkin_config.appearance.minimap.coordstext = "off"
      else
        pfSkin_config.appearance.minimap.coordstext = "mouseover"
      end
    end
  end

  -- migrate pagemaster to separate settings
  if checkversion(5, 4, 15) then
    if pfSkin_config.bars.pagemaster == "1" then
      pfSkin_config.bars.pagemaster = nil
      pfSkin_config.bars.pagemasteralt = "1"
      pfSkin_config.bars.pagemastershift = "1"
      pfSkin_config.bars.pagemasterctrl = "1"
    end
  end

  -- migrate cooldown font from unit_font to separate setting
  if checkversion(5, 4, 18) then
    pfSkin_config.appearance.cd.font = pfSkin_config.global.font_unit
  end

  -- migrate combopoint size to separate settings
  if checkversion(5, 4, 18) then
    if pfSkin_config.unitframes.combosize then
      pfSkin_config.unitframes.combowidth = pfSkin_config.unitframes.combosize
      pfSkin_config.unitframes.comboheight = pfSkin_config.unitframes.combosize
      pfSkin_config.unitframes.combosize = nil
    end
  end


  -- Remove "Show only own debuffs" from unitframes and nameplates
  -- (feature was removed; only Target Debuff Bar in buffwatch keeps it)
  if pfSkin_config.nameplates then
    pfSkin_config.nameplates.selfdebuff = "0"
  end
  if pfSkin_config.unitframes then
    for _, unit in pairs({"target", "targettarget", "targettargettarget",
                          "focus", "focustarget", "pet", "pettarget",
                          "group", "raid", "player"}) do
      if pfSkin_config.unitframes[unit] and pfSkin_config.unitframes[unit].selfdebuff then
        pfSkin_config.unitframes[unit].selfdebuff = "0"
      end
    end
  end

  pfSkin_config.version = pfSkin.version.string
end