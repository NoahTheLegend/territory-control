void onInit(CBlob@ this)
{
	this.addCommandID("consume");
	this.Tag("hopperable");
	this.Tag("forcefeed_always");
	this.Tag("dartguninjectable");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton(22, Vec2f(0, 0), this, this.getCommandID("consume"), "Drink!", params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("consume"))
	{
		if (getGameTime() < this.get_u32("consume_delay")) return;
		this.set_u32("consume_delay", getGameTime()+2);
		this.getSprite().PlaySound("Gurgle2.ogg", 2.00f, 1.00f);

		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			if (!caller.hasScript("Tea_Effect.as")) caller.AddScript("Tea_Effect.as");

			if (isServer())
			{
				this.server_Die();
			}
		}
	}
}
