#include "PixelOffsets.as"
#include "RunnerTextures.as"

void onInit(CBlob@ this)
{
	if (this.get_string("reload_script") != "villaincap")
		UpdateScript(this);
}

void UpdateScript(CBlob@ this) // the same as onInit, works one time when get equiped
{
	//this.SetLight(true);
	//this.SetLightRadius(80.0f);
	//this.SetLightColor(SColor(255, 255, 240, 171));
	
	CSpriteLayer@ villaincap = this.getSprite().addSpriteLayer("villaincap", "VillainCap.png", 16, 16);
	

	if (villaincap !is null)
	{
		villaincap.SetVisible(true);
		villaincap.SetRelativeZ(200);
		if (this.getSprite().isFacingLeft())
			villaincap.SetFacingLeft(true);
	}
}

void onTick(CBlob@ this)
{
    if (this.get_string("reload_script") == "villaincap")
	{
		UpdateScript(this);
		this.set_string("reload_script", "");
	}

	if (this.get_f32("villaincap_health") >= 10.0f)
	{
		this.getSprite().PlaySound("woodheavyhit1");
		this.set_string("equipment_head", "");
		this.set_f32("villaincap_health", 9.9f);
		this.RemoveScript("villaincap_effect.as");
	}

	CSpriteLayer@ villaincap = this.getSprite().getSpriteLayer("villaincap");
	
	if (villaincap !is null)
	{
		Vec2f headoffset(this.getSprite().getFrameWidth() / 2, -this.getSprite().getFrameHeight() / 2);
		Vec2f head_offset = getHeadOffset(this, -1, 0);
		
		headoffset += this.getSprite().getOffset();
		headoffset += Vec2f(-head_offset.x, head_offset.y);
		headoffset += Vec2f(0, -3);
		villaincap.SetOffset(headoffset);
	}
}