#include "Requirements.as";
#include "Requirements_Tech.as";
#include "ShopCommon.as";
#include "Knocked.as";
#include "Hitters.as";
#include "HittersTC.as";
#include "DeityCommon.as";

const SColor[] colors = 
{
	SColor(255, 255, 30, 30),
	SColor(255, 30, 255, 30),
	SColor(255, 30, 30, 255)
};

void onInit(CBlob@ this)
{
	this.set_u8("deity_id", Deity::gregor);

	this.addCommandID("turn_sounds");
	this.addCommandID("sync_deity");

	CSprite@ sprite = this.getSprite();
	// sprite.SetEmitSound("gregor_Music.ogg");
	// sprite.SetEmitSoundVolume(0.4f);
	// sprite.SetEmitSoundSpeed(1.0f);
	// sprite.SetEmitSoundPaused(false);
					
	this.set_Vec2f("shop menu size", Vec2f(4, 2));
	
	AddIconToken("$icon_gregor_follower$", "InteractionIcons.png", Vec2f(32, 32), 11);
	{
		ShopItem@ s = addShopItem(this, "Rite of gregor", "$icon_gregor_follower$", "follower", "Gain gregor's goodwill by offering him a bottle of vodka.");
		AddRequirement(s.requirements, "blob", "vodka", "Vodka", 1);
		s.customButton = true;
		s.buttonwidth = 2;	
		s.buttonheight = 2;
		
		s.spawnNothing = true;
	}
	
	AddIconToken("$icon_gregor_offering_0$", "AltarGregor_Icons.png", Vec2f(24, 24), 0);
	{
		ShopItem@ s = addShopItem(this, "Squat of Hobones", "$icon_gregor_offering_0$", "offering_hobo", "Bring this corpse back from the dead as a filthy hobo.");
		AddRequirement(s.requirements, "blob", "peasant", "Peasant's Corpse", 1);
		AddRequirement(s.requirements, "blob", "vodka", "Vodka", 1);
		AddRequirement(s.requirements, "blob", "ratburger", "Rat Burger", 1);
		s.customButton = true;
		s.buttonwidth = 1;	
		s.buttonheight = 1;
		
		s.spawnNothing = true;
	}
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
	if (cmd == this.getCommandID("turn_sounds"))
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
	else if (cmd == this.getCommandID("sync_deity"))
	{
		if (isClient())
		{
			u8 deity;
			u16 blobid;

			if (!params.saferead_u8(deity)) return;
			if (!params.saferead_u16(blobid)) return;
			
			CBlob@ b = getBlobByNetworkID(blobid);
			if (b is null) return;
			b.set_u8("deity_id", deity);
			if (b.getPlayer() is null) return;
			b.getPlayer().set_u8("deity_id", deity);
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
						this.add_f32("deity_power", 50);
						
						if (isClient())
						{
							// if (callerBlob.get_u8("deity_id") != Deity::mithrios)
							// {
								// client_AddToChat(callerPlayer.getCharacterName() + " has become a follower of gregor_builder.", SColor(255, 255, 0, 0));
							// }
							
							CBlob@ localBlob = getLocalPlayerBlob();
							if (localBlob !is null)
							{
								if (this.getDistanceTo(localBlob) < 128)
								{
									this.getSprite().PlaySound("Gregor_Offering.ogg", 2.00f, 1.00f);
									SetScreenFlash(255, 255, 255, 255, 3.00f);
								}
							}
						}
						
						if (isServer())
						{
							callerPlayer.set_u8("deity_id", Deity::gregor);
							callerBlob.set_u8("deity_id", Deity::gregor);

							CBitStream params;
							params.write_u8(Deity::gregor);
							params.write_u16(callerBlob.getNetworkID());
	
							this.SendCommand(this.getCommandID("sync_deity"), params);
						}
					}
					else
					{
						u8 deity_id = callerPlayer.get_u8("deity_id");
					
						if (data == "offering_hobo")
						{
							this.add_f32("deity_power", 25);
							if (isServer()) this.Sync("deity_power", false);
							
							if (isServer())
							{
								CMap@ map = getMap();
							
								float x = this.getPosition().x + (128 - XORRandom(256));
								Vec2f pos;
								
								if(map.rayCastSolid(Vec2f(x, 0.0f), Vec2f(x, map.tilemapheight * map.tilesize), pos))
								{
									CBlob@ artifact = server_CreateBlob("demonicartifact", this.getTeamNum(), pos);
									CBlob@ lightning = server_CreateBlob("lightningbolt", this.getTeamNum(), pos);
								}
							}
						}
					}
				}				
			}
		}
	}
}