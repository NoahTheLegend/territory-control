// #include "MakeMat.as";
#include "MakeCrate.as";
#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";

void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-25); //background
	
	addTokens(this); //colored shop icons

	this.set_f32("pickup_priority", 8.00f); // The lower, the higher priority

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(4, 4));
	this.set_string("shop description", "Ancient manipulator");
	this.set_u8("shop icon", 15);
	this.Tag("heavy weight");
	
	{
		ShopItem@ s = addShopItem(this, "Transmute Stone to Copper", "$mat_iron$", "mat_iron-250", "Transmute 250 Stone into 250 Iron Ore.");
		AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 250);
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 35);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Transmute Iron to Copper", "$mat_copper$", "mat_copper-250", "Transmute 250 Iron Ore into 250 Copper Ore.");
		AddRequirement(s.requirements, "blob", "mat_iron", "Iron Ore", 250);
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 10);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Transmute Gold to Mithril", "$mat_mithril$", "mat_mithril-250", "Transmute 250 Gold Ore into 250 Mithril Ore.");
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold Ore", 250);
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 50);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Refine Mithril", "$mat_mithrilingot$", "mat_mithrilingot-2", "Refine 10 Mithril Ore into 2 Mithril Ingots.");
		AddRequirement(s.requirements, "blob", "mat_mithril", "Mithril Ore", 10);
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 10);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Reconstruct 10 Plasteel Sheets", "$icon_plasteel$", "mat_plasteel-10", "A durable yet lightweight material.");
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 50);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 16);
		AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingot", 10);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Wilmet", "$mat_wilmet$", "mat_wilmet-20", "Refine 50 Mithril Ore And 50 Gold Ore into 25 wilmet.");
		AddRequirement(s.requirements, "blob", "mat_mithril", "Mithril Ore", 50);
		AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 50);
		AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingot", 2);
		s.spawnNothing = true;
	}
	{
	    ShopItem@ s = addShopItem(this, "Life Matter", "$lifematter$", "lifematter", "Transform a live form into matter.");
		AddRequirement(s.requirements, "blob", "kitten", "Kitten", 1);
		AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingot", 8);
		AddRequirement(s.requirements, "blob", "mat_plasteel", "Plasteel Sheet", 50);
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 50);
		s.spawnNothing = true;
    }
	{
	    ShopItem@ s = addShopItem(this, "Energy Matter", "$energymatter$", "energymatter", "Transform a live form into energy.");
		AddRequirement(s.requirements, "blob", "kitten", "Kitten", 1);
		AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingot", 4);
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 50);
		AddRequirement(s.requirements, "blob", "mat_plasteel", "Plasteel Sheet", 50);
		s.spawnNothing = true;
    }
	{
	    ShopItem@ s = addShopItem(this, "Pheromones", "$pheromones$", "pheromones", "Mysterious pheromones.");
		AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingot", 8);
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 150);
		AddRequirement(s.requirements, "blob", "lifematter", "Life Matter", 1);
		AddRequirement(s.requirements, "blob", "energymatter", "Energy Matter", 1);
		s.spawnNothing = true;
    }
	{
		ShopItem@ s = addShopItem(this, "Advanced Engineer", "$advancedengineertools$", "advancedengineertools", "A better engineer");
		AddRequirement(s.requirements, "blob", "mat_plasteel", "Plasteel Sheet", 50);
		AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingot", 4);
		s.spawnNothing = true;
	}
	{
	    ShopItem@ s = addShopItem(this, "Laser Sniper Rifle", "$lasersniper$", "lasersniper", "A very strong sniper rifle.");
		AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingot", 20);
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 250);
		AddRequirement(s.requirements, "blob", "lifematter", "Life Matter", 1);
		AddRequirement(s.requirements, "blob", "energymatter", "Energy Matter", 3);
		s.spawnNothing = true;
    }
	{
	    ShopItem@ s = addShopItem(this, "Laser Shotgun", "$lasershotgun$", "lasershotgun", "A short-ranged weapon with high damage and low firerate.");
		AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingot", 20);
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 250);
		AddRequirement(s.requirements, "blob", "lifematter", "Life Matter", 3);
		AddRequirement(s.requirements, "blob", "energymatter", "Energy Matter", 1);
		s.spawnNothing = true;
    }
	{
	    ShopItem@ s = addShopItem(this, "Laser Rifle", "$laserrifle$", "laserrifle", "Automatical rifle with weaker damage and good firerate.");
		AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingot", 15);
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 200);
		AddRequirement(s.requirements, "blob", "lifematter", "Life Matter", 2);
		AddRequirement(s.requirements, "blob", "energymatter", "Energy Matter", 1);
		s.spawnNothing = true;
    }
	{
	    ShopItem@ s = addShopItem(this, "Blaster", "$blaster$", "blaster", "Automatical blaster with medium damage and low firerate.");
		AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingot", 15);
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 150);
		AddRequirement(s.requirements, "blob", "lifematter", "Life Matter", 1);
		AddRequirement(s.requirements, "blob", "energymatter", "Energy Matter", 2);
		s.spawnNothing = true;
    }
}

void addTokens(CBlob@ this)
{
    AddIconToken("$icon_plasteel$", "Material_Plasteel.png", Vec2f(16, 16), 0);
	AddIconToken("$lifematter$", "LifeMatter.png", Vec2f(7, 13), 0);
	AddIconToken("$energymatter$", "EnergyMatter.png", Vec2f(7, 9), 0);
	AddIconToken("$pheromones$", "Pheromones.png", Vec2f(5, 7), 0);
	AddIconToken("$mat_wilmet$", "Material_Wilmet.png", Vec2f(16, 16), 0);
	AddIconToken("$advancedengineertools$", "AdvancedEngineerTools.png", Vec2f(16, 16), 0);
	AddIconToken("$lasersniper$", "LaserSniperRifle.png", Vec2f(35, 7), 0);
	AddIconToken("$lasershotgun$", "LaserShotgun.png", Vec2f(20, 6), 0);
	AddIconToken("$laserrifle$", "LaserRifle.png", Vec2f(21, 6), 0);
	AddIconToken("$blaster$", "Blaster.png", Vec2f(24, 8), 0);
}	



void onChangeTeam(CBlob@ this, const int oldTeam)
{
	// reset shop colors
	addTokens(this);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	this.set_bool("shop available", (caller.getPosition() - this.getPosition()).Length() < 64.0f);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/MolecularFabricator_Create.ogg");

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
			else if(spl[0] == "scyther")
			{
				CBlob@ crate = server_MakeCrate("scyther", "Scyther Construction Kit", 0, callerBlob.getTeamNum(), this.getPosition(), false);
				crate.Tag("plasteel");
				crate.Init();

				callerBlob.server_Pickup(crate);
			}
			else if (spl[0] == "molecularfabricator")
			{
				CBlob@ crate = server_MakeCrate("molecularfabricator", "Molecular Fabricator Construction Kit", 0, callerBlob.getTeamNum(), this.getPosition(), false);
				crate.Tag("plasteel");
				crate.Init();

				callerBlob.server_Pickup(crate);
			}
			else if (spl[0] == "coilgun")
			{
				CBlob@ crate = server_MakeCrate("coilgun", "Coilgun Construction Kit", 0, callerBlob.getTeamNum(), this.getPosition(), false);
				crate.Tag("plasteel");
				crate.Init();

				callerBlob.server_Pickup(crate);
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

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic() && blob.isCollidable();
}