#include "Hitters.as";
#include "HittersTC.as";
#include "Explosion.as";
#include "VehicleFuel.as";
#include "GunCommon.as";

const Vec2f miniGun_offset = Vec2f(-42,10);
const Vec2f rocketminiGun_offset = Vec2f(-11,4.5);

const Vec2f upVelo = Vec2f(0.00f, -0.015f);
const Vec2f downVelo = Vec2f(0.00f, 0.006f);
const Vec2f leftVelo = Vec2f(-0.02f, 0.00f);
const Vec2f rightVelo = Vec2f(0.02f, 0.00f);

const Vec2f minClampVelocity = Vec2f(-0.40f, -0.70f);
const Vec2f maxClampVelocity = Vec2f( 0.40f, 0.00f);

const Vec2f gun_clampAngle = Vec2f(-20, 80);
const Vec2f rocket_clampAngle = Vec2f(-20, 80);

const f32 thrust = 1000.00f;

const u32 shootDelay = 2; // Ticks
const u32 shootDelayRocket = 15; // Ticks
const f32 damage = 4.0f;
const int maxRocketStack = 30;
const int maxAmmoStack = 500;

void onInit(CBlob@ this)
{
	this.set_string("custom_explosion_sound", "bigbomb_explosion.ogg");
	this.set_bool("map_damage_raycast", true);
	this.set_u32("duration", 0);
	this.Tag("map_damage_dirt");

	this.addCommandID("load_fuel");
	this.addCommandID("addRocket");
	this.addCommandID("addAmmo");
	this.addCommandID("shootRocket");
	this.addCommandID("shoot");
	this.addCommandID("play_music");
	this.addCommandID("stop_music");

	this.Tag("vehicle");
	this.Tag("aerial");
	this.set_bool("lastTurn", false);
	this.set_bool("music", false);
	this.set_bool("glide", false);

	GunSettings settings = GunSettings();

	settings.B_GRAV = Vec2f(0, 0.0008); //Bullet Gravity
	settings.B_TTL = 14; //Bullet Time to live
	settings.B_SPEED = 60; //Bullet speed
	settings.B_DAMAGE = damage; //Bullet damage
	settings.MUZZLE_OFFSET = Vec2f(-42,10);
	settings.G_RECOIL = 0;

	this.set("gun_settings", @settings);

	if (this !is null)
	{
		CShape@ shape = this.getShape();
		if (shape !is null)
		{
			shape.SetRotationsAllowed(false);
		}
	}

	this.set_f32("max_fuel", 5000);
	this.set_f32("fuel_consumption_modifier", 2.00f);

	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			ap.offsetZ = 10.0f;
			ap.SetKeysToTake(key_action1 | key_action2 | key_action3);
		}
	}

	this.set_u16("ammoCount", 0);
	this.set_u16("rocketCount", 3);

	this.getCurrentScript().tickFrequency = 1;
	
	if (getNet().isServer())
	{
		CBlob@ blob = server_CreateBlob("donotspawnthiswithacommand");
		if (blob !is null)
		{
			blob.server_setTeamNum(this.getTeamNum());
			blob.setInventoryName(this.getInventoryName() + "'s Blade");
			blob.getShape().getConsts().collideWhenAttached;
			this.server_AttachTo(blob, "BLADE");
			this.set_u16("bladeid", blob.getNetworkID());
		}
	}
}

void onInit(CSprite@ this)
{
	//Add minigun
	CSpriteLayer@ mini = this.addSpriteLayer("minigun", "UHT_Gun.png", 16, 16);
	if (mini !is null)
	{
		mini.SetOffset(miniGun_offset);
		mini.SetRelativeZ(-50.0f);
		mini.SetVisible(true);
	}

	// Add minigun muzzle flash
	CSpriteLayer@ flash = this.addSpriteLayer("muzzle_flash", "flash_bullet.png", 16, 8);
	if (flash !is null)
	{
		GunSettings@ settings;
		this.getBlob().get("gun_settings", @settings);

		Animation@ anim = flash.addAnimation("default", 1, false);
		int[] frames = {0, 1, 2, 3, 4, 5, 6, 7};
		anim.AddFrames(frames);
		flash.SetRelativeZ(51.0f);
		flash.SetOffset(Vec2f(-57.5,9));
		flash.SetVisible(false);
		//flash.setRenderStyle(RenderStyle::light);
	}
	
	//Add blade
	CSpriteLayer@ blade = this.addSpriteLayer("blade", "UHT_Blade.png", 67, 8);
	if (blade !is null)
	{
		Animation@ anim = blade.addAnimation("default", 1, true);
		int[] frames = {1, 2, 3, 2};
		anim.AddFrames(frames);
		
		blade.SetOffset(Vec2f(-10, -20.5));
		blade.SetRelativeZ(-50.0f);
		blade.SetVisible(true);
	}
	
	//Add tail rotor
	
	CSpriteLayer@ tailrotor = this.addSpriteLayer("tailrotor", "UHT_TailRotor.png", 16, 16);
	if (tailrotor !is null)
	{
		Animation@ anim = tailrotor.addAnimation("default", 1, true);
		int[] frames = {0, 1, 2, 3};
		anim.AddFrames(frames);
		
		tailrotor.SetOffset(Vec2f(33, -8.5));
		tailrotor.SetRelativeZ(0.0f);
		tailrotor.SetVisible(true);
	}

	//Add launcher
	CSpriteLayer@ rocket = this.addSpriteLayer("rocketlauncher", "UHT_Launcher.png", 16, 16);
	if (rocket !is null)
	{
		rocket.SetOffset(rocketminiGun_offset);
		rocket.SetRelativeZ(50.0f);
		rocket.SetVisible(true);
	}
	
	//Add copter wing
	CSpriteLayer@ wing = this.addSpriteLayer("wing", "UHT_Wing.png", 13, 5);
	if (wing !is null)
	{
		Animation@ anim = wing.addAnimation("default", 0, false);
		anim.AddFrame(1);
		wing.SetOffset(Vec2f(-9, 0));
		wing.SetRelativeZ(50.5f);
		wing.SetVisible(true);
	}
	
	//Add balkenkreuz
	CSpriteLayer@ balkenkreuz = this.addSpriteLayer("balkenkreuz", "UHT_Balkenkreuz.png", 10, 10);
	if (balkenkreuz !is null)
	{
		balkenkreuz.SetOffset(Vec2f(-9, 0));
		//balkenkreuz.SetRelativeZ(0.0f);
		balkenkreuz.SetVisible(true);
	}

	this.SetEmitSound("Eurokopter_Loop.ogg");
	this.SetEmitSoundSpeed(0.01f);
	this.SetEmitSoundPaused(false);
}

void updateLayer(CSprite@ sprite, string name, int index, bool visible, bool remove)
{
	if (sprite !is null)
	{
		CSpriteLayer@ layer = sprite.getSpriteLayer(name);
		if (layer !is null)
		{
			if (remove == true)
			{
				sprite.RemoveSpriteLayer(name);
				return;
			}
			else
			{
				layer.SetFrameIndex(index);
				layer.SetVisible(visible);
			}
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onTick(CBlob@ this)
{	
	if (this !is null)
	{
		CSprite@ sprite = this.getSprite();
		CShape@ shape = this.getShape();
		Vec2f currentVel = this.getVelocity();
		f32 angle = shape.getAngleDegrees();

		const bool flip = this.isFacingLeft();

		Vec2f newForce = Vec2f(0, 0);

		AttachmentPoint@[] aps;
		this.getAttachmentPoints(@aps);
		
		CSpriteLayer@ blade = sprite.getSpriteLayer("blade");
		CSpriteLayer@ tailrotor = sprite.getSpriteLayer("tailrotor");
		if (blade !is null)
		{
			blade.ResetTransform();
			blade.SetRelativeZ(0.0f);
		}

		f32 fuel = GetFuel(this);

		int size = aps.size();
		for(int a = 0; a < size; a++)
		{
			AttachmentPoint@ ap = aps[a];
			if (ap !is null)
			{
				CBlob@ hooman = ap.getOccupied();
				if (hooman !is null)
				{
					if (ap.name == "DRIVER")
					{
						const bool pressed_w  = ap.isKeyPressed(key_up);
						const bool pressed_s  = ap.isKeyPressed(key_down);
						const bool pressed_a  = ap.isKeyPressed(key_left);
						const bool pressed_d  = ap.isKeyPressed(key_right);
						const bool pressed_c  = ap.isKeyPressed(key_pickup);
						const bool pressed_m1 = ap.isKeyPressed(key_action1);
						const bool pressed_m2 = ap.isKeyPressed(key_action2);

						const f32 mass = this.getMass();

						if (fuel > 0)
						{
							if (pressed_a) newForce += leftVelo;
							if (pressed_d) newForce += rightVelo;
							
							if (pressed_m1)this.set_bool("glide", true);
							else
							{
								this.set_bool("glide", false);
								if (pressed_w) newForce += upVelo;
								if (pressed_s) newForce += downVelo;
							}
						}
						else
						{
							return;
						}
						Vec2f mousePos = ap.getAimPos();
						CBlob@ pilot = ap.getBlob();
						if (pilot !is null && pressed_m2 && (this.getVelocity().x < 5.00f || this.getVelocity().x > -5.00f))
						{
							if (mousePos.x < pilot.getPosition().x) this.SetFacingLeft(true);
							else if (mousePos.x > pilot.getPosition().x) this.SetFacingLeft(false);
						}
						else if (this.getVelocity().x < -1.750f)
							this.SetFacingLeft(true);
						else if (this.getVelocity().x > 1.750f)
							this.SetFacingLeft(false);
						
						CSpriteLayer@ rocket = sprite.getSpriteLayer("rocketlauncher");
						CSpriteLayer@ minigun = sprite.getSpriteLayer("minigun");
						CBlob@ passanger = this.getAttachmentPoint(1).getOccupied();
						if (passanger is null)
						{
							minigun.ResetTransform();
							rocket.ResetTransform();
						}
					}
					else if (ap.name == "PASSENGER" && hooman !is null)
					{
						bool pressed_m1 = ap.isKeyPressed(key_action1);
						bool pressed_m2 = ap.isKeyPressed(key_action2);
						Vec2f GunAimPos = hooman.getAimPos();
						CBlob@ realPlayer = getLocalPlayerBlob();
						const f32 flip_factor = flip ? -1: 1;
						
						
						CSpriteLayer@ minigun = sprite.getSpriteLayer("minigun");
						if (minigun !is null)
						{
							if (this.get_bool("lastTurn") != flip)
							{
								this.set_bool("lastTurn", flip);
								minigun.ResetTransform();

								CSpriteLayer@ rocket = sprite.getSpriteLayer("rocketlauncher");
								if (rocket !is null)
								{
									rocket.ResetTransform();
								}
							}

							Vec2f aimvector = GunAimPos - minigun.getWorldTranslation();
							aimvector.RotateBy(-this.getAngleDegrees());

							const f32 angle = constrainAngle(-aimvector.Angle() + (flip ? 180 : 0)) * flip_factor;
							const f32 clampedAngle = (Maths::Clamp(angle, gun_clampAngle.x, gun_clampAngle.y) * flip_factor);

							this.set_f32("gunAngle", clampedAngle);

							minigun.ResetTransform();
							minigun.RotateBy(clampedAngle, Vec2f(5 * flip_factor, 1));

							CSpriteLayer@ flash = sprite.getSpriteLayer("muzzle_flash");
							if (flash !is null)
							{
								GunSettings@ settings;
								this.get("gun_settings", @settings);

								flash.ResetTransform();
								flash.SetRelativeZ(1.0f);
								flash.RotateBy(clampedAngle, Vec2f(20 * flip_factor, 1));
							}

							if (pressed_m1)
							{
								if (getGameTime() > this.get_u32("fireDelayGun") && realPlayer !is null && realPlayer is hooman)
								{
									CBitStream params;
									params.write_s32(this.get_f32("gunAngle"));
									params.write_Vec2f(minigun.getWorldTranslation());
									this.SendCommand(this.getCommandID("shoot"), params);
									this.set_u32("fireDelayGun", getGameTime() + (shootDelay));
								}
							}
						}

						CSpriteLayer@ rocket = sprite.getSpriteLayer("rocketlauncher");
						if (rocket !is null)
						{
							Vec2f aimvector = GunAimPos - rocket.getWorldTranslation();
							aimvector.RotateBy(-this.getAngleDegrees());

							const f32 angle = constrainAngle(-aimvector.Angle() + (flip ? 180 : 0)) * flip_factor;
							const f32 RocketClampedAngle = Maths::Clamp(angle, rocket_clampAngle.x, rocket_clampAngle.y) * flip_factor;

							this.set_f32("rocketAngle", RocketClampedAngle);

							rocket.ResetTransform();
							rocket.RotateBy(RocketClampedAngle, Vec2f(0,0));

							if (pressed_m2)
							{
								if (getGameTime() > this.get_u32("fireDelayRocket") && realPlayer !is null && realPlayer is hooman)
								{
									CBlob@ target = getMap().getBlobAtPosition(GunAimPos);

									CBitStream params;
									params.write_u16(target !is null ? target.getNetworkID() : 0);
									params.write_s32(this.get_f32("rocketAngle"));
									params.write_Vec2f(rocket.getWorldTranslation());
									this.SendCommand(this.getCommandID("shootRocket"), params);
									this.set_u32("fireDelayRocket", getGameTime() + shootDelayRocket);
								}
							}
						}
					}
				}
			}
		}
		Vec2f targetForce;
		Vec2f currentForce = this.get_Vec2f("current_force");
		CBlob@ pilot = this.getAttachmentPoint(0).getOccupied();
		if (fuel > 0 && pilot !is null) targetForce = this.get_Vec2f("target_force") + newForce;
		else targetForce = Vec2f(0, 0);
		
		CSpriteLayer@ balkenkreuz = this.getSprite().getSpriteLayer("balkenkreuz");
		
		if (this.getTeamNum() == 250) balkenkreuz.SetVisible(true);
		else balkenkreuz.SetVisible(false);
		balkenkreuz.SetOffset(Vec2f(9, 4.5));

		f32 targetForce_y = Maths::Clamp(targetForce.y, minClampVelocity.y, maxClampVelocity.y);

		Vec2f clampedTargetForce = Vec2f(Maths::Clamp(targetForce.x, Maths::Max(minClampVelocity.x, -Maths::Abs(targetForce_y)), Maths::Min(maxClampVelocity.x, Maths::Abs(targetForce_y))), targetForce_y);
		
		Vec2f resultForce;
		if(!this.get_bool("glide"))
		{
			resultForce = Vec2f(Lerp(currentForce.x, clampedTargetForce.x, lerp_speed_x), Lerp(currentForce.y, clampedTargetForce.y, lerp_speed_y));
			this.set_Vec2f("current_force", resultForce);
		}
		else
		{
			resultForce = Vec2f(Lerp(currentForce.x, clampedTargetForce.x, lerp_speed_x), -0.5890000005);
			this.set_Vec2f("current_force", resultForce);
		}

		this.AddForce(resultForce * thrust);
		this.setAngleDegrees(resultForce.x * 80.00f);
		
		int anim_time_formula = Maths::Floor(1.00f + (1.00f - Maths::Abs(resultForce.getLength())) * 3) % 4;
		blade.ResetTransform();
		blade.animation.time = anim_time_formula;
		if (blade.animation.time == 0)
		{
			blade.SetFrameIndex(0);
			blade.RotateBy(180, Vec2f(0.0f,2.0f));
		}
		
		tailrotor.animation.time = anim_time_formula;
		if (tailrotor.animation.time == 0)
		{
			tailrotor.SetFrameIndex(1);
		}
		
		//if (this.get_bool("music") == false)
		sprite.SetEmitSoundSpeed(Maths::Min(0.0001f + Maths::Abs(resultForce.getLength() * 1.50f), 1.10f));
		//else sprite.SetEmitSoundSpeed(1.00f);

		this.set_Vec2f("target_force", clampedTargetForce);
		
		f32 taken = this.get_f32("fuel_consumption_modifier") * resultForce.getLength();
		
		if (this.exists("bladeid"))
		{
			CBlob@ blade = getBlobByNetworkID(this.get_u16("bladeid"));
			if (blade !is null)
			{
				blade.set_f32("damage", taken);
				blade.set_u16("angle", angle);
			}
		}
	
		if (this.getTickSinceCreated() % 5 == 0)
		{
			TakeFuel(this, taken);
		}
	}
}

const f32 lerp_speed_x = 0.20f;
const f32 lerp_speed_y = 0.20f;

f32 Lerp(f32 a, f32 b, f32 time)
{
	return a + (b - a) * time;
}

f32 constrainAngle(f32 x)
{
	x = (x + 180) % 360;
	if (x < 0) x += 360;
	return x - 180;
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attachedPoint.socket)
	{
		this.Tag("no barrier pass");
	}
	if (attached !is null)
	{
		if (attached.hasTag("flesh"))attached.SetVisible(false);
		if (attached.getName() != "donotspawnthiswithacommand")
		{
			attached.Tag("invincible");
			attached.Tag("invincibilityByVehicle");
		}
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint)
{
	if (attachedPoint.socket)
	{
		detached.setVelocity(this.getVelocity());
		detached.AddForce(Vec2f(0.0f, -300.0f));
		this.Untag("no barrier pass");
	}
	if (detached !is null)
	{
		detached.SetVisible(true);
		detached.Untag("invincible");
		detached.Untag("invincibilityByVehicle");
	}
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	if (!blob.isCollidable() || blob.isAttached()){
		return false;
	} // no colliding against people inside vehicles
	if (blob.getRadius() > this.getRadius() ||
	        (blob.getTeamNum() != this.getTeamNum() && blob.hasTag("player") && this.getShape().vellen > 1.0f) ||
	        (blob.getShape().isStatic()) || blob.hasTag("projectile"))
	{
		return true;
	}
	return false;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	Vec2f buttonPos;
	buttonPos = Vec2f(-5,2);
	if (caller.getTeamNum() == this.getTeamNum())
	{
		CBlob@ carried = caller.getCarriedBlob();
		if (carried !is null && this.get_bool("music") == false)
		{
			if(carried.getName() == "musicdisc")
			{
				u16 carried_netid = carried.getNetworkID();
	
				CBitStream params;
				params.write_u16(carried_netid);
				
				caller.CreateGenericButton("$musicdisc$", buttonPos, this, this.getCommandID("play_music"), "Make it play funny music.", params);
			}
		} else 
		if(carried !is null && this.get_bool("music") == true){
			if(carried.getName() == "wrench")
				caller.CreateGenericButton("$icon_wrench$", buttonPos, this, this.getCommandID("stop_music"), "Stop the music.");
		}
		{
			CBitStream params;
			CBlob@ carried = caller.getCarriedBlob();
			if (carried !is null && this.get_u16("rocketCount") < maxRocketStack)
			{
				params.write_netid(caller.getNetworkID());
				caller.CreateGenericButton("$icon_sammissile$", Vec2f(3, 2), this, this.getCommandID("addRocket"), "Load Missiles\n(" + this.get_u16("rocketCount") + " / " + maxRocketStack + ")", params);
			}
		}
		{
			CBitStream params;
			CBlob@ carried = caller.getCarriedBlob();
			if (carried !is null && this.get_u16("ammoCount") < maxAmmoStack)
			{
				params.write_netid(caller.getNetworkID());
				caller.CreateGenericButton("$icon_gatlingammo$", Vec2f(17, 5), this, this.getCommandID("addAmmo"), "Load Gatling Ammo\n(" + this.get_u16("ammoCount") + " / " + maxAmmoStack + ")", params);
			}
		}
		{
			CBitStream params;
			CBlob@ carried = caller.getCarriedBlob();
			if (carried !is null && this.get_f32("fuel_count") < this.get_f32("max_fuel"))
			{
				string fuel_name = carried.getName();
				bool isValid = fuel_name == "mat_fuel";

				if (isValid)
				{
					params.write_netid(caller.getNetworkID());
					CButton@ button = caller.CreateGenericButton("$" + fuel_name + "$", Vec2f(12, 0), this, this.getCommandID("load_fuel"), "Load " + carried.getInventoryName() + "\n(" + this.get_f32("fuel_count") + " / " + this.get_f32("max_fuel") + ")", params);
				}
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 dmg = damage;
	switch (customData)
	{
		case Hitters::sword:
		case Hitters::arrow:
		case Hitters::stab:
			dmg *= 0.25f;
			break;
		case Hitters::bomb:
			dmg *= 1.25f;
			break;
		case Hitters::keg:
		case Hitters::explosion:
			dmg *= 0.5f;
			break;
		case Hitters::bomb_arrow:
			dmg *= 0.5f;
			break;
		case Hitters::flying:
			dmg *= 0.5f;
			break;
	}
	if (customData == HittersTC::bullet_high_cal)
		damage *= 0.5;
	return dmg;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if(cmd == this.getCommandID("shoot"))
	{
		if (this.get_u16("ammoCount") > 0)
		{
			this.sub_u16("ammoCount", 1);
			this.Sync("ammoCount", true);
			f32 angle = params.read_s32();
			ShootGun(this, angle, params.read_Vec2f());
		}
	}
	else if(cmd == this.getCommandID("shootRocket"))
	{
		CBlob@ target = getBlobByNetworkID(params.read_u16());

		if (this.get_u16("rocketCount") > 0)
		{
			this.sub_u16("rocketCount", 1);
			this.Sync("rocketCount", true);
			f32 angle = params.read_s32();
			shootRocket(this, angle, target, params.read_Vec2f());
		}
	}
	else if(cmd == this.getCommandID("addRocket"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		CBlob@ carried = caller.getCarriedBlob();
		
		CInventory@ invo = caller.getInventory();
		int rocketCount = invo.getCount("mat_sammissile");

		if (carried !is null && carried.getName() == "mat_sammissile")
		{
			rocketCount += carried.getQuantity();
			u16 remain = GiveRockets(this, rocketCount);
			int takken = Maths::Max(0, rocketCount - remain);

			if (takken >= carried.getQuantity())
			{
				carried.Tag("dead");
				carried.server_Die();
				invo.server_RemoveItems("mat_sammissile", takken - carried.getQuantity());
			}
			else
			{
				carried.server_SetQuantity(remain);
			}
		}
	}
	else if(cmd == this.getCommandID("addAmmo"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		CBlob@ carried = caller.getCarriedBlob();
		
		CInventory@ invo = caller.getInventory();
		int ammoCount = invo.getCount("mat_gatlingammo");

		if (carried !is null && carried.getName() == "mat_gatlingammo")
		{
			ammoCount += carried.getQuantity();
			u16 remain = GiveAmmo(this, ammoCount);
			int takken = Maths::Max(0, ammoCount - remain);

			if (takken >= carried.getQuantity())
			{
				carried.Tag("dead");
				carried.server_Die();
				invo.server_RemoveItems("mat_gatlingammo", takken - carried.getQuantity());
			}
			else
			{
				carried.server_SetQuantity(remain);
			}
		}
	}
	else if (cmd == this.getCommandID("load_fuel"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		CBlob@ carried = caller.getCarriedBlob();

		if (carried !is null)
		{
			string fuel_name = carried.getName();
			f32 fuel_modifier = 1.00f;
			bool isValid = false;

			fuel_modifier = GetFuelModifier(fuel_name, isValid, 2);

			if (isValid)
			{
				u16 remain = GiveFuel(this, carried.getQuantity(), fuel_modifier);

				if (remain == 0)
				{
					carried.Tag("dead");
					carried.server_Die();
				}
				else
				{
					carried.server_SetQuantity(remain);
				}
			}
		}
	}
	else if (cmd == this.getCommandID("play_music"))
	{
		CBlob@ carried = getBlobByNetworkID(params.read_u16());
		if(carried !is null){
			this.set_bool("music", true);
			if (this.exists("bladeid"))
			{
				CBlob@ blade = getBlobByNetworkID(this.get_u16("bladeid"));
				if (blade !is null)
				{
					blade.getSprite().SetEmitSound("HELIHELI.ogg");
					blade.getSprite().SetEmitSoundPaused(false);
					blade.getSprite().SetEmitSoundVolume(0.4);
				}
			}
			carried.server_Die();
		}
	}
	else if (cmd == this.getCommandID("stop_music"))
	{
		if(this.get_bool("music") == true)
		{
			this.set_bool("music", false);
			if (this.exists("bladeid"))
			{
				CBlob@ blade = getBlobByNetworkID(this.get_u16("bladeid"));
				if (blade !is null)
				{
					blade.getSprite().SetEmitSoundPaused(true);
				}
			}
		}
	}
}

f32 GiveAmmo(CBlob@ this, f32 amount)
{
	f32 max_ammo = maxAmmoStack;
	s32 ammo_consumed = s32(max_ammo) - s32(this.get_u16("ammoCount"));
	f32 remaing_ammo = Maths::Max(0, s32(amount) - ammo_consumed);

	this.set_u16("ammoCount", Maths::Max(0, Maths::Min(max_ammo, this.get_u16("ammoCount") + (amount - remaing_ammo))));
	return remaing_ammo;
}

f32 GiveRockets(CBlob@ this, f32 amount)
{
	f32 max_ammo = maxRocketStack;
	s32 ammo_consumed = s32(max_ammo) - s32(this.get_u16("rocketCount"));
	f32 remaing_ammo = Maths::Max(0, s32(amount) - ammo_consumed);

	this.set_u16("rocketCount", Maths::Max(0, Maths::Min(max_ammo, this.get_u16("rocketCount") + (amount - remaing_ammo))));
	return remaing_ammo;
}

void onRender(CSprite@ this)
{
	if (this is null) return; //can happen with bad reload

	// draw only for local player
	CBlob@ blob = this.getBlob();
	CBlob@ localBlob = getLocalPlayerBlob();

	if (blob is null)
	{
		return;
	}

	if (localBlob is null)
	{
		return;
	}

	AttachmentPoint@ gunner = blob.getAttachments().getAttachmentWithBlob(localBlob);
	if (gunner !is null)
	{
		if(gunner.name == "DRIVER")
		{
			drawFuelCount(blob);
			renderAmmo(blob,false);
		}
		else
		{
			renderAmmo(blob,true);
		}
	}

	Vec2f mouseWorld = getControls().getMouseWorldPos();
	bool mouseOnBlob = (mouseWorld - blob.getPosition()).getLength() < this.getBlob().getRadius();
	f32 fuel = blob.get_f32("fuel_count");
	if (fuel <= 0 && mouseOnBlob)
	{
		Vec2f pos = blob.getInterpolatedScreenPos();

		GUI::SetFont("menu");
		GUI::DrawTextCentered("Requires fuel!", Vec2f(pos.x, pos.y + 85 + Maths::Sin(getGameTime() / 5.0f) * 5.0f), SColor(255, 255, 55, 55));
		GUI::DrawTextCentered("(Fuel)", Vec2f(pos.x, pos.y + 105 + Maths::Sin(getGameTime() / 5.0f) * 5.0f), SColor(255, 255, 55, 55));
	}
}

const f32 fuel_factor = 100.00f;

void renderAmmo(CBlob@ blob, bool rocket)
{//this is for weapon system officer
	if (rocket)
	{
		int gatling_ammo = blob.get_u16("ammoCount");
		int rocket_ammo = blob.get_u16("rocketCount");
		string role = "You are a weapon system officer";
		string reqsText = "Ammo: " + gatling_ammo + " / " + maxAmmoStack + " | Rockets: " + rocket_ammo + " / " + maxRocketStack;
		string help = "LMB for Machine gun | RMB for Rocket Launcher";
		int shift = 20;
		//GUI::DrawTextCentered(rocket_reqsText, blob.getInterpolatedScreenPos() + Vec2f(0, 60 + shift), color_white);
		
		GUI::SetFont("menu");
		GUI::DrawTextCentered(role, blob.getInterpolatedScreenPos() + Vec2f(0, 60 + shift), color_white);
		GUI::DrawTextCentered(reqsText, blob.getInterpolatedScreenPos() + Vec2f(0, 75 + shift), color_white);
		if (u_showtutorial)
		{
			//shift = 0;
			GUI::DrawTextCentered(help, blob.getInterpolatedScreenPos() + Vec2f(0, 90 + shift), color_white);
		}
	}
}

void ShootGun(CBlob@ this, f32 angle, Vec2f gunPos)
{
	if (isServer())
	{
		f32 sign = (this.isFacingLeft() ? -1 : 1);
		angle += ((XORRandom(400) - 100) / 100.0f);
		angle += this.getAngleDegrees();

		GunSettings@ settings;
		this.get("gun_settings", @settings);

		Vec2f fromBarrel = Vec2f((settings.MUZZLE_OFFSET.x + 5) * -sign, settings.MUZZLE_OFFSET.y);
		fromBarrel.RotateBy(this.getAngleDegrees());

		CBlob@ passanger = this.getAttachmentPoint(1).getOccupied();
		if (passanger !is null)
		{
			shootGun(this.getNetworkID(), angle, passanger.getNetworkID(), this.getPosition() + fromBarrel);
		}
	}

	if (isClient())
	{
		CSpriteLayer@ flash = this.getSprite().getSpriteLayer("muzzle_flash");
		if (flash !is null)
		{
			//Turn on muzzle flash
			flash.SetFrameIndex(0);
			flash.SetVisible(true);
		}
		this.getSprite().PlaySound("Helichopper_Shoot.ogg", 2.00f);
	}

	this.set_u32("fireDelayGunSprite", getGameTime() + (shootDelay + 1)); //shoot delay increased to compensate for cmd time
}

void shootGun(const u16 gunID, const f32 aimangle, const u16 hoomanID, const Vec2f pos) 
{
	CRules@ rules = getRules();
	CBitStream params;

	params.write_netid(hoomanID);
	params.write_netid(gunID);
	params.write_f32(aimangle);
	params.write_Vec2f(pos);
	params.write_u32(getGameTime());

	rules.SendCommand(rules.getCommandID("fireGun"), params);
}

void shootRocket(CBlob@ this, f32 angle, CBlob@ target, Vec2f gunPos)
{
	Vec2f dir = Vec2f((this.isFacingLeft() ? -1 : 1), 0.0f).RotateBy(angle);
	Vec2f startPos = gunPos;

	if (isServer())
	{
		CBlob@ m = server_CreateBlobNoInit("sammissile");
		m.setPosition(startPos);
		m.set_Vec2f("direction", dir);
		m.set_u16("target", target !is null ? target.getNetworkID() : 0);
		m.set_f32("velocity", 15.00f);
		m.server_setTeamNum(this.getTeamNum());
		m.Init();
	}

	if (isClient())
	{
		for (int i = 1; i < 5; i++) {MakeParticle(this, -dir * i, "SmallExplosion");}
		this.getSprite().PlaySound("Missile_Launch.ogg");
	}

	//this.set_u32("fireDelayRocket", getGameTime() + shootDelayRocket);
}

void MakeParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	Vec2f offset = Vec2f(8, 0).RotateBy(this.getAngleDegrees());
	ParticleAnimated(filename, this.getPosition() + offset, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}

void drawFuelCount(CBlob@ this)
{//this is for pilot
	int fuel = this.get_f32("fuel_count");
	string role = "You are a pilot";
	string reqsText = "Fuel: " + fuel + " / " + this.get_f32("max_fuel");
	string help = "Hold LMB to stop vertical acceleration";
	string help2 = "Hold RMB to set helicopter's facing in a cursor direction";
	int shift = 20;

	GUI::SetFont("menu");
	GUI::DrawTextCentered(role, this.getInterpolatedScreenPos() + Vec2f(0, 60 + shift), color_white);
	GUI::DrawTextCentered(reqsText, this.getInterpolatedScreenPos() + Vec2f(0, 75 + shift), color_white);
	if (u_showtutorial) {
		//shift = 0;
		GUI::DrawTextCentered(help, this.getInterpolatedScreenPos() + Vec2f(0, 90 + shift), color_white);
		GUI::DrawTextCentered(help2, this.getInterpolatedScreenPos() + Vec2f(0, 105 + shift), color_white);
	}
}

void onDie(CBlob@ this)
{
	DoExplosion(this);
	
	if (this.exists("bladeid"))
	{
		CBlob@ blade = getBlobByNetworkID(this.get_u16("bladeid"));
		if (blade !is null)
		{
			blade.server_Die();
		}
	}
/*
	if (isServer())
	{
		CBlob@ wreck = server_CreateBlobNoInit("helichopperwreck");
		wreck.setPosition(this.getPosition());
		wreck.setVelocity(this.getVelocity());
		wreck.setAngleDegrees(this.getAngleDegrees());
		wreck.server_setTeamNum(this.getTeamNum());
		wreck.Init();
	}
*/
}

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

void DoExplosion(CBlob@ this)
{
	CRules@ rules = getRules();
	if (!shouldExplode(this, rules))
	{
		addToNextTick(this, rules, DoExplosion);
		return;
	}

	this.set_f32("map_damage_radius", 48.0f);
	this.set_f32("map_damage_ratio", 0.4f);
	f32 angle = this.get_f32("bomb angle");

	Explode(this, 100.0f, 50.0f);

	for (int i = 0; i < 4; i++) 
	{
		Vec2f dir = getRandomVelocity(angle, 1, 40);
		LinearExplosion(this, dir, 40.0f + XORRandom(64), 48.0f, 6, 0.5f, Hitters::explosion);
	}

	Vec2f pos = this.getPosition() + this.get_Vec2f("explosion_offset").RotateBy(this.getAngleDegrees());
	CMap@ map = getMap();

	if (isServer())
	{
		for (int i = 0; i < (5 + XORRandom(5)); i++)
		{
			CBlob@ blob = server_CreateBlob("flame", -1, this.getPosition());
			blob.setVelocity(Vec2f(XORRandom(10) - 5, -XORRandom(10)));
			blob.server_SetTimeToDie(10 + XORRandom(5));
		}
	}

	if (isClient())
	{
		for (int i = 0; i < 40; i++)
		{
			MakeParticle(this, Vec2f( XORRandom(64) - 32, XORRandom(80) - 60), getRandomVelocity(angle, XORRandom(400) * 0.01f, 70), particles[XORRandom(particles.length)]);
		}
	}

	this.getSprite().Gib();
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 1 + XORRandom(200) * 0.01f, 2 + XORRandom(5), XORRandom(100) * -0.00005f, true);
}