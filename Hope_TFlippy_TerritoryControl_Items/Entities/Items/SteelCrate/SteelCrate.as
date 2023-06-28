// lootcrate for launchpads

void onInit(CBlob@ this)
{
    this.addCommandID("sync_state");
    this.Tag("heavy weight");

    //SyncVars(this);
    this.Tag("extractable");

    this.Tag("parachute");
    if (this.hasTag("asteroid")) this.set_string("destination", "asteroid");
    else if (this.hasTag("moon")) this.set_string("destination", "moon");
    else if (this.hasTag("exoplanet")) this.set_string("destination", "exoplanet");

    CSprite@ sprite = this.getSprite();
    if (sprite !is null)
    {
        CSpriteLayer@ parachute = sprite.addSpriteLayer("parachute", "ParachuteBig.png", 31, 32);
        if (parachute !is null)
        {
            parachute.SetOffset(Vec2f(0,-20));
            parachute.SetRelativeZ(-15.0f);
            parachute.SetVisible(false);
        }
    }

    //printf(this.get_string("m1"));
    //printf(this.get_string("m2"));

    this.set_f32("dts", 0);
    this.set_f32("wps", 0);
}

void onTick(CBlob@ this)
{
    if (this.getTickSinceCreated() == 1)
    {
        string dest = this.get_string("destination");
        //printf("my destination: "+dest);

        MakeInventory(this, dest);
    }
    CSprite@ sprite = this.getSprite();
    if (sprite !is null)
    {
        CSpriteLayer@ parachute = sprite.getSpriteLayer("parachute");
        {
            if (parachute !is null)
            {
                if (this.hasTag("parachute")) parachute.SetVisible(true);
                else parachute.SetVisible(false);
            }
        }
    }

    if (this.hasTag("parachute"))
    {
        if (this.getVelocity().y > 1.0f)
            this.setVelocity(Vec2f(this.getVelocity().x, 1.0f));
    }
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (solid)
        this.Untag("parachute");
}

const string[] enemies = { // name-chance up to 1000
    "heavychicken-450",
    "drone-500",
    "centipede-200", //bugged on server
    "scyther-650",
    "ancientwreckage-450"
};

void ReleaseEnemies(CBlob@ this)
{
    f32 dts = 1+this.get_f32("dts");
    f32 wps = 1+this.get_f32("wps");

    f32 ratioevent = 0.75 * dts;
    f32 ratioprevent = 1.0 - 0.25 * wps;
    f32 ratio = ratioevent * ratioprevent;

    //printf("dts "+dts);
    //printf("wps "+wps);
    //printf("re "+ratioevent);
    //printf("pre "+ratioprevent);

    if (isServer())
    {
        for (u8 i = 0; i < enemies.length; i++)
        {
            string[] spl = enemies[i].split("-");
            if (spl.length == 2)
            {
                string dest = this.get_string("destination");
                string name = spl[0];
                f32 chance = parseFloat(spl[1])*ratio;

                if (dest == "asteroid") 
                {
                    if (name == "ancientwreckage") continue;
                    chance *= 0.05; // less enemies
                }
                else if (dest == "moon" && name != "heavychicken") chance *= 1.25; // robotics
                //add new organic space enemies here

                //printf("name: "+name+" chance: "+chance);

                if (XORRandom(1000) <= chance)
                {
                    server_CreateBlob(name, 222, this.getPosition()+Vec2f(XORRandom(32)-16, XORRandom(32)-16));
                    if (name == "drone")
                    {
                        if (XORRandom(100) <= 80) server_CreateBlob(name, 222, this.getPosition()+Vec2f(XORRandom(32)-16, XORRandom(32)-16));
                        if (XORRandom(100) <= 60) server_CreateBlob(name, 222, this.getPosition()+Vec2f(XORRandom(32)-16, XORRandom(32)-16));
                        if (XORRandom(100) <= 40) server_CreateBlob(name, 222, this.getPosition()+Vec2f(XORRandom(32)-16, XORRandom(32)-16));
                        if (XORRandom(100) <= 20) server_CreateBlob(name, 222, this.getPosition()+Vec2f(XORRandom(32)-16, XORRandom(32)-16));
                    }
                    if (name == "ancientwreckage" && dest == "moon")
                    {
                        CMap@ map = this.getMap();
                        if (map !is null)
                        {
                            u8 rand = XORRandom(10)+1;
                            for (u8 i = 0; i < rand; i++)
                            {
                                if (XORRandom(2) == 1) server_CreateBlob(name, 222, Vec2f(XORRandom(map.tilemapwidth), 0));
                            }
                        }
                    }
                }
            }
        }
    }
}

void MakeInventory(CBlob@ this, string dest)
{
    f32 drs = 0;
    f32 dts = 0;
    f32 wps = 0;

    for (u8 i = 1; i <= 4; i++)
    {
        if (this.exists("m"+i))
        {
            if (this.get_string("m"+i) == "drillstation") drs++;
            else if (this.get_string("m"+i) == "detailedscanner") dts++;
            else if (this.get_string("m"+i) == "weaponpack") wps++;
        }
    }

    this.set_f32("drs", drs);
    this.set_f32("dts", dts);
    this.set_f32("wps", wps);

    //print("drs "+drs);
    //print("dts "+dts);
    //print("wps "+wps);

    if (isServer())
    {
        if (dest == "asteroid")
        {
            for (u8 i = 0; i < 25+this.get_f32("drs")*8+XORRandom(11); i++)
            {
                u8 slot = XORRandom(matAsteroid.length);
                u16 chance;
                for (u8 j = 0; j < rolling.length; j++)
                {
                    string[] s = rolling[j].split("-");
                    string n = s[0]; //name
                    u16 v = parseFloat(s[1]); //value
                    if (matAsteroid[slot]!=n) continue;
                    else
                    {
                        if (XORRandom(2500) <= v) // item passed
                        {
                            CBlob@ blob = server_CreateBlob(n, this.getTeamNum(), this.getPosition());
                            blob.server_SetQuantity(Maths::Floor(valAsteroid[slot] * yieldAsteroid[slot]/1000.0f + XORRandom(valAsteroid[slot])));
                            this.server_PutInInventory(blob);
                        }
                        else
                        {
                            //printf(n);
                            i--;
                        }
                    }
                }
            }
        }
        else if (dest == "moon")
        {
            for (u8 i = 0; i < 30+this.get_f32("drs")*5+XORRandom(16); i++)
            {
                u8 slot = XORRandom(matMoon.length);
                u16 chance;
                for (u8 j = 0; j < rolling.length; j++)
                {
                    string[] s = rolling[j].split("-");
                    string n = s[0]; //name
                    u16 v = parseFloat(s[1]); //value
                    if (matMoon[slot]!=n) continue;
                    else
                    {
                        string[] spl = n.split("_");
                        if (spl.length > 1)
                        {
                            string mat = spl[0];
                            if (mat == "mat")
                                v *= 1 + (this.get_f32("drs")*0.33);
                        }
                        if (XORRandom(2500) <= v) // item passed
                        {
                            CBlob@ blob = server_CreateBlob(n, this.getTeamNum(), this.getPosition());
                            blob.server_SetQuantity(Maths::Floor(valMoon[slot] * yieldMoon[slot]/1000.0f + XORRandom(valMoon[slot])));
                            this.server_PutInInventory(blob);
                        }
                        else
                        {
                            //printf(n);
                            i--;
                        }
                    }
                }
            }
        }
        else if (dest == "exoplanet")
        {
            for (u8 i = 0; i < 25+this.get_f32("drs")*5+XORRandom(16); i++)
            {
                u8 slot = XORRandom(matExoplanet.length);
                u16 chance;
                for (u8 j = 0; j < rolling.length; j++)
                {
                    string[] s = rolling[j].split("-");
                    string n = s[0]; //name
                    u16 v = parseFloat(s[1]); //value
                    if (matExoplanet[slot]!=n) continue;
                    else
                    {
                        string[] spl = n.split("_");
                        if (spl.length > 1)
                        {
                            string mat = spl[0];
                            if (mat == "mat")
                                v *= 1 + (this.get_f32("drs")*0.33);
                        }
                        if (XORRandom(2500) <= v) // item passed
                        {
                            CBlob@ blob = server_CreateBlob(n, this.getTeamNum(), this.getPosition());
                            blob.server_SetQuantity(Maths::Floor(valExoplanet[slot] * yieldExoplanet[slot]/1000.0f + XORRandom(valExoplanet[slot])));
                            this.server_PutInInventory(blob);
                        }
                        else
                        {
                            //printf(n);
                            i--;
                        }
                    }
                }
            }
        }
    }
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
    if (this is null) return;
    if (this.hasTag("released")) return;
    if (this.getTickSinceCreated() <= 5) return;
    if (blob is null) return;

    ReleaseEnemies(this);
    this.Tag("released");
}

const string[] rolling = { // from 0 to 2500, as bigger value as more chance to get item
    "advancedengineertools-1500", 
    "amogusplushie-200", 
    "ancientmanipulator-750",
    "blaster-850",
    "callahan-350",
    "chargelance-250",
    "chargeblaster-600"
    "chargepistol-1500",
    "chargerifle-1250",
    "covfefe-10",
    "cricket-750",
    "cube-50",
    "demonicartifact-25",
    "energymatter-1450",
    "exosuititem-1000",
    "gyromat-1350",
    "illegalgunpart-1000",
    "infernalstone-150",
    "infernocannon-235",
    "klaxon-300",
    "laserrifle-1200",
    "lasershotgun-1350",
    "drak-1400",
    "lasersniper-900",
    "lifematter-1450",
    "mat_antimatter-800",
    "mat_copper-2250",
    "mat_concrete-1500",
    "mat_gold-1500",
    "mat_iron-2250",
    "mat_lancerod-1500",
    "mat_matter-1700",
    "mat_mithril-1200",
    "mat_mithrilbomb-1150",
    "mat_plasteel-1500",
    "mat_stone-2500",
    "mat_sulphur-1250",
    "mat_titanium-2250",
    "mat_wilmet-1800",
    "molecularfabricator-750",
    "oof-650",
    "pheromones-2000",
    "shito-15",
    "suszooka-25",
    "zatniktel-400",
    "zatniktelbig-250"
};

const string[] matAsteroid = {
    "mat_iron",
    "mat_copper",
    "mat_gold",
    "mat_titanium",
    "mat_concrete",
    "mat_mithril",
    "mat_sulphur",
    "mat_mithrilingot",
    "infernalstone",
    "amogusplushie",
    "covfefe"
};

const u16[] valAsteroid = {
    3000,
    1200,
    1250,
    900,
    1500,
    1400,
    1000,
    75,
    1, //infernal stone
    1, //amogi
    1
};
// yields are the random increasing amount, as more it is (from 1 to 1000), as more mats it can summon with a random chance
const u16[] yieldAsteroid = { // depending on the value
    200,
    75,
    75,
    225,
    90,
    275, // mithril
    500,
    300,
    150,
    0,
    0,
    0
};

const string[] matMoon = {
    "mat_stone",
    "mat_iron",
    "mat_copper",
    "mat_titanium",
    "mat_sulphur",
    "mat_matter",
    "mat_plasteel",
    "mat_mithrilbomb",
    "oof",
    "mat_wilmet",
    "exosuititem",
    "illegalgunpart",
    "infernalstone",
    "amogusplushie",
    "lifematter",
    "energymatter",
    "chargeblaster",
    "chargerifle",
    "chargepistol",
    "cricket",
    "chargelance",
    "mat_lancerod",
    "klaxon",
    "cube",
    "demonicartifact",
    "ancientmanipulator",
    "zatniktel",
    "zatniktelbig"
};

const u16[] valMoon = {
    3000,
    2500,
    1250,
    1300,
    750,
    175,
    100,
    2,
    1, //oof
    400,
    2,
    1,
    1,
    1, //amogi
    6,
    6,
    1,
    1,
    2,
    1,
    1,
    50, //lancerod
    1,
    1,
    1,
    1,
    1,
    1
};

const u16[] yieldMoon = {
    1000,
    250,
    200,
    350,
    300,
    250, //mithril
    175,
    100, 
    150,
    70,
    0, //oof
    500,
    200,
    0,
    0,
    500,
    450,
    450, //energymatter
    0,
    0,
    150,
    0,
    0,
    350, //lancerod
    200,
    0,
    0,
    0,
    0,
    0
};

const string[] matExoplanet = {
    "mat_iron",
    "mat_copper",
    "mat_gold",
    "mat_titanium",
    "mat_mithril",
    "mat_sulphur",
    "mat_plasteel",
    "mat_matter",
    "mat_antimatter", // pls dont make it much
    "mat_mithrilbomb",
    "mat_wilmet",
    "amogusplushie",
    "gyromat",
    "suszooka",
    "lifematter",
    "energymatter",
    "pheromones",
    "advancedengineertools",
    "callahan",
    "blaster",
    "infernocannon",
    "lasershotgun",
    "drak",
    "laserrifle",
    "lasersniper",
    "molecularfabricator",
    "shito"
};

const u16[] valExoplanet = {
    1500,
    1000,
    900,
    1000,
    1000,
    1500,
    650,
    350, //matter
    15,
    6,
    700,
    2,
    2,
    1, //suszooka
    10,
    10,
    3,
    3, //adv tools
    1,
    1,
    1,
    2,
    1,
    2,
    1,
    1,
    1
};

const u16[] yieldExoplanet = {
    250,
    150,
    150,
    150,
    250,
    100,
    500,
    500,
    150,
    250, //mithbomb
    200,
    100,
    275,
    0,
    150,
    150, //energymatter
    100,
    150,
    0,
    0,
    0,
    150, //lasershotgun
    200,
    50,
    0,
    0 //shito
};

void SyncVars(CBlob@ this)
{
    if (isServer())
    {
        CBitStream params;
        params.write_string(this.get_string("destination"));
        this.SendCommand(this.getCommandID("sync_state"), params);
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("sync_state"))
	{
        if (isClient())
        {
            string dest = params.read_string();

            this.set_string("destination", dest);
        }
    }
}