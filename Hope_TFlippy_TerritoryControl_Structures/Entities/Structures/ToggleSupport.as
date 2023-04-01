// NEEDS TO BE ADDED THROUGH CFG! Otherwise may cause *functions have same name* error
// EmitSound needs to be set manually to certain blobs

void onInit(CBlob@ this)
{
    this.addCommandID("state");
    this.Tag("togglesupport");
    
    this.set_bool("state", true);
	bool state = this.get_bool("state");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	bool nospam = getGameTime() >= this.get_u32("next use");
	if (!caller.isOverlapping(this)) return;
	{
		bool state = this.get_bool("state");
		if (this.getName() == "collector" && !state) return;
		CBitStream params;
		params.write_bool(!state);
		
		if (nospam)
			caller.CreateGenericButton((state ? 27 : 23), Vec2f(12, -8)+this.get_Vec2f("button_offset"), this, 
				this.getCommandID("state"), getTranslatedString(state ? "Turn off" : "Turn on"), params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("state"))
	{
		bool newState = params.read_bool();
		this.set_bool("state", newState);
		if (this.hasTag("hassound")) this.getSprite().SetEmitSoundPaused(!newState);
		if (this.get_bool("state"))
		{
			this.getSprite().PlaySound("LeverToggle.ogg", 2.0f, 1.2f);
			if (this.getName() == "chickenassembler") this.getSprite().PlaySound("ChargeLanceCycle.ogg", 2.0f, 1.5f);
		} else {
			this.getSprite().PlaySound("LeverToggle.ogg", 2.0f, 0.8f);
		}
		
		this.set_u32("next use", getGameTime() + 20);
	}
}
