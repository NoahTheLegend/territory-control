void onInit(CBlob@ this)
{
	this.SetLight(true);
	this.SetLightRadius(24.0f);
	this.SetLightColor(SColor(255, 25, 255, 100));

	this.Tag("dangerous");
}
