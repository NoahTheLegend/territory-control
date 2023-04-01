void onInit(CBlob@ this)
{
    this.addCommandID("tame");
    this.Tag("tameable");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
    if (caller is null) return;
	CBlob@ carried = caller.getCarriedBlob();
    CBitStream params;
    params.write_u16(caller.getNetworkID());
    if (carried !is null && carried.getName() == "saddle")
    {
        CButton@ button = caller.CreateGenericButton(17, Vec2f(0, 0), this, this.getCommandID("tame"), "Tame", params);
    }
}

void onTick(CBlob@ this)
{
    
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("tame"))
    {
        u16 id = params.read_u16();
        CBlob@ caller = getBlobByNetworkID(id);
        if (caller !is null)
        {
            CBlob@ carried = caller.getCarriedBlob();
            if (carried !is null && carried.getName() == "saddle")
            {
                //TODO: add a sound clientside
                if (isServer())
                {
                    AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("SADDLE");
                    if (ap !is null && ap.getOccupied() is null)
                    {
                        carried.server_DetachFromAll();
                        this.server_AttachTo(carried, ap);
                    }
                }
            }
        }
    }
}