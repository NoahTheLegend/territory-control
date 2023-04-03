void onInit(CBlob@ this)
{
	this.addCommandID("consume");
	this.Tag("hopperable");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (this.isOverlapping(caller) || this.isAttachedTo(caller))
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		caller.CreateGenericButton(22, Vec2f(0, 0), this, this.getCommandID("consume"), "Drink!", params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("consume"))
	{
		if (getGameTime() < this.get_u32("consume_delay")) return;
		this.set_u32("consume_delay", getGameTime()+2);
		this.getSprite().PlaySound("Gurgle2.ogg", 1.0f, 1.2f);

		if (!isServer()) return;
		f32 heal_amount = 5.0f;
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			if (caller.getHealth() + heal_amount/2 < caller.getInitialHealth())
			{
				caller.server_Heal(heal_amount);
			}
			else caller.server_SetHealth(caller.getInitialHealth());

			this.server_Die();
		}
	}
}