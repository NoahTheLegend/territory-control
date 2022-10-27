#include "PixelOffsets.as";
#include "RunnerTextures.as";

void onInit(CBlob@ this)
{
	if (this.get_string("reload_script") != "cowboyhat")
		UpdateScript(this);
}

void UpdateScript(CBlob@ this) // the same as onInit, works one time when get equiped
{
	//this.SetLight(true);
	//this.SetLightRadius(80.0f);
	//this.SetLightColor(SColor(255, 255, 240, 171));
	
	CSpriteLayer@ cowhat = this.getSprite().addSpriteLayer("cowboyhat", "CowboyHat.png", 16, 16);
	

	if (cowhat !is null)
	{
		cowhat.SetVisible(true);
		cowhat.SetRelativeZ(200);
		if (this.getSprite().isFacingLeft())
			cowhat.SetFacingLeft(true);
	}
}

void onTick(CBlob@ this)
{
    if (this.get_string("reload_script") == "cowboyhat")
	{
		UpdateScript(this);
		this.set_string("reload_script", "");
	}

	if (this.get_f32("cowboyhat_health") >= 10.0f)
	{
		this.getSprite().PlaySound("woodheavyhit1");
		this.set_string("equipment_head", "");
		this.set_f32("cowboyhat_health", 9.9f);
		this.RemoveScript("cowboyhat_effect.as");
	}

	CSpriteLayer@ cowhat = this.getSprite().getSpriteLayer("cowboyhat");
	
	if (cowhat !is null)
	{
		Vec2f headoffset(this.getSprite().getFrameWidth() / 2, -this.getSprite().getFrameHeight() / 2);
		Vec2f head_offset = getHeadOffset(this, -1, 0);
		
		headoffset += this.getSprite().getOffset();
		headoffset += Vec2f(-head_offset.x, head_offset.y);
		headoffset += Vec2f(0, -3);
		cowhat.SetOffset(headoffset);
	}
}