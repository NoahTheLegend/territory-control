#include "Hitters.as";
#include "MinableMatsCommon.as";

const f32 ELECTRICITY_PICK_RADIUS = 64.0f;

void onInit(CBlob@ this)
{
	//if (isServer()
	//&& getMap().getBlobAtPosition(this.getPosition()) !is null
	//&& getMap().getBlobAtPosition(this.getPosition()).hasTag("overlap_allowed")) this.server_Die(); 

	this.getSprite().SetZ(50);
	this.getShape().SetRotationsAllowed(false);
	this.getShape().getConsts().waterPasses = true;
	
	this.Tag("place norotate");

	HarvestBlobMat[] mats = {}; //These numbers are the TOTAL amount of mats you get from mining the blob fully
	mats.push_back(HarvestBlobMat(2.0f, "mat_steelingot")); //NO FILE
	mats.push_back(HarvestBlobMat(10.0f, "mat_copperwire")); //NO FILE
	this.set("minableMats", mats);

	this.addCommandID("sync_prep");
	this.addCommandID("sync");
	this.addCommandID("restart");
	this.addCommandID("state");

	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	this.Tag("builder always hit");

	this.set_u32("elec_max", 0);

	this.set_Vec2f("button_offset", Vec2f(-12, 8));
	
	this.Tag("ignore blocking actors");
	this.Tag("collector");
	this.Tag("conveyor"); // needed for easy preventing spamming in 1 block
	//this.Tag("draw_wire");
	this.Tag("inline_block");
	this.set_bool("inactive", false);

	this.getCurrentScript().tickFrequency = 1;

	CheckInactive(this);

	this.set_u32("elec", 0);
	server_Sync(this);
}

void CheckInactive(CBlob@ this)
{
	CBlob@[] collectors;
	getBlobsByTag("collector", collectors);
	if (collectors.length > 0)
	{
		for (u16 i = 0; i < collectors.length; i++)
		{
			CBlob@ collector = collectors[i];
			if (collector is null) continue;
			if (collector is this) continue;
			if (this.getDistanceTo(collector) > ELECTRICITY_PICK_RADIUS) continue;
			this.set_bool("inactive", true);
			break;
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBitStream params;
	if (this.get_bool("inactive") && caller !is null && this.isOverlapping(caller))
	{
		CButton@ button = caller.CreateGenericButton(11, Vec2f(0, 0), this, this.getCommandID("restart"), "Restart collector", params);
	}
}

void onTick(CBlob@ this)
{
	if (!this.get_bool("state"))
	{
		this.set_bool("inactive", true);
	}
	if (this.get_u32("elec") > 250000) this.set_u32("elec", 0);
	if (getGameTime()%30==0)
	{
		//printf(""+this.get_u32('elec'));
		//this.set_u32("elec", 1350);
		if (this.get_bool("inactive"))
		{
			this.setInventoryName("Inactive");
			return;
		}

		CBlob@[] generators;
		CBlob@[] input;
		getBlobsByTag("generator", generators);
		if (generators.length > 0)
		{
			for (u16 i = 0; i < generators.length; i++)
			{
				CBlob@ generator = generators[i];
				if (generator is null) continue;
				if (generator.get_u16("consume_id") != 0 && generator.get_u16("consume_id") != this.getNetworkID()) continue;
				if (generator.getTeamNum() < 7 && generator.getTeamNum() != this.getTeamNum()) continue;

				if (this.getDistanceTo(generator) > ELECTRICITY_PICK_RADIUS) continue;
				input.push_back(generator);
			}
		}

		u32 elec_max = 0;
		for (u8 i = 0; i < input.length; i++)
		{
			CBlob@ generator = input[i];
			if (generator is null) continue;
			generator.set_u16("consume_id", this.getNetworkID());
			u32 elec = this.get_u32("elec");
			if (elec < this.get_u32("elec_max"))
			{
				u32 generator_elec = generator.get_u32("elec");
				u32 res = elec + generator_elec;
				if (res > this.get_u32("elec_max")) generator_elec -= res - this.get_u32("elec_max");

				this.add_u32("elec", generator_elec);
				this.Sync("elec", true);
				generator.add_u32("elec", -generator_elec);
				generator.Sync("elec", true);
			}
			elec_max += generator.get_u32("elec_max");
		}

		this.set_u32("elec_max", elec_max);
	}
}	

void onSetStatic(CBlob@ this, const bool isStatic)
{	
	if (!isStatic) return;

	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.SetZ(-10);

	sprite.PlaySound("/build_door.ogg");
}	

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	this.getSprite().SetZ(300);
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::builder) damage *= 20.0f;
	return damage;
}


void server_Sync(CBlob@ this)
{
    if (isServer())
    {
        CBitStream params;
        params.write_u32(this.get_u32("elec"));
		params.write_u32(this.get_u32("elec_max"));
		params.write_bool(this.get_bool("inactive"));
        this.SendCommand(this.getCommandID("sync"), params);
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("sync"))
	{
		if (isClient())
		{
			u32 elec;
			u32 elec_max;
			bool inactive;

			if (!params.saferead_u32(elec)) return;
			if (!params.saferead_u32(elec_max)) return;
			if (!params.saferead_bool(inactive)) return;

			this.set_u32("elec", elec);
			this.set_u32("elec_max", elec_max);
			this.set_bool("inactive", inactive);
		}
	}
	else if (cmd == this.getCommandID("restart"))
	{
		this.setInventoryName("Collector");
		this.set_bool("inactive", false);
		this.set_bool("state", true);

		CheckInactive(this);
	}
}