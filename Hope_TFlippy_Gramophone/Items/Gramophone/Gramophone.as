// A script by TFlippy

#include "GramophoneCommon.as";
#include "CargoAttachmentCommon.as";

void onInit(CBlob@ this)
{
	this.set_u8("track_id", 255);
	this.addCommandID("set_disc");
	
	CSprite@ sprite = this.getSprite();
	sprite.SetZ(50);
	
	CSpriteLayer@ sl_disc = sprite.addSpriteLayer("disc", "MusicDisc.png", 8, 8);
	if (sl_disc !is null)
	{
		
		Animation@ anim = sl_disc.addAnimation("default", 0, true);
		
		for (int i = 0; i < records.length; i++)
		{
			anim.AddFrame(i);
		}
		
		sl_disc.SetVisible(false);
		sl_disc.SetOffset(Vec2f(0, 1));
		sl_disc.SetRelativeZ(-10);
	}
	
	// CSprite@ sprite = this.getSprite();
	// for (int i = 0; i < records.length; i++)
	// {
		// Animation@ anim = sprite.addAnimation("disc_" + i, 8, true);
		// anim.AddFrame(1);
		// anim.AddFrame(i);
	// }
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !blob.hasTag("helicopter");
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

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (inventoryBlob is null) return;

	CInventory@ inv = inventoryBlob.getInventory();

	if (inv is null) return;

	this.doTickScripts = true;
	inv.doTickScripts = true;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		TryToAttachCargo(this, blob);
	}
}