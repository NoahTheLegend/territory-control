// Princess brain

#include "Hitters.as";
#include "HittersTC.as";
#include "Explosion.as";
#include "FireParticle.as"
#include "FireCommon.as";
#include "RunnerCommon.as";
#include "BrainCommon.as";
#include "ThrowCommon.as";

void onInit(CBlob@ this)
{
	this.getSprite().addSpriteLayer("isOnScreen","NoTexture.png",1,1);
	this.set_u32("nextAttack", 0);
	this.set_u32("nextBomb", 0);

	this.set_f32("minDistance", 32);
	this.set_f32("chaseDistance", 200);
	this.set_f32("maxDistance", 400);

	this.set_f32("inaccuracy", 0.01f);
	this.set_u8("reactionTime", 30);
	this.set_u8("attackDelay", 0);
	this.set_bool("bomber", true);
	this.set_bool("raider", true);

	this.SetDamageOwnerPlayer(null);

	this.Tag("can open door");
	this.Tag("combat chicken");
	this.Tag("npc");
	this.Tag("flesh");
	this.Tag("player");

	this.getCurrentScript().tickFrequency = 1;

	this.set_f32("voice pitch", 0.50f);

	if (isServer())
	{
		this.set_u16("stolen coins", 750);

		this.server_setTeamNum(250);

		string gun_config;
		string ammo_config;
		
		if (XORRandom(500) < 1)
		{
			gun_config = "ruhm";
			ammo_config = "mat_sniperammo";
	
			this.set_u8("reactionTime", 0);
			this.set_u8("attackDelay", 0);
			this.set_f32("chaseDistance", 1536);
			this.set_f32("minDistance", 256);
			this.set_f32("maxDistance", 1536);
			this.set_f32("inaccuracy", 0.005f);
		}
		else
		{
			if (XORRandom(100) < 1)
			{
				gun_config = "rekt";
				ammo_config = "mat_gatlingammo";
	
				this.set_u8("reactionTime", 0);
				this.set_u8("attackDelay", 0);
				this.set_f32("chaseDistance", 768);
				this.set_f32("minDistance", 128);
				this.set_f32("maxDistance", 768);
				this.set_f32("inaccuracy", 0.05f);
			}
			else
			{
				switch(XORRandom(24))
				{
					case 0:
					case 1:
					case 2:
						gun_config = "assaultrifle";
						ammo_config = "mat_rifleammo";
		
						this.set_u8("attackDelay", 2);
						this.set_f32("chaseDistance", 128);
						this.set_f32("minDistance", 128);
						this.set_f32("maxDistance", 512);
						this.set_bool("bomber", false);
		
						break;
	
					case 3:
					case 4:
						gun_config = "flamethrower";
						ammo_config = "mat_oil";
	
						this.set_f32("chaseDistance", 88);
						this.set_f32("minDistance", 128);
						this.set_f32("maxDistance", 256);
	
						break;
	
					case 5:
					case 6:
					case 7:
						gun_config = "minigun";
						ammo_config = "mat_gatlingammo";
		
						this.set_f32("chaseDistance", 88);
						this.set_f32("minDistance", 128);
						this.set_f32("maxDistance", 256);
						this.set_f32("inaccuracy", 0.08f);
						this.set_bool("bomber", false);
		
						break;
	
					case 8:
					case 9:
						gun_config = "sniper";
						ammo_config = "mat_sniperammo";
		
						this.set_u8("attackDelay", 30);
						this.set_f32("chaseDistance", 1337); // No chasing, they're snipers // is this a meme number huh?
						this.set_f32("minDistance", 192);
						this.set_f32("maxDistance", 768);
						this.set_f32("inaccuracy", 0.025f);
						this.set_bool("bomber", false);
		
						break;
	
					case 10:
					case 11:
						gun_config = "amr";
						ammo_config = "mat_sniperammo";
		
						this.set_u8("attackDelay", 90);
						this.set_f32("chaseDistance", 1337);
						this.set_f32("minDistance", 192);
						this.set_f32("maxDistance", 768);
						this.set_f32("inaccuracy", 0.025f);
						this.set_bool("bomber", false);
		
						break;
	
					case 12:
					case 13:
					case 21:
					case 22:
						if (XORRandom(2) < 1)
						{
							gun_config = "msgl";
							ammo_config = "mat_grenade";
		
							this.set_u8("attackDelay", 20);
							this.set_f32("chaseDistance", 128);
							this.set_f32("minDistance", 192);
							this.set_f32("maxDistance", 256);
							this.set_f32("inaccuracy", 0.02f);
						}
						else
						{
							gun_config = "sgl";
							ammo_config = "mat_grenade";
		
							this.set_u8("attackDelay", 20);
							this.set_f32("chaseDistance", 128);
							this.set_f32("minDistance", 192);
							this.set_f32("maxDistance", 256);
							this.set_f32("inaccuracy", 0.02f);
						}
						break;
	
					case 14:
					case 15:
						gun_config = "raygun";
						ammo_config = "mat_mithril";
	
						this.set_f32("chaseDistance", 192);
						this.set_f32("minDistance", 192);
						this.set_f32("maxDistance", 768);
						this.set_f32("inaccuracy", 0.00f);
	
						break;
						
					case 16:
					case 17:
					case 18:
					case 19:
					case 20:
						gun_config = "autoshotgun";
						ammo_config = "mat_shotgunammo";
		
						this.set_u8("attackDelay", 10);
						this.set_f32("chaseDistance", 88);
						this.set_f32("minDistance", 128);
						this.set_f32("maxDistance", 512);
						this.set_f32("inaccuracy", 0.025f);
						this.set_bool("bomber", false);
		
						break;
	
					// case 14:
						// gun_config = "mininukelauncher";
						// ammo_config = "mat_mininuke";
	
						// this.set_u8("reactionTime", 30);
						// this.set_u8("attackDelay", 300);
						// this.set_f32("chaseDistance", 500);
						// this.set_f32("minDistance", 400);
						// this.set_f32("maxDistance", 600);
						// this.set_f32("inaccuracy", 0.00f);
	
						// break;
	
/*					default:
						gun_config = "xmas";
						ammo_config = "mat_rifleammo";
						
						this.set_u8("attackDelay", 2);
						this.set_f32("chaseDistance", 128);
						this.set_f32("minDistance", 256);
						this.set_f32("maxDistance", 512);
						this.set_bool("bomber", true);
						
						break; */
					
					default:
						gun_config = "xm";
						ammo_config = "mat_rifleammo";
		
						this.set_u8("attackDelay", 2);
						this.set_f32("chaseDistance", 88);
						this.set_f32("minDistance", 128);
						this.set_f32("maxDistance", 256);
						this.set_bool("bomber", true);
		
						break;
				}
			}
		}

		// gun and ammo
		CBlob@ ammo = server_CreateBlob(ammo_config, this.getTeamNum(), this.getPosition());
		
		if (gun_config == "msgl" || gun_config == "sgl")
		{
			ammo.server_SetQuantity(ammo.maxQuantity * 10);
		}
		else if (gun_config == "flamethrower" || gun_config == "raygun")
		{
			ammo.server_SetQuantity(ammo.maxQuantity * 5);
		}
		else
		{
			ammo.server_SetQuantity(ammo.maxQuantity * 2);
		}
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
	if (player !is null) player.SetScoreboardVars("ScoreboardIcons.png", 16, Vec2f(16, 16));
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return this.hasTag("dead");
}

void onTick(CBlob@ this)
{
	if (this.getName() == "heavychicken")
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

	if (getGameTime() % 30 == 0) this.set_u8("mode", 0);

	if (this.getHealth() < 0.0 && this.hasTag("dead"))
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
		}

		this.getCurrentScript().runFlags |= Script::remove_after_this;
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
	switch (customData)
	{
		case Hitters::fire:
		case Hitters::burn:
		case HittersTC::radiation:
			damage = 0.00f;
			break;
	}

	if (isClient())
	{
		if (getGameTime() > this.get_u32("next sound") - 50)
		{
			this.getSprite().PlaySound("scoutchicken_vo_hit" + (1 + XORRandom(3)) + ".ogg", 1, 0.8f);
			this.set_u32("next sound", getGameTime() + 60);
		}
	}

	return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (this.getPlayer() is null)
		return this.getTeamNum() != blob.getTeamNum();
	else return true;
}