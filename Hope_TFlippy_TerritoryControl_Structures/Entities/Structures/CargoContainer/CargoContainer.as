#include "CargoAttachmentCommon.as"

void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-10.0f);
	
	
	this.inventoryButtonPos = Vec2f(-22, 0);
	this.set_Vec2f("store_offset", Vec2f(4, 0));
	this.Tag("remote_storage");
	this.Tag("extractable");
	this.Tag("ignore extractor");

	this.addCommandID("own_access");
	this.addCommandID("switch_access");
	this.addCommandID("sync");
	this.addCommandID("init_sync");
	this.addCommandID("store inventory");

	this.set_u16("owner_player_id", 0);
	this.set_bool("locked", false);
}

void onTick(CBlob@ this)
{
	if (isClient() && this.getTickSinceCreated() == 1)
	{
		CBitStream params;
		this.SendCommand(this.getCommandID("init_sync"), params);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getTeamNum() < 7) return;
	if (caller.getPlayer() is null) return;

	if (caller is null) return;
	if (this.getDistanceTo(caller) > 32.0f) return;
	
	CBitStream params;
	params.write_u16(caller.getPlayer().getNetworkID());

	if (this.get_u16("owner_player_id") == 0)
	{
		CButton@ own = caller.CreateGenericButton(11, Vec2f(12, 0), this, 
				this.getCommandID("own_access"), "Set personal access", params);
	}

	if (isOwner(this, caller))
	{
		CButton@ switchbutton = caller.CreateGenericButton(8, Vec2f(12, 0), this, 
				this.getCommandID("switch_access"), this.get_bool("locked") ? "Unlock" : "Lock", params);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		TryToAttachCargo(this, blob);
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool isOwner(CBlob@ this, CBlob@ blob)
{
	if (blob.getPlayer() is null) return false;
	return this.get_u16("owner_player_id") == blob.getPlayer().getNetworkID();
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return forBlob !is null && (this.getTeamNum() >= 100 ? (isOwner(this, forBlob) || !this.get_bool("locked")) : this.getTeamNum() == forBlob.getTeamNum());	
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("sync"))
	{
		if (!isClient()) return;

		u16 pid = params.read_u16();
		bool locked = params.read_bool();

		this.set_u16("owner_player_id", pid);
		this.set_bool("locked", locked);
	}
	else if (cmd == this.getCommandID("store inventory"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null && isServer())
		{
			CInventory @inv = caller.getInventory();
			if (caller.getName() == "builder")
			{
				CBlob@ carried = caller.getCarriedBlob();
				if (carried !is null)
				{
					// TODO: find a better way to check and clear blocks + blob blocks || fix the fundamental problem, blob blocks not double checking requirement prior to placement.
					if (carried.hasTag("temp blob"))
					{
						carried.server_Die();
					}
				}
			}
			
			if (inv !is null)
			{
				while (inv.getItemsCount() > 0)
				{
					CBlob@ item = inv.getItem(0);
					if (!this.server_PutInInventory(item))
					{
						caller.server_PutInInventory(item);
						break;
					}
				}
			}
		}
	}
	else if (cmd == this.getCommandID("init_sync"))
	{
		if (!isServer()) return;

		Sync(this);
	}
	else if (cmd == this.getCommandID("own_access"))
	{
		if (!isServer()) return;

		u16 pid = params.read_u16();
		CPlayer@ p = getPlayerByNetworkId(pid);
		
		if (p is null) return;

		this.set_u16("owner_player_id", pid);
		this.set_bool("locked", true);

		Sync(this);
	}
	else if (cmd == this.getCommandID("switch_access"))
	{
		if (!isServer()) return;

		this.set_bool("locked", !this.get_bool("locked"));
		Sync(this);
	}
}

void Sync(CBlob@ this)
{
	if (!isServer()) return;

	CBitStream params;
	params.write_u16(this.get_u16("owner_player_id"));
	params.write_bool(this.get_bool("locked"));

	this.SendCommand(this.getCommandID("sync"), params);
}

void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu@ gridmenu)
{
	if (forBlob is null) return;
	if (forBlob.getControls() is null) return;

	Vec2f mscpos = forBlob.getControls().getMouseScreenPos(); 

	Vec2f MENU_POS = mscpos+Vec2f(-424,-168);
	CGridMenu@ sv = CreateGridMenu(MENU_POS, this, Vec2f(1, 1), "Store ");
	
	CBitStream params;
	params.write_u16(forBlob.getNetworkID());
	CGridButton@ store = sv.AddButton("$str$", "Store ", this.getCommandID("store inventory"), Vec2f(1, 1), params);
}