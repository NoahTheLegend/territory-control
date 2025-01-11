#include "PixelOffsets.as";
#include "RunnerTextures.as";

void onInit(CBlob@ this)
{
	if (this.get_string("reload_script") != "fez")
		UpdateScript(this);
}

void UpdateScript(CBlob@ this) // the same as onInit, works one time when get equiped
{
	//this.SetLight(true);
	//this.SetLightRadius(80.0f);
	//this.SetLightColor(SColor(255, 255, 240, 171));
	
	CSpriteLayer@ fez = this.getSprite().addSpriteLayer("fez", "Fez.png", 16, 16);
	

	if (fez !is null)
	{
		fez.SetVisible(true);
		fez.SetRelativeZ(200);
		if (this.getSprite().isFacingLeft()) fez.SetFacingLeft(true);
	}
}

void onTick(CBlob@ this)
{
    if (this.get_string("reload_script") == "fez")
	{
		UpdateScript(this);
		this.set_string("reload_script", "");
	}

	if (this.get_f32("fez_health") >= 10.0f)
	{
		this.getSprite().PlaySound("woodheavyhit1");
		this.set_string("equipment_head", "");
		this.set_f32("fez_health", 9.9f);
		this.RemoveScript("fez_effect.as");
	}

	CSpriteLayer@ fez = this.getSprite().getSpriteLayer("fez");
	
	if (fez !is null)
	{
		Vec2f headoffset(this.getSprite().getFrameWidth() / 2, -this.getSprite().getFrameHeight() / 2);
		Vec2f head_offset = getHeadOffset(this, -1, 0);
		
		headoffset += this.getSprite().getOffset();
		headoffset += Vec2f(-head_offset.x, head_offset.y);
		headoffset += Vec2f(0, -3);
		fez.SetOffset(headoffset);
	}
}