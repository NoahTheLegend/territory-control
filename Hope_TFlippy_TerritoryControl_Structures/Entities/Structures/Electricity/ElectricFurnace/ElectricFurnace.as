#include "MakeMat.as";

void onInit(CSprite@ this)
{
	// Building
	this.SetZ(-50); //-60 instead of -50 so sprite layers are behind ladders
}

const string[] matNames = { 
	"mat_wood",
	"mat_copper",
	"mat_iron",
	"mat_gold",
	"mat_titanium",
	"mat_ironingot"
};

const string[] matNamesResult = { 
	"mat_coal",
	"mat_copperingot",
	"mat_ironingot",
	"mat_goldingot",
	"mat_titaniumingot",
	"mat_steelingot"
};

const int[] matRatio = { 
	30,
	10,
	10,
	30,
	20,
	6
};

const int[] coalRatio = {
	0,
	0,
	0,
	0,
	0,
	0
};

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 90;

	this.Tag("ignore extractor");
	this.Tag("builder always hit");
	this.Tag("hassound");

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("InductionFurnace_Loop.ogg");
		sprite.SetEmitSoundVolume(0.275f);
		sprite.SetEmitSoundSpeed(1.0f);
		sprite.SetEmitSoundPaused(false);
	}

	this.addCommandID("incmultiplier");
	this.addCommandID("decmultiplier");
	u8 syncmultiplier = 0;
	if (isServer() && this.get_u8("multiplier") > 1)
		syncmultiplier = this.get_u8("multiplier");
	this.set_u8("multiplier", 1);
	if (syncmultiplier > 1) this.set_u8("multiplier", syncmultiplier);
	this.set_u8("step", 1);
}

void onTick(CBlob@ this)
{
	if (!this.get_bool("state") && this.hasTag("togglesupport")) return; // set this to stop structure
	//printf("step "+this.get_u8("step")+" mp "+this.get_u8("multiplier"));
	if (this.get_u8("step") == this.get_u8("multiplier")) //&& this.get_u32("elec") > 1000)
	{
		for (u8 i = 0; i < 6; i++) // i < matNames.length
		{
			if (this.hasBlob(matNames[i], matRatio[i]*this.get_u8("multiplier")) && (coalRatio[i] == 0 || this.hasBlob("mat_coal", coalRatio[i])))
			{
				if (isServer())
				{
					CBlob @mat = server_CreateBlob(matNamesResult[i], -1, this.getPosition());
					mat.server_SetQuantity(3*this.get_u8("multiplier"));
					mat.Tag("justmade");
					mat.Tag("from_forge");
					this.TakeBlob(matNames[i], matRatio[i]*this.get_u8("multiplier"));
					if (coalRatio[i] > 0) this.TakeBlob("mat_coal", coalRatio[i]*this.get_u8("multiplier"));

					CMap@ map = this.getMap();
					if (map !is null)
					{
						CBlob@ blob = map.getBlobAtPosition(this.getPosition() + Vec2f(0, 28.0f));
						if (blob !is null && blob.getName() == "storage")
						{
							if (!blob.server_PutInInventory(mat))
							{
								mat.setPosition(blob.getPosition());
							}
						}
					}
				}
				
				//this.add_u32("elec", -(this.get_u16("energy_consumption")*this.get_u8("multiplier")));

				this.getSprite().PlaySound("ProduceSound.ogg");
				this.getSprite().PlaySound("BombMake.ogg");
			}
		}
		this.set_u8("step", 1);
	}
	else
		this.set_u8("step", this.get_u8("step") + 1);

	if (this.get_u8("step") > this.get_u8("multiplier"))
		this.set_u8("step", 1);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (this.isOverlapping(caller) && (this.get_bool("state") || !this.hasTag("togglesupport")))
	{
		u8 multp = this.get_u8("multiplier");

		CBitStream params;
		if (multp < 10)
		{
			CBitStream params;
			CButton@ button = caller.CreateGenericButton(16, Vec2f(-8, 0.0f), this, this.getCommandID("incmultiplier"), "Increase multiplier to "+(multp+1), params);
			button.deleteAfterClick = false;
		}
		if (multp > 1)
		{
			CButton@ button = caller.CreateGenericButton(19, Vec2f(8, 0.0f), this, this.getCommandID("decmultiplier"), "Decrease multiplier to "+(multp-1), params);
			button.deleteAfterClick = false;
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("incmultiplier"))
	{
		u8 multp = this.get_u8("multiplier");
		if (multp < 10)
			this.set_u8("multiplier", multp+1);
		this.set_u8("step", 1);
	}
	else if (cmd == this.getCommandID("decmultiplier"))
	{
		u8 multp = this.get_u8("multiplier");
		if (multp > 1)
			this.set_u8("multiplier", multp-1);
		this.set_u8("step", 1);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;

	if(blob.hasTag("justmade")){
		blob.Untag("justmade");
		return;
	}

	for(int i = 0; i < 5; i += 1) // i < matNames.length!
	if (!blob.isAttached() && blob.hasTag("material") && blob.getName() == matNames[i])
	{
		if (isServer()) this.server_PutInInventory(blob);
		if (isClient()) this.getSprite().PlaySound("bridge_open.ogg");
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

	this.getCurrentScript().tickFrequency = 90 / (this.exists("gyromat_acceleration") ? this.get_f32("gyromat_acceleration") : 1);
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	if(blob.getName() != "gyromat") return;

	this.getCurrentScript().tickFrequency = 90 / (this.exists("gyromat_acceleration") ? this.get_f32("gyromat_acceleration") : 1);
}