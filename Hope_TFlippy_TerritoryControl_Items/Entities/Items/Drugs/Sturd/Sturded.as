#include "Knocked.as";
#include "RunnerCommon.as";
#include "Hitters.as";
#include "HittersTC.as";
#include "MakeDustParticle.as";

void onTick(CBlob@ this)
{
	if (this.hasTag("dead")) return;
	
	f32 true_level = this.get_f32("sturded");		
	f32 level = 1.00f + true_level;
	if (true_level > 4.0f) true_level = 4.0f;
	
	if (true_level <= 0)
	{
		if (isClient() && this.isMyPlayer())
		{
			if (getBlobByName("info_dead") !is null)
				getMap().CreateSkyGradient("Dead_skygradient.png");	
			else if (getBlobByName("info_magmacore") !is null)
				getMap().CreateSkyGradient("MagmaCore_skygradient.png");	
			else
				getMap().CreateSkyGradient("skygradient.png");	
		}
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
	else
	{
		f32 time = f32(getGameTime() * level);
		
		RunnerMoveVars@ moveVars;
		if (this.get("moveVars", @moveVars))
		{
			moveVars.walkFactor *= 0.9f;
			moveVars.jumpFactor *= 1.25f + true_level;
		}	
					
		this.set_f32("sturded", Maths::Max(0, this.get_f32("sturded") - (0.00025f)));
	}
	
	// print("" + true_level);
	// print("" + (1.00f / (level)));
}
