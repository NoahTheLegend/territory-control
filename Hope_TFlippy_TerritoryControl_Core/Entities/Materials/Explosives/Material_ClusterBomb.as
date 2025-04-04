#include "Hitters.as";
#include "Explosion.as";

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(true);
	
	this.set_bool("map_damage_raycast", true);
	this.set_Vec2f("explosion_offset", Vec2f(0, 16));
	
	this.set_u8("stack size", 2);
	this.set_f32("bomb angle", 90);
	
	this.Tag("explosive");
	this.Tag("medium weight");
	
	this.maxQuantity = 2;
}

void onDie(CBlob@ this)
{
	if (this.hasTag("DoExplode"))
	{
		DoExplosion(this);
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage >= this.getHealth() && !this.hasTag("dead"))
	{
		this.Tag("DoExplode");
		this.set_f32("bomb angle", 90);
		this.server_Die();
	}
	
	return damage;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal)
{
	if (blob !is null ? !blob.isCollidable() : !solid)
	{
		return;
	}

	f32 vellen = this.getOldVelocity().Length();
	if (vellen >= 8.0f) 
	{
		if (blob !is null)
		{
			if (blob.hasTag("plane") && blob.getTeamNum() == this.getTeamNum())
				return;
		}
		
		Vec2f dir = -this.getOldVelocity();
		dir.Normalize();

		this.Tag("DoExplode");
		this.set_f32("bomb angle", dir.Angle());
		this.server_Die();
	}
}

void DoExplosion(CBlob@ this)
{
	CRules@ rules = getRules();
	if (!shouldExplode(this, rules))
	{
		addToNextTick(this, rules, DoExplosion);
		return;
	}
	
	f32 random = XORRandom(16);
	f32 modifier = 1 + Maths::Log(this.getQuantity());
	f32 angle = this.get_f32("bomb angle");
	// print("Modifier: " + modifier + "; Quantity: " + this.getQuantity());

	this.set_f32("map_damage_radius", (40.0f + random) * modifier);
	this.set_f32("map_damage_ratio", 0.25f);
	
	Explode(this, 24.0f + random, 5.0f);
	
	for (int i = 0; i < 4 * modifier; i++) 
	{
		Vec2f dir = getRandomVelocity(angle, 1, 120);
		dir.x *= 2;
		dir.Normalize();
		
		LinearExplosion(this, dir, 8.0f + XORRandom(16) + (modifier * 8), 8 + XORRandom(24), 3, 2.0f, Hitters::explosion);
	}
	
	Vec2f pos = this.getPosition();
	CMap@ map = getMap();
	
	if (isServer())
	{
		CBlob@[] blobs;
		
		if (map.getBlobsInRadius(pos, 128.0f, @blobs))
		{
			for (int i = 0; i < blobs.length; i++)
			{		
				CBlob@ blob = blobs[i];
				if (blob !is null && (blob.hasTag("flesh") || blob.hasTag("plant"))) 
				{
					map.server_setFireWorldspace(blob.getPosition(), true);
					blob.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), 0.5f, Hitters::fire);
				}
			}
		}
	
		CBlob@ boom = server_CreateBlobNoInit("clusterbombexplosion");
		boom.setPosition(this.getPosition());
		boom.set_f32("bomb angle", this.get_f32("bomb angle"));
		int boom_end = 8;
		int boom_frequency = 1;

		CBlob@[] blobsInRadius;
		if (map.getBlobsInRadius(pos, 128.0f, @blobsInRadius))
		{
			for (int i = 0; i < blobsInRadius.length; i++)
			{		
				CBlob@ blob = blobsInRadius[i];
				if (blob !is null && blob.getName() == "mat_clusterbomb")
				{
					boom_frequency += 1;
				}
			}
		}
		boom.set_u8("boom_frequency", boom_frequency);
		boom.set_u8("boom_end", boom_end);
		// default values for the cluster bomb
		boom.Init();
	}

	if (isClient())
	{
		this.getSprite().Gib();
	}
}