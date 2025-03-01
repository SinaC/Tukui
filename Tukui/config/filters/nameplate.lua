--[[
	Nameplate Filter
	
	Add the nameplates name that you do NOT want to see.
]]
local T, C, L = unpack(select(2, ...)) -- Import Functions/Constants, Config, Locales

local function SpellName(id)
	local name, _, _, _, _, _, _, _, _ = GetSpellInfo(id) 	
	return name
end


T.PlateBlacklist = {
	--Shaman Totems
	["Earth Elemental Totem"] = true,
	["Fire Elemental Totem"] = true,
	["Fire Resistance Totem"] = true,
	["Flametongue Totem"] = true,
	["Frost Resistance Totem"] = true,
	["Healing Stream Totem"] = true,
	["Magma Totem"] = true,
	["Mana Spring Totem"] = true,
	["Nature Resistance Totem"] = true,
	["Searing Totem"] = true,
	["Stoneclaw Totem"] = true,
	["Stoneskin Totem"] = true,
	["Strength of Earth Totem"] = true,
	["Windfury Totem"] = true,
	["Totem of Wrath"] = true,
	["Wrath of Air Totem"] = true,

	--Army of the Dead
	["Army of the Dead Ghoul"] = true,

	--Hunter Trap
	["Venomous Snake"] = true,
	["Viper"] = true,
	
	--Misc
	["Lava Parasite"] = true,

	--Test
	--["Unbound Seer"] = true,
}

-- Target/Arena Frames/ Nameplates use these
T.DebuffWhiteList = {
-- Death Knight
	[SpellName(47476)] = true, --strangulate
	[SpellName(49203)] = true, --hungering cold
-- Druid
	[SpellName(33786)] = true, --Cyclone
	[SpellName(2637)] = true, --Hibernate
	[SpellName(339)] = true, --Entangling Roots
	[SpellName(80964)] = true, --Skull Bash
	[SpellName(78675)] = true, --Solar Beam
-- Hunter
	[SpellName(3355)] = true, --Freezing Trap Effect
	--[SpellName(60210)] = true, --Freezing Arrow Effect
	[SpellName(1513)] = true, --scare beast
	[SpellName(19503)] = true, --scatter shot
	[SpellName(34490)] = true, --silence shot
-- Mage
	[SpellName(31661)] = true, --Dragon's Breath
	[SpellName(61305)] = true, --Polymorph
	[SpellName(18469)] = true, --Silenced - Improved Counterspell
	[SpellName(122)] = true, --Frost Nova
	[SpellName(55080)] = true, --Shattered Barrier
	[SpellName(82691)] = true, --Ring of Frost
-- Paladin
	[SpellName(20066)] = true, --Repentance
	[SpellName(10326)] = true, --Turn Evil
	[SpellName(853)] = true, --Hammer of Justice
-- Priest
	[SpellName(605)] = true, --Mind Control
	[SpellName(64044)] = true, --Psychic Horror
	[SpellName(8122)] = true, --Psychic Scream
	[SpellName(9484)] = true, --Shackle Undead
	[SpellName(15487)] = true, --Silence
-- Rogue
	[SpellName(2094)] = true, --Blind
	[SpellName(1776)] = true, --Gouge
	[SpellName(6770)] = true, --Sap
	[SpellName(18425)] = true, --Silenced - Improved Kick
-- Shaman
	[SpellName(51514)] = true, --Hex
	[SpellName(3600)] = true, --Earthbind
	[SpellName(8056)] = true, --Frost Shock
	[SpellName(63685)] = true, --Freeze
	[SpellName(39796)] = true, --Stoneclaw Stun
-- Warlock
	[SpellName(710)] = true, --Banish
	[SpellName(6789)] = true, --Death Coil
	[SpellName(5782)] = true, --Fear
	[SpellName(5484)] = true, --Howl of Terror
	[SpellName(6358)] = true, --Seduction
	[SpellName(30283)] = true, --Shadowfury
	[SpellName(89605)] = true, --Aura of Foreboding
-- Warrior
	[SpellName(20511)] = true, --Intimidating Shout
-- Racial
	[SpellName(25046)] = true, --Arcane Torrent
	[SpellName(20549)] = true, --War Stomp
--PVE
}
