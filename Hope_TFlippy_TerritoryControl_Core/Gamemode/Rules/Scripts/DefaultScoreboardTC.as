
// Custom scoreboard to handle kills, deaths, killstreak and bounties

#include "AssistCommon.as";

void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (!this.isGameOver() && !this.isWarmup())	//Only count kills, deaths and assists when the game is on
	{
		if (blob !is null)
		{
			CPlayer@ killer = blob.getPlayerOfRecentDamage();
			CPlayer@ victim = blob.getPlayer();
			CPlayer@ helper = getAssistPlayer(victim, killer);

			if (helper !is null)
			{
				helper.setAssists(helper.getAssists() + 1);
			}

			if (victim !is null)
			{
				victim.setDeaths(victim.getDeaths() + 1);
				//announceDeaths(victim);
				if (killer !is null) //requires victim so that killing trees matters
				{
					if (killer.getTeamNum() != blob.getTeamNum() && killer.getCharacterName() != victim.getCharacterName())
					{
						killer.setKills(killer.getKills() + 1);
                        killer.setAssists(killer.getAssists() + 1);
						dropBounty(victim);
						announceKills(killer);
						victim.setScore(0);
                		victim.setAssists(0);
					}
				}
			}
		}
	}
}

void announceKills(CPlayer@ this)
{
    string playerName = this.getCharacterName();
    bool hasFirstKill;

	if (this.isMyPlayer() && this.get_bool("no_ks_sounds")) return;

    if (this.getKills() == 1)
    {
        for (u8 i = 0; i < getPlayersCount(); i++)
	    {
		    CPlayer@ p = getPlayer(i);
		    if (p.getKills() > 0 && p.getCharacterName() != playerName) 
            {
                hasFirstKill = true;
                break;
            }
	    }

        if (!hasFirstKill)
        {
			if (isClient())
			{
				Sound::Play("FirstBlood.ogg");
				client_AddToChat(playerName + " got the first kill!", SColor(255, 255, 0, 0));
			}
        }
        return;
    }

    switch(this.getAssists()) 
    {
        case 5:
			if (isClient())
			{
				switch (XORRandom(1))
				{
					case 0:
						Sound::Play("Unstoppable.ogg");
						break;
					case 1:
						Sound::Play("Rampage.ogg");
						break;
				}
			}
			client_AddToChat(playerName + " murdered 5 in a row !", SColor(255, 255, 0, 0));
            break;
        case 10:
			if (isClient())
			{
				switch (XORRandom(1))
				{
					case 0:
						Sound::Play("HolyShit.ogg");
						break;
					case 1:
						Sound::Play("Dominating.ogg");
						break;
				}
				client_AddToChat(playerName + " has slayed 10 in a row, be careful !", SColor(255, 255, 0, 0));
			}
            break;
        case 15:
			if (isClient())
			{
				switch (XORRandom(1))
				{
					case 0:
						Sound::Play("GodLike.ogg");
						break;
					case 1:
						Sound::Play("UltraKill.ogg");
						break;
				}
				client_AddToChat(playerName + " exterminated 15 souls, may God help us !", SColor(255, 255, 0, 0));
			}
            break;
        case 20:
			if (isClient())
			{
				Sound::Play("MonsterKill.ogg");
				client_AddToChat(playerName + " wiped out the server with a 20 killstreak, it's over !", SColor(255, 255, 0, 0));
			}
            break;
    }
}

void dropBounty(CPlayer@ this) 
{
	
	
	int killstreak = this.getAssists();
	int payedBounty = this.getScore();
	CBlob@ blob = this.getBlob();
	string playerName = this.getCharacterName();

	if (killstreak >= 5 && killstreak < 10) 
	{
		createBounty(blob, 4, payedBounty);
		announceBounty(playerName, 4, payedBounty);
	} 

	if (killstreak >= 10 && killstreak < 15) 
	{
		createBounty(blob, 6, payedBounty);
		announceBounty(playerName, 6, payedBounty);
	}

	if (killstreak >= 15 && killstreak < 20)
	{
		createBounty(blob, 8, payedBounty);
		announceBounty(playerName, 8, payedBounty);
	}

	if (killstreak >= 20)
	{
		createBounty(blob, 10, payedBounty);
		announceBounty(playerName, 10, payedBounty);
	}
	
}

void createBounty(CBlob@ this, int bounty, int payedBounty) 
{
	if (isServer()) 
	{
		CBlob@ blob = server_CreateBlob("mat_goldingot", this.getTeamNum(), this.getPosition());
		payedBounty != 0 ? blob.server_SetQuantity(bounty + (payedBounty / 100)): blob.server_SetQuantity(bounty);
	}
}

void announceBounty(string playerName, int bounty, int payedBounty) 
{
	int totalBounty = payedBounty != 0 ? bounty + (payedBounty / 100) : bounty;
	if (isClient()) 
	{
		Sound::Play("Coins.ogg");
		client_AddToChat(playerName + " has been killed and dropped " + totalBounty + " gold ingots as bounty!", SColor(255, 255, 0, 0));
	}
}

// void announceDeaths(CPlayer@ this)
// {
// 	if (this.getDeaths() == 21) 
// 	{
// 		if (isClient()) 
// 		{
// 			Sound::Play("Skill_Issue.ogg");
// 			client_AddToChat(this.getCharacterName() + " has died more than 20 times!", SColor(255, 255, 0, 0));
// 		}
// 	}
// }