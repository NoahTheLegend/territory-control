const u32 ELECTRICITY_MAX = 4500;
const u32 ELECTRICITY_PROD = 250;

void onInit(CBlob@ this)
{
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 30;

	this.Tag("builder always hit");
	this.Tag("generator");

	this.addCommandID("sync_prep");
	this.addCommandID("sync");
	this.Tag("extractable");

	this.set_u32("elec_max", ELECTRICITY_MAX);
	this.set_u16("consume_id", 0);
	this.set_Vec2f("wire_offset", Vec2f(-12.5, -3.5));
	this.set_u32("do sound idk", 0);

	this.set_u32("elec", 0);
	//server_Sync(this);

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("lgenerator_loop.ogg");
		sprite.SetEmitSoundVolume(0.20f);
		sprite.SetEmitSoundPaused(true);
	}
}

void onInit(CSprite@ this)
{
	this.SetZ(-50);
}

void onTick(CBlob@ this)
{
	u32 elec = this.get_u32("elec");
	CInventory@ inv = this.getInventory();
	if (inv is null) return;

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		if (getGameTime() < this.get_u32("do sound idk"))
		{
			if (isClient())
			{
				ParticleAnimated("LargeSmoke", this.getPosition() + Vec2f(9, -10), Vec2f(0.2f, -0.75f), 0, 1.00f, 5 + XORRandom(5), 0, false);
			}
			sprite.SetEmitSoundPaused(false);
		}
		else sprite.SetEmitSoundPaused(true);
	}

	CBlob@ fuel = inv.getItem("mat_methane");
	if (fuel is null) return;

	//bool matching = fuel.getName() == "mat_oil" || fuel.getName() == "mat_methane" || fuel.getName() == "mat_fuel";
	bool matching = fuel.getName() == "mat_methane";

	//CBlob@ feeder = getBlobByNetworkID(this.get_u16("consume_id"));
	//if (this.get_u16("consume_id") != 0 && feeder is null)
	//{
	//    this.set_u16("consume_id", 0);
	//}

	if (matching) // && elec <= ELECTRICITY_MAX-ELECTRICITY_PROD)
	{
		this.set_u32("do sound idk", getGameTime()+300);

		//u16 diff = ELECTRICITY_MAX - elec;
		u16 quantity = fuel.getQuantity();
		//bool bfuel = false;
		//u16 prod = ELECTRICITY_PROD;
		//if (quantity < 10) prod *= (quantity*0.1);
		//printf(""+prod);

		//if (fuel.getName() == "mat_fuel") bfuel = true;

		//if (diff <= prod) // set to max if last step will make energy over max value
		//{
		//	this.set_u32("elec", ELECTRICITY_MAX);
		//	u16 fuel_consumed = (ELECTRICITY_MAX - this.get_f32("fuel_count")) / (fuel.getName() == "mat_fuel" ? 1.0f : 5.0f);
		//}
		//else
		//{
		//	this.add_u32("elec", prod+XORRandom(prod+1));
		//}

		//if (this.get_u32("elec") > this.get_u32("elec_max")) this.set_u32("elec", this.get_u32("elec_max"));

		if (isServer())
		{
			//if (bfuel)
			//{
			//	if (quantity == 1)
			//	{
			//		fuel.Tag("dead");
			//		fuel.server_Die();
			//	}
			//	else fuel.server_SetQuantity(quantity-1);
			//}
			//else if (quantity <= 5)
			//{
			//	fuel.Tag("dead");
			//	fuel.server_Die();
			//}
			//else
			//{
			if (quantity > 10)
			{
				u8 rand = XORRandom(5);
				fuel.server_SetQuantity(quantity-6+rand);
			//}
				CBlob@ oil = server_CreateBlob("mat_oil", this.getTeamNum(), this.getPosition());
				if (oil !is null)
				{
					oil.server_SetQuantity(5+XORRandom(6));
					this.server_PutInInventory(oil);
				}
			}
			else
			{
				CBlob@ oil = server_CreateBlob("mat_oil", this.getTeamNum(), this.getPosition());
				if (oil !is null)
				{
					oil.server_SetQuantity(XORRandom(fuel.getQuantity())+1);
					this.server_PutInInventory(oil);
				}
				if (isServer())
				{
					fuel.Tag("dead");
					fuel.server_Die();
				}
			}
		}
	}
}

void server_Sync(CBlob@ this)
{
    if (isServer())
    {
        CBitStream params;
        params.write_u32(this.get_u32("elec"));
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
            if (!params.saferead_u32(elec)) return;
			this.set_u32("elec", elec);
		}
	}
}

const string[] matNames = { 
	"mat_methane"
	//"mat_oil",
	//"mat_fuel"
};

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;
	
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