#include "Hitters.as";
#include "Knocked.as";

void onInit(CSprite@ this)
{
	Animation@ anim = this.addAnimation("default", 1, true);
	{
		int[] frames(4);
		for(int i = 0; i < 4; i++)
		{
			frames[i] = i;
		}
		anim.AddFrames(frames);
	}
	this.SetAnimation(anim);
}

void onInit(CBlob@ this)
{
    this.server_setTeamNum(XORRandom(6));

	this.Tag("ignore fall");
	this.set_u32("next attack", 0);

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1);
	}
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
					this.getSprite().PlaySound("amoamogus0.ogg", 0.4f);
				}
				
				this.set_u32("next attack", getGameTime() + 4 + XORRandom(10));
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
