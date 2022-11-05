#include "RunnerCommon.as"

void onTick(CBlob@ this)
{
    if (this.get_string("reload_script") == "carbonboots")
        this.set_string("reload_script", "");
    
    RunnerMoveVars@ moveVars;
    if (this.get("moveVars", @moveVars))
    {
        moveVars.walkFactor *= 0.975f;
    }
    
    if (this.get_f32("carbonboots_health") >= 98.0f)
    {
        this.getSprite().PlaySound("ricochet_" + XORRandom(3));
        this.set_string("equipment_boots", "");
        this.set_f32("carbonboots_health", 97.9f);
        this.RemoveScript("carbonboots_effect.as");
    }
}