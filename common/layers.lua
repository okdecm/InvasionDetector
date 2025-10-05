local addonName, addon = ...;

local module = {};
addon.common = addon.common or {};
addon.common.layers = module;

function module:GetCurrentLayer()
	if (not NWB_CurrentLayer) then
		error("NWB (NovaWorldBuffs) not found - unable to determine current layer");
	end

	return NWB_CurrentLayer;
end
