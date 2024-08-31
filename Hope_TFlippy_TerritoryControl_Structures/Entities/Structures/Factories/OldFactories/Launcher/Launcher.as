
#include "FilteringCommon.as";

void onInit(CBlob@ this){
	
	this.set_bool("whitelist", false);
	this.Tag("place norotate");
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || blob.hasTag("player")) return;
	if (blob.getPosition().y > this.getPosition().y) return;
	if (blob.getShape().isStatic())return;
	if (blob.isAttached() || blob.isInWater())return;
	if (!server_isItemAccepted(this, blob.getName()))return;
	if (blob.hasTag("chicken_turret"))return;
	
	f32 velx = this.isFacingLeft() ? -2.0f : 2.0f;
	if (Maths::Abs(blob.getVelocity().y) < 2.0f){
		if(blob.getPosition().x > this.getPosition().x-1 && blob.getPosition().x < this.getPosition().x+1){
			blob.setVelocity(Vec2f(velx, -8.0f));
		} else {
			blob.setVelocity(Vec2f(velx, -8.0f));
			blob.setPosition(Vec2f(this.getPosition().x,blob.getPosition().y));
		}
		if(isClient()) 
		if(this.getSprite() !is null){
			this.getSprite().SetAnimation("jump");
			this.getSprite().SetFrameIndex(0);
			this.getSprite().PlaySound("/launcher_boing" + XORRandom(2) + ".ogg", 0.5f, 0.9f);
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}