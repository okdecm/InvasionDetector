local addonName, addon = ...;

local module = {};
addon.checker = module;

local logging = addon.common.logging;
local layers = addon.common.layers;

local logger = logging:Create({
	prefix = addonName .. " - ",
	level = "info"
});

local updateTicker = nil;

module.lastUpdated = nil;

function module:Start(config)
	logger.debug("Starting checker");

	if (updateTicker) then
		logger.debug("Stopping previous update ticker");

		updateTicker:Cancel();
	end

	logger.debug("Starting new update ticker with rate " .. tostring(config.rate) .. " seconds");

	updateTicker = C_Timer.NewTicker(
		config.rate,
		function()
			local now = GetServerTime();

			logger.debug("Tick: " .. tostring(now));

			local inInstance = IsInInstance();

			if (inInstance) then
				logger.debug("Player is in an instance - skipping tick");

				return;
			end

			local layer = layers:GetCurrentLayer();

			if (not layer or layer < 1) then
				logger.debug("Unable to determine current layer - skipping tick");

				return;
			end

			local invasions = FindInvasions();

			config.onTick(now, layer, invasions);

			-- Flag our last update
			module.lastUpdated = {
				when = now,
				layer = layer
			};
		end
	);
end

function FindInvasions()
	logger.debug("Finding invasions");

	local azerothMapID = 947;

	local invasions = {};

	-- Get all our points of interest on the map (Azeroth)
	local pointsOfInterest = C_AreaPoiInfo.GetAreaPOIForMap(azerothMapID);

	-- logger.debug("Found " .. tostring(#pointsOfInterest) .. " points of interest on map " .. tostring(azerothMapID));

	for _, pointOfInterest in ipairs(pointsOfInterest) do
		local pointOfInterestInfo = C_AreaPoiInfo.GetAreaPOIInfo(azerothMapID, pointOfInterest);

		-- logger.debug("Found point of interest with ID " .. tostring(pointOfInterest) .. " and name " .. tostring(pointOfInterestInfo.name));

		-- Is POI an invasion
		if(pointOfInterestInfo.name == "Under Attack") then
			-- Invasion found!
			local zone = pointOfInterestInfo.description;

			logger.debug("Found invasion in zone " .. tostring(zone));

			table.insert(
				invasions,
				zone
			);
		end
	end

	logger.debug("Found " .. tostring(#invasions) .. " invasions");

	return invasions;
end
