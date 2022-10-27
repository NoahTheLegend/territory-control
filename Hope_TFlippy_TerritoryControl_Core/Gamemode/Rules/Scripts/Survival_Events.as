#define SERVER_ONLY

void onInit(CRules@ this)
{
	u32 time = getGameTime();
	this.set_u32("lastMeteor", time);
	this.set_u32("lastWreckage", time);
	this.set_u32("lastCapsule", time);
//	this.set_u32("lastnuke", time);
//	this.set_u32("nuketimer", XORRandom(50*30)+10*30);
//	this.set_u32("timetonuke", 1);
//	this.set_bool("timetonukego", false);
//	this.set_bool("stillnuking?", false);
//	this.set_u32("random", XORRandom(80000)+30000);
//	this.set_bool("activated", false);
//	this.set_bool("alwaysnight", false);
//	this.set_bool("cancelnight", false);


//	this.set_u32("nightevent", XORRandom(11));
	this.addCommandID("callputin");
	this.addCommandID("alwaysnightevent");
	this.addCommandID("alwaysnighteventcancel");
//	nightevent in chatcommands
}

void onRestart(CRules@ this)
{
	u32 time = getGameTime();
	this.set_u32("lastMeteor", time);
	this.set_u32("lastWreckage",time);
//	this.set_u32("lastnuke", time);
//	this.set_u32("lastCapsule", time);
//	this.set_u32("nuketimer", XORRandom(50*30)+10*30);
//	this.set_u32("timetonuke", 1);
//	this.set_bool("timetonukego", false);
//	this.set_bool("stillnuking?", false);
//	this.set_u32("random", XORRandom(80000)+30000);
//	this.set_bool("activated", false);
//	this.set_bool("nightcall", false);
//	this.set_bool("alwaysnight", false);
//	this.set_bool("cancelnight", false);
//	
//	this.set_u32("nightevent", XORRandom(11));
	this.addCommandID("callputin");
	this.addCommandID("nightevent");
	this.addCommandID("alwaysnightevent");
	this.addCommandID("alwaysnighteventcancel");
}

void onTick(CRules@ this)
{
    if (getGameTime() % 30 == 0)
    {
		CMap@ map = getMap();

		u32 lastMeteor = this.get_u32("lastMeteor");
		u32 lastWreckage = this.get_u32("lastWreckage");
		u32 lastNuke = this.get_u32("lastnuke");
		
		u32 time = getGameTime();
		u32 timeSinceMeteor = time - lastMeteor;
		u32 timeSinceWreckage = time - lastWreckage;
		u32 timeSinceNuke = time - lastNuke;

        if (timeSinceMeteor > 6000 && XORRandom(Maths::Max(35000 - timeSinceMeteor, 0)) == 0) // Meteor strike
        {
			tcpr("[RGE] Random event: Meteor");
            server_CreateBlob("meteor", -1, Vec2f(XORRandom(map.tilemapwidth) * map.tilesize, 0.0f));
			
			this.set_u32("lastMeteor", time);
        }
		
		if (timeSinceWreckage > 30000 && XORRandom(Maths::Max(250000 - timeSinceWreckage, 0)) == 0) // Wreckage 30000 250000
        {
            tcpr("[RGE] Random event: Wreckage");
            server_CreateBlob(XORRandom(100) > 50 ? "ancientcapsule" : "poisonship", -1, Vec2f(XORRandom(map.tilemapwidth) * map.tilesize, 0.0f));
			
			this.set_u32("lastWreckage", time);
    	}
		/*
		if (timeSinceWreckage > 30000 && XORRandom(Maths::Max(108000 - timeSinceWreckage, 0)) == 0) // Ancient capsule
        {
            tcpr("[RGE] Random event: Capsule");
            server_CreateBlob("ancientcapsule", -1, Vec2f(XORRandom(map.tilemapwidth) * map.tilesize, 0.0f));
			
			this.set_u32("lastCapsule", time);
    	}
		*/
/*		
		if (getGameTime() == this.get_u32("random") && !this.get_bool("timetonukego") || this.get_bool("activated") && !this.get_bool("timetonukego"))
		{
			this.set_bool("activated", false);

			this.set_u32("nuketimer", XORRandom(30)+15);
			this.set_u32("timetonuke", 45);
			this.set_bool("timetonukego", true);
			tcpr("[RGE] Random event: Atomic bombardment");
			printf("activated");
			printf("" + this.get_u32("nuketimer"));
			this.set_u32("lastnuke", time);
			CBitStream params;
			this.SendCommand(getRules().getCommandID("nukevent"), params);
		}
*/
		this.set_bool("activated", false);

		if (this.get_bool("timetonukego"))
		{
			if (this.get_u32("timetonuke") > 0) 
			{
				this.set_u32("timetonuke", this.get_u32("timetonuke") - 1);
				printf("" + this.get_u32("timetonuke"));
			}
			if (this.get_u32("timetonuke") == 0)
			{
				printf("started");
				this.set_bool("stillnuking?", true);
				this.set_bool("timetonukego", false);
			}
		}
/*
		if (this.get_u32("timetonuke") < 1)
		{
			if (this.get_u32("nuketimer") > 0) this.set_u32("nuketimer", this.get_u32("nuketimer") - 1);
			//printf("" + this.get_u32("nuketimer"));
		}
		int randomnukecd = XORRandom(99) + 1;

		if (randomnukecd > 33 && this.get_bool("stillnuking?"))
		{
			printf("createdanuke");
			server_CreateBlob("mininuke", -1, Vec2f(XORRandom(map.tilemapwidth) * map.tilesize, 0.0f));
		}
		if (this.get_u32("nuketimer") == 0)
		{
			//printf("stopped");
			this.set_bool("stillnuking?", false);
		}
*/
		//else if (this.get_u32("nightevent") != 0 && getGameTime() < 120) this.daycycle_speed = 20;

		if ((this.get_u32("nightevent") == 1 || this.get_bool("alwaysnight")) && !this.get_bool("raining") && XORRandom(1000) == 0)
		{
			this.set_bool("raining", true);
			if (isServer()) server_CreateBlob("blizzard", -1, Vec2f(0,0));
		}

		if ((this.get_bool("nightcall") && getGameTime() > 20 && getGameTime() <= 30)
		|| (this.get_bool("alwaysnight") && getGameTime() == this.get_u32("alwaysnighttimeactivated")))
		{
			CBitStream params;
			this.SendCommand(getRules().getCommandID("nightevent"), params);
			this.set_bool("nightcall", false);
		}
    }
	if ((this.get_u32("nightevent") == 1 || this.get_bool("alwaysnight")) && !this.get_bool("cancelnight")) 
	{
		if (getGameTime() % 30 == 0) getMap().SetDayTime(0.01);
		if (getGameTime() % 29 == 0) getMap().SetDayTime(1.0);
		this.set_bool("nightcall", true);
		this.set_bool("alwaysnight", true);
		//print("" + getMap().getDayTime());
		//print("" + this.get_bool("alwaysnight") + " " + this.get_u32("nightevent") + " " + getMap().getDayTime());
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (cmd==this.getCommandID("callputin"))
	{
		this.set_bool("activated", true);
	}
	else if (cmd==this.getCommandID("alwaysnightevent"))
	{
		printf("called");
		this.set_bool("cancelnight", false);
		this.set_u32("alwaysnighttimeactivated", getGameTime() + 1);
		this.set_bool("alwaysnight", true);
	}
	else if (cmd==this.getCommandID("alwaysnighteventcancel"))
	{
		printf("canceled");
		getMap().SetDayTime(0.2);
		this.set_bool("cancelnight", true);
		
		this.set_bool("alwaysnight", false);
		this.set_u32("nightevent", 0);
	}
}