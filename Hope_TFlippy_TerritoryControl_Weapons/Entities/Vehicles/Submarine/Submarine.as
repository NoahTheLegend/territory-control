#include "Hitters.as";
#include "HittersTC.as";

void onInit(CBlob@ this)
{
	this.set_Vec2f("force", Vec2f_zero);
	this.set_f32("ap_offsetz", 10.0f);
	this.Tag("save_detach_collision");
	this.Tag("vehicle");

	this.addCommandID("launch_missile");
	this.set_f32("wrench_repair_amount", 30.0f);

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("DRIVER");
	if (ap is null)
    
	ap.SetKeysToTake(key_left | key_right | key_up | key_down);

	this.getShape().SetRotationsAllowed(false);
	CSprite@ sprite = this.getSprite();

	sprite.SetEmitSound("HeavyEngineRun_mid.ogg");
	sprite.SetEmitSoundVolume(0.0f);
	sprite.SetEmitSoundSpeed(1.0f);
	sprite.SetEmitSoundPaused(false);
	sprite.SetZ(-50.0f);

	this.SetLight(true);
	this.SetLightRadius(64.0f);
	this.SetLightColor(SColor(255, 255, 240, 210));

	CSpriteLayer@ decal = sprite.addSpriteLayer("screw", "Screw.png", 4, 19);
	if (decal !is null)
	{
		Animation@ def = decal.addAnimation("default", 2, true);
		int[] frames = {0,1,2,3,4,5,6,7};
		def.AddFrames(frames);

		decal.SetRelativeZ(49.0f);
		decal.SetOffset(Vec2f(43, 0.0f));
		decal.SetAnimation(def);
	}	

	CShape@ shape = this.getShape();
	Vec2f raw_offset = Vec2f(8, 14);

	shape.SetOffset(raw_offset);
	Vec2f pos_off = Vec2f(this.isFacingLeft() ? 16 : -16, -14) + raw_offset;
	{
		// back
		Vec2f[] s = { Vec2f( -20.0f,  -21.0f ) -pos_off,
						  Vec2f( 0.0f,  -25.0f ) -pos_off,
						  Vec2f( 0.0f,  2.0f ) -pos_off,
						  Vec2f( -20.0f,  -2.0f ) -pos_off 
						};
		shape.AddShape(s);
	}
	
	{
		// front
		Vec2f[] s = { Vec2f( 52.0f,  -25.0f ) -pos_off,
						  Vec2f( 54.0f,  -25.0f ) -pos_off,
						  Vec2f( 54.0f,  1.0f ) -pos_off,
						  Vec2f( 59.0f,  1.0f ) -pos_off 
						};
		shape.AddShape(s);
	}

	{
		// right exit
		Vec2f[] s = { Vec2f(39.0f, -26.0f) - pos_off,
		                  Vec2f(54.0f,  -25.0f) - pos_off,
		                  Vec2f(54.0f,  -22.0f) - pos_off,
		                  Vec2f(39.0f, -24.0f) - pos_off
		                };
		shape.AddShape(s);
	}

	{
		// left  exit
		Vec2f[] s = { Vec2f(0.0f, -26.0f) - pos_off,
		                  Vec2f(23.0f,  -26.0f) - pos_off,
		                  Vec2f(23.0f,  -24.0f) - pos_off,
		                  Vec2f(0.0f, -24.0f) - pos_off
		                };
		shape.AddShape(s);
	}

	getMap().server_AddMovingSector(Vec2f(-20.0f, -10.0f), Vec2f(35.0f, 12.0f), "airpocket", this.getNetworkID());
	getMap().server_AddMovingSector(Vec2f(10.0f, -10.0f), Vec2f(20.0f, 8.0f), "ladder", this.getNetworkID());
}

void makeBubbleParticle(CBlob@ this, const Vec2f vel, const string filename = "Bubble")
{
	if (!isClient()) return;
	const f32 rad = this.getRadius();
	if (this.isFacingLeft())
	{
	   {
	     Vec2f random = Vec2f(43.0f, 3.0f);
		 Vec2f sus = getRandomVelocity(90.0f, 3.0f, 90.0f);
	     ParticleAnimated(filename, this.getPosition() + random + sus, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
	   }
	return;
	}   
	Vec2f random = Vec2f(-43.0f, 3.0f);
	Vec2f sus = getRandomVelocity(90.0f, 3.0f, 90.0f);
	ParticleAnimated(filename, this.getPosition() + random + sus, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}

const f32 damp = 0.8f;
const Vec2f force_horizontal = Vec2f(0.2f, -0.2f); // right left
const Vec2f force_vertical = Vec2f(-0.1f, 0.1f); // up down
const f32 max_speed = 10.0f;
const f32 turn_speed = 1.2f;

void onTick(CBlob@ this)
{
	bool inwater = getMap().isInWater(this.getPosition() - Vec2f(0, 2));

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("DRIVER");
	if (ap is null) return;

	CShape@ shape = this.getShape();
	if (shape is null) return;

	const Vec2f vel = this.getVelocity();
	shape.SetGravityScale(inwater ? 0 : 1);

	Vec2f force = this.get_Vec2f("force");
	Vec2f target_force = force;

	CBlob@ pilot = ap.getOccupied();
	if (inwater && pilot !is null && shape.vellen < max_speed)
	{
		bool left = ap.isKeyPressed(key_left);
		bool right = ap.isKeyPressed(key_right);
		bool up = ap.isKeyPressed(key_up);
		bool down = ap.isKeyPressed(key_down);

		f32 accel = this.get_f32("gyromat_acceleration");;

		if (up) target_force += Vec2f(0, force_vertical.x * accel);
		if (down) target_force += Vec2f(0, force_vertical.y * accel);
		if (left) target_force += Vec2f(force_horizontal.y * accel, 0);
		if (right) target_force += Vec2f(force_horizontal.x * accel, 0);

		if (left && vel.x < -turn_speed) this.SetFacingLeft(true);
		if (right && vel.x > turn_speed) (this.SetFacingLeft(false));
	}

	target_force *= damp;

	this.set_Vec2f("force", target_force);
	this.AddForce(target_force * this.getMass());

	AttachmentPoint@[] aps;

	if (this.isInWater())
	{
		if (!isClient()){ return;}
		makeBubbleParticle(this, Vec2f(), XORRandom(100) > 50 ? "Bubble" : "SmallBubble1");
	}

	if (ap.isKeyPressed(key_left) || ap.isKeyPressed(key_right) || ap.isKeyPressed(key_up) || ap.isKeyPressed(key_down))
	{    
		this.getSprite().PlaySound("HoverBike_Loop.ogg", 0.4f, 0.4f);
	}	
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return true;
}

void onAttach(CBlob@ this,CBlob@ attached,AttachmentPoint @attachedPoint)
{
	attached.Tag("invincible");
	attached.Tag("invincibilityByVehicle");
}

void onDetach(CBlob@ this,CBlob@ detached,AttachmentPoint@ attachedPoint)
{
	detached.Untag("invincible");
	detached.Untag("invincibilityByVehicle");
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return ((this.getTeamNum() > 100 ? true : forBlob.getTeamNum() == this.getTeamNum()) && forBlob.getDistanceTo(this) < 32.0f);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("launch_missile"))
	{
		if (!isServer()) return;
		u16 pid;
		if (!params.saferead_u16(pid)) return;

		CPlayer@ p = getPlayerByNetworkId(pid);
		if (p is null) return;

		CBlob@ caller = p.getBlob();
		if (caller is null) return;

		CInventory@ inv = this.getInventory();

		for (u8 i = 0; i < 32; i++)
		{
			CBlob@ item = inv.getItem(i);
			if (item is null) continue;
			if (item.hasTag("cruisemissile"))
			{
				CBitStream params1;
				params1.write_u16(caller.getNetworkID());
				params1.write_u16(pid);

				this.server_PutOutInventory(item);
				item.setPosition(this.getPosition() + (this.isFacingLeft() ? Vec2f(16,-4) : Vec2f(-16,-4)));
				item.IgnoreCollisionWhileOverlapped(this);
				item.SendCommand(item.getCommandID("offblast"), params1);
				break;
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 32.0f) return;
	if (!isInventoryAccessible(this, caller)) return;
	
	CInventory@ inv = this.getInventory();
	bool close = true;
	for (u8 i = 0; i < 32; i++)
	{
		CBlob@ item = inv.getItem(i);
		if (item is null) continue;
		if (item.hasTag("cruisemissile"))
		{
			close = false;
			break;
		}
	}
	if (close) return;

	CPlayer@ ply = caller.getPlayer();
	if (ply !is null)
	{
		CBitStream params;
		params.write_u16(ply.getNetworkID());

		caller.CreateGenericButton(11, Vec2f(-12.0f, 0), this, this.getCommandID("launch_missile"), "Off blast!", params);
	}
}

void onInit(CSprite@ this)
{
	this.SetZ(-40); //background

	CBlob@ blob = this.getBlob();
	CSpriteLayer@ front = this.addSpriteLayer("front", this.getFilename() , 90, 32, blob.getTeamNum(), blob.getSkinNum());
	front.SetOffset(Vec2f(0.0f, 0.0f));

	if (front !is null)
	{
		Animation@ anim = front.addAnimation("dymlayer", 0, false);
		anim.AddFrame(12);
		front.SetRelativeZ(99);
	}
}

void onTick(CSprite@ this)
{
	CBlob@ b = this.getBlob();
	if (b is null) return;

	f32 vel = b.isInWater() ? Maths::Clamp(b.getVelocity().Length(), 0.5f, 1.5f) : 0;
	this.SetEmitSoundVolume(vel);
	this.SetEmitSoundSpeed(Maths::Clamp(vel, 0.75f, 1.25f));

	CSpriteLayer@ front = this.getSpriteLayer("front");
	if (front !is null)
	{
		bool visible = false;
		CBlob@ blob = this.getBlob();
		CBlob@ pb = getLocalPlayerBlob();

		if (pb !is null)
		{
			visible = pb.getDistanceTo(blob) >= 48.0f;
		}

		front.SetVisible(visible);
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 dmg = damage;
	if (hitterBlob !is null && hitterBlob.hasTag("rpgmissile")) dmg *= 10;

	switch (customData)
	{
		// TC		
		case HittersTC::bullet_low_cal:
		case HittersTC::bullet_high_cal:
		case HittersTC::shotgun:
			dmg *= 2.00f;
			break;
			
		case HittersTC::radiation:
			// dmg = Maths::Max((dmg * 2.00f) * (this.get_u8("radpilled") * 0.10f), 0);
			dmg *= Maths::Floor(2.00f / (1.00f + this.get_u8("radpilled") * 0.25f));
			break;
		// Vanilla
		case Hitters::builder:
			dmg *= 10;
			break;

		case Hitters::spikes:
		case Hitters::sword:
		case Hitters::arrow:
		case Hitters::stab:
			dmg *= 0;
			break;

		case Hitters::drill:
		case Hitters::bomb_arrow:
		case Hitters::bomb:
			dmg *= 2.50f;
			break;

		case Hitters::keg:
		case Hitters::explosion:
		case Hitters::crush:
			dmg *= 1.00f;
			break;

		case Hitters::cata_stones:
		case Hitters::flying: // boat ram
			dmg *= 10.00f;
			break;
	}

	return dmg;
}