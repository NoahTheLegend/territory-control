// Princess brain

#include "Hitters.as";
#include "HittersTC.as";
#include "Explosion.as";
#include "FireParticle.as"
#include "FireCommon.as";
#include "RunnerCommon.as";
#include "MakeCrate.as";
#include "ThrowCommon.as";
#include "Survival_Structs.as";

u32 next_commander_event = 0; // getGameTime() + (30 * 60 * 5) + XORRandom(30 * 60 * 5));
bool dry_shot = true;

const u16 MAX_CHICKENS_ON_MAP = 32;

void onInit(CBlob@ this)
{
	this.set_u32("nextAttack", 0);
	this.set_u32("nextBomb", 0);

	this.set_f32("minDistance", 32);
	this.set_f32("chaseDistance", 200);
	this.set_f32("maxDistance", 400);

	this.set_f32("inaccuracy", 0.01f);
	this.set_u8("reactionTime", 0);
	this.set_u8("attackDelay", 0);
	this.set_bool("bomber", false);
	this.set_bool("raider", false);
	this.getSprite().PlaySound("DFF-Intro.ogg", 99.0f);

	// this.set_u32("next_event", getGameTime() + (30 * 60 * 5) + XORRandom(30 * 60 * 5));

	next_commander_event = getGameTime(); // + (30 * 60 * 5) + XORRandom(30 * 60 * 5));
	this.addCommandID("commander_order_recon_squad");

	this.SetDamageOwnerPlayer(null);

	this.Tag("can open door");
	this.Tag("combat chicken");
	this.Tag("npc");
	this.Tag("flesh");
	this.Tag("player");

	this.getCurrentScript().tickFrequency = 1;

	this.set_f32("voice pitch", 1.50f);
	this.getSprite().addSpriteLayer("isOnScreen","NoTexture.png",1,1);
	if (isServer())
	{
		this.set_u16("stolen coins", 850);

		this.server_setTeamNum(250);

		string gun_config;
		string ammo_config;

		switch(XORRandom(6))
		{
			case 0:
				gun_config = "cock";
				ammo_config = "mat_pistolammo";

				this.set_u8("attackDelay", 6);
				this.set_f32("chaseDistance", 88);
				this.set_f32("minDistance", 128);
				this.set_f32("maxDistance", 512);

				break;

			case 1: //real nazi moment
				gun_config = "c96";
				ammo_config = "mat_rifleammo";

				this.set_u8("attackDelay", 10);
				this.set_f32("chaseDistance", 192); 
				this.set_f32("minDistance", 192);
				this.set_f32("maxDistance", 768);

				break;
			
			case 2:
				gun_config = "fuger";
				ammo_config = "mat_pistolammo";

				this.set_u8("attackDelay", 3);
				this.set_f32("chaseDistance", 88);
				this.set_f32("minDistance", 128);
				this.set_f32("maxDistance", 512);

				break;
			
			case 3:
				gun_config = "pdw";
				ammo_config = "mat_pistolammo";

				this.set_u8("attackDelay", 1);
				this.set_f32("chaseDistance", 88);
				this.set_f32("minDistance", 128);
				this.set_f32("maxDistance", 512);
				
				break;
				
			/*
			case 2:
				gun_config = "sar";
				ammo_config = "mat_rifleammo";
				
				this.set_u8("reactionTime", 30);
				this.set_u8("attackDelay", 6);
				this.set_f32("chaseDistance", 400);
				this.set_f32("minDistance", 64);
				this.set_f32("maxDistance", 600);
				
				break;

			case 3:
			*/

			default:
				gun_config = "beagle";
				ammo_config = "mat_rifleammo";

				this.set_u8("attackDelay", 2);
				this.set_f32("chaseDistance", 88);
				this.set_f32("minDistance", 128);
				this.set_f32("maxDistance", 512);
				break;
		}

		CBlob@ phone = server_CreateBlob("phone", this.getTeamNum(), this.getPosition());
		this.server_PutInInventory(phone);

		if (XORRandom(100) < 60) 
		{
			CBlob@ bp_auto = server_CreateBlob("bp_automation_advanced", -1, this.getPosition());
			this.server_PutInInventory(bp_auto);
		}

		if (XORRandom(100) < 80) 
		{
			CBlob@ bp_sdr = server_CreateBlob("bp_energetics", -1, this.getPosition());
			this.server_PutInInventory(bp_sdr);
		}

		// gun and ammo
		CBlob@ ammo = server_CreateBlob(ammo_config, this.getTeamNum(), this.getPosition());
		ammo.server_SetQuantity(ammo.maxQuantity * 2);
		this.server_PutInInventory(ammo);

		CBlob@ gun = server_CreateBlob(gun_config, this.getTeamNum(), this.getPosition());
		if (gun !is null)
		{
			this.server_Pickup(gun);
			
			if (gun.hasCommandID("reload"))
			{
				CBitStream stream;
				gun.SendCommand(gun.getCommandID("reload"), stream);
			}
		}
	}
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null) player.SetScoreboardVars("ScoreboardIcons.png", 17, Vec2f(16, 16));
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return this.hasTag("dead");
}

void onTick(CBlob@ this)
{
	if (this.getName() == "commanderchicken")
	{
		if (this.getCarriedBlob() !is null && this !is null && this.getPlayer() is null) this.getCarriedBlob().Tag("fakeweapon");
	}

	CBlob@[] fakeweapons;
	getBlobsByTag("fakeweapon", fakeweapons);

	for (int i = 0; i < fakeweapons.length; i++)
	{
		if (!fakeweapons[i].isAttached() && fakeweapons[i] !is null) fakeweapons[i].server_Die();
	}

	RunnerMoveVars@ moveVars;
	if (this.get("moveVars", @moveVars))
	{
		moveVars.walkFactor *= 1.10f;
		moveVars.jumpFactor *= 1.30f;
	}

	if (this.getHealth() < 3.0 && this.hasTag("dead"))
	{
		this.getSprite().PlaySound("Wilhelm.ogg", 1.8f, 1.8f);

		if (isServer())
		{
			this.server_SetPlayer(null);
			server_DropCoins(this.getPosition(), Maths::Max(0, Maths::Min(this.get_u16("stolen coins"), 5000)));
			CBlob@ carried = this.getCarriedBlob();

			if (carried !is null)
			{
				carried.server_DetachFrom(this);
			}
			this.server_SetHealth(20.0f);
		}

		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}

	if (isServer())
	{
		if (getGameTime() >= next_commander_event)
		{
			CBlob@[] bases;
			getBlobsByTag("faction_base", @bases);
			u16 base_netid = 0;

			if (bases.length > 0) 
			{
				CBlob@ base = bases[XORRandom(bases.length)];
				if (base !is null)
				{
					next_commander_event = getGameTime() + (30 * 60 * 5) + XORRandom(30 * 60 * 20);
					if(dry_shot)
					{
						dry_shot = false;
					}
					else
					{
						f32 map_width = getMap().tilemapwidth * 8;
						f32 initial_position_x = Maths::Clamp(base.getPosition().x + (80 - XORRandom(160)) * 8.00f, 256.00f, map_width - 256.00f);

						CBitStream stream;
						stream.write_u16(base.getNetworkID());
						this.SendCommand(this.getCommandID("commander_order_recon_squad"), stream);

						for (int i = 0; i < 5; i++)
						{
							CBlob@ blob = server_MakeCrateOnParachute(XORRandom(2) == 0 ? "soldierchicken" : "scoutchicken", "SpaceStar Ordering Recon Squad", 0, 250, Vec2f(initial_position_x + (256.0f - XORRandom(512)), XORRandom(32)));
							if (XORRandom(20) == 0)
							{
								CBlob@ blob1 = server_MakeCrateOnParachute("heavychicken", "SpaceStar Ordering Recon Squad", 0, 250, Vec2f(initial_position_x + (256.0f - XORRandom(512)), XORRandom(32)));
								blob1.Tag("unpack on land");
								blob1.Tag("destroy on touch");
							}
							blob.Tag("unpack on land");
							blob.Tag("destroy on touch");
						}

						if (XORRandom(3) == 0)
						{
							{
								for (int i = 0; i < 15; i++)
								{
									CBlob@ blob = server_MakeCrateOnParachute("mine", "SpaceStar Ordering Mines", 0, 250, Vec2f(base.getPosition().x + (378 - XORRandom(756)), XORRandom(64)));
									blob.Tag("unpack on land");
									blob.Tag("destroy on touch");
								}
							}
						}
					}
				}
			}
			else
			{
				next_commander_event = getGameTime() + 2*((30 * 60 * 5) + XORRandom(30 * 60 * 20));
				dry_shot = true;
			}
		}
	}

	if (isClient())
	{
		if (getGameTime() > this.get_u32("next sound") && XORRandom(100) < 5)
		{
			// this.getSprite().PlaySound("scoutchicken_vo_perish.ogg", 0.8f, 1.5f);
			this.set_u32("next sound", getGameTime() + 100);
		}
	}
	
	if (this.isMyPlayer())
	{
		if (this.isKeyJustPressed(key_action3))
		{
			client_SendThrowOrActivateCommand(this);
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient())
	{
		if (getGameTime() > this.get_u32("next sound") - 50)
		{
			this.getSprite().PlaySound("scoutchicken_vo_hit" + (1 + XORRandom(3)) + ".ogg", 1, 0.8f);
			this.set_u32("next sound", getGameTime() + 60);
		}
	}

	if (customData == Hitters::explosion) return damage * 0.175f;

	return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (this.getPlayer() is null)
		return this.getTeamNum() != blob.getTeamNum();
	else return true;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("commander_order_recon_squad"))
	{
		CBlob@[] chickens; // dk if this works correctly
		getBlobsByTag("chicken", chickens);
		
		u16 chickens_quantity = 0;
		for (u16 i = 0; i < chickens.length; i++)
		{
			if (chickens[i] !is null && !chickens[i].hasTag("dead")
			&& chickens[i].getCarriedBlob() !is null && chickens[i].getCarriedBlob().hasTag("weapon")) chickens_quantity++;
		}

		if (chickens_quantity > MAX_CHICKENS_ON_MAP + (getPlayerCount()*2)) return;

		CBlob@ target = getBlobByNetworkID(params.read_u16());
		if (target !is null)
		{
			CTeam@ team = getRules().getTeam(target.getTeamNum());
			if (team !is null)
			{
				client_AddToChat("An UPF Recon Squad has been called upon " + GetTeamName(target.getTeamNum()) + "'s " + target.getInventoryName() + "!", SColor(255, 255, 0, 0));
				Sound::Play("ChickenMarch.ogg", target.getPosition(), 1.00f, 1.00f);
			}
		}
	}
}

