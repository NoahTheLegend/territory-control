#include "PixelOffsets.as";
#include "RunnerTextures.as";

void onInit(CBlob@ this)
{
	if (this.get_string("reload_script") != "jingasa")
		UpdateScript(this);
}

void UpdateScript(CBlob@ this) // the same as onInit, works one time when get equiped
{
	//this.SetLight(true);
	//this.SetLightRadius(80.0f);
	//this.SetLightColor(SColor(255, 255, 240, 171));
	
	CSpriteLayer@ jingasa = this.getSprite().addSpriteLayer("jingasa", "Jingasa.png", 16, 16);
	

	if (jingasa !is null)
	{
		jingasa.SetVisible(true);
		jingasa.SetRelativeZ(200);
		if (this.getSprite().isFacingLeft())
			jingasa.SetFacingLeft(true);
	}
}

void onTick(CBlob@ this)
{
    if (this.get_string("reload_script") == "jingasa")
	{
		UpdateScript(this);
		this.set_string("reload_script", "");
	}

	if (this.get_f32("jingasa_health") >= 10.0f)
	{
		this.getSprite().PlaySound("woodheavyhit1");
		this.set_string("equipment_head", "");
		this.set_f32("jingasa_health", 9.9f);
		this.RemoveScript("jingasa_effect.as");
	}

	CSpriteLayer@ jingasa = this.getSprite().getSpriteLayer("jingasa");
	
	if (jingasa !is null)
	{
		Vec2f headoffset(this.getSprite().getFrameWidth() / 2, -this.getSprite().getFrameHeight() / 2);
		Vec2f head_offset = getHeadOffset(this, -1, 0);
		
		headoffset += this.getSprite().getOffset();
		headoffset += Vec2f(-head_offset.x, head_offset.y);
		headoffset += Vec2f(0, -3);
		jingasa.SetOffset(headoffset);

		//if (isClient()) this.Tag("stealth");
	}
	// else 
	// {
	// 	if (isClient())
	// 	{
	// 	 if (this.hasTag("stealth")) this.Untag("stealth");
	// 	}
	// }
}