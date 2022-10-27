// A script by Skemonde

#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";
#include "MaterialCommon.as";

Random traderRandom(Time());


const string[] for_sale =
{
	//advanced
	"bnak",
	"svd",
	"grenadelauncher",
	"gaussrifle",
	"flamethrower",
	"blazethrower",
	"acidthrower",
	"mininukelauncher",
	"rp46",
	"tkb521",
	
	//chicken guns
	"amr",
	"assaultrifle",
	"autoshotgun",
	"beagle",
	"fuger",
	"carbine",
	"sniper",
	"minigun",
	"pdw",
	"rekt",
	"silencedrifle",
	"sgl",
	"sar",
	"rpg",
	"uzi",
	"napalmer",
	"msgl",
	"macrogun",
	
	//alienshit
	"callahan",
	"chargeblaster",
	"chargelance",
	"chargepistol",
	"chargerifle",
	"infernocannon",
	"oof",
	
	//special guns
	"taser",
	"rpc",
	"zatniktel",
	"raygun",
	"rendezook",
	"dartgun",
	"blaster",
	
	//MTC guns
	"cock",
	"cockl",
	"tar",
	"tarl",
	"xm",
	"xmas",
	"c96",
	"m712",
	"silencedak",
	"bamr",
	"ruhm",
	"cricket",
	"laserrifle",
	"lasershotgun",
	"lasersniper"	
};

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
	this.Tag("extractable");

	this.addCommandID("selling_guns");
	this.addCommandID("state");
	
	this.getCurrentScript().tickFrequency = 30;
	bool state = this.get_bool("state");
	
	//prices
	
	//banditshit
	this.set_u8("banditrifle", 1);
	this.set_u8("puntgun", 10);
	
	//basic guns
	this.set_u8("revolver", 1);
	this.set_u8("smg", 1);
	this.set_u8("rifle", 2);
	this.set_u8("leverrifle", 2);
	this.set_u8("shotgun", 9);
	this.set_u8("boomstick", 4);
	this.set_u8("dp27", 21);
	
	//advanced
	this.set_u8("bazooka", 3);
	this.set_u8("bnak", 12);
	this.set_u8("svd", 22);
	this.set_u8("grenadelauncher", 4);
	this.set_u8("gaussrifle", 10);
	this.set_u8("flamethrower", 4);
	this.set_u8("blazethrower", 9);
	this.set_u8("acidthrower", 13);
	this.set_u8("mininukelauncher", 15);
	this.set_u8("rp46", 20);
	this.set_u8("tkb521", 25);
	
	//chicken guns
	this.set_u8("amr", 33);
	this.set_u8("assaultrifle", 2);
	this.set_u8("autoshotgun", 3);
	this.set_u8("beagle", 7);
	this.set_u8("fuger", 1);
	this.set_u8("carbine", 10);
	this.set_u8("sniper", 4);
	this.set_u8("minigun", 33);
	this.set_u8("pdw", 9);
	this.set_u8("rekt", 100);
	this.set_u8("silencedrifle", 3);
	this.set_u8("sgl", 33);
	this.set_u8("sar", 1);
	this.set_u8("rpg", 33);
	this.set_u8("uzi", 1);
	this.set_u8("napalmer", 33);
	this.set_u8("msgl", 3);
	this.set_u8("macrogun", 20);
	
	//alienshit
	this.set_u8("callahan", 50);
	this.set_u8("chargeblaster", 6);
	this.set_u8("chargelance", 10);
	this.set_u8("chargepistol", 2);
	this.set_u8("chargerifle", 3);
	this.set_u8("infernocannon", 9);
	this.set_u8("oof", 1);
	
	//special guns
	this.set_u8("taser", 3);
	this.set_u8("rpc", 2);
	this.set_u8("zatniktel", 50);
	this.set_u8("raygun", 2);
	this.set_u8("rendezook", 2);
	this.set_u8("dartgun", 2);
	this.set_u8("blaster", 10);
	
	//MTC guns
	this.set_u8("cock", this.get_u8("fuger") + 4);
	this.set_u8("cockl", this.get_u8("cock") + 1);
	this.set_u8("tar", this.get_u8("sar") + 6);
	this.set_u8("tarl", this.get_u8("tar") + 1);
	this.set_u8("xm", this.get_u8("assaultrifle") + 10);
	this.set_u8("xmas", this.get_u8("xm") + this.get_u8("carbine") + 48);
	this.set_u8("c96", this.get_u8("beagle") + 2);
	this.set_u8("m712", this.get_u8("c96") + this.get_u8("pdw") + 32);
	this.set_u8("silencedak", this.get_u8("bnak") + this.get_u8("silencedrifle") + 34);
	this.set_u8("bamr", this.get_u8("amr") + 47);
	this.set_u8("ruhm", 100);
	this.set_u8("cricket", 1);
	this.set_u8("laserrifle", 5);
	this.set_u8("lasershotgun", 3);
	this.set_u8("lasersniper", 10);
}

void onTick(CBlob@ this)
{
	bool isAuto = this.get_bool("state");
	
	if (isAuto) {
		CInventory@ inv = this.getInventory();
		s32 count = inv.getItemsCount();
		if (inv !is null)
		{
			for (s32 i = 0; i < for_sale.length; i++)
			{
				CBlob@ item = inv.getItem(for_sale[i]);
				if (item !is null)
				{
					if (isServer()){
						item.server_Die();
						Material::createFor(this, "mat_goldingot", this.get_u8(for_sale[i]));
					}
					if (isClient())
						this.getSprite().PlaySound("LotteryTicket_Kaching", 2.00f, 1.00f);
				}
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.isOverlapping(caller))
	{
		CButton@ button = caller.CreateGenericButton(25, Vec2f(8, 0), this, this.getCommandID("selling_guns"), "Sell guns!");
	}
	{
		bool state = this.get_bool("state");
		CBitStream params;
		params.write_bool(!state);
		
		caller.CreateGenericButton((state ? 27 : 23), Vec2f(-8, 0), this,
			this.getCommandID("state"), getTranslatedString(state ? "Make it Manual" : "Make it Automatic"), params);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || this.isAttached()) return;

	if (!blob.isAttached() && !blob.hasTag("player") && !blob.getShape().isStatic() && (blob.hasTag("weapon")))
	{
		if (isServer()) this.server_PutInInventory(blob);
		if (isClient()) this.getSprite().PlaySound("bridge_open.ogg");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("selling_guns"))
	{
		CInventory@ inv = this.getInventory();
		s32 count = inv.getItemsCount();
		if (inv !is null)
		{
			for (s32 i = 0; i < for_sale.length; i++)
			{
				CBlob@ item = inv.getItem(for_sale[i]);
				if (item !is null)
				{
					if (isServer()){
						item.server_Die();
						Material::createFor(this, "mat_goldingot", this.get_u8(for_sale[i]));
					}
					if (isClient())
						this.getSprite().PlaySound("LotteryTicket_Kaching", 2.00f, 1.00f);
				}
			}
		}
	}
	
	if (cmd == this.getCommandID("state"))
	{
		bool newState = params.read_bool();
		this.set_bool("state", newState);
		
		if (this.get_bool("state"))
		{
			this.getSprite().PlaySound("LeverToggle.ogg", 2.0f, 1.2f);
		} else {
			this.getSprite().PlaySound("LeverToggle.ogg", 2.0f, 0.8f);
		}
	}
}