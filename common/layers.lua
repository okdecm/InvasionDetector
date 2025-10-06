local addonName, addon = ...;

local module = {};
addon.common = addon.common or {};
addon.common.layers = module;

function module:GetCurrentLayer()
	-- TY NovaWorldBuffs
	local layer = NWB_CurrentLayer;

	if (not layer or layer < 1) then
		return nil;
	end

	return layer;
end
