local addonName, addon = ...;

local module = {};
addon.common = addon.common or {};
addon.common.logging = module;

local logLevels = {
	debug = 0,
	info = 1,
	warn = 2,
	error = 3
};

function module:Log(prefix, level, message)
	print((prefix or "") .. "[" .. level .. "] " .. tostring(message));
end

function module:Create(config)
	local function createLogCallback(level)
		return function(message)
			if (logLevels[level] < logLevels[config.level]) then
				return;
			end

			module:Log(config.prefix, level, message);
		end
	end

	return {
		debug = createLogCallback("debug"),
		info = createLogCallback("info"),
		warn = createLogCallback("warn"),
		error = createLogCallback("error")
	};
end
