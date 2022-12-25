// Vehicle Workshop

#include "Requirements.as";
#include "Requirements_Tech.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "WARCosts.as";
#include "CheckSpam.as";

const s32 cost_catapult = 80;
const s32 cost_ballista = 150;
const s32 cost_ballista_ammo = 30;
const s32 cost_ballista_ammo_upgrade_gold = 60;

void onInit(CBlob@ this)
{
	this.Tag("builder always hit");
	this.Tag("change team on fort capture");

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	addTokens(this); //colored shop icons

	AddIconToken("$icon_gatlinggun$", "Icon_Vehicles.png", Vec2f(24, 24), 2);
	AddIconToken("$icon_mortar$", "Icon_Vehicles.png", Vec2f(24, 24), 3);
	AddIconToken("$icon_incendiarymortar$", "IncendiaryMortar_Icon.png", Vec2f(24, 24), 0);
	AddIconToken("$icon_howitzer$", "Icon_Vehicles.png", Vec2f(24, 24), 4);
	AddIconToken("$icon_zeppelin$", "Zepplin.png", Vec2f(181, 90), 0);
	AddIconToken("$icon_autocannon$", "AutocannonIcon.png", Vec2f(96, 48), 0);

	AddIconToken("$mat_ironingot$", "Material_IronIngot.png", Vec2f(16, 16), 1);
	AddIconToken("$antiair", "AntiAC_top.png", Vec2f(32, 16), 3);

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 8));
	this.set_Vec2f("shop menu size", Vec2f(12, 16));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	{
		ShopItem@ s = addShopItem(this, "Catapult", "$icon_catapult$", "catapult", "$catapult$\n\n\n" + descriptions[5], false, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200);
		AddRequirement(s.requirements, "coin", "", "Coins", 100);

		s.crate_icon = 4;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Ballista", "$icon_ballista$", "ballista", "$ballista$\n\n\n" + descriptions[6], false, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 500);
		AddRequirement(s.requirements, "coin", "", "Coins", 300);

		s.crate_icon = 5;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Steam Tank", "$icon_steamtank$", "steamtank", "$icon_steamtank$\n\n\n" + "An armored land vehicle. Comes with a powerful cannon and a durable ram.", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 20);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 10);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 250);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);

		s.crate_icon = 7;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	// {
		// ShopItem@ s = addShopItem(this, "Ballista Ammo", "$mat_bolts$", "mat_bolts", "$mat_bolts$\n\n\n" + descriptions[15], false, false);
		// s.crate_icon = 5;
		// s.customButton = true;
		// s.buttonwidth = 2;
		// s.buttonheight = 2;
		// AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 160);
		// AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 80);
	// }
	{
		ShopItem@ s = addShopItem(this, "Dinghy", "$icon_dinghy$", "dinghy", "$dinghy$\n\n\n" + descriptions[10]);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "coin", "", "Coins", 30);

		s.spawnNothing = true;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	// {
		// ShopItem@ s = addShopItem(this, "Buoy", "$buoy_icon$", "buoy", "Useful for anchoring.");
		// AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		// AddRequirement(s.requirements, "blob", "mat_gold", "Gold", 100);
		// AddRequirement(s.requirements, "blob", "mat_stone", "Stone", 100);
		// s.spawnNothing = true;
	// }
	{
		ShopItem@ s = addShopItem(this, "Longboat", "$icon_longboat$", "longboat", "$longboat$\n\n\n" + descriptions[33], false, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 200);
		AddRequirement(s.requirements, "coin", "", "Coins", 120);

		s.crate_icon = 1;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "War Boat", "$icon_warboat$", "warboat", "$warboat$\n\n\n" + descriptions[37], false, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 500);
		AddRequirement(s.requirements, "coin", "", "Coins", 200);

		s.crate_icon = 2;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Machine Gun", "$icon_gatlinggun$", "gatlinggun", "Useful for making holes.", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 16);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 8);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 150);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);

		s.crate_icon = 11;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Autocannon", "$icon_autocannon$", "autocannon", "A slow and sturdy wooden monstrosity.", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 24);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 1000);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);

		s.crate_icon = 11;
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Bomber", "$icon_bomber$", "bomber", "$icon_bomber$\n\n\n\n\n\n\n\n" + "A large aerial vehicle used for safe transport and bombing the peasants below.\n[Space] to drop items out of inventory.", false, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 250);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);

		s.crate_icon = 13;
		s.customButton = true;
		s.buttonwidth = 3;
		s.buttonheight = 4;
	}
	{
		ShopItem@ s = addShopItem(this, "Armored Bomber", "$icon_armoredbomber$", "armoredbomber", "$icon_armoredbomber$\n\n\n\n\n\n\n\n" + "A fortified but slow moving balloon with an iron basket and two attachment slots. Resistant against gunfire.\n[Space] to drop items out of inventory.", false, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 450);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 20);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 16);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);

		s.crate_icon = 13;
		s.customButton = true;
		s.buttonwidth = 3;
		s.buttonheight = 4;
	}
	{
		ShopItem@ s = addShopItem(this, "Mortar", "$icon_mortar$", "mortar", "Mortar combat!", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 12);
		AddRequirement(s.requirements, "coin", "", "Coins", 250);

		s.crate_icon = 3;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Rocket Launcher", "$icon_rocketlauncher$", "rocketlauncher", "A rapid-fire rocket launcher especially useful against aerial targets.", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 12);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 375);
		AddRequirement(s.requirements, "coin", "", "Coins", 350);

		s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Howitzer", "$icon_howitzer$", "howitzer", "Mortar's bigger brother.", false, true);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 16);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 175);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);

		s.crate_icon = 12;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	//{
		//ShopItem@ s = addShopItem(this, "Anti-air turret", "$antiair$", "antiair", "A strong machinegun, that is very useful against aerial targets.", false, true);
		//AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 24);
		//AddRequirement(s.requirements, "blob", "mat_steelingot", "Iron Ingot", 8);
		//AddRequirement(s.requirements, "coin", "", "Coins", 500);

		//s.crate_icon = 0;
		//s.customButton = true;
		//s.buttonwidth = 2;
		//s.buttonheight = 2;
	//}
	{
		ShopItem@ s = addShopItem(this, "Spotter Airplane", "$icon_triplane$", "triplane", "$icon_triplane$\n\n\n\n" + "A fast airplane used for scouting and light bombing.\n\n[W]/[D] to accelerate\n[LMB] to shoot\n[Space] to drop items out of inventory\n[C] to leave", false, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 250);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 6);
		AddRequirement(s.requirements, "coin", "", "Coins", 250);

		s.crate_icon = 14;
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Cargo Container", "$icon_cargocontainer$", "cargocontainer", "$icon_cargocontainer$\n\n\n\n" + "A large shipping container with a huge storage capacity.\n\nCan be moved around by vehicles.\nActs as a remote inventory.", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 16);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);

		s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Minicopter", "$icon_minicopter$", "minicopter", "$icon_minicopter$\n\n\n\n\n" + "A fast helicopter used for scouting and transport.\n\n[W]/[S] for vertical throttle, [A]/[D] for horizontal throttle.", false, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 300);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 16);
		AddRequirement(s.requirements, "blob", "mat_copperwire", "Copper Wire", 20);
		AddRequirement(s.requirements, "coin", "", "Coins", 750);

		s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Jet Fighter!", "$jetfighter$", "jetfighter", "$jetfighter$\n\n\n" + "", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 32);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 20);
		AddRequirement(s.requirements, "coin", "", "Coins", 3000);

		s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Drone!\n\nRequres batteries to fly.", "$uav_icon$", "uav", "$uav$\n\n\n\nRemotely controlled drone, with a machinegun on its hull and controller." + "", false, false);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 16);
		AddRequirement(s.requirements, "blob", "mat_copperwire", "Copper Wire", 30);
		AddRequirement(s.requirements, "coin", "", "Coins", 1500);

		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Helichopper", "$helichopper$", "helichopper", "$helichopper$\n\n\n\n\nBoss-helicopter!" + "", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 50);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 40);
		AddRequirement(s.requirements, "blob", "mat_copperwire", "Copper Wire", 100);
		AddRequirement(s.requirements, "coin", "", "Coins", 7500);

		s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 2;
	}
	/*
	{
		ShopItem@ s = addShopItem(this, "Incendiary Mortar", "$icon_incendiarymortar$", "incendiarymortar", "Trenches won't save you....", false, true);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Iron Ingot", 24);
		AddRequirement(s.requirements, "coin", "", "Coins", 1000);

		s.crate_icon = 3;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	*/	
	{
		ShopItem@ s = addShopItem(this, "Charge Drill", "$chargedrill$", "chargedrill", "$chargedrill$\n\n\n\n\n" + "A giant drill that is capable to dig giant tunnels.\nYou can roll it while driving, press [DOWN] button.\nYou can reverse modes while driving, press [SPACEBAR] button.", false, false);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 24);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 20);
		AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingot", 12);
		AddRequirement(s.requirements, "blob", "mat_copperwire", "Copper Wire", 40);
		AddRequirement(s.requirements, "coin", "", "Coins", 1750);

		//s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 3;
	}
	{
		ShopItem@ s = addShopItem(this, "Journalist copter", "$jourcopicon$", "jourcop", "$jourcopicon$\n\n\n\n\n\nWatch the battlefield dramas, but don't forget about the *birdies*!", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 28);
		AddRequirement(s.requirements, "blob", "mat_titaniumingot", "Titanium Ingot", 6);
		AddRequirement(s.requirements, "blob", "mat_copperwire", "Copper Wire", 40);
		AddRequirement(s.requirements, "coin", "", "Coins", 1500);

		s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 3;
	}
	{
		ShopItem@ s = addShopItem(this, "Gunship", "$gunshipicon$", "gunship", "$gunshipicon$\n\n\n\n\n\n\n\nA massive ship with an incendiary mortar on its nose.", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 80);
		AddRequirement(s.requirements, "blob", "mat_titaniumingot", "Titanium Ingot", 32);
		AddRequirement(s.requirements, "coin", "", "Coins", 1500);

		s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 3;
	}
	{
		ShopItem@ s = addShopItem(this, "Zeppelin", "$icon_zeppelin$", "zepplin", "$icon_zeppelin$\n\n\n\n\n\n\n\n\n\n\n" + "A large zeppelin.\n\nYou can shoot from gatling gun.\nUses gatling ammo on the first inventory slot.", false, false);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 48);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 24);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 1250);
		AddRequirement(s.requirements, "coin", "", "Coins", 3000);

		//s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 12;
		s.buttonheight = 3;
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

	AddIconToken("$icon_catapult$", "VehicleIcons.png", Vec2f(32, 32), 0, teamnum);
	AddIconToken("$icon_ballista$", "VehicleIcons.png", Vec2f(32, 32), 1, teamnum);
	AddIconToken("$icon_warboat$", "VehicleIcons.png", Vec2f(32, 32), 2, teamnum);
	AddIconToken("$icon_longboat$", "VehicleIcons.png", Vec2f(32, 32), 4, teamnum);
	AddIconToken("$icon_dinghy$", "VehicleIcons.png", Vec2f(32, 32), 5, teamnum);

	AddIconToken("$icon_bomber$", "Icon_Bomber.png", Vec2f(64, 64), 0, teamnum);
	AddIconToken("$icon_armoredbomber$", "Icon_ArmoredBomber.png", Vec2f(64, 64), 0, teamnum);
	AddIconToken("$icon_triplane$", "Icon_Triplane.png", Vec2f(64, 32), 0, teamnum);
	AddIconToken("$icon_steamtank$", "Icon_Vehicles.png", Vec2f(48, 24), 0, teamnum);
	AddIconToken("$icon_rocketlauncher$", "Icon_Vehicles.png", Vec2f(24, 24), 5, teamnum);
	AddIconToken("$icon_cargocontainer$", "CargoContainer.png", Vec2f(64, 24), 0, teamnum);
	AddIconToken("$icon_minicopter$", "minicopter_icon.png", Vec2f(64, 32), 0, teamnum);
	AddIconToken("$jourcopicon$", "JourcopIcon.png", Vec2f(80, 40), 0, teamnum);
	AddIconToken("$gunshipicon$", "GunshipIcon.png", Vec2f(80, 64), 0, teamnum);

	AddIconToken("$uav_icon$", "UAV.png", Vec2f(64, 24), 0, teamnum);
	AddIconToken("$jetfighter$", "JetFighter.png", Vec2f(80, 32), 0, teamnum);
	AddIconToken("$helichopper$", "Helichopper.png", Vec2f(80, 40), 0, teamnum);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	this.set_bool("shop available", this.isOverlapping(caller));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/ChaChing.ogg");
		u16 caller, item;
		if (!params.saferead_netid(caller) || !params.saferead_netid(item))
		{
			return;
		}
		string name = params.read_string();
		if (isServer())
		{
			if (name == "dinghy")
			{
				server_CreateBlob("dinghy", this.getTeamNum(), this.getPosition());
			}
		}
	}
}

void onInit(CSprite@ this)
{
	this.SetZ(50); //foreground

	CBlob@ blob = this.getBlob();
	CSpriteLayer@ planks = this.addSpriteLayer("planks", this.getFilename() , 64, 56, blob.getTeamNum(), blob.getSkinNum());

	if (planks !is null)
	{
		Animation@ anim = planks.addAnimation("default", 0, false);
		anim.AddFrame(1);
		planks.SetOffset(Vec2f(0.0f, 0.0f));
		planks.SetRelativeZ(-100);
	}
}
