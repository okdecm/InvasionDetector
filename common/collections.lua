local addonName, addon = ...;

local module = {};
addon.common = addon.common or {};
addon.common.collections = module;

function module:Filter(collection, predicateFunction)
	if(type(predicateFunction) ~= "function") then
		error("predicateFunction is not a function");
	end

	local result = {};

	for key, value in pairs(collection) do
		if(predicateFunction(key, value)) then
			result[key] = value;
		end
	end

	return result;
end

function module:Find(collection, predicateFunction)
	if(type(predicateFunction) ~= "function") then
		error("predicateFunction is not a function");
	end

	for key, value in pairs(collection) do
		if(predicateFunction(key, value)) then
			return value;
		end
	end
end

function module:Contains(collection, value)
	for _, v in ipairs(collection) do
		if(v == value) then
			return true;
		end
	end

	return false;
end

-- SEE: https://www.lua.org/pil/19.3.html
function module:SortedPairs(collection, sortFunction)
	local clonedTable = {};

	for n in pairs(collection) do
		table.insert(clonedTable, n);
	end

	table.sort(clonedTable, sortFunction);

	local i = 0;
	local iterator = function()
		i = i + 1;

		if (clonedTable[i] == nil) then
			return nil;
		else
			return clonedTable[i], collection[clonedTable[i]];
		end
	end

	return iterator;
end
