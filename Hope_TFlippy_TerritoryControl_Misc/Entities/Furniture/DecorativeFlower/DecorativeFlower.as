void onInit(CBlob@ this)
{
    this.getShape().SetOffset(Vec2f(0, 2));

	this.Tag("furniture");
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}