#include "PixelOffsets.as";
#include "RunnerTextures.as";

void onInit(CBlob@ this)
{
	if (this.get_string("reload_script") != "priesthat")
		UpdateScript(this);
}

void UpdateScript(CBlob@ this) // the same as onInit, works one time when get equiped
{
	//this.SetLight(true);
	//this.SetLightRadius(80.0f);
	//this.SetLightColor(SColor(255, 255, 240, 171));
	
	CSpriteLayer@ priestHat = this.getSprite().addSpriteLayer("priesthat", "PriestHat.png", 16, 16);
	

	if (priestHat !is null)
	{
		priestHat.SetVisible(true);
		priestHat.SetRelativeZ(200);
		if (this.getSprite().isFacingLeft()) priestHat.SetFacingLeft(true);
	}
}

void onTick(CBlob@ this)
{
    if (this.get_string("reload_script") == "priesthat")
	{
		UpdateScript(this);
		this.set_string("reload_script", "");
	}

	if (this.get_f32("priesthat_health") >= 10.0f)
	{
		this.getSprite().PlaySound("woodheavyhit1");
		this.set_string("equipment_head", "");
		this.set_f32("priesthat_health", 9.9f);
		this.RemoveScript("priesthat_effect.as");
	}

	CSpriteLayer@ priestHat = this.getSprite().getSpriteLayer("priesthat");
	
	if (priestHat !is null)
	{
		Vec2f headoffset(this.getSprite().getFrameWidth() / 2, -this.getSprite().getFrameHeight() / 2);
		Vec2f head_offset = getHeadOffset(this, -1, 0);
		
		headoffset += this.getSprite().getOffset();
		headoffset += Vec2f(-head_offset.x, head_offset.y);
		headoffset += Vec2f(0, -3);
		priestHat.SetOffset(headoffset);

		// if (isClient()) this.Tag("sanctfied");
	} 
	// else 
	// {
	// 	if (isClient())
	// 	{
	// 	 if (this.hasTag("sanctfied")) this.Untag("sanctfied");
	// 	}
	// }
}