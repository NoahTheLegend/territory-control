#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "GramophoneCommon.as";

const f32 min_pitch = 0.5f;
const f32 max_pitch = 1.95f;

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);

	CSprite@ sprite = this.getSprite();
	sprite.SetZ(-50);
	sprite.SetAnimation("default");

	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
	this.Tag("change team on fort capture");

	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(9, 7));
	this.set_string("shop description", "Disc Shop");
	this.set_u8("shop icon", 15);

	for (int i = 0; i < records.length; i++)
	{
		GramophoneRecord record = records[i];
		if (record !is null)
		{
			AddIconToken("$musicdisc"+i+"$", "MusicDisc.png", Vec2f(8, 8), i);
			{
				ShopItem@ s = addShopItem(this, record.name, "$musicdisc"+i+"$", i + "", "Buy [" + record.name + "] pirated disc!", true);
				AddRequirement(s.requirements, "coin", "", "Coins", 40);

				s.spawnNothing = true;
			}
		}
	}

	this.set_u8("track_id", 255);
	this.addCommandID("set_disc");

	this.addCommandID("pitch_scroll");
	this.addCommandID("request_sync");
	if (!this.exists("pitch")) this.set_f32("pitch", 1.0f);

	if (isClient())
	{
		CBitStream params;
		this.SendCommand(this.getCommandID("request_sync"), params);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	this.set_bool("shop available", this.isOverlapping(caller));

	CBlob@ carried = caller.getCarriedBlob();

	u8 track_id = this.get_u8("track_id");
	bool insert = carried !is null && carried.getName() == "musicdisc";
	bool eject = carried is null && track_id != 255;

	f32 pitch = this.get_f32("pitch");

	if (pitch < max_pitch)
	{
		CBitStream params;
		params.write_bool(false);
		{CButton@ button = caller.CreateGenericButton(16, Vec2f(0, -18), this, this.getCommandID("pitch_scroll"), "Increase pitch ("+Maths::Round(pitch*100)+"%)", params);}
	}

	if (pitch > min_pitch)
	{
		CBitStream params;
		params.write_bool(true);
		{CButton@ button = caller.CreateGenericButton(19, Vec2f(0, 10), this, this.getCommandID("pitch_scroll"), "Decrease pitch ("+Maths::Round(pitch*100)+"%)", params);}
	}

	CBitStream params;
	params.write_u16(caller.getNetworkID());

	if (insert)
	{
		CButton@ button = caller.CreateGenericButton(17, Vec2f(0, -8), this, this.getCommandID("set_disc"), "Insert", params);
	}
	else if (eject)
	{
		CButton@ button = caller.CreateGenericButton(9, Vec2f(0, -8), this, this.getCommandID("set_disc"), "Eject", params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if(cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("ConstructShort");

		u16 caller, item;

		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;

		string name = params.read_string();
		CBlob@ callerBlob = getBlobByNetworkID(caller);

		if (callerBlob is null) return;

		if (isServer())
		{
			CPlayer@ ply = callerBlob.getPlayer();
		
			string[] spl = name.split("-");

			if (spl[0] == "coin")
			{
				CPlayer@ callerPlayer = callerBlob.getPlayer();
				if (callerPlayer is null) return;

				callerPlayer.server_setCoins(callerPlayer.getCoins() +  parseInt(spl[1]));
			}
			else if (name.findFirst("mat_") != -1)
			{
				CPlayer@ callerPlayer = callerBlob.getPlayer();
				if (callerPlayer is null) return;

				CBlob@ mat = server_CreateBlob(spl[0], callerBlob.getTeamNum(), this.getPosition());

				if (mat !is null)
				{
					mat.Tag("do not set materials");
					mat.server_SetQuantity(parseInt(spl[1]));
					if (!callerBlob.server_PutInInventory(mat))
					{
						mat.setPosition(callerBlob.getPosition());
					}
				}
			}
			else
			{
				CBlob@ blob =server_CreateBlobNoInit("musicdisc");

				if (blob is null) return;
				blob.setPosition(this.getPosition());
			
				if (!blob.canBePutInInventory(callerBlob))
				{
					callerBlob.server_Pickup(blob);
				}
				else if (callerBlob.getInventory() !is null && !callerBlob.getInventory().isFull())
				{
					callerBlob.server_PutInInventory(blob);
				}

				blob.server_setTeamNum(-1);
				blob.set_u8("track_id", u8(parseInt(spl[0])));
				blob.Init();	
			}
		}
	}
	else if (cmd == this.getCommandID("pitch_scroll"))
	{
		if (!isServer()) return;

		bool decrease = params.read_bool();
		this.add_f32("pitch", decrease ? -0.05f : 0.05f);
		this.Sync("pitch", true);
	}
	else if (cmd == this.getCommandID("request_sync"))
	{
		if (!isServer()) return;
		this.Sync("pitch", true);
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