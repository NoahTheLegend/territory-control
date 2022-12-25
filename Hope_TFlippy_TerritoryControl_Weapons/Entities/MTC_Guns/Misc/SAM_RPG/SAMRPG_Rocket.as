#include "Hitters.as";
#include "Explosion.as";

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

const u32 fuel_timer_max = 30 * 3.50f;

void onInit(CBlob@ this)
{
	this.set_f32("map_damage_ratio", 5.0f);
	this.set_f32("map_damage_radius", 56.0f);
	this.set_string("custom_explosion_sound", "Keg.ogg");
		
	this.set_u32("fuel_timer", 0);
	this.set_f32("velocity", 15.0f);
	
	this.Tag("map_damage_dirt");
	this.Tag("aerial");
	this.Tag("projectile");
	this.Tag("change_rotation");
	this.Tag("bullet_collision");
	
	this.getShape().SetRotationsAllowed(true);
	
	this.set_u32("fuel_timer", getGameTime() + fuel_timer_max + XORRandom(15));
	
	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("RPG_Loop.ogg");
	sprite.SetEmitSoundSpeed(1.0f);
	sprite.SetEmitSoundPaused(false);
	
	this.SetLight(true);
	this.SetLightRadius(64.0f);
	this.SetLightColor(SColor(255, 255, 100, 0));
}

void onTick(CBlob@ this)
{
	Vec2f dir;
	if (this.get_u32("fuel_timer") > getGameTime())
	{
		Vec2f dir = Vec2f(0, 1);
		dir.RotateBy(this.getAngleDegrees());
					
		this.setVelocity(dir * -this.get_f32("velocity"));
		
		if(isClient())
		{
			MakeParticle(this, -dir, XORRandom(100) < 30 ? ("SmallSmoke" + (1 + XORRandom(2))) : "SmallExplosion" + (1 + XORRandom(3)));
		}
		
		this.setAngleDegrees(-this.getVelocity().Angle() + 90.1);
		
		// Not as hardcore shitcode anymore, but still shitcode
		if (this.getTickSinceCreated() > 30)
		{
			CBlob@[] blobs;
			//getBlobsByTag("aerial", @blobs);
			this.getMap().getBlobsInRadius(this.getPosition(), 512.0f, blobs);

			f32 distance = 99999.0f;
			u32 index = 0;
			const Vec2f mypos = this.getPosition();
			Vec2f target;
			CBlob@[] airblobs;

			for (int i = 0; i < blobs.length; i++)
			{
				if (blobs[i].getTeamNum() == this.getTeamNum() || blobs[i] is this) continue;
				if (!blobs[i].hasTag("aerial")) continue;
				airblobs.push_back(blobs[i]);
			}

			if (airblobs.length > 0)
			{
				for (int i = 0; i < airblobs.length; i++)
				{
					f32 bdist = (airblobs[i].getPosition() - mypos).Length();
					if (bdist < distance)
					{
						distance = bdist;
						index = i;
					}
				}
				target = airblobs[index].getPosition();
				dir = -(target - mypos);
				dir.Normalize();
			}
			else 
			{
				if (this.get_u32("fuel_timer") > getGameTime())
				{
					Vec2f dir = Vec2f(0, 1);
					dir.RotateBy(this.getAngleDegrees());
					
					this.setVelocity(dir * -this.get_f32("velocity"));

					if(isClient())
					{
						MakeParticle(this, -dir, XORRandom(100) < 30 ? ("SmallSmoke" + (1 + XORRandom(2))) : "SmallExplosion" + (1 + XORRandom(3)));
					}

					this.setAngleDegrees(-this.getVelocity().Angle() + 90.1);
				}
				else
				{
					this.setAngleDegrees(-this.getVelocity().Angle() + 90.1);
					this.getSprite().SetEmitSoundPaused(true);
				}
			}
		}
		if (this.getTickSinceCreated() > 120)
		{
			if (isServer())
			{
				this.server_Die();
			}
		}
		const f32 ratio = 0.25f;
		// Vec2f nDir = (this.get_Vec2f("direction") * (1.00f - inp_ratio)) + (dir * inp_ratio);
		Vec2f nDir = (this.get_Vec2f("direction") * (1.00f - ratio)) + (dir * ratio);
		nDir.Normalize();
		this.SetFacingLeft(false);
		this.set_f32("velocity", Maths::Min(this.get_f32("velocity") + 0.2f, 15.0f));
		this.setAngleDegrees(-nDir.getAngleDegrees() + 90.1);
		this.setVelocity(-nDir * this.get_f32("velocity"));
		this.set_Vec2f("direction", nDir);
		if(isClient())
		{
			MakeParticle(this, -dir, XORRandom(100) < 30 ? ("SmallSmoke" + (1 + XORRandom(2))) : "SmallExplosion" + (1 + XORRandom(3)));
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.isCollidable() && blob.getTeamNum() != this.getTeamNum(); // && blob.isCollidable();
}

void DoExplosion(CBlob@ this)
{
	CRules@ rules = getRules();
	if (!shouldExplode(this, rules))
	{
		addToNextTick(this, rules, DoExplosion);
		return;
	}
	
	if (this.hasTag("dead")) return;

	f32 random = XORRandom(8);
	f32 modifier = 1 + Maths::Log(this.getQuantity());
	f32 angle = -this.get_f32("bomb angle");
	// print("Modifier: " + modifier + "; Quantity: " + this.getQuantity());

	this.set_f32("map_damage_radius", (30.0f + random) * modifier);
	this.set_f32("map_damage_ratio", 1.5f);
	
	Explode(this, 24.0f + random, 35.0f);
	
	for (int i = 0; i < 4 * modifier; i++) 
	{
		Vec2f dir = getRandomVelocity(angle, 1, 120);
		dir.x *= 2;
		dir.Normalize();
		
		LinearExplosion(this, dir, 8.0f + XORRandom(16) + (modifier * 8), 8 + XORRandom(24), 3, 0.125f, Hitters::explosion);
	}
	
	Vec2f pos = this.getPosition();
	CMap@ map = getMap();
	
	for (int i = 0; i < 8; i++)
	{
		MakeExplosionParticle(this, Vec2f( XORRandom(64) - 32, XORRandom(80) - 60), getRandomVelocity(-angle, XORRandom(220) * 0.01f, 90), particles[XORRandom(particles.length)]);
	}
	
	this.Tag("dead");
	this.getSprite().Gib();
}

void MakeExplosionParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(8), 0, true);
}

void MakeParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	Vec2f offset = Vec2f(0, 0).RotateBy(this.getAngleDegrees());
	ParticleAnimated(filename, this.getPosition() + offset, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}

void onDie(CBlob@ this)
{
	DoExplosion(this);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (solid) this.server_Die();
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}