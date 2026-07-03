-- HoryUI :: node skill data (no logic, just a table)
-- Maps a gathering node's world-object name -> the profession + skill level
-- required to gather it. 1.12 has NO API that reports a node's required skill, so
-- (like data/sellprices.lua for vendor prices) this static table is required.
-- Read by modules/nodeskill.lua, which appends the requirement to the node's
-- tooltip on hover. Names are the enUS/Turtle world-object names; non-enUS
-- clients won't match (extend per-locale if needed). Turtle-custom nodes not
-- listed here simply show no line -- add them as you meet them.
--
-- Form: [nodeName] = { "<Profession>", <requiredSkill> }

HoryUI = HoryUI or {}

HoryUI.nodeSkills = {
  -- ------------------------------------------------------------------ Mining
  ["Copper Vein"]                     = { "Mining", 1 },
  ["Tin Vein"]                        = { "Mining", 65 },
  ["Silver Vein"]                     = { "Mining", 75 },
  ["Iron Deposit"]                    = { "Mining", 100 },
  ["Gold Vein"]                       = { "Mining", 115 },
  ["Mithril Deposit"]                 = { "Mining", 175 },
  ["Truesilver Deposit"]              = { "Mining", 230 },
  ["Small Thorium Vein"]              = { "Mining", 245 },
  ["Rich Thorium Vein"]               = { "Mining", 275 },
  ["Dark Iron Deposit"]               = { "Mining", 230 },
  ["Lesser Bloodstone Deposit"]       = { "Mining", 75 },
  ["Incendicite Mineral Vein"]        = { "Mining", 65 },
  ["Indurium Mineral Vein"]           = { "Mining", 150 },
  ["Hakkari Thorium Vein"]            = { "Mining", 275 },
  -- Ooze/rock covered variants share the base vein's requirement
  ["Ooze Covered Silver Vein"]        = { "Mining", 75 },
  ["Ooze Covered Gold Vein"]          = { "Mining", 115 },
  ["Ooze Covered Truesilver Deposit"] = { "Mining", 230 },
  ["Ooze Covered Mithril Deposit"]    = { "Mining", 175 },
  ["Ooze Covered Thorium Vein"]       = { "Mining", 245 },
  ["Ooze Covered Rich Thorium Vein"]  = { "Mining", 275 },

  -- -------------------------------------------------------------- Herbalism
  ["Peacebloom"]          = { "Herbalism", 1 },
  ["Silverleaf"]          = { "Herbalism", 1 },
  ["Earthroot"]           = { "Herbalism", 15 },
  ["Mageroyal"]           = { "Herbalism", 50 },
  ["Briarthorn"]          = { "Herbalism", 70 },
  ["Bruiseweed"]          = { "Herbalism", 100 },
  ["Wild Steelbloom"]     = { "Herbalism", 115 },
  ["Grave Moss"]          = { "Herbalism", 120 },
  ["Kingsblood"]          = { "Herbalism", 125 },
  ["Liferoot"]            = { "Herbalism", 150 },
  ["Fadeleaf"]            = { "Herbalism", 160 },
  ["Goldthorn"]           = { "Herbalism", 170 },
  ["Khadgar's Whisker"]   = { "Herbalism", 185 },
  ["Wintersbite"]         = { "Herbalism", 195 },
  ["Firebloom"]           = { "Herbalism", 205 },
  ["Purple Lotus"]        = { "Herbalism", 210 },
  ["Arthas' Tears"]       = { "Herbalism", 220 },
  ["Sungrass"]            = { "Herbalism", 230 },
  ["Blindweed"]           = { "Herbalism", 235 },
  ["Ghost Mushroom"]      = { "Herbalism", 245 },
  ["Gromsblood"]          = { "Herbalism", 250 },
  ["Golden Sansam"]       = { "Herbalism", 260 },
  ["Dreamfoil"]           = { "Herbalism", 270 },
  ["Mountain Silversage"] = { "Herbalism", 280 },
  ["Plaguebloom"]         = { "Herbalism", 285 },
  ["Icecap"]              = { "Herbalism", 290 },
  ["Black Lotus"]         = { "Herbalism", 300 },
  ["Bloodvine"]           = { "Herbalism", 300 },
}
