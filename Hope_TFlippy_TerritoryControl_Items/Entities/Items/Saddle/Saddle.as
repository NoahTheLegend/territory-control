void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(false);
	this.addCommandID("detach");

	//AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PILOT");
	//if (ap !is null)
	//{
	//	ap.SetKeysToTake(key_left | key_right | key_down);
	//}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
    if (caller is null || this.hasAttached()) return;
    CBitStream params;
    if (this.isAttachedToPoint("SADDLE"))
	{
		CButton@ button = caller.CreateGenericButton(9, Vec2f(0, 0), this, this.getCommandID("detach"), "Detach", params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("detach"))
    {
        if (isServer()) this.server_DetachFromAll();
    }
}

void onTick(CBlob@ this)
{

}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (inventoryBlob is null) return;

	CInventory@ inv = inventoryBlob.getInventory();

	if (inv is null) return;

	this.doTickScripts = true;
	
	inv.doTickScripts = true;
}