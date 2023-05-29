#include "Hitters.as";
#include "MakeMat.as";
#include "Knocked.as";
#include "GunCommon.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.isAttached()) return 0;
	return damage;
}

void onInit(CBlob@ this)
{
	GunSettings settings = GunSettings();

	//General
	//settings.CLIP = 0; //Amount of ammunition in the gun at creation
	settings.TOTAL = 200; //Max amount of ammo that can be in a clip
	settings.FIRE_INTERVAL = 4; //Time in between shots
	settings.RELOAD_TIME = 120; //Time it takes to reload (in ticks)
	//settings.AMMO_BLOB = "mat_methane"; //Ammunition the gun takes
	this.set_string("ammoBlob", "mat_methane"); //Ammunition the gun takes (can be changed dynamically)

	//Bullet
	settings.B_PER_SHOT = 1; //Shots per bullet | CHANGE B_SPREAD, otherwise both bullets will come out together
	settings.B_SPREAD = 0; //the higher the value, the more 'uncontrollable' bullets get
	//settings.B_GRAV = Vec2f(0, 0.001); //Bullet gravity drop
	settings.B_SPEED = 14; //Bullet speed, STRONGLY AFFECTED/EFFECTS B_GRAV
	//settings.B_TTL = 100; //TTL = 'Time To Live' which determines the time the bullet lasts before despawning
	//settings.B_DAMAGE = 4.0f; //1 is 1 heart
	//settings.B_TYPE = HittersTC::bullet_high_cal; //Type of bullet the gun shoots | hitter

	//Recoil
	settings.G_RECOIL = 0; //0 is default, adds recoil aiming up
	//settings.G_RANDOMX = true; //Should we randomly move x
	//settings.G_RANDOMY = false; //Should we randomly move y, it ignores g_recoil
	settings.G_RECOILT = 7; //How long should recoil last, 10 is default, 30 = 1 second (like ticks)
	settings.G_BACK_T = 6; //Should we recoil the arm back time? (aim goes up, then back down with this, if > 0, how long should it last)

	//Sound
	settings.FIRE_SOUND = "FlamethrowerFire.ogg"; //Sound when shooting
	settings.RELOAD_SOUND = "FlamethrowerReload.ogg"; //Sound when reloading

	//Offset
	settings.MUZZLE_OFFSET = Vec2f(-18, -2); //Where the muzzle flash appears

	this.set("gun_settings", @settings);

	//Custom
	this.set_string("CustomCase", "");
	this.set_string("CustomFlash", "");
	this.set_u32("CustomGunRecoil", 0);
	this.set_string("ProjBlob", "methane");
	this.Tag("CustomSoundLoop");
	this.Tag("medium weight");
	this.Tag("gas immune");
	
	this.addCommandID("set_gas_type");
}

void onTick(CBlob@ this)
{
	GunSettings settings = GunSettings();
	bool error = false;
	
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (point is null) return;
	
	CBlob@ holder = point.getOccupied();
	if (holder is null) return;
	
	if (this.get_u8("clip") >= 1)
	{
		this.set_bool("can_change_gas_type", false);
	}
	else this.set_bool("can_change_gas_type", true);
	
	string ammoName = this.get_string("ammoBlob");
	this.getSprite().SetAnimation(ammoName);
	
	if (!ammoName.empty())
	{
		string[]@ tokens = ammoName.split("_");
		if (tokens.length > 0)
		{
			if (tokens.length > 1 && tokens[0] == "mat") 
			{
				if (tokens[1] != "methane")
				{
					string drug_name = tokens[1];
					
					this.set_string("ProjBlob", drug_name + "gas");
					
					if (tokens[1] == "gae") this.set_string("ProjBlob", "gae");
					else if (tokens[1] == "mustard") this.set_string("ProjBlob", "mustard");
				}
				else this.set_string("ProjBlob", "methane");
			}
		}
	}
	else
	{
		error = true;
		this.set_string("ammoBlob", "mat_methane");
		this.set_string("ProjBlob", "methane");
	}
	
	if (error)
	{
		const bool lmb = holder.isKeyJustPressed(key_action1) || point.isKeyJustPressed(key_action1);
		if (lmb)
		{
			if (isClient())
			{
				if (holder.isMyPlayer())
				{
					this.getSprite().PlaySound("NoAmmo.ogg", 1, 1);
				}
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	bool can_change = this.get_bool("can_change_gas_type");
	
	if ((this.getTeamNum() < 7 && (caller.getTeamNum() == this.getTeamNum())) || this.getTeamNum() > 6)
	{
		CBlob@ carried = caller.getCarriedBlob();
		if (carried !is null && carried.hasTag("mat_gas") && carried.getName() != "mat_acid" && can_change)
		{
			u16 carried_netid = carried.getNetworkID();
			CBitStream params;
			params.write_u16(carried_netid);
			caller.CreateGenericButton("$" + carried.getName() + "$", Vec2f(0, 0), this, this.getCommandID("set_gas_type"), "Change gas type!", params);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("set_gas_type"))
	{
		CBlob@ carried = getBlobByNetworkID(params.read_u16());
		string help_message = "Empty gas tank before changing gas type";

		if (carried !is null){
			this.set_string("ammoBlob", carried.getName());
			if (carried.getName() != "mat_methane") this.setInventoryName("Gas Spreader XS-65 " + "(" + carried.getInventoryName() + ")\n" + help_message);
			else this.setInventoryName("Gas Spreader XS-65\n" + help_message);
		}
	}
}

CBlob@ GetAmmoBlob(CBlob@ this)
{
	CInventory@ inv = this.getInventory();
	s32 size = inv.getItemsCount();
	for (s32 i = 0; i < size; i++)
	{
		CBlob@ item = inv.getItem(i);
		if (item !is null)
		{
			if (item.hasTag("mat_gas") && item.getName() != "mat_acid")
			{
				return item;
			}
		}
	}
	return null;
}