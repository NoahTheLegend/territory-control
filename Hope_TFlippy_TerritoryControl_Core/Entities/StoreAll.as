void onInit(CBlob@ this)
{
	this.addCommandID("sv_store");
	AddIconToken("$str$", "StoreAll.png", Vec2f(16, 16), 0);
}

/*
void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	
	if (caller.getTeamNum() == this.getTeamNum())
	{
		CInventory @inv = caller.getInventory();
		if(inv is null) return;

		if(inv.getItemsCount() > 0)
		{
			params.write_u16(caller.getNetworkID());
			CButton@ buttonOwner = caller.CreateGenericButton(28, this.get_Vec2f("store_offset"), this, this.getCommandID("sv_store"), "Store", params);
		}
	}
}
*/

void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu@ gridmenu)
{
	if (forBlob is null) return;
	if (forBlob.getControls() is null) return;
	Vec2f mscpos = forBlob.getControls().getMouseScreenPos(); 

	Vec2f MENU_POS = mscpos+Vec2f(-275,-72);
	CGridMenu@ sv = CreateGridMenu(MENU_POS, this, Vec2f(1, 1), "Store ");
	
	CBitStream params;
	params.write_u16(forBlob.getNetworkID());
	CGridButton@ store = sv.AddButton("$str$", "Store ", this.getCommandID("sv_store"), Vec2f(1, 1), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	CBlob@ caller = getBlobByNetworkID(params.read_u16());

	if (isServer())
	{
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
						caller.server_PutOutInventory(item);
						this.server_PutInInventory(item);
					}
				}
			}
		}
	}


}