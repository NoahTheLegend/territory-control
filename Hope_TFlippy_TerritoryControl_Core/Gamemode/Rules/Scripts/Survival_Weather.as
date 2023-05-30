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
							rain.server_SetTimeToDie(length / 30.00f);
						}
					}
					break;
					
					case MapType::desert:
					{
						CBlob@ rain = server_CreateBlob("sandstorm", 255, Vec2f(0, 0));
						if (rain !is null)
						{
							rain.server_SetTimeToDie(length / 30.00f);
						}
					}
					break;

					//case MapType::magmacore:
					//{
					//	break;
					//}
					
					case MapType::normal:
					case MapType::jungle:
					case MapType::dead:
					default:
					{
						CBlob@ rain = server_CreateBlob("rain", 255, Vec2f(0, 0));
						if (rain !is null)
						{
							rain.server_SetTimeToDie(length / 30.00f);
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
		u8 rand = XORRandom(100);

		if (rand < 4)
		{
			//if (XORRandom(3) == 0)
				server_CreateBlob("info_dead", 255, Vec2f(0, 0));
			//else
			//	server_CreateBlob("info_magmacore", 255, Vec2f(0, 0));
		}
		else if (rand >= 4 && rand < 14) server_CreateBlob("info_jungle", 255, Vec2f(0, 0));
		else if (rand >= 14 && rand < 30) server_CreateBlob("info_arctic", 255, Vec2f(0, 0));
		else if (rand >= 30 && rand < 63) server_CreateBlob("info_desert", 255, Vec2f(0, 0));
		else server_CreateBlob("info_forest", 255, Vec2f(0,0));
	}
	this.set_bool("updated", true);
}
