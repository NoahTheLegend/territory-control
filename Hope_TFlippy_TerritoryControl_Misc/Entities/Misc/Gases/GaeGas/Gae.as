#include "Hitters.as";
#include "Explosion.as";

void onInit(CBlob@ this)
{
	this.Tag("gas");

	this.getShape().SetGravityScale(0.10f);
	
	this.getSprite().setRenderStyle(RenderStyle::additive);
	this.getSprite().SetZ(10.0f);
	
	this.SetMapEdgeFlags(CBlob::map_collide_sides);
	this.getCurrentScript().tickFrequency = 15 + XORRandom(15);
	
	if (!this.exists("toxicity")) this.set_f32("toxicity", 0.00f);
	
	this.getSprite().RotateBy(90 * XORRandom(4), Vec2f());
	this.server_SetTimeToDie(60 + XORRandom(90));
}

void onTick(CBlob@ this)
{
	if (isServer() && this.getPosition().y < 0) this.server_Die();
	
	CBlob@[] blobsInRadius;
	if (getMap().getBlobsInRadius(this.getPosition(), this.getRadius() * 1.5f, @blobsInRadius))
	{
		int blobSize = blobsInRadius.length;
		for (uint i = 0; i < blobSize; i++)
		{
			CBlob@ blob = blobsInRadius[i];
			if (blob is null || !blob.hasTag("flesh") || blob.hasTag("gas") || blob.hasTag("gas immune") || !blob.isCollidable() || !blob.hasTag("human") || blob.hasTag("transformed") || blob.hasTag("npc")) 
			{ 
				break; 
			} 
			else
			{			
				if (!blob.hasScript("GaeEffect.as") && blob !is null) blob.AddScript("GaeEffect.as");
			}
		}
	}

	if(isClient())
	{
		if (this.isOnScreen()) 
		{
			MakeParticle(this, "Gae.png");
		}
	}
}
 
bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.hasTag("gas");
}
 
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return 0;
}

void MakeParticle(CBlob@ this, const string filename = "LargeSmoke")
{
	CParticle@ particle = ParticleAnimated(filename, this.getPosition() + Vec2f(16 - XORRandom(32), 8 - XORRandom(32)), Vec2f(), float(XORRandom(360)), 1.0f + (XORRandom(50) / 100.0f), 4, 0.00f, false);
	if (particle !is null) 
	{
		particle.collides = false;
		particle.bounce = 0.0f;
		particle.fastcollision = true;
		particle.lighting = false;
		particle.setRenderStyle(RenderStyle::additive);
	}
}