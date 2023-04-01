#include "Hitters.as";
#include "Explosion.as";

const u32 fly_timer_max = 25 * 60;

void onInit(CBlob@ this)
{
	this.Tag("usable by anyone");

	this.addCommandID("offblast");
	this.addCommandID("select");
	this.addCommandID("aste");

    this.set_f32("velocity", 0);
    this.set_u32("fly_timer", 0);
    this.set_u32("preptimer", 0);
	this.set_u8("state", 0);

	this.Tag("grapplable");

    this.getShape().SetRotationsAllowed(false);

    CSprite@ sprite = this.getSprite();
    if (sprite !is null)
    {
        sprite.SetRelativeZ(-15.0f);
		this.SetMapEdgeFlags(u8(CBlob::map_collide_none | CBlob::map_collide_left | CBlob::map_collide_right | CBlob::map_collide_nodeath));
    }

	AddIconToken("$icon_asteroid$", "IconAsteroid.png", Vec2f(16, 16), 0);
}

void onInit(CSprite@ this)
{
	this.SetEmitSound("Mystical_EnergySwordHumLoop5.ogg");
    this.SetEmitSoundVolume(1.2f);
    this.SetEmitSoundSpeed(0.25f);
    this.SetEmitSoundPaused(false);

	CSpriteLayer@ f = this.addSpriteLayer("turbinefire", "Effect_Fire", 40, 16);
	if (f !is null)
	{
		Animation@ fanim = f.addAnimation("fsize", 3, true);
		if (fanim !is null)
		{
			int[] frames = {0,1,2};
			fanim.AddFrames(frames);
			f.SetAnimation(fanim);
		}
		f.RotateByDegrees(-90.0f, Vec2f(0,0));
		f.SetOffset(Vec2f(-0.35, 65));
		f.SetVisible(false);
	}
}

void onTick(CBlob@ this)
{
	if (this.hasTag("offblast"))
	{
		Vec2f dir;

		if (this.get_u32("fly_timer") > getGameTime())
		{
			this.set_f32("velocity", Maths::Min(this.get_f32("velocity") + 0.025f, 10.0f));

			this.setVelocity(Vec2f(XORRandom(10) < 5 ? 0.25f : -0.25f, -this.get_f32("velocity")));
			MakeParticle(this, Vec2f(0,0.5+XORRandom(10)/10), XORRandom(100) < 25 ? ("RocketFire" + (1 + XORRandom(2))) : "SmallExplosion" + (1 + XORRandom(3)));
			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
			{
				sprite.SetEmitSound("Rocket_Idle.ogg");
				sprite.SetEmitSoundSpeed(1.4f);
        		sprite.SetEmitSoundVolume(2.0f);
				sprite.SetEmitSoundPaused(false);

				CSpriteLayer@ fire = sprite.getSpriteLayer("turbinefire");
				if (fire !is null)
				{
					fire.SetVisible(true);
					fire.SetAnimation("fsize");
				}
			}

			this.SetLight(true);
			this.SetLightRadius(256.0f);
			this.SetLightColor(SColor(255, 255, 100, 0));
		}
		else
		{
			this.Tag("dead");
            this.server_Die();
		}
	}
}

void MakeParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	Vec2f offset = Vec2f(XORRandom(25)-12, 64+XORRandom(16));
	CMap@ map = getMap(); // fire things up if standing under
	if (isServer() && map !is null)
	{
		for (u8 i = 0; i < 10; i++)
		{
			map.server_setFireWorldspace(this.getPosition()+offset+Vec2f(XORRandom(24)-12, XORRandom(32)-16), true);
		}
	}
	if (!isClient()) return;
    for (u8 i = 0; i < 10; i++)
    {
	    ParticleAnimated(filename, this.getPosition() + offset, Vec2f(0, 0.5+XORRandom(10)/10), float(XORRandom(360)), 1.5f, 2 + XORRandom(3), 0.25f, false);
    }
}

void onDie(CBlob@ this)
{
	//drop mats here
	if (this.getPosition().y < 0) return;
	Explode(this, 64.0f, 0.5f);
	if (this.exists("motherlaunchpadid"))
	{
		CBlob@ lpad = getBlobByNetworkID(this.get_u16("motherlaunchpadid"));
		if (lpad !is null)
		{
			lpad.Tag("unsuccess");
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (this.hasTag("offblast")) return;
	CBitStream params;
	params.write_u16(caller.getNetworkID());

	if (this.get_u8("state") == 0)
	{
		caller.CreateGenericButton(16, Vec2f(0.0f, 14.0f), this, this.getCommandID("select"), "Select destination.", params);
	}
	else if (this.get_u8("state") == 1)
	{
		caller.CreateGenericButton(11, Vec2f(0.0f, 14.0f), this, this.getCommandID("offblast"), "Launch!", params);
	}
}

void DestinationMenu(CBlob@ this, CBlob@ caller)
{
	if (caller !is null && caller.isMyPlayer())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f), this, Vec2f(1, 1), "Choose destination.");
		
		if (menu !is null)
		{
			menu.deleteAfterClick = true;

			CGridButton@ buttonaste = menu.AddButton("$icon_asteroid$", "Set destination to an asteroid.", this.getCommandID("aste"), Vec2f(1, 1), params);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("select"))
	{
		u16 blobid = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(blobid);
		DestinationMenu(this, blob);
	}
	else if (cmd == this.getCommandID("offblast"))
	{
		if (this.hasTag("offblast")) return;

		this.Tag("projectile");
		this.Tag("aerial");

		this.set_Vec2f("direction", Vec2f(0, 1));

		this.Tag("offblast");
		this.set_u32("fly_timer", getGameTime() + fly_timer_max);
        this.set_u32("preptimer", getGameTime()+2*30);

		if (this.exists("motherlaunchpadid"))
		{
			CBlob@ lpad = getBlobByNetworkID(this.get_u16("motherlaunchpadid"));
			if (lpad !is null)
			{
				u32 t;
				//printf("lpad !is null");
				if (this.get_string("destination") == "asteroid")
				{
					if (isServer())
					{
						t = 4.0*30*60+XORRandom(2500);
						lpad.set_u32("time_to_arrival", t);

						lpad.Sync("time_to_arrival", true);
					}
					lpad.set_string("destination", "asteroid");

					CBitStream params;
					params.write_string("asteroid");
					lpad.SendCommand(lpad.getCommandID("set_dest"), params);
					//printf("rocket: lpad destination: "+lpad.get_string("destination"));
				}
			}
		}
	}
	else if (cmd == this.getCommandID("aste"))
	{
		this.set_u8("state", 1);
		this.set_string("destination", "asteroid");
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return false;
}
