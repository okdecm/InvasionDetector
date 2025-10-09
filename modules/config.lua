local addonName, addon = ...;

local module = {};
addon.config = module;

local logging = addon.common.logging;

local logger = logging:Create({
	prefix = addonName .. " - ",
	level = "info"
});

local settingsCategory = nil;

function module:Initialize(config)
	local frame = CreateFrame("Frame", addonName .. "Config", UIParent, "ResizeLayoutFrame");
	frame:SetPoint("TOPLEFT");
	frame.spacing = 10;

	local header = CreateFrame("Frame", frame:GetID() .. "Header", frame, "ResizeLayoutFrame");
	header:SetPoint("TOPLEFT");
	header.spacing = 10;

	header.title = header:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
	header.title:SetPoint("TOPLEFT", 0, -10);
	header.title:SetText(addonName);

	header.credit = header:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
	header.credit:SetPoint("TOPLEFT", header.title, "BOTTOMLEFT", 0, -10);
	header.credit:SetText("by Dec (Decw - Spineshatter EU, @okdecm on Discord)");

	header:Layout();

	local body = CreateFrame("Frame", frame:GetID() .. "Body", frame, "ResizeLayoutFrame");
	body:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10);
	body.spacing = 10;

	local showMinimapButton = CreateCheckbox(
		body,
		"Minimap",
		"Show Minimap Button",
		"Show the minimap button to quickly open the config",
		function(self, checked)
			config.minimap.hide = not checked;
		end
	);
	showMinimapButton:SetPoint("TOPLEFT", body, "TOPLEFT", 0, -10);
	showMinimapButton:SetChecked(not config.minimap.hide);

	-- local announceInvasions = CreateCheckbox(
	-- 	body,
	-- 	"AnnounceInvasions",
	-- 	"Announce Invasions",
	-- 	"Announce invasions in guild chat",
	-- 	function(self, checked)
	-- 		config.announceInvasions = checked;
	-- 	end
	-- );
	-- announceInvasions:SetPoint("TOPLEFT", showMinimapButton, "BOTTOMLEFT", 0, -10);
	-- announceInvasions:SetChecked(config.announceInvasions);

	body:Layout();

	frame:Layout();

	frame:Hide();

	if InterfaceOptions_AddCategory then
		InterfaceOptions_AddCategory(frame);

		return;
	end

	local category, layout = Settings.RegisterCanvasLayoutCategory(frame, addonName);

	Settings.RegisterAddOnCategory(category);

	settingsCategory = category;
end

function module:Open()
	if InterfaceOptionsFrame_OpenToCategory then
		InterfaceOptionsFrame_OpenToCategory(addonName);

		return;
	end

	if (not settingsCategory) then
		logger.warn("Settings category not initialized");

		return;
	end

	Settings.OpenToCategory(settingsCategory.ID);
end

function CreateCheckbox(parent, id, label, description, onClick)
	local check = CreateFrame("CheckButton", parent:GetID() .. id .. "Checkbox", parent, "InterfaceOptionsCheckButtonTemplate");

	check:SetScript(
		"OnClick",
		function(self)
			local tick = self:GetChecked();

			onClick(self, tick and true or false);

			if tick then
				-- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
				PlaySound(856);
			else
				-- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
				PlaySound(857);
			end
		end
	);

	check.label = _G[check:GetName() .. "Text"];
	check.label:SetText(label);

	check.tooltipText = label;
	check.tooltipRequirement = description;

	return check;
end
