// ArcherShop.as

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";
#include "MakeSeed.as";

Random traderRandom(Time());

void onInit(CBlob@ this)
{
	this.Tag("upkeep building");
	this.set_u8("upkeep cap increase", 30);
	this.set_u8("upkeep cost", 0);

	this.Tag("invincible");
	
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;
	
	this.Tag("change team on fort capture");
	
	getMap().server_SetTile(this.getPosition(), CMap::tile_castle_back);

	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 49, Vec2f(8, 8));
	this.SetMinimapRenderAlways(true);
	
	AddIconToken("$bp_mechanist$", "Blueprints.png", Vec2f(16, 16), 2);
	AddIconToken("$mat_goldingot$", "Material_GoldIngot.png", Vec2f(16, 16), 1);
	AddIconToken("$musicdisc$", "MusicDisc.png", Vec2f(8, 8), 0);
	AddIconToken("$seed$", "Seed.png",Vec2f(8,8),0);
	AddIconToken("$icon_cake$", "Cake.png", Vec2f(16, 8), 0);
	AddIconToken("$icon_car$", "Icon_Car.png", Vec2f(16, 8), 0);
	AddIconToken("$foodcan$", "FoodCan.png", Vec2f(16, 16), 0);
	
	this.getCurrentScript().tickFrequency = 30 * 3;
	
	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 8));
	this.set_Vec2f("shop menu size", Vec2f(6,5));
	this.set_string("shop description", "Chicken Store");
	this.set_u8("shop icon", 25);
	
	// {
		// ShopItem@ s = addShopItem(this, "Sell Grain (1)", "$COIN$", "coin-40", "Sell 1 Grain for 40 coins.");
		// AddRequirement(s.requirements, "blob", "grain", "Grain", 1);
		// s.spawnNothing = true;
	// }
	if (isServer())
	{
		this.server_setTeamNum(-1);
	}
	

	{
		ShopItem@ s = addShopItem(this, "Buy Gold Ingot (1)", "$mat_goldingot_1x$", "mat_goldingot-1", "Buy 1 Gold Ingot for 100 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 100);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Gold Ingot (10)", "$mat_goldingot_10x$", "mat_goldingot-10", "Buy 10 Gold Ingots for 1000 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 1000);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Stone (250)", "$mat_stone_1x$", "mat_stone-250", "Buy 250 stone for 125 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 125);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Stone (2500)", "$mat_stone_10x$", "mat_stone-2500", "Buy 2500 stone for 1250 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 1250);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Wood (250)", "$mat_wood_1x$", "mat_wood-250", "Buy 250 wood for 90 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 90);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Wood (2500)", "$mat_wood_10x$", "mat_wood-2500", "Buy 2500 wood for 900 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 900);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Gold Ingot (1)", "$COIN$", "coin-100", "Sell 1 Gold Ingot for 100 coins.");
		AddRequirement(s.requirements, "blob", "mat_goldingot", "Gold Ingot", 1);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Gold Ingot (10)", "$COIN$", "coin-1000", "Sell 10 Gold Ingots for 1000 coins.");
		AddRequirement(s.requirements, "blob", "mat_goldingot", "Gold Ingot", 10);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Stone (250)", "$COIN$", "coin-100", "Sell 250 stone for 100 coins.");
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 250);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Stone (2500)", "$COIN$", "coin-1000", "Sell 2500 stone for 1000 coins.");
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 2500);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Wood (250)", "$COIN$", "coin-75", "Sell 250 wood for 75 coins.");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 250);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Wood (2500)", "$COIN$", "coin-750", "Sell 2500 wood for 750 coins.");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 2500);
		s.spawnNothing = true;
	}
	{
		u32 cost = 250;
		ShopItem@ s = addShopItem(this, "Sell Pumpkin (1)", "$COIN$", "coin-" + cost, "Sell 1 pumpkin for " + cost + " coins.");
		AddRequirement(s.requirements, "blob", "pumpkin", "Pumpkin", 1);
		s.spawnNothing = true;
	}
	{
		u32 cost = 400;
		ShopItem@ s = addShopItem(this, "Sell Oil Drum (50 l)", "$COIN$", "coin-" + cost, "Sell 50 litres of oil for " + cost + " coins.");
		AddRequirement(s.requirements, "blob", "mat_oil", "Oil Drum (50 l)", 50);
		s.spawnNothing = true;
	}
	{
		u32 cost = 200;
		{
			ShopItem@ s = addShopItem(this, "Sell Scrub's Chow (1)", "$COIN$", "coin-" + cost, "Sell 1 Scrub's Chow for " + cost + " coins.");
			AddRequirement(s.requirements, "blob", "foodcan", "Scrub's Chow", 1);
			s.spawnNothing = true;
		}
		{
			ShopItem@ s = addShopItem(this, "Sell Scrub's Chow (4)", "$COIN$", "coin-" + cost*4, "Sell 4 Scrub's Chow for " + cost*4 + " coins.");
			AddRequirement(s.requirements, "blob", "foodcan", "Scrub's Chow", 4);
			s.spawnNothing = true;
		}
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Grain (1)", "$COIN$", "coin-50", "Sell 1 grain for 50 coins.");
		AddRequirement(s.requirements, "blob", "grain", "Grain", 1);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Grain (5)", "$COIN$", "coin-250", "Sell 5 grain for 250 coins.");
		AddRequirement(s.requirements, "blob", "grain", "Grain", 5);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Wonderful Fluffy UPF Badger!", "$ss_badger$", "badger", "Every child's dream! Don't hesitate and get your own Wonderful Fluffy Badger!");
		AddRequirement(s.requirements, "coin", "", "Coins", 199);
		s.buttonwidth = 4;
		s.buttonheight = 1;
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Unlucky Badger", "$badgerBomb$", "badgerbomb", "A badger with an explosive personality.");
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
		AddRequirement(s.requirements, "blob", "mat_oil", "Oil Drum (25)", 25);
		s.buttonwidth = 4;
		s.buttonheight = 1;
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Fluffy Badger Plushie (1)", "$badgerplushie$", "badgerplushie-30", "Everyone's favourite pet now as a toy!");
		AddRequirement(s.requirements, "coin", "", "Coins", 149);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "SpaceStar Ordering Transmitter", "$phone$", "phone", "Want to get help from UPF in hard battles? This will make your desires come true!");
		AddRequirement(s.requirements, "coin", "", "Coins", 4499);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "UPF Beagle-2o", "$beagle$", "beagle", "Good handgun for commander personal defense!");
		AddRequirement(s.requirements, "coin", "", "Coins", 999);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Ice Cream (1)", "$icecream$", "icecream-8", "Kids have a second stomach when it comes to eating ice cream!");
		AddRequirement(s.requirements, "coin", "", "Coins", 19);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Cinnamon Bun", "$icon_cake$", "cake", "A tasty cinnamon-flavoured stack.");
		AddRequirement(s.requirements, "coin", "", "Coins", 48);
		s.spawnNothing = true;
	}
	

	
	// Random@ rand = Random(this.getNetworkID());
	
	// // Gold Trader
	// if (rand.NextRanged(100) < 75)
	// {
		// {
			// ShopItem@ s = addShopItem(this, "Buy Gold Ingot (1)", "$mat_goldingot$", "mat_goldingot-1", "Buy 1 Gold Ingot for 100 coins.");
			// AddRequirement(s.requirements, "coin", "", "Coins", 100);
			// s.spawnNothing = true;
		// }
		// {
			// ShopItem@ s = addShopItem(this, "Sell Gold Ingot (1)", "$COIN$", "coin-100", "Sell 1 Gold Ingot for 100 coins.");
			// AddRequirement(s.requirements, "blob", "mat_goldingot", "Gold Ingot", 1);
			// s.spawnNothing = true;
		// }
	// }
	
	// // Materials Trader
	// if (rand.NextRanged(100) < 40)
	// {
		// {
			// ShopItem@ s = addShopItem(this, "Buy Stone (250)", "$mat_stone$", "mat_stone-250", "Buy 250 stone for 125 coins.");
			// AddRequirement(s.requirements, "coin", "", "Coins", 125);
			// s.spawnNothing = true;
		// }
		// {
			// ShopItem@ s = addShopItem(this, "Buy Wood (250)", "$mat_wood$", "mat_wood-250", "Buy 250 wood for 90 coins.");
			// AddRequirement(s.requirements, "coin", "", "Coins", 90);
			// s.spawnNothing = true;
		// }
		// {
			// ShopItem@ s = addShopItem(this, "Sell Stone (250)", "$COIN$", "coin-100", "Sell 250 stone for 100 coins.");
			// AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 250);
			// s.spawnNothing = true;
		// }
		// {
			// ShopItem@ s = addShopItem(this, "Sell Wood (250)", "$COIN$", "coin-75", "Sell 250 wood for 75 coins.");
			// AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 250);
			// s.spawnNothing = true;
		// }
	// }
	
	// // Misc Trader
	// if (rand.NextRanged(100) < 40)
	// {
		// {
			// ShopItem@ s = addShopItem(this, "Gramophone Record", "$musicdisc$", "musicdisc", "A random gramophone record!");
			// AddRequirement(s.requirements, "coin", "", "Coins", 30);
			// s.spawnNothing = true;
		// }	
		// {
			// ShopItem@ s = addShopItem(this, "Voltron Battery Plus", "$mat_battery$", "mat_battery-50-50", "Energize yourself with our electricity in a can!");
			// AddRequirement(s.requirements, "coin", "", "Coins", 249);
			// s.spawnNothing = true;
		// }
		// {
			// ShopItem@ s = addShopItem(this, "Fluffy Badger Plushie (1)", "$badgerplushie$", "badgerplushie-30", "Everyone's favourite pet now as a toy!");
			// AddRequirement(s.requirements, "coin", "", "Coins", 149);
			// s.spawnNothing = true;
		// }
	// }
	
	// // Food Trader
	// if (rand.NextRanged(100) < 60)
	// {
		// {
			// ShopItem@ s = addShopItem(this, "Buy Scrub's Chow (1)", "$foodcan$", "foodcan", "Buy 1 Scrub's Chow for 100 coins. Cheap food commonly eaten by lowlife.");
			// AddRequirement(s.requirements, "coin", "", "Coins", 100);
			// s.spawnNothing = true;
		// }
		// {
			// ShopItem@ s = addShopItem(this, "Sell Stone (250)", "$COIN$", "coin-100", "Sell 1 Scrub's Chow for 75 coins.");
			// AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 75);
			// s.spawnNothing = true;
		// }
		// {
			// ShopItem@ s = addShopItem(this, "Cinnamon Bun", "$icon_cake$", "cake", "A tasty cinnamon-flavoured stack.");
			// AddRequirement(s.requirements, "coin", "", "Coins", 50);
			// s.spawnNothing = true;
		// }
		// {
			// ShopItem@ s = addShopItem(this, "Ice Cream (1)", "$icecream$", "icecream-8", "Cotton candy-flavoured ice cream. Ideal snack for hot summers!");
			// AddRequirement(s.requirements, "coin", "", "Coins", 39);
			// s.spawnNothing = true;
		// }
	// }
	
	CSprite@ sprite = this.getSprite();

	if (sprite !is null)
	{
		string keck = "Merchant_Ambassador.png";
		CSpriteLayer@ trader = sprite.addSpriteLayer("trader", keck, 16, 24, 0, 0);
		trader.SetRelativeZ(20);
		Animation@ stop = trader.addAnimation("stop", 1, false);
		stop.AddFrame(0);
		Animation@ walk = trader.addAnimation("walk", 1, false);
		walk.AddFrame(0); walk.AddFrame(1); walk.AddFrame(2); walk.AddFrame(3);
		walk.time = 10;
		walk.loop = true;
		trader.SetOffset(Vec2f(0, 4));
		trader.SetFrame(0);
		trader.SetAnimation(stop);
		trader.SetIgnoreParentFacing(true);
		this.set_bool("trader moving", false);
		this.set_bool("moving left", false);
		this.set_u32("move timer", getGameTime() + (traderRandom.NextRanged(5) + 5)*getTicksASecond());
		this.set_u32("next offset", traderRandom.NextRanged(16));
	}
	
}

void onTick(CBlob@ this)
{
	if (isServer())
	{
		const u8 myTeam = this.getTeamNum();
		if (myTeam >= 100) return;

		CBlob@[] players;
		getBlobsByTag("player", @players);
		
		for (uint i = 0; i < players.length; i++)
		{
			if (players[i].getTeamNum() == myTeam)
			{
				CPlayer@ ply = players[i].getPlayer();
			
				if (ply !is null) ply.server_setCoins(ply.getCoins() + 2);
			}
		}
	}
}

void onTick(CSprite@ this)
{
	//TODO: empty? show it.
	CBlob@ blob = this.getBlob();
	CSpriteLayer@ trader = this.getSpriteLayer("trader");
	bool trader_moving = blob.get_bool("trader moving");
	bool moving_left = blob.get_bool("moving left");
	u32 move_timer = blob.get_u32("move timer");
	u32 next_offset = blob.get_u32("next offset");
	if (!trader_moving)
	{
		if (move_timer <= getGameTime())
		{
			blob.set_bool("trader moving", true);
			trader.SetAnimation("walk");
			trader.SetFacingLeft(!moving_left);
			Vec2f offset = trader.getOffset();
			offset.x *= -1.0f;
			trader.SetOffset(offset);
		}
	}
	else
	{
		//had to do some weird shit here because offset is based on facing
		Vec2f offset = trader.getOffset();
		if (moving_left && offset.x > -next_offset)
		{
			offset.x -= 0.5f;
			trader.SetOffset(offset);
		}
		else if (moving_left && offset.x <= -next_offset)
		{
			blob.set_bool("trader moving", false);
			blob.set_bool("moving left", false);
			blob.set_u32("move timer", getGameTime() + (traderRandom.NextRanged(5) + 5)*getTicksASecond());
			blob.set_u32("next offset", traderRandom.NextRanged(16));
			trader.SetAnimation("stop");
		}
		else if (!moving_left && offset.x > -next_offset)
		{
			offset.x -= 0.5f;
			trader.SetOffset(offset);
		}
		else if (!moving_left && offset.x <= -next_offset)
		{
			blob.set_bool("trader moving", false);
			blob.set_bool("moving left", true);
			blob.set_u32("move timer", getGameTime() + (traderRandom.NextRanged(5) + 5)*getTicksASecond());
			blob.set_u32("next offset", traderRandom.NextRanged(16));
			trader.SetAnimation("stop");
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if(cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/ChaChing.ogg");
		
		u16 caller, item;
		
		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;
		
		string name = params.read_string();
		CBlob@ callerBlob = getBlobByNetworkID(caller);
		
		if (callerBlob is null) return;
		
		if (isServer())
		{
			string[] spl = name.split("-");
			
			if (spl[0] == "coin")
			{
				CPlayer@ callerPlayer = callerBlob.getPlayer();
				if (callerPlayer is null) return;
				
				callerPlayer.server_setCoins(callerPlayer.getCoins() +  parseInt(spl[1]));
			}
			else if(spl[0] == "seed")
			{
				CBlob@ blob = server_MakeSeed(this.getPosition(),XORRandom(2)==1 ? "tree_pine" : "tree_bushy");
				
				if (blob is null) return;
			   
				if (!blob.canBePutInInventory(callerBlob))
				{
					callerBlob.server_Pickup(blob);
				}
				else if (callerBlob.getInventory() !is null && !callerBlob.getInventory().isFull())
				{
					callerBlob.server_PutInInventory(blob);
				}
			}
			else if (name.findFirst("mat_") != -1)
			{
				CPlayer@ callerPlayer = callerBlob.getPlayer();
				if (callerPlayer is null) return;
				
				CBlob@ mat = server_CreateBlob(spl[0]);
							
				if (mat !is null)
				{
					mat.Tag("do not set materials");
					mat.server_SetQuantity(parseInt(spl[1]));
					if (!callerBlob.server_PutInInventory(mat))
					{
						mat.setPosition(callerBlob.getPosition());
					}
				}
			}
			else
			{
				CBlob@ blob = server_CreateBlob(spl[0], callerBlob.getTeamNum(), this.getPosition());
				
				if (blob is null) return;
			   
				if (!blob.canBePutInInventory(callerBlob))
				{
					callerBlob.server_Pickup(blob);
				}
				else if (callerBlob.getInventory() !is null && !callerBlob.getInventory().isFull())
				{
					callerBlob.server_PutInInventory(blob);
				}
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	this.set_Vec2f("shop offset", Vec2f(0,0));
	this.set_bool("shop available", this.isOverlapping(caller));
}