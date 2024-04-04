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
	
	// this.set_string("custom_explosion_sound", "bigbomb_explosion.ogg");
	this.set_bool("map_damage_raycast", true);
	this.set_Vec2f("explosion_offset", Vec2f(0, 16));
	
	this.set_u8("stack size", 1);
	this.set_f32("bomb angle", 90);
	
	// this.Tag("map_damage_dirt");
	
	this.Tag("explosive");
	this.Tag("medium weight");
	
	this.maxQuantity = 1;
}

void onDie(CBlob@ this)
{
	if (isServer() && this.hasTag("DoExplode"))
	{
		CBlob@ boom = server_CreateBlobNoInit("nukeexplosion");
		boom.setPosition(this.getPosition());
		boom.set_u8("boom_start", 0);
		boom.set_u8("boom_end", 5);
		boom.set_f32("mithril_amount", 50);
		boom.set_f32("flash_distance", 256);
		// boom.Tag("no mithril");
		// boom.Tag("no flash");
		boom.Init();
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
			s8 s_door = blob.getName().find("door");
			if(s_door <= 0)
			{	
				if (!blob.hasTag("plane")
				&& !blob.isInInventory() && !blob.isAttached())
					return;
			}
		}
		
		Vec2f dir = Vec2f(-normal.x, normal.y);

		this.Tag("DoExplode");
		this.set_f32("bomb angle", dir.Angle());
		this.server_Die();
	}
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (inventoryBlob !is null && (inventoryBlob.hasTag("flesh") || inventoryBlob.hasTag("player")) && this !is null)
	{
		CInventory@ inv = inventoryBlob.getInventory();
		if (inv !is null)
		{
			u8 counter = 1;
			u16 nukes = inv.getItemsCount();
			for (u16 i = 0; i < nukes; i++)
			{
				CBlob@ item = inv.getItem(i);
				if (item is null) continue;
				if (item.getName() == "mat_mininuke") counter++;
			}
			return counter <= 5;
		}
	}
	return true;
}