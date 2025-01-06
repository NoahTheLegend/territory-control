#include "Knocked.as";
#include "RunnerCommon.as";
#include "Hitters.as";
#include "HittersTC.as";
#include "EmotesCommon.as"

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	string config = this.getConfig();

	Animation@ animation_build = sprite.getAnimation("build");
	if (animation_build !is null) animation_build.time = 1;

	this.set_u32("build delay", 1);
}