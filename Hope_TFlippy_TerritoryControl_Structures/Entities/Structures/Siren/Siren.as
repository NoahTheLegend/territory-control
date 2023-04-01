// A script by TFlippy & Pirate-Rob

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";
#include "BuilderHittable.as";
#include "Hitters.as";
#include "GramophoneCommon.as";

void onInit(CBlob@ this)
{
	this.set_u8("track_id", 255);
	this.addCommandID("set_disc");
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.set_string("ogg", "siren_leveled.ogg");

	this.Tag("builder always hit");
	
	this.getCurrentScript().tickFrequency = 45;
	
	this.set_bool("isActive", false);
	this.addCommandID("sv_toggle");
	this.addCommandID("cl_toggle");
}

void onInit(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	this.SetEmitSound(blob.get_string("ogg"));
	this.SetEmitSoundVolume(5.0f);
	this.SetEmitSoundSpeed(1.0f);
	
	this.SetEmitSoundPaused(!this.getBlob().get_bool("isActive"));
}

void onTick(CBlob@ this)
{
	if (isServer())
	{
		CBlob@[] blobs;
		getBlobsByTag("aerial", @blobs);
		
		Vec2f pos = this.getPosition();
		
		for (int i = 0; i < blobs.length; i++)
		{
			if ((blobs[i].getPosition() - pos).LengthSquared() < (1000.0f * 1000.0f) && blobs[i].getTeamNum() != this.getTeamNum())
			{
				if (this.get_bool("isActive")) return;
			
				this.set_bool("isActive", true);
			
				CBitStream stream;
				stream.write_bool(true);
				this.SendCommand(this.getCommandID("cl_toggle"), stream);
	
				return;
			}
		}
		
		if (!this.get_bool("isActive")) return;
		
		this.set_bool("isActive", false);
	
		CBitStream stream;
		stream.write_bool(false);
		this.SendCommand(this.getCommandID("cl_toggle"), stream);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (isServer())
	{
		if (cmd == this.getCommandID("sv_toggle"))
		{
			bool active = params.read_bool();
			
			this.set_bool("isActive", active);

			CBitStream stream;
			stream.write_bool(active);
			this.SendCommand(this.getCommandID("cl_toggle"), stream);
		}
	}

	if (cmd == this.getCommandID("set_disc"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		CBlob@ carried = caller.getCarriedBlob();
		CSprite@ sprite = this.getSprite();
		
		u8 current_track_id = this.get_u8("track_id");
		
		if (current_track_id != 255)
		{
			this.set_string("ogg", "siren_leveled.ogg");
			sprite.SetEmitSound("siren_leveled.ogg");
			sprite.SetEmitSoundPaused(!this.get_bool("isActive"));
			if (this.get_bool("isActive")) sprite.SetAnimation("on");
			if (isServer())
			{
				CBlob@ disc = server_CreateBlobNoInit("musicdisc");
				disc.setPosition(this.getPosition() + Vec2f(0, -4));
				disc.set_u8("track_id", this.get_u8("track_id"));
				disc.server_setTeamNum(this.getTeamNum());
				disc.Init();
			}
		}
		
		if (carried !is null && carried.getName() == "musicdisc")
		{
			u8 track_id = carried.get_u8("track_id");
			if (track_id < records.length)
			{
				this.set_u8("track_id", track_id);
			
				if (isServer()) 
				{
					carried.server_Die();
				}
				
				GramophoneRecord record = records[track_id];
				if (record !is null)
				{
					sprite.RewindEmitSound();
					this.set_string("ogg", record.filename);
					if (this.get_bool("isActive")) sprite.SetAnimation("on");
					sprite.SetEmitSound(record.filename);
					sprite.SetEmitSoundPaused(!this.get_bool("isActive"));
					sprite.SetEmitSoundVolume(5.0f);
				}
			}
		}
		else
		{
			this.set_u8("track_id", 255);
			this.set_string("ogg", "siren_leveled.ogg");
			sprite.SetEmitSoundPaused(!this.get_bool("isActive"));
			sprite.SetEmitSound("siren_leveled.ogg");
			
			sprite.SetAnimation(this.get_bool("isActive") ? "on" : "off");
			CSpriteLayer@ sl_disc = sprite.getSpriteLayer("disc");
			if (sl_disc !is null)
			{
				sl_disc.SetVisible(false);
			}
		}
	}
	
	if (isClient())
	{
		if (cmd == this.getCommandID("cl_toggle"))
		{		
			bool active = params.read_bool();
		
			this.set_bool("isActive", active);
		
			CSprite@ sprite = this.getSprite();

			if (active) sprite.SetAnimation("on");
		
			sprite.PlaySound("LeverToggle.ogg");
			sprite.SetEmitSoundPaused(!active);
			sprite.SetAnimation(active ? "on" : "off");
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBlob@ carried = caller.getCarriedBlob();

	u8 track_id = this.get_u8("track_id");
	bool insert = carried !is null && carried.getName() == "musicdisc";
	bool eject = carried is null && track_id != 255;

	CBitStream params;
	params.write_u16(caller.getNetworkID());

	if (insert)
	{
		CButton@ button = caller.CreateGenericButton(17, Vec2f(0, 0), this, this.getCommandID("set_disc"), "Insert", params);
	}
	else if (eject)
	{
		CButton@ button = caller.CreateGenericButton(9, Vec2f(0, 0), this, this.getCommandID("set_disc"), "Eject", params);
	}
}

void onDie(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSoundPaused(true);
}

// void GetButtonsFor(CBlob@ this, CBlob@ caller)
// {
	// if (!this.isOverlapping(caller)) return;
	
	// CBitStream params;
	// params.write_bool(!this.get_bool("isActive"));
	
	// CButton@ buttonEject = caller.CreateGenericButton(11, Vec2f(0, -8), this, this.getCommandID("sv_toggle"), (this.get_bool("isActive") ? "Turn Off" : "Turn On"), params);
// }