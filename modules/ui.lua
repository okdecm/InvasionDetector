local addonName, addon = ...;

local module = {};
addon.ui = module;

function module:Create(id)
	local frame = CreateFrame("Frame", id, UIParent);

	frame:SetAttribute("toplevel", true);
	frame:SetFrameStrata("DIALOG");

	frame:SetSize(400, 200);
	frame:SetPoint("CENTER");
	frame:SetMovable(true);
	frame:SetResizable(true);

	frame.background = frame:CreateTexture();
	frame.background:SetAllPoints();
	frame.background:SetColorTexture(0, 0, 0, 0.5);

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
	frame.title:SetPoint("TOP", frame, "TOP", 0, -10);
	frame.title:SetText("Invasion Detector");

	frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton");
	frame.closeButton:SetSize(16, 16);
	frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2);
	frame.closeButton:SetScript(
		"OnClick",
		function()
			frame:Hide();
		end
	);

	frame.dragBar = CreateFrame("Frame", nil, frame, "PanelDragBarTemplate");
	frame.dragBar:SetHeight(32);
	frame.dragBar:SetPoint("TOPLEFT");
	frame.dragBar:SetPoint("TOPRIGHT");

	frame.resizeButton = CreateFrame("Button", nil, frame, "PanelResizeButtonTemplate");
	frame.resizeButton:SetPoint("BOTTOMRIGHT", -4, 4);
	frame.resizeButton:Init(frame, 300, 200);

	frame.content = CreateFrame("ScrollFrame", nil, frame, "WowScrollBox");
	frame.content:SetPoint("TOP", frame.title, "BOTTOM", 0, -10);
	frame.content:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10);
	frame.content:SetPoint("LEFT", frame, "LEFT", 10, 0);
	frame.content:SetPoint("RIGHT", frame, "RIGHT", -10, 0);

	frame.layers = {};

	return frame;
end

function module:RenderInvasions(frame, invasions, spawnCooldown, spawnWindow)
	local now = GetServerTime();

	local padding = 4;
	local gap = 6;

	local layerIndex = 0;
	for layer, zones in pairs(invasions) do
		layerIndex = layerIndex + 1;

		local layerFrame = frame.layers[layerIndex];

		if (not layerFrame) then
			layerFrame = CreateFrame("Frame", nil, frame.content);

			if (layerIndex == 1) then
				layerFrame:SetPoint("TOP");
				layerFrame:SetPoint("LEFT");
				layerFrame:SetPoint("RIGHT");
			else
				local relativeLayerFrame = frame.layers[layerIndex - 1];

				layerFrame:SetPoint("TOPLEFT", relativeLayerFrame, "BOTTOMLEFT", 0, -gap);
				layerFrame:SetPoint("TOPRIGHT", relativeLayerFrame, "BOTTOMRIGHT", 0, -gap);
			end

			layerFrame.background = layerFrame:CreateTexture();
			layerFrame.background:SetAllPoints();
			layerFrame.background:SetColorTexture(0, 0, 0, 0.5);

			layerFrame.title = layerFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText");
			layerFrame.title:SetPoint("TOPLEFT", layerFrame, "TOPLEFT", padding, -padding);
			layerFrame.title:SetTextColor(1, 0.8, 0, 1);

			layerFrame.zones = {};

			frame.layers[layerIndex] = layerFrame;
		end

		layerFrame.title:SetText("Layer " .. tostring(layer));

		local zonesHeight = 0;

		local zoneIndex = 0;
		for zone, invasion in pairs(zones) do
			zoneIndex = zoneIndex + 1;

			local zoneFrame = layerFrame.zones[zoneIndex];

			if (not zoneFrame) then
				zoneFrame = CreateFrame("Frame", nil, layerFrame);

				if (zoneIndex == 1) then
					zoneFrame:SetPoint("TOP", layerFrame.title, "BOTTOM", 0, -padding);
					zoneFrame:SetPoint("LEFT", layerFrame, "LEFT");
					zoneFrame:SetPoint("TOPRIGHT", layerFrame, "RIGHT");
				else
					local relativeZoneFrame = layerFrame.zones[zoneIndex - 1];

					zoneFrame:SetPoint("TOPLEFT", relativeZoneFrame, "BOTTOMLEFT");
					zoneFrame:SetPoint("TOPRIGHT", relativeZoneFrame, "BOTTOMRIGHT");
				end

				zoneFrame.background = zoneFrame:CreateTexture();
				zoneFrame.background:SetAllPoints();
				zoneFrame.background:SetColorTexture(0, 0, 0, 0.5);

				zoneFrame.title = zoneFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText");
				zoneFrame.title:SetPoint("LEFT", zoneFrame, "LEFT", padding, 0);

				zoneFrame.status = zoneFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText");
				zoneFrame.status:SetPoint("RIGHT", zoneFrame, "RIGHT", -padding, 0);

				zoneFrame.detail = zoneFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText");
				zoneFrame.detail:SetPoint("RIGHT", zoneFrame.status, "LEFT", -padding, 0);
				zoneFrame.detail:SetTextScale(0.8);

				layerFrame.zones[zoneIndex] = zoneFrame;
			end

			if (invasion.status == "active") then
				zoneFrame.status:SetText("Active");
				zoneFrame.status:SetTextColor(0, 1, 0, 1);

				local timeSinceLastSeen = now - invasion.lastSeen;

				if (invasion.spawnedAt) then
					local timeSinceSpawn = now - invasion.spawnedAt;

					zoneFrame.detail:SetText("Spawned " .. module:SecondsToClock(timeSinceSpawn) .. " ago / Last seen " .. module:SecondsToClock(timeSinceLastSeen) .. " ago");
				else
					zoneFrame.detail:SetText("Last seen " .. module:SecondsToClock(timeSinceLastSeen) .. " ago");
				end

				zoneFrame.detail:SetTextColor(1, 1, 1, 1);
			else
				zoneFrame.status:SetText("Inactive");
				zoneFrame.status:SetTextColor(1, 0, 0, 1);

				if (invasion.despawnedAt) then
					local timeSinceDespawn = now - invasion.despawnedAt;

					if (timeSinceDespawn < spawnCooldown) then
						local cooldown = spawnCooldown - timeSinceDespawn;

						zoneFrame.detail:SetText("On cooldown for " .. module:SecondsToClock(cooldown));
						zoneFrame.detail:SetTextColor(0.6, 1, 0.6, 1);
					else
						local window = (spawnWindow - (timeSinceDespawn - spawnCooldown));

						zoneFrame.detail:SetText("Spawn within " .. module:SecondsToClock(window));
						zoneFrame.detail:SetTextColor(1, 1, 0.6, 1);
					end
				else
					zoneFrame.detail:SetText("Lost track");
					zoneFrame.detail:SetTextColor(0.6, 0.6, 0.6, 1);
				end
			end

			zoneFrame.title:SetText(zone);

			zoneFrame:SetHeight(padding + zoneFrame.title:GetHeight() + padding);

			zoneFrame:Show();
			
			zonesHeight = zonesHeight + zoneFrame:GetHeight();
		end

		layerFrame:SetHeight(padding + layerFrame.title:GetHeight() + zonesHeight + padding);

		layerFrame:Show();
	end
end

function module:SecondsToClock(totalSeconds)
	local oneMinuteInSeconds = 60;

	if (totalSeconds < oneMinuteInSeconds) then
		return totalSeconds .. "s";
	end

	local oneHourInSeconds = 3600;

	if (totalSeconds < oneHourInSeconds) then
		local minutes = math.floor(totalSeconds / oneMinuteInSeconds);
		local seconds = totalSeconds - (minutes * oneMinuteInSeconds);

		return minutes .. "m " .. seconds .. "s";
	end

	local hours = math.floor(totalSeconds / oneHourInSeconds);
	local minutes = math.floor((totalSeconds - (hours * oneHourInSeconds)) / oneMinuteInSeconds);
	local seconds = totalSeconds - (hours * oneHourInSeconds) - (minutes * oneMinuteInSeconds);

	return hours .. "h " .. minutes .. "m " .. seconds .. "s";
end
