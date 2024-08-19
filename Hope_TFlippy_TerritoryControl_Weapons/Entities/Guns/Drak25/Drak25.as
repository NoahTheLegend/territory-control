#include "GunCommon.as";
#include "GunStandard.as";
#include "GunModule.as"
#include "BulletCase.as";
#include "Recoil.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.isAttached()) return 0;
	return damage;
}

void onInit(CBlob@ this)
{
	GunSettings settings = GunSettings();

	//General
	settings.CLIP = 30; //Amount of ammunition in the gun at creation
	settings.TOTAL = 30; //Max amount of ammo that can be in a clip
	settings.FIRE_INTERVAL = 4; //Time in between shots
	settings.RELOAD_TIME = 1; //Time it takes to reload (in ticks)
	settings.AMMO_BLOB = ""; //Ammunition the gun takes

	//Bullet
	//settings.B_PER_SHOT = 1; //Shots per bullet | CHANGE B_SPREAD, otherwise both bullets will come out together
	settings.B_SPREAD = 2; //the higher the value, the more 'uncontrollable' bullets get
	settings.B_GRAV = Vec2f(0, 0); //Bullet gravity drop
	settings.B_SPEED = 25; //Bullet speed, STRONGLY AFFECTED/EFFECTS B_GRAV
	settings.B_TTL = 35; //TTL = 'Time To Live' which determines the time the bullet lasts before despawning
	settings.B_DAMAGE = 1.1f; //1 is 1 heart
	settings.B_TYPE = HittersTC::plasma; //Type of bullet the gun shoots | hitter

	//Recoil
	settings.G_RECOIL = -3; //0 is default, adds recoil aiming up
	settings.G_RANDOMX = true; //Should we randomly move x
	settings.G_RANDOMY = false; //Should we randomly move y, it ignores g_recoil
	settings.G_RECOILT = 2; //How long should recoil last, 10 is default, 30 = 1 second (like ticks)
	settings.G_BACK_T = 2; //Should we recoil the arm back time? (aim goes up, then back down with this, if > 0, how long should it last)

	//Sound
	settings.FIRE_SOUND = "DLoop.ogg"; //Sound when shooting

	//Offset
	settings.MUZZLE_OFFSET = Vec2f(-17.5, -0.5); //Where the muzzle flash appears

	this.set("gun_settings", @settings);
	
	//Custom
	this.set_f32("CustomBulletLength", 4.0f);
	this.set_f32("CustomBulletWidth", 2.0f);
	this.set_f32("CustomReloadPitch", 1.7);
	this.set_string("CustomBullet", "item_bullet_blaster.png");
	this.set_string("CustomFlash", "flash_blaster.png");
	this.Tag("CustomSoundLoop");

	this.set_f32("heat", 0);
	this.set_f32("heat_pershot", 35);
	this.set_f32("max_heat", 1333);
	this.set_f32("cooling", 15);
	this.set_f32("cooling_overheat", 5);
	this.set_f32("overheat", 0);
	this.set_u32("heat_lock", 0);

	this.SetLight(true);
	this.SetLightRadius(16.00f);
	this.SetLightColor(SColor(255, 85, 255, 55));

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;
	sprite.SetEmitSound(settings.FIRE_SOUND);
	sprite.SetEmitSoundVolume(1.5f);
	sprite.SetEmitSoundSpeed(1.0f);

	GunInit(this);
}

void GunInit(CBlob@ this)
{
	// Prevent classes from jabbing n stuff
	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null) 
	{
		ap.SetKeysToTake(key_action1);
	}

	u8 t;
	if (this.hasTag("pistol")) t = 5;
	else if (this.hasTag("sniper")) t = 45;
	else t = 30;
	this.set_u8("a1time", t);
	this.set_u8("holdtime", t);
	this.set_u32("lastshot", 0);

	// Set commands
	this.addCommandID("reload");
	this.addCommandID("fireProj");
	this.addCommandID("sync_interval");
	this.addCommandID("sync_heat");

	// Set vars
	this.set_bool("beginReload", false); //Starts a reload
	this.set_bool("doReload", false); //Determines if the gun is in a reloading phase
	this.set_u8("actionInterval", 0); //Timer for gun activities like shooting and reloading
	this.set_u8("clickReload", 1); //'Click' moment after shooting
	this.set_f32("gun_recoil_current", 0.0f); //Determines how far the kickback animation is when shooting

	this.Tag("weapon");
	this.Tag("InfiniteAmmo");
	this.Tag("no shitty rotation reset");
	this.Tag("hopperable");

	GunSettings@ settings;
	this.get("gun_settings", @settings);

	if (!this.exists("CustomBullet")) this.set_string("CustomBullet", "item_bullet.png");  // Default bullet image
	if (!this.exists("CustomBulletWidth")) this.set_f32("CustomBulletWidth", 1.0f);  // Default bullet width
	if (!this.exists("CustomBulletLength")) this.set_f32("CustomBulletLength", 14.0f); // Default bullet length

	string vert_name = this.get_string("CustomBullet");
	CRules@ rules = getRules();

	if (isClient()) //&& !rules.get_bool(vert_name + '-inbook'))
	{
		if (vert_name == "")
		{
			// warn(this.getName() + " Attempted to add an empty CustomBullet, this can cause null errors");
			return;
		}

		//rules.set_bool(vert_name + '-inbook', true);

		Vertex[]@ bullet_vertex;
		rules.get(vert_name, @bullet_vertex);

		if (bullet_vertex is null)
		{
			Vertex[] vert;
			rules.set(vert_name, @vert);
		}

		// #blamekag
		if (!rules.exists("VertexBook"))
		{
			string[] book;
			rules.set("VertexBook", @book);
			book.push_back(vert_name);
		}
		else
		{
			string[]@ book;
			rules.get("VertexBook", @book);
			book.push_back(vert_name);
		}
	}

	this.set_u8("clip", settings.CLIP); //Clip u8 for easy maneuverability

	CSprite@ sprite = this.getSprite();

	if (this.hasTag("CustomSoundLoop"))
	{
		sprite.SetEmitSound(settings.FIRE_SOUND);
		sprite.SetEmitSoundVolume(this.exists("CustomShootVolume") ? this.get_f32("CustomShootVolume") : 2.0f);
		sprite.SetEmitSoundPaused(true);
	}

	// Required or stuff breaks due to wonky mouse syndrome
#ifndef GUNS
	if (isServer())
		getControls().setMousePosition(Vec2f(0,0));
#endif

	if (!this.exists("CustomFlash") || (this.exists("CustomFlash") && !this.get_string("CustomFlash").empty()))
	{
		// Determine muzzleflash sprite
		const bool hitterType = settings.B_TYPE == HittersTC::plasma || settings.B_TYPE == HittersTC::railgun_lance;
		const string muzzleflash_file = this.exists("CustomFlash") ? this.get_string("CustomFlash") : hitterType ? "flash_plasma" : "flash_bullet";

		// Add muzzle flash
		CSpriteLayer@ flash = sprite.addSpriteLayer("muzzle_flash", muzzleflash_file, 16, 8, this.getTeamNum(), 0);
		if (flash !is null)
		{
			Animation@ anim = flash.addAnimation("default", 1, false);
			int[] frames = {0, 1, 2, 3, 4, 5, 6, 7};
			anim.AddFrames(frames);
			flash.SetRelativeZ(1.0f);
			flash.SetOffset(settings.MUZZLE_OFFSET);
			flash.SetFacingLeft(this.hasTag("CustomMuzzleLeft"));
			flash.SetVisible(false);
			//flash.setRenderStyle(RenderStyle::additive);
		}
	}

	/*GunModule[] modules = {};
	modules.push_back(TestModule());
	this.set("GunModules", modules);*/

	/*if (true)//(this.exists("GunModule"))
	{
		GunModule[]@ modules;
		this.get("GunModule", @modules);
		print("done");
		for (int a = 0; a < modules.length(); a++)
			modules[a].onModuleInit(this);
	}*/
}

void onTick(CBlob@ this)
{
	if (this.get_u32("heat_lock") <= getGameTime())
	{
		if (this.get_f32("heat") > 0 && this.get_f32("overheat") == 0)
		{
			this.set_f32("heat", Maths::Max(0, this.get_f32("heat")-this.get_f32("cooling")));
		}
		if (this.get_f32("overheat") > 0)
		{
			this.set_f32("overheat", Maths::Max(0, this.get_f32("overheat")-this.get_f32("cooling_overheat")));

			if (isClient() && getGameTime()%5 == 0)
			{
				makeSteamParticle(this, Vec2f());
			}
		}
	}

	if (this.hasTag("a1") && getGameTime() >= this.get_u32("disable_a1")) this.Untag("a1");
	if (this.hasTag("hold") && getGameTime() >= this.get_u32("disable_hold")) this.Untag("hold");
	// Server will always get put back to sleep (doesnt need to run any of this)
	if (this.isAttached())
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		CBlob@ holder = point.getOccupied();

		if (holder !is null)
		{
			CSprite@ sprite = this.getSprite();

			sprite.SetEmitSoundVolume(1.5f + 0.5f*this.get_f32("heat")/this.get_f32("max_heat"));
			sprite.SetEmitSoundSpeed(1.0f + 0.5f*this.get_f32("heat")/this.get_f32("max_heat"));

			f32 aimangle = getAimAngle(this, holder);
			f32 tempangle = aimangle;
			if (tempangle > 360.0f)
				tempangle -= 360.0f;
			else if (tempangle < -360.0f)
				tempangle += 360.0f;
			if (holder.isKeyPressed(key_action2))// || isBot)
			{
				u8 t = this.get_u8("a1time");
				
				this.Tag("a1");
				this.set_u32("disable_a1", getGameTime()+t);
			}

			this.set_f32("gun_recoil_current", Maths::Lerp(this.get_f32("gun_recoil_current"), 0, 0.45f));

			GunSettings@ settings;
			this.get("gun_settings", @settings);

			this.set_u8("clip", Maths::Ceil(30 * this.get_f32("heat")/this.get_f32("max_heat"))); //Clip u8 for easy maneuverability
			settings.CLIP = Maths::Ceil(30 * this.get_f32("heat")/this.get_f32("max_heat"));
			if (isServer() && !isClient())
			{
				this.set_u8("clip", 15);
				settings.CLIP = 15;
			}

			settings.FIRE_INTERVAL = 3 - Maths::Round(2 * this.get_f32("heat")/this.get_f32("max_heat"));

			f32 oAngle = (aimangle % 360) + 180;

			// Shooting
			const bool can_shoot = holder.isAttached() && holder.getName() != "automat" ? 
					   holder.isAttachedToPoint("PASSENGER") || holder.isAttachedToPoint("PILOT") : true;

			// Keys
			const bool pressing_shoot = (this.hasTag("CustomSemiAuto") ?
					   point.isKeyJustPressed(key_action1) || holder.isKeyJustPressed(key_action1) : //automatic
					   point.isKeyPressed(key_action1) || holder.isKeyPressed(key_action1)); //semiautomatic

			this.SetLightRadius(pressing_shoot ? 32.00f : 16.00f);

			const bool just_pressed_a1 = point.isKeyJustPressed(key_action1) || holder.isKeyJustPressed(key_action1);
			const bool just_released_a1= (!point.isKeyPressed(key_action1) && point.wasKeyPressed(key_action1))
				|| (!holder.isKeyPressed(key_action1) && holder.wasKeyPressed(key_action1));

			if (isClient() && this.get_f32("overheat") == 0)
			{
				if (just_pressed_a1)
				{
					this.getSprite().PlaySound("DStart.ogg", 1.5f, 1.25f);		
				}
				if (just_released_a1)
				{
					this.getSprite().PlaySound("DEnd0.ogg", 2.25f, 1.0f + 0.2f*this.get_f32("heat")/this.get_f32("max_heat"));	
					this.getSprite().PlaySound("DEnd1.ogg", 2.25f, 1.0f + 0.33f*this.get_f32("heat")/this.get_f32("max_heat"));	
				}
			}

			// Sound
			const f32 cycle_pitch  = this.exists("CustomCyclePitch")  ? this.get_f32("CustomCyclePitch")  : 1.0f;
			const f32 shoot_volume = this.exists("CustomShootVolume") ? this.get_f32("CustomShootVolume") : 2.0f;

			// Loop firing sound
			if (this.hasTag("CustomSoundLoop"))
			{
				sprite.SetEmitSoundPaused(!(pressing_shoot && this.get_f32("overheat") == 0));
			}

			uint8 actionInterval = this.get_u8("actionInterval");
			if (actionInterval > 0)
			{
				actionInterval--; // Timer counts down with ticks

				if (this.exists("CustomCycle") && isClient())
				{
					// Custom cycle sequence 
					if ((actionInterval == settings.FIRE_INTERVAL / 2) && this.get_bool("justShot"))
					{
						sprite.PlaySound(this.get_string("CustomCycle"));
						this.set_bool("justShot", false);
					}
				}
			}
			else if (pressing_shoot && can_shoot)
			{
				if (this.get_f32("overheat") == 0)
				{
					/*for (int a = 0; a < modules.length(); a++)
					{
						modules[a].onFire(this);
					}*/

					// Shoot weapon
					actionInterval = settings.FIRE_INTERVAL;
					//bool accurateHit = !this.hasTag("sniper") && getGameTime() >= (this.get_u32("lastshot") + actionInterval * 5);
					//this.set_u32("lastshot", getGameTime());

					Vec2f fromBarrel = Vec2f((settings.MUZZLE_OFFSET.x / 3) * (this.isFacingLeft() ? 1 : -1), settings.MUZZLE_OFFSET.y + 1);
					fromBarrel = fromBarrel.RotateBy(aimangle);

					//bool a2 = holder.isKeyPressed(key_action2) || isBot;

					if ((settings.B_SPREAD != 0 && settings.B_PER_SHOT == 1))// || this.hasTag("sniper"))
					{
						f32 spr = settings.B_SPREAD;
						//f32 res = a2 ? 1 : 2;
						//if (!isBot)
						//{
						//	u8 sniperspr = this.hasTag("sniper") ? 5 : 0;
						//	if (!a2) spr += sniperspr;
						//	spr *= res;
						//}
						
						//if (!accurateHit) aimangle += XORRandom(2) != 0 ? -XORRandom(spr) : XORRandom(spr);
						aimangle += XORRandom(2) != 0 ? -XORRandom(spr) : XORRandom(spr);
					}
					
					if (isClient() || (isServer() && holder.getPlayer() is null && holder.getBrain() !is null && holder.getBrain().isActive()))
					{
						this.add_f32("heat", this.get_f32("heat_pershot"));
						if (this.get_f32("heat") > this.get_f32("max_heat"))
						{
							this.set_f32("overheat", 500);
							if (isClient())
							{
								sprite.PlaySound("DrillOverheat.ogg");
								makeSteamPuff(this);
							}
						}
						this.set_u32("heat_lock", getGameTime()+5);

						// Local hosts / clients will run this
						if (holder.isMyPlayer())
						{
							shootGun(this.getNetworkID(), aimangle, holder.getNetworkID(), sprite.getWorldTranslation() + fromBarrel);
							
							CBitStream params;
							params.write_bool(true);
							params.write_f32(this.get_f32("heat"));
							this.SendCommand(this.getCommandID("sync_heat"), params);
						}
						else if (isServer()) // Server will run this
						{
							shootGun(this.getNetworkID(), aimangle, holder.getNetworkID(), this.getPosition() + fromBarrel);
						}
					}

					// Shooting sound
					if (!this.hasTag("CustomSoundLoop")) sprite.PlaySound(settings.FIRE_SOUND, shoot_volume);

					// Gun 'kickback' anim
					this.set_f32("gun_recoil_current", this.exists("CustomGunRecoil") ? this.get_u32("CustomGunRecoil") : 3);

					CSpriteLayer@ flash = sprite.getSpriteLayer("muzzle_flash");
					if (flash !is null)
					{
						//Turn on muzzle flash
						flash.SetFrameIndex(0);
						flash.SetVisible(true);
					}

					if (isClient()) 
					{
						this.set_bool("justShot", true);
					}
				}
			}

			if (actionInterval != 0 || this.get_u8("actionInterval") != 0) this.set_u8("actionInterval", actionInterval);
			//if (getGameTime()%15==0)printf(""+this.get_u8("actionInterval"));

			sprite.ResetTransform();
			//sprite.RotateBy( aimangle, holder.isFacingLeft() ? Vec2f(-3,3) : Vec2f(3,3) );
			this.setAngleDegrees(aimangle);
			sprite.SetOffset(Vec2f(this.get_f32("gun_recoil_current"), 0)); //Recoil effect for gun blob
		}
	} 
	else 
	{
		if (isClient() && this.hasTag("CustomSoundLoop"))
		{
			// Turn off sound if detached
			this.getSprite().SetEmitSoundPaused(true);
		}
		this.getCurrentScript().runFlags |= Script::tick_not_sleeping;
	}
}

void makeSteamParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	const f32 rad = this.getRadius();
	Vec2f random = Vec2f(XORRandom(128) - 64, XORRandom(128) - 64) * 0.015625f * rad;
	ParticleAnimated(filename, this.getPosition() + random, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}

void makeSteamPuff(CBlob@ this, const f32 velocity = 1.0f, const int smallparticles = 10, const bool sound = true)
{
	if (sound)
	{
		this.getSprite().PlaySound("Steam.ogg");
	}

	makeSteamParticle(this, Vec2f(), "MediumSteam");
	for (int i = 0; i < smallparticles; i++)
	{
		f32 randomness = (XORRandom(32) + 32) * 0.015625f * 0.5f + 0.75f;
		Vec2f vel = getRandomVelocity(-90, velocity * randomness, 360.0f);
		makeSteamParticle(this, vel);
	}
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (inventoryBlob is null) return;
	this.getSprite().SetEmitSoundPaused(true);
}