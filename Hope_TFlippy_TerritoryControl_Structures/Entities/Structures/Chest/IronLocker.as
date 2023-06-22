#include "MinableMatsCommon.as";
// A script by TFlippy

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
	this.addCommandID("sv_grab");
	AddIconToken("$str$", "StoreAll.png", Vec2f(16, 16), 0);

	HarvestBlobMat[] mats = {};
	mats.push_back(HarvestBlobMat(2.0f, "mat_ironingot"));
	this.set("minableMats", mats);
	this.set_string("Owner", "");
}

void onTick(CBlob@ this)
{
	CPlayer@ owner = getPlayerByUsername(this.get_string("Owner"));
	if (owner !is null) 
	{
		this.setInventoryName(this.get_string("Owner") == "" ? "Nobody" : owner.getCharacterName() + "'s Personal Locker");
		this.server_setTeamNum(owner.getTeamNum());
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	this.inventoryButtonPos = Vec2f(0, 0);

	if (this.getMap().rayCastSolid(caller.getPosition(), this.getPosition())) return;
	
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	
	if (caller.getPlayer() is null) return; 
	
	if (caller.isOverlapping(this) && this.get_string("Owner") == "")
	{	
		CButton@ buttonOwner = caller.CreateGenericButton(9, Vec2f(0, 0), this, this.getCommandID("sv_setowner"), "Claim", params);
	}
	
	if (caller.getPlayer().getUsername() == this.get_string("Owner"))
	{
		CInventory @inv = caller.getInventory();
		if(inv is null) return;

		CBlob@ carried = caller.getCarriedBlob();
		if(carried is null && this.isOverlapping(caller))
		{
			/*
			if(inv.getItemsCount() > 0)
			{
				// params.write_u16(caller.getNetworkID()); // wtf why
				CButton@ buttonOwner = caller.CreateGenericButton(28, Vec2f(0, -10), this, this.getCommandID("sv_store"), "Store", params);
			}
			*/
			if (this.getInventory() !is null && this.getInventory().getItemsCount() > 0)
			{
				CButton@ buttonOwner = caller.CreateGenericButton(16, Vec2f(0, 16), this, this.getCommandID("sv_grab"), "Grab all", params);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	CBlob@ caller = getBlobByNetworkID(params.read_u16());
	if (isServer())
	{
		if (cmd == this.getCommandID("sv_setowner"))
		{
			if (this.get_string("Owner") != "") return;
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
		
		if (cmd == this.getCommandID("sv_grab"))
		{
			if (caller !is null)
			{
				CInventory @inv = this.getInventory();
				if (inv !is null)
				{
					while (inv.getItemsCount() > 0)
					{
						CBlob@ item = inv.getItem(0);
						if (!caller.server_PutInInventory(item))
						{
							this.server_PutOutInventory(item);
							break;
						}
					}
				}
			}
		}
	}

	if (caller !is null && caller.isMyPlayer())
	{
		caller.ClearGridMenus();
		caller.ClearButtons();
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

void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu@ gridmenu)
{
	if (forBlob is null) return;
	if (forBlob.getControls() is null) return;
	Vec2f mscpos = forBlob.getControls().getMouseScreenPos(); 

	Vec2f MENU_POS = mscpos+Vec2f(-80,-96);
	CGridMenu@ sv = CreateGridMenu(MENU_POS, this, Vec2f(1, 1), "Store ");
	
	CBitStream params;
	params.write_u16(forBlob.getNetworkID());
	CGridButton@ store = sv.AddButton("$str$", "Store ", this.getCommandID("sv_store"), Vec2f(1, 1), params);
}