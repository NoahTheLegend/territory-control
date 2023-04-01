#include "VehicleCommon.as"
//made by Pankov
// Mounted Bow logic

const Vec2f arm_offset = Vec2f(-36, -14);

void onInit(CBlob@ this)
{
	this.Tag("usable by anyone");
	this.Tag("turret");

	Vehicle_Setup(this,
	              65.0f, // move speed
	              0.1f,  // turn speed
	              Vec2f(0.0f, 0.0f), // jump out velocity
	              false  // inventory access
	             );

	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	Vehicle_SetupWeapon(this, v,
	                    45, // fire delay (ticks)
	                    1, // fire bullets amount
	                    Vec2f(50.0f, 2.0f), // fire position offset
	                    "mat_tankshell", // bullet ammo config name
	                    "tankshell", // bullet config name
	                    "KegExplosion", // fire sound
	                    "EmptyFire" // empty fire sound
	                   );
	v.charge = 400;
	// init arm

	this.getShape().SetRotationsAllowed(true);
	this.set_string("autograb blob", "mat_tankshell");

		Vehicle_SetupGroundSound(this, v, "WoodenWheelsRolling",  // movement sound
	                         1.0f, // movement sound volume modifier   0.0f = no manipulation
	                         1.0f // movement sound pitch modifier     0.0f = no manipulation
	                        );
	Vehicle_addWheel(this, v, "WoodenWheels.png", 16, 16, 0, Vec2f(-16.0f, 6.0f));

	this.getCurrentScript().runFlags |= Script::tick_hasattached;

	// auto-load on creation
	if (isServer())
	{
		CBlob@ ammo = server_CreateBlob("mat_tankshell");
		if (ammo !is null)
		{
			if (!this.server_PutInInventory(ammo)) ammo.server_Die();
		}
	}
}

void onInit(CSprite@ this)
{
	CSpriteLayer@ arm = this.addSpriteLayer("arm", "autocannon_Cannon.png", 71, 20);
	if (arm !is null)
	{
		{
			Animation@ anim = arm.addAnimation("default", 0, true);
			int[] frames = {0};
			anim.AddFrames(frames);
		}
		{
			Animation@ anim = arm.addAnimation("shoot", 2, false);
			int[] frames = {0, 1};
			anim.AddFrames(frames);
		}

		arm.SetOffset(arm_offset);
	}

	this.SetZ(-20.0f);
}

void onTick(CSprite@ this)
{
	CSpriteLayer@ arm = this.getSpriteLayer("arm");
	if (arm.isAnimationEnded()) arm.SetAnimation("default");
}

f32 getAimAngle(CBlob@ this, VehicleInfo@ v)
{
	f32 angle = Vehicle_getWeaponAngle(this, v);
	bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("GUNNER");
	bool failed = true;

	f32 targetAngle;

	if (gunner !is null && gunner.getOccupied() !is null)
	{
		gunner.offsetZ = 5.0f;
		Vec2f aim_vec = gunner.getPosition() + Vec2f(16,0) - gunner.getAimPos();

		if (this.isAttached())
		{
			return 0;
		}
		else
		{
			if ((!facing_left && aim_vec.x < 0) ||
			     (facing_left && aim_vec.x > 0))
			{
				if (aim_vec.x > 0) aim_vec.x = -aim_vec.x;

				targetAngle = (-(aim_vec).getAngle() + 180.0f);
				targetAngle = Maths::Max(-35.0f, Maths::Min(targetAngle, 35.0f));

				if (angle >= targetAngle-1 && angle <= targetAngle+1) return angle;
				else if (angle > targetAngle) angle--;
				else if (angle < targetAngle) angle++;
			}
			else this.SetFacingLeft(!facing_left);
		}
	}

	return angle;
}

void onTick(CBlob@ this)
{
	if (this.hasAttached() || this.getTickSinceCreated() < 30) //driver, seat or gunner, or just created
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v)) return;

		//set the arm angle based on GUNNER mouse aim, see above ^^^^
		f32 angle = getAimAngle(this, v);
		Vehicle_SetWeaponAngle(this, angle, v);
		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ arm = sprite.getSpriteLayer("arm");

		if (arm !is null)
		{
			bool facing_left = sprite.isFacingLeft();
			f32 rotation = angle * (facing_left ? -1 : 1);

			arm.ResetTransform();
			arm.SetFacingLeft(facing_left);
			arm.SetRelativeZ(50.0f);
			arm.SetOffset(arm_offset);
			arm.RotateBy(rotation*1.2f, Vec2f(facing_left ? -16.0f : 16.0f, 0.0f));
		}

		Vehicle_StandardControls(this, v);
	}
	if (this.hasTag("invincible") && this.isAttached())
	{
		CBlob@ gunner = this.getAttachmentPoint(0).getOccupied();
		if (gunner !is null)
		{
			gunner.Tag("invincible");
			gunner.Tag("invincibilityByVehicle");
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (!Vehicle_AddFlipButton(this, caller))
	{
		Vehicle_AddLoadAmmoButton(this, caller);
	}
}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _unused)
{
	if (isClient()) this.getSprite().getSpriteLayer("arm").SetAnimation("shoot");

	if (bullet !is null)
	{
		bullet.server_setTeamNum(this.getTeamNum());

		u16 charge = v.charge;
		f32 angle = this.getAngleDegrees() + Vehicle_getWeaponAngle(this, v);
		angle = angle * (this.isFacingLeft() ? -1 : 1);

		Vec2f vel = Vec2f((30.0f + (XORRandom(40) / 1000.0f) * 2.0f ) * (this.isFacingLeft() ? -1 : 1), 0.0f).RotateBy(angle);
		bullet.setVelocity(vel);

		Vec2f offset = Vec2f((this.isFacingLeft() ? -1 : 1) * 68, -14);
		offset.RotateBy(angle);
		bullet.setPosition(this.getPosition() + offset);

		bullet.server_SetTimeToDie(-1);
		bullet.server_SetTimeToDie(0.8f);

		if (isClient())
		{
			Vec2f dir = Vec2f((this.isFacingLeft() ? -1 : 1), 0.0f).RotateBy(angle);
			ParticleAnimated("SmallExplosion.png", this.getPosition() + offset, dir, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("fire blob"))
	{
		CBlob@ blob = getBlobByNetworkID(params.read_netid());
		const u8 charge = params.read_u8();
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v)) return;

		Vehicle_onFire(this, v, blob, charge);
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return true;
	// return this.getTeamNum() == byBlob.getTeamNum();
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic() && blob.isCollidable();
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null) TryToAttachVehicle(this, blob);
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return false;

	CInventory@ inv = forBlob.getInventory();

	return forBlob.getCarriedBlob() is null && (inv !is null ? inv.getItem(v.ammo_name) is null : true);
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attached.hasTag("bomber")) return;

	if (attached.getPlayer() !is null && this.hasTag("invincible"))
	{
		if (this.isAttached())
		{
			attached.Tag("invincible");
			attached.Tag("invincibilityByVehicle");
		}
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached.hasTag("invincibilityByVehicle"))
	{
		detached.Untag("invincible");
		detached.Untag("invincibilityByVehicle");
	}
}
