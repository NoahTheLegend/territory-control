
void onInit(CBlob@ this)
{
    this.addCommandID("switch");
    this.set_bool("extraction_enabled", true);
    if (!this.exists("disable_button_offset")) this.set_Vec2f("disable_button_offset", Vec2f(0,0));
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBlob@ carried = caller.getCarriedBlob();
    CBitStream params;
    if (carried !is null)
    {
        if (carried.getName() == "wrench")
        {
            CButton@ button = caller.CreateGenericButton(8, this.get_Vec2f("disable_button_offset"), this, this.getCommandID("switch"), this.get_bool("extraction_enabled") ? "Disable extraction from this structure." : "Enable extraction from this structure.", params);
        }
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("switch"))
	{
        this.get_bool("extraction_enabled") ? this.Tag("ignore extractor") : this.Untag("ignore extractor");
        this.set_bool("extraction_enabled", !this.get_bool("extraction_enabled"));
    }
}