---
-- SexyLoot Options - Standalone Window
-- Full control over layout and size

local _, private = ...;

-- Define UpdatePreviewFrame to prevent errors (simple stub)
function UpdatePreviewFrame()
	if SexyLoot_UpdatePreviewFrame then
		SexyLoot_UpdatePreviewFrame();
	end
end

-- Create the main options frame
local optionsFrame = CreateFrame("Frame", "SexyLootOptionsFrame", UIParent);
optionsFrame:SetSize(600, 500);
optionsFrame:SetPoint("CENTER");
optionsFrame:SetMovable(true);
optionsFrame:EnableMouse(true);
optionsFrame:RegisterForDrag("LeftButton");
optionsFrame:SetScript("OnDragStart", optionsFrame.StartMoving);
optionsFrame:SetScript("OnDragStop", optionsFrame.StopMovingOrSizing);
optionsFrame:Hide();

-- Create background
optionsFrame:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 8, right = 8, top = 8, bottom = 8 }
});
optionsFrame:SetBackdropColor(0, 0, 0, 1);

-- Create title background
local titleBg = optionsFrame:CreateTexture(nil, "OVERLAY");
titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header");
titleBg:SetPoint("TOP", 0, 12);
titleBg:SetSize(256, 64);

-- Title
optionsFrame.title = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal");
optionsFrame.title:SetPoint("TOP", 0, -2);
optionsFrame.title:SetText("|cffff69b4SexyLoot|r Configuration");

-- Create close button
local closeButton = CreateFrame("Button", nil, optionsFrame, "UIPanelCloseButton");
closeButton:SetPoint("TOPRIGHT", -2, -2);
closeButton:SetScript("OnClick", function()
	optionsFrame:Hide();
end);

-- Create inset frame for content
local inset = CreateFrame("Frame", nil, optionsFrame);
inset:SetPoint("TOPLEFT", 12, -30);
inset:SetPoint("BOTTOMRIGHT", -12, 30);
inset:SetBackdrop({
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
});
inset:SetBackdropColor(0.1, 0.1, 0.1, 0.8);

-- Create tab container
local tabContainer = CreateFrame("Frame", nil, inset);
tabContainer:SetPoint("TOPLEFT", 10, -10);
tabContainer:SetPoint("BOTTOMRIGHT", -10, 10);

-- Tab buttons
local tabs = {};
local tabContent = {};

local function CreateTab(id, text)
	local tab = CreateFrame("Button", "SexyLootOptionsFrameTab"..id, optionsFrame, "CharacterFrameTabButtonTemplate");
	tab:SetID(id);
	tab:SetText(text);
	tab:SetScript("OnClick", function(self)
		-- Manually handle tab switching
		for i = 1, #tabs do
			if i == self:GetID() then
				tabs[i]:SetDisabledFontObject(GameFontHighlightSmall);
				tabContent[i]:Show();
			else
				tabs[i]:SetDisabledFontObject(GameFontDisableSmall);
				tabContent[i]:Hide();
			end
		end
	end);
	return tab;
end

-- Create tabs
tabs[1] = CreateTab(1, "General");
tabs[2] = CreateTab(2, "Tracking");
tabs[3] = CreateTab(3, "Display");
tabs[4] = CreateTab(4, "Filters");

-- Position tabs and initialize
tabs[1]:SetPoint("TOPLEFT", optionsFrame, "BOTTOMLEFT", 15, 2);
for i = 2, #tabs do
	tabs[i]:SetPoint("LEFT", tabs[i-1], "RIGHT", -16, 0);
end

-- Initialize the tab system
optionsFrame.numTabs = #tabs;
optionsFrame.selectedTab = 1;

-- Tab 1: General Settings
tabContent[1] = CreateFrame("Frame", nil, tabContainer);
tabContent[1]:SetAllPoints();

local generalY = -20;

-- Test preview button (temporary for debugging)
local previewTestButton = CreateFrame("Button", nil, tabContent[1], "UIPanelButtonTemplate");
previewTestButton:SetPoint("TOPLEFT", 350, generalY - 80);
previewTestButton:SetSize(120, 22);
previewTestButton:SetText("Toggle Preview");
previewTestButton:SetScript("OnClick", function()
	if not SexyLootDB then SexyLootDB = {}; end
	SexyLootDB.locked = not SexyLootDB.locked;
	print("TEST BUTTON: locked =", SexyLootDB.locked);
	if UpdatePreviewFrame then
		print("TEST BUTTON: Calling UpdatePreviewFrame");
		UpdatePreviewFrame();
	else
		print("TEST BUTTON: UpdatePreviewFrame not found");
	end
end);

-- Lock/Unlock checkbox
local lockCheck = CreateFrame("CheckButton", "SexyLootLockCheck", tabContent[1], "UICheckButtonTemplate");
lockCheck:SetPoint("TOPLEFT", 20, generalY);
_G[lockCheck:GetName().."Text"]:SetText("Lock Frames (uncheck to enable dragging)");
lockCheck:SetScript("OnClick", function(self)
	SexyLootDB.locked = self:GetChecked();
	if SexyLootDB.locked then
		print("|cffff69b4SexyLoot:|r Frames locked");
	else
		print("|cffff69b4SexyLoot:|r Frames unlocked - drag to reposition");
	end
	-- Update preview frame visibility
	if SexyLoot_UpdatePreviewFrame then
		SexyLoot_UpdatePreviewFrame();
	else
		print("SexyLoot Debug: Preview function not available from checkbox");
	end
end);

-- Test all button
local testButton = CreateFrame("Button", nil, tabContent[1], "UIPanelButtonTemplate");
testButton:SetPoint("TOPLEFT", 350, generalY + 3);
testButton:SetSize(100, 22);
testButton:SetText("Test All");
testButton:SetScript("OnClick", function()
	SexyLoot_ShowTestAlerts();
end);

-- Reset position button
local resetButton = CreateFrame("Button", nil, tabContent[1], "UIPanelButtonTemplate");
resetButton:SetPoint("LEFT", testButton, "RIGHT", 5, 0);
resetButton:SetSize(100, 22);
resetButton:SetText("Reset Position");
resetButton:SetScript("OnClick", function()
	SexyLootDB.positions = nil;
	SexyLootDB.anchorPoint = nil;
	SexyLootDB.anchorX = nil;
	SexyLootDB.anchorY = nil;
	print("|cffff69b4SexyLoot:|r Positions reset to default");
	if LootAlertFrameMixIn then
		LootAlertFrameMixIn:AdjustAnchors();
	end
	-- Update preview frame position
	SexyLoot_UpdatePreviewFrame();
end);

generalY = generalY - 40;

-- Sound settings
local soundHeader = tabContent[1]:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
soundHeader:SetPoint("TOPLEFT", 20, generalY);
soundHeader:SetText("Sound Settings");
generalY = generalY - 25;

local soundCheck = CreateFrame("CheckButton", "SexyLootSoundCheck", tabContent[1], "UICheckButtonTemplate");
soundCheck:SetPoint("TOPLEFT", 20, generalY);
_G[soundCheck:GetName().."Text"]:SetText("Enable Sounds");
soundCheck:SetScript("OnClick", function(self)
	SexyLootDB.config = SexyLootDB.config or {};
	SexyLootDB.config.sound = self:GetChecked();
end);

generalY = generalY - 30;

local coinSoundCheck = CreateFrame("CheckButton", "SexyLootCoinSoundCheck", tabContent[1], "UICheckButtonTemplate");
coinSoundCheck:SetPoint("TOPLEFT", 20, generalY);
_G[coinSoundCheck:GetName().."Text"]:SetText("Use coin jingle for money gains (not losses)");
coinSoundCheck:SetScript("OnClick", function(self)
	SexyLootDB.config = SexyLootDB.config or {};
	SexyLootDB.config.coinSound = self:GetChecked();
end);

generalY = generalY - 30;

local animCheck = CreateFrame("CheckButton", "SexyLootAnimCheck", tabContent[1], "UICheckButtonTemplate");
animCheck:SetPoint("TOPLEFT", 20, generalY);
_G[animCheck:GetName().."Text"]:SetText("Enable Animations");
animCheck:SetScript("OnClick", function(self)
	SexyLootDB.config = SexyLootDB.config or {};
	SexyLootDB.config.anims = self:GetChecked();
end);

generalY = generalY - 40;

-- Test buttons
local testHeader = tabContent[1]:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
testHeader:SetPoint("TOPLEFT", 20, generalY);
testHeader:SetText("Test Individual Toasts");
generalY = generalY - 30;

local testTypes = {
	{name = "Legendary", func = "TestLegendary"},
	{name = "Epic", func = "TestEpic"},
	{name = "Common", func = "TestCommon"},
	{name = "Money Gain", func = "TestMoneyGain"},
	{name = "Money Loss", func = "TestMoneyLoss"},
	{name = "Recipe", func = "TestRecipe"},
};

local btnX = 20;
local btnY = generalY;
for i, test in ipairs(testTypes) do
	local btn = CreateFrame("Button", nil, tabContent[1], "UIPanelButtonTemplate");
	btn:SetPoint("TOPLEFT", btnX, btnY);
	btn:SetSize(85, 22);
	btn:SetText(test.name);
	btn:SetScript("OnClick", function()
		_G["SexyLoot_"..test.func]();
	end);
	
	btnX = btnX + 90;
	if i % 3 == 0 then
		btnX = 20;
		btnY = btnY - 27;
	end
end

-- Tab 2: Tracking Settings
tabContent[2] = CreateFrame("Frame", nil, tabContainer);
tabContent[2]:SetAllPoints();
tabContent[2]:Hide();

local trackingY = -20;

local trackingHeader = tabContent[2]:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
trackingHeader:SetPoint("TOPLEFT", 20, trackingY);
trackingHeader:SetText("Choose What to Track");
trackingY = trackingY - 30;

local trackingOptions = {
	{var = "looting", text = "Track Looting (items you pick up)"},
	{var = "creating", text = "Track Crafting (items you create)"},
	{var = "rolling", text = "Track Rolling (dungeon/raid rolls)"},
	{var = "money", text = "Track Money Changes (gains and losses)"},
	{var = "trades", text = "Track Trades (items received in trade)"},
	{var = "mail", text = "Track Mail (items received via mail)"},
	{var = "recipes", text = "Track Recipe Learning"},
	{var = "honor", text = "Track Honor/PvP Rewards"},
};

for _, option in ipairs(trackingOptions) do
	local check = CreateFrame("CheckButton", "SexyLoot"..option.var.."Check", tabContent[2], "UICheckButtonTemplate");
	check:SetPoint("TOPLEFT", 20, trackingY);
	_G[check:GetName().."Text"]:SetText(option.text);
	check:SetScript("OnClick", function(self)
		SexyLootDB.config = SexyLootDB.config or {};
		SexyLootDB.config[option.var] = self:GetChecked();
	end);
	trackingY = trackingY - 30;
end

-- Tab 3: Display Settings
tabContent[3] = CreateFrame("Frame", nil, tabContainer);
tabContent[3]:SetAllPoints();
tabContent[3]:Hide();

local displayY = -20;

-- Scale slider
local scaleSlider = CreateFrame("Slider", "SexyLootScaleSlider", tabContent[3], "OptionsSliderTemplate");
scaleSlider:SetPoint("TOPLEFT", 30, displayY);
scaleSlider:SetMinMaxValues(0.3, 2.0);
scaleSlider:SetValueStep(0.05);
scaleSlider:SetWidth(200);
_G[scaleSlider:GetName().."Text"]:SetText("Alert Scale");
_G[scaleSlider:GetName().."Low"]:SetText("0.3");
_G[scaleSlider:GetName().."High"]:SetText("2.0");
scaleSlider:SetScript("OnValueChanged", function(self, value)
	SexyLootDB.config = SexyLootDB.config or {};
	SexyLootDB.config.scale = value;
	_G[self:GetName().."Text"]:SetText(string.format("Alert Scale: %.2f", value));
	-- Update preview frame scale if visible
	UpdatePreviewFrame();
end);

displayY = displayY - 60;

-- Number of toasts slider
local numToastsSlider = CreateFrame("Slider", "SexyLootNumToastsSlider", tabContent[3], "OptionsSliderTemplate");
numToastsSlider:SetPoint("TOPLEFT", 30, displayY);
numToastsSlider:SetMinMaxValues(1, 8);
numToastsSlider:SetValueStep(1);
numToastsSlider:SetWidth(200);
_G[numToastsSlider:GetName().."Text"]:SetText("Maximum Toasts");
_G[numToastsSlider:GetName().."Low"]:SetText("1");
_G[numToastsSlider:GetName().."High"]:SetText("8");
numToastsSlider:SetScript("OnValueChanged", function(self, value)
	SexyLootDB.config = SexyLootDB.config or {};
	SexyLootDB.config.numbuttons = value;
	_G[self:GetName().."Text"]:SetText(string.format("Maximum Toasts: %d", value));
end);

displayY = displayY - 60;

-- Toast spacing slider
local paddingSlider = CreateFrame("Slider", "SexyLootPaddingSlider", tabContent[3], "OptionsSliderTemplate");
paddingSlider:SetPoint("TOPLEFT", 30, displayY);
paddingSlider:SetMinMaxValues(0, 20);
paddingSlider:SetValueStep(1);
paddingSlider:SetWidth(200);
_G[paddingSlider:GetName().."Text"]:SetText("Toast Spacing");
_G[paddingSlider:GetName().."Low"]:SetText("0");
_G[paddingSlider:GetName().."High"]:SetText("20");
paddingSlider:SetScript("OnValueChanged", function(self, value)
	SexyLootDB.config = SexyLootDB.config or {};
	SexyLootDB.config.offset_x = value;
	_G[self:GetName().."Text"]:SetText(string.format("Toast Spacing: %d pixels", value));
end);

displayY = displayY - 60;

-- Update speed slider
local durationSlider = CreateFrame("Slider", "SexyLootDurationSlider", tabContent[3], "OptionsSliderTemplate");
durationSlider:SetPoint("TOPLEFT", 30, displayY);
durationSlider:SetMinMaxValues(0.1, 2.0);
durationSlider:SetValueStep(0.1);
durationSlider:SetWidth(200);
_G[durationSlider:GetName().."Text"]:SetText("Update Speed");
_G[durationSlider:GetName().."Low"]:SetText("0.1s");
_G[durationSlider:GetName().."High"]:SetText("2.0s");
durationSlider:SetScript("OnValueChanged", function(self, value)
	SexyLootDB.config = SexyLootDB.config or {};
	SexyLootDB.config.time = value;
	_G[self:GetName().."Text"]:SetText(string.format("Update Speed: %.1f seconds", value));
end);

displayY = displayY - 60;

-- Growth Direction
local growthLabel = tabContent[3]:CreateFontString(nil, "ARTWORK", "GameFontNormal");
growthLabel:SetPoint("TOPLEFT", 30, displayY);
growthLabel:SetText("Growth Direction:");

local growthDropdown = CreateFrame("Frame", "SexyLootGrowthDropdown", tabContent[3], "UIDropDownMenuTemplate");
growthDropdown:SetPoint("LEFT", growthLabel, "RIGHT", 0, -2);
UIDropDownMenu_SetWidth(growthDropdown, 100);

UIDropDownMenu_Initialize(growthDropdown, function(self)
	local options = {
		{text = "Up", value = "UP"},
		{text = "Down", value = "DOWN"},
	};
	for _, option in ipairs(options) do
		local info = UIDropDownMenu_CreateInfo();
		info.text = option.text;
		info.value = option.value;
		info.func = function()
			SexyLootDB.config = SexyLootDB.config or {};
			SexyLootDB.config.growthDirection = option.value;
			UIDropDownMenu_SetText(growthDropdown, option.text);
			if LootAlertFrameMixIn then
				LootAlertFrameMixIn:AdjustAnchors();
			end
		end
		UIDropDownMenu_AddButton(info);
	end
end);

displayY = displayY - 40;

-- Frame Strata
local strataLabel = tabContent[3]:CreateFontString(nil, "ARTWORK", "GameFontNormal");
strataLabel:SetPoint("TOPLEFT", 30, displayY);
strataLabel:SetText("Frame Strata:");

local strataDropdown = CreateFrame("Frame", "SexyLootStrataDropdown", tabContent[3], "UIDropDownMenuTemplate");
strataDropdown:SetPoint("LEFT", strataLabel, "RIGHT", 0, -2);
UIDropDownMenu_SetWidth(strataDropdown, 120);

UIDropDownMenu_Initialize(strataDropdown, function(self)
	local options = {
		{text = "Low", value = "LOW"},
		{text = "Medium", value = "MEDIUM"},
		{text = "High", value = "HIGH"},
		{text = "Dialog", value = "DIALOG"},
		{text = "Fullscreen", value = "FULLSCREEN_DIALOG"},
	};
	for _, option in ipairs(options) do
		local info = UIDropDownMenu_CreateInfo();
		info.text = option.text;
		info.value = option.value;
		info.func = function()
			SexyLootDB.config = SexyLootDB.config or {};
			SexyLootDB.config.frameStrata = option.value;
			UIDropDownMenu_SetText(strataDropdown, option.text);
			for i = 1, 8 do
				local button = _G["LootAlertButton"..i];
				if button then
					button:SetFrameStrata(option.value);
				end
			end
		end
		UIDropDownMenu_AddButton(info);
	end
end);

-- Tab 4: Filter Settings
tabContent[4] = CreateFrame("Frame", nil, tabContainer);
tabContent[4]:SetAllPoints();
tabContent[4]:Hide();

local filterY = -20;

local qualityHeader = tabContent[4]:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
qualityHeader:SetPoint("TOPLEFT", 20, filterY);
qualityHeader:SetText("Quality Filters");
filterY = filterY - 30;

local ignoreQualityCheck = CreateFrame("CheckButton", "SexyLootIgnoreQualityCheck", tabContent[4], "UICheckButtonTemplate");
ignoreQualityCheck:SetPoint("TOPLEFT", 20, filterY);
_G[ignoreQualityCheck:GetName().."Text"]:SetText("Show all item qualities (ignore quality filter below)");
ignoreQualityCheck:SetScript("OnClick", function(self)
	SexyLootDB.config = SexyLootDB.config or {};
	SexyLootDB.config.ignore_level = self:GetChecked();
end);

filterY = filterY - 40;

local qualityNames = {"Poor (Grey)", "Common (White)", "Uncommon (Green)", "Rare (Blue)", "Epic (Purple)", "Legendary (Orange)"};

-- Single quality slider for all levels
local minQualitySlider = CreateFrame("Slider", "SexyLootMinQualitySlider", tabContent[4], "OptionsSliderTemplate");
minQualitySlider:SetPoint("TOPLEFT", 30, filterY);
minQualitySlider:SetMinMaxValues(0, 5);
minQualitySlider:SetValueStep(1);
minQualitySlider:SetWidth(400);
_G[minQualitySlider:GetName().."Text"]:SetText("Minimum Quality to Show");
_G[minQualitySlider:GetName().."Low"]:SetText("Poor");
_G[minQualitySlider:GetName().."High"]:SetText("Legendary");
minQualitySlider:SetScript("OnValueChanged", function(self, value)
	-- Don't do anything if this is being called during initialization
	if not self.initialized then
		return;
	end
	
	SexyLootDB.config = SexyLootDB.config or {};
	SexyLootDB.config.min_quality = value;
	_G[self:GetName().."Text"]:SetText(string.format("Minimum Quality: %s and above", qualityNames[value + 1]));
end);

filterY = filterY - 60;

local filterNote = tabContent[4]:CreateFontString(nil, "ARTWORK", "GameFontNormal");
filterNote:SetPoint("TOPLEFT", 30, filterY);
filterNote:SetText("|cffaaaaaaOnly items of this quality or better will trigger notifications.|r");
filterNote:SetJustifyH("LEFT");

-- Initialize on show
optionsFrame:SetScript("OnShow", function(self)
	-- Set first tab as active without using PanelTemplates
	for i = 1, #tabs do
		if i == 1 then
			tabs[i]:SetDisabledFontObject(GameFontHighlightSmall);
			tabContent[i]:Show();
		else
			tabs[i]:SetDisabledFontObject(GameFontDisableSmall);
			tabContent[i]:Hide();
		end
	end
	
	-- Load saved settings
	if SexyLootDB then
		lockCheck:SetChecked(SexyLootDB.locked ~= false);
		
		if SexyLootDB.config then
			-- General
			soundCheck:SetChecked(SexyLootDB.config.sound ~= false);
			coinSoundCheck:SetChecked(SexyLootDB.config.coinSound);
			animCheck:SetChecked(SexyLootDB.config.anims ~= false);
			
			-- Tracking
			for _, option in ipairs(trackingOptions) do
				local check = _G["SexyLoot"..option.var.."Check"];
				if check then
					check:SetChecked(SexyLootDB.config[option.var] ~= false);
				end
			end
			
			-- Display - mark sliders as not initialized to prevent function calls during SetValue
			scaleSlider.initialized = false;
			numToastsSlider.initialized = false;
			paddingSlider.initialized = false;
			durationSlider.initialized = false;
			
			scaleSlider:SetValue(SexyLootDB.config.scale or 0.75);
			numToastsSlider:SetValue(SexyLootDB.config.numbuttons or 8);
			paddingSlider:SetValue(SexyLootDB.config.offset_x or 2);
			durationSlider:SetValue(SexyLootDB.config.time or 0.3);
			
			-- Now mark them as initialized so future changes will work
			scaleSlider.initialized = true;
			numToastsSlider.initialized = true;
			paddingSlider.initialized = true;
			durationSlider.initialized = true;
			
			local growth = SexyLootDB.config.growthDirection or "UP";
			UIDropDownMenu_SetText(growthDropdown, growth == "DOWN" and "Down" or "Up");
			
			local strata = SexyLootDB.config.frameStrata or "MEDIUM";
			local strataText = "Medium";
			if strata == "LOW" then strataText = "Low"
			elseif strata == "HIGH" then strataText = "High"
			elseif strata == "DIALOG" then strataText = "Dialog"
			elseif strata == "FULLSCREEN_DIALOG" then strataText = "Fullscreen"
			end
			UIDropDownMenu_SetText(strataDropdown, strataText);
			
			-- Filters
			ignoreQualityCheck:SetChecked(SexyLootDB.config.ignore_level);
			minQualitySlider.initialized = false;
			minQualitySlider:SetValue(SexyLootDB.config.min_quality or 1);
			minQualitySlider.initialized = true;
		end
	end
end);

-- Test functions
function SexyLoot_ShowTestAlerts()
	if not LootAlertFrameMixIn then
		print("|cffff69b4SexyLoot:|r Error - Core not loaded. Please reload UI.");
		return;
	end
	
	local testData = {
		{
			name = "Thunderfury, Blessed Blade",
			quality = 5,
			texture = "Interface\\Icons\\INV_Sword_39",
			label = LEGENDARY_ITEM_LOOT_LABEL,
			toast = "legendarytoast"
		},
		{
			name = "50 Gold",
			quality = 6,
			label = "You received:",
			toast = "moneytoast",
			money = 500000
		},
		{
			name = "Epic Sword",
			quality = 4,
			texture = "Interface\\Icons\\INV_Sword_01",
			label = YOU_RECEIVED_LABEL,
			toast = "heroictoast"
		}
	};
	
	for i, data in ipairs(testData) do
		data.link = "|cff9d9d9d|Hitem:7073:::::::::|h[Test]|h|r";
		LootAlertFrameMixIn:AddAlert(data.name, data.link, data.quality, data.texture, nil, true, data.label, data.toast, nil, nil, nil, data.money);
	end
end

function SexyLoot_TestLegendary()
	if not LootAlertFrameMixIn then return; end
	local data = {
		name = "Thunderfury, Blessed Blade",
		quality = 5,
		texture = "Interface\\Icons\\INV_Sword_39",
		label = LEGENDARY_ITEM_LOOT_LABEL,
		toast = "legendarytoast",
		link = "|cffff8000|Hitem:19019:::::::::|h[Thunderfury]|h|r"
	};
	LootAlertFrameMixIn:AddAlert(data.name, data.link, data.quality, data.texture, nil, true, data.label, data.toast);
end

function SexyLoot_TestEpic()
	if not LootAlertFrameMixIn then return; end
	local data = {
		name = "Shadowmourne",
		quality = 4,
		texture = "Interface\\Icons\\INV_Axe_113",
		label = YOU_RECEIVED_LABEL,
		toast = "heroictoast",
		link = "|cffa335ee|Hitem:49623:::::::::|h[Shadowmourne]|h|r"
	};
	LootAlertFrameMixIn:AddAlert(data.name, data.link, data.quality, data.texture, nil, true, data.label, data.toast);
end

function SexyLoot_TestMoneyGain()
	if not LootAlertFrameMixIn then return; end
	local data = {
		name = "15 Gold 32 Silver",
		quality = 6,
		label = "You received:",
		toast = "moneytoast",
		money = 153200,
		link = false
	};
	LootAlertFrameMixIn:AddAlert(data.name, data.link, data.quality, false, nil, true, data.label, data.toast, nil, nil, nil, data.money);
end

function SexyLoot_TestMoneyLoss()
	if not LootAlertFrameMixIn then return; end
	local data = {
		name = "5 Gold 50 Silver",
		quality = 0,
		label = "You spent:",
		toast = "moneytoast",
		money = 55000,
		link = false,
		isLoss = true
	};
	LootAlertFrameMixIn:AddAlert(data.name, data.link, data.quality, false, nil, true, data.label, data.toast, nil, nil, nil, data.money, nil, true);
end

function SexyLoot_TestRecipe()
	if not LootAlertFrameMixIn then return; end
	local data = {
		name = "Flask of the Titans",
		quality = 3,
		texture = "Interface\\AddOns\\SexyLoot\\assets\\UI-TradeSkill-Circle",
		label = NEW_RECIPE_LEARNED_TITLE,
		toast = "recipetoast",
		link = "|cff1eff00|Hitem:13510:::::::::|h[Flask Recipe]|h|r",
		subType = TOAST_PROFESSION_ALCHEMY
	};
	LootAlertFrameMixIn:AddAlert(data.name, data.link, data.quality, data.texture, nil, true, data.label, data.toast, nil, nil, nil, nil, data.subType);
end

function SexyLoot_TestCommon()
	if not LootAlertFrameMixIn then return; end
	local data = {
		name = "Linen Cloth",
		quality = 1,
		texture = "Interface\\Icons\\INV_Fabric_Linen_01",
		label = YOU_RECEIVED_LABEL,
		toast = "commontoast",
		link = "|cffffffff|Hitem:2589:::::::::|h[Linen Cloth]|h|r",
		count = 5
	};
	LootAlertFrameMixIn:AddAlert(data.name, data.link, data.quality, data.texture, data.count, true, data.label, data.toast);
end

-- Slash commands
SLASH_SEXYLOOT1 = "/sexyloot";
SLASH_SEXYLOOT2 = "/sl";
SlashCmdList["SEXYLOOT"] = function(msg)
	msg = msg:lower();
	if msg == "lock" then
		SexyLootDB.locked = true;
		print("|cffff69b4SexyLoot:|r Frames locked");
		if SexyLoot_UpdatePreviewFrame then
			SexyLoot_UpdatePreviewFrame();
		else
			print("SexyLoot Debug: SexyLoot_UpdatePreviewFrame function not found!");
		end
	elseif msg == "unlock" then
		SexyLootDB.locked = false;
		print("|cffff69b4SexyLoot:|r Frames unlocked - drag to reposition");
		if SexyLoot_UpdatePreviewFrame then
			SexyLoot_UpdatePreviewFrame();
		else
			print("SexyLoot Debug: SexyLoot_UpdatePreviewFrame function not found!");
		end
	elseif msg == "test" then
		SexyLoot_ShowTestAlerts();
	elseif msg == "preview" then
		if SexyLoot_UpdatePreviewFrame then
			print("SexyLoot Debug: Calling preview function manually");
			SexyLoot_UpdatePreviewFrame();
		else
			print("SexyLoot Debug: SexyLoot_UpdatePreviewFrame function not found!");
		end
	elseif msg == "reset" then
		SexyLootDB.positions = nil;
		SexyLootDB.anchorPoint = nil;
		SexyLootDB.anchorX = nil;
		SexyLootDB.anchorY = nil;
		print("|cffff69b4SexyLoot:|r Positions reset to default");
		if SexyLoot_UpdatePreviewFrame then
			SexyLoot_UpdatePreviewFrame();
		end
	elseif msg == "config" or msg == "options" or msg == "" then
		if optionsFrame:IsShown() then
			optionsFrame:Hide();
		else
			optionsFrame:Show();
		end
	else
		print("|cffff69b4SexyLoot|r commands:");
		print("  /sl - Open configuration");
		print("  /sl lock - Lock frames");
		print("  /sl unlock - Unlock frames for dragging");
		print("  /sl test - Show test alerts");
		print("  /sl reset - Reset positions to default");
		print("  /sl preview - Force update preview frame");
	end
end;