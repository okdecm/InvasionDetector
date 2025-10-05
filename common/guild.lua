local addonName, addon = ...;

local module = {};
addon.common = addon.common or {};
addon.common.guild = module;

function module:GetGuildMember(rosterIndex)
	local name, _, _, _, _, zone, _, _, online, _, _, _, _, isMobile = GetGuildRosterInfo(rosterIndex);

	if (not name) then
		return nil;
	end

	return {
		name = name,
		zone = zone,
		online = online,
		isMobile = isMobile
	};
end

function module:IsGuildMemberInInstance(rosterIndex)
	-- Get the players guild roster info
	local memberInfo = module:GetGuildMember(rosterIndex);

	if (not memberInfo) then
		return false;
	end

	local isOnline = (memberInfo.online and not memberInfo.isMobile);

	-- If the player is online
	if (not isOnline) then
		return false;
	end

	-- Get the map info if we can (if we can't assume they're out in the open world)
	local mapInfo = addon.common.collections:Find(
		addon.data.maps,
		function(mapID, mapInfo)
			-- Instanced zones count as their own Map
			if(mapInfo.Name == memberInfo.zone) then
				return true;
			end

			return false;
		end
	);

	-- If their map info instance type is above 0, it's an instance
	if(mapInfo and mapInfo.InstanceType > 0) then
		return false;
	end

	-- They're in the open world
	return true;
end

function module:TryAnnounceToGuild(peers, message)
	-- F-it ALWAYS send it
	-- SendChatMessage(message, "GUILD");

	-- print("Trying to announce to guild: " .. message);

	local me = addon.common.guids:Me();
	local meNormalized = addon.common.guids:Normalize(me);

	-- Also YOINKED from Nova - thank you bro
	local eligiblePlayers = {
		meNormalized
	};

	local numTotalMembers = GetNumGuildMembers();

	for rosterIndex = 1, numTotalMembers do
		local name, _, _, _, _, _, _, _, online, _, _, _, _, isMobile = GetGuildRosterInfo(rosterIndex);
		local hasAddon = peers[name];

		-- If guild member is online and has addon installed
		if (name and online and not isMobile and hasAddon) then
			table.insert(eligiblePlayers, name);
		end
	end

	table.sort(eligiblePlayers);

	-- Whoever is first in the list has prio to notify
	local firstPlayer = eligiblePlayers[1];

	-- print("First eligible player to announce to guild: " .. tostring(firstPlayer) .. " (me: " .. tostring(meNormalized) .. ")");

	if(firstPlayer == meNormalized) then
		-- We're the first player, announce to guild
		-- print("Announcing to guild: " .. message);

		SendChatMessage(message, "GUILD");
	end
end
