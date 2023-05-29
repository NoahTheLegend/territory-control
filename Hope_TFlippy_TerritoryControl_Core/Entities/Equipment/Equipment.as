#include "RunnerCommon.as"

// Made by GoldenGuy 

void onInit(CBlob@ this)
{
	this.Tag("equipment support");

	this.addCommandID("equip_head");
	this.addCommandID("equip_torso");
	this.addCommandID("equip2_torso");
	this.addCommandID("equip_boots");
}

void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu@ gridmenu)
{
	const string name = this.getName();

	Vec2f MENU_POS;

	if (name == "builder" || name == "peasant" || name == "rockman") MENU_POS = gridmenu.getUpperLeftPosition() + Vec2f(-84, -204);
	else if (name == "archer") MENU_POS = gridmenu.getUpperLeftPosition() + Vec2f(-84, -56);
	else MENU_POS = gridmenu.getUpperLeftPosition() + Vec2f(-36, -56);

	CGridMenu@ equipments = CreateGridMenu(MENU_POS, this, Vec2f(1, 3), "equipment");
	CGridMenu@ extraequipments = CreateGridMenu(MENU_POS+Vec2f(-48, 0), this, Vec2f(1, 1), "equipment");

	string HeadImage = "Equipment.png";
	string TorsoImage = "Equipment.png";
	string Torso2Image = "Equipment.png";
	string BootsImage = "Equipment.png";

	int HeadFrame = 0;
	int TorsoFrame = 1;
	int Torso2Frame = 1;
	int BootsFrame = 2;

	if (this.get_string("equipment_head") != "")
	{
		HeadImage = this.get_string("equipment_head")+"_icon.png";
		HeadFrame = 0;
	}
	if (this.get_string("equipment_torso") != "")
	{
		TorsoImage = this.get_string("equipment_torso")+"_icon.png";
		TorsoFrame = 0;
	}
	if (this.get_string("equipment2_torso") != "")
	{
		Torso2Image = this.get_string("equipment2_torso")+"_icon.png";
		Torso2Frame = 0;
	}
	if (this.get_string("equipment_boots") != "")
	{
		BootsImage = this.get_string("equipment_boots")+"_icon.png";
		BootsFrame = 0;
	}

	if (equipments !is null)
	{
		equipments.SetCaptionEnabled(false);
		equipments.deleteAfterClick = false;

		if (this !is null)
		{
			CBitStream params;
			params.write_u16(this.getNetworkID());

			int teamnum = this.getTeamNum();
			if (teamnum > 6) teamnum = 7;
			AddIconToken("$headimage$", HeadImage, Vec2f(24, 24), HeadFrame, teamnum);
			AddIconToken("$torsoimage$", TorsoImage, Vec2f(24, 24), TorsoFrame, teamnum);
			AddIconToken("$bootsimage$", BootsImage, Vec2f(24, 24), BootsFrame, teamnum);

			CGridButton@ head = equipments.AddButton("$headimage$", "", this.getCommandID("equip_head"), Vec2f(1, 1), params);
			if (head !is null)
			{
				if (this.get_string("equipment_head") != "") head.SetHoverText("Unequip head.\n");
				else head.SetHoverText("Equip head.\n");
			}

			CGridButton@ torso = equipments.AddButton("$torsoimage$", "", this.getCommandID("equip_torso"), Vec2f(1, 1), params);
			if (torso !is null)
			{
				if (this.get_string("equipment_torso") != "") torso.SetHoverText("Unequip torso.\n");
				else torso.SetHoverText("Equip torso.\n");
			}

			CGridButton@ boots = equipments.AddButton("$bootsimage$", "", this.getCommandID("equip_boots"), Vec2f(1, 1), params);
			if (boots !is null)
			{
				if (this.get_string("equipment_boots") != "") boots.SetHoverText("Unequip boots.\n");
				else boots.SetHoverText("Equip boots.\n");
			}
		}
	}
	if (extraequipments !is null)
	{
		extraequipments.SetCaptionEnabled(false);
		extraequipments.deleteAfterClick = false;

		if (this !is null)
		{
			CBitStream params;
			params.write_u16(this.getNetworkID());

			int teamnum = this.getTeamNum();
			if (teamnum > 6) teamnum = 7;
			AddIconToken("$torsoimage$", Torso2Image, Vec2f(24, 24), TorsoFrame, teamnum);

			CGridButton@ torso = extraequipments.AddButton("$torsoimage$", "", this.getCommandID("equip2_torso"), Vec2f(1, 1), params);
			if (torso !is null)
			{
				if (this.get_string("equipment2_torso") != "") torso.SetHoverText("Unequip secondary torso.\n");
				else torso.SetHoverText("Equip secondary torso.\n");
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("equip_head") || cmd == this.getCommandID("equip_torso") || cmd == this.getCommandID("equip2_torso") || cmd == this.getCommandID("equip_boots"))
	{
		u16 callerID;
		if (!params.saferead_u16(callerID)) return;
		CBlob@ caller = getBlobByNetworkID(callerID);
		if (caller is null) return;
		if (caller.get_string("equipment_torso") != "" && cmd == this.getCommandID("equip_torso"))
			removeTorso(caller, caller.get_string("equipment_torso"));
		else if (caller.get_string("equipment2_torso") != "" && cmd == this.getCommandID("equip2_torso"))
			remove2Torso(caller, caller.get_string("equipment2_torso"));
		else if (caller.get_string("equipment_boots") != "" && cmd == this.getCommandID("equip_boots"))
			removeBoots(caller, caller.get_string("equipment_boots"));
		else if (caller.get_string("equipment_head") != "" && cmd == this.getCommandID("equip_head"))
			removeHead(caller, caller.get_string("equipment_head"));

		CBlob@ item = caller.getCarriedBlob();
		if (item !is null)
		{
			string eqName = item.getName();
			if (getEquipmentType(item) == "head" && cmd == this.getCommandID("equip_head"))
			{
				addHead(caller, eqName);
				if (eqName == "militaryhelmet" || eqName == "carbonhelmet" || eqName == "wilmethelmet" || eqName == "bucket" || eqName == "pumpkin" || 
					eqName == "scubagear" || eqName == "minershelmet") 
					caller.set_f32(eqName+"_health", item.get_f32("health"));

				if (item.hasTag("bushy")) caller.Tag("bushy");
				if (item.getQuantity() <= 1) item.server_Die();
				else item.server_SetQuantity(Maths::Max(item.getQuantity() - 1, 0));
			}
			else if (getEquipmentType(item) == "torso" && cmd == this.getCommandID("equip_torso"))
			{
				addTorso(caller, eqName);
				if (eqName == "bulletproofvest" || eqName == "carbonvest" || eqName == "wilmetvest" || eqName == "keg") caller.set_f32(eqName+"_health", item.get_f32("health"));
				item.server_Die();
			}
			else if (getEquipmentType(item) == "torso" && cmd == this.getCommandID("equip2_torso"))
			{
				add2Torso(caller, eqName);
				if (eqName == "bulletproofvest" || eqName == "carbonvest" || eqName == "wilmetvest" || eqName == "keg") caller.set_f32(eqName+"_health", item.get_f32("health"));
				item.server_Die();
			}
			else if (getEquipmentType(item) == "boots" && cmd == this.getCommandID("equip_boots"))
			{
				addBoots(caller, eqName);
				if (eqName == "combatboots" || eqName == "carbonboots" || eqName == "wilmetboots") caller.set_f32(eqName+"_health", item.get_f32("health"));
				item.server_Die();
			}
			else if (caller.getSprite() !is null && caller.isMyPlayer()) caller.getSprite().PlaySound("NoAmmo.ogg", 1.0f);
		}

		caller.ClearMenus();
	}
}

string getEquipmentType(CBlob@ equipment)
{
	if (equipment.hasTag("head")) return "head";
	else if (equipment.hasTag("torso")) return "torso";
	else if (equipment.hasTag("boots")) return "boots";

	return "nugat";		//haha yes.
}

void addHead(CBlob@ playerblob, string headname)	//Here you need to add head overriding. If you dont need to override head just ignore this part of script.
{
	if (playerblob.get_string("equipment_head") == "")
	{
		if (playerblob.get_u8("override head") != 0) playerblob.set_u8("last head", playerblob.get_u8("override head"));
		else playerblob.set_u8("last head", playerblob.getHeadNum());
	}

	if (headname == "scubagear")
	{
		playerblob.set_u8("override head", 88);
		playerblob.Tag("disguised");
	}
	else if (headname == "bucket")
	{
		playerblob.set_u8("override head", 107);
		playerblob.Tag("disguised");
	}
	else if (headname == "pumpkin")
	{
		playerblob.set_u8("override head", 108);
		playerblob.Tag("disguised");
	}
	else if (headname == "nvd")
	{
		if (playerblob.getSprite() !is null) playerblob.getSprite().AddScript("nvd_effect.as");
		playerblob.Tag("NoFlash");
	}

	playerblob.setHeadNum((playerblob.getHeadNum()+1) % 3);
	playerblob.Tag(headname);
	playerblob.set_string("reload_script", headname);

	playerblob.AddScript(headname+"_effect.as");

	playerblob.set_string("equipment_head", headname);
	playerblob.Tag("update head");
}

void removeHead(CBlob@ playerblob, string headname)
{
	if (playerblob.getSprite().getSpriteLayer(headname) !is null) playerblob.getSprite().RemoveSpriteLayer(headname);
	if (playerblob.getSprite().getSpriteLayer("bushy") !is null) playerblob.getSprite().RemoveSpriteLayer("bushy");
	if (headname == "minershelmet") playerblob.SetLight(false);	//example of removing custom tags like Light

	playerblob.Untag(headname);
	if (isServer())
	{
		CBlob@ oldeq = server_CreateBlob(headname, playerblob.getTeamNum(), playerblob.getPosition());
		if (headname == "militaryhelmet")	//need to be after creating blob, bcos it sets hp to it
		{
			if (playerblob.hasTag("bushy")) oldeq.Tag("bushy");
			oldeq.set_f32("health", playerblob.get_f32(headname+"_health"));
			oldeq.getSprite().SetFrameIndex(Maths::Floor(playerblob.get_f32(headname+"_health") / 6.26f));
		}
		else if (headname == "carbonhelmet" || headname == "wilmethelmet" || headname == "bucket" || headname == "pumpkin" || headname == "scubagear" || headname == "minershelmet")
		{
			oldeq.set_f32("health", playerblob.get_f32(headname+"_health"));
		}
		playerblob.server_PutInInventory(oldeq);
	}
	playerblob.set_u8("override head", playerblob.get_u8("last head"));
	playerblob.setHeadNum((playerblob.getHeadNum()+1) % 3);
	playerblob.set_string("equipment_head", "");
	playerblob.RemoveScript(headname+"_effect.as");
	playerblob.Tag("update head");
	playerblob.Untag("disguised");
	if (playerblob.hasTag("pax immune")) playerblob.Untag("pax immune");
	if (playerblob.hasTag("bushy")) playerblob.Untag("bushy");
	if (headname == "nvd" && playerblob.get_bool("nvd_state"))
	{
		if (playerblob.isMyPlayer())
		{
			if (getBlobByName("info_dead") !is null)
				getMap().CreateSkyGradient("Dead_skygradient.png");	
			else if (getBlobByName("info_magmacore") !is null)
				getMap().CreateSkyGradient("MagmaCore_skygradient.png");	
			else
				getMap().CreateSkyGradient("skygradient.png");	
			playerblob.set_bool("nvd_state", false);
			SetScreenFlash(65, 0, 255, 0, 0.1);
		}
		playerblob.Tag("NoFlash");
		if (playerblob.getSprite() !is null) playerblob.getSprite().RemoveScript("nvd_effect.as");
	}
}

void addTorso(CBlob@ playerblob, string torsoname)			//The same stuff as in head here.
{
	playerblob.Tag(torsoname);
	playerblob.set_string("reload_script", torsoname);
	playerblob.AddScript(torsoname+"_effect.as");
	playerblob.set_string("equipment_torso", torsoname);
}

void add2Torso(CBlob@ playerblob, string torsoname)			//The same stuff as in head here.
{
	playerblob.Tag(torsoname);
	playerblob.set_string("reload_script", torsoname);
	playerblob.AddScript(torsoname+"_effect.as");
	playerblob.set_string("equipment2_torso", torsoname);
}

void removeTorso(CBlob@ playerblob, string torsoname)		//Same stuff with removing again.
{
	if (torsoname == "suicidevest" && playerblob.hasTag("exploding")) return;
	if (torsoname == "parachutepack")
	{
		CSpriteLayer@ pack = playerblob.getSprite().getSpriteLayer("pack");
		if (pack !is null) playerblob.getSprite().RemoveSpriteLayer("pack");
		CSpriteLayer@ parachute = playerblob.getSprite().getSpriteLayer("parachute");
		if (parachute !is null)
		{
			if (parachute.isVisible()) ParticlesFromSprite(parachute);
			if (playerblob.hasTag("parachute")) playerblob.getSprite().PlaySound("join");
			playerblob.getSprite().RemoveSpriteLayer("parachute");
		}
		playerblob.Untag("parachute");
	}
	else if (playerblob.getSprite().getSpriteLayer(torsoname) !is null) playerblob.getSprite().RemoveSpriteLayer(torsoname);

	if (torsoname == "backpack")
	{
		CBlob@ backpackblob = getBlobByNetworkID(playerblob.get_u16("backpack_id"));
		if (backpackblob !is null) backpackblob.server_Die();
	}

	playerblob.Untag(torsoname);
	if (isServer())
	{
		CBlob@ oldeq = server_CreateBlob(torsoname, playerblob.getTeamNum(), playerblob.getPosition());
		if (torsoname == "bulletproofvest" || torsoname == "carbonvest" || torsoname == "wilmetvest" || torsoname == "keg") 
			oldeq.set_f32("health", playerblob.get_f32(torsoname+"_health"));
		playerblob.server_PutInInventory(oldeq);
	}
	
	playerblob.set_string("equipment_torso", "");
	playerblob.RemoveScript(torsoname+"_effect.as");
}

void remove2Torso(CBlob@ playerblob, string torsoname)		//Same stuff with removing again.
{
	if (torsoname == "suicidevest" && playerblob.hasTag("exploding")) return;
	if (torsoname == "parachutepack")
	{
		CSpriteLayer@ pack = playerblob.getSprite().getSpriteLayer("pack");
		if (pack !is null) playerblob.getSprite().RemoveSpriteLayer("pack");
		CSpriteLayer@ parachute = playerblob.getSprite().getSpriteLayer("parachute");
		if (parachute !is null)
		{
			if (parachute.isVisible()) ParticlesFromSprite(parachute);
			if (playerblob.hasTag("parachute")) playerblob.getSprite().PlaySound("join");
			playerblob.getSprite().RemoveSpriteLayer("parachute");
		}
		playerblob.Untag("parachute");
	}
	else if (playerblob.getSprite().getSpriteLayer(torsoname) !is null) playerblob.getSprite().RemoveSpriteLayer(torsoname);

	if (torsoname == "backpack")
	{
		CBlob@ backpackblob = getBlobByNetworkID(playerblob.get_u16("backpack_id"));
		if (backpackblob !is null) backpackblob.server_Die();
	}

	playerblob.Untag(torsoname);
	if (isServer())
	{
		CBlob@ oldeq = server_CreateBlob(torsoname, playerblob.getTeamNum(), playerblob.getPosition());
		if (torsoname == "bulletproofvest" || torsoname == "carbonvest" || torsoname == "wilmetvest" || torsoname == "keg") 
			oldeq.set_f32("health", playerblob.get_f32(torsoname+"_health"));
		playerblob.server_PutInInventory(oldeq);
	}
	
	playerblob.set_string("equipment2_torso", "");
	playerblob.RemoveScript(torsoname+"_effect.as");
}

void addBoots(CBlob@ playerblob, string bootsname)		//You still reading this?
{
	playerblob.Tag(bootsname);
	playerblob.set_string("reload_script", bootsname);
	playerblob.AddScript(bootsname+"_effect.as");
	playerblob.set_string("equipment_boots", bootsname);
}

void removeBoots(CBlob@ playerblob, string bootsname)		//I think you should already get how this works.
{
	if (bootsname == "flippers")
	{
		RunnerMoveVars@ moveVars;
		if (playerblob.get("moveVars", @moveVars)) moveVars.swimspeed -= 10.0f;
	}

	playerblob.Untag(bootsname);
	if (isServer())
	{
		CBlob@ oldeq = server_CreateBlob(bootsname, playerblob.getTeamNum(), playerblob.getPosition());
		if (bootsname == "combatboots" || bootsname == "carbonboots" || bootsname == "wilmetboots") oldeq.set_f32("health", playerblob.get_f32(bootsname+"_health"));
		playerblob.server_PutInInventory(oldeq);		
	}
	playerblob.set_string("equipment_boots", "");
	playerblob.RemoveScript(bootsname+"_effect.as");
}

void onDie(CBlob@ this)
{
    if (isServer())
	{
		string headname = this.get_string("equipment_head");
		string torsoname = this.get_string("equipment_torso");
		string torso2name = this.get_string("equipment2_torso");
		string bootsname = this.get_string("equipment_boots");

		if (headname != "")
		{
			if (headname == "carbonhelmet" || headname == "wilmethelmet" || headname == "bucket" || headname == "pumpkin" || headname == "scubagear" || headname == "minershelmet" || headname == "nvd")
			{
				CBlob@ item = server_CreateBlob(headname, this.getTeamNum(), this.getPosition());
				if (item !is null) item.set_f32("health", this.get_f32(headname+"_health"));
				this.RemoveScript(headname+"_effect.as");
			}
		}
		if (torsoname != "")
		{
			if (torsoname == "bulletproofvest" || torsoname == "carbonvest" || torsoname == "wilmetvest")
			{
				CBlob@ item = server_CreateBlob(torsoname, this.getTeamNum(), this.getPosition());
				if (item !is null) item.set_f32("health", this.get_f32(torsoname+"_health"));
				this.RemoveScript(torsoname+"_effect.as");
			}
			else if (!this.exists("vest_explode") && torsoname != "keg")
				server_CreateBlob(torsoname, this.getTeamNum(), this.getPosition());
		}
		if (torso2name != "")
		{
			if (torso2name == "bulletproofvest" || torso2name == "carbonvest" || torso2name == "wilmetvest")
			{
				CBlob@ item = server_CreateBlob(torso2name, this.getTeamNum(), this.getPosition());
				if (item !is null) item.set_f32("health", this.get_f32(torso2name+"_health"));
				this.RemoveScript(torso2name+"_effect.as");
			}
			else if (!this.exists("vest_explode") && torso2name != "keg")
				server_CreateBlob(torso2name, this.getTeamNum(), this.getPosition());
		}
		if (bootsname != "")
		{
			if (bootsname == "combatboots" || bootsname == "carbonboots" || bootsname == "wilmetboots")
			{
				CBlob@ item = server_CreateBlob(bootsname, this.getTeamNum(), this.getPosition());
				if (item !is null) item.set_f32("health", this.get_f32(bootsname+"_health"));
				this.RemoveScript(bootsname+"_effect.as");
			}
			else server_CreateBlob(bootsname, this.getTeamNum(), this.getPosition());
		}
	}
}
