const u32 ELECTRICITY_MAX = 1500;
const u32 ELECTRICITY_PROD = 50;

void onInit(CBlob@ this)
{
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 30;

	this.Tag("ignore extractor");
	this.Tag("builder always hit");
	this.Tag("generator");

	this.addCommandID("sync_prep");
	this.addCommandID("sync");

	this.set_u32("elec_max", ELECTRICITY_MAX);
	this.set_u16("consume_id", 0);
	this.set_Vec2f("wire_offset", Vec2f(-14.5, 0));

	this.set_u32("elec", 0);
	server_Sync(this);

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("generator_loop.ogg");
		sprite.SetEmitSoundSpeed(0.85f);
		sprite.SetEmitSoundVolume(0.4f);
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
				ParticleAnimated("LargeSmoke", this.getPosition() + Vec2f(6, -12), Vec2f(0.2f, -0.75f), 0, 1.00f, 5 + XORRandom(5), 0, false);
			}
			sprite.SetEmitSoundPaused(false);
		}
		else sprite.SetEmitSoundPaused(true);
	}

	CBlob@ fuel = inv.getItem(0);
	if (fuel is null) return;

	bool matching = fuel.getName() == "mat_wood" || fuel.getName() == "mat_coal";

	CBlob@ feeder = getBlobByNetworkID(this.get_u16("consume_id"));
	if (this.get_u16("consume_id") != 0 && feeder is null)
	{
	    this.set_u16("consume_id", 0);
	}

	if (matching && elec <= ELECTRICITY_MAX-ELECTRICITY_PROD)
	{
		this.set_u32("do sound idk", getGameTime()+300);

		u16 diff = ELECTRICITY_MAX - elec;
		u16 quantity = fuel.getQuantity();
		bool coal = false;
		if (fuel.getName() == "mat_coal") coal = true;

		if (diff <= ELECTRICITY_PROD) // set to max if last step will make energy over max value
		{
			this.set_u32("elec", ELECTRICITY_MAX);
			u16 fuel_consumed = (ELECTRICITY_MAX - this.get_f32("fuel_count")) / (fuel.getName() == "mat_coal" ? 1.0f : 40.0f);
		}
		else
		{
			if (coal || quantity >= 40) this.add_u32("elec", ELECTRICITY_PROD+XORRandom(ELECTRICITY_PROD+1));
		}

		if (this.get_u32("elec") > this.get_u32("elec_max")) this.set_u32("elec", this.get_u32("elec_max"));

		if (isServer())
		{
			if (coal)
			{
				if (quantity <= 1) fuel.server_Die();
				else fuel.server_SetQuantity(quantity-1);
			}
			else
			{
				if (quantity <= 40) fuel.server_Die();
				else fuel.server_SetQuantity(quantity-40);
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
	"mat_wood",
	"mat_coal"
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