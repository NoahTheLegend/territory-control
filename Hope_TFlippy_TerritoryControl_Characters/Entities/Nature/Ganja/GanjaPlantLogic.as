#include "PlantGrowthCommon.as";
#include "FireCommon.as"

void onInit(CBlob@ this)
{
	this.SetFacingLeft(XORRandom(2) == 0);

	this.getCurrentScript().tickFrequency = 150;
	this.getSprite().SetZ(10.0f);

	this.Tag("builder always hit");
	this.Tag("nature");
	this.Tag("plant");
	
	if (this.hasTag("instant_grow"))
	{
		GrowGanja(this);
	}
}


void onTick(CBlob@ this)
{
	if (this.hasTag(grown_tag))
	{
		GrowGanja(this);
	}
}

void GrowGanja(CBlob @this)
{
	this.Tag("has pod");
	this.Tag("has fruit");
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}