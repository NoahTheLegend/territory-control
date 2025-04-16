#include "RunnerCommon.as";
#include "Hitters.as";
#include "Knocked.as"
#include "FireCommon.as"
#include "Help.as"
#include "Survival_Structs.as";
#include "Logging.as";
#include "DeityCommon.as";
#include "MakeDustParticle.as";

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
	this.Tag("medium weight");
	this.Tag("grapplable");

	this.addCommandID("jetpackv1_effects_client");
	this.addCommandID("jetpackv1_effects");
	this.addCommandID("jetpackv2_effects");
	this.addCommandID("jetpackv2_keypress");

	//default player minimap dot - not for migrants
	if (this.getName() != "migrant")
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 8, Vec2f(8, 8));
	}

	this.set_s16(burn_duration , 130);

	//fix for tiny chat font
	this.SetChatBubbleFont("hud");
	this.maxChatBubbleLines = 4;

	setKnockable(this);

	this.set_u32("disable_gliding", 0);
	this.set_f32("overdosing", 0);
}

void onTick(CBlob@ this)
{
	CPlayer@ player = this.getPlayer();
	if (player !is null && player.get_bool("customfreeze"))
	{
		SetKnocked(this, 30);
		this.setVelocity(Vec2f(0,0));
		if (isServer() && this.isAttached()) this.server_DetachFromAll();
	}
	else if (this.get_bool("customfreeze"))
	{
		SetKnocked(this, 60);
		this.setVelocity(Vec2f(0,0));
		if (isServer() && this.isAttached()) this.server_DetachFromAll();
	}
	DoKnockedUpdate(this);

	if (this.isAttached() && isKnocked(this))
	{
		return;
	}

	if (getGameTime() <= this.get_u32("disable_gliding"))
	{
		this.setPosition(Vec2f(this.getPosition().x, this.getOldPosition().y));
		this.setVelocity(Vec2f(this.getVelocity().x, 0));
		if (this.getMap() !is null)
		{
			CBlob@[] find_glider;
			this.getMap().getBlobsAtPosition(this.getPosition()+Vec2f(0,12), find_glider);
			for (u16 i = 0; i < find_glider.length; i++)
			{
				if (find_glider[i] !is null && find_glider[i].getName() == "glider") //&& find_glider[i].get_u32("elec") > 3)
				{
					//printf("e");
					this.set_u32("disable_gliding", getGameTime()+10);
				}
			}
		}
	}

	if (isClient() && !this.isMyPlayer())
	{
		//jet v1
		u32 tmp = this.get_u32("nextJetpack");
		if (tmp > getGameTime())
			makeSteamParticle(this, Vec2f(), XORRandom(100) < 30 ? ("SmallFire" + (1 + XORRandom(2))) : "SmallExplosion" + (1 + XORRandom(3)));
		else if (tmp > getGameTime())
			makeSteamParticle(this, Vec2f(XORRandom(128) - 64, XORRandom(128) - 64) * 0.0015f * this.getRadius(),"SmallSteam",Vec2f(XORRandom(10)-5,XORRandom(10)-5)*0.2*this.getRadius());
	
	
		if (this.get_u32("timer") > 0) this.set_u32("timer", this.get_u32("timer") - 1);
		// jet v2
		if (this.hasTag("pressed_shift"))
		{
			Vec2f pos = this.getPosition() + Vec2f(0.0f, 2.0f);
			u8 particlesrandom = XORRandom(3);
			f32 fl = this.isFacingLeft() ? 1.0f : -1.0f;
			switch (particlesrandom)
			{
				case 0:
					MakeParticle(this, pos + Vec2f(fl*5.0f, 8.0f), "SmallExplosion1.png");
					break;
				case 1:
					MakeParticle(this, pos + Vec2f(fl*5.0f, 8.0f), "SmallExplosion2.png");
					if (this.get_f32("fuel_count") < 500 && this.get_f32("fuel_count") > 0)
					{
						MakeParticle(this, pos + Vec2f(fl*5.0f, 8.0f), "SmallSteam.png");
						this.getSprite().PlaySound("DrillOverheat.ogg");
					}
					break;
				case 2:
					MakeParticle(this, pos + Vec2f(fl*5.0f, 8.0f), "SmallExplosion3.png");
					break;
			}
			if (this.get_u32("timer") == 0) 
			{
				CSprite@ sprite = this.getSprite();
				//sprite.PlaySound("FlamethrowerFire.ogg", 0.4f);
				sprite.SetEmitSound("FlamethrowerFire.ogg");
				sprite.SetEmitSoundSpeed(1.1f);
				sprite.SetEmitSoundPaused(false);
				if (this.get_u32("timer") < 1) this.set_u32("timer", 45);
			}
		}
	}

	if (this.isInWater())
	{
		RunnerMoveVars@ moveVars;
		if (this.get("moveVars", @moveVars) && !this.hasScript("flippers_effect.as"))
		{
			moveVars.swimspeed = 2.0f;
			CBlob@ fishie = this.getCarriedBlob();
			if (fishie !is null && fishie.getName() == "fishy" && !fishie.hasTag("dead"))
			{
				moveVars.swimspeed = 3.25f;
			}
		}
	}

	CRules@ rules = getRules();
	if (rules !is null)
	{
		if (rules.get_bool("raining"))
		{
			RunnerMoveVars@ moveVars;
			if (this.get("moveVars", @moveVars))
			{
				Vec2f pos = this.getPosition();
				if (!getMap().rayCastSolidNoBlobs(Vec2f(pos.x, 0), pos))
				{
					moveVars.walkFactor *= 0.95f;
					moveVars.jumpFactor *= 0.90f;
				}
			}
		}
		
		const u8 team = this.getTeamNum();
		if (team < 7)
		{
			TeamData@ team_data;
			GetTeamData(team, @team_data);
			
			if (team_data != null && team_data.upkeep_cap > 0)
			{
				u16 upkeep = team_data.upkeep;
				u16 upkeep_cap = team_data.upkeep_cap;
				f32 upkeep_ratio = f32(upkeep) / f32(upkeep_cap);
				
				RunnerMoveVars@ moveVars;
				if (this.get("moveVars", @moveVars))
				{
					if (upkeep_ratio <= UPKEEP_RATIO_BONUS_SPEED) 
					{ 
						moveVars.walkFactor *= 1.20f;
						moveVars.jumpFactor *= 1.15f;
					}
					
					if (upkeep_ratio >= UPKEEP_RATIO_PENALTY_SPEED) 
					{
						moveVars.walkFactor *= 0.80f;
						moveVars.jumpFactor *= 0.80f;
					}
				}
			}
		}
	}

	u8 deity_id = this.get_u8("deity_id");
	switch (deity_id)
	{
		case Deity::mithrios:
		{
			CBlob@ altar = getBlobByName("altar_mithrios");
			if (altar !is null)
			{
				f32 power = altar.get_f32("deity_power");
			
				RunnerMoveVars@ moveVars;
				if (this.get("moveVars", @moveVars))
				{
					moveVars.walkFactor *= 1.00f + Maths::Clamp(power * 0.00009f, 0.00f, 0.40f);
				}
				
				CBlob@[] blobs;
				getBlobsByTag("flesh", @blobs);
				
				if (getGameTime() % 90 == 0)
				{
					CBlob@ localBlob = getLocalPlayerBlob();
					if (this is localBlob)
					{
						u8 light_intensity = u8(255.00f * Maths::Clamp(power / 1000.00f, 0.00f, 1.00f));
						
						for (int i = 0; i < blobs.length; i++)
						{
							CBlob@ blob = blobs[i];
							if (blob !is null)
							{
								blob.SetLight(true);
								blob.SetLightRadius(16.00f);
								blob.SetLightColor(SColor(0, light_intensity, 0, 0)); // Currently not being reset upon altar destruction or deity change, deal with that later
							}
						}
					}
				}
			}
		}
		break;
	
		case Deity::ivan:
		{
			RunnerMoveVars@ moveVars;
			if (this.get("moveVars", @moveVars))
			{
				moveVars.walkFactor *= 1.20f;
				moveVars.jumpFactor *= 1.15f;
			}
		}
		break;
		
		case Deity::dragonfriend:
		{
			if (this.isKeyJustPressed(key_eat) && !(getKnocked(this) > 0 || this.get_f32("babbyed") > 0.00f))
			{
				if (getGameTime() >= this.get_u32("nextDragonFireball"))
				{
					CBlob@ altar = getBlobByName("altar_dragonfriend");
					if (altar !is null)
					{
						f32 power = altar.get_f32("deity_power");
						
						Vec2f vel = this.getAimPos() - this.getPosition();
						vel.Normalize();
						vel *= 13.00f;
						
						if (isServer())
						{
							CBlob@ fireball = server_CreateBlobNoInit("fireball");
							fireball.setPosition(this.getPosition());
							fireball.setVelocity(vel);
							fireball.server_setTeamNum(this.getTeamNum());
							fireball.set_f32("power", power);
							fireball.Init();
						}
						
						if (isClient())
						{
							this.getSprite().PlaySound("KegExplosion", 1.00f, 1.50f);
						}
						
						this.setVelocity(this.getVelocity() - (vel * 0.50f));
						
						
						u32 cooldown = (30 * 15);
						if (this.get_f32("fumes_effect") > 0.00f)
						{
							cooldown /= 5.00f;
						}
						
						this.set_u32("nextDragonFireball", getGameTime() + cooldown);
					}
				}
				else
				{
					if (this.isMyPlayer()) 
					{
						Sound::Play("/NoAmmo");
					}
				}
			}
		}
	}
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (isClient() && this.isMyPlayer())
	{
		CCamera@ cam = getCamera();
		cam.setRotation(0, 0, 0);
		
		if (isClient() && this.isMyPlayer()) 
		{
			if (getRules().get_bool("raining"))
			{
				//getMap().CreateSkyGradient("skygradient_rain.png");
			}
			else
			{
				//if (getBlobByName("info_dead") !is null)
				//	getMap().CreateSkyGradient("Dead_skygradient.png");	
				//else if (getBlobByName("info_magmacore") !is null)
				//	getMap().CreateSkyGradient("MagmaCore_skygradient.png");	
				//else
					getMap().CreateSkyGradient("skygradient.png");	
			}
		}
		//print("reset camera");
	}
}

void MakeParticle(CBlob@ this, const Vec2f pos, const string filename)
{
	this.getSprite().SetEmitSoundPaused(false);
	if (!this.isOnScreen()) {return;}
	ParticleAnimated(filename, pos, Vec2f(0, 1.0f), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(4), XORRandom(100) * -0.00005f, true);
	//ParticleAnimated(filename, this.getPosition() + pos, Vec2f(0, 1.0f), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(4), XORRandom(100) * -0.00005f, true);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if ((this.exists("vest_explode") && this.get_u32("vest_explode") > getGameTime()) && customData == Hitters::suicide)
	{
		return 0;
	}
	
	if ((customData == Hitters::suicide || customData == Hitters::nothing) && (getKnocked(this) > 0 || this.hasTag("no_suicide")))
	{
		damage = 0;
	}

	u8 deity_id = this.get_u8("deity_id");
	switch (deity_id)
	{
		case Deity::mithrios:
		{
			if (hitterBlob !is null && hitterBlob !is this)
			{
				CBlob@ altar = getBlobByName("altar_mithrios");
				if (altar !is null)
				{
					
					f32 ratio = Maths::Clamp(altar.get_f32("deity_power") * 0.0001f, 0.00f, 0.50f);
					f32 inv_ratio = 1.00f - ratio;
					
					// print("" + ratio);
					
					f32 damage_reflected = Maths::Min(damage * ratio, Maths::Max(this.getHealth(), 0));

					hitterBlob.setVelocity(hitterBlob.getVelocity() - (velocity * damage_reflected * 2.00f));
					this.setVelocity(this.getVelocity() + (velocity * damage_reflected * 2.00f));

					if (isServer() && hitterBlob.get_u8("deity_id") != Deity::mithrios)
					{
						this.server_Hit(hitterBlob, worldPoint, velocity, damage_reflected, customData);
					}

					if (isClient())
					{
						this.getSprite().PlaySound("DemonicBoing", 0.50f, 2.00f);
						if (this.isMyPlayer()) SetScreenFlash(100, 50, 0, 0);
					}

					damage *= inv_ratio;
				}
			}
		}
		break;

		case Deity::dragonfriend:
		{
			if ((customData == Hitters::fire || customData == Hitters::burn) && !hitterBlob.hasTag("acid"))
			{
				CBlob@ altar = getBlobByName("altar_dragonfriend");
				if (altar !is null)
				{
					f32 ratio = Maths::Clamp(altar.get_f32("deity_power") * 0.0001f, 0.00f, 1.00f);
					f32 inv_ratio = 1.00f - ratio;
					damage *= inv_ratio;
				}
			}
		}
		break;
	}

	return damage;
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	u8 deity_id = this.get_u8("deity_id");
	switch (deity_id)
	{
		case Deity::foghorn:
		{
			if (hitBlob !is null && hitBlob.getTeamNum() == 250 && hitBlob !is this)
			{
				CBlob@ altar = getBlobByName("altar_foghorn");
				if (altar !is null)
				{
					string action = "damaged";
					string type = "property";
					f32 reputation_penalty = damage * 100.00f;

					if (hitBlob.hasTag("flesh"))
					{
						reputation_penalty *= 3.00f;
						action = "injured";
						type = "personnel";
					}

					reputation_penalty = Maths::Round(reputation_penalty);

					if (isClient())
					{
						if (this.isMyPlayer()) 
						{
							client_AddToChat("You have " + action + " UPF " + type + "! (" + -reputation_penalty + " reputation)", 0xffff0000);
							Sound::Play("Collect.ogg", hitBlob.getPosition(), 2.00f, 0.80f);
						}
					}

					altar.add_f32("deity_power", -reputation_penalty);
					if (isServer()) altar.Sync("deity_power", false);
				}
			}
		}
		break;
	}
}

void onHitMap( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, u8 customData )
{
	u8 deity_id = this.get_u8("deity_id");
	switch (deity_id)
	{
		case Deity::foghorn:
		{
			if (getMap().isBlobWithTagInRadius("upf property", worldPoint, 128))
			{
				CBlob@ altar = getBlobByName("altar_foghorn");
				if (altar !is null)
				{
					string type = "property";
					f32 reputation_penalty = damage * 25.00f;

					reputation_penalty = Maths::Round(reputation_penalty);

					if (isClient())
					{
						if (this.isMyPlayer()) 
						{
							client_AddToChat("You have damaged UPF " + type + "! (" + -reputation_penalty + " reputation)", 0xffff0000);
							Sound::Play("Collect.ogg", worldPoint, 2.00f, 0.80f);
						}
					}

					altar.add_f32("deity_power", -reputation_penalty);
					if (isServer()) altar.Sync("deity_power", false);
				}
			}
		}
		break;
	}
}

// pick up efffects
// something was picked up

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().PlaySound("/PutInInventory.ogg");
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	this.getSprite().PlaySound("/Pickup.ogg");

	if (attached !is null && isServer())
	{
		CPlayer@ player = this.getPlayer();
		if (player !is null)
		{
			//KVSES-//tcpr("[PPU] " + player.getUsername() + " has picked up " + attached.getName());
		}
		else
		{
			//KVSES-//tcpr("[BPU] " + this.getName() + " has picked up " + attached.getName());
		}
	}

	if (isClient())
	{
		RemoveHelps(this, "help throw");

		if (!attached.hasTag("activated"))
			SetHelp(this, "help throw", "", "$" + attached.getName() + "$" + "Throw    $KEY_C$", "", 2);
	}

	// check if we picked a player - don't just take him out of the box
	/*if (attached.hasTag("player"))
	this.server_DetachFrom( attached ); CRASHES*/
}

bool isDangerous(CBlob@ blob)
{
	return blob.hasTag("explosive") || blob.hasTag("weapon") || blob.hasTag("dangerous");
}

// set the Z back
void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached !is null && detached.hasTag("save_detach_collision"))
	{
		this.IgnoreCollisionWhileOverlapped(null);
		detached.IgnoreCollisionWhileOverlapped(null);
	}
	if (detached !is null && isServer())
	{
		CPlayer@ player = this.getPlayer();
		if (player !is null)
		{
			//KVSES-//tcpr("[PDI] " + player.getUsername() + " has dropped " + detached.getName());
		}
		else
		{
			//KVSES-//tcpr("[BDI] " + this.getName() + " has dropped " + detached.getName());
		}
	}

	this.getSprite().SetZ(0.0f);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return byBlob !is this && (this.hasTag("migrant") || this.hasTag("dead"));
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	if (this.getPlayer() == null || forBlob.getPlayer() == null) return false;
	return (forBlob !is this) && ((getKnocked(this) > 0) || (this.get_f32("babbyed") > 0) || (this.isKeyPressed(key_down)) || (this.hasTag("dead")));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("jetpackv1_effects"))
	{
		bool init = params.read_bool();

		if (init)
		{
			if (isServer())
			{
				CBitStream params1;
				params1.write_bool(false);
				this.SendCommand(this.getCommandID("jetpackv1_effects"), params1);
			}
		}
		if (!init)
		{
			if (isClient() && !this.isMyPlayer())
			{
				this.set_u32("nextJetpack", getGameTime()+45);
				Vec2f pos = this.getPosition() + Vec2f(0.0f, 4.0f);

				MakeDustParticle(pos + Vec2f(2.0f, 0.0f), "Dust.png");
				this.getSprite().PlaySound("/Jetpack_Offblast.ogg");
			}
		}
	}
	else if (cmd == this.getCommandID("jetpackv2_effects"))
	{
		if (!isServer()) return;
		bool just_pressed = params.read_bool();
		CBitStream params;
		params.write_bool(just_pressed);
		this.SendCommand(this.getCommandID("jetpackv2_keypress"), params);
	}
	else if (cmd == this.getCommandID("jetpackv2_keypress"))
	{
		if (!isClient()) return;
		bool press = params.read_bool();

		if (press)
		{
			this.Tag("pressed_shift");
		}
		else
		{
			this.Untag("pressed_shift");
		}
	}
}

void makeSteamParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam", const Vec2f displacement = Vec2f(0,0))
{
	if (!isClient()) return;

	ParticleAnimated(filename, this.getPosition()+displacement, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}
