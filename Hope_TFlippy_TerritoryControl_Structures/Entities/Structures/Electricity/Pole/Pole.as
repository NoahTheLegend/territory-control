#include "Hitters.as";
#include "MinableMatsCommon.as";

const f32 ELECTRICITY_PICK_RADIUS = 64.0f;
const f32 ELECTRICITY_GIVE_RADIUS = 64.0f;
const u16 ELECTRICITY_GIVE_AMOUNT = 50;

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
	mats.push_back(HarvestBlobMat(2.0f, "mat_ironingot")); //NO FILE
	mats.push_back(HarvestBlobMat(2.0f, "mat_copperingot")); //NO FILE
	mats.push_back(HarvestBlobMat(5.0f, "mat_copperwire")); //NO FILE
	this.set("minableMats", mats);

	this.addCommandID("sync_prep");
	this.addCommandID("sync");

	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	this.Tag("builder always hit");
	
	this.Tag("ignore blocking actors");
	this.Tag("pole");
	this.Tag("conveyor"); // needed for easy preventing spamming in 1 block
	this.Tag("draw_wire");
	this.Tag("inline_block");

	this.set_bool("inactive", false);
	
	this.set_u16("inherit_id", 0);
	this.set_f32("max_dist", ELECTRICITY_PICK_RADIUS);

	FindInherit(this);

	this.set_u32("elec", 0);
	server_Sync(this);
}

void FindInherit(CBlob@ this)
{
	CBlob@[] inherit;
	CMap@ map = this.getMap();
	if (map is null) return;
	f32 stage_dist = ELECTRICITY_PICK_RADIUS / 8;
	bool dobreak = false;
	u16 inherit_id = 0;
	u16 collector_id = 0;
	for (u8 i = 1; i < 9; i++)
	{
		//printf(""+(stage_dist*i));
		map.getBlobsInRadius(this.getPosition(), stage_dist*i, inherit);
		for (u16 i = 0; i < inherit.length; i++)
		{
			CBlob@ picked = inherit[i];
			if (picked is null) continue;
			if (picked is this) continue;
			if (picked.get_u16("inherit_id") == this.getNetworkID()) continue;
			if (picked.getName() == "collector" || (picked.getName() == "pole" && picked.get_u16("collector_id") != 0))
			{
				if (picked.getDistanceTo(this) < ELECTRICITY_PICK_RADIUS)
				{
					if (picked.getName() == "collector")
					{
						collector_id = picked.getNetworkID();
					}
					else
					{
						collector_id = picked.get_u16("collector_id");
					}
					inherit_id = picked.getNetworkID();
					dobreak = true;
					break;
				}
			}
		}
		if (dobreak) break;
	}
	//printf(""+inherit_id);
	//printf(""+collector_id);
	this.set_u16("inherit_id", inherit_id);
	this.set_u16("collector_id", collector_id);
}

void onTick(CBlob@ this)
{
	if ((this.get_u32("elec") == 0 && getGameTime()%90==0) || (this.get_u32("elec") > 0 && getGameTime()%30==0))
	{
		//printf(""+this.get_u16("inherit_id"));
		//printf(""+this.get_u16("collector_id"));

		if (this.get_u32("elec") == 0)
		{
			if (this.get_u16("inherit_id") == 0 
			|| getBlobByNetworkID(this.get_u16("inherit_id")) is null)
			{
				FindInherit(this);
			}
		}

		CBlob@ inherit = getBlobByNetworkID(this.get_u16("inherit_id"));
		if (inherit !is null && !inherit.get_bool("inactive") && this.getDistanceTo(inherit) < ELECTRICITY_PICK_RADIUS)
		{
			this.set_u32("elec", inherit.get_u32("elec"));
		}
		else
		{
			this.set_u32("elec", 0);
			//this.set_u16("inherit_id", 0);
			//this.set_u16("collector_id", 0);
		}

		u16 collector_id = this.get_u16("collector_id");

		CBlob@ collector = getBlobByNetworkID(collector_id);
		if (collector_id == 0 || collector is null || collector.getName() != "collector")
		{
			if (inherit !is null)
			{
				u16 inherit_collector_id = inherit.get_u16("collector_id");
				CBlob@ inherit_collector = getBlobByNetworkID(inherit_collector_id);
				if (inherit_collector !is null && inherit_collector.getName() == "collector")
					this.set_u16("collector_id", inherit_collector_id);
				else this.set_u16("collector_id", 0);
			}
			else this.set_u16("collector_id", 0);
		}

		if (this.get_u32("elec") > 0)
		{
			CBlob@[] consumptions;
			if (getMap() !is null) getMap().getBlobsInRadius(this.getPosition(), ELECTRICITY_GIVE_RADIUS, consumptions);
		
			for (u16 i = 0; i < consumptions.length; i++)
			{
				CBlob@ consumer = consumptions[i];
				if (consumer is null) continue;
				if (!consumer.hasTag("consumes energy")) continue;
				if (consumer.get_u16("feed_id") != 0 && consumer.get_u16("feed_id") != this.getNetworkID()) continue;
	
				if (collector_id != 0)
				{
					if (collector !is null && collector.getName() == "collector")
					{
						u32 elec = collector.get_u32("elec");
						u32 consumer_elec = consumer.get_u32("elec");
						u32 consumer_elec_max = consumer.get_u32("elec_max");
						if (consumer_elec < consumer_elec_max && elec >= consumer_elec)
						{
							u32 diff = consumer_elec_max - consumer_elec;
							u32 amo = Maths::Min(consumer_elec_max - consumer_elec, ELECTRICITY_GIVE_AMOUNT * consumer.get_u8("consume_mod"));
							if (amo > elec) amo = elec;
							
							consumer.add_u32("elec", amo);
							//printf("BEFORE: "+elec);
							//if (collector.get_u32("elec") >= diff)
							if (collector.get_u32("elec") - amo < 0) collector.set_u32("elec", 0);
							else
								collector.add_u32("elec", -amo);
							//else collector.set_u32("elec", 0);
	
							//printf("GIVEN: "+amo);
							//printf("LEFT: "+collector.get_u32("elec"));

							consumer.set_u16("feed_id", this.getNetworkID());
						}
					}
				}
			}
		}
	}
}	

void onSetStatic(CBlob@ this, const bool isStatic)
{	
	if (!isStatic) return;
	FindInherit(this);

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
		CBitStream stream;

		stream.write_u32(this.get_u32("elec"));
		stream.write_u16(this.get_u16("inherit_id"));
		stream.write_u16(this.get_u16("collector_id"));

		this.SendCommand(this.getCommandID("sync"), stream);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("sync"))
	{
		if (isClient())
		{
			u32 elec;
			u16 inherit_id;
			u16 collector_id;

			if (!params.saferead_u32(elec)) return;
			if (!params.saferead_u16(inherit_id)) return;
			if (!params.saferead_u16(collector_id)) return;

			this.set_u32("elec", elec);
			this.set_u16("inherit_id", inherit_id);
			this.set_u16("collector_id", collector_id);
		}
	}
}