#include "RunnerCommon.as"

void onTick(CBlob@ this)
{
    if (this.get_string("reload_script") == "combatboots")
        this.set_string("reload_script", "");
    
    RunnerMoveVars@ moveVars;
    if (this.get("moveVars", @moveVars))
    {
        moveVars.walkFactor *= 5.0f;
        moveVars.jumpFactor *= 5.0f;
    }
    
    if (this.get_f32("stinkers_health") >= 48.0f)
    {
        this.getSprite().PlaySound("ricochet_" + XORRandom(3));
        this.set_string("equipment_boots", "");
        this.set_f32("stinkers_health", 47.9f);
        this.RemoveScript("Stinkers_effect.as");
    }
}