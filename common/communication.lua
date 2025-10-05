local addonName, addon = ...;

local module = {};
addon.common = addon.common or {};
addon.common.communication = module;

local LibSerialize = LibStub("LibSerialize");
local LibDeflate = LibStub("LibDeflate");
local AceComm = LibStub("AceComm-3.0");

function module:Create(config)
	local peers = {};

	return {
		peers = peers,
		listen = function(onReceiveMessage)
			AceComm:RegisterComm(
				config.prefix,
				function(prefix, data, channel, sender)
					if (prefix ~= config.prefix) then
						return;
					end

					local me = addon.common.guids:Me();
					local meNormalized = addon.common.guids:Normalize(me);
					local senderNormalized = addon.common.guids:Normalize(sender);

					if (senderNormalized == meNormalized) then
						-- Ignore messages from ourselves
						return;
					end

					peers[senderNormalized] = {
						lastReceived = time()
					};

					local payload = module:DecodePayload(data);

					onReceiveMessage(sender, channel, payload);
				end
			);
		end,
		send = function(channel, target, data)
			local payload = module:EncodePayload(data);

			AceComm:SendCommMessage(config.prefix, payload, channel, target);
		end
	};
end

function module:EncodePayload(payload)
	local serialized = LibSerialize:Serialize(payload);
	local compressed = LibDeflate:CompressDeflate(
		serialized,
		{
			level = 9
		}
	);
	local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed);

	return encoded;
end

function module:DecodePayload(payload)
	local decoded = LibDeflate:DecodeForWoWAddonChannel(payload);

	if (not decoded) then
		error("Failed to decode payload");
	end

	local decompressed = LibDeflate:DecompressDeflate(decoded);

	if (not decompressed) then
		error("Failed to decompress payload");
	end

	local success, data = LibSerialize:Deserialize(decompressed);

	if (not success) then
		error("Failed to deserialize payload");
	end

	return data;
end
