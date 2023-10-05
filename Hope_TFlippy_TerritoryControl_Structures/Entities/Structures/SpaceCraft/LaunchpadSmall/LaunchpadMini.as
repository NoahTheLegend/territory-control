#include "CustomBlocks.as";
#include "Requirements.as";
#include "ShopCommon.as";
#include "Costs.as";
#include "GenericButtonCommon.as";
#include "ShopCommon.as";

// please dont look at this code i beg you
// will rewrite it eventually
// this was one of my first modding projects

void onInit(CBlob@ this)
{
    this.addCommandID("set_dest");
    this.addCommandID("sync_state");
    this.addCommandID("init_sync_state");
    this.addCommandID("add_materials");
    this.addCommandID("construct");
    this.addCommandID("create_rocket");
    this.addCommandID("set_max_time");
    this.addCommandID("shop made item");
    this.addCommandID("shop menu");
    this.addCommandID("shop buy");

    this.Tag("infinite_radius");
    this.set_u8("frameindex", 0);
    this.set_u32("time_to_arrival", 0);
    if (isClient()) InitSyncState(this);

    // SHOP
	this.set_Vec2f("shop offset", Vec2f(0, 32));
	this.set_Vec2f("shop menu size", Vec2f(2, 2));
	this.set_string("shop description", "Construct module");
	this.set_u8("shop icon", 11);
    this.Tag(SHOP_AUTOCLOSE);

    this.set_TileType("background tile", CMap::tile_biron);

    this.inventoryButtonPos = Vec2f(-24, 86);

    this.Tag("builder always hit");
    this.set_bool("update", true);
    this.Tag("launchpad");

    this.SetLightColor(SColor(255,255,255,255));
    this.SetLightRadius(164.0f);
    this.SetLight(true);

    this.set_u32("max_time", 0);
    this.set_u8("screenframe", 0);

    AddIconToken("$icon_construct$", "InteractionIcons.png", Vec2f(32, 32), 15);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 128.0f) return;
    
    this.set_Vec2f("shop offset", Vec2f(0, 32));

	this.set_bool("shop available", this.get_u8("frameindex") < 3);

	CBitStream params;
	params.write_u16(caller.getNetworkID());

	if (this.get_u8("frameindex") >= 3)
	{
		CButton@ button = caller.CreateGenericButton(17, Vec2f(0, 16), this, this.getCommandID("create_rocket"), "Finish", params);
	}
}

const string[] reqtrusters = { //0
    "mat_ironingot-100",
    "mat_steelingot-50",
    "mat_fuel-100",
    "mat_copperwire-100",
    "mat_carbon-100",
    "mat_titaniumingot-75"
};

const string[] reqhull = { //1
    "mat_ironingot-250",
    "mat_steelingot-100",
    "mat_copperingot-75",
    "mat_carbon-200",
    "mat_titaniumingot-100"
};

const string[] reqhead = { //2
    "mat_ironingot-100",
    "mat_steelingot-100",
    "mat_goldingot-50",
    "mat_copperingot-150",
    "mat_carbon-150"
};

string uppercaseFirstLetter(string &in str)
{
    str[0] = str.toUpper()[0];
    return str;
}

void onTick(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null) return;

    this.SetAnimation("default");
    this.SetFrameIndex(blob.get_u8("frameindex"));
    this.animation.frame = blob.get_u8("frameindex");
}

void onTick(CBlob@ this)
{
    // setup locator anim
    if (this.get_u8("frameindex") == 3) this.setInventoryName("Ready");
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
        this.Tag("hasrocket");
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
            this.setInventoryName("Destination: "+this.get_string("destination")+"\nETA: "+minutes+"m. "+seconds+"s.");
        }

        if (this.get_u32("time_to_arrival") > 1 && this.get_u32("time_to_arrival") <= 120)
        { // spawn crate
            string dest = this.get_string("destination");

            if (isServer())
            {
                CBlob@ crate = server_CreateBlobNoInit("steelcrate");
                crate.server_setTeamNum(this.getTeamNum());
                crate.setPosition(Vec2f(this.getPosition().x + XORRandom(1080.0f)-512.0f, 0));

                crate.Tag("parachute");
                crate.Tag(dest); // some shit mp desync avoiding
                crate.set_string("destination", dest);
                crate.Init();
            }

            onRocketReturn(this);
            this.Untag("unsuccess");
        }

        return;
    }
    else this.Untag("hasrocket");

    //update level
    //if (this.get_u32("elec") <= 5000) return; 
    u8 frameindex = this.get_u8("frameindex");
    string[] matNames;

    if (frameindex == 0)
        matNames = reqtrusters;
    else if (frameindex == 1)
        matNames = reqhull;
    else
        matNames = reqhead;

    string matsneeded;

    if (this.get_bool("update") && frameindex < 3)
    {
        u8 idx = this.get_u8("frameindex")+1;
        string desc = "Construct "+idx+(idx==1?"st":idx==2?"nd":idx==3?"rd":"th")+" module!";
        
        for (u8 i = 0; i < matNames.length; i++)
        {
            string[] spl = matNames[i].split("-");

            string name;
            int cost;
            if (spl.length < 2)
            {
                if (spl.length < 1) continue;
                cost = 1;
            }
            else
            {
                name = spl[0];
                cost = parseInt(spl[1]);
            }

            string pure_name = "";
            string[] spl_name = name.split("_");
            if (spl_name.length == 1)
            {
                pure_name = spl_name[0];
            }
            else
                pure_name = spl_name[1];


            int separator = pure_name.find("ingot");
            if (separator == -1) pure_name.find("wire");
            if (separator != -1)
            {
                pure_name = pure_name.substr(0, separator)+" "+pure_name.substr(separator);
            }

            this.set_Vec2f("shop menu size", Vec2f(2, 2));
		    ShopItem@ s = addShopItem(this, "Module", "$badgerplushie$", "construct", desc, false);
		    AddRequirement(s.requirements, "blob", name, pure_name, cost);
            s.spawnNothing = true;
            s.customButton = true;
            s.buttonwidth = 2;
            s.buttonheight = 2;

            matsneeded = matsneeded + (i!=0?"\n":"") + pure_name+": "+cost;
        }

        this.set_bool("update", false);
    }
    else if (frameindex >= 3)
        matsneeded = "Ready!";

    this.setInventoryName(matsneeded);
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return false;
}

void InitSyncState(CBlob@ this)
{
    this.SendCommand(this.getCommandID("init_sync_state"));
}

void SyncState(CBlob@ this)
{
    if (isServer())
    {
        CBitStream params;
        params.write_u8(this.get_u8("frameindex"));
        params.write_bool(this.get_bool("update"));
        params.write_u32(this.get_u32("time_to_arrival"));
        this.SendCommand(this.getCommandID("sync_state"), params);
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("init_sync_state"))
    {
        if (isServer())
        {
            SyncState(this);
        }
    }
    else if (cmd == this.getCommandID("sync_state"))
	{
        if (isClient())
        {
            u8 frameindex;
            bool update;
            u32 timeto;

            if (!params.saferead_u8(frameindex)) return;
            this.set_u8("frameindex", frameindex);
            if (!params.saferead_bool(update)) return;
            this.set_bool("update", update);
            if (!params.saferead_u32(timeto)) return;
            this.set_u32("time_to_arrival", timeto);
        }
    }
    else if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("/Construct.ogg");

		u16 caller, item;
		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;

		string name = params.read_string();
		CBlob@ callerBlob = getBlobByNetworkID(caller);

		if (callerBlob is null) return;

        if (!isServer()) return;
        if (name == "construct")
        {
            this.set_u8("frameindex", this.get_u8("frameindex")+1);
            this.set_bool("update", true);
            this.Sync("frameindex", true);
            this.Sync("update", true);

            ShopItem[] items;
		    this.set("shop array", items);
        }

        SyncState(this);
	}  
    else if (cmd == this.getCommandID("set_dest"))
    {
        string dest = params.read_string();
        this.set_string("destination", dest);
    }
    else if (cmd == this.getCommandID("set_max_time"))
    {
        u32 t = params.read_u32();
        this.set_u32("max_time", t);
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
    
        this.set_u8("frameindex", 0);
        this.Tag("made");
        this.set_bool("update", true);
    }
}

void onRocketReturn(CBlob@ this)
{
    this.Untag("made");
    this.set_u16("ETA", 0);
    this.set_u32("time_to_arrival", 0);
    this.set_u32("max_time", 0);
    this.set_bool("update", true);
}