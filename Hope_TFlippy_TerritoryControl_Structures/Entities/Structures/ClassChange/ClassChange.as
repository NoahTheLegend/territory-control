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

	//this.Tag("upkeep building");
	//this.set_u8("upkeep cap increase", 0);
	//this.set_u8("upkeep cost", 5);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("remote_storage");
	this.Tag("builder always hit");
	this.Tag("change team on fort capture");

	this.getCurrentScript().tickFrequency = 300;

	// getMap().server_SetTile(this.getPosition(), CMap::tile_wood_back);

	this.inventoryButtonPos = Vec2f(-8, 0);
	this.addCommandID("sv_store");

	addTokens(this); //colored shop icons

	this.set_Vec2f("shop offset", Vec2f(0,0));
	this.set_Vec2f("shop menu size", Vec2f(5, 3));
	this.set_string("shop description", "Wardrobe");
	this.set_u8("shop icon", 15);

	{
		ShopItem@ s = addShopItem(this, "Building for Dummies", "$artisancertificate$", "artisancertificate", "Simplified Builder manuscript for those dumb peasants.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 200);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Engineer's Tools", "$engineertools$", "engineertools", "Engineer's Tools for real engineers.", true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 4);
		AddRequirement(s.requirements, "coin", "", "Coins", 750);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Suspicious Engineer's Tools", "$susengineertools$", "susengineertools", "Become a neutral spy engineer with 99% credibility.", true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 4);
		AddRequirement(s.requirements, "blob", "amogusplushie", "Amogus Plushie", 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 1000);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Advanced Engineer", "$advancedengineertools$", "advancedengineertools", "An engineer with extra hp.");
		AddRequirement(s.requirements, "blob", "mat_plasteel", "Plasteel Sheet", 125);
		AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingot", 12);
		s.spawnNothing = true;
	}
	{
	    ShopItem@ s = addShopItem(this, "In development", "$pheromones$", "pheromones", "Empty button");
		AddRequirement(s.requirements, "blob", "adminbuilder", "Placeholder", 1);
		s.spawnNothing = true;
    }
	{
		ShopItem@ s = addShopItem(this, "Hazmat Suit", "$icon_hazmat$", "hazmatitem", "A hazardous materials suit giving the wearer protection against fire, toxic gases, radiation and drowning.");
		AddRequirement(s.requirements, "blob", "mat_mithril", "Mithril", 75);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Soldier uniform", "$icon_suitofarmor$", "suitofarmor", "A suit of armor that offers you mobility. Has a good knife for self defense if you happen to lose your gun.\nHas extra resistance to bullets.");
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 8);
		AddRequirement(s.requirements, "coin", "", "Coins", 250);
		
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Royal Guard Armor", "$icon_royalarmor$", "royalarmor", "A heavy armor that offers high damage resistance at cost of low mobility. Has a shield which is tough enough to block bullets.");
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 4);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 10);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Ancient Weaboo Scroll", "$ninjascroll$", "ninjascroll", "An ancient scroll with ninja codex and techniques.");
		AddRequirement(s.requirements, "coin", "", "Coins", 4000);
		AddRequirement(s.requirements, "blob", "log", "Log", 1);
		AddRequirement(s.requirements, "blob", "klaxon", "klaxon", 1);
		AddRequirement(s.requirements, "blob", "animalbox", "Animal box", 1);
		AddRequirement(s.requirements, "blob", "bobomax", "Bobomax", 1);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Robotic suit", "$robosuititem$", "robosuititem", "A reproduced with human tech exosuit prototype.");
		AddRequirement(s.requirements, "coin", "", "Coins", 2500);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 100);
		AddRequirement(s.requirements, "blob", "mat_titaniumingot", "Titanium Ingot", 200);
		AddRequirement(s.requirements, "blob", "mat_copperwire", "Copper wire", 400);
		AddRequirement(s.requirements, "blob", "mat_battery", "Battery", 500);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Transform into a scout chicken", "$icon_scoutchicken$", "transform-scoutchicken", "Get into scout chicken corpse and have a free small weaponpack.\n\nOnly for neutrals.");
		AddRequirement(s.requirements, "coin", "", "Coins", 4000);
		AddRequirement(s.requirements, "blob", "scoutchicken", "Corpse of a scout chicken.", 1);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Transform into a soldier chicken", "$icon_soldierchicken$", "transform-soldierchicken", "Get into soldier chicken corpse and have a free weaponpack.\n\nOnly for neutrals.");
		AddRequirement(s.requirements, "coin", "", "Coins", 7500);
		AddRequirement(s.requirements, "blob", "soldierchicken", "Corpse of a combat chicken.", 1);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Transform into a commander chicken", "$icon_commanderchicken$", "transform-commanderchicken", "Get into commander chicken corpse and have a light weaponpack with a chicken phone.\nPassively sends forces onto faction buildings.\n\nOnly for neutrals.");
		AddRequirement(s.requirements, "coin", "", "Coins", 7500);
		AddRequirement(s.requirements, "blob", "phone", "Phone", 1);
		AddRequirement(s.requirements, "blob", "commanderchicken", "Corpse of a commander chicken.", 1);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Transform into a heavy chicken", "$icon_heavychicken$", "transform-heavychicken", "Get into heavy chicken suit and have a free heavy weaponpack.\n\nOnly for neutrals.");
		AddRequirement(s.requirements, "coin", "", "Coins", 12500);
		AddRequirement(s.requirements, "blob", "heavychicken", "Corpse of a heavy chicken.", 1);

		s.spawnNothing = true;
	}
	{
	    ShopItem@ s = addShopItem(this, "In development.", "$pheromones$", "pheromones", "Empty button");
		AddRequirement(s.requirements, "blob", "adminbuilder", "Placeholder.", 1);
		s.spawnNothing = true;
    }
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

	AddIconToken("$icon_royalarmor$", "RoyalArmor.png", Vec2f(16, 8), 0, teamnum);
	AddIconToken("$icon_suitofarmor$", "SuitOfArmor.png", Vec2f(16, 16), 0, teamnum);
	AddIconToken("$icon_scoutchicken$", "ChickenHeads.png", Vec2f(16, 16), 0, teamnum);
	AddIconToken("$icon_soldierchicken$", "ChickenHeads.png", Vec2f(16, 16), 1, teamnum);
	AddIconToken("$icon_commanderchicken$", "ChickenHeads.png", Vec2f(16, 16),2, teamnum);
	AddIconToken("$icon_heavychicken$", "ChickenHeads.png", Vec2f(16, 16), 3, teamnum);
}

bool canPickup(CBlob@ blob)
{
	return blob.hasTag("classchanger");
}

void onTick(CBlob@ this)
{
	if (this.getInventory().isFull()) return;

	CBlob@[] blobs;
	if (getMap().getBlobsInBox(this.getPosition() + Vec2f(128, 96), this.getPosition() + Vec2f(-128, -96), @blobs))
	{
		for (uint i = 0; i < blobs.length; i++)
		{
			CBlob@ blob = blobs[i];

			if ((canPickup(blob)) && !blob.isAttached())
			{
				if (isClient() && this.getInventory().canPutItem(blob)) blob.getSprite().PlaySound("/PutInInventory.ogg");
				if (isServer()) this.server_PutInInventory(blob);
			}
		}
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	if (forBlob is null || this is null) return false;
	CBlob@ carried = forBlob.getCarriedBlob();
	return forBlob.isOverlapping(this) && (carried is null ? true : canPickup(carried));
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (isInventoryAccessible(this, caller))
	{
		this.set_Vec2f("shop offset", Vec2f(8, 0));
		this.set_bool("shop available", this.isOverlapping(caller));

		CBitStream params;
		params.write_u16(caller.getNetworkID());

		CInventory @inv = caller.getInventory();
		if (inv is null) return;
		
		CBlob@ carried = caller.getCarriedBlob();
		if(carried is null && this.isOverlapping(caller))
		{
			if (inv.getItemsCount() > 0)
			{
				for (int i = 0; i < inv.getItemsCount(); i++)
				{
					CBlob @item = inv.getItem(i);
					if (canPickup(item))
					{
						params.write_u16(caller.getNetworkID());
						CButton@ buttonOwner = caller.CreateGenericButton(28, Vec2f(0, -10), this, this.getCommandID("sv_store"), "Store", params);
						break;
					}
				}
			}
		}
	}
	else
	{
		this.set_Vec2f("shop offset", Vec2f(0, 0));
		this.set_bool("shop available", this.isOverlapping(caller));
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("ConstructShort");

		u16 caller, item;

		if (!params.saferead_netid(caller) || !params.saferead_netid(item))
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

				MakeMat(callerBlob, this.getPosition(), spl[0], parseInt(spl[1]));

				// CBlob@ mat = server_CreateBlob(spl[0]);

				// if (mat !is null)
				// {
					// mat.Tag("do not set materials");
					// mat.server_SetQuantity(parseInt(spl[1]));
					// if (!callerBlob.server_PutInInventory(mat))
					// {
						// mat.setPosition(callerBlob.getPosition());
					// }
				// }
			}
			else if (name.findFirst("transform-") != -1)
			{
				string[] spll = name.split("-");
				if (spll.length == 2 && callerBlob.getTeamNum() > 6)
				{
					CBlob@ blob = server_CreateBlob(spll[1], 250, callerBlob.getPosition());
					blob.IgnoreCollisionWhileOverlapped(callerBlob);
					if (callerBlob.getPlayer() !is null) blob.server_SetPlayer(callerBlob.getPlayer());
					callerBlob.server_Die();
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
	if (cmd == this.getCommandID("sv_store"))
	{
		if (isServer())
		{
			CBlob@ caller = getBlobByNetworkID(params.read_u16());
			if (caller !is null)
			{
				CInventory @inv = caller.getInventory();
				if (caller.getName() == "builder")
				{
					CBlob@ carried = caller.getCarriedBlob();
					if (carried !is null)
					{
						if (carried.hasTag("temp blob"))
						{
							carried.server_Die();
						}
					}
				}
				if (inv !is null)
				{
					for (int i = 0; i < inv.getItemsCount(); i++)
					{
						CBlob @item = inv.getItem(i);
						if (canPickup(item))
						{
							caller.server_PutOutInventory(item);
							this.server_PutInInventory(item);
							i--;
						}
					}
				}
			}
		}
	}
}
