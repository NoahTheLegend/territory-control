
u32 smartStorageTake(CBlob@ this, string blobName, u32 quantity)
{
	u32 cur_quantity = this.get_u32("SS_"+blobName);
	if (cur_quantity > 1)
	{
		cur_quantity--;//remove offset
		u32 amount = Maths::Min(cur_quantity, quantity);
		if (isServer())
		{
			this.sub_u32("SS_"+blobName, amount);
			this.Sync("SS_"+blobName, true);
		}
		return cur_quantity-amount;
	}
	return 0;
}

u32 smartStorageCheck(CBlob@ this, string blobName)
{
	if (this.exists("SS_"+blobName)) 
	{
		u32 cur_quantity = this.get_u32("SS_"+blobName);
		if (cur_quantity > 1) return cur_quantity-1;
		
	}
	return 0;
}
