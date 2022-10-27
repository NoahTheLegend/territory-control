#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.set_f32("scope_zoom", 0.35f);

	if (this.getSprite() !is null) this.getSprite().SetRelativeZ(201);
}
