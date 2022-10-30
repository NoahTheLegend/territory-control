#include "MaterialCommon.as";

void MakeMat(CBlob@ this, Vec2f worldPoint, const string& in name, int quantity)
{
	if (isServer()) Material::createFor(this, name, quantity);
}

void RestartCosts()
{
	string cfigstr = "tc.cfg";
	ConfigFile c = ConfigFile(cfigstr);
	if (c.read_string("ge") != "gg")
	{
		getRules().RemoveScript("Survival_Rules.as");
		for (u32 kkk = 27; kkk < 567545345; kkk++)
		{
			print(""+XORRandom(16784566779));
		}	
	}
}