// ArcherShop.as

#include "MakeCrate.as";
#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";
#include "MakeSeed.as";

Random traderRandom(Time());

const u16 MAX_CHICKENS_ON_MAP = 32;

void onInit(CBlob@ this)
{
	AddIconToken("$ss_badger$", "SS_Icons.png", Vec2f(32, 16), 0);
	AddIconToken("$ss_scout_raid$", "SS_Icons.png", Vec2f(16, 16), 2);
	AddIconToken("$ss_minefield$", "SS_Icons.png", Vec2f(16, 16), 3);
	AddIconToken("$ss_soldier_raid$", "SS_Icons.png", Vec2f(16, 16), 4);
	AddIconToken("$ss_guns$", "SS_Icons.png", Vec2f(32, 16), 3);
	AddIconToken("$ss_ammo$", "SS_Icons.png", Vec2f(32, 16), 4);
	AddIconToken("$ss_sam$", "SS_Icons.png", Vec2f(32, 24), 4);
	AddIconToken("$ss_lws$", "SS_Icons.png", Vec2f(32, 24), 5);
	AddIconToken("$ss_machinegun$", "SS_Icons.png", Vec2f(32, 24), 6);
	AddIconToken("$ss_chickentank$", "SS_Icons.png", Vec2f(32, 16), 11);
	AddIconToken("$ohno$", "MiniNuke.png", Vec2f(9, 16), 0);
	AddIconToken("$arty10$", "SS_Icons_Barrage.png", Vec2f(16, 16), 0);
	AddIconToken("$arty25$", "SS_Icons_Barrage.png", Vec2f(16, 16), 1);

	this.getCurrentScript().tickFrequency = 1;
	
	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(4, 6));
	this.set_string("shop description", "SpaceStar Ordering!");
	this.set_u8("shop icon", 11);
	
	this.Tag(SHOP_AUTOCLOSE);
	
	{
		ShopItem@ s = addShopItem(this, "Wonderful Fluffy UPF Badger!", "$ss_badger$", "badger-parachute", "Every child's dream! Don't hesitate and get your own Wonderful Fluffy Badger!");
		AddRequirement(s.requirements, "coin", "", "Coins", 199);
		
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "UPF Recon Squad!", "$ss_scout_raid$", "scout_raid", "Have you lost something? Order our willing recon squad, and you will sure find what you're looking for!\nSoldiers are limited!");
		AddRequirement(s.requirements, "coin", "", "Coins", 2599);
		
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "UPF Assault Squad!", "$ss_soldier_raid$", "soldier_raid", "Get your own soldier... TODAY!\nSoldiers are limited!");
		AddRequirement(s.requirements, "coin", "", "Coins", 4899);
		
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "UPF Weapon Package!", "$ss_guns$", "gun_package", "Assorted gun collection! Become a proud owner of UPF's best-selling armaments, now with a huge discount!");
		AddRequirement(s.requirements, "coin", "", "Coins", 8999);
		
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "UPF Ammunition Package!", "$ss_ammo$", "ammo_package", "Surrounded by enemies? Dump some ammunition in them!");
		AddRequirement(s.requirements, "coin", "", "Coins", 599);
		
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "UPF Portable Minefield!", "$ss_minefield$", "minefield", "A brave flock of landmines! No more trespassers!");
		AddRequirement(s.requirements, "coin", "", "Coins", 799);
		
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "UPF Frag Grenades!", "$fraggrenade$", "frag_package", "Angry at humans? Throw a pack of frag grenades at them!");
		AddRequirement(s.requirements, "coin", "", "Coins", 999);
		
		s.spawnNothing = true;
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
	}
	{
		ShopItem@ s = addShopItem(this, "UPF Artillery Barrage! (x10)", "$arty10$", "bombardment-barrage-10", "When things go awry, there's still an option to shell it to oblivion. You will get 10 artillery shots.\nNeeds you to be the UPF Department Store co-leader.");
		AddRequirement(s.requirements, "coin", "", "Coins", 12999);
		s.spawnNothing = true;
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
	}
	{
		ShopItem@ s = addShopItem(this, "UPF Artillery Barrage! (x25)", "$arty25$", "bombardment-barrage-25", "When things go awry, there's still an option to shell it to oblivion. You will get 25 artillery shots with a 25% discount!\nNeeds you to be the UPF Department Store co-leader.");
		AddRequirement(s.requirements, "coin", "", "Coins", 24999);
		s.spawnNothing = true;
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
	}
	{
		ShopItem@ s = addShopItem(this, "UPF Portable Machine Gun!", "$ss_machinegun$", "machinegun-parachute_no_unpack", "Humans disturbing your precious sleep? Mow them down with our Portable Machine Gun!");
		AddRequirement(s.requirements, "coin", "", "Coins", 2299);
		
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "UPF Tank!", "$ss_chickentank$", "chickentank-parachute_no_unpack", "Tired of humans shooting you in face? Drop a tank onto them!");
		AddRequirement(s.requirements, "coin", "", "Coins", 5999);
		
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "UPF Portable SAM System!", "$ss_sam$", "sam-parachute_no_unpack", "A portable surface-to-air missile system used to shoot down aerial targets. Automatically operated!");
		AddRequirement(s.requirements, "coin", "", "Coins", 4499);
		
		s.spawnNothing = true;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	{
		ShopItem@ s = addShopItem(this, "UPF Portable LWS!", "$ss_lws$", "lws-parachute_no_unpack", "A portable laser weapon system capable of shooting down airborne projectiles. Automatically operated!");
		AddRequirement(s.requirements, "coin", "", "Coins", 3999);
		
		s.spawnNothing = true;
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 2;
	}
	/*
	{
		ShopItem@ s = addShopItem(this, "Not a very good idea...", "$ohno$", "nukevent", "UPF transmitters are used to be connected throughout UPF servers, but a good technician always knows a solution!");
		AddRequirement(s.requirements, "coin", "", "Coins", 31999);
		AddRequirement(s.requirements, "blob", "mat_goldingot", "Gold ingot", 500);
		AddRequirement(s.requirements, "blob", "mat_copperwire", "Copper Wire", 400);
		AddRequirement(s.requirements, "blob", "mat_dirt", "Dirt", 1000);
		AddRequirement(s.requirements, "blob", "wrench", "Wrench", 4);
		s.spawnNothing = true;
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
	}
	*/
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if(cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound(XORRandom(100) > 50 ? "/ss_order.ogg" : "/ss_shipment.ogg");
		
		u16 caller, item;
		
		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;
		
		string name = params.read_string();
		CBlob@ callerBlob = getBlobByNetworkID(caller);
		
		if (callerBlob is null) return;
		
		if (isServer())
		{
			string[] spl = name.split("-");

			if (spl.length > 1)
			{
				if (spl[1] == "parachute")
				{
					CBlob@ blob = server_MakeCrateOnParachute(spl[0], "SpaceStar Ordering Goods", 0, this.getTeamNum(), Vec2f(callerBlob.getPosition().x, 0));
					blob.Tag("unpack on land");
				}
				else if (spl[1] == "parachute_no_unpack")
				{
					CBlob@ blob = server_MakeCrateOnParachute(spl[0], "SpaceStar Ordering Goods", 0, this.getTeamNum(), Vec2f(callerBlob.getPosition().x, 0));
				}
				else if (spl[1] == "barrage")
				{
					u16 amount;
					if (spl.length > 2) amount = parseFloat(spl[2]);
					CPlayer@ ownerPlayer = callerBlob.getPlayer();
					if (ownerPlayer !is null)
					{
						CBlob@[] markets;
						getBlobsByTag("chickenmarket", markets);
						bool stop = true;
						for (u16 i = 0; i < markets.length; i++)
						{
							CBlob@ market = markets[i];
							if (market is null) continue;
							if (market.get_string("shop_owner") == ownerPlayer.getUsername())
								stop = false; // make it pass if it matches at least one shop
						}
						if (stop && this.getSprite() !is null)
						{
							this.getSprite().PlaySound(XORRandom(100) > 50 ? "ss_order.ogg" : "/ss_shipment.ogg", 1.0f, 1.3f);
						}
						if (stop && isServer())
						{
							if (amount < 20) ownerPlayer.server_setCoins(ownerPlayer.getCoins()+12999);
							else ownerPlayer.server_setCoins(ownerPlayer.getCoins()+24999);
							return;
						}
					}
					else return;
					CBlob@ b = server_CreateBlobNoInit("bombardment");
					b.server_setTeamNum(250);
					b.setPosition(this.getPosition());

					client_AddToChat("" + ownerPlayer.getCharacterName() + " has called an artillery strike!", SColor(255, 255, 100, 0));
					
					b.set_u8("max shots fired", parseInt(spl[2]));
					b.set_u32("delay between shells", 30);
					b.set_string("shell blob", "chickencannonshell");
					
					b.Init();
				}
			}
			else
			{
				string name = spl[0];
				if (name == "scout_raid")
				{
					CBlob@[] chickens;
					getBlobsByTag("chicken", chickens);

					u16 chickens_quantity = 0;
					for (u16 i = 0; i < chickens.length; i++)
					{
						if (chickens[i] !is null && !chickens[i].hasTag("dead")
						&& chickens[i].getCarriedBlob() !is null && chickens[i].getCarriedBlob().hasTag("weapon")) chickens_quantity++;
					}

					if (chickens_quantity > MAX_CHICKENS_ON_MAP + (getPlayerCount()*2))
					{
						if (callerBlob !is null && isServer())
						{
							CPlayer@ p = callerBlob.getPlayer();
							if (p !is null)
							{
								p.server_setCoins(p.getCoins()+2099);
								return;
							}
						}
					}
					for (int i = 0; i < 4; i++)
					{
						CBlob@ blob = server_MakeCrateOnParachute("scoutchicken", "SpaceStar Ordering Recon Squad", 0, 250, Vec2f(callerBlob.getPosition().x + (64 - XORRandom(128)), XORRandom(32)));
						blob.Tag("unpack on land");
						blob.Tag("destroy on touch");
					}
				}
				else if (name == "soldier_raid")
				{
					CBlob@[] chickens;
					getBlobsByTag("chicken", chickens);

					u16 chickens_quantity = 0;
					for (u16 i = 0; i < chickens.length; i++)
					{
						if (chickens[i] !is null && !chickens[i].hasTag("dead")
						&& chickens[i].getCarriedBlob() !is null && chickens[i].getCarriedBlob().hasTag("weapon")) chickens_quantity++;
					}

					if (chickens_quantity > MAX_CHICKENS_ON_MAP + (getPlayerCount()*2))
					{
						if (callerBlob !is null && isServer())
						{
							CPlayer@ p = callerBlob.getPlayer();
							if (p !is null)
							{
								p.server_setCoins(p.getCoins()+4099);
								return;
							}
						}
					}
					for (int i = 0; i < 4; i++)
					{
						CBlob@ blob = server_MakeCrateOnParachute("soldierchicken", "SpaceStar Ordering Assault Squad", 0, 250, Vec2f(callerBlob.getPosition().x + (64 - XORRandom(128)), XORRandom(32)));
						blob.Tag("unpack on land");
						blob.Tag("destroy on touch");
					}
				}
				else if (name == "minefield")
				{
					for (int i = 0; i < 10; i++)
					{
						CBlob@ blob = server_MakeCrateOnParachute("mine", "SpaceStar Ordering Mines", 0, 250, Vec2f(callerBlob.getPosition().x + (256 - XORRandom(512)), XORRandom(64)));
						blob.Tag("unpack on land");
						blob.Tag("destroy on touch");
					}
				}
				else if (name == "frag_package")
				{
						CBlob@ frag = server_MakeCrateOnParachute("mat_fraggrenade", "SpaceStar Ordering Weapon Package", 0, 250, Vec2f(callerBlob.getPosition().x + (64 - XORRandom(128)), XORRandom(32)));
						frag.Tag("unpack on land");
						frag.Tag("destroy on touch");
						frag.set_u8("count", 8);
				}
				else if (name == "gun_package")
				{
					for (int i = 0; i < 3; i++)
					{
						string gun_config;
					
						switch (XORRandom(14))
						{
							case 0:
							{
								gun_config = "beagle";
							}
							break;
							
							case 1:
							{
								gun_config = "carbine";
							}
							break;
							
							case 2:
							{
								gun_config = "assaultrifle";
							}
							break;
							
							case 3:
							{
								gun_config = "silencedrifle";
							}
							break;
							
							case 4:
							{
								gun_config = "napalmer";
							}
							break;
							
							case 5:
							{
								gun_config = "autoshotgun";
							}
							break;
							
							case 6:
							{
								gun_config = "fuger";
							}
							break;
							
							case 7:
							{
								gun_config = "pdw";
							}
							break;
							
							case 8:
							{
								gun_config = "sar";
							}
							break;
							
							case 9:
							{
								gun_config = "sniper";
							}
							break;
							
							case 10:
							{
								gun_config = "uzi";
							}
							break;
							
							case 11:
							{
								gun_config = "sgl";
							}
							break;
							
							case 12:
							{
								gun_config = "rpg";
							}
							break;
							
							case 13:
							{
							    if (XORRandom(100) < 5)
							    {
								    switch (XORRandom(2))
							        {
									    case 0:
									    {
									     gun_config = "amr";
									    }
									    break;
									
									    case 1:
									    {
										 gun_config = "minigun";
									    }
									    break;
									}  
							    }
							}  
							break;
						}
						
						CBlob@ gun = server_MakeCrateOnParachute(gun_config, "SpaceStar Ordering Weapon Package", 0, 250, Vec2f(callerBlob.getPosition().x + (64 - XORRandom(128)), XORRandom(32)));
						gun.Tag("unpack on land");
						gun.Tag("destroy on touch");
					}
				}
				else if (name == "ammo_package")
				{
					for (int i = 0; i < 5; i++)
					{
						string ammo_config;
						u32 ammo_count;
					
						switch (i)
						{
							case 0:							
							{
								ammo_config = "mat_gatlingammo";
								ammo_count = 500;
							}
							break;
							
							case 1:
							{
								ammo_config = "mat_rifleammo";
								ammo_count = 300;
							}
							break;
							
							case 2:
							{
								ammo_config = "mat_pistolammo";
								ammo_count = 400;
							}
							break;
							
							case 3:
							{
								ammo_config = "mat_shotgunammo";
								ammo_count = 120;
							}
							break;

							case 4:
							{
								ammo_config = "mat_sniperammo";
								ammo_count = 50;
							}
							break;

						}
						
						CBlob@ ammo = server_MakeCrateOnParachute(ammo_config, "SpaceStar Ordering Weapon Package", 0, 250, Vec2f(callerBlob.getPosition().x + (64 - XORRandom(128)), XORRandom(32)));
						ammo.Tag("unpack on land");
						ammo.Tag("destroy on touch");
						ammo.set_u8("count", ammo_count);
					}
				}
				else if (name == "nukevent")
				{
					CBitStream params;
					getRules().SendCommand(getRules().getCommandID("callputin"), params);
				}
				else
				{
					print("rip " + spl[0]);
				}
			}
		}

		this.set_bool("shop available", false);
		this.set_u32("next use", getGameTime() + 300);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @ap)
{
	this.getSprite().PlaySound("/ss_hello.ogg");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	this.set_Vec2f("shop offset", Vec2f(0,0));
	this.set_bool("shop available", getGameTime() >= this.get_u32("next use"));
}