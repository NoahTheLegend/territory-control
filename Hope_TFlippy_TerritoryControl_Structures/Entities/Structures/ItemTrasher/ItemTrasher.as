void onInit(CSprite@ this)
{
	this.SetZ(-50);
}

void onInit(CBlob@ this)
{
	this.addCommandID("add_filter_item");

	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 60;

	this.Tag("builder always hit");

	this.set_string("filtername", "turned off");
	this.set_string("invname", "turned off");
	
	this.Tag("remote_storage");
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (this is null || blob is null || blob.hasTag("player") || blob.hasTag("npc")) return;
	if (this.get_string("filtername") == "turned off" || blob.getName() != this.get_string("filtername")) return;
	if (!blob.isAttached() && !blob.hasTag("dead"))
	{
		if (isServer()) blob.server_Die();
	}
}

void onTick(CBlob@ this)
{
	client_UpdateName(this);
}

void client_UpdateName(CBlob@ this)
{
	if (isClient())
	{
		string name = this.get_string("invname");
		this.setInventoryName("Destroying item: "+name);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	
	if ((this.getTeamNum() < 7 && (caller.getTeamNum() == this.getTeamNum())) || this.getTeamNum() > 6) {

		CBlob@ carried = caller.getCarriedBlob();
		if (carried !is null)
		{
			u16 carried_netid = carried.getNetworkID();
			CBitStream params;
			params.write_u16(carried_netid);
			caller.CreateGenericButton("$" + carried.getName() + "$", Vec2f(0,-8), this, this.getCommandID("add_filter_item"), "Add to Filter", params);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("add_filter_item"))
	{
		CBlob@ carried = getBlobByNetworkID(params.read_u16());

		//if(isServer())
		if (carried !is null){
			if (carried.getName() == this.get_string("filtername"))
			{
				this.set_string("filtername", "turned off");
				this.set_string("invname", "turned off");
				return;
			}
			this.set_string("filtername", carried.getName());
			this.set_string("invname", carried.getInventoryName());
		}
	}
}
