#include "CustomBlocks.as";

void onInit(CBlob@ this)
{
    this.addCommandID("sync_command");
    this.addCommandID("set_dest");
    this.addCommandID("sync_state");
    this.addCommandID("add_materials");
    this.addCommandID("construct");
    this.addCommandID("create_rocket");
    this.addCommandID("set_max_time");

    this.set_TileType("background tile", CMap::tile_biron);

    //CMap@ map = this.getMap();
    //if (map !is null && isServer())
    //{   
    //    for (u8 i = 0; i < 11; i++)
    //    {
    //        for (u8 j = 0; j < 3; j++)
    //        {
    //            map.server_SetTile(this.getPosition()+Vec2f(-8, i*8), CMap::tile_biron);
    //        }
    //    }
    //}

    this.inventoryButtonPos = Vec2f(-24, 86);

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
    this.SetLightRadius(164.0f);
    this.SetLight(true);

    this.set_string("module1", "");
    this.set_string("module2", "");
    this.set_string("module3", "");
    this.set_string("module4", "");

    this.set_u32("max_time", 0);
    this.set_u8("screenframe", 0);

    AddIconToken("$icon_construct$", "InteractionIcons.png", Vec2f(32, 32), 15);
}

void onInit(CSprite@ this)
{
    this.SetRelativeZ(-15);

    CSpriteLayer@ scr = this.addSpriteLayer("screen", "RocketStateScreens.png", 13, 11);
	if (scr !is null)
	{
        Animation@ state = scr.addAnimation("state", 0, false);
        for (u8 i = 0; i < 30; i++)
        {
            state.AddFrame(i);
        }
        scr.SetRelativeZ(-8);
        scr.SetOffset(Vec2f(-36.5f, 80.5f));
        scr.SetVisible(false);
        scr.SetAnimation("state");
    }

    CSpriteLayer@ locator = this.addSpriteLayer("locator", "RocketsLocator.png", 32, 24);
	if (locator !is null)
	{
		Animation@ anim = locator.addAnimation("spin", 10, true);
		for (int i = 0; i < 4; i++)
		{
			anim.AddFrame(i);
		}
		
		locator.SetVisible(true);
		locator.SetOffset(Vec2f(-28, 84));
		locator.SetRelativeZ(-10);
        if (isServer() && this.getBlob() !is null)
        {
            CBlob@ blob = server_CreateBlob("scanner_ghost");
            blob.setPosition(this.getBlob().getPosition()+Vec2f(34, 80));
            this.getBlob().set_netid("scanner", blob.getNetworkID());
        }
	}
    Animation@ ranim = this.addAnimation("building", 0, false);
    int[] frames = {0,1,2,3,4,5,6,7,8,9,10,11};
    ranim.AddFrames(frames);
    this.SetAnimation("building");

    this.SetEmitSound("Mystical_EnergySwordHumLoop5.ogg");
    this.SetEmitSoundVolume(1.0f);
    this.SetEmitSoundSpeed(0.25f);
    this.SetEmitSoundPaused(true);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBitStream params;
	params.write_u16(caller.getNetworkID());

	if (this.get_u8("frameindex") >= 11)
	{
		CButton@ button = caller.CreateGenericButton(17, Vec2f(8, 43), this, this.getCommandID("create_rocket"), "Finish", params);
	}
}

const string[] reqtrusters = { //0-1
    "mat_steelingot",
    "mat_copperingot",
    "mat_fuel",
    "mat_copperwire",
    "lighter",
    "mat_carbon",
    "mat_titaniumingot",
    "bp_energetics"
};

const string[] reqengines = { //2-3
    "mat_ironingot",
    "mat_steelingot",
    "mat_copperingot",
    "mat_oil",
    "mat_copperwire",
    "mat_carbon",
    "mat_titaniumingot",
    "catalyzer",
    "bp_energetics"
};

const string[] reqhull = { //4
    "mat_ironingot",
    "mat_steelingot",
    "mat_carbon",
    "mat_titaniumingot",
    "mat_concrete",
    "wrench"
};

const string[] reqcompunit = { //5
    "mat_ironingot",
    "mat_steelingot",
    "mat_copperwire",
    "mat_carbon",
    "mat_titaniumingot",
    "bp_automation_advanced"
};

const string[] reqmodule = { //6-10
    "mat_ironingot",
    "mat_steelingot",
    "mat_carbon",
    "mat_titaniumingot",
    "mat_mithrilingot",
    "mat_copperingot"
};

const string[] reqhead = { //11
    "mat_ironingot",
    "mat_steelingot",
    "mat_carbon",
    "mat_titaniumingot",
    "mat_mithrilingot",
    "mat_goldingot"
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
    //this.set_string("module4", "fueltank");
    //this.set_string("module2", "drillstation");
    //this.set_string("module3", "detailedscanner");
    //this.set_string("module1", "weaponpack");
    //if (getGameTime()%90==0)
    //{
    //    printf("m1 "+this.get_string("module1"));
    //    printf("m2 "+this.get_string("module2"));
    //    printf("m3 "+this.get_string("module3"));
    //    printf("m4 "+this.get_string("module4"));
    //}
    // setup locator anim
    CSprite@ sprite = this.getSprite();
    {
        if (sprite !is null)
        {
            CSpriteLayer@ screen = sprite.getSpriteLayer("screen");
            if (screen !is null)
            {
                if (this.get_u32("time_to_arrival") < 30) screen.SetVisible(false);
            }
            if (getGameTime()%90==0 && this.get_u8("frameindex") >= 2) sprite.SetEmitSoundPaused(false);
            CSpriteLayer@ locator = sprite.getSpriteLayer("locator");
            if (getGameTime()%5==0 && locator !is null)
            {
                locator.SetAnimation("spin");
            }
            sprite.SetFrameIndex(this.get_u8("frameindex"));

            CSpriteLayer@ module1 = sprite.getSpriteLayer("module1");
            if (module1 is null)
            {
                CSpriteLayer@ module1 = sprite.addSpriteLayer("module1", "modules.png", 19, 12);
                module1.SetOffset(Vec2f(3.5, -20));
                Animation@ manim = sprite.addAnimation("modules", 0, false);
                int[] frames = {0,1,2,3};
                manim.AddFrames(frames);
                module1.SetAnimation("modules");
                module1.SetVisible(false);
            }
            else if (this.get_u8("frameindex") >= 7 && this.get_u8("frameindex") < 12 && this.get_u16("rocketid") == 0 && this.get_u16("ETA") == 0)
            {
                module1.SetVisible(true);
                if (this.get_string("module1") == "drillstation")
                    module1.SetFrameIndex(0);
                else if (this.get_string("module1") == "fueltank")
                    module1.SetFrameIndex(2);
                else if (this.get_string("module1") == "detailedscanner")
                    module1.SetFrameIndex(1);
                else if (this.get_string("module1") == "weaponpack")
                    module1.SetFrameIndex(3);
                else module1.SetVisible(false);
            }
            else module1.SetVisible(false);

            CSpriteLayer@ module2 = sprite.getSpriteLayer("module2");
            if (module2 is null)
            {
                CSpriteLayer@ module2 = sprite.addSpriteLayer("module2", "modules.png", 19, 12);
                module2.SetOffset(Vec2f(3.5, -35));
                Animation@ manim = sprite.addAnimation("modules", 0, false);
                int[] frames = {0,1,2,3};
                manim.AddFrames(frames);
                module2.SetAnimation("modules");
                module2.SetVisible(false);
            }
            else if (this.get_u8("frameindex") >= 8 && this.get_u8("frameindex") < 12 && this.get_u16("rocketid") == 0 && this.get_u16("ETA") == 0)
            {
                module2.SetVisible(true);
                if (this.get_string("module2") == "drillstation")
                    module2.SetFrameIndex(0);
                else if (this.get_string("module2") == "fueltank")
                    module2.SetFrameIndex(2);
                else if (this.get_string("module2") == "detailedscanner")
                    module2.SetFrameIndex(1);
                else if (this.get_string("module2") == "weaponpack")
                    module2.SetFrameIndex(3);
                else module2.SetVisible(false);
            }
            else module2.SetVisible(false);

            CSpriteLayer@ module3 = sprite.getSpriteLayer("module3");
            if (module3 is null)
            {
                CSpriteLayer@ module3 = sprite.addSpriteLayer("module3", "modules.png", 19, 12);
                module3.SetOffset(Vec2f(3.5, -50));
                Animation@ manim = sprite.addAnimation("modules", 0, false);
                int[] frames = {0,1,2,3};
                manim.AddFrames(frames);
                module3.SetAnimation("modules");
                module3.SetVisible(false);
            }
            else if (this.get_u8("frameindex") >= 9 && this.get_u8("frameindex") < 12 && this.get_u16("rocketid") == 0 && this.get_u16("ETA") == 0)
            {
                module3.SetVisible(true);
                if (this.get_string("module3") == "drillstation")
                    module3.SetFrameIndex(0);
                else if (this.get_string("module3") == "fueltank")
                    module3.SetFrameIndex(2);
                else if (this.get_string("module3") == "detailedscanner")
                    module3.SetFrameIndex(1);
                else if (this.get_string("module3") == "weaponpack")
                    module3.SetFrameIndex(3);
                else module3.SetVisible(false);
            }
            else module3.SetVisible(false);

            CSpriteLayer@ module4 = sprite.getSpriteLayer("module4");
            if (module4 is null)
            {
                CSpriteLayer@ module4 = sprite.addSpriteLayer("module4", "modules.png", 19, 12);
                module4.SetOffset(Vec2f(3.5, -65));
                Animation@ manim = sprite.addAnimation("modules", 0, false);
                int[] frames = {0,1,2,3};
                manim.AddFrames(frames);
                module4.SetAnimation("modules");
                module4.SetVisible(false);
            }
            else if (this.get_u8("frameindex") >= 10 && this.get_u8("frameindex") < 12 && this.get_u16("rocketid") == 0 && this.get_u16("ETA") == 0)
            {
                module4.SetVisible(true);
                if (this.get_string("module4") == "drillstation")
                    module4.SetFrameIndex(0);
                else if (this.get_string("module4") == "fueltank")
                    module4.SetFrameIndex(2);
                else if (this.get_string("module4") == "detailedscanner")
                    module4.SetFrameIndex(1);
                else if (this.get_string("module4") == "weaponpack")
                    module4.SetFrameIndex(3);
                else module4.SetVisible(false);
            }
            else module4.SetVisible(false);
        }
    }
    if (this.get_u8("frameindex") == 11) this.setInventoryName("Ready");
    if (this.hasTag("unsuccess"))
    {
        this.Untag("unsuccess");
        printf(""+this.hasTag("unsuccess"));
    }
    // rocket is in space, handle logic
    bool hasrocket = false;
    CBlob@ r = getBlobByNetworkID(this.get_u16("rocketid"));
        if (this.get_u16("rocketid") != 0 && r !is null && r.getName() == "spacerocket") hasrocket = true;
    if (hasrocket || this.get_u32("time_to_arrival") > 0)
    {
        CSprite@ sprite = this.getSprite();
        
        if (sprite !is null)
        {
            CSpriteLayer@ screen = sprite.getSpriteLayer("screen");
            if (screen !is null)
            {
                u32 ts = this.get_u32("time_to_arrival");
                u32 max = this.get_u32("max_time");
                if (max > 0 && !hasrocket) //&& !hasrocket?
                {
                    screen.SetVisible(true);
                    if (ts >= max-100*30)
                    { // atmosphere out
                        if (getGameTime()%10==0)
                            this.add_u8("screenframe", 1);

                        u8 frame = this.get_u8("screenframe");
                        if (frame == 3) frame = 1;

                        u8[] frames = {0,1,2};
                        if (frame == 4)
                        {
                            frame = 0;
                            this.set_u8("screenframe", 0);
                        }

                        screen.SetFrameIndex(frames[frame]);
                    }
                    else if (ts < max-100*30 && ts >= max-160*30)
                    { // space idle
                        if (getGameTime()%10==0)
                            this.add_u8("screenframe", 1);

                        u8 frame = this.get_u8("screenframe");
                        if (frame == 3) frame = 1;

                        u8[] frames = {3,4,5};
                        if (frame == 4)
                        {
                            frame = 0;
                            this.set_u8("screenframe", 0);
                        }

                        screen.SetFrameIndex(frames[frame]);
                    }
                    else if (this.get_string("destination") == "asteroid" && ts < max-160*30 && ts >= max-163*30)
                    { // asteroid in
                        u8[] frames = {12,11,10,9,8,8};

                        if (ts == max-160*30-10)
                            screen.SetFrameIndex(frames[0]);
                        if (ts == max-160*30-20)
                            screen.SetFrameIndex(frames[1]);
                        if (ts == max-160*30-30)
                            screen.SetFrameIndex(frames[2]);
                        if (ts == max-160*30-40)
                            screen.SetFrameIndex(frames[3]);
                        if (ts == max-160*30-50)
                            screen.SetFrameIndex(frames[4]);
                        if (ts == max-160*30-60)
                            screen.SetFrameIndex(frames[5]);
                    }
                    else if (this.get_string("destination") == "asteroid" && ts < max-163*30 && ts >= 120*30)
                    { // asteroid idle
                        if (getGameTime()%10==0)
                            this.add_u8("screenframe", 1);

                        u8 frame = this.get_u8("screenframe");

                        u8[] frames = {8,7,6};
                        if (frame >= 3)
                        {
                            frame = 0;
                            this.set_u8("screenframe", 0);
                        }

                        screen.SetFrameIndex(frames[frame]);
                    }
                    else if (this.get_string("destination") == "asteroid" && ts < 120*30 && ts >= 117*30)
                    { // asteroid out
                        u8[] frames = {12,11,10,9,8,6};

                        if (ts == max-120*30-10)
                            screen.SetFrameIndex(frames[4]);
                        if (ts ==  max-120*30-20)
                            screen.SetFrameIndex(frames[3]);
                        if (ts ==  max-120*30-30)
                            screen.SetFrameIndex(frames[2]);
                        if (ts == max-120*30-40)
                            screen.SetFrameIndex(frames[1]);
                        if (ts == max-120*30-50)
                            screen.SetFrameIndex(frames[0]);
                        if (ts == max-120*30-60)
                            screen.SetFrameIndex(frames[5]);
                    }
                    else if (this.get_string("destination") == "moon" && ts < max-160*30 && ts >= max-164*30)
                    { // moon in
                        u8[] frames = {13,14,15,16};

                        if (ts == max-160*30-8)
                            screen.SetFrameIndex(frames[0]);
                        if (ts == max-160*30-16)
                            screen.SetFrameIndex(frames[1]);
                        if (ts == max-160*30-24)
                            screen.SetFrameIndex(frames[2]);
                        if (ts == max-160*30-36)
                            screen.SetFrameIndex(frames[3]);
                    }
                    else if (this.get_string("destination") == "moon" && ts < max-164*30 && ts >= 120*30)
                    { // moon idle
                        screen.SetFrameIndex(16);
                    }
                    else if (this.get_string("destination") == "moon" && ts < 120*30 && ts >= 117*30)
                    { // moon out
                        u8[] frames = {18,19,20};

                        if (ts == 120-12)
                            screen.SetFrameIndex(frames[0]);
                        if (ts ==  120*30-24)
                            screen.SetFrameIndex(frames[1]);
                        if (ts ==  120*30-36)
                            screen.SetFrameIndex(frames[2]);
                    }
                    else if (this.get_string("destination") == "exoplanet" && ts < max-160*30 && ts >= max-164*30)
                    { // exoplanet in
                        u8[] frames = {26,22,23,21};

                        if (ts == max-160*30-8)
                            screen.SetFrameIndex(frames[0]);
                        if (ts == max-160*30-16)
                            screen.SetFrameIndex(frames[1]);
                        if (ts == max-160*30-24)
                            screen.SetFrameIndex(frames[2]);
                        if (ts == max-160*30-32)
                            screen.SetFrameIndex(frames[3]);
                    }
                    else if (this.get_string("destination") == "exoplanet" && ts < max-164*30 && ts >= 120*30)
                    { // exoplanet idle
                        if (getGameTime()%10==0)
                            this.add_u8("screenframe", 1);

                        u8 frame = this.get_u8("screenframe");

                        u8[] frames = {21,24};
                        if (frame >= 2)
                        {
                            frame = 0;
                            this.set_u8("screenframe", 0);
                        }

                        screen.SetFrameIndex(frames[frame]);
                    }
                    else if (this.get_string("destination") == "exoplanet" && ts < 120*30 && ts >= 117*30)
                    { // exoplanet out
                        u8[] frames = {23,22,26,21};

                        if (ts == 120-8)
                            screen.SetFrameIndex(frames[0]);
                        if (ts ==  120*30-16)
                            screen.SetFrameIndex(frames[1]);
                        if (ts ==  120*30-24)
                            screen.SetFrameIndex(frames[2]);
                        if (ts ==  120*30-32)
                            screen.SetFrameIndex(frames[3]);
                    }
                    else if (ts < 117*30 && ts >= 60*30)
                    { // space idle
                        if (getGameTime()%10==0)
                            this.add_u8("screenframe", 1);

                        u8 frame = this.get_u8("screenframe");
                        if (frame == 3) frame = 1;

                        u8[] frames = {3,4,5};
                        if (frame == 4)
                        {
                            frame = 0;
                            this.set_u8("screenframe", 0);
                        }

                        screen.SetFrameIndex(frames[frame]);
                    }
                    else if (ts < 60*30 && ts > 30)
                    { // atmosphere in
                        if (getGameTime()%10==0)
                            this.add_u8("screenframe", 1);

                        u8 frame = this.get_u8("screenframe");

                        u8[] frames = {27,28,29};
                        if (frame == 3)
                        {
                            frame = 0;
                            this.set_u8("screenframe", 0);
                        }

                        screen.SetFrameIndex(frames[frame]);
                    }
                }
                else screen.SetVisible(false);
            }
        }

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
            string m1 = this.get_string("module1");
            string m2 = this.get_string("module2");
            string m3 = this.get_string("module3");
            string m4 = this.get_string("module4");

            if (isServer())
            {
                CBlob@ crate = server_CreateBlobNoInit("steelcrate");
                crate.server_setTeamNum(this.getTeamNum());
                crate.setPosition(Vec2f(this.getPosition().x + XORRandom(1080.0f)-512.0f, 0));

                crate.set_string("m1", m1);
                crate.set_string("m2", m2);
                crate.set_string("m3", m3);
                crate.set_string("m4", m4);

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

    //update level
    //if (this.get_u32("elec") <= 5000) return; 
    u8 frameindex = this.get_u8("frameindex");
    string[] matNames;

    if (frameindex <= 1)
    {
        matNames = reqtrusters;
    }
    else if (frameindex >= 2 && frameindex <= 3)
    {
        matNames = reqengines;
    }
    else if (frameindex == 4)
    {
        matNames = reqhull;
    }
    else if (frameindex == 5)
    {
        matNames = reqcompunit;
    }
    else if (frameindex >= 6 && frameindex <= 9)
    {
        matNames = reqmodule;
    }
    else
    {
        matNames = reqhead;
    }
    if (this.hasTag("update"))
    {
        if (isServer())
        {
            if (frameindex <= 1)
            {
                //set requirements here
                this.set_u16("mat_steelingot", 50);
                this.set_u16("mat_copperingot", 50);
                this.set_u16("mat_fuel", 100);
                this.set_u16("mat_copperwire", 50);
                this.set_u16("mat_carbon", 100);
                this.set_u16("mat_titaniumingot", 75);
                this.set_u16("lighter", 1);
                this.set_u16("bp_energetics", 1);
            }
            else if (frameindex >= 2 && frameindex <= 3)
            {
                if (this.getSprite() !is null) this.getSprite().SetEmitSoundPaused(false);
                this.set_u16("mat_ironingot", 100);
                this.set_u16("mat_steelingot", 50);
                this.set_u16("mat_copperingot", 150);
                this.set_u16("mat_oil", 300);
                this.set_u16("mat_copperwire", 150);
                this.set_u16("mat_carbon", 150);
                this.set_u16("mat_titaniumingot", 50);
                this.set_u16("catalyzer", 1);
            }
            else if (frameindex == 4)
            {
                this.set_u16("mat_ironingot", 200);
                this.set_u16("mat_steelingot", 100);
                this.set_u16("mat_carbon", 350);
                this.set_u16("mat_titaniumingot", 200);
                this.set_u16("mat_concrete", 3000);
                this.set_u16("wrench", 2);
            }
            else if (frameindex == 5)
            {
                this.set_u16("mat_ironingot", 200);
                this.set_u16("mat_steelingot", 75);
                this.set_u16("mat_copperwire", 300);
                this.set_u16("mat_carbon", 250);
                this.set_u16("mat_titaniumingot", 100);
                this.set_u16("bp_automation_advanced", 1);
            }
            else if (frameindex >= 6 && frameindex <= 9)
            {
                this.set_u16("mat_ironingot", 50);
                this.set_u16("mat_steelingot", 30);
                this.set_u16("mat_copperingot", 30);
                this.set_u16("mat_mithrilingot", 15);
                this.set_u16("mat_carbon", 100);
                this.set_u16("mat_titaniumingot", 30);
            }
            else if (frameindex == 10)
            {
                this.set_u16("mat_ironingot", 100);
                this.set_u16("mat_steelingot", 75);
                this.set_u16("mat_mithrilingot", 50);
                this.set_u16("mat_goldingot", 75);
                this.set_u16("mat_carbon", 250);
                this.set_u16("mat_titaniumingot", 100);
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

    if (frameindex <= 1)
    {
        matsneeded = "Materials left:\nSteel ingots - "+this.get_u16("mat_steelingot")+"\nCopper ingots - "+this.get_u16("mat_copperingot")+"\nFuel - "+this.get_u16("mat_fuel")+"\nCopper wires - "+this.get_u16("mat_copperwire")+"\nCarbon - "+this.get_u16("mat_carbon")+"\nTitanium ingots - "+this.get_u16("mat_titaniumingot")+"\nLighters - "+this.get_u16("lighter")+"\nBlueprint (Energetics) - "+this.get_u16("bp_energetics");
    }
    else if (frameindex >= 2 && frameindex <= 3)
    {
        matsneeded = "Materials left:\nIron ingots - "+this.get_u16("mat_ironingot")+"\nSteel ingots - "+this.get_u16("mat_steelingot")+"\nCopper ingots - "+this.get_u16("mat_copperingot")+"\nOil - "+this.get_u16("mat_oil")+"\nCopper wires - "+this.get_u16("mat_copperwire")+"\nCarbon - "+this.get_u16("mat_carbon")+"\nTitanium ingots - "+this.get_u16("mat_titaniumingot")+"\nCatalyzers - "+this.get_u16("catalyzer")+"\nBlueprint (Energetics) - "+this.get_u16("bp_energetics");
    }
    else if (frameindex == 4)
    {
        matsneeded = "Materials left:\nIron ingots - "+this.get_u16("mat_ironingot")+"\nSteel ingots - "+this.get_u16("mat_steelingot")+"\nCarbon - "+this.get_u16("mat_carbon")+"\nTitanium ingots - "+this.get_u16("mat_titaniumingot")+"\nConcrete - "+this.get_u16("mat_concrete")+"\nWrenchs - "+this.get_u16("wrench");
    }
    else if (frameindex == 5)
    {
        matsneeded = "Materials left:\nIron ingots - "+this.get_u16("mat_ironingot")+"\nSteel ingots - "+this.get_u16("mat_steelingot")+"\nCopper ingots - "+this.get_u16("mat_copperingot")+"\nCopper wires - "+this.get_u16("mat_copperwire")+"\nCarbon - "+this.get_u16("mat_carbon")+"\nTitanium ingots - "+this.get_u16("mat_titaniumingot")+"\nBlueprint (Advanced Automation) - "+this.get_u16("bp_automation_advanced");
    }
    else if (frameindex >= 6 && frameindex <= 9)
    {
        matsneeded = "Materials left:\nIron ingots - "+this.get_u16("mat_ironingot")+"\nSteel ingots - "+this.get_u16("mat_steelingot")+"\nCopper ingots - "+this.get_u16("mat_copperingot")+"\nCarbon - "+this.get_u16("mat_carbon")+"\nTitanium ingots - "+this.get_u16("mat_titaniumingot")+"\nMithril ingots - "+this.get_u16("mat_mithrilingot");
    }
    else if (frameindex == 10)
    {
        matsneeded = "Materials left:\nIron ingots - "+this.get_u16("mat_ironingot")+"\nSteel ingots - "+this.get_u16("mat_steelingot")+"\nGold ingots - "+this.get_u16("mat_goldingot")+"\nCarbon - "+this.get_u16("mat_carbon")+"\nTitanium ingots - "+this.get_u16("mat_titaniumingot")+"\nMithril ingots - "+this.get_u16("mat_mithrilingot");
    }
    else matsneeded = "Ready!";

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

                    if (count <= quantity)
                    {
                        if (isServer())
                        {
                            item.server_SetQuantity(quantity-count);
                            if (item.getQuantity() <= 0) item.server_Die();
                        }
                        this.set_u16(invname, 0);
                    }
                    else
                    {
                        this.set_u16(invname, count - quantity);
                        item.Tag("dead");
                        if (isServer()) item.server_Die();
                    }
                    if (isServer() && quantity == 0) item.server_Die();

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
        if (upgrade && this.get_u8("frameindex") < 12)
        {
            if (this.get_u8("frameindex") >= 6 && this.get_u8("frameindex") <= 9) // -1 because before upgrade
            {
                CInventory@ inv = this.getInventory();
                if (inv !is null)
                {
                    u8 powerdrill = 0;
                    u8 mat_fuel = 0;
                    u8 phone = 0;
                    u8 uzi = 0;

                    for (u8 i = 0; i < inv.getItemsCount(); i++)
                    {
                        CBlob@ blob = inv.getItem(i);
                        if (blob !is null)
                        {
                            if (blob.getName() == "powerdrill") powerdrill++;
                            if (blob.getName() == "mat_fuel")
                            {
                                mat_fuel++;
                            }
                            if (blob.getName() == "phone")
                            {
                                phone++;
                                //printf(""+phone);
                            }
                            if (blob.getName() == "uzi") uzi++;
                        }
                    }

                    if (powerdrill >= 8)
                    {
                        this.set_string("module"+(this.get_u8("frameindex")-5), "drillstation");
                        u8 counter = 0;

                        for (u8 i = 0; i < inv.getItemsCount(); i++)
                        {
                            CBlob@ blob = inv.getItem(i);
                            if (blob !is null && blob.getName() == "powerdrill" && counter < 8)
                            {
                                counter++;
                                blob.Tag("dead");
                                blob.server_Die();
                            }
                        }
                        this.Sync("module"+(this.get_u8("frameindex")-5), true);
                    }
                    else if (mat_fuel >= 15 && !this.hasTag("has_fuel_tank"))
                    {
                        this.set_string("module"+(this.get_u8("frameindex")-5), "fueltank");
                        u8 counter = 0;

                        for (u8 i = 0; i < inv.getItemsCount(); i++)
                        {
                            CBlob@ blob = inv.getItem(i);
                            
                            if (blob !is null && blob.getName() == "mat_fuel" && counter < 15)
                            {
                                counter++;
                                blob.Tag("dead");
                                blob.server_Die();
                            }
                        }
                        this.Tag("has_fuel_tank");
                        this.Sync("module"+(this.get_u8("frameindex")-5), true);
                    }
                    else if (phone >= 1)
                    {
                        this.set_string("module"+(this.get_u8("frameindex")-5), "detailedscanner");
                        u8 counter = 0;

                        for (u8 i = 0; i < inv.getItemsCount(); i++)
                        {
                            CBlob@ blob = inv.getItem(i);

                            if (blob !is null && blob.getName() == "phone" && counter < 1)
                            {
                                counter++;
                                blob.Tag("dead");
                                blob.server_Die();
                            }
                        }
                        this.Sync("module"+(this.get_u8("frameindex")-5), true);
                    }
                    else if (uzi >= 4)
                    {
                        this.set_string("module"+(this.get_u8("frameindex")-5), "weaponpack");
                        u8 counter = 0;

                        for (u8 i = 0; i < inv.getItemsCount(); i++)
                        {
                            CBlob@ blob = inv.getItem(i);
                            
                            if (blob !is null && blob.getName() == "uzi" && counter < 4)
                            {
                                counter++;
                                blob.Tag("dead");
                                blob.server_Die();
                            }
                        } 
                        this.Sync("module"+(this.get_u8("frameindex")-5), true);
                    }
                }
            }

            this.add_u8("frameindex", 1);
            this.Sync("frameindex", true);
            this.Tag("update");
            //this.add_u32("elec", -5000);
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

        if (frameindex <= 1)                                   matNames = reqtrusters;
        else if (frameindex >= 2 && frameindex <= 3)           matNames = reqengines;
        else if (frameindex == 4)                              matNames = reqhull;
        else if (frameindex == 5)                              matNames = reqcompunit;
        else if (frameindex >= 6 && frameindex <= 9)           matNames = reqmodule;
        else                                                   matNames = reqhead;

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
        for (u8 i = 1; i < 5; i++)
        {
            params.write_string(this.get_string("module"+i));
        }
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
            string module1, module2, module3, module4;

            if (!params.saferead_u8(frameindex)) return;
            if (!params.saferead_u32(timeto)) return;
            if (!params.saferead_string(module1)) return;
            if (!params.saferead_string(module2)) return;
            if (!params.saferead_string(module3)) return;
            if (!params.saferead_string(module4)) return;

            this.set_u8("frameindex", frameindex);
            this.set_u32("time_to_arrival", timeto);
            this.set_string("module1", module1);
            this.set_string("module2", module1);
            this.set_string("module3", module1);
            this.set_string("module4", module1);
        }
    }
    else if (cmd == this.getCommandID("create_rocket"))
    {
        if (this.hasTag("made")) return;
        if (isServer())
        {
            CBlob@ blob = server_CreateBlob("spacerocket", this.getTeamNum(), this.getPosition());
            blob.set_u16("motherlaunchpadid", this.getNetworkID());
            blob.Sync("motherlaunchpadid", true);
            this.set_u16("rocketid", blob.getNetworkID());
            this.Sync("rocketid", true);
            blob.set_string("module1", this.get_string("module1"));
            blob.Sync("module1", true);
            blob.set_string("module2", this.get_string("module2"));
            blob.Sync("module2", true);
            blob.set_string("module3", this.get_string("module3"));
            blob.Sync("module3", true);
            blob.set_string("module4", this.get_string("module4"));
            blob.Sync("module4", true);
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
    this.set_string("module1", "");
    this.set_string("module2", "");
    this.set_string("module3", "");
    this.set_string("module4", "");
    this.set_u16("ETA", 0);
    this.set_u32("time_to_arrival", 0);
    this.set_u32("max_time", 0);
    this.Tag("update");
}

void onDie(CBlob@ this)
{
    CBlob@ scanner = getBlobByNetworkID(this.get_netid("scanner"));
    if (scanner !is null)
    {
        scanner.server_Die();
    }
}