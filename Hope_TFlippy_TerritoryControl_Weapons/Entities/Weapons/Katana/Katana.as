#include "Hitters.as";
#include "HittersTC.as";
#include "Knocked.as";

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.set_u32("next attack", 0);
	this.set_u32("next dash", 0);
	this.set_u32("dash time", 0);
	this.set_u16("holderid", 0);
	this.Tag("no_bullet_collision");

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1 | key_action2);
	}
	if (this.getSprite() !is null) this.getSprite().RotateBy(-45, Vec2f());
	this.getShape().SetRotationsAllowed(false);
}

void onInit(CSprite@ this)
{
	this.ScaleBy(0.75f, 0.75f);

	CSpriteLayer@ layer = this.addSpriteLayer("l", "KatanaEffect.png", 32, 32);
	if (layer !is null)
	{
		Animation@ anim = layer.addAnimation("KatanaEffect.png", 0, false);
		int[] frames = {0,1,2,3,4,5};
		if (anim !is null)
		{
			anim.AddFrames(frames);
			layer.SetAnimation(anim);
		}
		layer.SetOffset(Vec2f(0, -4.0f));
		layer.SetRelativeZ(-10.0f);
		layer.SetVisible(false);
	}
}

void onTick(CBlob@ this)
{	
	if (this.isAttached())
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		CBlob@ holder = point.getOccupied();

		if (holder is null) return;
		this.set_u16("holderid", holder.getNetworkID());

		CMap@ map = this.getMap();
		if (map is null) return;
		if (this.hasTag("dash"))
		{
			CBlob@[] dashhit;
			if (getGameTime()%8==0 && !this.isOnLadder()
			&& this.getVelocity().x >= 2.0f || this.getVelocity().x <= 2.0f)
			{
				map.getBlobsInRadius(this.getPosition(), 8.0f, dashhit);
				for (u16 i = 0; i < dashhit.length; i++)
				{
					CBlob@ e = dashhit[i];
					if (e is null || e is holder || !e.hasTag("flesh")) continue;
					if (isServer()) holder.server_Hit(e, e.getPosition(), Vec2f(), 0.825f, Hitters::sword, true);
				}
			}
		}

		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			CSpriteLayer@ l = sprite.getSpriteLayer("l");
			l.SetFacingLeft(!this.isFacingLeft());
			if (!this.hasTag("faceleft") && holder.isFacingLeft())
			{
				this.Tag("faceleft");
				sprite.ResetTransform();
				sprite.RotateBy(45, Vec2f());
				sprite.ScaleBy(0.85f, 0.85f);
			}
			else if (this.hasTag("faceleft") && !holder.isFacingLeft())
			{
				this.Untag("faceleft");
				sprite.ResetTransform();
				sprite.RotateBy(-45, Vec2f());
				sprite.ScaleBy(0.85f, 0.85f);
			}
			if (this.get_u32("next attack") > getGameTime())
			{
				bool faceleft = this.isFacingLeft();
				u32 diff = this.get_u32("next attack") - getGameTime();
				Vec2f v = faceleft ? Vec2f(-8.0f, 4.0f) : Vec2f(8.0f, 4.0f);

				if (diff >= 12)
				{
					sprite.RotateBy(faceleft?-20:20, v);
					if (l !is null)
					{
						l.SetVisible(true);
						if (diff == 15) l.SetFrameIndex(5);
						else if (diff == 14) l.SetFrameIndex(5);
						else if (diff == 13) l.SetFrameIndex(0);
						else if (diff == 12) l.SetFrameIndex(0);
					}
				}
				else if (diff < 10 && diff >= 7)
				{
					if (l !is null)
					{
						l.SetVisible(false);
					}
					sprite.RotateBy(faceleft?20:-20, v);
				}
				else if (diff <= 1)
				{
					
					sprite.ResetTransform();
					sprite.RotateBy(faceleft?45:-45, Vec2f());
					sprite.ScaleBy(0.85f, 0.85f);
				}

				return;
			}
		}
		
		if (getKnocked(holder) <= 0)
		{		
			if (point.isKeyPressed(key_action1) && getGameTime() > this.get_u32("dash time"))
			{
				u8 team = holder.getTeamNum();
				
				HitInfo@[] hitInfos;
				if (getMap().getHitInfosFromArc(this.getPosition(), -(holder.getAimPos() - this.getPosition()).Angle(), 90, 24, this, @hitInfos))
				{
					for (uint i = 0; i < hitInfos.length; i++)
					{
						CBlob@ blob = hitInfos[i].blob;
						if (blob !is null && blob.hasTag("flesh"))
						{
							if (isServer())
							{
								holder.server_Hit(blob, blob.getPosition(), Vec2f(), 1.0f, Hitters::sword, true);
							}
						}
					}
				}
				
				this.set_u32("next attack", getGameTime() + 15);
			}
			if (point.isKeyJustPressed(key_action2) && getGameTime() > this.get_u32("next dash"))
			{
				holder.Tag("no_flesh_collision");
				this.Tag("dash");
				holder.setVelocity(Vec2f(holder.isFacingLeft()?Maths::Min(-5.0f, holder.getVelocity().x):Maths::Max(holder.getVelocity().x, 5.0f), -1.0f));
				holder.AddForce(Vec2f(holder.isFacingLeft() ? this.getMass()*((this.isOnGround()?-80.0f:-20.0f)) : this.getMass()*((this.isOnGround()?80.0f:20.0f)), this.getMass()*(this.isOnGround()?-40.0f:-7.5f)));
				this.set_u32("dash time", getGameTime() + 10);
				this.set_u32("next dash", getGameTime() + 225);
			}
		}
		if (getGameTime() > this.get_u32("dash time"))
		{
			if (sprite !is null && getGameTime() == this.get_u32("dash time")+1)
			{
				CSpriteLayer@ l = sprite.getSpriteLayer("l");
				if (l !is null)
				{
					sprite.ResetTransform();
					sprite.RotateBy(holder.isFacingLeft()?45:-45, Vec2f());
					sprite.ScaleBy(0.85f, 0.85f);
					l.SetVisible(false);
					l.ResetTransform();
				}
			}
			this.Untag("dash");
			holder.Untag("no_flesh_collision");
		}
		else
		{
			if (sprite !is null)
			{
				CSpriteLayer@ l = sprite.getSpriteLayer("l");
				if (l !is null)
				{
					l.SetVisible(true);
					sprite.RotateBy(holder.isFacingLeft()?-45:45, Vec2f());
					l.RotateBy(holder.isFacingLeft()?-45:45, Vec2f());
				}
			}
		}
	}
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (inventoryBlob is null) return;
	inventoryBlob.Untag("no_flesh_collision");
	this.Untag("dash");
}

void onDetach(CBlob@ this,CBlob@ detached,AttachmentPoint@ attachedPoint)
{
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		CSpriteLayer@ l = sprite.getSpriteLayer("l");
		if (l !is null) l.SetVisible(false);
	}

	detached.Untag("noLMB");
	detached.Untag("no_flesh_collision");
	this.Untag("dash");
	// detached.Untag("noShielding");
}

void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{
	attached.Tag("noLMB");
	// attached.Tag("noShielding");
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob !is null && blob.isCollidable()) return true;
	return false;
}

