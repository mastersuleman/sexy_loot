local _, private = ...;

local Weapon, Armor, Container, Consumable, _, TradeGoods, Projectile, Quiver, Recipe, Gem, Misc, Quest = GetAuctionItemClasses();

private.config = {
    -- Technical
    scale        = 0.75,
    sound        = true,
    coinSound    = true,
    time         = 0.30,
    numbuttons   = 8,
    anims        = true,
    offset_x     = 2,
    growthDirection = "UP",
    frameStrata  = "MEDIUM",

    -- Activity tracking
    looting      = true,
    creating     = true,
    rolling      = true,
    money        = true,
    recipes      = true,
    honor        = true,

    -- Filtering
    ignore_level = false,
    min_quality  = 1,
    max_level    = 4,
    filter       = false,
    filter_type  = {
        MONEY,
        Weapon,
    },
};
