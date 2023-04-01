// A script by TFlippy

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";

Random traderRandom(Time());

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);

	// this.Tag("upkeep building");
	// this.set_u8("upkeep cap increase", 0);
	// this.set_u8("upkeep cost", 5);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
	this.Tag("change team on fort capture");

	// getMap().server_SetTile(this.getPosition(), CMap::tile_wood_back);

	AddIconToken("$filled_bucket$", "bucket.png", Vec2f(16, 16), 1);

	addTokens(this); //colored shop icons

	this.set_Vec2f("shop offset", Vec2f(0,0));
	this.set_Vec2f("shop menu size", Vec2f(6, 4));
	this.set_string("shop description", "Builder's Workshop");
	this.set_u8("shop icon", 15);
	//this.set_Vec2f("class offset", Vec2f(-6, 0));
	//this.set_string("required class", "pus");
    {
        ShopItem@ s = addShopItem(this, "Decorative Plant", "$decorativeplant$", "decorativeplant", "Decorative Plant.", true);
        AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 125);
		AddRequirement(s.requirements, "blob", "mat_dirt", "Dirt", 20);
		AddRequirement(s.requirements, "coin", "", "Coins", 100);
	
	    s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Lantern", "$lantern$", "lantern", descriptions[9], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 10);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Jack o' Lantern", "$jackolantern$", "jackolantern", "A spooky pumpkin.", true);
		AddRequirement(s.requirements, "blob", "lantern", "Lantern", 1);
		AddRequirement(s.requirements, "blob", "pumpkin", "Pumpkin", 1);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Bucket", "$bucket$", "bucket", descriptions[36], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 10);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Filled Bucket", "$filled_bucket$", "filled_bucket", Descriptions::filled_bucket, false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 10);
		AddRequirement(s.requirements, "coin", "", "Coins", 10);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Sponge", "$sponge$", "sponge", descriptions[53], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Trampoline", "$icon_trampoline$", "trampoline", descriptions[30], false);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 150);

		s.spawnNothing = true;
	}
	// {
		// ShopItem@ s = addShopItem(this, "Arrows (30)", "$mat_arrows$", "mat_arrows-30", descriptions[2], true);
		// AddRequirement(s.requirements, "coin", "", "Coins", 15);

		// s.spawnNothing = true;
	// }
	{
		ShopItem@ s = addShopItem(this, "Crate", "$crate$", "crate", "A wooden crate used for storage.\nBreaks upon impact.", true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 75);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Boulder", "$boulder$", "boulder", "Boulder used for crushing people.", true);
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 50);

		s.spawnNothing = true;
	}
	{
        ShopItem@ s = addShopItem(this, "Decorative Jellyfish", "$jellyfishjar$", "jellyfishjar", "A fancy source of light.", true);
        AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 50);
		AddRequirement(s.requirements, "blob", "jellyfish", "Jellyfish", 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 250);
	
	    s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Keg", "$keg$", "keg", "Highly explosive keg used by knight only.\nCan be worn.", true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 75);
		AddRequirement(s.requirements, "coin", "", "Coins", 70);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Chair", "$chair$", "chair", "Quite comfortable.", true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 40);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Table", "$table$", "table", "A portable surface with 4 legs.", true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 75);

		s.spawnNothing = true;
	}	
    {
        ShopItem@ s = addShopItem(this, "Nightstand", "$nightstand$", "nightstand", "A simple nightstand.", true);
        AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 75);
	
	    s.spawnNothing = true;
	} 
    {
        ShopItem@ s = addShopItem(this, "Bed", "$bed$", "bed", "A comfortable bed.", true);
        AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 150);
	
	    s.spawnNothing = true;
	}
    {
        ShopItem@ s = addShopItem(this, "Bookshelf", "$bookshelf$", "bookshelf", "Decorative bookshelf.", true);
        AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 125);
		AddRequirement(s.requirements, "coin", "", "Coins", 20);
	
	    s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Gaming Chair", "$gamingchair$", "gamingchair", "A chair for true gamer.", true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Gaming Table", "$gamingtable$", "gamingtable", "A table for true gamer.", true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200);

		s.spawnNothing = true;
	}
	// {
	// 	ShopItem@ s = addShopItem(this, "Cowboy Hat", "$cowboyhat$", "cowboyhat", "A hat gives you +99 shooting accuracy!", true);
	// 	AddRequirement(s.requirements, "coin", "", "Coins", 250);

	// 	s.spawnNothing = true;
	// }
	// {
	// 	ShopItem@ s = addShopItem(this, "Top Hat", "$tophat$", "tophat", "The kind of hat is a must for a gentlemen wardrobe.", true);
	// 	AddRequirement(s.requirements, "coin", "", "Coins", 500);

	// 	s.spawnNothing = true;
	// }
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	// reset shop colors
	addTokens(this);
}

void addTokens(CBlob@ this)
{
	int teamnum = this.getTeamNum();
	if (teamnum > 6) teamnum = 7;

	AddIconToken("$icon_trampoline$", "Trampoline.png", Vec2f(32, 16), 3, teamnum);
	AddIconToken("$icon_engineertools$", "EngineerTools.png", Vec2f(16, 16), 0, teamnum);
	AddIconToken("$chair$", "Chair.png", Vec2f(13, 17), 2, teamnum);
	AddIconToken("$table$", "table.png", Vec2f(24, 10), 0, teamnum);
	AddIconToken("$gamingchair$", "GamingChair.png", Vec2f(15, 18), 2, teamnum);
	AddIconToken("$gamingtable$", "GamingTable.png", Vec2f(24, 10), 0, teamnum);
    AddIconToken("$decorativeplant$", "DecorativePlant.png", Vec2f(14, 46), 0, teamnum);	
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if(caller.getName() == this.get_string("required class"))
	{
		this.set_Vec2f("shop offset", Vec2f_zero);
	}
	else
	{
		this.set_Vec2f("shop offset", Vec2f(0, 0));
	}
	this.set_bool("shop available", this.isOverlapping(caller));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if(cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("ConstructShort");

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
			else if (name == "filled_bucket")
			{
				CBlob@ b = server_CreateBlobNoInit("bucket");
				b.setPosition(callerBlob.getPosition());
				b.server_setTeamNum(callerBlob.getTeamNum());
				b.Tag("_start_filled");
				b.Init();
				callerBlob.server_Pickup(b);
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
