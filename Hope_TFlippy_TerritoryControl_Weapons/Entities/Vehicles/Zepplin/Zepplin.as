#include "VehicleCommon.as"
#include "Hitters.as"
#include "HittersTC.as"
#include "Explosion.as";

//most of the code is in BomberCommon.as

const u32 shootDelay = 12; // Ticks
const f32 damage = 4.5f;
const Vec2f arm_offset = Vec2f(-26, 50);

string[] particles = 
{
	"SmallExplosion1.png",
	"SmallExplosion2.png",
	"SmallExplosion3.png"
};
void onInit(CBlob@ this)
{
	Vehicle_Setup(this,
	              60.0f, // move speed
	              0.40f,  // turn speed
	              Vec2f(0.0f, -5.0f), // jump out velocity
	              true  // inventory access
	             );

	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v)) return;

	Vehicle_SetupAirship(this, v, 100.0f); 
	
	//this.set_Vec2f getPositionWithOffset(0.0f, 0.0f)

	this.Tag("vehicle");
	this.Tag("bomber");

	this.getShape().SetOffset(Vec2f(-20, 47));
	this.getShape().SetRotationsAllowed(false);

	this.set_f32("max_fuel", 10000);
	this.set_f32("fuel_consumption_modifier", 1.0f);
	
	this.getSprite().SetZ(-50);
	
	Vec2f pos_off(8, 60);
	{
		Vec2f[] shape = { Vec2f(0.0f, 0.0f) - pos_off,
		                  Vec2f(130.0f,  0.0f) - pos_off,
		                  Vec2f(130.0f,  35.0f) - pos_off,
		                  Vec2f(0.0f, 35.0f) - pos_off
		                };
		this.getShape().AddShape(shape);
	}
	
	
	{
		Vec2f[] shape = { Vec2f( 110.0f,  35.0f ) -pos_off,
						  Vec2f( 105.0f,  35.0f ) -pos_off,
						  Vec2f( 105.0f,  63.0f ) -pos_off,
						  Vec2f( 110.0f,  63.0f ) -pos_off 
						};
		this.getShape().AddShape( shape );
	}
	
	Vehicle_SetupWeapon(this, v,
	                    shootDelay, // fire delay (ticks)
	                    1, // fire bullets amount
	                    Vec2f(-6.0f, 2.0f), // fire position offset
	                    "mat_gatlingammo", // bullet ammo config name
						"", // fire position offset
	                    "MLG_Shoot2", // fire sound
	                    "EmptyFire" // empty fire sound
	                   );
	v.charge = 400;
	// init arm + cage sprites
	CSprite@ sprite = this.getSprite();
	CSpriteLayer@ arm = sprite.addSpriteLayer("arm", "ZepplinGatling.png", 24, 16);
	
	getMap().server_AddMovingSector(Vec2f(32.0f, 55.0f), Vec2f(-12.0f, 0.0f), "ladder", this.getNetworkID());
	getMap().server_AddMovingSector(Vec2f(22.0f, 55.0f), Vec2f(-12.0f, 0.0f), "ladder", this.getNetworkID());
	getMap().server_AddMovingSector(Vec2f(12.0f, 55.0f), Vec2f(-12.0f, 0.0f), "ladder", this.getNetworkID());
	getMap().server_AddMovingSector(Vec2f(2.0f, 55.0f), Vec2f(-12.0f, 0.0f), "ladder", this.getNetworkID());
	getMap().server_AddMovingSector(Vec2f(-8.0f, 55.0f), Vec2f(-12.0f, 0.0f), "ladder", this.getNetworkID());
	getMap().server_AddMovingSector(Vec2f(-18.0f, 55.0f), Vec2f(-12.0f, 0.0f), "ladder", this.getNetworkID());
	getMap().server_AddMovingSector(Vec2f(-28.0f, 55.0f), Vec2f(-12.0f, 0.0f), "ladder", this.getNetworkID());
	getMap().server_AddMovingSector(Vec2f(-38.0f, 55.0f), Vec2f(-12.0f, 0.0f), "ladder", this.getNetworkID());
	getMap().server_AddMovingSector(Vec2f(-48.0f, 55.0f), Vec2f(-12.0f, 0.0f), "ladder", this.getNetworkID());//awful fix, I know
	
	if (arm !is null)
	{
		{
			Animation@ anim = arm.addAnimation("default", 0, true);
			int[] frames = {0};
			anim.AddFrames(frames);
		}
	
		{
			Animation@ anim = arm.addAnimation("shoot", 1, false);
			int[] frames = {0, 2, 1};
			anim.AddFrames(frames);
		}
		
		arm.SetOffset(arm_offset);
		arm.SetRelativeZ(-1.0f);
	}

	this.getShape().SetRotationsAllowed(false);
	this.set_string("autograb blob", "mat_gatlingammo");
	this.set_u32("fireDelay", 0);
	sprite.SetZ(10.0f);

	if (isServer())
	{
		CBlob@ ammo = server_CreateBlob("mat_gatlingammo");
		if (ammo !is null)
		{
			if (!this.server_PutInInventory(ammo))
				ammo.server_Die();
		}
	}
	
	this.SetLight(false);
}

void onInit(CSprite@ this)
{
	//this.RemoveSpriteLayer("tracer");
	//CSpriteLayer@ tracer = this.addSpriteLayer("tracer", "GatlingGun_Tracer.png" , 32, 1, this.getBlob().getTeamNum(), 0);
//
	//if (tracer !is null)
	//{
	//	Animation@ anim = tracer.addAnimation("default", 0, false);
	//	anim.AddFrame(0);
	//	tracer.SetRelativeZ(-2.0f);
	//	tracer.SetOffset(arm_offset);
	//	tracer.SetVisible(false);
	//	tracer.setRenderStyle(RenderStyle::additive);
	//}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	blob.setAngleDegrees(blob.getVelocity().x * 4);
	
	CSpriteLayer@ arm = this.getSpriteLayer("arm");
	if (arm.isAnimationEnded())
	{
		arm.SetAnimation("default");
	}
}

f32 getAimAngle(CBlob@ this, VehicleInfo@ v)
{
	f32 angle = Vehicle_getWeaponAngle(this, v);
	bool facing_left = this.isFacingLeft();
	AttachmentPoint@ gunner = this.getAttachments().getAttachmentPointByName("FLYER");
	bool failed = true;

	if (gunner !is null && gunner.getOccupied() !is null)
	{
		gunner.offsetZ = 60.0f;
		Vec2f aim_vec = (gunner.getPosition() - gunner.getAimPos()) + Vec2f(arm_offset.x * (facing_left ? 1 : -1), arm_offset.y);
		
		
		if (this.isAttached())
		{
			if (facing_left) { aim_vec.x = -aim_vec.x; }
			angle = (-(aim_vec).getAngle() + 180.0f);
		}
		else
		{
			if ((!facing_left && aim_vec.x < 0) || (facing_left && aim_vec.x > 0))
			{
				if (aim_vec.x > 0) { aim_vec.x = -aim_vec.x; }

				angle = (-(aim_vec).getAngle() + 180.0f);
				angle = Maths::Max(-10.0f, Maths::Min(angle, 70.0f));
			}
			else
			{
				// this.SetFacingLeft(!facing_left);
			}
		}
	}

	return angle;
}

void onTick(CBlob@ this)
{
	if (this.hasAttached() || this.getTickSinceCreated() < 30)
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}

		AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("FLYER");
		CBlob@ flyer = ap.getOccupied();
		
		if (flyer !is null)
		{	
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
				arm.SetRelativeZ(-60.0f);
				arm.SetOffset(arm_offset);
				arm.RotateBy(rotation, Vec2f(facing_left ? -4.0f : 4.0f, 0.0f));
			}
			
			if (flyer.isMyPlayer())
			{
				if (ap.isKeyPressed(key_action3) && getGameTime() > this.get_u32("fireDelay"))
				{
					// print("shoot");
				
					CBitStream fireParams;
					fireParams.write_u16(flyer.getNetworkID());
					fireParams.write_u8(0);
					this.SendCommand(this.getCommandID("fire"), fireParams);
				}
			}
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	//if (blob !is null)
	//{
	//	TryToAttachCargo(this, blob); u can also enable this
	//}
	CMap@ map = getMap();
	if (map !is null)
	{
		Vec2f pos = this.getPosition();
		if (map.isTileSolid(map.getTile(pos + Vec2f(0, 40))) // point of secondary shape, mid
		|| map.isTileSolid(map.getTile(pos + Vec2f(-8, 40))) // point of secondary shape, 1 block left from mid
		|| map.isTileSolid(map.getTile(pos + Vec2f(8, 40)))) // point of secondary shape, 1 block right from mid
		{
			this.setPosition(this.getPosition() - Vec2f(0, 16));
		}
	}
}

void onDie(CBlob@ this)
{
	if (isServer())
	{
		

		for (int i = 0; i < 5 + XORRandom(3); i++)
		{
			CBlob@ blob = server_CreateBlob("flame", -1, this.getPosition());
			blob.setVelocity(Vec2f(XORRandom(10) - 5, -XORRandom(6)));
			blob.server_SetTimeToDie(4 + XORRandom(15));
		}
	}
}

//required shit


//bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
//{
	//return Vehicle_doesCollideWithBlob_ground(this, blob);
//}

bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) 
{
	return getGameTime() > this.get_u32("fireDelay");
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return true;
}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 _unused)
{
	if (getGameTime() < this.get_u32("fireDelay")) return;

	if (isClient()) this.getSprite().getSpriteLayer("arm").SetAnimation("shoot");
	
	f32 angle = getAimAngle(this, v);
	angle = angle * (this.isFacingLeft() ? -1 : 1);
	
	bool flip = this.isFacingLeft();	
		
	Vec2f dir = Vec2f((this.isFacingLeft() ? -1 : 1), 0.0f).RotateBy(angle);
	Vec2f startPos = this.getPosition() + Vec2f(arm_offset.x * (flip ? 1 : -1), arm_offset.y);
	Vec2f endPos = startPos + dir * 500;
	Vec2f hitPos;
	f32 length;
	
	HitInfo@[] hitInfos;
	
	bool mapHit = getMap().rayCastSolid(startPos, endPos, hitPos);
	length = (hitPos - startPos).Length();
	
	bool blobHit = getMap().getHitInfosFromRay(startPos, angle + (flip ? 180.0f : 0.0f), length, this, @hitInfos);
		
	if (isClient())
	{
		//DrawLine(this.getSprite(), startPos, length / 32, angle, this.isFacingLeft());
		ShakeScreen(64, 32, hitPos);	
		
		for (int i = 0; i < 4; i++)
		{
			MakeExplosionParticle(hitPos + Vec2f(XORRandom(16) - 8, XORRandom(16) - 8), getRandomVelocity(0, XORRandom(220) * 0.005f, 90), particles[XORRandom(particles.length)]);
		}
		
		
		// Vec2f mousePos = getControls().getMouseScreenPos();
		// getControls().setMousePosition(Vec2f(mousePos.x, mousePos.y - 10));
	}
	
	if (isServer())
	{
		if (blobHit)
		{
			f32 falloff = 1;
			for (u32 i = 0; i < hitInfos.length; i++)
			{
				if (hitInfos[i].blob !is null)
				{	
					CBlob@ blob = hitInfos[i].blob;
					
					if ((blob.isCollidable() || blob.hasTag("flesh")) && blob.getTeamNum() != this.getTeamNum())
					{
						// print("Hit " + blob.getName() + " for " + damage * falloff);
						this.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), damage * Maths::Max(0.1, falloff), Hitters::arrow);
						falloff = falloff * 0.5f;			
					}
				}
			}
		}
		
		if (mapHit)
		{
			CMap@ map = getMap();
			
			for (u32 i = 1; i < 10; i++)
			{
				Vec2f tpos = hitPos + (dir * i * 4);
				TileType tile =	map.getTile(tpos).type;
				
				if (!map.isTileBedrock(tile))
				{
					map.server_DestroyTile(tpos, damage / i);
				}
			}
		}
	}
	
	this.set_u32("fireDelay", getGameTime() + shootDelay);
}

void MakeExplosionParticle(const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;
	ParticleAnimated(filename, pos, vel, float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(8), 0, true);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("fire raycast"))
	{
		const u8 charge = params.read_u8();
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Vehicle_onFire(this, v, null, charge);
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::explosion || customData == HittersTC::plasma)
	{
		damage += 2.0f;
		return damage * 3.0f;
	}
	return damage;
}

//void DrawLine(CSprite@ this, Vec2f startPos, f32 length, f32 angle, bool flip)
//{
//	CSpriteLayer@ tracer = this.getSpriteLayer("tracer");
//	
//	tracer.SetVisible(true);
//	
//	tracer.ResetTransform();
//	tracer.ScaleBy(Vec2f(length, 1.0f));
//	tracer.TranslateBy(Vec2f(length * 16.0f, 0.0f));
//	tracer.RotateBy(angle + (flip ? 180 : 0), Vec2f());
//}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (!Vehicle_AddFlipButton(this, caller))
	{
		Vehicle_AddLoadAmmoButton(this, caller);
	}
}

