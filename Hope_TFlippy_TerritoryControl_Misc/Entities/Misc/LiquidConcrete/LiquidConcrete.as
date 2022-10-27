#include "Hitters.as"
//#include "LoaderUtilities.as"
#include "CustomBlocks.as";

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(false);
	this.setAngleDegrees(XORRandom(4) * 90);
	
	this.set_f32("wetness", 300.00f);
}

void onTick(CBlob@ this)
{
	const f32 wetness = this.get_f32("wetness");
	this.getSprite().SetFrameIndex(wetness / (600.00f / 4));
	
	if (wetness <= 0)
	{
		CMap@ map = this.getMap();
		Vec2f pos = this.getPosition();
	
		for (int y = 0; y < 3; y++)
		{
			for (int x = 0; x < 3; x++)
			{
				Vec2f offset = pos + (Vec2f(x - 1, y - 1) * 8.00f);
				if (!map.isTileSolid(offset))
				{
					map.server_SetTile(offset, CMap::tile_concrete);
					this.Tag("dead");
					this.server_Die();
				}
			}
		}
		return;
	}

	CBlob@[] spawns;
	getBlobsByTag("respawn", spawns);
	getBlobsByName("ruins", spawns);

	for (int i = 0; i < spawns.length; i++)
	{
		if (spawns[i] is null) continue;
		if (this.isOverlapping(spawns[i])) 
		{
			this.getSprite().PlaySound("NoAmmo.ogg", 1.0f);
			this.server_Die();
		}
	}
	
	this.set_f32("wetness", wetness - 1);
}

void onDie(CBlob@ this)
{
	
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{

}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return true;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return true;
}