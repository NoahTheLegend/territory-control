#include "Requirements.as";
#include "ShopCommonTC.as";
#include "CTFShopCommon.as";

Random traderRandom(Time());

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;
	this.Tag("builder always hit");
	this.set_Vec2f("shop menu size", Vec2f(4, 2));
	this.set_string("shop description", "Most Wanted Player's");
	this.set_u8("shop icon", 25);
	this.set_bool("shop_open", false);
	this.set_Vec2f("shop offset", Vec2f(0, 0));
}

void onTick(CBlob@ this)
{
	populateShop(this);
}

void populateShop(CBlob@ this) 
{
	for (u8 i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ p = getPlayer(i);

		if (p.getAssists() < 5)
		{
			removeShopItemTC(this, "Wanted Criminal", "$icon_paper$", p.getCharacterName(), "Identification: " + p.getCharacterName() + "\n\nIncrease the criminal bounty reward to make sure he will be hunted!");
			this.set_bool("shop_open", false);
		}
		else
		{
			{
				ShopItemTC@ s = addShopItemTC(this, "Wanted Criminals", "$icon_paper$", p.getCharacterName(), "Identification: " + p.getCharacterName() + "\n\nIncrease the criminal bounty reward to make sure he will be hunted!");
				if (s.hasRequirements == false) 
				{
					AddRequirement(s.requirements, "coin", "", "Coins", 500);
					s.hasRequirements = true;
					s.spawnNothing = true;
				}
			}
			this.set_bool("shop_open", true);
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (this.get_bool("shop_open") == true) 
	{
		this.set_bool("shop available", this.isOverlapping(caller));
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if(cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("LotteryTicket_Kaching", 2.00f, 1.00f);

		u16 caller, item;

		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;

		string name = params.read_string();
		CBlob@ callerBlob = getBlobByNetworkID(caller);

		if (callerBlob is null) return;

		string[] spl = name.split("-");

		if (spl[0] == "coin")
		{
			if (isServer()) 
			{
			CPlayer@ callerPlayer = callerBlob.getPlayer();
			if (callerPlayer is null) return;
			callerPlayer.server_setCoins(callerPlayer.getCoins() +  parseInt(spl[1]));
			}
		}
		else
		{
			string playerName = spl[0];
			if (playerName == "") return;

			for (u8 i = 0; i < getPlayersCount(); i++)
			{
				CPlayer@ p = getPlayer(i);
				if (p.getCharacterName() == playerName)
				{
					if (p.getScore() < 30000)
					{
						p.setScore(p.getScore() + 500);
						if (isClient()) 
						{
							client_AddToChat(playerName + " bounty has been increased by $500!", SColor(255, 255, 0, 0));
						}
						break;
					}
					else 
					{
						if (callerBlob.isMyPlayer()) 
						{
							if (isClient())
							{
								client_AddToChat("Bounty maximum value has been reached, don't waste you money son.", SColor(255, 255, 0, 0));
							}
						}
						break;
					}
				}
			}
		}
	}
}
