void onTick(CSprite@ this)
{
	if (isClient())
	{
		CBlob@ blob = this.getBlob();
		if (blob !is null)
		{
			if (blob.get_u8("delay") > 0) blob.add_u8("delay", -1);
			if (!blob.get_bool("state") && blob.get_u8("delay") == 0)
			{
				if (blob.getHealth() < blob.getInitialHealth() * 0.75f)
				{
					this.SetAnimation("destruction");
					if (blob.getHealth() < blob.getInitialHealth() * 0.25f)
					{
						this.SetFrameIndex(2);
					}
					else if (blob.getHealth() < blob.getInitialHealth() * 0.5f)
					{
						this.SetFrameIndex(1);
					}
					else this.SetFrameIndex(0);
				}
				else
				{
					this.SetAnimation("default");
				}
			}
		}
	}
}