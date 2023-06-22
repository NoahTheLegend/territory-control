// const f32 yPos = 90.00f;

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

const f32 speed = 2.00f;
// const f32 speed = 0.10f;

void onInit(CBlob@ this)
{
	this.getShape().SetGravityScale(0.0f);
	this.getShape().getConsts().mapCollisions = false;
	this.getShape().SetRotationsAllowed(false);

	this.SetMapEdgeFlags(CBlob::map_collide_none | CBlob::map_collide_nodeath);

	this.Tag("train");
	this.Tag("invincible");

	this.SetLight(true);
	this.SetLightRadius(64.0f);
	this.SetLightColor(SColor(255, 150, 25, 0));

	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		sprite.SetEmitSoundVolume(10.0f);
		sprite.SetEmitSound("Train_Loop.ogg");
		sprite.SetEmitSoundPaused(false);
		sprite.RewindEmitSound();
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	//stops E glitch
	return this.getPosition().x < getMap().tilemapwidth * 8;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !blob.hasTag("train");
}

void onTick(CBlob@ this)
{
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();
	Vec2f vel = -(this.getOldPosition()-pos);

	CBlob@[] overlapping;
	map.getBlobsInBox(pos - Vec2f(40, 40), pos - Vec2f(-40, 20), @overlapping);
	for (u16 i = 0; i < overlapping.length; i++)
	{
		if (overlapping[i] is null || !overlapping[i].isOnGround()) continue;
		if (overlapping[i].getVelocity().x < 4.0f && !overlapping[i].isKeyPressed(key_left))
			overlapping[i].AddForce(Vec2f(1 + (overlapping[i].isKeyPressed(key_right)?1:0),0) * overlapping[i].getMass());
	}
}
