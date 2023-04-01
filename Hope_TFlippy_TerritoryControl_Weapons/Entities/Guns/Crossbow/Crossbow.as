#include "GunCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID("set_arrow");

	GunSettings settings = GunSettings();

	//General
	//settings.CLIP = 0; //Amount of ammunition in the gun at creation
	settings.TOTAL = 1; //Max amount of ammo that can be in a clip
	settings.FIRE_INTERVAL = 20; //Time in between shots
	settings.RELOAD_TIME = 35; //Time it takes to reload (in ticks)
	settings.AMMO_BLOB = "mat_arrows"; //Ammunition the gun takes

	//Bullet
	settings.B_PER_SHOT = 5; //Shots per bullet | CHANGE B_SPREAD, otherwise both bullets will come out together
	settings.B_SPREAD = 4; //the higher the value, the more 'uncontrollable' bullets get
	//settings.B_GRAV = Vec2f(0, 0.001); //Bullet gravity drop
	settings.B_SPEED = 25; //Bullet speed, STRONGLY AFFECTED/EFFECTS B_GRAV
	//settings.B_TTL = 100; //TTL = 'Time To Live' which determines the time the bullet lasts before despawning
	settings.B_DAMAGE = 2.0f; //1 is 1 heart
	//settings.B_TYPE = HittersTC::bullet_high_cal; //Type of bullet the gun shoots | hitter

	//Recoil
	settings.G_RECOIL = -10; //0 is default, adds recoil aiming up
	//settings.G_RANDOMX = true; //Should we randomly move x
	//settings.G_RANDOMY = false; //Should we randomly move y, it ignores g_recoil
	settings.G_RECOILT = 7; //How long should recoil last, 10 is default, 30 = 1 second (like ticks)
	settings.G_BACK_T = 6; //Should we recoil the arm back time? (aim goes up, then back down with this, if > 0, how long should it last)

	//Sound
	settings.FIRE_SOUND = "BowFire.ogg"; //Sound when shooting
	settings.RELOAD_SOUND = "BowPull.ogg"; //Sound when reloading

	this.set("gun_settings", @settings);

	//Custom
	this.set_string("CustomCycle", "");
	this.set_string("CustomCase", "");
	this.set_u32("CustomGunRecoil", 2);
	this.set_string("CustomFlash", "");
	this.set_f32("CustomReloadPitch", 0.9f);
	if (isServer() && this.exists("ProjBlob")) this.Sync("ProjBlob", true);
	if (!this.exists("ProjBlob")) this.set_string("ProjBlob", "arrow");
	this.set_Vec2f("ProjOffset", Vec2f(-15, -1.5));

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		Animation@ anim = sprite.addAnimation("reload", 1, false);
		if (anim !is null)
		{
			anim.AddFrame(2);
			sprite.SetAnimation("reload");
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBlob@ carried = caller.getCarriedBlob();
	if (this.isAttached()) return;
	CBitStream params;

	if (carried !is null && (carried.getName() == "mat_arrows"
	|| carried.getName() == "mat_waterarrows"
	|| carried.getName() == "mat_firearrows"
	|| carried.getName() == "mat_bombarrows"))
	{
		params.write_u16(caller.getNetworkID());
		CButton@ button = caller.CreateGenericButton(17, Vec2f(0, 0), this, this.getCommandID("set_arrow"), "Change arrow type", params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("set_arrow"))
	{
		u16 netid = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(netid);
		GunSettings@ settings;
		if (!this.get("gun_settings", @settings)) return;

		if (caller !is null && settings !is null)
		{
			CBlob@ carried = caller.getCarriedBlob();
			if (carried !is null)
			{
				this.Untag("waterarrows");
				this.Untag("firearrows");
				this.Untag("bombarrows");
				if (carried.getName() == "mat_arrows")
				{
					this.setInventoryName("Crossbow (arrows)");
					settings.AMMO_BLOB = "mat_arrows";
				}
				else if (carried.getName() == "mat_waterarrows")
				{
					this.setInventoryName("Crossbow (water arrows)");
					this.Tag("waterarrows");
					settings.AMMO_BLOB = "mat_waterarrows";
				}
				else if (carried.getName() == "mat_firearrows")
				{
					this.setInventoryName("Crossbow (fire arrows)");
					this.Tag("firearrows");
					settings.AMMO_BLOB = "mat_firearrows";
				}
				else if (carried.getName() == "mat_bombarrows")
				{
					this.setInventoryName("Crossbow (bomb arrows)");
					this.Tag("bombarrows");
					settings.AMMO_BLOB = "mat_bombarrows";
				}
			}
			this.set_u8("clip", 0);
			this.set("gun_settings", @settings);
		}
	}
}

void onTick(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	this.inventoryIconFrame = this.get_u8("clip") == 0 ? 2 : 0;
	if (sprite is null) return;
	if (sprite.getAnimation("default") !is null)
	{
		sprite.SetAnimation("default");
		if (this.hasTag("waterarrows")) sprite.SetFrameIndex(1);
		else if (this.hasTag("firearrows")) sprite.SetFrameIndex(2);
		else if (this.hasTag("bombarrows")) sprite.SetFrameIndex(3);
		else sprite.SetFrameIndex(0);
	}
	if (this.get_u8("clip") == 0)
		if (sprite.getAnimation("reload") !is null) sprite.SetAnimation("reload");
	//printf(""+this.get_u8("clip"));
}