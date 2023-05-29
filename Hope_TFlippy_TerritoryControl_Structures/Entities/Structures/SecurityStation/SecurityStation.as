#include "Hitters.as";
#include "HittersTC.as";
#include "MakeMat.as";
#include "MaterialCommon.as";

// A script by TFlippy

void onInit(CBlob@ this)
{
	this.Tag("builder always hit");
	this.Tag("change team on fort capture");

	this.getSprite().SetZ(-10.0f);
	this.set_u32("security_link_id", u32(this.getNetworkID()));
	this.set_bool("open", false);

	if (isServer())
	{
		CBlob@ card = server_CreateBlobNoInit("securitycard");
		card.setPosition(this.getPosition());
		card.set_u32("security_link_id", this.get_u32("security_link_id"));
		card.server_setTeamNum(this.getTeamNum());
		card.Init();
		//printf("" + card.get_u32("security_link_id"));
	}

	this.set_u32("elec", 0);

	this.setInventoryName("Security Station #" + this.get_u32("security_link_id"));
	this.addCommandID("copy_card");
	this.addCommandID("open_access");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	//if (this.get_u32("elec") < 50) return;
	if (caller !is null && caller.isOverlapping(this))
	{
		CBlob@[] blobs;
		getBlobsByTag("security_linkable", @blobs);

		CBlob@ card = caller.getCarriedBlob();

		if (this.get_bool("open") || (card !is null && card.getName() == "securitycard" && card.get_u32("security_link_id") == this.get_u32("security_link_id")))
			{
				u32 link = this.get_u32("security_link_id");
				for (int i = 0; i < blobs.length; i++)
				{
					CBlob@ blob = blobs[i];
					if (blob !is null)
					{
						if (card is blob) continue; // button appears on the card
						// Vec2f deltaPos = (blob.getPosition() - this.getPosition()) * 0.50f;
						u32 blob_link = blob.get_u32("security_link_id");

						CBitStream params;
						params.write_bool(!blob.get_bool("security_state"));

						blob.addCommandID("security_set_state");
						CButton@ button = caller.CreateGenericButton(11, Vec2f(0, -8), blob, blob.getCommandID("security_set_state"), "Toggle", params);
						button.enableRadius = 512;
						button.SetEnabled((blob_link == link || blob_link == 0) && blob.getTeamNum() != 250);
					}
				}
			}

		if (card !is null && card.getName() == "securitycard")
		{
			if (card.isAttachedTo(caller))
			{
				CBitStream params;
				params.write_u32(card.get_u32("security_link_id"));
				params.write_u16(caller.getNetworkID());
				CButton@ button = caller.CreateGenericButton(11, Vec2f(0, -8), this, this.getCommandID("copy_card"), "Copy card", params);
			}
			if (card.getName() == "securitycard" && card.get_u32("security_link_id") == this.get_u32("security_link_id"))
			{
				CBitStream params;
				string name = this.get_bool("open") ? "Enable security cards." : "Disable security cards.";
				CButton@ button = caller.CreateGenericButton(8, Vec2f(0, -16), this, this.getCommandID("open_access"), name, params);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("copy_card"))
	{
		u32 id = params.read_u32();

		CBlob@ caller = getBlobByNetworkID(params.read_u16());

		if (caller !is null && isServer())
		{
			CBlob@ card = server_CreateBlobNoInit("securitycard");
			card.setPosition(this.getPosition());
			card.server_setTeamNum(this.getTeamNum());
			card.set_u32("security_link_id", id);
			card.Init();
			caller.getPlayer().server_setCoins(caller.getPlayer().getCoins() - 200);
		}
		//this.add_u32("elec", -125);
	}
	else if (cmd == this.getCommandID("open_access"))
	{
		this.set_bool("open", !this.get_bool("open"));
	}
}