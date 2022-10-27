#include "PixelOffsets.as";
#include "RunnerTextures.as";

void onInit(CBlob@ this)
{
	if (this.get_string("reload_script") != "beret")
		UpdateScript(this);
}

void UpdateScript(CBlob@ this) // the same as onInit, works one time when get equiped
{
	//this.SetLight(true);
	//this.SetLightRadius(80.0f);
	//this.SetLightColor(SColor(255, 255, 240, 171));
	
	CSpriteLayer@ beret = this.getSprite().addSpriteLayer("beret", "Beret.png", 16, 16);
	

	if (beret !is null)
	{
		beret.SetVisible(true);
		beret.SetRelativeZ(200);
		if (this.getSprite().isFacingLeft()) beret.SetFacingLeft(true);
	}
}

void onTick(CBlob@ this)
{
    if (this.get_string("reload_script") == "beret")
	{
		UpdateScript(this);
		this.set_string("reload_script", "");
	}

	if (this.get_f32("beret_health") >= 10.0f)
	{
		this.getSprite().PlaySound("woodheavyhit1");
		this.set_string("equipment_head", "");
		this.set_f32("beret_health", 9.9f);
		this.RemoveScript("beret_effect.as");
	}

	CSpriteLayer@ beret = this.getSprite().getSpriteLayer("beret");
	
	if (beret !is null)
	{
		Vec2f headoffset(this.getSprite().getFrameWidth() / 2, -this.getSprite().getFrameHeight() / 2);
		Vec2f head_offset = getHeadOffset(this, -1, 0);
		
		headoffset += this.getSprite().getOffset();
		headoffset += Vec2f(-head_offset.x, head_offset.y);
		headoffset += Vec2f(0, -3);
		beret.SetOffset(headoffset);
	}
}