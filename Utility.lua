Utility = {};

-- YOINKED from NovaWorldBuffs (ty King)
function Utility:NormalizeWho(who)
	local normalizedRealmName = GetNormalizedRealmName();

	-- First remove spaces
	local normalizedWho = string.gsub(who, " ", "");

	-- Then any single quotes
	normalizedWho = string.gsub(normalizedWho, "'", "");

	-- If we don't have a realm, go ahead and append it
	if(not string.match(normalizedWho, "-") and normalizedRealmName) then
		--Sometimes it comes through without realm in classic?
		normalizedWho = normalizedWho .. "-" .. normalizedRealmName;
	end

	return normalizedWho;
end

function Utility:GetMeNormalized()
	return Utility:NormalizeWho(UnitName("player"));
end

-- Convert seconds to readable format (YOINKED from NovaWorldBuffs)
function Utility:ConvertSecondsToFormat(seconds, countOnly, type, space)
	local timecalc = 0;
	if (countOnly) then
		timecalc = seconds;
	else
		timecalc = seconds - time();
	end
	local d = math.floor((timecalc % (86400*365)) / 86400);
	local h = math.floor((timecalc % 86400) / 3600);
	local m = math.floor((timecalc % 3600) / 60);
	local s = math.floor((timecalc % 60));
	if (space or LOCALE_koKR or LOCALE_zhCN or LOCALE_zhTW) then
		space = " ";
	else
		space = "";
	end
	if (type == "short") then
		if (d == 1 and h == 0) then
			return d .. "d";
		elseif (d == 1) then
			return d .. "d" .. space .. h .. "h";
		end
		if (d > 1 and h == 0) then
			return d .. "d";
		elseif (d > 1) then
			return d .. "d" .. space .. h .. "h";
		end
		if (h == 1 and m == 0) then
			return h .. "h";
		elseif (h == 1) then
			return h .. "h" .. space .. m .. "m";
		end
		if (h > 1 and m == 0) then
			return h .. "h";
		elseif (h > 1) then
			return h .. "h" .. space .. m .. "m";
		end
		if (m == 1 and s == 0) then
			return m .. "m";
		elseif (m == 1) then
			return m .. "m" .. space .. s .. "s";
		end
		if (m > 1 and s == 0) then
			return m .. "m";
		elseif (m > 1) then
			return m .. "m" .. space .. s .. "s";
		end
		--If no matches it must be seconds only.
		return s .. "s";
	elseif (type == "medium") then
		if (d == 1 and h == 0) then
			return d .. " " .. L["dayMedium"];
		elseif (d == 1) then
			return d .. " " .. L["dayMedium"] .. " " .. h .. " " .. L["hoursMedium"];
		end
		if (d > 1 and h == 0) then
			return d .. " " .. L["daysMedium"];
		elseif (d > 1) then
			return d .. " " .. L["daysMedium"] .. " " .. h .. " " .. L["hoursMedium"];
		end
		if (h == 1 and m == 0) then
			return h .. " " .. L["hourMedium"];
		elseif (h == 1) then
			return h .. " " .. L["hourMedium"] .. " " .. m .. " " .. L["minutesMedium"];
		end
		if (h > 1 and m == 0) then
			return h .. " " .. L["hoursMedium"];
		elseif (h > 1) then
			return h .. " " .. L["hoursMedium"] .. " " .. m .. " " .. L["minutesMedium"];
		end
		if (m == 1 and s == 0) then
			return m .. " " .. L["minuteMedium"];
		elseif (m == 1) then
			return m .. " " .. L["minuteMedium"] .. " " .. s .. " " .. L["secondsMedium"];
		end
		if (m > 1 and s == 0) then
			return m .. " " .. L["minutesMedium"];
		elseif (m > 1) then
			return m .. " " .. L["minutesMedium"] .. " " .. s .. " " .. L["secondsMedium"];
		end
		--If no matches it must be seconds only.
		return s .. " " .. L["secondsMedium"];
	else
		if (d == 1 and h == 0) then
			return d .. " " .. "day";
		elseif (d == 1) then
			return d .. " " .. "day" .. " " .. h .. " " .. "hours";
		end
		if (d > 1 and h == 0) then
			return d .. " " .. "days";
		elseif (d > 1) then
			return d .. " " .. "days" .. " " .. h .. " " .. "hours";
		end
		if (h == 1 and m == 0) then
			return h .. " " .. "hour";
		elseif (h == 1) then
			return h .. " " .. "hour" .. " " .. m .. " " .. "minutes";
		end
		if (h > 1 and m == 0) then
			return h .. " " .. "hours";
		elseif (h > 1) then
			return h .. " " .. "hours" .. " " .. m .. " " .. "minutes";
		end
		if (m == 1 and s == 0) then
			return m .. " " .. "minute";
		elseif (m == 1) then
			return m .. " " .. "minute" .. " " .. s .. " " .. "seconds";
		end
		if (m > 1 and s == 0) then
			return m .. " " .. "minutes";
		elseif (m > 1) then
			return m .. " " .. "minutes" .. " " .. s .. " " .. "seconds";
		end
		--If no matches it must be seconds only.
		return s .. " " .. "seconds";
	end
end

function Utility:Find(list, predicateFunction)
	if(type(predicateFunction) ~= "function") then
		error("predicateFunction is not a function");
	end

	for key, value in pairs(list) do
		if(predicateFunction(key, value)) then
			return value;
		end
	end
end

function Utility:IsGuildMemberInInstance(rosterIndex)
	-- Get the players guild roster info
	local name, _, _, _, _, zone, _, _, online, _, _, _, _, isMobile = GetGuildRosterInfo(rosterIndex);

	-- If the player is online
	if (name and online and not isMobile) then
		-- Get the map info if we can (if we can't assume they're out in the open world)
		local mapInfo = Utility:Find(
			Maps,
			function(mapID, mapInfo)
				-- Instanced zones count as their own Map
				if(mapInfo.Name == zone) then
					return true;
				end

				return false;
			end
		);

		-- If their map info instance type is above 0, it's an instance
		if(mapInfo and mapInfo.InstanceType > 0) then
			return false;
		end
	end

	-- They're in the open world
	return true;
end

function Utility:TryNotifyGuild(whoHasAddon, message, isGuildMemberEligiblePredicateFunction)
	-- F- it ALWAYS send it
	-- SendChatMessage(message, "GUILD");

	-- Also YOINKED from Nova - thank you bro
	local eligiblePlayers = {};

	local numTotalMembers = GetNumGuildMembers();

	for i = 1, numTotalMembers do
		local name, _, _, _, _, zone, _, _, online, _, _, _, _, isMobile = GetGuildRosterInfo(i);

		-- If guild member is online and has addon installed
		if (name and online and whoHasAddon[name] and not isMobile) then
			local isEligible = true;

			if(type(isGuildMemberEligiblePredicateFunction) == "function") then
				isEligible = isGuildMemberEligiblePredicateFunction(i);
			end

			if(isEligible) then
				eligiblePlayers[name] = true;
			end
		end
	end

	local me = Utility:GetMeNormalized();

	-- Whoever is first in the list has prio to notify
	for who, _ in Utility:PairsByAlphabeticalKeys(eligiblePlayers) do
		if (who == me) then
			SendChatMessage(message, "GUILD");
		end

		return;
	end
end

-- SEE: https://www.lua.org/pil/19.3.html
function Utility:PairsByAlphabeticalKeys(_table, sortFunction)
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
