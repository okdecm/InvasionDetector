local addonName, addon = ...;

local LibDataBroker = LibStub("LibDataBroker-1.1");
local LibDBIcon = LibStub("LibDBIcon-1.0");

local ui = addon.ui;
local sync = addon.sync;
local checker = addon.checker;

local logging = addon.common.logging;
local collections = addon.common.collections;
local versioning = addon.common.versioning;
local guild = addon.common.guild;
local layers = addon.common.layers;

local config = {
	checkRate = 5,

	spawnCooldown = 10800, -- 3 hours
	spawnWindow = 3600, -- 1 hour
};

local peers = {};

local logger = logging:Create({
	prefix = addonName .. " - ",
	level = "info"
});

local addonLDB = LibDataBroker:NewDataObject(
	addonName,
	{
		type = "data source",
		text = "Invasion Detector",
		icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01.png",
		OnEnter = function(self, button)
			GameTooltip:SetOwner(self, "ANCHOR_NONE");
			GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT");

			GameTooltip:ClearLines();
			GameTooltip:AddLine("Invasion Detector");
			GameTooltip:AddLine("Left click to open the main window.", 0.6, 0.6, 0.6, true);

			GameTooltip:Show();
		end,
		OnLeave = function()
			GameTooltip:Hide();
		end,
		OnClick = function()
			ShowUI();
		end
	}
);

local frame = ui:Create(addonName .. "Frame");
local frameUpdateTicker = nil;

frame:Hide();

frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("PLAYER_ENTERING_WORLD");

frame:SetScript(
	"OnShow",
	function()
		logger.debug("Frame shown");

		frameUpdateTicker = C_Timer.NewTicker(
			1,
			function()
				UpdateUI();
			end
		);
	end
);

frame:SetScript(
	"OnHide",
	function()
		logger.debug("Frame hidden");

		if (not frameUpdateTicker) then
			return;
		end

		frameUpdateTicker:Cancel();
		frameUpdateTicker = nil;
	end
);

frame:SetScript(
	"OnEvent",
	function(frame, event, ...)
		if(event == "ADDON_LOADED") then
			local loadedAddonName = ...;

			-- If the addon is loading, initialize everything
			if (loadedAddonName ~= addonName) then
				return;
			end

			logger.debug("ADDON_LOADED");

			addon.version = C_AddOns.GetAddOnMetadata(addonName, "version");
			logger.info("Version: " .. tostring(addon.version));

			local semanticVersion = versioning:ParseSemanticVersion(addon.version);

			if (not InvasionDetectorDB or InvasionDetectorDB.addonVersion ~= addon.version) then
				logger.debug("Database version does not match current addon version, resetting database");

				InvasionDetectorDB = {
					addonVersion = addon.version,
					profile = {
						announcements = true,
						minimap = {
							hide = false
						}
					},
					invasions = {}
				};
			end

			LibDBIcon:Register(
				addonName,
				addonLDB,
				InvasionDetectorDB.profile.minimap
			);

			PruneInvasions();

			sync:Initialize({
				prefix = "Dec_ID-" .. semanticVersion.major,
				onSyncRequest = function(sender)
					logger.debug("Received sync request from " .. sender);

					sync:Sync(sender, InvasionDetectorDB.invasions, true);
				end,
				onSync = function(sender, currentLayer, invasions, shouldCounterSync)
					logger.debug("Received sync from " .. sender);

					peers[sender] = {
						lastSync = GetServerTime(),
						layer = currentLayer
					};

					for layer, zones in pairs(invasions) do
						InvasionDetectorDB.invasions[layer] = InvasionDetectorDB.invasions[layer] or {};

						for zone, invasion in pairs(zones) do
							local existingRecord = InvasionDetectorDB.invasions[layer][zone];

							local shouldUpdate = (not existingRecord or invasion.lastSeen > existingRecord.lastSeen);

							if (shouldUpdate) then
								InvasionDetectorDB.invasions[layer][zone] = invasion;
							end
						end
					end

					if (shouldCounterSync) then
						logger.debug("Countering sync from " .. sender);

						sync:Sync(sender, InvasionDetectorDB.invasions, false);
					end
				end
			});

			C_Timer.NewTicker(
				30,
				function()
					local currentLayer = layers:GetCurrentLayer();

					sync:Sync(nil, currentLayer, InvasionDetectorDB.invasions, false);
				end
			);
		elseif(event == "PLAYER_ENTERING_WORLD") then
			logger.debug("PLAYER_ENTERING_WORLD");

			-- Re sync our database if possible (e.g. when leaving an instance and we want fresh timers)
			sync:RequestSync();

			-- Wait for 5 seconds to allow POI's to load in (hacky)
			C_Timer.After(
				5,
				function()
					checker:Start({
						rate = 5,
						onTick = OnTick
					});
				end
			);
		else
			logger.warn("Unhandled event: " .. tostring(event));
		end
	end
);

function OnTick(when, layer, seenInvasions)
	PruneInvasions();

	local lastUpdatedOnTheSameLayer = (checker.lastUpdated and checker.lastUpdated.layer == layer);

	logger.debug("Tick received for layer " .. layer .. " with " .. tostring(#seenInvasions) .. " invasions");

	InvasionDetectorDB.invasions[layer] = InvasionDetectorDB.invasions[layer] or {};

	for _, zone in ipairs(seenInvasions) do
		local existingInvasion = InvasionDetectorDB.invasions[layer][zone];

		if (existingInvasion and existingInvasion.status == "active") then
			-- Already keeping track of invasion, update last seen
			existingInvasion.lastSeen = when;
		else
			-- Newly active invasion
			InvasionDetectorDB.invasions[layer][zone] = {
				status = "active",
				lastSeen = when
			};

			-- If we last updated on the same layer, we can be sure this invasion has spawned
			if (lastUpdatedOnTheSameLayer) then
				logger.debug("Invasion spawned in " .. zone .. " on layer " .. layer);

				InvasionDetectorDB.invasions[layer][zone].spawnedAt = when;

				MaybeAnnounceToGuild("Invasion spawned - " .. zone .. " (layer " .. layer .. ")");
				PlaySound(8459);
			end
		end
	end

	for zone, existingInvasion in pairs(InvasionDetectorDB.invasions[layer]) do
		local sawInvasion = collections:Contains(seenInvasions, zone);

		if (not sawInvasion) then
			if (existingInvasion.status == "inactive") then
				-- Already keeping track of invasion, skip it
			else
				-- Newly inactive invasion
				InvasionDetectorDB.invasions[layer][zone] = {
					status = "inactive",
					lastSeen = existingInvasion.lastSeen
				};

				-- If we last updated on the same layer, we can be sure this invasion has despawned
				if (lastUpdatedOnTheSameLayer) then
					logger.debug("Invasion despawned in " .. zone .. " on layer " .. layer);

					InvasionDetectorDB.invasions[layer][zone].despawnedAt = existingInvasion.lastSeen;

					MaybeAnnounceToGuild("Invasion despawned - " .. zone .. " (layer " .. layer .. ")");
				end
			end
		end
	end
end

function MaybeAnnounceToGuild(message)
	logger.debug("Maybe announcing to guild: " .. message);

	if (not InvasionDetectorDB.profile.announcements) then
		logger.debug("Announcements are disabled - skipping guild announcement");

		return;
	end

	local currentLayer = layers:GetCurrentLayer();

	if (not currentLayer) then
		logger.debug("Unable to determine current layer - skipping guild announcement");

		return;
	end

	local activePeersOnSameLayer = collections:Filter(
		peers,
		function(peer)
			local isOnSameLayer = (peer.layer == currentLayer);
			local lastSeenRecently = (GetServerTime() - peer.lastSync) < 300;

			return isOnSameLayer and lastSeenRecently;
		end
	);

	guild:TryAnnounceToGuild(
		activePeersOnSameLayer,
		message
	);
end

function ClearInvasions()
	InvasionDetectorDB.invasions = {};
end

function PruneInvasions()
	local now = GetServerTime();

	for layer, zones in pairs(InvasionDetectorDB.invasions) do
		for zone, invasion in pairs(zones) do
			local timeSinceLastSeen = now - invasion.lastSeen;

			if (timeSinceLastSeen > (config.spawnCooldown + config.spawnWindow)) then
				logger.debug("Pruning stale invasion on layer " .. layer .. " in zone " .. zone);

				InvasionDetectorDB.invasions[layer][zone] = nil;
			end
		end
	end
end

function UpdateUI()
	ui:RenderInvasions(frame, InvasionDetectorDB.invasions, config.spawnCooldown, config.spawnWindow);
end

function ShowUI()
	UpdateUI();

	frame:Show();
end

function HideUI()
	frame:Hide();
end

function ToggleMinimap()
	if (InvasionDetectorDB.profile.minimap.hide) then
		logger.info("Showing minimap icon");

		LibDBIcon:Show(addonName);
		InvasionDetectorDB.profile.minimap.hide = false;
	else
		logger.info("Hiding minimap icon");

		LibDBIcon:Hide(addonName);
		InvasionDetectorDB.profile.minimap.hide = true;
	end
end

function ToggleAnnouncements()
	if (not InvasionDetectorDB.profile.announcements) then
		logger.info("Enabling announcements");

		InvasionDetectorDB.profile.announcements = true;
	else
		logger.info("Disabling announcements");

		InvasionDetectorDB.profile.announcements = false;
	end
end

SLASH_INVASTIONDETECTOR1 = "/invasiondetector";
SLASH_INVASTIONDETECTOR2 = "/id";

SlashCmdList["INVASTIONDETECTOR"] = function(argumentsString, editBox)
	-- print("InvasionDetector slash command received arguments: " .. tostring(argumentsString));

	if (argumentsString == "test") then
		-- MaybeAnnounceToGuild("Ignore this - testing if some code works");
	end

	local arguments = strsplit(" ", argumentsString);

	local command = arguments[1];

	if (command == "show") then
		ShowUI();

		return;
	end

	if (command == "hide") then
		HideUI();

		return;
	end

	if (command == "clear") then
		ClearInvasions();

		return;
	end

	if (command == "prune") then
		PruneInvasions();

		return;
	end

	if (command == "minimap") then
		ToggleMinimap();

		return;
	end

	if (command == "announcements") then
		ToggleAnnouncements();

		return;
	end

	print("InvasionDetector (/id or /invasiondetector) commands:");
	print("show - Show the main window");
	print("hide - Hide the main window");
	print("clear - Clear all invasions from the database");
	print("prune - Prune stale invasions from the database");
	print("minimap - Toggle the minimap icon");
	print("announcements - Toggle announcements for spawns/despawns to guild");
end
