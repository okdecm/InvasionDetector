local addonName, addon = ...;

local data = {
	["0"] = {
		name = "Eastern Kingdoms",
		instanceType = 0
	},
	["1"] = {
		name = "Kalimdor",
		instanceType = 0
	},
	["13"] = {
		name = "Testing",
		instanceType = 0
	},
	["25"] = {
		name = "Scott Test",
		instanceType = 0
	},
	["29"] = {
		name = "CashTest",
		instanceType = 1
	},
	["30"] = {
		name = "Alterac Valley",
		instanceType = 3
	},
	["33"] = {
		name = "Shadowfang Keep",
		instanceType = 1
	},
	["34"] = {
		name = "Stormwind Stockade",
		instanceType = 1
	},
	["35"] = {
		name = "<unused>StormwindPrison",
		instanceType = 0
	},
	["36"] = {
		name = "Deadmines",
		instanceType = 1
	},
	["37"] = {
		name = "Azshara Crater",
		instanceType = 0
	},
	["42"] = {
		name = "Collin's Test",
		instanceType = 0
	},
	["43"] = {
		name = "Wailing Caverns",
		instanceType = 1
	},
	["44"] = {
		name = "<unused> Monastery",
		instanceType = 1
	},
	["47"] = {
		name = "Razorfen Kraul",
		instanceType = 1
	},
	["48"] = {
		name = "Blackfathom Deeps",
		instanceType = 1
	},
	["70"] = {
		name = "Uldaman",
		instanceType = 1
	},
	["90"] = {
		name = "Gnomeregan",
		instanceType = 1
	},
	["109"] = {
		name = "Sunken Temple",
		instanceType = 1
	},
	["129"] = {
		name = "Razorfen Downs",
		instanceType = 1
	},
	["169"] = {
		name = "Emerald Dream",
		instanceType = 2
	},
	["189"] = {
		name = "Scarlet Monastery",
		instanceType = 1
	},
	["209"] = {
		name = "Zul'Farrak",
		instanceType = 1
	},
	["229"] = {
		name = "Blackrock Spire",
		instanceType = 1
	},
	["230"] = {
		name = "Blackrock Depths",
		instanceType = 1
	},
	["249"] = {
		name = "Onyxia's Lair",
		instanceType = 2
	},
	["269"] = {
		name = "Caverns of Time",
		instanceType = 1
	},
	["289"] = {
		name = "Scholomance",
		instanceType = 1
	},
	["309"] = {
		name = "Zul'Gurub",
		instanceType = 2
	},
	["329"] = {
		name = "Stratholme",
		instanceType = 1
	},
	["349"] = {
		name = "Maraudon",
		instanceType = 1
	},
	["369"] = {
		name = "Deeprun Tram",
		instanceType = 0
	},
	["389"] = {
		name = "Ragefire Chasm",
		instanceType = 1
	},
	["409"] = {
		name = "Molten Core",
		instanceType = 2
	},
	["429"] = {
		name = "Dire Maul",
		instanceType = 1
	},
	["449"] = {
		name = "Alliance PVP Barracks",
		instanceType = 0
	},
	["450"] = {
		name = "Horde PVP Barracks",
		instanceType = 0
	},
	["451"] = {
		name = "Development Land",
		instanceType = 0
	},
	["469"] = {
		name = "Blackwing Lair",
		instanceType = 2
	},
	["489"] = {
		name = "Warsong Gulch",
		instanceType = 3
	},
	["509"] = {
		name = "Ruins of Ahn'Qiraj",
		instanceType = 2
	},
	["529"] = {
		name = "Arathi Basin",
		instanceType = 3
	},
	["531"] = {
		name = "Ahn'Qiraj Temple",
		instanceType = 2
	},
	["533"] = {
		name = "Naxxramas",
		instanceType = 2
	}
};

addon.data = addon.data or {};
addon.data.maps = data;
