void onInit(CBlob@ this)
{
	this.Tag("torso");
	
	if (this.getName() == "suicidevest" || this.getName() == "keg")
		this.Tag("explosive");

	else if (this.getName() == "bulletproofvest" || this.getName() == "carbonvest" || this.getName() == "wilmetvest")
		this.Tag("armor");
}