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
	this.Tag("extractable");

	this.addCommandID("sv_store");
	AddIconToken("$str$", "StoreAll.png", Vec2f(16, 16), 0);

	HarvestBlobMat[] mats = {};
	mats.push_back(HarvestBlobMat(50.0f, "mat_wood"));
	this.set("minableMats", mats);	
}

void onTick(CBlob@ this)
{
	PickupOverlap(this);
}

void PickupOverlap(CBlob@ this)
{
	if (isServer())
	{
		Vec2f tl, br;
		this.getShape().getBoundingRect(tl, br);
		CBlob@[] blobs;
		this.getMap().getBlobsInBox(tl, br, @blobs);
		for (uint i = 0; i < blobs.length; i++)
		{
			CBlob@ blob = blobs[i];
			if (!blob.isAttached() && blob.isOnGround() && blob.hasTag("material"))
			{
				this.server_PutInInventory(blob);
			}
		}
	}
}
/*
void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (this.getMap().rayCastSolid(caller.getPosition(), this.getPosition())) return;

	CBitStream params;
	params.write_u16(caller.getNetworkID());

	CInventory @inv = caller.getInventory();
	if(inv is null) return;
	
	CBlob@ carried = caller.getCarriedBlob();
	if(carried is null && this.isOverlapping(caller))
	{
		if(inv.getItemsCount() > 0)
		{
			params.write_u16(caller.getNetworkID());
			CButton@ buttonOwner = caller.CreateGenericButton(28, Vec2f(0, -10), this, this.getCommandID("sv_store"), "Store", params);
		}
	}
}
*/
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
						CBlob @item = inv.getItem(0);
						caller.server_PutOutInventory(item);
						this.server_PutInInventory(item);
					}
				}
			}
		}
	}

}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return forBlob.isOverlapping(this);
}

void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu@ gridmenu)
{
	if (forBlob is null) return;
	if (forBlob.getControls() is null) return;
	Vec2f mscpos = forBlob.getControls().getMouseScreenPos(); 

	Vec2f MENU_POS = mscpos+Vec2f(-132,-48);
	CGridMenu@ sv = CreateGridMenu(MENU_POS, this, Vec2f(1, 1), "Store ");
	
	CBitStream params;
	params.write_u16(forBlob.getNetworkID());
	CGridButton@ store = sv.AddButton("$str$", "Store ", this.getCommandID("sv_store"), Vec2f(1, 1), params);
}