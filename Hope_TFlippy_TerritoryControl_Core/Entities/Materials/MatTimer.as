void onInit(CBlob@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBlob@ this)
{
	if (isServer()) 
	{
		if (!this.isOnGround()) 
		{
			this.set_u32("death_date", getGameTime() + (60 * 30)); // 1 minute for all
			return;
		}

		if (getGameTime() > this.get_u32("death_date")) 
		{
			this.server_Die();
		}
	}
} 
