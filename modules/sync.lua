local addonName, addon = ...;

local module = {};
addon.sync = module;

local logging = addon.common.logging;
local communication = addon.common.communication;
local versioning = addon.common.versioning;

local logger = logging:Create({
	prefix = addonName .. " - ",
	level = "info"
});

local communicator = nil;

function module:Initialize(config)
	logger.debug("Initializing sync module");

	communicator = communication:Create({
		prefix = config.prefix
	});

	communicator.listen(
		function(sender, channel, payload)
			-- print("Received message from " .. sender .. " on channel " .. channel .. ":");
			-- DevTools_Dump(payload);

			if (not payload) then
				logger.debug("Received empty message from " .. sender);

				return;
			end

			local senderAddonVersion = payload.addonVersion;

			if (not senderAddonVersion) then
				logger.debug("Received message without addon version from " .. sender);

				return;
			end

			local senderAddonVersionComparison = versioning:CompareSemanticVersions(
				versioning:ParseSemanticVersion(senderAddonVersion),
				versioning:ParseSemanticVersion(addon.version)
			);

			if (senderAddonVersionComparison < 0) then
				logger.debug("Received message from " .. sender .. " with out of date addon version");

				return;
			end

			if (senderAddonVersionComparison > 0) then
				logger.debug("Received message from " .. sender .. " with newer addon version");

				logger.warn("Your addon is out of date. Please update to the latest version.");

				return;
			end

			logger.debug("Received message of type " .. tostring(payload.type) .. " from " .. sender);

			if (payload.type == "SYNC_REQUEST") then
				config.onSyncRequest(sender);
			elseif (payload.type == "SYNC") then
				if (not payload.body) then
					logger.debug("Received SYNC message without body from " .. sender);

					return;
				end

				local invasions = payload.body.invasions;
				local shouldCounterSync = (payload.body.shouldCounterSync ~= false);

				if (not invasions) then
					logger.debug("Received SYNC message body without invasions from " .. sender);

					return;
				end

				config.onSync(sender, invasions, shouldCounterSync);
			elseif (payload.type == "INVASION_SPAWNED") then
				if (not payload.body) then
					logger.debug("Received INVASION_SPAWNED message without body from " .. sender);

					return;
				end

				if (not payload.body.layer) then
					logger.debug("Received INVASION_SPAWNED message without layer from " .. sender);

					return;
				end

				if (not payload.body.zone) then
					logger.debug("Received INVASION_SPAWNED message without zone from " .. sender);

					return;
				end

				if (not payload.body.when) then
					logger.debug("Received INVASION_SPAWNED message without when from " .. sender);

					return;
				end

				local layer = payload.body.layer;
				local zone = payload.body.zone;
				local when = payload.body.when;

				config.onInvasionSpawned(sender, layer, zone, when);
			elseif (payload.type == "INVASION_DESPAWNED") then
				if (not payload.body) then
					logger.debug("Received INVASION_DESPAWNED message without body from " .. sender);

					return;
				end

				if (not payload.body.layer) then
					logger.debug("Received INVASION_DESPAWNED message without layer from " .. sender);

					return;
				end

				if (not payload.body.zone) then
					logger.debug("Received INVASION_DESPAWNED message without zone from " .. sender);

					return;
				end

				if (not payload.body.when) then
					logger.debug("Received INVASION_DESPAWNED message without when from " .. sender);

					return;
				end

				local layer = payload.body.layer;
				local zone = payload.body.zone;
				local when = payload.body.when;

				config.onInvasionDespawned(sender, layer, zone, when);
			else
				logger.warn("Unknown message type: " .. tostring(payload.type));
			end
		end
	);
end

function module:GetPeers()
	if (not communicator) then
		logger.warn("Communicator not initialized");

		return nil;
	end

	return communicator.peers;
end

function Communicate(target, channel, message)
	if (not communicator) then
		logger.error("Communicator not initialized");

		return;
	end

	-- print("Communicating to " .. tostring(target) .. " on channel " .. tostring(channel) .. ":");
	-- DevTools_Dump(message);

	communicator.send(channel, target, message);
end

function CreateMessage(type, body)
	return {
		addonVersion = addon.version,
		type = type,
		body = body
	};
end

function module:RequestSync()
	logger.debug("IS REQUESTING SYNC FROM GUILD");

	local message = CreateMessage(
		"SYNC_REQUEST"
	);

	Communicate(nil, "GUILD", message);
end

function module:Sync(target, invasions, shouldCounterSync)
	logger.debug("IS SENDING SYNC TO " .. target);

	local message = CreateMessage(
		"SYNC",
		{
			invasions = invasions,
			shouldCounterSync = shouldCounterSync
		}
	);

	Communicate(target, "WHISPER", message);
end

function module:UpdateGuild(invasions)
	local message = CreateMessage(
		"SYNC",
		{
			invasions = invasions,
			shouldCounterSync = false
		}
	);

	Communicate(nil, "GUILD", message);
end

function module:AnnounceInvasionSpawned(layer, zone, when)
	logger.debug("IS ANNOUNCING INVASION SPAWNED IN " .. zone .. " ON LAYER " .. tostring(layer));

	local message = CreateMessage(
		"INVASION_SPAWNED",
		{
			layer = layer,
			zone = zone,
			when = when
		}
	);

	Communicate(nil, "GUILD", message);
end

function module:AnnounceInvasionDespawned(layer, zone, when)
	logger.debug("IS ANNOUNCING INVASION DESPAWNED IN " .. zone .. " ON LAYER " .. tostring(layer));

	local message = CreateMessage(
		"INVASION_DESPAWNED",
		{
			layer = layer,
			zone = zone,
			when = when
		}
	);

	Communicate(nil, "GUILD", message);
end
