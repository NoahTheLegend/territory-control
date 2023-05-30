void onInit(CBlob@ this)
{	
	this.maxQuantity = 1;
    this.set_u32("cooldown", 0);
}

void onTick(CBlob@ this)
{
    if (this.get_u32("cooldown") > 1) this.set_u32("cooldown", this.get_u32("cooldown") - 1);

	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	if(point is null) {return;}
	CBlob@ playerblob = point.getOccupied();
    if(playerblob is null)
	{
        return;
    }
    CControls@ controls = playerblob.getControls();
    if(controls is null || !playerblob.isMyPlayer())
	{
        return;
    }
    if (controls.isKeyPressed(KEY_SPACE) && getGameTime() % 3 == 0) 
    {
        this.SendCommand(this.getCommandID("activate"));
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if(cmd == this.getCommandID("activate"))
    {
        if(isServer())
        {
    		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
            if(point is null){return;}
    		CBlob@ holder = point.getOccupied();

            if(holder !is null && this !is null)
            {
                CBlob@ blob = server_CreateBlob("concretegrenade", this.getTeamNum(), this.getPosition());
                holder.server_Pickup(blob);
                this.server_Die();
            }
        }
    }
}
