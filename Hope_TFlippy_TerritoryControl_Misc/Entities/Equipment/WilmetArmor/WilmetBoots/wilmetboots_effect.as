#include "RunnerCommon.as"

void onTick(CBlob@ this)
{
    if (this.get_string("reload_script") == "wilmetboots")
        this.set_string("reload_script", "");
    
        RunnerMoveVars@ moveVars;
    if (this.get("moveVars", @moveVars))
    {
        moveVars.walkFactor *= 1.1f;
		moveVars.jumpFactor *= 2.0f;
    }
    
    if (this.get_f32("wilmetboots_health") >= 85.0f)
    {
        this.getSprite().PlaySound("ricochet_" + XORRandom(3));
        this.set_string("equipment_boots", "");
        this.set_f32("wilmetboots_health", 84.9f);
        this.RemoveScript("wilmetboots_effect.as");
    }
}