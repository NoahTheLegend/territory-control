#include "RunnerCommon.as"

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    return damage;
}

void onTick(CBlob@ this)
{
    RunnerMoveVars@ moveVars;
    if (this.get("moveVars", @moveVars))
    {
        moveVars.walkFactor *= 1.2f;
		moveVars.jumpFactor *= 2.5f;
    }
}