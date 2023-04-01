#include "MinableMatsCommon.as";

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getShape().getConsts().mapCollisions = false;
	this.getShape().SetOffset(Vec2f(-1.0,-3.0));
	
	//this.set_u16("capacity", 100);
	this.Tag("smart_storage");
	this.Tag("builder always hit");
	this.Tag("remote_storage");

	HarvestBlobMat[] mats = {};
	mats.push_back(HarvestBlobMat(10.0f, "mat_copperingot"));
	mats.push_back(HarvestBlobMat(10.0f, "mat_ironingot"));
	mats.push_back(HarvestBlobMat(5.0f, "mat_steelingot"));
	this.set("minableMats", mats);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	/*if (caller !is null)
	{
		if ((this.getTeamNum() == caller.getTeamNum() || this.getTeamNum() > 6) && caller.isOverlapping(this))
		{
			CInventory @inv = caller.getInventory();
			if (inv !is null)
			{
				if (inv.getItemsCount() > 0)
				{
					CBitStream params;
					params.write_u16(caller.getNetworkID());
					caller.CreateGenericButton(28, Vec2f(0, -10), this, this.getCommandID("sv_store"), "Store", params);
				}
			}
		}
	}*/
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return (forBlob.getTeamNum() == this.getTeamNum() || this.getTeamNum() > 6) && forBlob.isOverlapping(this);
}