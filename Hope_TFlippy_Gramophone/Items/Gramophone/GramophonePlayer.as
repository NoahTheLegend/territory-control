#include "GramophoneCommon.as";

void onDie(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSoundPaused(true);
}

void onTick(CBlob@ this)
{
	if(isClient())
	{
		CSprite@ sprite = this.getSprite();

		u8 track_id = this.get_u8("track_id");

		if (track_id != 255)
		{
			GramophoneRecord@ record = records[track_id];
			if (record !is null && (s_musicvolume > 0 || !s_gamemusic))
			{
				sprite.SetEmitSoundPaused(false);
				sprite.SetEmitSoundVolume(s_gamemusic ? s_musicvolume * 2 : record.volume);
			}
			else sprite.SetEmitSoundPaused(true);
		}
	}
}


void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("set_disc"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		CBlob@ carried = caller.getCarriedBlob();
		CSprite@ sprite = this.getSprite();
		
		u8 current_track_id = this.get_u8("track_id");
		
		if (current_track_id != 255)
		{
			if (isServer())
			{
				CBlob@ disc = server_CreateBlobNoInit("musicdisc");
				disc.set_u8("track_id", this.get_u8("track_id"));
				disc.Init();
				disc.setPosition(this.getPosition() + Vec2f(0, -4));
				disc.setVelocity(Vec2f(0, -8));
				disc.server_setTeamNum(this.getTeamNum());
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
					sprite.SetEmitSound(record.filename);
					sprite.SetEmitSoundPaused(false);
					
					sprite.SetAnimation("playing");
					CSpriteLayer@ sl_disc = sprite.getSpriteLayer("disc");
					if (sl_disc !is null)
					{
						sl_disc.SetFrameIndex(track_id);
						sl_disc.SetVisible(true);
					}
				}
			}
		}
		else
		{
			this.set_u8("track_id", 255);
			sprite.SetEmitSoundPaused(true);
			
			sprite.SetAnimation("default");
			CSpriteLayer@ sl_disc = sprite.getSpriteLayer("disc");
			if (sl_disc !is null)
			{
				sl_disc.SetVisible(false);
			}
		}
	}
}