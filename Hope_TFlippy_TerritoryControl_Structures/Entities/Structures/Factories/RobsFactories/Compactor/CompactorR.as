#include "MakeMat.as";
#include "Requirements.as";

const u16 MAX_LOOP = 10; // what you get for breaking it
const u16 LOOP_RNG = 40; // variation on what will spawn if broken 

void onInit(CSprite@ this)
{
	this.SetZ(-50);
}

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 60;

	this.Tag("builder always hit");
	
	this.set_u32("compactor_quantity", 0);
	this.set_string("compactor_resource", "");
	this.set_string("compactor_resource_name", "");
	
	this.addCommandID("compactor_withdraw");
	this.addCommandID("add_filter_item");
	this.addCommandID("compactor_sync");

	this.set_string("filtername", "anything");
	this.set_string("invname", "anything");
	
	this.Tag("remote_storage");
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
		this.setInventoryName("Compactor\n(" + this.get_u32("compactor_quantity") + " " + this.get_string("compactor_resource_name") + ")\n"+"Filter: "+name);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (this is null || blob is null) return;
	if (this.get_string("filtername") != "anything" && blob.getName() != this.get_string("filtername")) return;
	if (!blob.isAttached() && !blob.hasTag("dead") && (blob.hasTag("material") || blob.hasTag("hopperable")))
	{
		string compactor_resource = this.get_string("compactor_resource");
		
		if (isServer() && compactor_resource == "")
		{
			this.set_string("compactor_resource", blob.getName());
			this.set_string("compactor_resource_name", blob.getInventoryName());
			// this.Sync("compactor_resource", false);
			// this.Sync("compactor_resource_name", false);
			
			compactor_resource = blob.getName();
		}
		
		if (blob.getName() == compactor_resource)
		{
			if (isServer()) 
			{
				this.add_u32("compactor_quantity", blob.getQuantity());
				// this.Sync("compactor_quantity", false);
				
				blob.Tag("dead");
				blob.server_Die();
				server_Sync(this);
			}
			
			if (isClient())
			{
				this.getSprite().PlaySound("bridge_open.ogg");
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	
	if ((this.getTeamNum() < 7 && (caller.getTeamNum() == this.getTeamNum())) || this.getTeamNum() > 6) {
		CButton@ button_withdraw = caller.CreateGenericButton(20, Vec2f(0, 0), this, this.getCommandID("compactor_withdraw"), "Take a stack", params);
		if (button_withdraw !is null)
		{
			button_withdraw.SetEnabled(this.get_u32("compactor_quantity") > 0);
		}
		Vec2f buttonPos;

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

// KAG's CBlob.Sync() is nonfunctional shit
// just get gud, sync works fine if you use it right - Rob
void server_Sync(CBlob@ this)
{
	if (isServer())
	{
		CBitStream stream;
		stream.write_string(this.get_string("compactor_resource_name"));
		stream.write_string(this.get_string("compactor_resource"));
		stream.write_u32(this.get_u32("compactor_quantity"));
		stream.write_string(this.get_string("filtername"));
		stream.write_string(this.get_string("invname"));
		
		this.SendCommand(this.getCommandID("compactor_sync"), stream);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("compactor_withdraw"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null && this.get_string("compactor_resource") != "")
		{
			u32 current_quantity = this.get_u32("compactor_quantity");
		
			if (isServer() && current_quantity > 0) 
			{
				CBlob@ blob = server_CreateBlob(this.get_string("compactor_resource"), this.getTeamNum(), this.getPosition());
				if (blob !is null)
				{
					u32 quantity = Maths::Min(current_quantity, blob.getMaxQuantity());
					u32 new_quantity = Maths::Max(current_quantity - quantity, 0);
										
					blob.server_SetQuantity(quantity);
					caller.server_Pickup(blob);
					
					this.set_u32("compactor_quantity", new_quantity);
					if (new_quantity == 0)
					{
						this.set_string("compactor_resource", "");
						this.set_string("compactor_resource_name", "");
					}
					server_Sync(this);
				}
			}
		}
	}
	else if (cmd == this.getCommandID("add_filter_item"))
	{
		CBlob@ carried = getBlobByNetworkID(params.read_u16());

		//if(isServer())
		if (carried !is null){
			if (carried.getName() == this.get_string("filtername"))
			{
				this.set_string("filtername", "anything");
				this.set_string("invname", "anything");
				return;
			}
			this.set_string("filtername", carried.getName());
			this.set_string("invname", carried.getInventoryName());
		}
	}
	else if (cmd == this.getCommandID("compactor_sync"))
	{
		if (isClient())
		{
			string name = params.read_string();
			string config = params.read_string();
			u32 quantity = params.read_u32();
			string filtername = params.read_string();
			string invname = params.read_string();
			
			this.set_string("compactor_resource_name", name);
			this.set_string("compactor_resource", config);
			this.set_u32("compactor_quantity", quantity);
			this.set_string("filtername", filtername);
			this.set_string("invname", invname);
			
			client_UpdateName(this);
		}
	}
}

void onDie(CBlob@ this)
{
	s32 current_quantity = this.get_u32("compactor_quantity");
	if (isServer() && current_quantity > 0) 
	{
		const string resource_name = this.get_string("compactor_resource");
		const u8 team = this.getTeamNum();
		const Vec2f pos = this.getPosition();
		const int rng_amount = MAX_LOOP + XORRandom(LOOP_RNG);

		for (int a = 0; a < current_quantity && a < rng_amount; a++)
		{
			CBlob@ blob = server_CreateBlob(resource_name, team, pos);
			if (blob is null) { continue; }

			u32 quantity = Maths::Min(current_quantity, blob.getMaxQuantity());
			current_quantity = Maths::Max(current_quantity - quantity, 0);
									
			blob.server_SetQuantity(quantity);
			blob.setVelocity(getRandomVelocity(0, XORRandom(400) * 0.01f, 360));
		}

		server_Sync(this);
	}
}