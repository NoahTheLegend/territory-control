#include "Knocked.as";

void onInit(CBlob@ this)
{
	this.addCommandID("set_id");
}

void onTick(CBlob@ this)
{
	if (this.getTickSinceCreated() == 10)
	{
		this.setInventoryName(this.getInventoryName()+" #"+this.get_u16("uav_netid"));
	}
	if (this.isAttached())
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		if(point !is null)
		{
			CBlob@ holder = point.getOccupied();
		
			if (holder !is null && getKnocked(holder) <= 0)
			{
				CSprite@ sprite = this.getSprite();
				const bool lmb = holder.isKeyJustPressed(key_action1) || point.isKeyPressed(key_action1);
				
				if (lmb)
				{
					CBlob@ uav = getBlobByNetworkID(this.get_u16("uav_netid"));
					if (uav !is null)
					{
						// this.getSprite().PlaySound("BeamTowerTargeter_Success.ogg", 0.50f, 1.00f);
					
						CBlob@ localBlob = getLocalPlayerBlob();
						if (localBlob !is null && localBlob is holder && localBlob.getPlayer() !is null)
						{
							CBitStream stream;
							stream.write_u16(localBlob.getPlayer().getNetworkID());
							stream.write_u16(localBlob.getNetworkID());
							uav.SendCommand(uav.getCommandID("offblast"), stream);
						}
					}
					else
					{
						this.getSprite().PlaySound("BeamTowerTargeter_Failed.ogg", 0.50f, 1.00f);
						if (isServer()) this.server_Die();
					}
				}
			}
		}
	}
}