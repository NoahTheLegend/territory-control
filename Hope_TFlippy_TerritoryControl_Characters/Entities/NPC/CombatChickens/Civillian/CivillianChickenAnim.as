#include "RunnerTextures.as"

void onInit(CSprite@ this)
{
	addRunnerTextures(this, "civillianchicken", "CivillianChicken");

	this.getCurrentScript().runFlags |= Script::tick_not_infire;
}

void onPlayerInfoChanged(CSprite@ this)
{
	addRunnerTextures(this, "civillianchicken", "CivillianChicken");
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	if (blob.hasTag("dead"))
	{
		this.SetAnimation("dead");
		return;
	}
	
	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	
	if (right || left)
	{
		this.SetAnimation("walk");
	}
	else this.SetAnimation("idle");
	
	Vec2f vel = blob.getVelocity();
	this.SetFacingLeft(vel.x > 0.0f);
}