
void onInit(CBlob@ this)
{
	this.SetLight(true);
	this.SetLightRadius(156.0f);
	this.SetLightColor(SColor(255, 125, 125, 255));

	CSpriteLayer@ l = this.getSprite().addSpriteLayer("layer", "JellyfishJar.png", 16, 32);
	if (l !is null)
	{
		l.SetFrameIndex(4);
		l.setRenderStyle(RenderStyle::additive);
	}

	this.Tag("builder always hit");
	this.Tag("ignore_arrow");
	this.Tag("ignore fall");
	this.Tag("furniture");
	this.Tag("heavy weight");

	this.getSprite().SetZ(-20.0f);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return true;
}