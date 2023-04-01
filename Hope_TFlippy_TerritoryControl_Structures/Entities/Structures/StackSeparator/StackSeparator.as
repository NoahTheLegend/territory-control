#include "MakeMat.as";
#include "Requirements.as";

void onInit(CSprite@ this)
{
	this.SetZ(-50);

	// this.SetEmitSound("assembler_loop.ogg");
	// this.SetEmitSoundVolume(1.0f);
	// this.SetEmitSoundSpeed(0.5f);
	// this.SetEmitSoundPaused(false);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	this.setPosition(this.getPosition()-Vec2f(0,2));
}

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);

	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 60;

	this.Tag("builder always hit");
	this.Tag("extractable");
	
	this.addCommandID("separate");

	this.addCommandID("pick_75");
	this.addCommandID("pick_50");
	this.addCommandID("pick_25");
	this.addCommandID("pick_1");

	AddIconToken("$icon_75%$", "Materials.png", Vec2f(16, 16), 24);
	AddIconToken("$icon_50%$", "Materials.png", Vec2f(16, 16), 16);
	AddIconToken("$icon_25%$", "Materials.png", Vec2f(16, 16), 8);
	AddIconToken("$icon_1$", "Materials.png", Vec2f(16, 16), 0);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (this is null || caller is null) return;
	CBitStream params;
	params.write_u16(caller.getNetworkID());

	caller.CreateGenericButton(24, Vec2f(0, -9), this, this.getCommandID("separate"), "Separate", params);
}

void PackerMenu(CBlob@ this, CBlob@ caller)
{
	if (caller !is null && caller.isMyPlayer())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f), this, Vec2f(2, 2), "Take amount");
		
		if (menu !is null)
		{
			menu.deleteAfterClick = true;

			CGridButton@ button75 = menu.AddButton("$icon_75%$", "Pick 75%", this.getCommandID("pick_75"), Vec2f(1, 1), params);
			CGridButton@ button50 = menu.AddButton("$icon_50%$", "Pick 50%", this.getCommandID("pick_50"), Vec2f(1, 1), params);
			CGridButton@ button25 = menu.AddButton("$icon_25%$", "Pick 25%", this.getCommandID("pick_25"), Vec2f(1, 1), params);
			CGridButton@ button1 = menu.AddButton("$icon_1$", "Pick only 1 item", this.getCommandID("pick_1"), Vec2f(1, 1), params);
			if (button1 !is null)
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null)
				{
					if (inv.getItem(0) is null || inv.getItem(0).getQuantity() <= 1) button1.SetEnabled(false);
				}
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("separate"))
	{
		u16 blobid = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(blobid);
		if (this !is null && blob !is null)
		{
			PackerMenu(this, blob);
		}
	}
	else if (cmd == this.getCommandID("pick_75"))
	{	
		u16 blobid = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(blobid);
		if (blob !is null)
		{
			if (this !is null)
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null)
				{
					CBlob@ item = inv.getItem(0);
					if (item !is null)
					{
						f32 count = item.getQuantity();
						u16 result = Maths::Floor(count*0.75);
						if (isServer() && result > 0)
						{
							item.server_SetQuantity(count-result);
							CBlob@ drop = server_CreateBlob(item.getName(), item.getTeamNum(), this.getPosition());
							drop.server_SetQuantity(result);
							if (!blob.server_PutInInventory(drop))
							{
								drop.setPosition(this.getPosition());
							}
						}
					}
				}
			}
		}
	}
	else if (cmd == this.getCommandID("pick_50"))
	{	
		u16 blobid = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(blobid);
		if (blob !is null)
		{
			if (this !is null)
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null)
				{
					CBlob@ item = inv.getItem(0);
					if (item !is null)
					{
						f32 count = item.getQuantity();
						u16 result = Maths::Floor(count*0.50);
						if (isServer() && result > 0)
						{
							item.server_SetQuantity(count-result);
							CBlob@ drop = server_CreateBlob(item.getName(), item.getTeamNum(), this.getPosition());
							drop.server_SetQuantity(result);
							if (!blob.server_PutInInventory(drop))
							{
								drop.setPosition(this.getPosition());
							}
						}
					}
				}
			}
		}
	}
	else if (cmd == this.getCommandID("pick_25"))
	{	
		u16 blobid = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(blobid);
		if (blob !is null)
		{
			if (this !is null)
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null)
				{
					CBlob@ item = inv.getItem(0);
					if (item !is null)
					{
						f32 count = item.getQuantity();
						u16 result = Maths::Floor(count*0.25);
						if (isServer() && result > 0)
						{
							item.server_SetQuantity(count-result);
							CBlob@ drop = server_CreateBlob(item.getName(), item.getTeamNum(), this.getPosition());
							drop.server_SetQuantity(result);
							if (!blob.server_PutInInventory(drop))
							{
								drop.setPosition(this.getPosition());
							}
						}
					}
				}
			}
		}
	}
	else if (cmd == this.getCommandID("pick_1"))
	{	
		u16 blobid = params.read_u16();
		CBlob@ blob = getBlobByNetworkID(blobid);
		if (blob !is null)
		{
			if (this !is null)
			{
				CInventory@ inv = this.getInventory();
				if (inv !is null)
				{
					if (inv.getItem(0) is null || inv.getItem(0).getQuantity() <= 1) return;

					CBlob@ item = inv.getItem(0);
					if (item !is null)
					{
						//if (item.getName() == "mat_antimatter") return;
						f32 count = item.getQuantity();
						if (isServer() && count > 0)
						{
							item.server_SetQuantity(count-1);
							CBlob@ drop = server_CreateBlob(item.getName(), item.getTeamNum(), this.getPosition());
							drop.server_SetQuantity(1);
							if (!blob.server_PutInInventory(drop))
							{
								drop.setPosition(this.getPosition());
							}
						}
					}
				}
			}
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if(blob.isKeyPressed(key_down))return false;

	return true;
}