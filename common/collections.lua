local addonName, addon = ...;

local module = {};
addon.common = addon.common or {};
addon.common.collections = module;

function module:Find(list, predicateFunction)
	if(type(predicateFunction) ~= "function") then
		error("predicateFunction is not a function");
	end

	for key, value in pairs(list) do
		if(predicateFunction(key, value)) then
			return value;
		end
	end
end

function module:Contains(list, value)
	for _, v in ipairs(list) do
		if(v == value) then
			return true;
		end
	end

	return false;
end

-- SEE: https://www.lua.org/pil/19.3.html
function module:SortedPairs(_table, sortFunction)
	local clonedTable = {};

	for n in pairs(_table) do
		table.insert(clonedTable, n);
	end

	table.sort(clonedTable, sortFunction);

	local i = 0;
	local iterator = function()
		i = i + 1;

		if (clonedTable[i] == nil) then
			return nil;
		else
			return clonedTable[i], _table[clonedTable[i]];
		end
	end

	return iterator;
end
