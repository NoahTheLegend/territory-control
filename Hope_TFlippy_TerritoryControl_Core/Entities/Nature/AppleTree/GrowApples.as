#include "AppleCommon.as";

const u8 APPLE_AMOUNT_LIMIT_PER_TREE = 5;
const u8 APPLE_AMOUNT_LIMIT_PER_MAP = 200;
const f32 APPLE_RADIUS_LIMIT = 8.0f;

void onTick(CBlob@ this)
{
	if (this.get_u16("grow check tick frequency") != 0 
		&& this.getTickSinceCreated() % this.get_u16("grow check tick frequency") == 0)
	{
		if (this.hasTag("growing apples") 
			&& !this.exists("cut_down_time"))
		{
			GrowApples(this);
		}
	}

	if (this.exists("cut_down_time"))	 // tree is falling
	{
		LoseApples(this);
	}
}

void LoseApples(CBlob@ this)
{
	if (!isServer())	return;

	for (uint i = 0; i < APPLE_AMOUNT_LIMIT_PER_TREE; i++)
	{
		u16 netid = this.get_u16("slot" + i);
		CBlob@ blob = getBlobByNetworkID(netid);
		
		if (blob !is null && blob.hasTag("growing on tree"))
		{	
			if (blob.hasTag("apple growth"))	// still a small apple, unspawn it
			{
				blob.getSprite().Gib();
				blob.server_Die();
				continue;
			}
			
			blob.Tag("apply velocity");
			MakeNonStatic(blob);
		}
	}
}

void GrowApples(CBlob@ this)
{
	if (!isServer() || XORRandom(8) > 0)	return;
	
	CBlob@[] apples;
	getBlobsByName("apple", @apples);

	if (apples.length >= APPLE_AMOUNT_LIMIT_PER_MAP) 	return;
	
	for (uint i = 0; i < APPLE_AMOUNT_LIMIT_PER_TREE; i++)	// check if there are free slots
	{
		if (!this.exists("slot" + i)) // free slot, use it
		{
			GrowAppleInSlot(this, i);
			break;
		}
		else // slot is used
		{
			u16 netid = this.get_u16("slot" + i);
			CBlob@ blob = getBlobByNetworkID(netid);

			if (blob is null ||										// apple doesn't exist
				(blob !is null && !blob.hasTag("growing on tree")))	// or apple exists but not hanging on tree - use the slot
			{
				GrowAppleInSlot(this, i);
				break;
			}
		}
	}
}

void GrowAppleInSlot(CBlob@ this, uint slot)
{
	CMap@ m = getMap();
	float ts = m.tilesize;	
	Vec2f position_shift 	= Vec2f(-ts * 2.5f + XORRandom(ts * 5), -ts * 5 + XORRandom(ts * 3));
	Vec2f spawn_position	= this.getPosition() + position_shift;
	
	// don't spawn if close to other apple or inside walls
	if (m.isBlobInRadius("apple", spawn_position, APPLE_RADIUS_LIMIT)
		|| m.isTileSolid(spawn_position))	
	{
		return;
	}
	
	CBlob@ apple = server_CreateBlob("apple", 255, spawn_position);
	
	if (apple !is null)
	{
		apple.Tag("apple growth"); // causes Apple onTick() to run, which manages apple growth
		apple.RemoveScript("Eatable.as"); // not eatable until grown
		apple.server_setTeamNum(255);
		this.set_u16("slot" + slot, apple.getNetworkID());
		
		apple.Sync("apple growth", true);
	}
}