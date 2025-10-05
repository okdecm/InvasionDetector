local addonName, addon = ...;

local module = {};
addon.common = addon.common or {};
addon.common.versioning = module;

function module:CompareSemanticVersions(a, b)
	if (a.major ~= b.major) then
		return a.major - b.major;
	end

	if (a.minor ~= b.minor) then
		return a.minor - b.minor;
	end

	return a.patch - b.patch;
end

function module:FormatSemanticVersion(major, minor, patch)
	return string.format("%d.%d.%d", major, minor, patch);
end

function module:ParseSemanticVersion(value)
	local major, minor, patch = string.match(value, "^(%d+)%.(%d+)%.(%d+)$");

	if (not major) then
		return nil;
	end

	return {
		major = tonumber(major),
		minor = tonumber(minor),
		patch = tonumber(patch)
	};
end