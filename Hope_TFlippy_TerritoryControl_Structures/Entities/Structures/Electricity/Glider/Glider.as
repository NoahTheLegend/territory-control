#include "Hitters.as";
#include "MapFlags.as";

void onInit(CBlob@ this)
{
	//if (isServer()
	//&& getMap().getBlobAtPosition(this.getPosition()) !is null
	//&& getMap().getBlobAtPosition(this.getPosition()).hasTag("overlap_allowed")) this.server_Die(); 
	
	this.getSprite().SetZ(50);
	this.getShape().SetRotationsAllowed(false);
	this.getShape().getConsts().waterPasses = true;
	
	this.Tag("place norotate");

	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	this.Tag("builder always hit");
	
	this.Tag("ignore blocking actors");
	this.Tag("conveyor");
	this.Tag("inline_block");
	this.Tag("no_wire");
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;
	
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	
	if(isServer()){
		CMap@ map = getMap();
		if(map.getTile(this.getPosition()).type == 0) map.server_SetTile(this.getPosition(), CMap::tile_wood_back);
	}

	sprite.SetZ(300);
	
	sprite.PlaySound("/build_door.ogg");
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null && blob.hasTag("player")) // && this.get_u32("elec") > 3)
	{
		blob.setPosition(Vec2f(blob.getPosition().x, blob.getPosition().y-2.0f));
		blob.setVelocity(Vec2f(blob.getVelocity().x, 0));

		blob.Tag("gliding");
		blob.set_u32("disable_gliding", getGameTime()+10);
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	this.getSprite().SetZ(300);
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::builder) damage *= 5.0f;
	return damage;
}