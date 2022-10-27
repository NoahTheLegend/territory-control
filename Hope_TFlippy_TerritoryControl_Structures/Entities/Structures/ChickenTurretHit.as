#include "Hitters.as"
#include "HittersTC.as"
#include "ParticleSparks.as";

//this makes chicken turrets more resistant against gunfire
void onInit(CBlob@ this)
{
	this.Tag("chicken_turret"); //tag is needed for wrench (you can repair chicken turrets now)
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 dmg = damage;
	
	switch (customData)
	{
		case HittersTC::bullet_low_cal:
		case HittersTC::bullet_high_cal:
		case HittersTC::shotgun:
		dmg *= 0.10f;
			break;
	}
	return dmg;
}