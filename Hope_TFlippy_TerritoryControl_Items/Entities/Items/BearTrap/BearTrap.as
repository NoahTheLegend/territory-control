#include "Hitters.as";
#include "HittersTC.as";
#include "Knocked.as"

void onInit(CBlob@ this)
{
	this.set_bool("armed", false);
	this.Tag("ignore fall");
	this.Tag("heavy weight");
	this.set_u32("next_pick", 0);
	
	this.addCommandID("beartrap_arm");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("beartrap_arm"))
	{
		bool state = params.read_bool();
		this.set_bool("armed", state);
		
		state ? this.getSprite().PlaySound("TrapArmed.ogg") : this.getSprite().PlaySound("TrapSnap.ogg");
		this.getSprite().SetFrameIndex(state ? 1 : 0);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (caller.getTeamNum() == this.getTeamNum())
	{
		if (this.getMap().rayCastSolid(caller.getPosition(), this.getPosition())) return;
		
		bool armed = this.get_bool("armed");
		
		CBitStream params;
		params.write_bool(!armed);
		CButton@ button = caller.CreateGenericButton(11, Vec2f(0, 0), this, this.getCommandID("beartrap_arm"), (armed ? "Disarm" : "Arm"), params);
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{

}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null && this.get_bool("armed") && blob.hasTag("flesh") && !isKnocked(blob))
	{
		SetKnocked(blob, 210);
		this.set_u32("next_pick", getGameTime()+270);
		this.getSprite().PlaySound("TrapSnap.ogg");
		this.set_bool("armed", false);
		this.getSprite().SetFrameIndex(0);
		
		if (isServer())
		{
			this.server_Hit(blob, this.getPosition(), Vec2f(0, 0), 1.0f, Hitters::builder, true);
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return getGameTime() >= this.get_u32("next_pick");
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return damage;
}

void onThisAddToInventory(CBlob@ this, CBlob@ carrier)
{
	if (carrier !is null) this.inventoryIconFrame = this.get_bool("armed") ? 1 : 0;
}
