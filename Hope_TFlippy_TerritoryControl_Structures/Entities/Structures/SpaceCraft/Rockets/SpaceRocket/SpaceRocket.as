#include "Hitters.as";
#include "Explosion.as";
#include "SpaceRocketAnim.as";

const u32 fly_timer_max = 30 * 60;

void onInit(CBlob@ this)
{
	this.Tag("usable by anyone");

	this.addCommandID("offblast");
	this.addCommandID("select");
	this.addCommandID("aste");
	this.addCommandID("moon");
	this.addCommandID("exo");

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
	AddIconToken("$icon_moon$", "IconMoon.png", Vec2f(16, 16), 0);
	AddIconToken("$icon_exoplanet$", "IconExoplanet.png", Vec2f(16, 16), 0);
}

void onTick(CBlob@ this)
{
	if (this.hasTag("offblast") && this.get_u32("preptimer") < getGameTime())
	{
		Vec2f dir;

		if (this.get_u32("fly_timer") > getGameTime())
		{
			this.set_f32("velocity", Maths::Min(this.get_f32("velocity") + 0.02f, 10.0f));

			this.setVelocity(Vec2f(XORRandom(10) < 5 ? 0.25f : -0.25f, -this.get_f32("velocity")));
			MakeParticle(this, Vec2f(0,0.5+XORRandom(10)/10), XORRandom(100) < 25 ? ("RocketFire" + (1 + XORRandom(2))) : "SmallExplosion" + (1 + XORRandom(3)));
			Ignite(this);
		}
		else
		{
			this.Tag("dead");
            this.server_Die();
		}
	}
}

void onDie(CBlob@ this)
{
	//drop mats here
	if (this.getPosition().y < 0) return;
	Explode(this, 128.0f, 0.5f);
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
		caller.CreateGenericButton(16, Vec2f(0.0f, 32.0f), this, this.getCommandID("select"), "Select destination.", params);
	}
	else if (this.get_u8("state") == 1)
	{
		caller.CreateGenericButton(11, Vec2f(0.0f, 32.0f), this, this.getCommandID("offblast"), "Launch!", params);
	}
}

void DestinationMenu(CBlob@ this, CBlob@ caller)
{
	if (caller !is null && caller.isMyPlayer())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f), this, Vec2f(3, 1), "Choose destination.");
		
		if (menu !is null)
		{
			menu.deleteAfterClick = true;

			CGridButton@ buttonaste = menu.AddButton("$icon_asteroid$", "Set destination to an asteroid.", this.getCommandID("aste"), Vec2f(1, 1), params);
			CGridButton@ buttonmoon = menu.AddButton("$icon_moon$", "Set destination to moon.", this.getCommandID("moon"), Vec2f(1, 1), params);
			CGridButton@ buttonexo = menu.AddButton("$icon_exoplanet$", "Set destination to another planet\nRequires an extra fuel tank!", this.getCommandID("exo"), Vec2f(1, 1), params);
			if (buttonexo !is null)
			{
				if (this.get_string("module1") != "fueltank"
				&& this.get_string("module2") != "fueltank"
				&& this.get_string("module3") != "fueltank"
				&& this.get_string("module4") != "fueltank")
					buttonexo.SetEnabled(false);
				else buttonexo.SetEnabled(true);
			}
		}
	}
}

void SetMaxTime(CBlob@ this, CBlob@ lpad, u32 t)
{
	if (this !is null && t > 0)
	{
		CBitStream params;
		params.write_u32(t);
		lpad.SendCommand(lpad.getCommandID("set_max_time"), params);
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
        this.set_u32("preptimer", getGameTime()+25*30);

		if (isClient())
		{
			CSprite@ sprite = this.getSprite();

            sprite.PlaySound("SpaceRocket_launch.ogg", 5.0f);
		}
		
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
						t = 5.5*30*60+XORRandom(2500);
						lpad.set_u32("time_to_arrival", t);

						lpad.Sync("time_to_arrival", true);
					}
					lpad.set_string("destination", "asteroid");

					CBitStream params;
					params.write_string("asteroid");
					lpad.SendCommand(lpad.getCommandID("set_dest"), params);
					//printf("rocket: lpad destination: "+lpad.get_string("destination"));
				}
				else if (this.get_string("destination") == "moon")
				{
					if (isServer())
					{
						t = 8.5*30*60+XORRandom(6000);
						lpad.set_u32("time_to_arrival", t);

						lpad.Sync("time_to_arrival", true);
					}
					lpad.set_string("destination", "moon");
					
					CBitStream params;
					params.write_string("moon");
					lpad.SendCommand(lpad.getCommandID("set_dest"), params);
					//printf("rocket: lpad destination: "+lpad.get_string("destination"));
				}
				else if (this.get_string("destination") == "exoplanet")
				{
					if (isServer())
					{
						t = 12.5*30*60+XORRandom(8000);
						lpad.set_u32("time_to_arrival", t);

						lpad.Sync("time_to_arrival", true);
					}
					lpad.set_string("destination", "exoplanet");
					
					CBitStream params;
					params.write_string("exoplanet");
					lpad.SendCommand(lpad.getCommandID("set_dest"), params);
					//printf("rocket: lpad destination: "+lpad.get_string("destination"));
				}
				SetMaxTime(this, lpad, t);
			}
		}
	}
	else if (cmd == this.getCommandID("aste"))
	{
		this.set_u8("state", 1);
		this.set_string("destination", "asteroid");
	}
	else if (cmd == this.getCommandID("moon"))
	{
		this.set_u8("state", 1);
		this.set_string("destination", "moon");
	}
	else if (cmd == this.getCommandID("exo"))
	{
		this.set_u8("state", 1);
		this.set_string("destination", "exoplanet");
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

void Ignite(CBlob@ this)
{
	Vec2f offset = Vec2f(XORRandom(49)-24, 100+XORRandom(16));
	CMap@ map = getMap(); // fire things up if standing under
	if (isServer() && map !is null)
	{
		for (u8 i = 0; i < 10; i++)
		{
			map.server_setFireWorldspace(this.getPosition()+offset+Vec2f(XORRandom(24)-12, XORRandom(32)-16), true);
		}
	}
}