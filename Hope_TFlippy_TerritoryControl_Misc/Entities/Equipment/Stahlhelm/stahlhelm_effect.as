#include "PixelOffsets.as";
#include "RunnerTextures.as";

void onInit(CBlob@ this)
{
	if(this.get_string("reload_script") != "stahlhelm")
		UpdateScript(this);
}

void UpdateScript(CBlob@ this) // the same as onInit, works one time when get equiped
{
    CSpriteLayer@ stahlhelm = this.getSprite().addSpriteLayer("stahlhelm", "Stahlhelm.png", 16, 16);
   
    if (stahlhelm !is null)
    {
		stahlhelm.SetVisible(true);
        stahlhelm.SetRelativeZ(200);
        if(this.getSprite().isFacingLeft())
            stahlhelm.SetFacingLeft(true);
    }
}
 
void onTick(CBlob@ this)
{
    if(this.get_string("reload_script") == "stahlhelm")
    {
        UpdateScript(this);
        this.set_string("reload_script", "");
    }
 
    CSpriteLayer@ stahlhelm = this.getSprite().getSpriteLayer("stahlhelm");
   
    if (stahlhelm !is null)
    {
        Vec2f headoffset(this.getSprite().getFrameWidth() / 2, -this.getSprite().getFrameHeight() / 2);
        Vec2f head_offset = getHeadOffset(this, -1, 0);
       
        headoffset += this.getSprite().getOffset();
        headoffset += Vec2f(-head_offset.x, head_offset.y);
        headoffset += Vec2f(0, -1);
        stahlhelm.SetOffset(headoffset);
    }
   
    if(this.get_f32("sh_health") >= 120.0f)
    {
        this.getSprite().PlaySound("ricochet_" + XORRandom(3));
        this.set_string("equipment_head", "");
        this.set_f32("sh_health", 0.0f);
		if (stahlhelm !is null)
		{
			this.getSprite().RemoveSpriteLayer("stahlhelm");
		}
        this.RemoveScript("stahlhelm_effect.as");
    }
}
 
void onDie(CBlob@ this)
{
	this.RemoveScript("stahlhelm_effect.as");
}