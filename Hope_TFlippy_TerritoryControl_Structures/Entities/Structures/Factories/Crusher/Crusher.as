#include "MakeMat.as";
#include "CustomBlocks.as";

void onInit(CSprite@ this)
{
	// Building
	this.SetZ(-50); //-60 instead of -50 so sprite layers are behind ladders
}

const string[] matNames = { 
	"mat_stone",
	"mat_dirt"
};

const string[] matNamesResult = { 
	"mat_concrete",
	"mat_sulphur"
};

const int[] matRatio = { // also change amount in CrusherAnim (51th line)
	100,
	100
};

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_biron);
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 45;

	this.Tag("ignore extractor");
	this.Tag("builder always hit");
}

void onTick(CBlob@ this)
{
	if (!this.get_bool("state")) return;
	//if (this.get_u32("elec") <= 100) return;
	for (int i = 0; i < matNames.length; i++)
	{
		if (this.hasBlob(matNames[i], matRatio[i]))
		{
			if (isServer())
			{
				CBlob@ mat = server_CreateBlob(matNamesResult[i], -1, this.getPosition());
				mat.server_SetQuantity(50);
				mat.Tag("justmade");
				this.TakeBlob(matNames[i], matRatio[i]);
			}
			if (isClient())
			{
				this.getSprite().PlaySound("ProduceSound.ogg", 0.85f, 0.8f);
				this.getSprite().PlaySound("BombMake.ogg", 0.85f, 0.8f);
			}
			//this.add_u32("elec", -50);
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || this is null) return;
	if (!this.get_bool("state")) return;

	if (blob.hasTag("justmade"))
	{
		blob.Untag("justmade");
		return;
	}

	if (!blob.isAttached() && blob.hasTag("material"))
	{
		string config = blob.getName();
		for (int i = 0; i < matNames.length; i++)
		{
			if (config == matNames[i])
			{
				if (isServer()) this.server_PutInInventory(blob);
				if (isClient()) this.getSprite().PlaySound("bridge_open.ogg");
			}
		}
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	// return (forBlob.getTeamNum() == this.getTeamNum() && forBlob.isOverlapping(this));
	return forBlob !is null && forBlob.isOverlapping(this);
}

void onAddToInventory( CBlob@ this, CBlob@ blob )
{
	if(blob.getName() != "gyromat") return;

	this.getCurrentScript().tickFrequency = 45 / (this.exists("gyromat_acceleration") ? this.get_f32("gyromat_acceleration") : 1);
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	if(blob.getName() != "gyromat") return;

	this.getCurrentScript().tickFrequency = 45 / (this.exists("gyromat_acceleration") ? this.get_f32("gyromat_acceleration") : 1);
} 