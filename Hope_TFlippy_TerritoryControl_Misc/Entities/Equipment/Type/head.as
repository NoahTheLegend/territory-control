void onInit(CBlob@ this)
{
	this.Tag("head");

	if (this.getName() == "militaryhelmet" || this.getName() == "carbonhelmet" || this.getName() == "wilmethelmet")
		this.Tag("armor");
}