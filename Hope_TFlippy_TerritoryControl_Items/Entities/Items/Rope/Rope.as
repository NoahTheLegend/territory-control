// ROPE CODE
// Made by NoahTheLegend
#include "RopeCommon.as";
const u16 ROPE_LIMIT = 10;

void onInit(CBlob@ this)
{
	if (isServer())
	{
		CBlob@[] bs;
		getBlobsByTag("tail", @bs);
		if (bs.length >= ROPE_LIMIT) this.server_Die();
	}

	this.getSprite().ReloadSprites(0, 0);
	this.Tag("pushedByDoor");
	this.getShape().SetRotationsAllowed(true);

	Rope ropeSettings;
	if (ropeSettings is null) return;
    
	{
		@ropeSettings.blob = @this;
		this.set("RopeSettings", @ropeSettings);
		if (ropeSettings !is null)
		{
			if (!this.hasTag("segment"))
			{
				ropeSettings.segments_left = MAX_ROPE_SEGMENTS;
				ropeSettings.Init();
			}
			else this.getShape().SetGravityScale(2.0f);
		}
	}
}

void onTick(CBlob@ this)
{
	//if(this.getTickSinceCreated() == 1)
	//	printf(""+this.getPosition().x);

	Vec2f vel = this.getOldPosition() - this.getPosition();
	if (vel.Length() > 1.0f)
        this.setAngleDegrees(-vel.Angle()-270);

	if (this.hasTag("segment")) return;
	Rope@ ropeSettings;
	if (this.get("RopeSettings", @ropeSettings))
	{
		if (isServer() && this.hasTag("tail"))
		{
			AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
			if (ap !is null && ap.getOccupied() !is null && (ap.getOccupied().getPosition()-this.getPosition()).Length()>32.0f)
				this.server_DetachFromAll();
		}
			
		ropeSettings.Update();
	}
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
	bool has_hooked = false;
	Rope@ ropeSettings;
	if (this.get("RopeSettings", @ropeSettings))
	{
		if (this.hasTag("tail") && getBlobByNetworkID(ropeSettings.hookedid) !is null) has_hooked = true;
		else if (!this.hasTag("tail") && getBlobByNetworkID(ropeSettings.leaderid) !is null) has_hooked = true;
	}
    return !this.hasTag("segment") && !has_hooked;
}

bool canBePutInInventory( CBlob@ this, CBlob@ inventoryBlob )
{
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.getName() == "rope") return false;
	return false;
}