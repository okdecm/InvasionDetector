local addonName, addon = ...;

local module = {};
addon.common = addon.common or {};
addon.common.guids = module;

function module:Me()
	return UnitName("player");
end

-- YOINKED from NovaWorldBuffs (ty King)
function module:Normalize(who)
	local normalizedRealmName = GetNormalizedRealmName();

	-- First remove spaces
	local normalized = string.gsub(who, " ", "");

	-- Then any single quotes
	normalized = string.gsub(normalized, "'", "");

	-- If we don't have a realm, go ahead and append it
	if(not string.match(normalized, "-") and normalizedRealmName) then
		--Sometimes it comes through without realm in classic?
		normalized = normalized .. "-" .. normalizedRealmName;
	end

	return normalized;
end
