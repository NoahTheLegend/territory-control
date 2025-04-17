#include "Explosion.as";
#include "Hitters.as";
#include "MakeMat.as";
#include "CustomBlocks.as";

const u8 cold_infernalstone_spawn_chance = 10;

u8 get_type(CBlob@ this)
{
    string name = this.getName();

    if (name.find("small") != -1) return 0; // small
    if (name.find("medium") != -1) return 1; // medium
    if (name.find("big") != -1) return 2; // big

    return 0;
}

const u8[][] min_max_spawn = {
    { 2, 4 }, // amount of small to drop from medium
    { 1, 2 } // amount of medium to drop from big
};

const f32[] pickaxe_dmg_reduction = {
    1.0f, // small type
    0.75f,  // medium type
    0.5f  // big type
};

const s32[] heats = {
    1800, // small, 1 min
    5400, // medium, 3 min
    9000 // big, 5 min
};

void onInit(CBlob@ this)
{
    this.set_f32("map_damage_ratio", 0.5f);
    this.set_bool("map_damage_raycast", true);
    this.set_string("custom_explosion_sound", "KegExplosion.ogg");
    this.Tag("map_damage_dirt");
    this.Tag("map_destroy_ground");
    this.Tag("ignore fall");
    this.set_u32("collision_time", 0);
    this.setAngleDegrees(XORRandom(360));

    u8 type = get_type(this);
    this.set_u8("type", type);
    if (type == 0) this.Tag("medium weight");
    else this.Tag("heavy weight");

    this.server_setTeamNum(-1);
    this.getShape().SetRotationsAllowed(true);

    s32 heat = heats[type];
    this.set_s32("max_heat", heat);

    if (!this.hasTag("spawn_at_sky")) return;
    
    CMap@ map = getMap();
    this.Tag("explosive");
    this.set_s32("heat", heat); // 6 min cooldown time (unless in water)

    this.setPosition(Vec2f(this.getPosition().x, 0.0f));
    this.setVelocity(Vec2f(20.0f - XORRandom(4001) / 100.0f, 15.0f));

    if (isClient())
    {
        CSprite@ sprite = this.getSprite();
        sprite.SetEmitSound("Rocket_Idle.ogg");
        sprite.SetEmitSoundPaused(false);
        sprite.SetEmitSoundVolume(1.5f);

        string extra = "";
        CBlob@ local = getLocalPlayerBlob();
        if (local !is null)
        {
            Vec2f lpos = local.getPosition();
            if (Maths::Abs(lpos.x - this.getPosition().x) > 512.0f)
            {
                if (lpos.x < this.getPosition().x) extra = " in the east";
                else extra = " in the west";
            }
        }
        client_AddToChat("A bright flash illuminates the sky"+extra, SColor(255, 255, 0, 0));
    }
}

void onTick(CBlob@ this)
{
    u8 type = this.get_u8("type");

    if (isServer() && !this.hasTag("collided") && this.getTickSinceCreated() < 5)
    {
        this.AddTorque(this.getVelocity().x * this.getMass() * (0.1f+(XORRandom(10) * 0.01f)) / (type+1));
    }

    if (isServer() && type == 0 && this.exists("detach_timing") && this.get_u32("detach_timing") >= getGameTime())
        this.AddTorque(this.getVelocity().x * this.getMass() * (0.5f+(XORRandom(50) * 0.01f)));

    s32 heat = this.get_s32("heat");
    s32 maxheat = this.get_s32("max_heat");
    f32 heatscale = float(heat) / float(maxheat);

    if (isClient() && heat > 0 && getGameTime() % int((1.0f - heatscale) * 9.0f + 1.0f) == 0)
    {
        MakeParticle(this, XORRandom(100) < 10 ? ("SmallSmoke" + (1 + XORRandom(2))) : "SmallExplosion" + (1 + XORRandom(3)));
    }
    if (this.hasTag("collided") && this.getVelocity().Length() < 2.0f) this.Untag("explosive");

    if (!this.hasTag("explosive"))
    {
        if (heat > 0)
        {
            AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
            if (point !is null)
            {
                CBlob@ holder = point.getOccupied();
                if (holder !is null && XORRandom(3) == 0)
                {
                    this.server_DetachFrom(holder);
                }
            }

            if (this.isInWater())
            {
                if(isClient() && getGameTime() % 4 == 0)
                {
                    MakeParticle(this, "MediumSteam");
                    this.getSprite().PlaySound("Steam.ogg");
                }

                heat -= 10;
            }
            else heat -= 1;

            if (isServer() && this.getTickSinceCreated() % (20 + this.getNetworkID() % 10) == 0)
            {
                CMap@ map = getMap();
                Vec2f pos = this.getPosition();
                CBlob@[] blobs;

                f32 radius = this.getRadius();
                if (map.getBlobsInRadius(pos, radius * 2.0f, @blobs))
                {
                    for (int i = 0; i < blobs.length; i++)
                    {
                        CBlob@ blob = blobs[i];
                        if (blob.isFlammable()) map.server_setFireWorldspace(blob.getPosition(), true);
                    }
                }

                f32 tileDist = radius * 2.0f;
                if (map.getTile(pos).type == CMap::tile_wood_back) map.server_setFireWorldspace(pos, true);
                if (map.getTile(pos + Vec2f(0, tileDist)).type == CMap::tile_wood) map.server_setFireWorldspace(pos + Vec2f(0, tileDist), true);
                if (map.getTile(pos + Vec2f(0, -tileDist)).type == CMap::tile_wood) map.server_setFireWorldspace(pos + Vec2f(0, -tileDist), true);
                if (map.getTile(pos + Vec2f(tileDist, 0)).type == CMap::tile_wood) map.server_setFireWorldspace(pos + Vec2f(tileDist, 0), true);
                if (map.getTile(pos + Vec2f(-tileDist, 0)).type == CMap::tile_wood) map.server_setFireWorldspace(pos + Vec2f(-tileDist, 0), true);
            }

            if (isClient() && XORRandom(100) < 60) this.getSprite().PlaySound("FireRoar.ogg");
        }
    }

    if (heat < 0) heat = 0;
    this.set_s32("heat", heat);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
    if (this.hasTag("collided")) return;
    if (solid || (blob !is null && blob.getShape().isStatic() && blob.doesCollideWithBlob(this)))
        onHitGround(this);
}

void MakeParticle(CBlob@ this, const string filename = "SmallSteam")
{
    if (!this.isOnScreen()) return;

    ParticleAnimated(filename, this.getPosition() + Vec2f(XORRandom(this.getRadius()), 0).RotateBy(XORRandom(360)), Vec2f_zero, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}

void onHitGround(CBlob@ this)
{
    if (!this.hasTag("explosive")) return;

    CMap@ map = getMap();

    f32 vellen = this.getOldVelocity().Length();
    if (vellen < 8.0f) return;

    u8 type = this.get_u8("type");
    f32 powerMultiplier = 1.0f;

    if (type == 1) powerMultiplier = 2.0f; // medium meteor
    else if (type == 2) powerMultiplier = 4.0f; // big meteor

    f32 power = Maths::Min(vellen / 9.0f, 1.0f) * powerMultiplier;
    if (!this.hasTag("collided"))
    {
        this.setVelocity(Vec2f(this.getVelocity().x / 8, this.getVelocity().y));
        this.set_u32("collision_time", getGameTime());

        if (isClient())
        {
            this.getSprite().SetEmitSoundPaused(true);
            ShakeScreen(power * 100.0f, power * 50.0f, this.getPosition());
            SetScreenFlash(150, 255, 238, 218);
            Sound::Play("MeteorStrike.ogg", this.getPosition(), 1.5f, 1.0f);
        }

        this.Tag("collided");
    }

    // create flames
    for (int i = 0; i < 5 * powerMultiplier; i++)
    {
        Vec2f pos = this.getPosition() + Vec2f(XORRandom(100) - 50, XORRandom(100) - 50);
        CBlob@ flame = server_CreateBlob("flame", -1, pos);
        if (flame !is null)
        {
            flame.server_SetTimeToDie(10 + XORRandom(6));
            flame.setVelocity(Vec2f(XORRandom(20) - 10, XORRandom(10) - 10));
            flame.server_setTeamNum(-1);
            flame.SetMass(500.0f);
            flame.getShape().setDrag(1.0f);
        }

    }

    if (isServer())
	{
		CBlob@ boom = server_CreateBlobNoInit("nukeexplosion");
        boom.set_u16("owner_id", this.getNetworkID());
		boom.Tag("no mithril");
		boom.Tag("no fallout");
        boom.Tag("no side blast");
		boom.setPosition(this.getPosition());
        boom.set_f32("map_damage_ratio", 0.25f);
		boom.set_u8("boom_start", 0);
		boom.set_u8("boom_end", 5 + (8 * (powerMultiplier - 1)));
        boom.set_u8("boom_frequency", 1);
        boom.set_u32("boom_delay", 0);
		boom.set_f32("flash_distance", 32.0f * powerMultiplier);
        boom.set_f32("explosion_radius", 32.0f + 1.0f * powerMultiplier);
        boom.set_f32("explosion_angle", -this.getVelocity().Angle());
        boom.set_f32("nuke_explosion_damage", 10.0f + (25.0f * powerMultiplier - 1));
        boom.set_f32("custom_explosion_sound_pitch", 1.5f - (0.15f * powerMultiplier));
		boom.Init();
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    if (hitterBlob !is null && hitterBlob.getName() == "nukeexplosion" && hitterBlob.get_u16("owner_id") == this.getNetworkID())
    {
        return 0.0f;
    }

    u8 type = this.get_u8("type");
    if (customData == Hitters::builder)
    {
        damage *= pickaxe_dmg_reduction[type];
    }

    if (customData != Hitters::builder && customData != Hitters::drill)
    {
        s32 heat = this.get_s32("heat");
        if (customData == Hitters::water || customData == Hitters::water_stun && heat > 0)
        {
            if(isClient())
            {
                MakeParticle(this, "MediumSteam");
                this.getSprite().PlaySound("Steam.ogg");
            }
            
            heat -= 350;
            if(heat < 0) heat = 0;
            this.set_s32("heat", heat);
        }

        if (customData == Hitters::explosion) return damage;
        return 0.0f;
    }

    if (isServer())
    {
        if (type != 0) return damage; // only small can drop resources

        MakeMat(hitterBlob, worldPoint, "mat_stone", (25 + XORRandom(50)) * damage);
        if (XORRandom(2) == 0) MakeMat(hitterBlob, worldPoint, "mat_copper", (20 + XORRandom(25)) * damage);
        if (XORRandom(2) == 0) MakeMat(hitterBlob, worldPoint, "mat_iron", (40 + XORRandom(60)) * damage);
        if (XORRandom(2) == 0) MakeMat(hitterBlob, worldPoint, "mat_mithril", (25 + XORRandom(30)) * damage);
        if (XORRandom(2) == 0) MakeMat(hitterBlob, worldPoint, "mat_gold", (XORRandom(75)) * damage);
        if (XORRandom(2) == 0) MakeMat(hitterBlob, worldPoint, "mat_titanium", (XORRandom(65)) * damage);
        if (XORRandom(2) == 0) MakeMat(hitterBlob, worldPoint, "mat_plasteel", (XORRandom(8)) * damage);
        if (XORRandom(2) == 0) MakeMat(hitterBlob, worldPoint, "mat_wilmet", (XORRandom(10)) * damage);
    }

    return damage;
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
    if (!isServer()) return;

    if (attachedPoint !is null && attachedPoint.name == "PICKUP")
    {
        this.set_u32("detach_timing", getGameTime());
    }
}

void onDie(CBlob@ this)
{
    if (!isServer()) return;
    if (this.hasTag("dead")) return;

    u8 type = this.get_u8("type");
    if (type == 0)
    {
        if (XORRandom(100) < cold_infernalstone_spawn_chance)
        {
            CBlob@ stone = server_CreateBlob("infernalstone", -1, this.getPosition());
            if (stone !is null)
            {
                stone.Tag("cold");
            }
        }
    }
    else
    {
        // drop respective smaller meteors
        u8 spawn_type = type - 1;
        u8 min = min_max_spawn[type - 1][0];
        u8 max = min_max_spawn[type - 1][1];
        u8 rnd = XORRandom(max - min + 1);
        u8 amount = min + rnd;

        f32 rad = this.getRadius();
        for (int i = 0; i < amount; i++)
        {
            u8 rnd_small = XORRandom(3);
            u8 rnd_medium = XORRandom(2);
            u8 rnd_big   = XORRandom(2);

            string spawn_name = spawn_type == 0 ? "small" : "medium";
            string spawn_blobname = "meteor" + spawn_name + (spawn_type == 0
                                                        ? rnd_small : spawn_type == 1
                                                        ? rnd_medium : rnd_big);

            CBlob@ blob = server_CreateBlob(spawn_blobname, -1, this.getPosition() + Vec2f(XORRandom(rad * 2) - rad, XORRandom(rad) - rad / 2));
            if (blob !is null)
            {
                blob.set_s32("heat", this.get_s32("heat") / 2);
                blob.Sync("heat", true); // dangerous
            }
        }
    }
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
    return this.getName() == "meteorsmall0" || this.getName() == "meteorsmall1";
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
    if (blob.hasTag("dead")) return false;
    if (blob.getName() == "flame") return false;

    return true;
}