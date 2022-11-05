#include "PixelOffsets.as"
#include "RunnerTextures.as"

void onInit(CBlob@ this)
{
	if (this.get_string("reload_script") != "wilmethelmet")
		UpdateScript(this);
}

void UpdateScript(CBlob@ this) // the same as onInit, works one time when get equiped
{
    CSpriteLayer@ milhelmet = this.getSprite().addSpriteLayer("wilmethelmet", "WilmetHelmet.png", 16, 16);
   
    if (milhelmet !is null)
    {
        milhelmet.addAnimation("default", 0, true);
		int[] frames = {0, 1, 2, 3};
		milhelmet.animation.AddFrames(frames);
		//milhelmet.SetAnimation(anim);
		
		milhelmet.SetVisible(true);
        milhelmet.SetRelativeZ(200);
        if (this.getSprite().isFacingLeft())
            milhelmet.SetFacingLeft(true);
    }
}
 
void onTick(CBlob@ this)
{
    if (this.get_string("reload_script") == "wilmethelmet")
    {
        UpdateScript(this);
        this.set_string("reload_script", "");
    }
 
    CSpriteLayer@ milhelmet = this.getSprite().getSpriteLayer("wilmethelmet");
    
   
    if (milhelmet !is null)
    {
        Vec2f headoffset(this.getSprite().getFrameWidth() / 2, -this.getSprite().getFrameHeight() / 2);
        Vec2f head_offset = getHeadOffset(this, -1, 0);
       
        headoffset += this.getSprite().getOffset();
        headoffset += Vec2f(-head_offset.x, head_offset.y);
        headoffset += Vec2f(0, -1);
        milhelmet.SetOffset(headoffset);
        milhelmet.SetFrameIndex(Maths::Floor(this.get_f32("wilmethelmet_health") / 10.0f));
    }
   
    if (this.get_f32("wilmethelmet_health") >= 120.0f)
    {
        this.getSprite().PlaySound("ricochet_" + XORRandom(3));
        this.set_string("equipment_head", "");
        this.set_f32("wilmethelmet_health", 119.9f);
		if (milhelmet !is null)
		{
			this.getSprite().RemoveSpriteLayer("wilmethelmet");
		}
        this.RemoveScript("wilmethelmet_effect.as");
    }
    
	// print("helmet: "+this.get_f32("mh_health"));
}
 
void onDie(CBlob@ this)
{
	if (isServer())
	{
		CBlob@ item = server_CreateBlob("wilmethelmet", this.getTeamNum(), this.getPosition());
		if (item !is null)
		{
			item.set_f32("health", this.get_f32("wilmethelmet_health"));
			item.getSprite().SetFrameIndex(Maths::Floor(this.get_f32("wilmethelmet_health") / 9.51f));
		}
	}
	
    this.RemoveScript("wilmethelmet_effect.as");
}