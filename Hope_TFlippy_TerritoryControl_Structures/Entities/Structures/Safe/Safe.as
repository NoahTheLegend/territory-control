#include "MinableMatsCommon.as";

void onInit(CSprite@ this)
{
	this.SetZ(-60);
}

void onInit(CBlob@ this)
{
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 30;
	this.Tag("builder always hit");
	
	this.server_setTeamNum(-1);
	
	this.Tag("ignore extractor");
	this.Tag("ignore inserter");
	
	this.set_string("Owner", "");
	this.addCommandID("sv_setowner");
	this.addCommandID("sv_store");
	this.addCommandID("clear_owners");
	this.addCommandID("server_sync");
	this.addCommandID("sync_to_server");
	this.addCommandID("add_owner");

	HarvestBlobMat[] mats = {};
	mats.push_back(HarvestBlobMat(4.0f, "mat_ironingot"));
	this.set("minableMats", mats);
	this.set_string("Owner", "");
	this.set_string("Owners", "");

	this.Tag("remote_storage");

	if (isServer())
	{
		CBitStream stream;
		stream.write_string(this.get_string("Owner"));
		stream.write_string(this.get_string("Owners"));
		
		this.SendCommand(this.getCommandID("server_sync"), stream);
	}
}

void onTick(CBlob@ this)
{
	CPlayer@ owner = getPlayerByUsername(this.get_string("Owner"));
	if (owner !is null) 
	{
		this.setInventoryName(this.get_string("Owner") == "" ? "Nobody" : owner.getCharacterName() + "'s Personal Safe");
		this.server_setTeamNum(owner.getTeamNum());
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	this.inventoryButtonPos = Vec2f(0, 0);
	if (!caller.isOverlapping(this)) return;

	if (this.getMap().rayCastSolid(caller.getPosition(), this.getPosition())) return;
	
	CBlob@ blob = caller.getCarriedBlob();
	bool is_paper;
	if (blob !is null && blob.getName() == "paper") is_paper = true;

	CBitStream params;
	params.write_u16(caller.getNetworkID());

	bool has_access = false;
	string[] spl = this.get_string("Owners").split("_");
	for (u16 i = 0; i < spl.length; i++)
	{
		if (caller.getPlayer() !is null && caller.getPlayer().getUsername() == spl[i])
		{
			has_access = true;
			break;
		}
	}
	
	if (caller.getPlayer() is null) return; 
	
	if (caller.isOverlapping(this) && this.get_string("Owner") == "")
	{	
		CButton@ buttonOwner = caller.CreateGenericButton(9, Vec2f(0, 0), this, this.getCommandID("sv_setowner"), "Claim", params);
	}
	
	if (caller.getPlayer().getUsername() == this.get_string("Owner") || has_access)
	{
		CInventory @inv = caller.getInventory();
		if(inv is null) return;

		CBlob@ carried = caller.getCarriedBlob();
		if(carried is null && this.isOverlapping(caller))
		{
			if(inv.getItemsCount() > 0)
			{
				// params.write_u16(caller.getNetworkID()); // wtf why
				CButton@ buttonOwner = caller.CreateGenericButton(28, Vec2f(0, -10), this, this.getCommandID("sv_store"), "Store", params);
			}
		}
	}
	if (caller.getPlayer().getUsername() == this.get_string("Owner"))
	{
		CButton@ button1 = caller.CreateGenericButton(9, Vec2f(10, 0), this, this.getCommandID("clear_owners"), "Clear all owners", params);
		CButton@ button2 = caller.CreateGenericButton(11, Vec2f(-10, 0), this, this.getCommandID("add_owner"), "Add an owner (insert paper with username)", params);
		if (!is_paper && button2 !is null) button2.SetEnabled(false);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (isClient() && cmd == this.getCommandID("server_sync"))
	{
		string owner;
		string owners;
		if (!params.saferead_string(owner)) return;
		if (!params.saferead_string(owners)) return;
		this.set_string("Owner", owner);
		this.set_string("Owners", owners);
	}
	if (cmd == this.getCommandID("add_owner"))
	{
		u16 callerid;
		if (!params.saferead_u16(callerid)) return;
		CBlob@ caller = getBlobByNetworkID(callerid);
		if (caller is null) return;
		CBlob@ carried = caller.getCarriedBlob();
		if (carried is null || carried.getName() != "paper") return;

		string text = carried.get_string("text");
		this.set_string("Owners", this.get_string("Owners")+text+"_");
		if (isServer()) carried.server_Die();
	}
	else if (cmd == this.getCommandID("clear_owners"))
	{
		this.set_string("Owners", "");
	}
	if (isServer())
	{
		if (cmd == this.getCommandID("sync_to_server"))
		{
			string owners = params.read_string();
			this.set_string("Owners", owners);
			this.Sync("Owners", true);
		}
		else if (cmd == this.getCommandID("sv_setowner"))
		{
			if (this.get_string("Owner") != "") return;
		
			CBlob@ caller = getBlobByNetworkID(params.read_u16());
			if (caller is null) return;
			
			CPlayer@ player = caller.getPlayer();
			if (player is null) return;
			
			this.set_string("Owner", player.getUsername());
			this.server_setTeamNum(player.getTeamNum());
			this.Sync("Owner", true);

			// print("Set owner to " + this.get_string("Owner") + "; Team: " + this.getTeamNum());
		}
		
		if (cmd == this.getCommandID("sv_store"))
		{
			CBlob@ caller = getBlobByNetworkID(params.read_u16());
			if (caller !is null)
			{
				CInventory @inv = caller.getInventory();
				if (caller.getName() == "builder")
				{
					CBlob@ carried = caller.getCarriedBlob();
					if (carried !is null)
					{
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
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.getPlayer() !is null)
	{
		if (hitterBlob.getName() != "peasant") damage *= (hitterBlob.getPlayer().getUsername() == this.get_string("Owner") ? 5.0f : 1.0f);
		else damage = 0.01;
	}

	return damage;
	
	return damage * (hitterBlob.getPlayer() is null ? 1.0f : (hitterBlob.getPlayer().getUsername() == this.get_string("Owner") ? 5.0f : 1.0f));
}

void onDie(CBlob@ this)
{
	string owner = this.get_string("Owner");
	if (owner != "") 
	{
		CPlayer@ player = getPlayerByUsername(owner);
		if (player !is null) client_AddToChat("" + player.getCharacterName() + "'s Personal Safe has been destroyed!");
	}
	
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	if (forBlob.getPlayer() is null) return false;

	bool has_access = false;
	string[] spl = this.get_string("Owners").split("_");
	for (u16 i = 0; i < spl.length; i++)
	{
		if (forBlob.getPlayer() !is null && forBlob.getPlayer().getUsername() == spl[i])
		{
			has_access = true;
			break;
		}
	}

	return has_access || forBlob.getPlayer().getUsername() == this.get_string("Owner");
}