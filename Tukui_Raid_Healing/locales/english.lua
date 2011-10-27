-- localization for enUS and enGB
local T, C, L = unpack(Tukui) -- Import: T - functions, constants, variables; C - config; L - locales

L.healium_NOTINCOMBAT = "Not while in combat"
L.healium_CHECKSPELL_SPELLNOTLEARNED = "Spell %s(%d) NOT learned"
L.healium_CHECKSPELL_SPELLNOTEXISTS = "Spell %d doesn't exist"
L.healium_CHECKSPELL_MACRONOTFOUND = "Macro %s NOT found"
L.healium_TOOLTIP_UNKNOWNSPELL = "Unknown spell %s(%d)"
L.healium_TOOLTIP_UNKNOWN_MACRO = "Unknown macro %s"
L.healium_TOOLTIP_UNKNOWN = "Unknown"
L.healium_TOOLIP_MACRO = "Macro: %s"
L.healium_TOOLTIP_TARGET = "Target: |cFF00FF00%s|r"
L.healium_BUFFDEBUFF_TOOMANYBUFF = "Too many buff for %s %s"
L.healium_BUFFDEBUFF_TOOMANYDEBUFF = "Too many debuff for %s %s"
L.healium_GREETING_VERSIONUNKNOWN = "Unknown version"
L.healium_GREETING_VERSION = "Version %s"
L.healium_GREETING_OPTIONS = "Use /th for in-game options"
L.healium_CONSOLE_HELP_GENERAL =     "Commands for %s or %s"
L.healium_CONSOLE_HELP_DEBUG =       " debug - toggle debug mode"
L.healium_CONSOLE_HELP_DUMPGENERAL = " dump - dump healium frames"
L.healium_CONSOLE_HELP_DUMPUNIT =    " dump [unit] - dump healium frame corresponding to unit"
L.healium_CONSOLE_HELP_DUMPPERF =    " dump perf - dump performance counters"
L.healium_CONSOLE_HELP_DUMPSHOW =    " dump show - show dump frame"
L.healium_CONSOLE_HELP_RESETPERF =   " reset perf - reset performance counters"
L.healium_CONSOLE_HELP_REFRESH =     " refresh - force a full refresh of heal buttons/buff/debuff"
L.healium_CONSOLE_HELP_TOGGLE =      " toggle raid||tank|pet|namelist - toggle frame"
L.healium_CONSOLE_HELP_NAMELISTADD =         " namelist add [name] - add name or currently targetted player to namelist"
L.healium_CONSOLE_HELP_NAMELISTREMOVE =      " namelist remove [name] - remove name or currently targetted player to namelist"
L.healium_CONSOLE_HELP_NAMELISTCLEAR =       " namelist clear - clear namelist"
L.healium_CONSOLE_DEBUG_ENABLED = "Switched to debug mode"
L.healium_CONSOLE_DEBUG_DISABLED = "Switch to release mode"
L.healium_CONSOLE_DUMP_UNITNOTFOUND = "Frame not found for unit %s"
L.healium_CONSOLE_RESET_PERF = "Performance counter resetted"
L.healium_CONSOLE_REFRESH_OK = "Frames refreshed"
L.healium_CONSOLE_TOGGLE_INVALID = "Valid choices are raid|tank|pet|namelist"
L.healium_CONSOLE_NAMELIST_ADDREMOVEINVALID = "Invalid or inexistant player"
L.healium_CONSOLE_NAMELIST_ADDALREADY = "Player already in namelist"
L.healium_CONSOLE_NAMELIST_REMOVENOTFOUND = "Player not found in namelist"
L.healium_CONSOLE_NAMELIST_INVALIDOPTION = "Invalid namelist option"
L.healium_CONSOLE_NAMELIST_ADDED = "%s added to namelist"
L.healium_CONSOLE_NAMELIST_REMOVED = "%s removed from namelist"
L.healium_CONSOLE_NAMELIST_CLEARED = "Namelist cleared"
L.healium_SETTINGS_UNKNOWNBUFFDEBUFF = "Unknown spellID %d from %s"
L.healium_SETTINGS_DUPLICATEBUFFDEBUFF = "SpellID %d and %d are the same buff/debuff (%s) in %s"
L.healium_TAB_TITLE = "Healium menu"
L.healium_TAB_TOOLTIP = "Healium: click for options"
L.healium_TAB_PLAYERFRAMESHOW = "Show raid frame"
L.healium_TAB_PLAYERFRAMEHIDE = "Hide raid frame"
L.healium_TAB_TANKFRAMESHOW = "Show tanks frame"
L.healium_TAB_TANKFRAMEHIDE = "Hide tanks frame"
L.healium_TAB_PETFRAMESHOW = "Show pets frame"
L.healium_TAB_PETFRAMEHIDE = "Hide pets frame"
L.healium_TAB_NAMELISTFRAMESHOW = "Show namelist frame"
L.healium_TAB_NAMELISTFRAMEHIDE = "Hide namelist frame"