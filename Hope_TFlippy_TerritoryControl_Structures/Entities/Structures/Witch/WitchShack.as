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
	this.set_u8("upkeep cap increase", 1);
	this.set_u8("upkeep cost", 0);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("change team on fort capture");
	this.addCommandID("write");
	this.Tag("can be captured by neutral");

	getMap().server_SetTile(this.getPosition(), CMap::tile_castle_back);

	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 7, Vec2f(8, 8));
	this.SetMinimapRenderAlways(true);

	AddIconToken("$mat_mithril$", "Material_Mithril.png", Vec2f(16, 16), 1);
	AddIconToken("$mat_mithrilingot$", "Material_MithrilIngot.png", Vec2f(16, 16), 1);
	AddIconToken("$card_pack$", "CardPack.png", Vec2f(9, 9), 0);
	AddIconToken("$choker_gem$", "Choker.png", Vec2f(10, 10), 0);
	AddIconToken("$bubble_gem$", "BubbleGem.png", Vec2f(10, 10), 0);

	addTokens(this); //colored shop icons

	this.getCurrentScript().tickFrequency = 30 * 5;

	// SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(3, 4));
	this.set_string("shop description", "Witch's Dilapidated Shack");
	this.set_u8("shop icon", 25);

	// {
		// ShopItem@ s = addShopItem(this, "Sell Grain (1)", "$COIN$", "coin-40", "Sell 1 Grain for 40 coins.");
		// AddRequirement(s.requirements, "blob", "grain", "Grain", 1);
		// s.spawnNothing = true;
	// }
	{
		ShopItem@ s = addShopItem(this, "Process Mithril (1)", "$mat_mithrilingot$", "mat_mithrilingot-1", "I shall remove the deadly curse from this mythical metal.");
		AddRequirement(s.requirements, "blob", "mat_mithril", "Mithril Ore", 10);
		AddRequirement(s.requirements, "coin", "", "Coins", 25);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Process Mithril (4)", "$mat_mithrilingot$", "mat_mithrilingot-4", "I shall remove the deadly curse from this mythical metal.");
		AddRequirement(s.requirements, "blob", "mat_mithril", "Mithril Ore", 40);
		AddRequirement(s.requirements, "coin", "", "Coins", 100);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Process Mithril (16)", "$mat_mithrilingot$", "mat_mithrilingot-16", "I shall remove the deadly curse from this mythical metal.");
		AddRequirement(s.requirements, "blob", "mat_mithril", "Mithril Ore", 160);
		AddRequirement(s.requirements, "coin", "", "Coins", 400);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Mystery Box", "$icon_mysterybox$", "mysterybox", "What's inside?\nInconceivable wealth, eternal suffering, upset badgers? Who knows! Only for 75 coins!");
		AddRequirement(s.requirements, "coin", "", "Coins", 75);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Companion Box", "$icon_animalbox$", "animalbox", "What's inside?\nI crammed this box with some sort of creature you may take a liking to!");
		AddRequirement(s.requirements, "blob", "grain", "Grain", 5);
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Alien box", "$icon_mysterybox$", "alienbox", "What's inside?\nOnly god knows!");
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 50);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Terdla's Bubble Gem", "$bubble_gem$", "bubblegem", "A useless pretty blue gem! May cause hiccups");
		AddRequirement(s.requirements, "blob", "pumpkin", "Pumpkin", 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Verdla's Suffocation Charm", "$choker_gem$", "choker", "A pretty green smokey gem!");
		AddRequirement(s.requirements, "blob", "mat_methane", "Methane", 50);
		AddRequirement(s.requirements, "blob", "mat_mithrilingot", "Mithril Ingots", 2);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Funny Magical Card Booster Pack", "$card_pack$", "card_pack", "A full pack of fun!");
		AddRequirement(s.requirements, "coin", "", "Coins", 30);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "A chemical book", "$t1_book$", "tips", "A book with drug and chemical laboratories tips in 3 parts.");
		AddRequirement(s.requirements, "coin", "", "Coins", 7500);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Dark Magic Scroll", "$moundscroll$", "moundscroll", "An ancient dark magic scroll.\nI offer those so many because uh, i robbered the owner!");
		AddRequirement(s.requirements, "blob", "mat_mithrilenriched", "Enriched mithril", 250);
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 50);
		AddRequirement(s.requirements, "blob", "choker", "Green gem", 4);
		AddRequirement(s.requirements, "coin", "", "Coins", 10000);

		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;
		s.spawnNothing = true;
	}

	CSprite@ sprite = this.getSprite();

	if (sprite !is null)
	{
		CSpriteLayer@ trader = sprite.addSpriteLayer("trader", "witch", 16, 24, 0, 0);
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

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	// reset shop colors
	addTokens(this);
}

void addTokens(CBlob@ this)
{
	int teamnum = this.getTeamNum();
	if (teamnum > 6) teamnum = 7;

	AddIconToken("$icon_mysterybox$", "MysteryBox.png", Vec2f(24, 16), 0, teamnum);
	AddIconToken("$icon_animalbox$", "AnimalBox.png", Vec2f(24, 16), 0, teamnum);
}

void onTick(CBlob@ this)
{
	// CBlob@[] blobs;

	u8 myTeam = this.getTeamNum();
	if (myTeam >= 100) return;

	CPlayer@[] players;
	for (int i = 0; i < getPlayerCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		if (p.getTeamNum() == this.getTeamNum()) 
		{
			CBlob@ blob = p.getBlob();
			if (blob !is null)
			{
				f32 maxHealth = Maths::Ceil(blob.getInitialHealth() * 1.25f);
				if (blob.getHealth() < maxHealth)
				{
					if (isServer())
					{
						blob.server_SetHealth(Maths::Min(blob.getHealth() + 0.125f, maxHealth));
					}

					if (isClient())
					{
						for (int i = 0; i < 4; i++)
						{
							ParticleAnimated("HealParticle.png", blob.getPosition() + Vec2f(XORRandom(16) - 8, XORRandom(16) - 8), Vec2f(0, f32(XORRandom(100) * -0.02f)) * 0.25f, 0, 0.5f, 10, 0, true);
						}
					}
				}
			}
		}
	}

	// if (this.getMap().getBlobsInRadius(this.getPosition(), 128.00f, @blobs))
	// {
		// for (int i = 0; i < blobs.length; i++)
		// {
			// if (blobs[i].getTeamNum() == myTeam)
			// {
				// CBlob@ blob = blobs[i];
				// if (blob.hasTag("player")) 
				// {
					// // blob.server_SetHealth(Maths::Min(blob.getHealth() + 0.25f, blob.getInitialHealth()));

					// f32 maxHealth = Maths::Ceil(blob.getInitialHealth() * 1.50f);

					// if (isServer())
					// {
						// blob.server_SetHealth(Maths::Min(blob.getHealth() + 0.125f, maxHealth));
					// }

					// if (isClient() && blob.getHealth() < maxHealth)
					// {
						// for (int i = 0; i < 4; i++)
						// {
							// ParticleAnimated("HealParticle.png", blob.getPosition() + Vec2f(XORRandom(16) - 8, XORRandom(16) - 8), Vec2f(0, f32(XORRandom(100) * -0.02f)) * 0.25f, 0, 0.5f, 10, 0, true);
						// }
					// }
					// // Add health particles?
				// }
			// }
		// }
	// }

	// for (uint i = 0; i < players.length; i++)
	// {
		// if (players[i].getTeamNum() == myTeam)
		// {
			// CPlayer@ ply = players[i].getPlayer();

			// if (ply !is null) ply.server_setCoins(ply.getCoins() + 1);
		// }
	// }
}

const string[] tips = {
"Cider = [heat < 500, pressure > 10000, Pumpkin]\n\n"+
"Boof = [pressure > 1000, heat < 500, Ganja >= 20, Dirt >= 20]\n\n"+
"Boof Gas = [pressure > 1000, heat > 700, Ganja pod]\n\n"+
"Vodka = [heat > 1000, Grain]\n\n"+ 
"Crack (small chance) and Coal = [pressure < 5000, heat > 500, Fiks]\n\n"+
"Fuel = [pressure > 40000, heat > 750, Oil, Methane]\n\n"+ 
"Fuel, Acid and Dirt = [pressure > 10000, pressure < 50000, heat > 1000, Oil]\n\n" +
"Oil = [pressure > 70000, pressure < 200000, heat > 1300, Coal, No steel]\n\n" +
"Stim, Dirt and Mustard = [pressure > 25000, heat > 400, hasSulphur, Sulphur >= 50, Acid >= 50]\n\n" +
"Sulphur = [pressure < 50000, heat > 100, Dirt, Acid]\n\n" +
"Fiks and Domino = [pressure < 25000, heat > 500, heat < 2000, Acid >= 15, Mithril >= 5]\n\n" +
"Baby = [pressure < 20000, heat > 100, heat < 500, Acid >= 20, Coal >= 15]\n\n" +
"Carbon - coal, heat >= 1k, pressure >= 100k, Steel 4-6\n\n" +
"Sturd = Fiks, Pumpkin >= 2\n\n" +
"Methane and Acid = [pressure > 1000, heat > 300, Meat]",

"Sosek = [pressure > 50000, heat > 1500, Vodka, Fuel >= 50, Coal >= 50]\n\n"+
"Acid = [pressure > 20000, heat > 300, Mustard, Fuel] \n\n"+
"Domino, MithrilEnriched and Fuel = [pressure > 25000, heat > 1500, Mithril >= 50, Acid >= 25]\n\n"+
"Bobongo, Methane and Fusk (very small chance) = [heat > 500, Dirt >= 50, Meat > 15, Acid >= 25]\n\n" +
"Rippio, Rippio Gas and Love (small chance) = [heat > 2250, Oil >= 25, Stim]\n\n"+
"Propesko and Love (very small chance) = [pressure < 100000, heat > 500, Acid >= 50, Sulphur >= 250, Coal >= 100]\n\n"+
"Schisk and Bobomax = [pressure > 40000, heat > 2000, Oil >= 25, Mithril >= 25]\n\n"+
"Gae gas = [pressure < 100000, heat >= 500, Love, Mustard >= 50]\n\n"+
"Steroid = [heat > 2000, Fiks, Domino, Stim]",

"Gooby = [pressure > 25000 | heat > 1000 | Rippio | Fiks | DangerMeat >= 45]\n\n"+
"Explodium = [heat < 300 | DangerMeat >= 15]\n\n"+
"Fumes = [pressure > 100000 | heat > 500 | Fuel >= 50 | Acid >= 50 | Coal >= 50]\n\n"+
"Dew = pressure > 10000 | heat < 500 | Protopopov >= 50 | Acid >= 50 | Mithril >= 25]\n\n"+
"Acid, Oil and Fusk (small chance) = [heat > 1400 | ProtopopovBulb]\n\n"+
"Poot, Bobomax and Oil = [pressure > 40000 | heat > 700 | Acid > 25 | Methane >= 25 | MithrilEnriched >= 5 | Meat >= 10]\n\n"+
"Foof = [pressure > 20000 | heat > 1000 | heat < 2000 | Acid >= 25 | Oil >= 20]\n\n"+
"Paxilon, PaxilonGas and Fusk (very small chance) = [heat > 500 | Oil >= 25 | Vodka]\n\n"+
"Love = [pressure < 50000 | heat >= 1200 | Rippio | Acid >= 25]\n\n"+
"Polymorphine = heat >= 1000 | Enriched mithril >= 15 | Steroid | Boof >= 25"
};

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
			else if(spl[0] == "ganja_seed")
			{
				Random rand(getGameTime());
				server_MakeSeedsFor(@callerBlob, "ganja_plant", rand.NextRanged(0)+1);
			}
			else if (spl[0] == "alienbox")
			{
				CBlob@ b = server_CreateBlobNoInit("mysterybox");
				if (b !is null)
				{
					b.Tag("alien");
					b.server_setTeamNum(-1);
					b.setPosition(this.getPosition());
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
			else if (name.findFirst("tips") != -1)
			{
				if (!isServer()) return;
				CBlob@ paper = server_CreateBlobNoInit("t1_book");
				if (paper !is null)
				{
					paper.server_setTeamNum(255);
					paper.set_string("text", tips[XORRandom(tips.length)]);
					callerBlob.server_PutInInventory(paper);
					paper.Init();
					paper.Sync("text", true);
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
			}
		}
		if (isClient())
		{
			this.setInventoryName(this.get_string("text"));
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

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	//this.set_Vec2f("shop offset", Vec2f(2,0));
	this.set_bool("shop available", this.isOverlapping(caller));

	if (caller is null) return;
	if (!this.isOverlapping(caller)) return;

	//rename the witch shack
	CBlob@ carried = caller.getCarriedBlob();
	if(carried !is null && carried.getName() == "paper" && caller.getTeamNum() == this.getTeamNum())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		params.write_u16(carried.getNetworkID());

		CButton@ buttonWrite = caller.CreateGenericButton("$icon_paper$", Vec2f(0, -8), this, this.getCommandID("write"), "Rename the shack.", params);
	}
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		Animation@ destruction = sprite.getAnimation("destruction");
		if (destruction !is null)
		{
			f32 frame = Maths::Floor((this.getInitialHealth() - this.getHealth()) / (this.getInitialHealth() / sprite.animation.getFramesCount()));
			sprite.animation.frame = frame;
		}
	}
}
