void onInit(CBlob@ this)
{
	this.Tag("furniture");
	this.Tag("heavy weight");
	
	this.set_f32("pickup_priority", 8.00f);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return true;
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return forBlob.isOverlapping(this);
}
