local LibSerialize = LibStub("LibSerialize");

InvasionDetector = {
	["AddonMessagePrefix"] = "InvasionDetector",
	["CheckSpeed"] = 5,
	["DecayBuffer"] = 10,
	["SpawnCooldown"] = 10800, -- 3 Hours
	["SpawnWindow"] = 3600, -- 1 Hour
	["HasAddon"] = {}
};

function InvasionDetector:Initialize()
	if(not InvasionDetectorDB) then
		InvasionDetectorDB = {
			["Invasions"] = {},
			["LastCheck"] = nil
		};
	end

	-- Register ourselves as having the addon (silly I know)
	local me = UnitName("player") .. "-" .. GetNormalizedRealmName();
	InvasionDetector.HasAddon[me] = true;

	C_ChatInfo.RegisterAddonMessagePrefix(InvasionDetector.AddonMessagePrefix);

	C_Timer.NewTicker(
		InvasionDetector.CheckSpeed,
		function()
			InvasionDetector:CheckForInvasions();
		end
	);
end

function InvasionDetector:CheckForInvasions()
	local checkTime = GetServerTime();

	-- Our maximum spawn time
	local minimumSpawnTime = InvasionDetector.SpawnCooldown;

	-- Map ID for Azeroth
	local mapID = 947;

	local pointsOfInterest = C_AreaPoiInfo.GetAreaPOIForMap(947);
	
	for _, pointOfInterest in ipairs(pointsOfInterest) do
		local pointOfInterestInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapID, pointOfInterest);

		-- Invasion found!
		if(pointOfInterestInfo.textureIndex == 41) then
			local invasionName = pointOfInterestInfo.description;

			print("invasionName " .. invasionName);

			-- Get our last seen time
			local lastSeen = InvasionDetectorDB.Invasions[invasionName];
			local timeDifference = (checkTime - (lastSeen or 0));

			if(timeDifference > 10) then
				print("TIME DIFFERENCE " .. timeDifference);
				print("minimumSpawnTime " .. minimumSpawnTime);
			end

			-- If we've not seen this invasion before or it was last seen as long ago as our decay buffer - it's a new spawn!
			if(not lastSeen or timeDifference >= minimumSpawnTime) then
				print("IS TRYING TO NOTIFY GUILD ABOUT " .. invasionName);
				-- Check if nobody has already notified in the guild chat
				InvasionDetector:TrySendGuildMessage("Invasion up! Spotted in " .. invasionName);
			end

			-- Store the time we saw it
			InvasionDetectorDB.Invasions[invasionName] = checkTime;
		end
	end

	InvasionDetectorDB.LastCheck = checkTime;
end

function InvasionDetector:TrySendGuildMessage(message)
	SendChatMessage("[Invasion Detector] " .. message, "GUILD");
	-- local onlineMembers = {};

	-- local numTotalMembers = GetNumGuildMembers();

	-- for i = 1, numTotalMembers do
	-- 	local name, _, _, _, _, _, _, _, online, _, _, _, _, isMobile = GetGuildRosterInfo(i);

	-- 	if (name and online and InvasionDetector.HasAddon[name] and not isMobile) then
	-- 		--If guild member is online and has addon installed add to temp table.
	-- 		onlineMembers[name] = true;
	-- 	end
	-- end

	-- local me = UnitName("player") .. "-" .. GetNormalizedRealmName();

	-- --Check temp table to see if we're first in alphabetical order.
	-- for k, v in pairs(onlineMembers) do
	-- 	if (k == me) then
	-- 		SendChatMessage("[Invasion Detector] " .. message, "GUILD");
	-- 	end

	-- 	return;
	-- end
end

function InvasionDetector:SendAddonMessage(type, body, chatType, target)
	local payload = {
		["Type"] = type,
		["Body"] = body
	};

	C_ChatInfo.SendAddonMessage(InvasionDetector.AddonMessagePrefix, LibSerialize:Serialize(payload), chatType, target);
end

function InvasionDetector:RequestSync()
	print("IS REQUESTING SYNC");

	InvasionDetector:SendAddonMessage("SYNC_REQUEST", nil, "GUILD");
end

function InvasionDetector:SendSync(target)
	print("IS SENDING SYNC");

	local response = {
		["Invasions"] = InvasionDetectorDB.Invasions
	};

	InvasionDetector:SendAddonMessage("SYNC", response, "WHISPER", target);
end

function InvasionDetector:RecieveAddonMessage(text, channel, sender, target)
	local me = UnitName("player") .. "-" .. GetNormalizedRealmName();

	local success, payload = LibSerialize:Deserialize(text);

	print("HAS GOT " .. payload.Type .. " MESSAGE FROM " .. sender .. " TO " .. target);

	-- If we ever recieve a message from someone else relating to this addon, note that down
	if(channel == "GUILD") then
		-- YOINKED from NovaWorldBuffs (ty King)
		local normalizedWho = string.gsub(sender, " ", "");
		normalizedWho = string.gsub(normalizedWho, "'", "");

		if (not string.match(normalizedWho, "-")) then
			--Sometimes it comes through without realm in classic?
			normalizedWho = normalizedWho .. "-" .. GetNormalizedRealmName();
		end

		InvasionDetector.HasAddon[normalizedWho] = true;
	end

	if(success) then
		if(payload.Type == "SYNC_REQUEST") then
			if(sender ~= me) then
				if(InvasionDetectorDB.LastCheck ~= nil) then
					InvasionDetector:SendSync(sender);
				end
			end
		elseif (payload.Type == "SYNC") then
			if(payload.Body) then
				-- Somebody has sent use their invasion data, try and update ours if we can
				local invasions = payload.Body.Invasions;

				for invasionName, lastSeen in pairs(invasions) do
					local myLastSeen = InvasionDetectorDB.Invasions[invasionName];

					-- Only overwrite newer "last seen" data (in the case one hadn't spawned when the user was online but had for another user)
					if(not myLastSeen or lastSeen > myLastSeen) then
						InvasionDetectorDB.Invasions[invasionName] = lastSeen;
					end
				end

				-- Send our data back to the sendee just so they can fill in any gaps also
				InvasionDetector:SendSync(sender);
			end
		end
	end
end

--Convert seconds to a readable format.
function InvasionDetector:ConvertSecondsToFormat(seconds, countOnly, type, space)
	local timecalc = 0;
	if (countOnly) then
		timecalc = seconds;
	else
		timecalc = seconds - time();
	end
	local d = math.floor((timecalc % (86400*365)) / 86400);
	local h = math.floor((timecalc % 86400) / 3600);
	local m = math.floor((timecalc % 3600) / 60);
	local s = math.floor((timecalc % 60));
	if (space or LOCALE_koKR or LOCALE_zhCN or LOCALE_zhTW) then
		space = " ";
	else
		space = "";
	end
	if (type == "short") then
		if (d == 1 and h == 0) then
			return d .. "d";
		elseif (d == 1) then
			return d .. "d" .. space .. h .. "h";
		end
		if (d > 1 and h == 0) then
			return d .. "d";
		elseif (d > 1) then
			return d .. "d" .. space .. h .. "h";
		end
		if (h == 1 and m == 0) then
			return h .. "h";
		elseif (h == 1) then
			return h .. "h" .. space .. m .. "m";
		end
		if (h > 1 and m == 0) then
			return h .. "h";
		elseif (h > 1) then
			return h .. "h" .. space .. m .. "m";
		end
		if (m == 1 and s == 0) then
			return m .. "m";
		elseif (m == 1) then
			return m .. "m" .. space .. s .. "s";
		end
		if (m > 1 and s == 0) then
			return m .. "m";
		elseif (m > 1) then
			return m .. "m" .. space .. s .. "s";
		end
		--If no matches it must be seconds only.
		return s .. "s";
	elseif (type == "medium") then
		if (d == 1 and h == 0) then
			return d .. " " .. L["dayMedium"];
		elseif (d == 1) then
			return d .. " " .. L["dayMedium"] .. " " .. h .. " " .. L["hoursMedium"];
		end
		if (d > 1 and h == 0) then
			return d .. " " .. L["daysMedium"];
		elseif (d > 1) then
			return d .. " " .. L["daysMedium"] .. " " .. h .. " " .. L["hoursMedium"];
		end
		if (h == 1 and m == 0) then
			return h .. " " .. L["hourMedium"];
		elseif (h == 1) then
			return h .. " " .. L["hourMedium"] .. " " .. m .. " " .. L["minutesMedium"];
		end
		if (h > 1 and m == 0) then
			return h .. " " .. L["hoursMedium"];
		elseif (h > 1) then
			return h .. " " .. L["hoursMedium"] .. " " .. m .. " " .. L["minutesMedium"];
		end
		if (m == 1 and s == 0) then
			return m .. " " .. L["minuteMedium"];
		elseif (m == 1) then
			return m .. " " .. L["minuteMedium"] .. " " .. s .. " " .. L["secondsMedium"];
		end
		if (m > 1 and s == 0) then
			return m .. " " .. L["minutesMedium"];
		elseif (m > 1) then
			return m .. " " .. L["minutesMedium"] .. " " .. s .. " " .. L["secondsMedium"];
		end
		--If no matches it must be seconds only.
		return s .. " " .. L["secondsMedium"];
	else
		if (d == 1 and h == 0) then
			return d .. " " .. "day";
		elseif (d == 1) then
			return d .. " " .. "day" .. " " .. h .. " " .. "hours";
		end
		if (d > 1 and h == 0) then
			return d .. " " .. "days";
		elseif (d > 1) then
			return d .. " " .. "days" .. " " .. h .. " " .. "hours";
		end
		if (h == 1 and m == 0) then
			return h .. " " .. "hour";
		elseif (h == 1) then
			return h .. " " .. "hour" .. " " .. m .. " " .. "minutes";
		end
		if (h > 1 and m == 0) then
			return h .. " " .. "hours";
		elseif (h > 1) then
			return h .. " " .. "hours" .. " " .. m .. " " .. "minutes";
		end
		if (m == 1 and s == 0) then
			return m .. " " .. "minute";
		elseif (m == 1) then
			return m .. " " .. "minute" .. " " .. s .. " " .. "seconds";
		end
		if (m > 1 and s == 0) then
			return m .. " " .. "minutes";
		elseif (m > 1) then
			return m .. " " .. "minutes" .. " " .. s .. " " .. "seconds";
		end
		--If no matches it must be seconds only.
		return s .. " " .. "seconds";
	end
end

local frame = CreateFrame("Frame", "InvasionDetectorFrame");

frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:RegisterEvent("CHAT_MSG_ADDON");

frame:SetScript(
	"OnEvent",
	function(frame, event, ...)
		if(event == "ADDON_LOADED") then
			local addonName = ...;

			if(addonName == "InvasionDetector") then
				InvasionDetector:Initialize();
			end
		elseif (event == "PLAYER_ENTERING_WORLD") then
			local isInitialLogin, isReloadingUI = ...;

			if(isInitialLogin or isReloadingUI) then
				InvasionDetector:RequestSync();
			end
		elseif (event == "CHAT_MSG_ADDON") then
			local prefix, text, channel, sender, target = ...;

			if(prefix == InvasionDetector.AddonMessagePrefix) then
				InvasionDetector:RecieveAddonMessage(text, channel, sender, target);
			end
		end
	end
);

SLASH_INVASTIONDETECTOR1 = "/invasiondetector";
SLASH_INVASTIONDETECTOR2 = "/id";

SlashCmdList["INVASTIONDETECTOR"] = function(...)
	local serverTime = GetServerTime();

	local maximumSpawnTime = (InvasionDetector.SpawnCooldown + InvasionDetector.SpawnWindow);

	for invasionName, lastSeen in pairs(InvasionDetectorDB.Invasions) do
		local timeDifference = (serverTime - lastSeen);

		-- Invasion is NOT active (wasn't seen recently)
		if(timeDifference > InvasionDetector.DecayBuffer) then
			local endOfSpawnWindow = (lastSeen + maximumSpawnTime);

			-- if our invasion is out of the bounds of the spawn time and is NOT active, it's a lost child (has since changed states when offline with no updates from guildies)
			if(endOfSpawnWindow < serverTime) then
				print(invasionName .. " invasion has no reliable timer");
			else
				local remainingTimeOnCooldown = (serverTime - (lastSeen + InvasionDetector.SpawnCooldown));

				-- Invasion is ON cooldown
				if(remainingTimeOnCooldown < 0) then
					print(invasionName .. " invasion is ON cooldown. Cooldown ends in " .. InvasionDetector:ConvertSecondsToFormat(-remainingTimeOnCooldown, true));
				else
					local remainingTimeInWindow = (InvasionDetector.SpawnWindow - remainingTimeOnCooldown);

					print(invasionName .. " invasion is off cooldown. Remaining time in window is " .. InvasionDetector:ConvertSecondsToFormat(remainingTimeInWindow, true));
				end
			end
		else
			print(invasionName .. " invasion is ACTIVE!");
		end
	end
end
