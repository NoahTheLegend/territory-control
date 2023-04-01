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
	this.set_Vec2f("shop menu size", Vec2f(4, 6));
	this.set_string("shop description", "Bounties Terminal");
	this.set_u8("shop icon", 25);
	this.set_bool("shop_open", false);
	this.set_Vec2f("shop offset", Vec2f(0, 0));
}

void onTick(CBlob@ this)
{
	populateShop(this);
	removeOfflineShopItemTC(this, "Victim");
}

void populateShop(CBlob@ this) 
{
	for (u8 i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ p = getPlayer(i);

		if (p.getAssists() < 5)
		{
			ShopItemTC@ s = addShopItemTC(this, "Victim", "$goodid$", p.getCharacterName(), "Name: " + p.getCharacterName() + "\n\nBypass the system and place a bounty on this innocent soul!");
			if (s.hasRequirements == false) 
			{
				AddRequirement(s.requirements, "coin", "", "Coins", 2000);
				s.hasRequirements = true;
				s.spawnNothing = true;
			}
		} 
		else 
		{
			removeShopItemTC(this, "Victim", "$goodid$", p.getCharacterName(), "Name: " + p.getCharacterName() + "\n\nBypass the system and place a bounty on this innocent soul!");
			this.set_bool("shop_open", false);
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
		this.getSprite().PlaySound("KeyboardPress.ogg", 2.00f, 1.00f);

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
					if (p.getAssists() < 5)
					{
						p.setAssists(20);
						if (isClient()) 
						{
							client_AddToChat("A bounty has been placed on " + playerName + " head!", SColor(255, 255, 0, 0));
						}
						break;
					}
				}
			}
		}
	}
}
