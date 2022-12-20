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
	
	this.set_string("Owner", "");
	this.addCommandID("sv_setowner");
	this.addCommandID("sv_store");
	this.addCommandID("clear_owners");
	this.addCommandID("open_addmenu");
	this.addCommandID("server_sync");

	for (u8 i = 0; i < 35; i++)
	{
		this.addCommandID("add_owner_"+i);
	}

	HarvestBlobMat[] mats = {};
	mats.push_back(HarvestBlobMat(4.0f, "mat_ironingot"));
	this.set("minableMats", mats);
	this.set_string("Owner", "");
	this.set_string("Owners", "");

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
	this.inventoryButtonPos = Vec2f(0, 0);

	if (this.getMap().rayCastSolid(caller.getPosition(), this.getPosition())) return;
	
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
		CButton@ button = caller.CreateGenericButton(5, Vec2f(-10, 0), this, this.getCommandID("open_addmenu"), "Add an owner", params);
		CButton@ button1 = caller.CreateGenericButton(9, Vec2f(10, 0), this, this.getCommandID("clear_owners"), "Clear all owners", params);
	}
}

void AddMenu(CBlob@ this, CBlob@ caller)
{
	string[] empty = {};
	string[] temp_usernames = {};
	if (this.get("temp_usernames", temp_usernames)) temp_usernames = empty;
	if (caller !is null && caller.isMyPlayer())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());

		Vec2f grid = Vec2f(Maths::Max(getPlayersCount(), 0),1);
		if (getPlayersCount() > 10) grid = Vec2f(Maths::Max(getPlayersCount()/2, 0), 2);
		else if (getPlayersCount() > 20) grid = Vec2f(Maths::Max(getPlayersCount()/3, 0), 3);

		CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f), this, grid, "Add an owner");
		string usernames = "";
		string owners = this.get_string("Owners");

		CBitStream stream;
		for (u16 i = 0; i < getPlayersCount(); i++)
		{
			CPlayer@ p = getPlayer(i);
			if (p is null) continue;
			temp_usernames.push_back(p.getUsername());
			usernames += p.getUsername()+"_";
		}
		//printf(usernames);
		stream.write_string(usernames);
		
		if (menu !is null)
		{
			menu.deleteAfterClick = true;
			for (u16 i = 0; i < getPlayersCount(); i++)
			{
				CPlayer@ p = getPlayer(i);
				if (p is null) continue;
				bool already_owner = false;
				if (p.getUsername() == this.get_string("Owner")) already_owner = true;

				string[] spl = owners.split("_");
				for (u16 i = 0; i < spl.length; i++)
				{
					if (p.getUsername() == spl[i]) already_owner = true;
				}

				CGridButton@ button = menu.AddButton("$icon_paper$", p.getUsername(), this.getCommandID("add_owner_"+i), Vec2f(1, 1), stream);
				if (already_owner && button !is null)
				{
					button.SetEnabled(false);
				}
			}
			this.set("temp_usernames", temp_usernames);
		}
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
	if (cmd == this.getCommandID("open_addmenu"))
	{
		u16 callerid;
		if (!params.saferead_u16(callerid)) return;
		CBlob@ caller = getBlobByNetworkID(callerid);
		if (caller is null) return;

		AddMenu(this, caller);
	}
	else if (cmd >= this.getCommandID("add_owner_0") && cmd <= this.getCommandID("add_owner_34"))
	{
		string usernames;
		if (!params.saferead_string(usernames)) return;
		string[] temp_usernames = {};
		string owners = this.get_string("Owners");
		
		if (!this.get("temp_usernames", temp_usernames)) return;

		for (u16 i = 0; i < getPlayersCount(); i++)
		{
			if (this.getCommandID("add_owner_"+i) == cmd)
			{
				//printf(""+temp_usernames[i]);
				if (temp_usernames.length <= i) continue;
				CPlayer@ p = getPlayer(i);
				if (p is null) return; // not needed to iterate further
				//printf("puser "+p.getUsername());
				//printf("temp "+temp_usernames[i]);
				if (p.getUsername() == temp_usernames[i]) // make sure this is a correct player
				{
					this.set_string("Owners", owners+p.getUsername()+"_");
					//printf(""+this.get_string("Owners"));
					return;
				}
			}
		}
	}
	else if (cmd == this.getCommandID("clear_owners"))
	{
		this.set_string("Owners", "");
	}
	if (isServer())
	{
		if (cmd == this.getCommandID("sv_setowner"))
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
						caller.server_PutOutInventory(item);
						this.server_PutInInventory(item);
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

	return forBlob.getPlayer().getUsername() == this.get_string("Owner");
}