
string[] names = 
{ 
	"Pete",
	"Morgan",
	"Jack",
	"Daniels",
	"Barbossa",
	"Gull",
	"Yiff",
	"Jones",
	"Tweety",
	"Birdd",
	"Willem",
	"Michiel",
	"Piter"
};

void onInit(CBlob@ this)
{
	Random@ rand = Random(this.getNetworkID());
	string name;
	if (this.getName() == "pirategull")
	{
		name = "Pirate " + names[rand.NextRanged(names.length)];
	}
	else if (this.getName() == "cowboygull")
	{
		name = "Cowboy " + names[rand.NextRanged(names.length)];
	}
	else if (this.getName() == "heavypirategull")
	{
		name = "Tanky " + names[rand.NextRanged(names.length)];
	}
	
	this.set_string("chicken name", name);
	this.setInventoryName(name);
	
	this.Tag("dangerous");
}