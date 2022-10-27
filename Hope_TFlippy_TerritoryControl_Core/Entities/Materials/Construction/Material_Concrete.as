void onInit(CBlob@ this)
{	
	this.maxQuantity = 3000;
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}