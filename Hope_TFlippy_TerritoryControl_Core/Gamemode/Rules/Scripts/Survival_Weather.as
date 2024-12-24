#define SERVER_ONLY
#include "CustomBlocks.as";
#include "MapType.as";

u32 next_rain = 1000;

void onInit(CRules@ this)
{
	this.set_bool("raining", false);
	
	u32 time = getGameTime();
	next_rain = time + 2500 + XORRandom(40000);
	this.set_bool("updated", false);
}

void onRestart(CRules@ this)
{
	this.set_bool("raining", false);

	u32 time = getGameTime();
	next_rain = time + 2500 + XORRandom(40000);
	this.set_bool("updated", false);
	// print("Rain start: " + start_rain + "; Length: " + (end_rain - start_rain));
}

void onTick(CRules@ this)
{
	if (isServer())
	{
		if (!this.get_bool("updated")) updateEnvironment(this);

		u32 time = getGameTime();
		if (time >= next_rain)
		{
			u32 length = (30 * 60 * 1) + XORRandom(30 * 60 * 4);

			if (!this.get_bool("raining"))
			{
				switch (this.get_u8("map_type"))
				{
					case MapType::arctic:
					{
						CBlob@ rain = server_CreateBlob("blizzard", 255, Vec2f(0, 0));
						if (rain !is null)
						{

						}
					}
					break;

					case MapType::desert:
					{
						break;
					}
					
					case MapType::normal:
					case MapType::jungle:
					case MapType::dead:
					default:
					{
						CBlob@ rain = server_CreateBlob("rain", 255, Vec2f(0, 0));
						if (rain !is null)
						{
							
						}
					}
					break;
				}
			}

			next_rain = time + length + 10000 + XORRandom(75000);
		}
	}
}

void updateEnvironment(CRules@ this) 
{
	if (isServer())
	{
		//u8 chance_dead = 4;
		//u8 chance_jungle = 10;
		//u8 chance_arctic = 16;
		//u8 chance_desert = 33;
		//u8 chance_forest = 37; // Sum should be 100

		// xmas holiday
		u8 chance_dead = 4-2;
		u8 chance_jungle = 10-5;
		u8 chance_arctic = 16+37;
		u8 chance_desert = 33-15;
		u8 chance_forest = 37-15;

		array<string> blobs = {"info_dead", "info_jungle", "info_arctic", "info_desert", "info_forest"};

		u8 rand = XORRandom(100);
		u8 cumulative = 0;

		array<u8> chances = {chance_dead, chance_jungle, chance_arctic, chance_desert, chance_forest};

		for (uint i = 0; i < chances.length(); i++)
		{
			cumulative += chances[i];
			if (rand < cumulative)
			{
				server_CreateBlob(blobs[i], 255, Vec2f(0, 0));
				break;
			}
		}
	}
	this.set_bool("updated", true);
}
