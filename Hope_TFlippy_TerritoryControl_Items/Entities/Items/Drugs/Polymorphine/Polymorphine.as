
void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(true);
	this.addCommandID("consume");
	this.Tag("hopperable");

	this.Tag("syringe");
	this.Tag("forcefeed_always");
	this.set_string("forcefeed_text", "Inject "+this.getInventoryName()+"!");

	this.Tag("dartguninjectable");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (getGameTime() <= this.get_u32("button_delay")) return;
	this.set_u32("button_delay", getGameTime()+5);

	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton(22, Vec2f(0, 0), this, this.getCommandID("consume"), this.get_string("forcefeed_text"), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("consume"))
	{
		if (getGameTime() < this.get_u32("consume_delay")) return;
		this.set_u32("consume_delay", getGameTime()+2);
		int rnd = XORRandom(2);
		this.getSprite().PlaySound("Syringe_Injection_"+rnd+".ogg", 2.00f, 1.00f);

		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			if (!caller.hasScript("Polymorphine_Effect.as")) caller.AddScript("Polymorphine_Effect.as");
			caller.get_f32("polymorphine_effect") == 0 ? caller.add_f32("polymorphine_effect", 2.00f) : caller.add_f32("polymorphine_effect", -1.50f);

			if (isServer())
			{
				this.server_Die();
			}
		}
	}
}

