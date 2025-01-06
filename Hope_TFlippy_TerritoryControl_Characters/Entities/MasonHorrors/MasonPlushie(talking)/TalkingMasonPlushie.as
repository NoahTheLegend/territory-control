#include "Hitters.as";
#include "Knocked.as";
#include "GenericButtonCommon.as"

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.set_u32("next attack", 0);
	this.addCommandID("ask");

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1);
	}

	CSprite@ sounds = this.getSprite();
}

void onTick(CBlob@ this)
{	
	if (this.isAttached())
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		CBlob@ holder = point.getOccupied();
		
		if (holder is null) return;

		if (getKnocked(holder) <= 0)
		{
			if (holder.isKeyPressed(key_action1) || point.isKeyPressed(key_action1))
			{
				if (this.get_u32("next attack") > getGameTime()) return;
			
				if (isClient())
				{
					this.getSprite().PlayRandomSound("build_wall.ogg", 1.0f, 1.0f);
				}
				
				this.set_u32("next attack", getGameTime() + 5);
			}
		}
	}
}

void onDetach(CBlob@ this,CBlob@ detached,AttachmentPoint@ attachedPoint)
{
	detached.Untag("noLMB");
}

void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{
	attached.Tag("noLMB");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (caller is null) return;
 	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton(14, Vec2f(0, 0), this, this.getCommandID("ask"), "Ask", params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if(cmd == this.getCommandID("ask"))
	{
		this.getSprite().PlayRandomSound("test", 2.0f, 0.90f);
	}
}