#include "Hitters.as";
#include "ParticleSparks.as";
#include "Knocked.as";

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.set_u32("next attack", 0);

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1);
	}
	
	// this.getSprite().addAnimation("honk", 0, false);
	if (this.getSprite() !is null) this.getSprite().SetRelativeZ(201);
}

void onTick(CBlob@ this)
{
	if (this.isAttached())
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		if(point is null){return;}
		CBlob@ holder = point.getOccupied();
		
		if (holder is null){return;}

		CSprite@ sprite = this.getSprite();
		if (sprite !is null && this.get_u32("animend") > getGameTime())
		{
			f32 l = this.get_f32("l");

			if (this.get_u32("animend") == getGameTime() + 19)
				sprite.RotateBy(24.0f*l, Vec2f(0, 2));
			else if (this.get_u32("animend") == getGameTime() + 18)
				sprite.RotateBy(24.0f*l, Vec2f(0, 2));
			else if (this.get_u32("animend") == getGameTime() + 17)
				sprite.RotateBy(16.0f*l, Vec2f(0, 2));
			else if (this.get_u32("animend") == getGameTime() + 14)
				sprite.RotateBy(-16.0f*l, Vec2f(0, 2));
			else if (this.get_u32("animend") == getGameTime() + 11)
				sprite.RotateBy(16.0f*l, Vec2f(0, 2));
			else if (this.get_u32("animend") == getGameTime() + 8)
				sprite.RotateBy(-16.0f*l, Vec2f(0, 2));
			else if (this.get_u32("animend") == getGameTime() + 7)
				sprite.RotateBy(-24.0f*l, Vec2f(0, 2));
			else if (this.get_u32("animend") == getGameTime() + 6)
			{
				sprite.RotateBy(-24.0f*l, Vec2f(0, 2));
				sprite.ResetTransform();
			}
		}

		if (getKnocked(holder) <= 0 && !holder.isAttached()) //Cant wrench while stunned
		{
			if (holder.isKeyPressed(key_action1) || point.isKeyPressed(key_action1))
			{
				if (this.get_u32("next attack") > getGameTime()) return;
				Vec2f pos = holder.getAimPos();
				
				if ((pos - this.getPosition()).getLength() < 48) //Range
				{
					getMap().rayCastSolidNoBlobs(this.getPosition(), pos, pos);
					CBlob@ blob = getMap().getBlobAtPosition(pos);
					if (blob !is null && blob.getHealth() < blob.getInitialHealth()) //Must be damaged
					{
						if (blob.hasTag("vehicle") || blob.hasTag("chicken_turret") || blob.getShape().isStatic() && !blob.hasTag("nature"))
						{
							this.set_u32("animend", getGameTime() + 20);
							f32 l = 1.0;
							if (this.isFacingLeft()) l = -1.0;
							this.set_f32("l", l);
							if (isServer())
							{
								blob.Tag("MaterialLess"); //No more materials can be harvested by mining this (prevents abuse with stone doors)
								if (blob.getShape().isStatic())
								{
									blob.server_Heal(6); //Remember this is halved
								}
								else
								{
									blob.server_Heal(3); //Only heals a small amount, bizaarly the actual healing amount is half of this
								}
								//print("health"+blob.getHealth() + " "+ blob.getInitialHealth());
							}
							if (isClient())
							{
								sparks(blob.getPosition(), 1, 0.25f);
							}
						}
					}
				}
				
				this.set_u32("next attack", getGameTime() + 20);
			}
		}
	}
}

void onDetach(CBlob@ this,CBlob@ detached,AttachmentPoint@ attachedPoint)
{
	detached.Untag("noLMB");
	CSprite@ sprite = this.getSprite();
	if (sprite !is null) sprite.ResetTransform();
}

void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{
	attached.Tag("noLMB");
	CSprite@ sprite = this.getSprite();
	if (sprite !is null) sprite.ResetTransform();
}