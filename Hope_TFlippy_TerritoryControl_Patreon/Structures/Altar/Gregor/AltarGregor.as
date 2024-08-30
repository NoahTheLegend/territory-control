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
	sprite.SetEmitSound("Magic_AuraLoop04.ogg");
	sprite.SetEmitSoundVolume(1.0f);
	sprite.SetEmitSoundSpeed(1.0f);
	sprite.SetEmitSoundPaused(false);
					
	this.set_Vec2f("shop menu size", Vec2f(4, 2));
	
	AddIconToken("$icon_gregor_follower$", "InteractionIcons.png", Vec2f(32, 32), 11);
	{
		ShopItem@ s = addShopItem(this, "Rite of gregor", "$icon_gregor_follower$", "follower", "Gain Gregor's goodwill by offering him a bottle of vodka.");
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
		AddRequirement(s.requirements, "coin", "", "Coins", 1000);
		s.customButton = true;
		s.buttonwidth = 1;	
		s.buttonheight = 1;
		
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Infernal Stone", "$infernalstone$", "infernalstone", "It's hot!");
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 350);
		AddRequirement(s.requirements, "blob", "fire_cards", "Fire Card", 4);
		AddRequirement(s.requirements, "coin", "", "Coins", 1000);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Mysterious Gadget", "$drone$", "drone", "Something is wrong here.");
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 100);
		AddRequirement(s.requirements, "blob", "steam_cards", "Steam Card", 2);
		AddRequirement(s.requirements, "coin", "", "Coins", 500);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Transmutation", "$mat_mithrilenriched$", "mat_mithrilenriched-7", "Transmutate 50 wilmet into 7 enriched mithril.");
		AddRequirement(s.requirements, "blob", "mat_wilmet", "Wilmet", 50);
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

		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;

		string name = params.read_string();
		CBlob@ callerBlob = getBlobByNetworkID(caller);
		CPlayer@ callerPlayer = callerBlob.getPlayer();

		if (callerBlob is null) return;

		// if (isServer())
		{
			string[] spl = name.split("-");

			if (spl[0] == "follower")
			{
				this.add_f32("deity_power", 50);
				
				if (isClient())
				{

					CBlob@ localBlob = getLocalPlayerBlob();
					if (localBlob !is null)
					{
						if (this.getDistanceTo(localBlob) < 128)
						{
							this.getSprite().PlaySound("packer_pack.ogg", 1.25f, 1.00f);
						}
					}
				}
				
				if (isServer())
				{
					callerPlayer.set_u8("deity_id", Deity::gregor);
					callerBlob.set_u8("deity_id", Deity::gregor);

					CBitStream params1;
					params1.write_u8(Deity::gregor);
					params1.write_u16(callerBlob.getNetworkID());
	
					this.SendCommand(this.getCommandID("sync_deity"), params1);
				}
			}
			if (isServer())
			{
				if (spl[0] == "coin")
				{
					CPlayer@ callerPlayer = callerBlob.getPlayer();
					if (callerPlayer is null) return;

					callerPlayer.server_setCoins(callerPlayer.getCoins() +  parseInt(spl[1]));
				}
				else if (name.findFirst("mat_") != -1)
				{
					CPlayer@ callerPlayer = callerBlob.getPlayer();
					if (callerPlayer is null) return;

					CBlob@ mat = server_CreateBlob(spl[0]);

					if (mat !is null)
					{
						mat.Tag("do not set materials");
						mat.server_SetQuantity(parseInt(spl[1]));
						if (!callerBlob.server_PutInInventory(mat))
						{
							mat.setPosition(callerBlob.getPosition());
						}
					}
				}
				else
				{
					CBlob@ blob = server_CreateBlob(spl[0], callerBlob.getTeamNum(), this.getPosition());

					if (blob is null) return;

					if (!blob.canBePutInInventory(callerBlob))
					{
						callerBlob.server_Pickup(blob);
					}
					else if (callerBlob.getInventory() !is null && !callerBlob.getInventory().isFull())
					{
						callerBlob.server_PutInInventory(blob);
					}
				}
			}
		}
	}
}