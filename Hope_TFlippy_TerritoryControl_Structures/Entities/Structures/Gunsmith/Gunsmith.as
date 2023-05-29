// A script by TFlippy

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";

const string[] resources =
{
	"mat_pistolammo",
	"mat_rifleammo",
	"mat_shotgunammo",
	"mat_sniperammo",
	"mat_gatlingammo"
};

const u8[] resourceYields =
{
	10,
	8,
	4,
	1,
	15
};

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);

	//this.Tag("upkeep building");
	//this.set_u8("upkeep cap increase", 0);
	//this.set_u8("upkeep cost", 5);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
	this.Tag("extractable");
	this.Tag("change team on fort capture");

	this.getCurrentScript().tickFrequency = 300;
	this.inventoryButtonPos = Vec2f(-8, 0);

	this.set_Vec2f("shop offset", Vec2f(0,0));
	this.set_Vec2f("shop menu size", Vec2f(5, 4));
	this.set_string("shop description", "Gunsmith's Workshop");
	this.set_u8("shop icon", 15);

	AddIconToken("$dp27$", "DP-27.png", Vec2f(32, 12), this.getTeamNum());
	AddIconToken("$icon_sniperammo$", "AmmoIcon_Sniper.png", Vec2f(24,24), 255);

	{
		ShopItem@ s = addShopItem(this, "Low Caliber Ammunition (20)", "$icon_pistolammo$", "mat_pistolammo-20", "Bullets for pistols and SMGs.");
		AddRequirement(s.requirements, "coin", "", "Coins", 30);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Revolver", "$revolver$", "revolver", "A compact firearm for those with small pockets.\n\nUses Lowcal Rounds.");
		AddRequirement(s.requirements, "coin", "", "Coins", 50);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Bobby Gun", "$smg$", "smg", "A submachine gun.\n\nUses Lowcal Rounds.");
		AddRequirement(s.requirements, "coin", "", "Coins", 100);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "High Caliber Ammunition (10)", "$icon_rifleammo$", "mat_rifleammo-10", "Bullets for rifles. Effective against armored targets.");
		AddRequirement(s.requirements, "coin", "", "Coins", 60);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Bolt Action Rifle", "$rifle$", "rifle", "A handy bolt action rifle.\n\nUses Highcal Rounds.");
		AddRequirement(s.requirements, "coin", "", "Coins", 200);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Lever Action Rifle", "$leverrifle$", "leverrifle", "A speedy lever action rifle.\n\nUses Highcal Rounds.");
		AddRequirement(s.requirements, "coin", "", "Coins", 300);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Shotgun Shells (4)", "$icon_shotgunammo$", "mat_shotgunammo-4", "Shotgun Shells for... Shotguns.");
		AddRequirement(s.requirements, "coin", "", "Coins", 50);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Boomstick", "$icon_boomstick$", "boomstick", "You see this? A boomstick! The twelve-gauge double-barreled Bobington.\n\nUses Shotgun Shells.");
		AddRequirement(s.requirements, "coin", "", "Coins", 250); //300c
		//AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 8); //80c
		//AddRequirement(s.requirements, "blob", "mat_copperingot", "Copper Ingot", 2); //20c
		//AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 6); //300c

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Shotgun", "$icon_shotgun$", "shotgun", "A short-ranged weapon that deals devastating damage.\n\nUses Shotgun Shells.");
		AddRequirement(s.requirements, "coin", "", "Coins", 350); 
		//AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 120); //324c
		//AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 4); //200c

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Machine Gun Ammunition (50)", "$icon_gatlingammo$", "mat_gatlingammo-50", "Ammunition used by the machine gun.");
		AddRequirement(s.requirements, "coin", "", "Coins", 75);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "DP-27", "$dp27$", "dp27", "A cheap machinegun that was primary used in WW2 by russians.\n\nUses Gatling Ammo.");
		AddRequirement(s.requirements, "coin", "", "Coins", 800); //1000c
		//AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 150); //405c
		//AddRequirement(s.requirements, "blob", "mat_copperingot", "Copper Ingot", 2); //20c
		//AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 8);	//400c

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "High Power Ammunition (10)", "$icon_sniperammo$", "mat_sniperammo-10", "Rounds that are mainly used by sniper rifles. Very effective against heavy armored targets.");
		AddRequirement(s.requirements, "coin", "", "Coins", 120);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Big iron", "$truerevolver$", "truerevolver", "If a cowboy wants a cool handgun - he gets it no matter what.\n\nUses High Power Rounds.");
		AddRequirement(s.requirements, "coin", "", "Coins", 750);

		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
}

void onTick(CBlob@ this)
{
	if(isServer())
	{
		u8 index = XORRandom(resources.length);

		if (!this.getInventory().isFull())
		{
			MakeMat(this, this.getPosition(), resources[index], XORRandom(resourceYields[index]));
		}
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return forBlob.getName() == "extractor" || (forBlob.isOverlapping(this) && forBlob.getCarriedBlob() is null);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBlob@ carried = caller.getCarriedBlob();

	if (isInventoryAccessible(this, caller))
	{
		this.set_Vec2f("shop offset", Vec2f(4, 0));
		this.set_bool("shop available", this.isOverlapping(caller));
	}
	else
	{
		this.set_Vec2f("shop offset", Vec2f(0, 0));
		this.set_bool("shop available", this.isOverlapping(caller));
	}
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
