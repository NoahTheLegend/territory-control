#include "MakeMat.as";
#include "MakeCrate.as";
#include "Requirements.as";
#include "CustomBlocks.as";

void onInit(CSprite@ this) // EmitSound toggle
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	// Building
	this.SetZ(-50);

	this.SetEmitSound("ChickenAssembler_Loop.ogg");
	this.SetEmitSoundVolume(0.4f);
	this.SetEmitSoundSpeed(0.9f);
	this.SetEmitSoundPaused(false);

	bool state = blob.get_bool("state");

	if (!state && blob.hasTag("togglesupport"))
	{
		this.SetEmitSoundPaused(true);
	}
}

class AssemblerItem
{
	string resultname;
	u32 resultcount;
	string title;
	CBitStream reqs;

	AssemblerItem(string resultname, u32 resultcount, string title)
	{
		this.resultname = resultname;
		this.resultcount = resultcount;
		this.title = title;
	}
}

void onInit(CBlob@ this)
{
	AssemblerItem[] items;
	{
		AssemblerItem i("assaultrifle", 2, "UPF Assault Rifle (2)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 24);
		AddRequirement(i.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 20);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 16);
		items.push_back(i);
	}
	{
		AssemblerItem i("autoshotgun", 2, "UPF Assault Shotgun (2)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 24);
		AddRequirement(i.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 30);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 12);
		items.push_back(i);
	}
	{
		AssemblerItem i("sniper", 2, "UPF Sniper Rifle (2)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 44);
		AddRequirement(i.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 30);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 24);
		items.push_back(i);
	}
	{
		AssemblerItem i("uzi", 4, "UPF Submachine Gun (4)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 36);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 16);
		items.push_back(i);
	}
	{
		AssemblerItem i("fuger", 4, "UPF Fuger (4)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 8);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 16);
		items.push_back(i);
	}
	{
		AssemblerItem i("silencedrifle", 2, "UPF Suppressed Rifle (2)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 30);
		AddRequirement(i.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 12);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 12);
		items.push_back(i);
	}
	{
		AssemblerItem i("sar", 4, "UPF Semiautomatic Rifle (4)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 34);
		AddRequirement(i.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 22);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 18);
		items.push_back(i);
	}
	{
		AssemblerItem i("msgl", 2, "UPF Multi-Shot Grenade Launcher AV-140 (2)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 40);
		AddRequirement(i.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 32);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 12);
		items.push_back(i);
	}
	{
		AssemblerItem i("samrpg", 2, "SAM RPG (2)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 16);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 50);
		AddRequirement(i.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 12);
		AddRequirement(i.reqs, "blob", "mat_copperingot", "Copper Ingot", 8);
		items.push_back(i);
	}
	{
		AssemblerItem i("mat_sammissile", 4, "SAM Missile (4)");
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 4);
		AddRequirement(i.reqs, "blob", "mat_methane", "Methane", 25);
		items.push_back(i);
	}
	{
		AssemblerItem i("incendiarymortar", 1, "Incendiary Mortar (1)");
		AddRequirement(i.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 24);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 4);
		items.push_back(i);
	}
	{
		AssemblerItem i("cruisemissile", 1, "Cruise Missile (1)");
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 16);
		AddRequirement(i.reqs, "blob", "mat_methane", "Methane", 50);
		AddRequirement(i.reqs, "blob", "mat_sulphur", "Sulphur", 25);
		items.push_back(i);
	}
	{
		AssemblerItem i("mat_hshell", 8, "HATC Shell (8)");
		AddRequirement(i.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 32);
		AddRequirement(i.reqs, "blob", "mat_sulphur", "Sulphur", 500);
		AddRequirement(i.reqs, "blob", "mat_mithrilenriched", "Enriched Mithril", 40);
		items.push_back(i);
	}
	{
		AssemblerItem i("advancedcruisemissile", 1, "Advanced Cruise Missile (1)");
		AddRequirement(i.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 8);
		AddRequirement(i.reqs, "blob", "mat_methane", "Methane", 25);
		AddRequirement(i.reqs, "blob", "mat_fuel", "Fuel", 25);
		AddRequirement(i.reqs, "blob", "mat_sulphur", "Sulphur", 50);
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 8);
		items.push_back(i);
	}
	{
		AssemblerItem i("hatc", 1, "HATC (1)");
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 36);
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 24);
		AddRequirement(i.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 40);
		AddRequirement(i.reqs, "blob", "mat_copperwire", "Copper Wire", 30);
		AddRequirement(i.reqs, "blob", "mat_battery", "Voltron Battery Plus", 400);
		items.push_back(i);
	}
	{
		AssemblerItem i("mat_battery", 100, "Voltron Battery Plus (100)");
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 10);
		AddRequirement(i.reqs, "blob", "mat_copperingot", "Copper Ingot", 10);
		AddRequirement(i.reqs, "blob", "mat_mithril", "Mithril", 50);
		AddRequirement(i.reqs, "blob", "mat_sulphur", "Sulphur", 150);
		items.push_back(i);
	}

	this.set("items", items);

	this.set_TileType("background tile", CMap::tile_biron);
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 150;

	this.Tag("builder always hit");
	this.Tag("change team on fort capture");
	this.Tag("hassound");
	
	this.addCommandID("set");

	this.set_u8("crafting", 0);

	this.Tag("ignore extractor");
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	if (!caller.isOverlapping(this)) return;
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());

		CButton@ button = caller.CreateGenericButton(21, Vec2f(0, -16), this, ChickenAssemblerMenu, "Set Item");
	}
}

void ChickenAssemblerMenu(CBlob@ this, CBlob@ caller)
{
	if(caller.isMyPlayer())
	{
		CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f), this, Vec2f(4, 8), "Set Assembly");
		if (menu !is null)
		{
			AssemblerItem[] items = getItems(this);
			for(uint i = 0; i < items.length; i += 1)
			{
				AssemblerItem item = items[i];

				CBitStream pack;
				pack.write_u8(i);

				int teamnum = this.getTeamNum();
				if (teamnum > 6) teamnum = 7;
				AddIconToken("$chicken_assembler_icon" + i + "$", "ChickenAssemblerIcons.png", Vec2f(32, 16), i, teamnum);

				string text = "Set to Assemble: " + item.title;
				if(this.get_u8("crafting") == i)
				{
					text = "Already Assembling: " + item.title;
				}

				CGridButton @butt = menu.AddButton("$chicken_assembler_icon" + i + "$", text, this.getCommandID("set"), pack);
				butt.hoverText = item.title + "\n" + getButtonRequirementsText(item.reqs, false);
				if(this.get_u8("crafting") == i)
				{
					butt.SetEnabled(false);
				}
			}
		}
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("set"))
	{
		u8 setting = params.read_u8();
		this.set_u8("crafting", setting);
	}
}

void onTick(CBlob@ this)
{
	if ((!this.get_bool("state") && this.hasTag("togglesupport"))) return; //|| this.get_u32("elec") == 0) return; // set this to stop structure
	int crafting = this.get_u8("crafting");

	AssemblerItem[]@ items = getItems(this);
	if (items.length == 0) return;

	AssemblerItem item = items[crafting];
	CInventory@ inv = this.getInventory();


	CBitStream missing;
	if (hasRequirements(inv, item.reqs, missing))
	{
		if (isServer()) //&& this.get_u32("elec") > 250)
		{
			if (item.resultname == "incendiarymortar" || item.resultname == "hatc")
			{
				CBlob@ blob = server_MakeCrate(item.resultname, item.title, 0, 250, this.getPosition(), true, item.resultcount);
			}
			else
			{
				CBlob@[] crates;
				getMap().getBlobsInRadius(this.getPosition(), 64.0f, @crates);

				CBlob@ crate;
				bool dont_spawn_crate = false;
				for (u8 i = 0; i < crates.length; i++)
				{
					if (crates[i] !is null && crates[i].getName() == "cacrate")
					{
						CInventory@ inv = crates[i].getInventory();
						if (inv.isFull() || inv.getItemsCount() > 9 - (item.resultname == "mat_battery" ? Maths::Floor(item.resultcount/50) : item.resultcount)) break;
						dont_spawn_crate = true;
						@crate = @crates[i];
					}
				}
				if (!dont_spawn_crate) @crate = server_CreateBlobNoInit("cacrate");
				if (crate !is null)
				{
					crate.server_setTeamNum(250);
					crate.setPosition(this.getPosition());
					crate.Tag("ignore extractor");
					crate.Init();
					crate.setInventoryName("UPF Assembly Crate");
					
					for (uint i = 0; i < item.resultcount; i++)
					{
						CBlob@ blob = server_CreateBlob(item.resultname, 250, this.getPosition());
						if (!crate.server_PutInInventory(blob))
						{
							@crate = server_CreateBlobNoInit("cacrate");
							if (crate !is null)
							{
								crate.server_setTeamNum(250);
								crate.setPosition(this.getPosition());
								crate.Tag("ignore extractor");
								crate.Init();
								crate.setInventoryName(item.title);
							}
						}
					}

					//this.add_u32("elec", -250);
					//this.Sync("elec", true);
				}
			}
			// CBlob @mat = server_CreateBlob(item.resultname, this.getTeamNum(), this.getPosition());
			// mat.server_SetQuantity(item.resultcount);
			server_TakeRequirements(inv, item.reqs);
		}

		this.getSprite().PlaySound("ProduceSound.ogg");
		this.getSprite().PlaySound("BombMake.ogg");
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;

	int crafting = this.get_u8("crafting");

	bool isMat = false;

	AssemblerItem[]@ items = getItems(this);
	if (items.length == 0) return;

	AssemblerItem item = items[crafting];
	CBitStream bs = item.reqs;
	bs.ResetBitIndex();
	string text, requiredType, name, friendlyName;
	u16 quantity = 0;

	while (!bs.isBufferEnd())
	{
		ReadRequirement(bs, requiredType, name, friendlyName, quantity);

		if(blob.getName() == name)
		{
			isMat = true;
			break;
		}
	}

	if (isMat && !blob.isAttached() && blob.hasTag("material"))
	{
		if (isServer()) this.server_PutInInventory(blob);
		if (isClient()) this.getSprite().PlaySound("bridge_open.ogg");
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return (this.getTeamNum() >= 100 ? true : (forBlob.getTeamNum() == this.getTeamNum())) && forBlob.isOverlapping(this);
}

AssemblerItem[] getItems(CBlob@ this)
{
	AssemblerItem[] items;
	this.get("items", items);
	return items;
}


void onAddToInventory( CBlob@ this, CBlob@ blob )
{
	if(blob.getName() != "gyromat") return;

	this.getCurrentScript().tickFrequency = 150 / (this.exists("gyromat_acceleration") ? this.get_f32("gyromat_acceleration") : 1);
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	if(blob.getName() != "gyromat") return;

	this.getCurrentScript().tickFrequency = 150 / (this.exists("gyromat_acceleration") ? this.get_f32("gyromat_acceleration") : 1);
}

void onDie(CBlob@ this)
{
	if (isServer()) server_CreateBlob("bp_automation_advanced", this.getTeamNum(), this.getPosition());
}