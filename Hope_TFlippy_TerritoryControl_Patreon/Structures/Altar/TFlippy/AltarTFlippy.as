#include "Requirements.as";
#include "Requirements_Tech.as";
#include "ShopCommon.as";
#include "DeityCommon.as";
#include "MakeSeed.as";

void onInit(CBlob@ this)
{
	//this.setPosition(this.getPosition()-Vec2f(8,8));

	this.set_u8("deity_id", Deity::tflippy);
	this.set_Vec2f("shop menu size", Vec2f(4, 4));

	this.addCommandID("turn_sounds");
	
	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("TC2music.ogg");
	sprite.SetEmitSoundVolume(2.0f);
	sprite.SetEmitSoundSpeed(1.00f);
	sprite.SetEmitSoundPaused(false);
	
	this.SetLight(true);
	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 255, 175, 61));

	this.addCommandID("sync_frame");
	this.set_u8("sprite_frame", XORRandom(14));
	this.addCommandID("sync_deity");

	if (isClient())
	{
		CBitStream params;
		params.write_bool(false);
		this.SendCommand(this.getCommandID("sync_frame"), params);
	}

	sprite.SetFrameIndex(this.get_u8("sprite_frame"));
	
	AddIconToken("$icon_tflippy_follower$", "InteractionIcons.png", Vec2f(32, 32), 11);
	{
		ShopItem@ s = addShopItem(this, "Rite of Nostalgy", "$icon_tflippy_follower$", "follower", "Gain old feelings by praising The Creator");
		AddRequirement(s.requirements, "blob", "foodcan", "Scrub Chow", 1);
		s.customButton = true;
		s.buttonwidth = 2;	
		s.buttonheight = 2;
		
		s.spawnNothing = true;
	}
	
	AddIconToken("$icon_tflippy_offering_0$", "AltarTFlippy_Icons.png", Vec2f(24, 24), 0);
	{
		ShopItem@ s = addShopItem(this, "Reverting saw", "$icon_tflippy_offering_0$", "offering_saw", "Revert a saw.");
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 250);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 4);
		s.customButton = true;
		s.buttonwidth = 1;	
		s.buttonheight = 1;
		
		s.spawnNothing = true;
	}
	AddIconToken("$icon_tflippy_offering_1$", "AltarTFlippy_Icons.png", Vec2f(24, 24), 1);
	{
		ShopItem@ s = addShopItem(this, "Boowb", "$icon_tflippy_offering_1$", "offering_boowb", "See a boowb!");
		AddRequirement(s.requirements, "blob", "hoob", "hoob", 1);
		s.customButton = true;
		s.buttonwidth = 1;	
		s.buttonheight = 1;
		
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Retro Bobby Gun", "$smgr$", "smgr", "An old submachine gun.\n\nUses Lowcal Rounds.");
		AddRequirement(s.requirements, "blob", "smg", "Bobby Gun", 1);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Retro Boomstick", "$boomstickr$", "boomstickr", "You see this? An old boomstick! The twelve-gauge double-barreled Bobington.\n\nUses Shotgun Shells.");
		AddRequirement(s.requirements, "blob", "boomstick", "Boomstick", 1);
		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Retro Lever Action Rifle", "$leverrifler$", "leverrifler", "An old and speedy lever action rifle.\n\nUses Highcal Rounds.");
		AddRequirement(s.requirements, "blob", "leverrifle", "Lever Rifle", 1);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Retro RPG", "$rpgr$", "rpgr", "An old RPG with 4 barrels.\n\nUses Grenades.");
		AddRequirement(s.requirements, "blob", "rpg", "RPG", 1);
		AddRequirement(s.requirements, "blob", "illegalgunpart", "Definitely Legal Gun Part", 1);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Retro MegaGun", "$minigunr$", "minigunr", "An old MEGAgun, boy!\n\nUses Gatling Ammo.");
		AddRequirement(s.requirements, "blob", "minigun", "MegaGun", 1);
		AddRequirement(s.requirements, "blob", "illegalgunpart", "Definitely Legal Gun Part", 1);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
}

void onTick(CBlob@ this)
{
	const bool server = isServer();
	const bool client = isClient();

	f32 power = this.get_f32("deity_power");
	if (power < 0.00f)
	{
		this.set_f32("deity_power", 0);
		power = 0;
	}
	this.setInventoryName("Altar of TFlippy\n\nNostalgy feel: " + Maths::Min(1000, Maths::Max(1, power/100)) + " hoob"+(Maths::Max(1, power/100) == 1?"":"s")+" of 1000" + "\nGun reload bonus: +" + (Maths::Min(power * 0.00003f, 0.35f)*100) + "%\n"+(this.get_u8("sprite_frame")==14?"Bonus: explosives weigh much less":""));
	const f32 radius = 64.00f + ((power / 100.00f) * 8.00f);
	this.SetLightRadius(radius);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (caller is null) return;
 	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton(27, Vec2f(0, -10), this, this.getCommandID("turn_sounds"), "Turn sounds off/on", params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("sync_frame"))
	{
		bool init = params.read_bool();
		if (!init)
		{
			if (isServer())
			{
				CBitStream stream;
				stream.write_bool(true);
				stream.write_u8(this.get_u8("sprite_frame"));
				this.SendCommand(this.getCommandID("sync_frame"), stream);
			}
		}
		else
		{
			if (isClient())
			{
				u8 frame = params.read_u8();
				this.set_u8("sprite_frame", frame);
				this.getSprite().SetFrameIndex(frame);
			}
		}
	}
	else if (cmd == this.getCommandID("sync_deity"))
	{
		if (isClient())
		{
			u8 deity;
			u16 blobid;
			f32 power;

			if (!params.saferead_u8(deity)) return;
			if (!params.saferead_u16(blobid)) return;
			if (!params.saferead_f32(power)) return;
			this.set_f32("deity_power", power);
			
			CBlob@ b = getBlobByNetworkID(blobid);
			if (b is null) return;
			b.set_u8("deity_id", deity);
			if (b.getPlayer() is null) return;
			b.getPlayer().set_u8("deity_id", deity);
		}
	}
	else if (cmd == this.getCommandID("turn_sounds"))
	{
		u16 caller;
		if (params.saferead_netid(caller))
		{
			CBlob@ b = getBlobByNetworkID(caller);
			if (isClient() && b.isMyPlayer() && this.getSprite() !is null)
			{
				this.getSprite().SetEmitSoundPaused(!this.getSprite().getEmitSoundPaused());
			}
		}
	}
	else if (cmd == this.getCommandID("shop made item"))
	{
		u16 caller, item;
		if (params.saferead_netid(caller) && params.saferead_netid(item))
		{
			string data = params.read_string();
			CBlob@ callerBlob = getBlobByNetworkID(caller);
			if (callerBlob !is null)
			{
				CPlayer@ callerPlayer = callerBlob.getPlayer();
				if (callerPlayer !is null)
				{
					if (data == "follower")
					{
						for (u8 i = 0; i < 24; i++)
						{
							ParticleAnimated("LargeSmoke", this.getPosition() + Vec2f(XORRandom(32) - 16, XORRandom(32) - 16),
								Vec2f(0.0f, -0.5f).RotateBy(15*i), 0, 1.00f + (XORRandom(10) * 0.01f), 2 + XORRandom(3), 0, false);
						}

						this.add_f32("deity_power", 100);
						
						if (isServer())
						{
							this.set_u8("sprite_frame", XORRandom(14));
							if (XORRandom(100) <= 5) this.set_u8("sprite_frame", 14); // 5% chance for fil's cat head
							CBitStream stream;
							stream.write_bool(true);
							stream.write_u8(this.get_u8("sprite_frame"));
							this.SendCommand(this.getCommandID("sync_frame"), stream);
						}
						
						if (isClient())
						{
							CBlob@ localBlob = getLocalPlayerBlob();
							if (localBlob !is null)
							{
								if (this.getDistanceTo(localBlob) < 128)
								{
									this.getSprite().PlaySound("drunk_fx4", 1.0f, 1.1f);
								}
							}
						}
						
						if (isServer())
						{
							callerPlayer.set_u8("deity_id", Deity::tflippy);
							callerBlob.set_u8("deity_id", Deity::tflippy);

							CBitStream params;
							params.write_u8(Deity::tflippy);
							params.write_u16(callerBlob.getNetworkID());
							params.write_f32(this.get_f32("deity_power"));
							this.SendCommand(this.getCommandID("sync_deity"), params);
						}
					}
					else
					{
						if (data == "offering_saw")
						{	
							if (isServer())
							{
								CBlob@ item = server_CreateBlob("saw", callerBlob.getTeamNum(), this.getPosition());
								callerBlob.server_Pickup(item);
							}
							
							if (isClient())
							{
								this.getSprite().PlaySound("ChaChing.ogg", 2.00f, 0.85f);
							}
						}
						else if (data == "offering_boowb")
						{	
							if (isServer())
							{
								for (u8 i = 0; i < getPlayersCount(); i++)
								{
									if (getPlayer(i) is null || getPlayer(i).getBlob() is null || (i != getPlayersCount() - 1 && XORRandom(getPlayersCount()/2) != 0)) continue;
									CBlob@ item = server_CreateBlob("boowb", callerBlob.getTeamNum(), getPlayer(i).getBlob().getPosition());
									break;
								}
							}
							
							if (isClient())
							{
								this.getSprite().PlaySound("ChaChing.ogg", 2.00f, 0.85f);
							}
						}
						else
						{
							if (isServer())
							{
								CBlob@ item = server_CreateBlob(data, callerBlob.getTeamNum(), callerBlob.getPosition());
								callerBlob.server_Pickup(item);
							}

							if (isClient())
							{
								this.getSprite().PlaySound("ChaChing.ogg", 2.00f, 0.85f);
							}
						}
					}
				}				
			}
		}
	}
}