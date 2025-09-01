---
-- SexyLoot Core - Enhanced loot notifications
-- Tracks: looting, trades, mail, gold gains/losses

local select = select;
local unpack = unpack;
local next = next;
local pairs = pairs;
local ipairs = ipairs;
local tonumber = tonumber;
local tostring = tostring;
local format = string.format;
local match = string.match;
local gsub = string.gsub;
local sub = string.sub;
local tRemove = table.remove;
local tInsert = table.insert;
local tWipe = table.wipe;

local private = select(2,...);
local config = private.config;
local mixin = private.Mixin;

-- /* config */
local scale = config.scale;
local offset_x = config.offset_x;
local point_x = config.point_x;
local point_y = config.point_y;
local ignlevel = config.ignore_level;
local uptime = config.time;
local looting = config.looting;
local creating = config.creating;
local rolling =	config.rolling;
local currency_loot = config.money;
local recipes_learned = config.recipes;
local honor_award = config.honor;
local quality_low = config.low_level;
local quality_max = config.max_level;

local LOOTALERT_NUM_BUTTONS = config.numbuttons;

-- /* api's */
local UnitName = UnitName;
local UnitLevel = UnitLevel;
local UnitFactionGroup = UnitFactionGroup;
local PlaySoundFile = PlaySoundFile;
local PlaySound = PlaySound;
local GetSpellInfo = GetSpellInfo;
local GetItemInfo = GetItemInfo;
local GetUnitName = GetUnitName;
local GetBattlefieldScore = GetBattlefieldScore;
local GetNumBattlefieldScores = GetNumBattlefieldScores;
local GetBattlefieldWinner = GetBattlefieldWinner;
local GetMoneyString = GetMoneyString;
local GetMoney = GetMoney;
local GameTooltip = GameTooltip;
local playerFaction = UnitFactionGroup("player");
local playerWinner = PLAYER_FACTION_GROUP[playerFaction];
local playerName = UnitName("player");
local GetAmountBattlefieldBonus = private.GetAmountBattlefieldBonus;

-- /* assets */
local assets = [[Interface\AddOns\SexyLoot\assets\]];
local picn = assets.."UI-TradeSkill-Circle";
local SOUNDKIT = {
	UI_EPICLOOT_TOAST = assets.."ui_epicloot_toast_01.ogg",
	UI_GARRISON_FOLLOWER_LEARN_TRAIT = assets.."ui_garrison_follower_trait_learned_02.ogg",
	UI_LEGENDARY_LOOT_TOAST = assets.."ui_legendary_item_toast.ogg",
	UI_RAID_LOOT_TOAST_LESSER_ITEM_WON = assets.."ui_loot_toast_lesser_item_won_01.ogg",
	COIN_SOUND = assets.."coinsound.ogg", -- Your custom coin sound file
};

-- /* consts */
local LE_ITEM_QUALITY_COMMON = 1;
local LE_ITEM_QUALITY_EPIC = 4;
local LE_ITEM_QUALITY_HEIRLOOM = 7;
local LE_ITEM_QUALITY_LEGENDARY = 5;
local LE_ITEM_QUALITY_POOR = 0;
local LE_ITEM_QUALITY_RARE = 3;
local LE_ITEM_QUALITY_UNCOMMON = 2;
local LE_ITEM_QUALITY_WOW_TOKEN = 8;
local LE_ITEM_QUALITY_ARTIFACT = 6;

local LOOT_ROLL_TYPE_NEED = 1;
local LOOT_ROLL_TYPE_GREED = 2;
local LOOT_ROLL_TYPE_DISENCHANT = 3;

local LOOT_BORDER_BY_QUALITY = {
	[LE_ITEM_QUALITY_UNCOMMON] = {0.34082, 0.397461, 0.53125, 0.644531},
	[LE_ITEM_QUALITY_RARE] = {0.272461, 0.329102, 0.785156, 0.898438},
	[LE_ITEM_QUALITY_EPIC] = {0.34082, 0.397461, 0.882812, 0.996094},
	[LE_ITEM_QUALITY_LEGENDARY] = {0.34082, 0.397461, 0.765625, 0.878906},
	[LE_ITEM_QUALITY_HEIRLOOM] = {0.34082, 0.397461, 0.648438, 0.761719},
	[LE_ITEM_QUALITY_ARTIFACT] = {0.272461, 0.329102, 0.667969, 0.78125},
};
local HONOR_BACKGROUND_TCOORDS = {
	["Alliance"] = {277, 113, 0.001953, 0.542969, 0.460938, 0.902344},
	["Horde"] = {281, 115, 0.001953, 0.550781, 0.003906, 0.453125},
};
local SUB_COORDS = HONOR_BACKGROUND_TCOORDS[playerFaction];
local HONOR_BADGE = {SUB_COORDS[3], SUB_COORDS[4], SUB_COORDS[5], SUB_COORDS[6]};

local PROFESSION_ICON_TCOORDS = {
	[TOAST_PROFESSION_ENCHANTING]		= {0, 0.25, 0, 0.25},
	[TOAST_PROFESSION_ALCHEMY]		= {0.25, 0.49609375, 0, 0.25},
	[TOAST_PROFESSION_BLACKSMITHING]		= {0.49609375, 0.7421875, 0, 0.25},
	[TOAST_PROFESSION_COOKING]		= {0.7421875, 0.98828125, 0, 0.25},
	[TOAST_PROFESSION_ENGINEERING]		= {0, 0.25, 0.25, 0.5},
	[TOAST_PROFESSION_FIRST_AID]	 	= {0.25, 0.49609375, 0.25, 0.5},
	[TOAST_PROFESSION_FISHING]		= {0.49609375, 0.7421875, 0.25, 0.5},
	[TOAST_PROFESSION_TAILORING]		= {0.7421875, 0.98828125, 0.25, 0.5},
	[TOAST_PROFESSION_INSCRIPTION]		= {0, 0.25, 0.5, 0.75},
	[TOAST_PROFESSION_JEWELCRAFTING]	= {0.25, .5, 0.5, .75},
	[TOAST_PROFESSION_LEATHERWORKING]		= {0.5, 0.73828125, 0.5, .75},
};

-- /* patterns */
local P_LOOT_ITEM = LOOT_ITEM:gsub("%%s%%s", "(.+)");
local P_LOOT_COUNT = ".*x(%d+)";
local P_LOOT_ITEM_CREATED_SELF = LOOT_ITEM_CREATED_SELF:gsub("%%s", "(.+)"):gsub("^", "^");
local P_LOOT_ITEM_SELF = LOOT_ITEM_SELF:gsub("%%s", "(.+)"):gsub("^", "^");
local P_LOOT_ITEM_SELF_MULTIPLE = LOOT_ITEM_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)"):gsub("^", "^");
local P_LOOT_ROLL_YOU_WON = LOOT_ROLL_YOU_WON:gsub("%%s", "(.+)");
local PATTERN_LEARN = ERR_LEARN_RECIPE_S:gsub("%%s", "(.+)");
local PATTERN_LOOT_MONEY = YOU_LOOT_MONEY:gsub("%%s", "(.*)");
local GOLD = GOLD_AMOUNT:gsub("%%d", "(%%d+)");
local SILVER = SILVER_AMOUNT:gsub("%%d", "(%%d+)");
local COPPER = COPPER_AMOUNT:gsub("%%d", "(%%d+)");

-- Money tracking
local previousMoney = 0;
local moneyUpdateTimer = 0;
local MONEY_UPDATE_DELAY = 0.5;

-- Trade tracking
local tradeItems = {};
local tradeMoney = 0;

-- Mail tracking  
local mailItems = {};

local expectations_list = {};
local patterns = {
	won = {
		[LOOT_ROLL_TYPE_NEED] = LOOT_ROLL_YOU_WON_NO_SPAM_NEED,
		[LOOT_ROLL_TYPE_GREED] = LOOT_ROLL_YOU_WON_NO_SPAM_GREED,
		[LOOT_ROLL_TYPE_DISENCHANT] = LOOT_ROLL_YOU_WON_NO_SPAM_DE,
	},
	rolled = {
		[LOOT_ROLL_TYPE_NEED] = LOOT_ROLL_ROLLED_NEED,
		[LOOT_ROLL_TYPE_GREED] = LOOT_ROLL_ROLLED_GREED,
		[LOOT_ROLL_TYPE_DISENCHANT] = LOOT_ROLL_ROLLED_DE,
	},
};

local prefix_table = {
	[TOAST_PROFESSION_ALCHEMY] = {ITEM_TYPE_RECIPE},
	[TOAST_PROFESSION_BLACKSMITHING] = {ITEM_TYPE_PLANS},
	[TOAST_PROFESSION_ENCHANTING] = {ITEM_TYPE_FORMULA},
	[TOAST_PROFESSION_ENGINEERING] = {ITEM_TYPE_SCHEMATIC},
	[TOAST_PROFESSION_INSCRIPTION] = {ITEM_TYPE_TECHNIQUE},
	[TOAST_PROFESSION_JEWELCRAFTING] = {ITEM_TYPE_DESIGN},
	[TOAST_PROFESSION_LEATHERWORKING] = {ITEM_TYPE_PATTERN},
	[TOAST_PROFESSION_TAILORING] = {ITEM_TYPE_PATTERN},
	[TOAST_PROFESSION_COOKING] = {ITEM_TYPE_RECIPE},
	[TOAST_PROFESSION_FIRST_AID] = {ITEM_TYPE_MANUAL},
};

-- /* tables */
LootAlertFrameMixIn = {};  -- Make it global so options.lua can access it
LootAlertFrameMixIn.alertQueue = {};
LootAlertFrameMixIn.alertButton = {};

function LootAlertFrameMixIn:AddAlert(name, link, quality, texture, count, ignore, label, toast, rollType, rollLink, tip, money, subType, isLoss)
	-- Load saved config and apply quality filter
	if SexyLootDB and SexyLootDB.config then
		ignlevel = SexyLootDB.config.ignore_level or ignlevel;
		
		-- Use single quality threshold for all levels
		local minQuality = SexyLootDB.config.min_quality or 1;
		
		if not ignore and not ignlevel then
			if quality < minQuality then
				return;
			end
		end
	end

	tInsert(self.alertQueue,{
		name 		= name,
		link 		= link,
		quality 	= quality,
		texture 	= texture,
		count 		= count,
		label 		= label,
		toast 		= toast,
		rollType 	= rollType,
		rollLink 	= rollLink,
		tip 		= tip,
		money		= money,
		subType 	= subType,
		isLoss      = isLoss
	});
end

function LootAlertFrameMixIn:CreateAlert()
	if #self.alertQueue > 0 then
		-- Get current max buttons setting
		local maxButtons = LOOTALERT_NUM_BUTTONS;
		if SexyLootDB and SexyLootDB.config and SexyLootDB.config.numbuttons then
			maxButtons = math.min(SexyLootDB.config.numbuttons, LOOTALERT_NUM_BUTTONS);
		end
		
		for i=1, maxButtons do
			local button = self.alertButton[i];
			if button and not button:IsShown() then
				local data = tRemove(self.alertQueue, 1);
				button.data = data;
				return button;
			end
		end
	end
	return nil;
end

function LootAlertFrameMixIn:AdjustAnchors()
	local previousButton;
	for i=1, LOOTALERT_NUM_BUTTONS do
		local button = self.alertButton[i];
		if button then
			button:ClearAllPoints();
			if button:IsShown() then
				if button.waitAndAnimOut:GetProgress() <= 0.74 then
					if not previousButton or previousButton == button then
						-- First toast uses saved position or default
						if SexyLootDB and SexyLootDB.anchorPoint then
							-- Use saved position whether locked or not
							button:SetPoint(SexyLootDB.anchorPoint, UIParent, SexyLootDB.anchorPoint, 
								SexyLootDB.anchorX or point_x, 
								SexyLootDB.anchorY or point_y);
						else
							-- Default positioning
							button:SetPoint("CENTER", UIParent, "CENTER", point_x, point_y);
						end
					else
						-- Stack subsequent toasts based on growth direction
						local spacing = (SexyLootDB and SexyLootDB.config and SexyLootDB.config.offset_x) or offset_x;
						local growthDirection = (SexyLootDB and SexyLootDB.config and SexyLootDB.config.growthDirection) or "UP";
						
						if growthDirection == "DOWN" then
							button:SetPoint("TOP", previousButton, "BOTTOM", 0, -spacing);
						else
							button:SetPoint("BOTTOM", previousButton, "TOP", 0, spacing);
						end
					end
					previousButton = button;
				end
			end
		end
	end
end

function LootAlertFrame_OnLoad(self)
	-- Load config from saved variables
	if SexyLootDB and SexyLootDB.config then
		uptime = SexyLootDB.config.time or uptime;
		private.config.time = uptime;
	end
	
	self.updateTime = uptime;
	self.moneyUpdateTimer = 0;
	self.atMailbox = false;
	self.previousBags = {};
	
	-- Initialize saved variables
	SexyLootDB = SexyLootDB or {};
	if SexyLootDB.locked == nil then
		SexyLootDB.locked = true;
	end
	
	-- Set frame strata
	self:SetFrameStrata("MEDIUM");
	
	-- Store initial money
	previousMoney = GetMoney();
	
	-- Initialize bag state
	for bag = 0, 4 do
		self.previousBags[bag] = {};
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot);
			if link then
				self.previousBags[bag][slot] = link;
			end
		end
	end
	
	self:RegisterEvent("CHAT_MSG_LOOT");
	self:RegisterEvent("CHAT_MSG_SYSTEM");
	self:RegisterEvent("CHAT_MSG_MONEY");
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS");
	self:RegisterEvent("PLAYER_MONEY");
	self:RegisterEvent("TRADE_ACCEPT_UPDATE");
	self:RegisterEvent("TRADE_CLOSED");
	self:RegisterEvent("TRADE_MONEY_CHANGED");
	self:RegisterEvent("MAIL_INBOX_UPDATE");
	self:RegisterEvent("MAIL_CLOSED");
	self:RegisterEvent("BAG_UPDATE");
	self:RegisterEvent("PLAYER_LOGIN");

	mixin(self, LootAlertFrameMixIn);
end

local function LootAlertFrame_HandleChatMessage(message)
	local link, quantity, rollType, roll;

	if expectations_list.disenchant_result then
		link, quantity = message:cmatch(LOOT_ITEM_SELF_MULTIPLE);
		if not link then
			link = message:cmatch(LOOT_ITEM_SELF);
		end
		if link and expectations_list[link] then
			rollType = LOOT_ROLL_TYPE_DISENCHANT;
			quantity = tonumber(quantity) or 1;
			expectations_list[link] = nil;
			expectations_list.disenchant_result = false;
			return link, quantity, rollType;
		end
	end

	link = message:cmatch(LOOT_ROLL_YOU_WON)
	if link and expectations_list[link] then
		rollType, roll = expectations_list[link][1], expectations_list[link][2];
		if rollType == LOOT_ROLL_TYPE_DISENCHANT then
			expectations_list.disenchant_result = true;
			return;
		else
			expectations_list[link] = nil;
			return link, 1, rollType, roll;
		end
	end

	for rollType, pattern in pairs(patterns.rolled) do
		local roll, link, player = message:cmatch(pattern);
		if roll and player == playerName then
			expectations_list[link] = {rollType, roll};
			return;
		end
	end

	for rollType, pattern in pairs(patterns.won) do
		local roll, link = message:cmatch(pattern);
		if roll then
			return link, 1, rollType, roll;
		end
	end
  
	return link, quantity, rollType, roll;
end

function LootAlertFrame_OnEvent(self, event, ...)
	local shouldTrack = SexyLootDB and SexyLootDB.config;
	
	if event == "PLAYER_LOGIN" then
		previousMoney = GetMoney();
		return;
	end
	
	if event == "CHAT_MSG_LOOT" then
		-- Check if looting is enabled
		if SexyLootDB and SexyLootDB.config and SexyLootDB.config.looting == false then return; end
		
		local player, label, toast;
		local itemName					  = arg1:match(P_LOOT_ITEM);
		local itemLoot					  = arg1:match(P_LOOT_ITEM_SELF);
		local itemMultiple				  = arg1:match(P_LOOT_ITEM_SELF_MULTIPLE);
		local itemCreate				  = arg1:match(P_LOOT_ITEM_CREATED_SELF);
		local count						  = arg1:match(P_LOOT_COUNT);
		local itemRoll, _, rollType, roll = LootAlertFrame_HandleChatMessage(arg1);
		
		-- Check specific tracking settings
		if itemCreate and (SexyLootDB and SexyLootDB.config and SexyLootDB.config.creating == false) then
			return;
		end
		if itemRoll and (SexyLootDB and SexyLootDB.config and SexyLootDB.config.rolling == false) then
			return;
		end
		
		if not itemName and not player then
			if itemCreate then
				itemName 	= itemCreate;
				label 		= YOU_CREATED_LABEL;
			elseif itemLoot or itemMultiple then
				itemName 	= itemLoot or itemMultiple;
				label 		= YOU_RECEIVED_LABEL;
			elseif itemRoll then
				itemName 	= itemRoll;
				label 		= YOU_WON_LABEL;
			end
			player = GetUnitName("player");
		end

		if itemName then
			local name, link, quality, iLevel, _, itemType, subType, _, _, texture = GetItemInfo(itemName);
			local legendary	  = quality == LE_ITEM_QUALITY_LEGENDARY;
			local average	  = quality >= LE_ITEM_QUALITY_UNCOMMON and not legendary;
			local common	  = quality <= LE_ITEM_QUALITY_COMMON;
			local heroic	  = iLevel >= 271 and not legendary;
			local pets		  = subType == PET or subType == PETS;
			local mounts	  = subType == ITEM_TYPE_MOUNT or subType == ITEM_TYPE_MOUNTS;
			
			if average then toast = "defaulttoast"; end
			if common then toast = "commontoast"; end
			if heroic then toast = "heroictoast"; end
			
			if legendary then
				label = LEGENDARY_ITEM_LOOT_LABEL;
				toast = "legendarytoast";
			end
			if pets then
				toast = "pettoast";
			elseif mounts then
				toast = "mounttoast";
			end
			
			if config.filter then
				for _, ignored in ipairs(config.filter_type) do
					if tostring(itemType) == tostring(ignored) then
						return;
					end
				end
			end
			
			if link then
				LootAlertFrameMixIn:AddAlert(name, link, quality, texture, count, ignlevel, label, toast, rollType, roll);
			end
		end
	end
	
	-- Money tracking
	if event == "CHAT_MSG_MONEY" then
		if SexyLootDB and SexyLootDB.config and SexyLootDB.config.money == false then return; end
		
		local currency = arg1:match(PATTERN_LOOT_MONEY);
		local gold     = arg1:match(GOLD);
		local silver   = arg1:match(SILVER);
		local copper   = arg1:match(COPPER);
		
		gold   = (gold and tonumber(gold)) or 0;
		silver = (silver and tonumber(silver)) or 0;
		copper = (copper and tonumber(copper)) or 0;
		
		local money = copper + silver * 100 + gold * 10000;
		local amount = GetMoneyString(money, true);
		if currency then
			if playerName then
				local label		= YOU_RECEIVED_LABEL;
				local quality 	= LE_ITEM_QUALITY_ARTIFACT;
				local toast 	= "moneytoast";
				
				LootAlertFrameMixIn:AddAlert(amount, false, quality, false, false, true, label, toast, false, false, false, money);
			end
		end
	end
	
	-- Track money losses
	if event == "PLAYER_MONEY" then
		if shouldTrack and SexyLootDB.config.money == false then return; end
		
		self.moneyUpdateTimer = MONEY_UPDATE_DELAY;
	end
	
	-- Recipe learning
	if event == "CHAT_MSG_SYSTEM" then
		if SexyLootDB and SexyLootDB.config and SexyLootDB.config.recipes == false then return; end
		
		local skill = arg1:match(PATTERN_LEARN);
		if skill then
			for prof, prefixes in next, prefix_table do
				if GetSpellInfo(prof) then
					for key, prefix in next, prefixes do
						local recipe = prefix .. skill or skill;
						local label = NEW_RECIPE_LEARNED_TITLE;
						local toast = "recipetoast";
						local tip = ERR_LEARN_RECIPE_S:gsub("%%s", skill);
						local _, link, quality = GetItemInfo(recipe);
						if link then
							LootAlertFrameMixIn:AddAlert(skill, link, quality, picn, false, true, label, toast, false, false, tip, false, prof);
						end
					end
				end
			end
		end
	end

	-- Honor/battlefield rewards
	if event == "UPDATE_BATTLEFIELD_STATUS" and honor_award then
		if (not GetBattlefieldWinner() or BATTLEFIELD_SHUTDOWN_TIMER <= 0 or IsActiveBattlefieldArena()) then return; end
		local link, entry, count, texture, quality, label, toast, tip;
		local honorIcon = assets.."PVPCurrency-Honor-"..playerFaction;
		local bonusIcon = assets.."achievement_legionpvptier4";
		local numScores = GetNumBattlefieldScores();
		local hasWon, winHonorAmount, winArenaAmount = GetAmountBattlefieldBonus();
		
		RequestBattlefieldScoreData();
		for i=1, numScores do
			local name, _, _, _, honorGained = GetBattlefieldScore(i);
			if name and name == playerName then
				link 	 	= "item:43308";
				entry 	  	= HONOR_POINTS;
				count	 	= honorGained;
				texture   	= honorIcon;
				quality   	= LE_ITEM_QUALITY_ARTIFACT;
				label 	  	= YOU_EARNED_LABEL;
				toast 		= "battlefieldtoast";
				tip 	  	= TOOLTIP_HONOR_POINTS;
				break;
			end
		end
		
		if link then
			LootAlertFrameMixIn:AddAlert(entry, link, quality, texture, count, true, label, toast, false, false, tip);
		end
		if not hasWon and GetBattlefieldWinner() == playerWinner then
			link	  	= "item:43307";
			entry	  	= ARENA_POINTS;
			count	  	= winArenaAmount;
			texture	  	= bonusIcon;
			tip 	  	= TOOLTIP_ARENA_POINTS;
			
			LootAlertFrameMixIn:AddAlert(entry, link, quality, texture, count, true, label, toast, false, false, tip);
		end
	end
	
	-- Trade tracking
	if event == "TRADE_ACCEPT_UPDATE" then
		if not shouldTrack or not SexyLootDB.config.trades then return; end
		
		if arg1 == 1 and arg2 == 1 then -- Both players accepted
			-- Track items received
			for i = 1, 6 do
				local name, texture, quantity = GetTradeTargetItemInfo(i);
				if name then
					local _, link, quality = GetItemInfo(GetTradeTargetItemLink(i));
					if link then
						local label = "Trade Received:";
						local toast = quality >= LE_ITEM_QUALITY_EPIC and "heroictoast" or "defaulttoast";
						LootAlertFrameMixIn:AddAlert(name, link, quality, texture, quantity, false, label, toast);
					end
				end
			end
		end
	end
	
	-- Mail tracking - track items as they're taken from mail
	if event == "MAIL_INBOX_UPDATE" then
		if SexyLootDB and SexyLootDB.config and SexyLootDB.config.mail == false then return; end
		-- Set flag that we're at the mailbox
		self.atMailbox = true;
	end
	
	if event == "MAIL_CLOSED" then
		-- Clear mailbox flag
		self.atMailbox = false;
	end
	
	-- Track bag updates while at mailbox
	if event == "BAG_UPDATE" and self.atMailbox then
		if SexyLootDB and SexyLootDB.config and SexyLootDB.config.mail == false then return; end
		
		local bag = arg1;
		-- Only check the bag that changed
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot);
			if link then
				local _, count = GetContainerItemInfo(bag, slot);
				-- Check if this is a new item (compare to previous inventory state)
				if not self.previousBags[bag] then
					self.previousBags[bag] = {};
				end
				
				if not self.previousBags[bag][slot] then
					-- New item in this slot
					local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(link);
					if name then
						local label = "Mail:";
						local toast = quality >= LE_ITEM_QUALITY_EPIC and "heroictoast" or "defaulttoast";
						LootAlertFrameMixIn:AddAlert(name, link, quality, texture, count, false, label, toast);
					end
				end
				self.previousBags[bag][slot] = link;
			else
				if self.previousBags[bag] then
					self.previousBags[bag][slot] = nil;
				end
			end
		end
	end
end

function LootAlertFrame_OnUpdate(self, elapsed)
	-- Get current update time from config
	local updateSpeed = uptime;
	if SexyLootDB and SexyLootDB.config and SexyLootDB.config.time then
		updateSpeed = SexyLootDB.config.time;
	end
	
	self.updateTime = self.updateTime - elapsed;
	
	-- Handle delayed money updates
	if self.moneyUpdateTimer > 0 then
		self.moneyUpdateTimer = self.moneyUpdateTimer - elapsed;
		if self.moneyUpdateTimer <= 0 then
			local currentMoney = GetMoney();
			local diff = currentMoney - previousMoney;
			
			if diff < 0 and SexyLootDB and SexyLootDB.config and SexyLootDB.config.money ~= false then
				-- Money loss
				local amount = GetMoneyString(math.abs(diff), true);
				local label = "You spent:";
				local quality = LE_ITEM_QUALITY_POOR;
				local toast = "moneytoast";
				LootAlertFrameMixIn:AddAlert(amount, false, quality, false, false, true, label, toast, false, false, false, math.abs(diff), nil, true);
			end
			
			previousMoney = currentMoney;
		end
	end
	
	if self.updateTime <= 0 then
		local alert = LootAlertFrameMixIn:CreateAlert();
		if alert then
			-- Load saved scale
			local alertScale = scale;
			if SexyLootDB and SexyLootDB.config and SexyLootDB.config.scale then
				alertScale = SexyLootDB.config.scale;
			end
			
			alert:SetScale(alertScale);
			alert:ClearAllPoints();
			alert:Show();
			alert.animIn:Play();
			LootAlertFrameMixIn:AdjustAnchors();
		end
		self.updateTime = updateSpeed; -- Use the current speed setting
	end
end

function LootAlertButtonTemplate_OnLoad(self)
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	self:SetMovable(true);
	self:RegisterForDrag("LeftButton");
	tInsert(LootAlertFrameMixIn.alertButton, self);
end

function LootAlertButtonTemplate_OnDragStart(self)
	if not SexyLootDB.locked then
		self:StartMoving();
	end
end

function LootAlertButtonTemplate_OnDragStop(self)
	self:StopMovingOrSizing();
	if not SexyLootDB.locked then
		local point, _, relativePoint, x, y = self:GetPoint();
		-- Save the position for all toasts (they all use the same anchor)
		SexyLootDB.anchorPoint = point;
		SexyLootDB.anchorX = x;
		SexyLootDB.anchorY = y;
		-- Update all visible toasts to new position
		LootAlertFrameMixIn:AdjustAnchors();
	end
end

-- NewRecipeLearnedAlertFrame
local function NewRecipeLearnedAlertFrame_GetStarTextureFromRank(quality)
	if quality == 2 then
		return "|T"..assets.."toast-star:12:12:0:0:32:32:0:21:0:21|t";
	elseif quality == 3 then
		return "|T"..assets.."toast-star-2:12:24:0:0:64:32:0:42:0:21|t";
	elseif quality == 4 then
		return "|T"..assets.."toast-star-3:12:36:0:0:64:32:0:64:0:21|t";
	end
	return nil;
end

function LootAlertButtonTemplate_OnShow(self)
	if not self.data then
		self:Hide();
		return;
	end

	-- Set frame strata from config
	local frameStrata = "MEDIUM";
	if SexyLootDB and SexyLootDB.config and SexyLootDB.config.frameStrata then
		frameStrata = SexyLootDB.config.frameStrata;
	end
	self:SetFrameStrata(frameStrata);

	local data = self.data;
	if data.name then
		local defaultToast 		= data.toast == "defaulttoast";
		local recipeToast 		= data.toast == "recipetoast";
		local battlefieldToast  = data.toast == "battlefieldtoast";
		local moneyToast 		= data.toast == "moneytoast";
		local legendaryToast 	= data.toast == "legendarytoast";
		local commonToast 		= data.toast == "commontoast";
		local qualityColor 		= ITEM_QUALITY_COLORS[data.quality] or nil;
		local averageToast		= not recipeToast and not moneyToast and not commonToast;
	
		if data.count then
			self.Count:SetText(data.count);
		else
			self.Count:SetText(" ");
		end

		-- Set label color based on gain/loss
		if data.isLoss then
			self.Label:SetTextColor(1, 0.2, 0.2); -- Red for losses
			self.MoneyLabel:SetTextColor(1, 0.2, 0.2);
		else
			self.Label:SetTextColor(1, 1, 1); -- White for gains
			self.MoneyLabel:SetTextColor(1, 1, 1);
		end

		self.Icon:SetTexture(data.texture);
		self.Icon:SetShown(averageToast);
		self.IconBorder:SetShown(averageToast);
		self.LessIcon:SetTexture(data.texture);
		self.ItemName:SetText(data.name);
		self.ItemName:SetShown(averageToast);
		self.LessItemName:SetText(data.name);
		self.Label:SetText(data.label);
		self.Label:SetShown(averageToast);
		self.RollWon:SetShown(data.rollLink);
		self.MoneyLabel:SetShown(moneyToast);
		self.MoneyLabel:SetText(data.label);
		self.Amount:SetShown(moneyToast);
		self.Amount:SetText(data.name);
		
		self.Background:SetShown(defaultToast);
		self.HeroicBackground:SetShown(data.toast == "heroictoast");
		self.PvPBackground:SetShown(battlefieldToast);
		self.PvPBackground:SetSize(SUB_COORDS[1], SUB_COORDS[2]);
		self.PvPBackground:SetTexCoord(unpack(HONOR_BADGE));
		self.RecipeBackground:SetShown(recipeToast);
		self.RecipeTitle:SetShown(recipeToast);
		self.RecipeName:SetShown(recipeToast);
		self.RecipeIcon:SetShown(recipeToast);
		self.LessBackground:SetShown(commonToast);
		self.LessItemName:SetShown(commonToast);
		self.LessIcon:SetShown(commonToast);
		self.LegendaryBackground:SetShown(legendaryToast);
		self.RollWonTitle:SetShown(data.rollLink);
		self.MoneyBackground:SetShown(moneyToast);
		self.MoneyIconBorder:SetShown(moneyToast);
		self.MoneyIcon:SetShown(moneyToast);
		self.MountToastBackground:SetShown(data.toast == "mounttoast");
		self.PetToastBackground:SetShown(data.toast == "pettoast");
		
		if data.rollLink then
			if data.rollType == LOOT_ROLL_TYPE_NEED then
				self.RollWonTitle:SetTexture([[Interface\Buttons\UI-GroupLoot-Dice-Up]]);
			elseif data.rollType == LOOT_ROLL_TYPE_GREED then
				self.RollWonTitle:SetTexture([[Interface\Buttons\UI-GroupLoot-Coin-Up]]);
			else
				self.RollWonTitle:Hide();
			end
			self.RollWon:SetText(data.rollLink);
		end

		if recipeToast then
			self.RecipeIcon:SetTexture(data.texture);
			local craftIcon = PROFESSION_ICON_TCOORDS[data.subType];
			if craftIcon then
				self.RecipeIcon:SetTexCoord(unpack(craftIcon));
			end
			
			local rankTexture = NewRecipeLearnedAlertFrame_GetStarTextureFromRank(data.quality);
			if rankTexture then
				self.RecipeName:SetFormattedText("%s %s", data.name, rankTexture);
			else
				self.RecipeName:SetText(data.name);
			end
			self.RecipeTitle:SetText(data.label);
		end

		if qualityColor then
			self.ItemName:SetTextColor(qualityColor.r, qualityColor.g, qualityColor.b);
		end

		if LOOT_BORDER_BY_QUALITY[data.quality] then
			self.IconBorder:SetTexCoord(unpack(LOOT_BORDER_BY_QUALITY[data.quality]));
		end
		
		-- Load sound settings
		local soundEnabled = true;
		local useCoinSound = false;
		if SexyLootDB and SexyLootDB.config then
			soundEnabled = SexyLootDB.config.sound ~= false;
			useCoinSound = SexyLootDB.config.coinSound;
		end
		
		if soundEnabled then
			-- Only play coin sound for gains, not losses
			if moneyToast and useCoinSound and not data.isLoss then
				PlaySoundFile(SOUNDKIT.COIN_SOUND);
			elseif legendaryToast then
				PlaySoundFile(SOUNDKIT.UI_LEGENDARY_LOOT_TOAST);
			elseif commonToast then
				PlaySoundFile(SOUNDKIT.UI_RAID_LOOT_TOAST_LESSER_ITEM_WON);
			elseif recipeToast then
				PlaySoundFile(SOUNDKIT.UI_GARRISON_FOLLOWER_LEARN_TRAIT);
			elseif not (moneyToast and data.isLoss) then
				-- Don't play epic sound for money losses
				PlaySoundFile(SOUNDKIT.UI_EPICLOOT_TOAST);
			end
		end
		
		-- Load animation settings
		local animsEnabled = true;
		if SexyLootDB and SexyLootDB.config then
			animsEnabled = SexyLootDB.config.anims ~= false;
		end
		
		if animsEnabled then
			if legendaryToast then
				self.legendaryGlow.animIn:Play();
				self.legendaryShine.animIn:Play();
			elseif recipeToast then
				self.recipeGlow.animIn:Play();
				self.recipeShine.animIn:Play();
			else
				self.glow.animIn:Play();
				self.shine.animIn:Play();
			end
		end
		
		self.hyperLink 		= data.link;
		self.tip 			= data.tip;
		self.name 			= data.name;
		self.money			= data.money;
	end
end

function LootAlertButtonTemplate_OnHide(self)
	-- Stop all animations first
	self.animIn:Stop();
	self.waitAndAnimOut:Stop();
	
	local animsEnabled = true;
	if SexyLootDB and SexyLootDB.config then
		animsEnabled = SexyLootDB.config.anims ~= false;
	end
	
	if animsEnabled and self.data then
		if self.data.toast == "legendarytoast" then
			self.legendaryGlow.animIn:Stop();
			self.legendaryShine.animIn:Stop();
		elseif self.data.toast == "recipetoast" then
			self.recipeGlow.animIn:Stop();
			self.recipeShine.animIn:Stop();
		else
			self.glow.animIn:Stop();
			self.shine.animIn:Stop();
		end
	end

	-- Clear data
	if self.data then
		tWipe(self.data);
	end
	
	-- Hide the frame
	self:Hide();
	
	-- Readjust anchors after hiding
	LootAlertFrameMixIn:AdjustAnchors();
end

function LootAlertButtonTemplate_OnClick(self, button)
	if button == "RightButton" then
		self:Hide();
	else
		if HandleModifiedItemClick(self.hyperLink) then
			return;
		end
	end
end

function LootAlertButtonTemplate_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -14, -6);
	if self.tip then
		GameTooltip:SetText(self.name, 1, 1, 1);
		GameTooltip:AddLine(self.tip, nil, nil, nil, 1);
	elseif self.money then
		GameTooltip:AddLine(self.data.label or YOU_RECEIVED_LABEL);
		SetTooltipMoney(GameTooltip, self.money, nil);
	else
		GameTooltip:SetHyperlink(self.hyperLink);
	end
	GameTooltip:Show();
end