void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(true);

	this.Tag("boots");

	if (this.getName() == "stinkers")
		this.Tag("armor");
}