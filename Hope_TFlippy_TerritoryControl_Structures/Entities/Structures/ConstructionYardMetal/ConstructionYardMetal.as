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
	this.set_Vec2f("shop menu size", Vec2f(10, 10));
	this.set_string("shop description", "Buy");
	this.set_u8("shop icon", 25);

	
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

	AddIconToken("$uav_icon$", "UAV.png", Vec2f(56, 24), 0, teamnum);
	AddIconToken("$jetfighter$", "JetFighter.png", Vec2f(80, 32), 0, teamnum);
	AddIconToken("$helichopper$", "Helichopper.png", Vec2f(80, 40), 0, teamnum);

	{
		ShopItem@ s = addShopItem(this, "Armored Bomber", "$icon_armoredbomber$", "armoredbomber", "$icon_armoredbomber$\n\n\n\n\n\n\n\n" + "A fortified but slow moving balloon with an iron basket and two attachment slots. Resistant against gunfire.\n[Space] to drop items out of inventory.", false, true);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 250);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 16);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 8);
		AddRequirement(s.requirements, "coin", "", "Coins", 750);

		s.crate_icon = 13;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 4;
	}
	{
		ShopItem@ s = addShopItem(this, "Cargo Container", "$icon_cargocontainer$", "cargocontainer", "$icon_cargocontainer$\n\n\n\n" + "A large shipping container with a huge storage capacity.\n\nCan be moved around by vehicles.\nActs as a remote inventory.", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 16);

		s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Jet Fighter", "$jetfighter$", "jetfighter", "$jetfighter$\n\n\n" + "", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 32);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 20);
		AddRequirement(s.requirements, "coin", "", "Coins", 3000);

		s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Charge Drill", "$chargedrill$", "chargedrill", "$chargedrill$\n\n\n\n\n" + "A giant drill that is capable to dig giant tunnels and omoron heartstones.\nYou can roll it while driving, press [DOWN] button.\nYou can reverse modes while driving, press [SPACEBAR] button.", false, false);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 24);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 20);
		AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingot", 12);
		AddRequirement(s.requirements, "blob", "mat_copperwire", "Copper Wire", 40);
		AddRequirement(s.requirements, "coin", "", "Coins", 1750);

		//s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Helichopper", "$helichopper$", "helichopper", "$helichopper$\n\n\n\n\nBoss-helicopter!" + "", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 32);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 48);
		AddRequirement(s.requirements, "blob", "mat_copperwire", "Copper Wire", 100);
		AddRequirement(s.requirements, "coin", "", "Coins", 5000);

		s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Drone\n\nRequres batteries to fly.", "$uav_icon$", "uav", "$uav$\n\n\n\nRemotely controlled drone, with a machinegun on its hull and controller." + "", false, false);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 16);
		AddRequirement(s.requirements, "blob", "mat_copperwire", "Copper Wire", 20);
		AddRequirement(s.requirements, "coin", "", "Coins", 1000);

		s.customButton = true;
		s.buttonwidth = 3;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Journalist copter", "$jourcopicon$", "jourcop", "$jourcopicon$\n\n\n\n\n\nWatch the battlefield dramas, but don't forget about the *birdies*!", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 28);
		AddRequirement(s.requirements, "blob", "mat_copperwire", "Copper Wire", 20);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);

		s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 3;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Gunship", "$gunshipicon$", "gunship", "$gunshipicon$\n\n\n\n\n\n\n\nA massive ship with an incendiary mortar on its nose.", false, true);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 64);
		AddRequirement(s.requirements, "blob", "mat_titaniumingot", "Titanium Ingot", 32);
		AddRequirement(s.requirements, "coin", "", "Coins", 1500);

		s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 4;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "Zeppelin", "$icon_zeppelin$", "zepplin", "$icon_zeppelin$\n\n\n\n\n\n\n\n\n\n\n" + "A large zeppelin.\n\nYou can shoot from gatling gun.\nUses gatling ammo on the first inventory slot.", false, false);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 48);
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 16);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 1000);
		AddRequirement(s.requirements, "coin", "", "Coins", 1500);

		//s.crate_icon = 0;
		s.customButton = true;
		s.buttonwidth = 10;
		s.buttonheight = 4;
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
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
