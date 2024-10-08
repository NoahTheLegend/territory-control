#include "Knocked.as";
#include "RunnerCommon.as";
#include "Hitters.as";
#include "HittersTC.as";
#include "MakeDustParticle.as";

const f32 max_time = 2.00f;

void onInit(CBlob@ this)
{

}

void onTick(CBlob@ this)
{
	if (this.hasTag("dead")) return;
	
	f32 true_level = this.get_f32("foofed");		
	f32 level = 1.00f + true_level;
	
	if (true_level <= 0)
	{
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
	else
	{
		this.set_f32("foofed", Maths::Max(0, this.get_f32("foofed") - (0.0025f)));
	}
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (hitBlob !is this && customData == Hitters::builder) MegaHit(this, worldPoint, velocity, damage, hitBlob, customData);
}

void onHitMap(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, u8 customData)
{
	MegaHit(this, worldPoint, velocity, damage, null, customData);
}

void MegaHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (customData == HittersTC::foof) return;

	// print("megahit");
	
	f32 true_level = this.get_f32("foofed");		
	f32 level = 1.00f + true_level;
	if (level >= 15.0f) level = 15.0f;

	// print("" + level);
	
	if (level > 1)
	{
		bool client = isClient();
		bool server = isServer();
		
		Vec2f dir = worldPoint - this.getPosition();
		f32 len = dir.getLength();
		dir.Normalize();
		f32 angle = dir.Angle();
		
		int count = true_level * 7.50f;
		
		for (int i = 0; i < count; i++)
		{
			Vec2f pos = worldPoint + getRandomVelocity(0, XORRandom(Maths::Min(24.00f * true_level, 48)), 360);	
			
			if (client && XORRandom(100) < 10 / Maths::Sqrt(count / 5 + 1))
			{
				MakeDustParticle(pos, "dust2.png");
			}
			
			if (server)
			{
				this.server_HitMap(pos, dir, damage, HittersTC::foof);
			}
		}
		
		if (client)
		{
			f32 magnitude = damage * level;
			this.getSprite().PlaySound("FallBig" + (XORRandom(5) + 1), level, 1.00f);
			ShakeScreen(magnitude * 10.0f, Maths::Min(magnitude * 8.0f, 30), this.getPosition());
		}
		
		if (hitBlob !is null)
		{
			if (server) this.server_Hit(hitBlob, worldPoint, velocity, true_level * 0.50f, HittersTC::foof, true);
			if (client) this.getSprite().PlaySound("nightstick_hit" + (1 + XORRandom(3)) + ".ogg", 0.9f, 0.8f);
			
			f32 mass = hitBlob.getMass();
			hitBlob.AddForce(dir * Maths::Min(500.0f * true_level, mass * 10.00f));
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 true_level = this.get_f32("foofed");		
	f32 level = 1.00f + true_level;
	f32 modifier = Maths::Min(level / max_time, 1);
	
	if (modifier >= 1)
	{
		return damage / Maths::Min(level, 2);
	}
	else
	{
		switch (customData)
		{
			case Hitters::nothing:
			case Hitters::suicide:
			case Hitters::suddengib:
				return 0;
		}
	}

	return damage;
}