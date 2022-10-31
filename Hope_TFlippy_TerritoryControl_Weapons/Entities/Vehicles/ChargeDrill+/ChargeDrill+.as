#include "VehicleCommon.as"
#include "CargoAttachmentCommon.as"
#include "Hitters.as";
#include "Explosion.as";

const f32 MAX_HEAT = 99999.0f;

void onInit(CBlob@ this)
{
	Vehicle_Setup(this,
	              70, // move speed
	              0.3f,  // turn speed
	              Vec2f(0.0f, 0.0f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	Vec2f[] shape = 
	{ 
		Vec2f(68, 0),
		Vec2f(86, 13),
		Vec2f(68, 26)
	};
		
	this.getShape().AddShape(shape);

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetRelativeZ(-10.0f);
		sprite.SetEmitSoundSpeed(0.875f);

		CSpriteLayer@ drill = sprite.addSpriteLayer("drill", "ChargeDrillDrills.png", 35, 23);
		if (drill !is null)
		{
			drill.SetOffset(Vec2f(-51.5, 6));
			drill.SetRelativeZ(-39.0f);

			Animation@ drillanim = drill.addAnimation("drilling", 2, true);
			if (drillanim !is null)
			{
				drillanim.AddFrame(1);
				drillanim.AddFrame(2);
				drillanim.AddFrame(3);

				//drill.SetAnimation(drillanim);
			}

			Animation@ drillanimdef = drill.addAnimation("drillingdef", 2, false);
			if (drillanimdef !is null)
			{
				drillanimdef.AddFrame(0);

				drill.SetAnimation(drillanimdef);
			}

			//drill.SetVisible(false);
			CSpriteLayer@ overheat = sprite.addSpriteLayer("overheat", "ChargeDrillDrills.png", 35, 23);
			if (overheat !is null)
			{
				overheat.SetOffset(Vec2f(-51.5, 6));
				overheat.SetRelativeZ(-39.0f);

				Animation@ overheatanim = overheat.addAnimation("overheat", 0, false);
				if (overheatanim !is null)
				{
					overheatanim.AddFrame(4);
					overheatanim.AddFrame(5);
					overheatanim.AddFrame(6);
					overheatanim.AddFrame(7);

					overheat.SetAnimation(overheatanim);
					overheat.SetFrameIndex(0);
					overheat.setRenderStyle(RenderStyle::additive);

					overheat.SetVisible(false);
				}
			}
		}
	}

	this.Tag("stopsound");
		
	this.set_f32("hit dmg modifier", 1.0f);//was 5.0
	this.set_f32("map dmg modifier", 2.0f);
	this.set_f32("heat", 0);
	this.set_bool("break", false);
	
	this.set_u32("lastHornTime", 0.0f);
	this.set_string("custom_explosion_sound", "KegExplosion");
	
	this.getShape().SetOffset(Vec2f(0, 8));
	
	Vehicle_SetupGroundSound(this, v, "machinery_out_lp_03", 0.8f, 1.0f);
	
	AttachmentPoint@ driverpoint = this.getAttachments().getAttachmentPointByName("DRIVER");
	if (driverpoint !is null)
	{
		driverpoint.SetKeysToTake(key_action1);
		driverpoint.SetKeysToTake(key_action3);
	}
	
	this.getShape().SetRotationsAllowed(true);
	
	this.SetLight(true);
	this.SetLightColor(SColor(180, 255, 50, 50));
	this.SetLightRadius(128.0f);

	if (isServer())
	{
		CBlob@ e = server_CreateBlobNoInit("stupidgame");
		e.set_u16("id", this.getNetworkID());
		e.Init();
		this.set_u16("theid", e.getNetworkID());
		this.Sync("theid", true);
	}
}

void makeSteamParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	const f32 rad = this.getRadius();
	Vec2f random = Vec2f(XORRandom(64) - 8, XORRandom(64) - 32) * 0.015625f * rad;
	ParticleAnimated(filename, this.getPosition() + random, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}

void onTick(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		if (this.getVelocity().x > 0.25f || this.getVelocity().x < -0.25) sprite.SetAnimation("default");
		else sprite.SetAnimation("stop");

		f32 heat = this.get_f32("heat");

		CSpriteLayer@ overheat = sprite.getSpriteLayer("overheat");
		if (overheat !is null)
		{
			if (heat < MAX_HEAT/3)
				overheat.SetVisible(false);
			else if (heat >= MAX_HEAT/3 && heat < MAX_HEAT/2)
			{
				overheat.SetVisible(true);
				overheat.SetFrameIndex(0);
			}
			else if (heat >= MAX_HEAT/2 && heat < MAX_HEAT/1.5)
				overheat.SetFrameIndex(1);
			else if (heat >= MAX_HEAT/1.5 && heat < MAX_HEAT)
				overheat.SetFrameIndex(2);
			else overheat.SetFrameIndex(3);
		}
	}
	if (this.get_bool("break"))
	{
		this.setVelocity(Vec2f(this.getVelocity().x*0.5, this.getVelocity().y));
	}

	if (getGameTime()%10==0 && !this.hasTag("l1") && this.get_f32("heat") > 0) this.add_f32("heat", this.isInWater() ? -2.5f : -1.5f);

	if (this.hasAttached() || this.getTickSinceCreated() < 30) //driver, seat or gunner, or just created
	{
		AttachmentPoint@ driver = this.getAttachments().getAttachmentPointByName("DRIVER");
		if (driver is null) return;
		CBlob@ blob = driver.getOccupied();
		if (blob is null) return; // add preventing disabling emitsound for juggernaut

		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		if (this.get_f32("heat") > MAX_HEAT && blob.isMyPlayer() && getGameTime()%30==0) SetScreenFlash(80, 230, 50, 70, 1.0f);

		if (sprite !is null)
		{
			CSpriteLayer@ drill = sprite.getSpriteLayer("drill");
			if (drill !is null)
			{
				CSpriteLayer@ overheat = sprite.getSpriteLayer("overheat");
				if (overheat !is null)
				{	
					if (driver.isKeyJustReleased(key_action3))
					{
						this.set_bool("break", !this.get_bool("break"));
					}
					if (driver.isKeyPressed(key_down))
					{
						if (this.get_bool("break"))
						{
							f32 torque = this.isOnWall() ? 625.0f : 1250.0f;
							this.AddTorque(this.isFacingLeft() ? -torque : torque);
						}
						else
						{
							f32 torque = 350.0f;
							this.AddTorque(this.isFacingLeft() ? torque : -torque);
						}
					}
					if (driver.isKeyPressed(key_action1))
					{
						this.Tag("l1");
						if (drill.getAnimation("drilling") !is null)
						{
							drill.SetAnimation("drilling");
						}
						//drill sound
						this.Untag("stopsound");
						f32 heat = this.get_f32("heat");
						//hit map
						CMap@ map = this.getMap();
						if (map is null) return;
						if (heat > MAX_HEAT)
						{
							sprite.PlaySound("DrillOverheat.ogg");
							makeSteamParticle(this, Vec2f(XORRandom(4)-2,-1));
						}
						if (isServer() && getGameTime()%1==0)
						{
							if (heat > MAX_HEAT) this.server_Hit(this, this.getPosition(), Vec2f(0,0), 1.5f, Hitters::fire, true);
							
							bool faceleft = this.isFacingLeft();
							f32 rotation = this.getAngleDegrees() + (faceleft ? 180.0f : 0.0f);
							Vec2f direction = Vec2f(1, 0).RotateBy(rotation);
							
							const f32 attack_distance = faceleft ? 0.1f : 80.0f;
							Vec2f fromPos = faceleft ? Vec2f(32,-6).RotateBy(rotation) : Vec2f(-64,6).RotateBy(rotation);
							const f32 distance = 148.0f;
							Vec2f attackVel = direction * attack_distance;
							HitInfo@[] hitInfos;
							bool hitsomething = false;
							bool hitblob = false;

							if (map.getHitInfosFromArc(this.getPosition() + fromPos + attackVel, -attackVel.Angle() - (faceleft ? -2.0f : 2.0f), 60, distance, this, true, @hitInfos))
							{
								bool hit_ground = false;
								for (uint i = 0; i < hitInfos.length; i++)
								{
									f32 attack_dam = 2.5f;
									HitInfo@ hi = hitInfos[i];
									bool hit_constructed = false;
									CBlob@ b = hi.blob;
									if (b !is null) // blob
									{
										// blob ignore list, this stops the drill from overheating f a s t
										// or blobs to increase damage to (for the future)
										if (b.hasTag("invincible")) continue;
										string name = b.getName();
										//detect
										const bool is_ground = b.hasTag("blocks sword") && !b.isAttached() && b.isCollidable();
										if (is_ground)
										{
											hit_ground = true;
										}

										if (b.getTeamNum() != this.getTeamNum()) this.server_Hit(b, hi.hitpos, attackVel, 1.0f, Hitters::drill);

										this.add_f32("heat", 1.5f);
										this.Sync("heat", true);
										hitsomething = true;
										hitblob = true;
									}
									else // map
									{
										TileType tile = hi.tile;
										if (isServer())
										{
											//tile destroyed last hit
											if (tile >= 800 && tile <= 824 && XORRandom(5) != 0)
											{
												sprite.PlaySound("metal_stone.ogg", 1.0f, 1.1f);
												this.add_f32("heat", 1.0f);
												this.Sync("heat", true);
												continue;
											}
											this.add_f32("heat", 0.45f);
											this.Sync("heat", true);
											if (!map.isTileSolid(map.getTile(hi.tileOffset))){ break; }
											map.server_DestroyTile(hi.hitpos, 0.25, this);
											if (map.isTileGround(tile) || map.isTileStone(tile) || map.isTileThickStone(tile))
											{
												this.set_bool("just hit dirt", true);
												this.Sync("just hit dirt", true);
											}
										}
										if (isClient())
										{
											if (map.isTileBedrock(tile))
											{
												sprite.PlaySound("metal_stone.ogg");
											}
										}
										//only counts as hitting something if its not mats, so you can drill out veins quickly
										if (!map.isTileStone(tile) || !map.isTileGold(tile))
										{
											hitsomething = true;
											if (map.isTileCastle(tile) || map.isTileWood(tile))
											{
												hit_constructed = true;
											}
											else
											{
												hit_ground = true;
											}
										}
									}
									if (hitsomething)
									{
										//if (heat < heat_max)
										//{
										//	if (hit_constructed)
										//	{
										//		heat += heat_add_constructed;
										//	}
										//	else if (hitblob)
										//	{
										//		heat += heat_add_blob;
										//	}
										//	else
										//	{
										//		heat += heat_add;
										//	}
										//}
										hitsomething = false;
										hitblob = false;
									}
								}
							}
						}
					}
					else
					{
						this.Untag("l1");
						if (drill.getAnimation("drillingdef") !is null)
						{
							drill.SetAnimation("drillingdef");
						}
						this.Tag("stopsound");
					}
				}
			}
		}

		Vehicle_StandardControls(this, v);
	}

	CBlob@ e = getBlobByNetworkID(this.get_u16("theid"));
	if (e !is null)
	{
		CSprite@ es = e.getSprite();
		if (es !is null)
		{
			es.SetEmitSound("/Drill.ogg");
			es.SetEmitSoundSpeed(0.825f);
			if (this.hasTag("stopsound"))
				es.SetEmitSoundPaused(true);
			else es.SetEmitSoundPaused(false);
		}
	}
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}
void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _unused) {}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob !is null)
	{
		TryToAttachCargo(this, blob);
		if(solid)
		{
			f32 vel_thresh =  1.0f;
			f32 dir_thresh =  0.25f;

			const f32 vellen = this.getShape().vellen;
			if (blob !is null && vellen > vel_thresh && blob.isCollidable())
			{
				Vec2f pos = this.getPosition();
				Vec2f vel = this.getVelocity();
				Vec2f other_pos = blob.getPosition();
				Vec2f direction = other_pos - pos;
				direction.Normalize();
				vel.Normalize();
				if (vel * direction > dir_thresh)
				{
					f32 power = vellen / 2;
					if (this.getTeamNum() != blob.getTeamNum())
					{
						this.server_Hit(blob, point1, vel, power, Hitters::flying, false);
						//print(power + " aa");
					}
				}
			}
		}
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attached !is this)
	{
		attached.Tag("invincible");
		attached.Tag("NOLMB");
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached !is null)
	{
		if (detached.getName() != "adminbuilder") detached.Untag("invincible");
		detached.Untag("NOLMB");
	}
	if (attachedPoint !is null && attachedPoint.name == "DRIVER")
	{
		if (attachedPoint.getOccupied() is null) this.Tag("stopsound");

		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			CSpriteLayer@ drill = sprite.getSpriteLayer("drill");
			if (drill !is null)
			{
				if (drill.getAnimation("drillingdef") !is null)
				{
					drill.SetAnimation("drillingdef");
				}
			}
		}
	}
}

void onDie(CBlob@ this)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;
	
	Explode(this, 32.0f, 4.0f);

	if (isServer())
	{
		CBlob@ blob = server_CreateBlob("chargedrillwreck", this.getTeamNum(), this.getPosition());
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return byBlob.hasTag("vehicle") && this.getTeamNum() == byBlob.getTeamNum();
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.isKeyPressed(key_down)) return false;
	return (this.getTeamNum() != blob.getTeamNum() ? blob.isCollidable() : false) && !blob.hasTag("dead") && !blob.hasTag("weapon");
}