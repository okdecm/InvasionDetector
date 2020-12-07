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

function Utility:TryNotifyGuild(message)
	-- F- it ALWAYS send it
	SendChatMessage(message, "GUILD");

	-- local onlineMembers = {};

	-- local numTotalMembers = GetNumGuildMembers();

	-- for i = 1, numTotalMembers do
	-- 	local name, _, _, _, _, _, _, _, online, _, _, _, _, isMobile = GetGuildRosterInfo(i);

	-- 	if (name and online and InvasionDetector.HasAddon[name] and not isMobile) then
	-- 		--If guild member is online and has addon installed add to temp table.
	-- 		onlineMembers[name] = true;
	-- 	end
	-- end

	-- local me = UnitName("player") .. "-" .. GetNormalizedRealmName();

	-- --Check temp table to see if we're first in alphabetical order.
	-- for k, v in pairs(onlineMembers) do
	-- 	if (k == me) then
	-- 		SendChatMessage("[Invasion Detector] " .. message, "GUILD");
	-- 	end

	-- 	return;
	-- end
end
