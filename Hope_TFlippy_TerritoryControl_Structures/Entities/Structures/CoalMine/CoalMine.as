// ArcherShop.as

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";

const string[] resources = 
{
	"mat_coal",
	"mat_iron",
	"mat_copper",
	"mat_stone",
	"mat_gold",
	"mat_titanium",
	"mat_sulphur",
	"mat_dirt"
};

const u8[] resourceYields = 
{
	10,
	27,
	8,
	45,
	20,
	12,
	10,
	15
};

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	this.getShape().getConsts().mapCollisions = false;

	sprite.SetZ(-50); //background
	sprite.SetEmitSound("Mine_Ambient.ogg");
	f32 mod = 0.75f+(0.01f*XORRandom(11));
	//printf(""+mod);
	sprite.SetEmitSoundSpeed(mod);
	sprite.SetEmitSoundVolume(0.3f);
	sprite.SetEmitSoundPaused(false);

	this.Tag("teamlocked tunnel");
	this.Tag("change team on fort capture");
	this.Tag("extractable");
	this.Tag("can be captured by neutral");
	this.Tag("no_die");

	this.Tag("upkeep building");
	this.set_u8("upkeep cap increase", 2);
	this.set_u8("upkeep cost", 0);

	if (isServer())
	{
		//0 - basic, 1 - iron, 2 - copper, 3 - gold, 4 - titanium, 5 - coal, 6 - mithril, 7 - dirt, 8 - sulphur 
		this.set_u8("type", XORRandom(9));
	}

	this.addCommandID("write");
	//this.set_Vec2f("nobuild extend", Vec2f(0.0f, 8.0f));
	this.set_Vec2f("travel button pos", Vec2f(3.5f, 4));
	this.inventoryButtonPos = Vec2f(-16, 8);
	this.getCurrentScript().tickFrequency = 30*5; //With 12 players its the same rate as before 1x, with 1 player its 0.35x

	getMap().server_SetTile(this.getPosition(), CMap::tile_castle_back);

	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 19, Vec2f(16, 8));
	this.SetMinimapRenderAlways(true);

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 8));
	this.set_Vec2f("shop menu size", Vec2f(6, 2));
	this.set_string("shop description", "Coalville Mining Company");
	
	if (this.hasTag("name_changed"))
	{
		this.setInventoryName(this.get_string("text"));
		this.set_string("shop description", this.get_string("text"));
	}
	
	this.set_u8("shop icon", 25);

	{
		ShopItem@ s = addShopItem(this, "Buy Dirt (50)", "$mat_dirt$", "mat_dirt-50", "Buy 50 Dirt for 50 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 50);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Stone (250)", "$mat_stone$", "mat_stone-250", "Buy 250 Stone for 135 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 135);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Coal (25)", "$mat_coal$", "mat_coal-25", "Buy 25 Coal for 250 coins.");
		AddRequirement(s.requirements,"coin","","Coins", 250); //made it cost a lot, so it's better to just conquer the building
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Copper Ore (50)", "$mat_copper$", "mat_copper-50", "Buy 50 copper for 75 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 75);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Iron Ore (100)", "$mat_iron$", "mat_iron-100", "Buy 100 Iron Ore for 125 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 125);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Sulphur (50)", "$mat_sulphur$", "mat_sulphur-50", "Buy 50 Sulphur for 150 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Dirt (500)", "$mat_dirt$", "mat_dirt-500", "Buy 500 Dirt for 500 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 500);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Stone (2500)", "$mat_stone$", "mat_stone-2500", "Buy 2500 Stone for 1350 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 1350);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Coal (250)", "$mat_coal$", "mat_coal-250", "Buy 250 Coal for 2500 coins.");
		AddRequirement(s.requirements,"coin","","Coins", 2500); //made it cost a lot, so it's better to just conquer the building
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Copper Ore (500)", "$mat_copper$", "mat_copper-500", "Buy 500 copper for 750 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 750);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Iron Ore (1000)", "$mat_iron$", "mat_iron-1000", "Buy 1000 Iron Ore for 1250 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 1250);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy Sulphur (500)", "$mat_sulphur$", "mat_sulphur-500", "Buy 500 Sulphur for 1500 coins.");
		AddRequirement(s.requirements, "coin", "", "Coins", 1500);
		s.spawnNothing = true;
	}
}

/*void onTick(CBlob@ this)
{
	if (isServer())
	{
		u8 index = XORRandom(resources.length - 1);
		MakeMat(this, this.getPosition(), resources[index], XORRandom(resourceYields[index]));
	}
}*/

void onTick(CBlob@ this)
{
	if (isClient() && this !is null && this.getTickSinceCreated() >= 5 && this.getTickSinceCreated() <= 250)
	{
		this.Sync("type", true);
		switch (this.get_u8("type"))
		{
			case 0:
			{
				this.setInventoryName("Exhausted mine");
				break;
			}
			case 1:
			{
				this.setInventoryName("Rich on iron mine");
				break;
			}
			case 2:
			{
				this.setInventoryName("Rich on copper mine");
				break;
			}
			case 3:
			{
				this.setInventoryName("Rich on gold mine");
				break;
			}
			case 4:
			{
				this.setInventoryName("Rich on titanium mine");
				break;
			}
			case 5:
			{
				this.setInventoryName("Rich on coal mine");
				break;
			}
			case 6:
			{
				this.setInventoryName("Rich on mithril mine");
				break;
			}
			case 7:
			{
				this.setInventoryName("Rich on dirt mine");
				break;
			}
			case 8:
			{
				this.setInventoryName("Rich on sulphur mine");
				break;
			}
		}
	}
	if (isServer())
	{
		// if (this.getInventory().isFull()) return;

		// u8 index = XORRandom(resources.length - 1);
		// MakeMat(this, this.getPosition(), resources[index], XORRandom(resourceYields[index]));

		CBlob@ storage = FindStorage(this.getTeamNum());
		int count = getPlayerCount();
		double mod = ((6 + count) + Maths::Max(0, count - 10)) * 0.05f; 
		//Previous rate at 12 players, players after 10 increase the rate by twice as much
		//0.35x Previous rate at 1 player
		//0.5x at 4 players
		//1x at 12 players
		//2x at 22 players
		
		u8 index = XORRandom(resources.length);
		u32 amount = Maths::Max(1, Maths::Floor(XORRandom(resourceYields[index]) * mod));
		//print(mod +  " " +amount);

		switch (this.get_u8("type"))
		{
			case 0:
			{
				amount = Maths::Floor(amount*0.5);
				break;
			}
			case 1:
			{
				if (resources[index] == "mat_iron")
					amount *= 2;
				break;
			}
			case 2:
			{
				if (resources[index] == "mat_copper")
					amount *= 2;
				break;
			}
			case 3:
			{
				if (resources[index] == "mat_gold")
					amount *= 3;
				break;
			}
			case 4:
			{
				if (resources[index] == "mat_titanium")
					amount *= 3;
				break;
			}
			case 5:
			{
				if (resources[index] == "mat_coal")
					amount *= 4;
				break;
			}
			case 6:
			{
				u32 amoamount = Maths::Max(1, Maths::Floor(XORRandom(3) * mod));
				if (storage !is null) MakeMat(storage, this.getPosition(), "mat_mithril", amoamount);
				else if (!this.getInventory().isFull()) MakeMat(this, this.getPosition(), "mat_mithril", amoamount);
				break;
			}
			case 7:
			{
				if (resources[index] == "mat_dirt")
					amount *= 2;
				break;
			}
			case 8:
			{
				if (resources[index] == "mat_sulphur")
					amount *= 4;
				break;
			}
		}
		
		if (storage !is null)
		{
			MakeMat(storage, this.getPosition(), resources[index], amount);
		}
		else if (!this.getInventory().isFull())
		{
			MakeMat(this, this.getPosition(), resources[index], amount);
		}
	}
}

CBlob@ FindStorage(u8 team)
{
	if (team >= 100) return null;

	CBlob@[] blobs;
	getBlobsByName("stonepile", @blobs);

	CBlob@[] validBlobs;

	for (u32 i = 0; i < blobs.length; i++)
	{
		if (blobs[i].getTeamNum() == team && !blobs[i].getInventory().isFull())
		{
			validBlobs.push_back(blobs[i]);
		}
	}

	if (validBlobs.length == 0) return null;

	return validBlobs[XORRandom(validBlobs.length)];
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	this.set_Vec2f("shop offset", Vec2f(3, -2));
	this.set_bool("shop available", this.isOverlapping(caller));

	if (caller is null) return;
	if (!this.isOverlapping(caller)) return;

	//rename the coal mine
	CBlob@ carried = caller.getCarriedBlob();
	if(carried !is null && carried.getName() == "paper" && caller.getTeamNum() == this.getTeamNum() && !caller.isAttached())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		params.write_u16(carried.getNetworkID());

		CButton@ buttonWrite = caller.CreateGenericButton("$icon_paper$", Vec2f(0, -8), this, this.getCommandID("write"), "Rename the mine.", params);
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return true;

	// return false;
	// return (forBlob.getTeamNum() == this.getTeamNum() && forBlob.isOverlapping(this));
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
	if (cmd == this.getCommandID("write"))
	{
		if (isServer())
		{
			CBlob @caller = getBlobByNetworkID(params.read_u16());
			CBlob @carried = getBlobByNetworkID(params.read_u16());

			if (caller !is null && carried !is null)
			{
				this.set_string("text", carried.get_string("text"));
				this.Sync("text", true);
				this.set_string("shop description", this.get_string("text"));
				this.Sync("shop description", true);
				carried.server_Die();
				this.Tag("name_changed");
			}
		}
		if (isClient())
		{
			this.setInventoryName(this.get_string("text"));
		}
	}
}
