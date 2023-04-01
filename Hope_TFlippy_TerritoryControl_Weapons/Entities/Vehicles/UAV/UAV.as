#include "Explosion.as";
#include "GunCommon.as";
#include "VehicleFuel.as";

const u32 fuel_timer_max = 30 * 5;
const f32 altitude_goal = 250.00f;
const Vec2f arm_offset = Vec2f(-4, 4);
const Vec2f gun_clampAngle = Vec2f(-10, 90);
const u16 maxAmmo = 500;

string[] particlesanim = 
{
	"SmallSteam",
	"MediumSteam",
	"LargeSmoke",
};

void onInit(CSprite@ this)
{
	this.SetZ(20);

	// Add arm
	CSpriteLayer@ mini = this.addSpriteLayer("arm", "MachineGun_Top.png", 32, 8);
	if (mini !is null)
	{
		mini.SetOffset(arm_offset);
		mini.SetRelativeZ(-50.0f);
		mini.SetVisible(true);
	}

	// Add muzzle flash
	CSpriteLayer@ flash = this.addSpriteLayer("muzzle_flash", "flash_bullet.png", 16, 8);
	if (flash !is null)
	{
		GunSettings@ settings;
		this.getBlob().get("gun_settings", @settings);

		Animation@ anim = flash.addAnimation("default", 1, false);
		int[] frames = {0, 1, 2, 3, 4, 5, 6, 7};
		anim.AddFrames(frames);
		flash.SetRelativeZ(1.0f);
		flash.SetOffset(Vec2f(arm_offset) + Vec2f(-21.0f, -1));
		flash.SetVisible(false);
		// flash.setRenderStyle(RenderStyle::additive);
	}

	this.SetEmitSound("Helichopper_Loop.ogg");
	this.SetEmitSoundSpeed(1.50f);
	this.SetEmitSoundVolume(0.60f);
	this.SetEmitSoundPaused(true);
}

void onInit(CBlob@ this)
{
	this.Tag("aerial");
	this.Tag("vehicle");
	this.Tag("heavy weight");
	
	this.set_u16("controller_blob_netid", 0);
	this.set_u16("controller_player_netid", 0);
	
	this.addCommandID("offblast");
	
	this.getShape().SetRotationsAllowed(true);
	this.getCurrentScript().tickFrequency = 0;

	GunSettings settings = GunSettings();

	this.setInventoryName(this.getInventoryName()+" #"+this.getNetworkID());

	settings.B_GRAV = Vec2f(0, 0.008); //Bullet Gravity
	settings.B_TTL = 14; //Bullet Time to live
	settings.B_SPEED = 60; //Bullet speed
	settings.B_DAMAGE = 0.75f; //Bullet damage
	settings.MUZZLE_OFFSET = Vec2f(-2,13);
	settings.G_RECOIL = 0;

	this.set("gun_settings", @settings);
	this.set_f32("CustomShootVolume", 1.0f);
	this.set_u16("ammoCount", 0);

	this.get_u32("fireDelayGun");

	this.SetLightRadius(16.0f);
	this.SetLightColor(SColor(255, 255, 0, 0));
	
	this.addCommandID("offblast");
	this.addCommandID("addAmmo");
	this.addCommandID("takeAmmo");
	this.addCommandID("shoot");
	
	if (isServer())
	{
		CBlob@ blob = server_CreateBlobNoInit("uavcontroller");
		blob.setPosition(this.getPosition());
		blob.set_u16("uav_netid", this.getNetworkID());
		this.set_u16("controller_netid", blob.getNetworkID());
		this.Sync("controller_netid", true);
		blob.server_setTeamNum(this.getTeamNum());
		blob.Init();
	}

	this.getShape().SetRotationsAllowed(true);

	CSprite@ sprite = this.getSprite();
	if (sprite !is null) sprite.SetAnimation("default");
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return false;
}

bool canBePickedUp(CBlob@ byBlob)
{
	return true;
}

s32 getHeight(CBlob@ this)
{
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();

	Vec2f point;
	if (map.rayCastSolidNoBlobs(pos, pos + Vec2f(0, 1000), point))
	{
		return Maths::Max((point.y - pos.y - 8) / 8.00f, 0);
	}
	else return map.tilemapheight + 50- pos.y / 8;
}

f32 constrainAngle(f32 x)
{
	x = (x + 180) % 360;
	if (x < 0) x += 360;
	return x - 180;
}

void onTick(CBlob@ this)
{
	CMap@ map = this.getMap();
	Vec2f pos = this.getPosition();
	Vec2f end;
	
	CSprite@ sprite = this.getSprite();

	if (this.isKeyJustPressed(key_action3))
	{
		ResetPlayer(this);
		this.Untag("offblast");
		if (sprite !is null) sprite.SetEmitSoundPaused(true);
		return;
	}

	CInventory@ inv = this.getInventory();
	if (inv !is null)
	{
		bool hasBattery = inv.getItem("mat_battery") !is null;
		if (inv.getCount("mat_battery") > 0)
		{
			if (this.hasTag("offblast") && getGameTime() % 30 == 0)
			{
				this.Tag("hasEnergy");
				CBlob@ bat = inv.getItem("mat_battery");
				if (isServer() && bat !is null && bat.getQuantity() > 0)
				{
					bat.server_SetQuantity(bat.getQuantity() - 1);
				}
			}
		}
		else
		{
			if (!this.isOnGround()) this.setVelocity(Vec2f(this.getVelocity().x, 0.1f));
			this.Untag("hasEnergy");
			if (sprite !is null) sprite.SetEmitSoundPaused(true);
			return;
		}
	}

	if (sprite !is null)
	{
		if (!this.hasTag("hasEnergy") || this.getPlayer() is null)
		{
			sprite.SetEmitSoundPaused(true);
			return;
		}
		else sprite.SetEmitSoundPaused(false);
	}

	if (isServer() && (this.getHealth() <= 0.0 || (this.getTimeToDie() == 0.1 || this.getTimeToDie() == 0.09 || this.getTimeToDie() == 0.08 || this.getTimeToDie() == 0.07))) // preventing lag-tick-skip
	{
		ResetPlayer(this);
		return;
	}

	if (getGameTime() % 5 == 0 && this !is null && this.hasTag("dying"))
	{
		f32 random = XORRandom(16);
		f32 quantity = this.getQuantity();
		f32 modifier = 1 + Maths::Log(quantity);
		if(isClient())
		{
			u8 len = particlesanim.length;
			for (int i = 0; i < 20 * modifier; i++) 
			{
				MakeParticle(this, Vec2f(0+XORRandom(5)-2.0f,-1.0f+XORRandom(3)-1.0f), particlesanim[XORRandom(len)]);
			}
		}
	}
		
	const bool left = this.isKeyPressed(key_left);
	const bool right = this.isKeyPressed(key_right);
	const bool up = this.isKeyPressed(key_up);
	const bool down = this.isKeyPressed(key_down);

	const f32 fuel = GetFuel(this);
	if (fuel > 0)
	{
		f32 h = (left ? -1 : 0) + (right ? 1 : 0); 
		f32 v = (up ? -1 : 0) + (down ? 1 : 0); 
		
		Vec2f vel = Vec2f(h, v);
		Vec2f gravity = Vec2f(0, -sv_gravity * this.getMass() / 25.00f);
		Vec2f force = (vel * this.getMass() * 0.35f);
		
		this.getSprite().SetEmitSoundSpeed(Maths::Min(0.0001f + Maths::Abs(force.getLength() * 1.50f), 1.10f));

		this.AddForce(force + gravity);
		this.setAngleDegrees((this.getVelocity().x * 2.00f) + (this.isFacingLeft() ? -5 : 5));

		if (this.getTickSinceCreated() % 5 == 0)
		{
			f32 taken = this.get_f32("fuel_consumption_modifier") * (this.getVelocity().getLength() + getHeight(this)/2);
			TakeFuel(this, taken);
		}
	}

	Vec2f aimPos = this.getAimPos();
	
	this.SetFacingLeft((aimPos - pos).x <= 0);

	f32 h = (left ? -1 : 0) + (right ? 1 : 0); 
	f32 v = (up ? -1 : 0) + (down ? 1 : 0); 
	
	Vec2f vel = Vec2f(h, v);
	Vec2f gravity = Vec2f(0, -sv_gravity * this.getMass() / 25.00f);
	Vec2f force = (vel * this.getMass() * 0.25f);
	
	// print("" + force.x);
	
	this.AddForce(force + gravity);
	this.setAngleDegrees((this.getVelocity().x * 2.00f) + (this.isFacingLeft() ? -5 : 5));
	// this.setAngleDegrees(0);
	// this.setAngleDegrees(-(this.getAimPos() - this.getPosition()).Angle() + (this.isFacingLeft() ? 180 : 0));
	
	// if (this.isKeyPressed(key_action1) && this.get_u32("nextShoot") <= getGameTime())
	// {
		// Shoot(this);
	// }

	if (this.isKeyJustPressed(key_action2))
	{
		this.Tag("dying");
		this.server_SetTimeToDie(3);
	}

	CSpriteLayer@ minigun = sprite.getSpriteLayer("arm");
	if (minigun !is null)
	{
		Vec2f pos = this.getPosition();
		Vec2f aimPos = this.getAimPos();
		const bool flip = this.isFacingLeft();
		
		this.SetFacingLeft((aimPos - pos).x <= 0);

		if (this.get_bool("lastTurn") != flip)
		{
			this.set_bool("lastTurn", flip);
			minigun.ResetTransform();
		}

		Vec2f aimvector = aimPos - Vec2f(minigun.getWorldTranslation().x, minigun.getWorldTranslation().y+8);
		aimvector.RotateBy(-this.getAngleDegrees());

		const f32 flip_factor = flip ? -1: 1;
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
			flash.RotateBy(clampedAngle, Vec2f(25 * flip_factor, 1.5f));
		}

		if (this.isKeyPressed(key_action1))
		{
			if (isClient() && this.isMyPlayer())
			{
				if (getGameTime() > this.get_u32("fireDelayGun"))
				{
					CBitStream params;
					params.write_s32(this.get_f32("gunAngle"));
					params.write_Vec2f(Vec2f(minigun.getWorldTranslation().x, minigun.getWorldTranslation().y+8));
					this.SendCommand(this.getCommandID("shoot"), params);
					this.set_u32("fireDelayGun", getGameTime() + 2);
				}
			}
		}
	}
}

void ResetPlayer(CBlob@ this)
{
	if (isServer())
	{
		CPlayer@ ply = getPlayerByNetworkId(this.get_u16("controller_player_netid"));
		CBlob@ blob = getBlobByNetworkID(this.get_u16("controller_blob_netid"));
		if (blob !is null && ply !is null && !blob.hasTag("dead"))
		{
			blob.server_SetPlayer(ply);
		}
		if (blob !is null && ply !is null) blob.Tag(ply.getUsername());
	}
}

void onDie(CBlob@ this)
{
	if (isServer())
	{
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

		this.getSprite().Gib();

		CPlayer@ ply = getPlayerByNetworkId(this.get_u16("controller_player_netid"));
		CBlob@ blob = getBlobByNetworkID(this.get_u16("controller_blob_netid"));
		if (blob !is null && ply !is null && !blob.hasTag("dead"))
		{
			blob.server_SetPlayer(ply);
		}
	}
	f32 random = XORRandom(16);
	f32 quantity = this.getQuantity();
	f32 modifier = 1 + Maths::Log(quantity);
	if(isClient())
	{
		u8 len = particlesanim.length;
		for (int i = 0; i < 200 * modifier; i++) 
		{
			MakeParticle(this, Vec2f(0+XORRandom(5)-2.0f,-1.0f+XORRandom(3)-1.0f), particlesanim[XORRandom(len)]);
		}
	}
}

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	GUI::SetFont("menu");
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	bool mouseOnBlob = (mouseWorld - blob.getPosition()).getLength() < this.getBlob().getRadius();
	if (blob.isMyPlayer() && mouseOnBlob)
	{
		GUI::DrawTextCentered("Left click to shoot.\nRight click to explode.\nSpace bar to get back to your body.", blob.getInterpolatedScreenPos() + Vec2f(0, 120), color_white);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (point is null) return;
	if (this.getDistanceTo(caller) <= 48)
	{
		if (caller.getName() == "uav" || caller is null) return;

		if (caller.getTeamNum() == this.getTeamNum())
		{
			const u16 ammoCount = this.get_u16("ammoCount");
			if (ammoCount < maxAmmo)
			{
				CBitStream params;
				params.write_u16(caller.getNetworkID());
				caller.CreateGenericButton("$icon_gatlingammo$", Vec2f(-8, 0), this, 
					this.getCommandID("addAmmo"), getTranslatedString("Insert Gatling Gun Ammo"), params);
			}
			CBlob@ controller = getBlobByNetworkID(this.get_u16("controller_netid"));
			if (!this.get_bool("offblast") && (controller is null || controller.getName() != "uavcontroller"))
			{
				CPlayer@ ply = caller.getPlayer();
				if (ply !is null)
				{
					CBitStream params;
					params.write_u16(ply.getNetworkID());
					params.write_u16(caller.getNetworkID());
					
					caller.CreateGenericButton(11, Vec2f(0, -8), this, this.getCommandID("offblast"), "Control UAV", params);
				}
			}
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

		Vec2f fromBarrel = Vec2f((settings.MUZZLE_OFFSET.x + 0) * -sign, settings.MUZZLE_OFFSET.y);
		fromBarrel.RotateBy(this.getAngleDegrees());
		shootGun(this.getNetworkID(), angle, this.getNetworkID(), this.getPosition() + fromBarrel);
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
		this.getSprite().PlaySound("Helichopper_Shoot.ogg", 1.00f);
	}

	this.set_u32("fireDelayGunSprite", getGameTime() + 3);
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

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("shoot"))
	{
		if (this.get_u16("ammoCount") > 0)
		{
			this.sub_u16("ammoCount", 1);
			this.Sync("ammoCount", true);
			f32 angle = params.read_s32();
			ShootGun(this, angle, params.read_Vec2f());
		}
	}
	else if (cmd == this.getCommandID("addAmmo"))
	{
		//mat_gatlingammo
		u16 blobNum = 0;
		if (!params.saferead_u16(blobNum))
		{
			warn("addAmmo");
			return;
		}
		CBlob@ blob = getBlobByNetworkID(blobNum);
		if (blob is null) return;

		CInventory@ invo = blob.getInventory();
		if (invo !is null)
		{
			u16 ammoCount = invo.getCount("mat_gatlingammo");
			ammoCount = Maths::Min(ammoCount, maxAmmo - this.get_u16("ammoCount"));
			if (ammoCount > 0)
			{
				this.Sync("ammoCount", true);
				this.add_u16("ammoCount", ammoCount);
				this.Sync("ammoCount", true);
				invo.server_RemoveItems("mat_gatlingammo", ammoCount);
			}
		}

		CBlob@ attachedBlob = blob.getAttachments().getAttachmentPointByName("PICKUP").getOccupied();
		if (attachedBlob !is null && attachedBlob.getName() == "mat_gatlingammo")
		{
			const u16 ammoCount = Maths::Min(attachedBlob.getQuantity(), maxAmmo - this.get_u16("ammoCount"));
			const u16 leftOver = attachedBlob.getQuantity() - ammoCount;
			this.add_u16("ammoCount", ammoCount);
			if (leftOver <= 0) attachedBlob.server_Die();
			else attachedBlob.server_SetQuantity(leftOver);
		}
	}
	else if (cmd == this.getCommandID("takeAmmo"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			const u16 ammoCount = Maths::Min(this.get_u16("ammoCount"), 500);
			if (ammoCount > 0)
			{
				this.sub_u16("ammoCount", ammoCount);
				if (isServer())
				{
					CBlob@ ammo = server_CreateBlob("mat_gatlingammo", -1, caller.getPosition());
					ammo.server_SetQuantity(ammoCount);
					caller.server_PutInInventory(ammo);
				}
			}
		}
	}
	else if (cmd == this.getCommandID("offblast"))
	{
		const u16 player_netid = params.read_u16();
		const u16 caller_netid = params.read_u16();

		CPlayer@ ply = getPlayerByNetworkId(player_netid);
		CBlob@ caller = getBlobByNetworkID(caller_netid);
		if (ply !is null && caller !is null)
		{
			if (isServer()) this.server_SetPlayer(ply);
			this.set_u16("controller_player_netid", player_netid);
			this.set_u16("controller_blob_netid", caller_netid);
			this.Tag("projectile");
			this.set_bool("offblast", true);
			
			this.set_u32("no_explosion_timer", getGameTime() + 30);
			
			CSprite@ sprite = this.getSprite();
			sprite.SetEmitSoundPaused(false);
			
			this.SetLight(true);
			this.SetLightRadius(128.0f);
			this.SetLightColor(SColor(255, 255, 100, 0));
			
			this.getCurrentScript().tickFrequency = 1;
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	if (this.getPlayer() is null) return true;
	else return false;
}

void MakeParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	Vec2f offset = Vec2f(0, 16).RotateBy(this.getAngleDegrees());
	ParticleAnimated(filename, this.getPosition() + offset, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}




			
