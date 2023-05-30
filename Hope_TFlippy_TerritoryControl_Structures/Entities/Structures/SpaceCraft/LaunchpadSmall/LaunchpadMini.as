#include "CustomBlocks.as";

void onInit(CBlob@ this)
{
    this.addCommandID("sync_command");
    this.addCommandID("sync_state");
    this.addCommandID("set_dest");
    this.addCommandID("add_materials");
    this.addCommandID("construct");
    this.addCommandID("create_rocket");
    this.addCommandID("set_max_time");

    this.set_TileType("background tile", CMap::tile_biron);

    //CMap@ map = this.getMap();
    //if (map !is null && isServer())
    //{   
    //    for (u8 i = 0; i < 6; i++)
    //    {
    //        for (u8 j = 0; j < 3; j++)
    //        {
    //            map.server_SetTile(this.getPosition()+Vec2f(-8, i*8), CMap::tile_biron);
    //        }
    //    }
    //}

    this.set_string("destination", "asteroid");

    this.inventoryButtonPos = Vec2f(-16, 32);

    this.Tag("builder always hit");
    this.Tag("update");
    this.Tag("launchpad");
    
    if (!this.exists("frameindex"))
    {
        this.set_u8("frameindex", 0);
    }
    else SyncState(this);

    if (!this.exists("time_to_arrival"))
    {
        this.set_u32("time_to_arrival", 0);
    }
    else SyncState(this);

    this.SetLightColor(SColor(255,255,255,255));
    this.SetLightRadius(128.0f);
    this.SetLight(true);

    AddIconToken("$icon_construct$", "InteractionIcons.png", Vec2f(32, 32), 15);
}

void onInit(CSprite@ this)
{
    this.SetRelativeZ(-15);

    Animation@ anim = this.addAnimation("construct", 0, false);
    if (anim !is null)
    {
        int[] frames = {0,1,2,3};
        anim.AddFrames(frames);
        this.SetAnimation(anim);
    }

    this.SetEmitSound("Mystical_EnergySwordHumLoop5.ogg");
    this.SetEmitSoundVolume(1.0f);
    this.SetEmitSoundSpeed(0.35f);
    this.SetEmitSoundPaused(true);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBitStream params;
	params.write_u16(caller.getNetworkID());

	if (this.get_u8("frameindex") == 3)
	{
		CButton@ button = caller.CreateGenericButton(17, Vec2f(0, 16), this, this.getCommandID("create_rocket"), "Finish", params);
	}
} 

const string[] reqtrusters = { //0
    "mat_ironingot",
    "mat_steelingot",
    "mat_fuel",
    "mat_copperwire",
    "mat_carbon",
    "mat_titaniumingot",
    "lighter"
};

const string[] reqhull = { //1
    "mat_ironingot",
    "mat_steelingot",
    "mat_copperingot",
    "mat_copperwire",
    "mat_carbon",
    "mat_titaniumingot"
};

const string[] reqhead = { //2
    "mat_ironingot",
    "mat_goldingot",
    "mat_copperwire",
    "mat_carbon",
    "mat_titaniumingot"
};

void SyncCommand(CBlob@ this, string name, u16 value)
{
    if (isServer())
    {
        CBitStream params;
        params.write_string(name);
        params.write_u16(value);
        this.SendCommand(this.getCommandID("sync_command"), params);
    }
}

void onTick(CBlob@ this)
{
    CSprite@ sprite = this.getSprite();
    {
        if (sprite !is null)
        {
            sprite.SetFrameIndex(this.get_u8("frameindex"));
        }
    }
    if (this.get_u8("frameindex") == 3) this.setInventoryName("Ready!");
    if (this.hasTag("unsuccess"))
    {
        this.Untag("unsuccess");
        printf(""+this.hasTag("unsuccess"));
    }
    // rocket is in space, handle logic
    bool hasrocket = false;
    CBlob@ r = getBlobByNetworkID(this.get_u16("rocketid"));
        if (this.get_u16("rocketid") != 0 && r !is null && r.getName() == "asteroidharvester") hasrocket = true;
    if (hasrocket || this.get_u32("time_to_arrival") > 0)
    {
        if (this.get_u32("time_to_arrival") >= 1) this.set_u32("time_to_arrival", this.get_u32("time_to_arrival") - 1);
            else this.set_u32("time_to_arrival", 0);

        if (getGameTime()%30==0)
        {
            if (this.hasTag("unsuccess"))
            {
                onRocketReturn(this);
                this.Untag("unsuccess");
            }

            this.set_u16("ETA", this.get_u32("time_to_arrival")/30);
            
            u8 minutes = this.get_u16("ETA")/60;
            u8 seconds = this.get_u16("ETA")%60;
            this.setInventoryName("Destination: "+this.get_string("destination")+"\nETA: "+minutes+"m.");
        }

        if (this.get_u32("time_to_arrival") > 1 && this.get_u32("time_to_arrival") <= 120)
        {
            if (isServer())
            {
                CBlob@ crate = server_CreateBlobNoInit("steelcrate");
                crate.server_setTeamNum(this.getTeamNum());
                crate.setPosition(Vec2f(this.getPosition().x + XORRandom(1592.0f)-746.0f, 0));

                crate.Tag("parachute");
                crate.Tag("asteroid"); // some shit mp desync avoiding
                crate.set_string("destination", "asteroid");
                crate.Init();
            }

            onRocketReturn(this);
            this.Untag("unsuccess");
        }

        return;
    }

    //if (this.get_u32("elec") <= 2500) return;
    //update level
    u8 frameindex = this.get_u8("frameindex");
    string[] matNames;
    if (frameindex == 0)
    {
        matNames = reqtrusters;
    }
    else if (frameindex == 1)
    {
        matNames = reqhull;
    }
    else if (frameindex == 2)
    {
        matNames = reqhead;
    }

    if (this.hasTag("update"))
    {
        if (isServer())
        {
            if (frameindex == 0)
            {
                //set requirements here
                this.set_u16("mat_ironingot", 75);
                this.set_u16("mat_steelingot", 20);
                this.set_u16("mat_fuel", 150);
                this.set_u16("mat_copperwire", 150);
                this.set_u16("mat_carbon", 150);
                this.set_u16("mat_titaniumingot", 75);
                this.set_u16("lighter", 2);
            }
            else if (frameindex == 1)
            {
                if (this.getSprite() !is null) this.getSprite().SetEmitSoundPaused(false);
                this.set_u16("mat_ironingot", 200);
                this.set_u16("mat_steelingot", 75);
                this.set_u16("mat_copperingot", 100);
                this.set_u16("mat_copperwire", 150);
                this.set_u16("mat_carbon", 400);
                this.set_u16("mat_titaniumingot", 100);
            }
            else
            {
                this.set_u16("mat_ironingot", 100);
                this.set_u16("mat_goldingot", 50);
                this.set_u16("mat_copperwire", 50);
                this.set_u16("mat_carbon", 200);
                this.set_u16("mat_titaniumingot", 50);
            }

            for (u8 i = 0; i < matNames.length; i++)
            {
                SyncCommand(this, matNames[i], this.get_u16(matNames[i]));
            }
            
            this.Untag("update");
        }
    }
    //if this lags server more, optimize by putting into end of getGameTime()%30==0 condition!
    string matsneeded;

    if (frameindex == 0)
    {
        matsneeded = "Materials left:\nIron ingots - "+this.get_u16("mat_ironingot")+"\nSteel ingots - "+this.get_u16("mat_steelingot")+"\nFuel - "+this.get_u16("mat_fuel")+"\nCopper wires - "+this.get_u16("mat_copperwire")+"\nCarbon - "+this.get_u16("mat_carbon")+"\nTitanium ingots - "+this.get_u16("mat_titaniumingot")+"\nLighters - "+this.get_u16("lighter");
    }
    else if (frameindex == 1)
    {
        matsneeded = "Materials left:\nIron ingots - "+this.get_u16("mat_ironingot")+"\nSteel ingots - "+this.get_u16("mat_steelingot")+"\nCopper ingots - "+this.get_u16("mat_copperingot")+"\nCopper wires - "+this.get_u16("mat_copperwire")+"\nCarbon - "+this.get_u16("mat_carbon")+"\nTitanium ingots - "+this.get_u16("mat_titaniumingot");
    }
    else if (frameindex == 2)
    {
        matsneeded = "Materials left:\nIron ingots - "+this.get_u16("mat_ironingot")+"\nGold ingots - "+this.get_u16("mat_goldingot")+"\nCopper wires - "+this.get_u16("mat_copperwire")+"\nCarbon - "+this.get_u16("mat_carbon")+"\nTitanium ingots - "+this.get_u16("mat_titaniumingot");
    }

    this.setInventoryName(matsneeded);

    if (getGameTime()%30==0 && isServer())
    {
        string matsneeded;

        //update inventory
        CInventory@ inv = this.getInventory();
        if (inv !is null)
        {
            for (u16 i = 0; i < inv.getItemsCount(); i++)
            {
                CBlob@ item = inv.getItem(i);
                if (item is null) continue;
                
                string invname = item.getName();
                u16 quantity = item.getQuantity();
                u16 count = this.get_u16(invname);

                for (u8 i = 0; i < matNames.length; i++)
                {
                    if (invname != matNames[i]) continue;

                    if (count < quantity)
                    {
                        item.server_SetQuantity(quantity-count);
                        this.set_u16(invname, 0);
                    }
                    else
                    {
                        this.set_u16(invname, count - quantity);
                        item.Tag("dead");
                        item.server_Die();
                    }
                    if (quantity == 0) item.server_Die();

                    //printf(invname+" materials left: "+count);
                }
            }
        }

        //check for finishing the goal
        bool upgrade = true;
        for (u8 i = 0; i < matNames.length; i++)
        {
            if (this.get_u16(matNames[i]) > 0)
                upgrade = false;
        }
        if (upgrade && this.get_u8("frameindex") < 3)
        {
            this.add_u8("frameindex", 1);
            this.Sync("frameindex", true);
            this.Tag("update");
            //this.add_u32("elec", -2500);
            //this.Sync("elec", true);
            //printf(""+this.get_u8("frameindex"));
        }

        for (u8 i = 0; i < matNames.length; i++)
        {
            SyncCommand(this, matNames[i], this.get_u16(matNames[i]));
        }
    }
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;
	
	if (!blob.isAttached() && !blob.isInInventory() && blob.hasTag("material"))
	{
		string config = blob.getName();
        string[] matNames;
        u8 frameindex = this.get_u8("frameindex");

        if (frameindex == 0)
        {
            matNames = reqtrusters;
        }
        else if (frameindex == 1)
        {
            matNames = reqhull;
        }
        else if (frameindex == 2)
        {
            matNames = reqhead;
        }

		for (u16 i = 0; i < matNames.length; i++)
		{
			if (config == matNames[i])
			{
				if (isServer()) this.server_PutInInventory(blob);
				if (isClient()) this.getSprite().PlaySound("bridge_open.ogg");
			}
		}
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	// return (forBlob.getTeamNum() == this.getTeamNum() && forBlob.isOverlapping(this));
	return forBlob !is null && this.getDistanceTo(forBlob) < 128.0f;
}

void SyncState(CBlob@ this)
{
    if (isServer())
    {
        CBitStream params;
        params.write_u8(this.get_u8("frameindex"));
        params.write_u16(this.get_u32("time_to_arrival"));
        this.SendCommand(this.getCommandID("sync_state"), params);
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("set_dest"))
    {
        string dest = params.read_string();
        this.set_string("destination", dest);
    }
    else if (cmd == this.getCommandID("set_max_time"))
    {
        u32 t = params.read_u32();
        this.set_u32("max_time", t);
    }
    else if (cmd == this.getCommandID("sync_command"))
	{
        if (isClient())
        {
            string name;
            u16 value;
            if (!params.saferead_string(name)) return;
            if (!params.saferead_u16(value)) return;

            this.set_u16(name, value);
        }
    }
	else if (cmd == this.getCommandID("sync_state"))
	{
        if (isClient())
        {
            u8 frameindex;
            u32 timeto;

            if (!params.saferead_u8(frameindex)) return;
            if (!params.saferead_u32(timeto)) return;

            this.set_u8("frameindex", frameindex);
            this.set_u32("time_to_arrival", timeto);

        }
    }
    else if (cmd == this.getCommandID("create_rocket"))
    {
        if (this.hasTag("made")) return;
        if (isServer())
        {
            CBlob@ blob = server_CreateBlob("asteroidharvester", this.getTeamNum(), this.getPosition());
            blob.set_u16("motherlaunchpadid", this.getNetworkID());
            blob.Sync("motherlaunchpadid", true);
            this.set_u16("rocketid", blob.getNetworkID());
            this.Sync("rocketid", true);
        }
    
        if (this.getSprite() !is null)  this.getSprite().SetEmitSoundPaused(true);
        this.set_u8("frameindex", 0);
        this.Tag("made");
        this.Tag("update");
    }
}

void onRocketReturn(CBlob@ this)
{
    this.Untag("made");
    this.set_u16("ETA", 0);
    this.set_u32("time_to_arrival", 0);
    this.Tag("update");
}