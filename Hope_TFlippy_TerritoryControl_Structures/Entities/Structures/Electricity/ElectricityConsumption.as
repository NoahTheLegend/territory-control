// passive taking energy from structures. Variative consumptions on interaction look at blob scripts
const f32 ELECTRICITY_GIVE_RADIUS = 64.0f; // copied from Pole.as;

void onInit(CBlob@ this)
{
    this.Tag("consumes energy");

    string name = this.getName();
    u16 energy_consumption = 0;
    u32 max_energy = 0;
    u8 consume_mod = 1;
    Vec2f wire_offset = Vec2f(0,0);

    if (name == "securitystation") // also taking energy on interacting with cards
    {
        energy_consumption = 5;
        max_energy = 500;
        consume_mod = 2;
        wire_offset = Vec2f(5.5, -9);
    }
    else if (name == "chickenassembler")
    {
        energy_consumption = 10;
        max_energy = 2000;
        consume_mod = 15;
        wire_offset = Vec2f(20, 8);
    }
    else if (name == "ceilinglamp")
    {
        energy_consumption = 1;
        max_energy = 50;
        //wire_offset = Vec2f(0, -4); // rotating allower, looks ugly
    }
    else if (name == "glider")
    {
        energy_consumption = 2;
        max_energy = 50;
    }
    else if (name == "vbarbedwire")
    {
        energy_consumption = 5;
        max_energy = 50;
    }
    else if (name == "drillrig")
    {
        energy_consumption = 50;
        max_energy = 1500;
        consume_mod = 10;
        
        wire_offset = Vec2f(0, -4.5);
    }
    else if (name == "discshop")
    {
        energy_consumption = 5;
        max_energy = 300;
        consume_mod = 3;
        wire_offset = Vec2f(0, 8);
    }
    else if (name == "crusher")
    {
        energy_consumption = 10;
        max_energy = 1000;
        consume_mod = 5;
        wire_offset = Vec2f(0, 12); 
    }
    else if (name == "sam")
    {
        energy_consumption = 20;
        max_energy = 1000;
        consume_mod = 3;
        wire_offset = Vec2f(0, 2);
    }
    else if (name == "sentry")
    {
        energy_consumption = 20;
        max_energy = 1000;
        consume_mod = 5;
        wire_offset = Vec2f(0, 0);
    }
    else if (name == "chemlab")
    {
        energy_consumption = 50;
        max_energy = 3000;
        consume_mod = 15;
        wire_offset = Vec2f(8, 4.5);
    }
    else if (name == "electricfurnace")
    {
        energy_consumption = 25; // multiplied per every item when smelt
        max_energy = 5000;
        consume_mod = 20;
        wire_offset = Vec2f(0, 8);
    }
    else if (name == "launchpadmini")
    {
        max_energy = 3000;
        consume_mod = 15;
        wire_offset = Vec2f(0, 32);
    }
    else if (name == "launchpad")
    {
        max_energy = 6000;
        consume_mod = 15;
        wire_offset = Vec2f(-2, 92);
    }

    this.set_u16("energy_consumption", energy_consumption);
    this.set_u32("elec_max", max_energy);
    this.set_Vec2f("wire_offset", wire_offset);
    this.set_u16("feed_id", 0);
    this.set_bool("state", true);
    this.set_u8("consume_mod", consume_mod);

    this.addCommandID("sync_prep");
	this.addCommandID("sync");

    this.set_u32("elec", 0);
	server_Sync(this);
}

void onTick(CBlob@ this)
{
    bool elec_skip = (this.hasTag("sentry") && this.getTeamNum() >= 7);
    if (!elec_skip && (this.get_u32("elec") > 0 && getGameTime()%30==0))
    {
        if (this.get_u32("elec") > this.get_u32("elec_max")) this.set_u32("elec", this.get_u32("elec_max"));
        //printf(""+this.get_u16('feed_id'));
        CBlob@ feeder = getBlobByNetworkID(this.get_u16("feed_id"));
        if (this.get_u16("feed_id") != 0 && (feeder is null || this.getDistanceTo(feeder) > ELECTRICITY_GIVE_RADIUS))
        {
            this.set_u16("feed_id", 0);
        }

        if (this.exists("state") && this.get_bool("state"))
        {
            if (this.get_u32("elec") <= this.get_u16("energy_consumption"))
            {
                this.set_u32("elec", 0);
            }
            else this.add_u32("elec", -this.get_u16("energy_consumption"));
        }
    }
}

void server_Sync(CBlob@ this)
{
    if (isServer())
    {
        CBitStream params;
        params.write_u32(this.get_u32("elec"));
        this.SendCommand(this.getCommandID("sync"), params);
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("sync"))
	{
		if (isClient())
		{
			u32 elec;
            if (!params.saferead_u32(elec)) return;
			this.set_u32("elec", elec);
		}
	}
}