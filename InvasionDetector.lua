local LibSerialize = LibStub("LibSerialize");
local LibDeflate = LibStub("LibDeflate");
local AceComm = LibStub("AceComm-3.0");

InvasionDetector = {
	["CommPrefix"] = "InvasionDetector",
	["CheckSpeed"] = 5,
	["SpawnCooldown"] = 10800, -- 3 Hours
	["SpawnWindow"] = 3600, -- 1 Hour
	
	["CheckTicker"] = nil,
	["HasAddon"] = {}
};

function InvasionDetector:Initialize()
	local currentVersion = GetAddOnMetadata("InvasionDetector", "Version") or 0;

	local isDatabaseOutdated = (not InvasionDetectorDB or not InvasionDetectorDB.Version or InvasionDetectorDB.Version < currentVersion);

	-- If we don't have a DB, or it's out of date, go ahead and (re-)create one
	if(not InvasionDetectorDB or isDatabaseOutdated) then
		if(not InvasionDetectorDB) then
			print("[Invasion Detector] Setting up database for the first time");
		else
			print("[Invasion Detector] Setting up fresh database due to new version");
		end

		InvasionDetectorDB = {
			["Version"] = currentVersion,
			["Invasions"] = {}
		};
	end

	local meNormalized = Utility:GetMeNormalized();

	-- Register ourselves as having the addon (silly I know)
	InvasionDetector.HasAddon[meNormalized] = true;

	-- Register our addon messages
	AceComm:RegisterComm(
		InvasionDetector.CommPrefix,
		function(...)
			return InvasionDetector:RecieveCommMessage(...);
		end
	);
end

function InvasionDetector:StartChecking()
	local inInstance = IsInInstance();

	-- If a ticker is already running - cancel it
	if(InvasionDetector.CheckTicker ~= nil) then
		InvasionDetector.CheckTicker:Cancel();
	end

	-- If we're in an instance, just run the checker once to flag any active invasions
	if(inInstance) then
		InvasionDetector:CheckForInvasions();
	else
		-- Start the ticker
		InvasionDetector.CheckTicker = C_Timer.NewTicker(
			InvasionDetector.CheckSpeed,
			function()
				InvasionDetector:CheckForInvasions();
			end
		);
	end
end

function InvasionDetector:CheckForInvasions()
	local checkTime = GetServerTime();

	-- Get the instance status ourselves due to the possiblity of this callback being called whilst transitioning between instances
	-- SEE: https://wow.gamepedia.com/API_C_Timer.NewTicker - Details area
	local inInstance = IsInInstance();

	local minimumSpawnTime = InvasionDetector.SpawnCooldown;

	-- We can only scan for POI's when not in instances
	if(not inInstance) then
		-- Map ID for Azeroth
		local mapID = 947;

		-- Get all our points of interest on the map
		local pointsOfInterest = C_AreaPoiInfo.GetAreaPOIForMap(947);
		
		for _, pointOfInterest in ipairs(pointsOfInterest) do
			local pointOfInterestInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapID, pointOfInterest);

			-- Invasion found!
			if(pointOfInterestInfo.textureIndex == 41) then
				local invasionName = pointOfInterestInfo.description;

				-- Make sure we have the structure to store info about this invasion
				InvasionDetectorDB.Invasions[invasionName] = InvasionDetectorDB.Invasions[invasionName] or {
					["Spawned"] = nil,
					["LastSeen"] = nil,
					["HasEnteredInstance"] = nil,
					["Despawned"] = nil
				};

				-- Get our last seen time
				local lastSeen = InvasionDetectorDB.Invasions[invasionName].LastSeen;
				local timeDifference = (checkTime - (lastSeen or 0));

				-- If we've not seen this invasion before or it was last seen as long ago as our decay buffer - it's a new spawn!
				if(not lastSeen or timeDifference >= minimumSpawnTime) then
					-- Note down when it spawned
					InvasionDetectorDB.Invasions[invasionName].Spawned = checkTime;
					InvasionDetectorDB.Invasions[invasionName].Despawned = nil;

					-- Try and notify in the guild chat
					Utility:TryNotifyGuild(InvasionDetector.HasAddon, "[Invasion Detector] Invasion up! Spotted in " .. invasionName);
				end

				-- Store the time we saw it
				InvasionDetectorDB.Invasions[invasionName].LastSeen = checkTime;
				-- Clear the instance flag
				InvasionDetectorDB.Invasions[invasionName].HasEnteredInstance = false;
			end
		end
	end

	-- Check our history for any de-spawns, and tag any we lose track of due to entering instances
	for invasionName, invasionInfo in pairs(InvasionDetectorDB.Invasions) do
		local spawned = invasionInfo.Spawned;
		local lastSeen = invasionInfo.LastSeen;
		local despanwed = invasionInfo.Despawned;

		local timeDifference = (checkTime - lastSeen);

		-- If it was last seen in the past, and it's still within the cooldown window, and it hasn't already been marked as despawned - it's a recent despawn
		if(lastSeen < checkTime and (timeDifference < minimumSpawnTime) and not despanwed) then
			-- If we've lost track of it due to entering an instance, note that down
			if(inInstance) then
				invasionInfo.HasEnteredInstance = true;
			else
				-- Note down when it despawned
				invasionInfo.Despawned = checkTime;

				-- Try and notify in the guild chat
				Utility:TryNotifyGuild(InvasionDetector.HasAddon, "[Invasion Detector] Invasion has ended in " .. invasionName);
			end
		end
	end

	InvasionDetectorDB.LastCheck = checkTime;
end

function InvasionDetector:RequestSync()
	-- print("[Invasion Detector] IS REQUESTING SYNC FROM GUILD");

	InvasionDetector:SendCommMessage("SYNC_REQUEST", nil, "GUILD");
end

function InvasionDetector:SendSync(target, shouldCounterSync)
	-- print("[Invasion Detector] IS SENDING SYNC TO " .. target);

	local response = {
		["Version"] = InvasionDetectorDB.Version,
		["Invasions"] = InvasionDetectorDB.Invasions,
		["ShouldCounterSync"] = shouldCounterSync
	};

	InvasionDetector:SendCommMessage("SYNC", response, "WHISPER", target);
end

function InvasionDetector:Sync(sender, version, invasions, shouldCounterSync)
	if(not version or version < InvasionDetectorDB.Version) then
		print("[Invasion Detector] Unable to sync - other user has out of date addon (" .. sender .. ")");
	elseif (version > InvasionDetectorDB.Version) then
		print("[Invasion Detector] Unable to sync - your addon is out of date");
	else
		-- print("[Invasion Detector] IS SYNCING WITH DATA FROM " .. sender);

		for invasionName, invasionInfo in pairs(invasions) do
			local lastSeen = invasionInfo.LastSeen;
			local myInvasionInfo = InvasionDetectorDB.Invasions[invasionName];

			-- Only overwrite newer "last seen" data (in the case one hadn't spawned when the user was online but had for another user)
			if(not myInvasionInfo or lastSeen > myInvasionInfo.LastSeen) then
				InvasionDetectorDB.Invasions[invasionName] = invasionInfo;
			end
		end

		-- Send our data back to the sendee just so they can fill in any gaps also
		if(shouldCounterSync) then
			-- We've just synced from them, so they shouldn't try and sync back again
			InvasionDetector:SendSync(sender, false);
		end
	end
end

function InvasionDetector:SendCommMessage(type, body, chatType, target)
	local data = {
		["Type"] = type,
		["Body"] = body
	};

	local serialized = LibSerialize:Serialize(data);
	local compressed = LibDeflate:CompressDeflate(serialized, {level = 9});
	local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed);

	AceComm:SendCommMessage(InvasionDetector.CommPrefix, encoded, chatType, target);
end

function InvasionDetector:RecieveCommMessage(prefix, payload, channel, sender)
	if(prefix ~= InvasionDetector.CommPrefix) then
		return;
	end

	local decoded = LibDeflate:DecodeForWoWAddonChannel(payload);

	if (not decoded) then
		print("[Invastion Detector] Failed to decode payload");

		return;
	end

	local decompressed = LibDeflate:DecompressDeflate(decoded);

	if (not decompressed) then
		print("[Invastion Detector] Failed to decompress payload");

		return;
	end

	local success, data = LibSerialize:Deserialize(decompressed);

	if (not success) then
		print("[Invastion Detector] Failed to deserialize payload");

		return;
	end

	local meNormalized = Utility:GetMeNormalized();
	local senderNormalized = Utility:NormalizeWho(sender);

	-- print("[Invasion Detector] HAS GOT " .. data.Type .. " MESSAGE FROM " .. senderNormalized);

	-- If we ever recieve a message relating to this addon, note that down
	InvasionDetector.HasAddon[senderNormalized] = true;

	if(data.Type == "SYNC_REQUEST") then
		-- Don't bother syncing with yourself dummy
		if(senderNormalized ~= meNormalized) then
			if(InvasionDetectorDB.LastCheck ~= nil) then
				InvasionDetector:SendSync(senderNormalized, true);
			end
		end
	elseif (data.Type == "SYNC") then
		if(data.Body) then
			-- Somebody has sent use their invasion data, try and update ours if we can
			local version = data.Body.Version;
			local invasions = data.Body.Invasions;
			local shouldCounterSync = data.Body.ShouldCounterSync;

			InvasionDetector:Sync(senderNormalized, version, invasions, shouldCounterSync);
		end
	end
end

function InvasionDetector:RecieveGuildMessage(text)
	text = string.lower(text);

	local command, arg = strsplit(" ", text, 2);

	if(string.match(command, "^!id")) then
		local serverTime = GetServerTime();

		-- Get how long it's been since our last send
		local timeDifference = (serverTime - (InvasionDetectorDB.LastSentGuildTimers or 0));

		-- If it has been sent within the last 2 minutes, don't bother
		if(timeDifference < (60 * 2)) then
			return;
		end

		-- Send the timers out to the guild
		InvasionDetector:OutputTimers("guild");

		-- Update our last sent time
		InvasionDetectorDB.LastSentGuildTimers = serverTime;
	end
end

function InvasionDetector:OutputTimers(chatType)
	local serverTime = GetServerTime();

	local messages = {};

	local maximumSpawnTime = (InvasionDetector.SpawnCooldown + InvasionDetector.SpawnWindow);

	for invasionName, invasionInfo in pairs(InvasionDetectorDB.Invasions) do
		local spawned = invasionInfo.Spawned;
		local lastSeen = invasionInfo.LastSeen;
		local hasEnteredInstance = invasionInfo.HasEnteredInstance;

		if(hasEnteredInstance) then
			messages[#messages + 1] = invasionName .. " invasion lost its timer due to the player entering an instance";
		else
			local timeDifference = (serverTime - lastSeen);

			-- Invasion is NOT active (wasn't seen recently)
			if(timeDifference > (InvasionDetector.CheckSpeed * 2)) then
				local endOfSpawnWindow = (lastSeen + maximumSpawnTime);

				-- if our invasion is out of the bounds of the spawn time and is NOT active, it's a lost child (has since changed states when offline with no updates from guildies)
				if(endOfSpawnWindow < serverTime) then
					messages[#messages + 1] = invasionName .. " invasion has no reliable timer";
				else
					local remainingTimeOnCooldown = (serverTime - (lastSeen + InvasionDetector.SpawnCooldown));

					-- Invasion is ON cooldown
					if(remainingTimeOnCooldown < 0) then
						messages[#messages + 1] = invasionName .. " invasion is ON cooldown. Cooldown ends in " .. Utility:ConvertSecondsToFormat(-remainingTimeOnCooldown, true);
					else
						local remainingTimeInWindow = (InvasionDetector.SpawnWindow - remainingTimeOnCooldown);

						messages[#messages + 1] = invasionName .. " invasion is off cooldown. Remaining time in window is " .. Utility:ConvertSecondsToFormat(remainingTimeInWindow, true);
					end
				end
			else
				local spawnedSecondsAgo = (serverTime - spawned);

				messages[#messages + 1] = invasionName .. " invasion is ACTIVE! Spawned " .. Utility:ConvertSecondsToFormat(spawnedSecondsAgo, true) .. " ago";
			end
		end
	end

	for _, message in ipairs(messages) do
		if(chatType == "guild") then
			Utility:TryNotifyGuild(InvasionDetector.HasAddon, "[Invasion Detector] " .. message, "GUILD");
		elseif(chatType == "party") then
			SendChatMessage("[Invasion Detector] " .. message, "PARTY");
		else
			print("[Invasion Detector] " .. message);
		end
	end
end

local frame = CreateFrame("Frame", "InvasionDetectorFrame");

frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:RegisterEvent("CHAT_MSG_GUILD");

frame:SetScript(
	"OnEvent",
	function(frame, event, ...)
		if(event == "ADDON_LOADED") then
			local addonName = ...;

			-- If the addon is loading, initialize everything
			if(addonName == "InvasionDetector") then
				InvasionDetector:Initialize();
			end
		elseif(event == "PLAYER_ENTERING_WORLD") then
			-- Re sync our database if possible (e.g. when leaving an instance and we want fresh timers)
			InvasionDetector:RequestSync();

			-- Start checking after 5 seconds
			C_Timer.After(
				5,
				function()
					InvasionDetector:StartChecking();
				end
			);
		elseif(event == "CHAT_MSG_GUILD") then
			local text = ...;

			InvasionDetector:RecieveGuildMessage(text);
		end
	end
);

SLASH_INVASTIONDETECTOR1 = "/invasiondetector";
SLASH_INVASTIONDETECTOR2 = "/id";

SlashCmdList["INVASTIONDETECTOR"] = function(argumentsString, editBox)
	InvasionDetector:OutputTimers(argumentsString);
end
