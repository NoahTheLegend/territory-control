//Script by Skemonde
//If you want explosives have this timer simply add this script to explosives' config and...
//...add 'this.set_u8("death_timer", INSERT_YOUR_TIME_IN_SECONDS);' into their script

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();

	CSpriteLayer@ timer = sprite.addSpriteLayer("timer", "Timer.png", 5, 7);
	timer.SetFrameIndex(9);
	if (timer !is null)
	{
		timer.SetOffset(timer_offset);
		timer.setRenderStyle(RenderStyle::additive);
		timer.SetRelativeZ(2000.0f);
	}
	this.set_u32("death_date", getGameTime() + (this.get_u8("death_timer") * 30));
}

const Vec2f timer_offset = Vec2f(0, -8);

void onTick( CBlob@ this )
{
	CSpriteLayer@ timer = this.getSprite().getSpriteLayer("timer");
	timer.SetFacingLeft(false);
		
	if (this.get_u32("death_date") >= getGameTime() && timer !is null) {

		timer.SetFrameIndex(Maths::Floor(((this.get_u32("death_date") - getGameTime()) / 30) + 1));
	} else this.server_Die();
}