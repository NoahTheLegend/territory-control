#include "Hitters.as"

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	shape.getConsts().mapCollisions = false;
	shape.SetStatic(true);
	this.set_f32("damage", 2);
	this.set_u16("angle", 0);
	//this.getCurrentScript().tickFrequency = 3;
}

void onTick(CBlob@ this)
{
	this.set_f32("fdamage", 3000);
	//this.set_f32("fdamage", Maths::Pow(this.get_f32("damage") * 0.75, 2.00f));
/*
	f32 damage = Maths::Pow(this.get_f32("damage") * 0.75, 2.00f);
	u16 angle = this.get_u16("angle");
	
	Vec2f tl, br;
	this.getShape().SetRotationsAllowed(true);
	this.getShape().getBoundingRect(tl, br);
	CBlob@[] blobs;
	if (getMap().getBlobsInBox(tl, br, @blobs))
	{
		int range = (blobs.length > 5 ? 5 : blobs.length);

		for (uint i = 0; i < range; i++)
		{
			CBlob@ blob = blobs[i];
			if (blob is null) { continue; }
			
			if (isServer() && canHit(this, blob))
			{ 
				if (damage >= 0.5)this.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), damage, Hitters::saw, true);
				if (blob.hasTag("dead"))this.getSprite().PlaySound("SawLog.ogg");
			}
		}
	}
*/
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	f32 damage = Maths::Pow(this.get_f32("fdamage") * 0.75, 2.00f);
	if (blob !is null)
	{
		if (isServer()) this.server_Hit(blob, this.getPosition(), Vec2f(0, 0), 0.5f * damage, Hitters::saw, true);
		if (blob.hasTag("dead"))this.getSprite().PlaySound("SawLog.ogg");
	}
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}

bool canHit(CBlob@ blade, CBlob@ victim)
{
	if (victim.getName() == "tiger" || victim.getName() == "jourcop" || victim.hasTag("invincible") || victim.hasTag("invincibilityByVehicle"))
		return false;
	else return true;
}