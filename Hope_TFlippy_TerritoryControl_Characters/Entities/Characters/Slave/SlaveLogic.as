#include "RunnerCommon.as";
#include "Hitters.as";

const f32 bite_freq = 30*30;

void onInit(CBlob@ this)
{
	this.Tag("remote_storage");

	this.Tag("player");
	this.Tag("flesh");
	this.Tag("neutral");
	this.Tag("human");

	this.addCommandID("bite");

	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));
	this.set_f32("mining_multiplier", 3.0f);
	this.set_u32("build delay", 8);

	this.set_u32("next_bite", 0);

	if (isServer())
	{
		this.server_setTeamNum(150);

		CBlob@ ball = server_CreateBlobNoInit("slaveball");
		ball.setPosition(this.getPosition());
		ball.server_setTeamNum(-1);
		ball.set_u16("slave_id", this.getNetworkID());
		ball.Init();
	}

	this.set_u8("mining_hardness", 0);
	this.getSprite().PlaySound("shackles_success.ogg", 1.25f, 1.00f);

	this.set_u32("timer", 0);
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null) player.SetScoreboardVars("ScoreboardIcons.png", 7, Vec2f(16, 16));
}

void onTick(CBlob@ this)
{
	if (this.get_u32("timer") > 1) this.set_u32("timer", this.get_u32("timer") - 1);

	RunnerMoveVars@ moveVars;
	if (!this.get("moveVars", @moveVars))
	{
		return;
	}

	if (this.get_string("equipment_torso") != "" && this.get_string("equipment2_torso") != "")
	{
		moveVars.walkFactor *= 0.9f;
		moveVars.jumpFactor *= 0.95f;
	}

	if (this.hasTag("glued") && this.get_u32("timer") > 1)
	{
		moveVars.walkFactor *= 0.4f;
		moveVars.jumpFactor *= 0.5f;
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return forBlob !is this;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	//print("" + customData);

	CPlayer@ player=this.getPlayer();

	if (this.hasTag("invincible") || (player !is null && player.freeze))
	{
		return 0;
	}

	switch(customData)
	{
		case Hitters::nothing:
		case Hitters::suicide:
		case Hitters::fall:
			damage = 0;
			break;
	}

	return damage;
}

// bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
// {
	// return byBlob.getName() != "slave";
// }


void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu @gridmenu)
{
	Vec2f ul = gridmenu.getUpperLeftPosition();
	Vec2f lr = gridmenu.getLowerRightPosition();

	this.ClearGridMenusExceptInventory();
	Vec2f pos = Vec2f(lr.x, ul.y) + Vec2f(-96, 152);
	CGridMenu@ menu = CreateGridMenu(pos, this, Vec2f(1, 1), "Bite yourself!");

	this.set_Vec2f("InventoryPos",pos);

	AddIconToken("$bite$", "Bite.png", Vec2f(16, 16), 1);

	if (menu !is null)
	{
		menu.deleteAfterClick = true;

		CGridButton@ button = menu.AddButton("$bite$", "Bite yourself!", this.getCommandID("bite"));
		if (button !is null)
		{
			button.SetEnabled(this.get_u32("next_bite") < getGameTime());
			button.selectOneOnClick = false;
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("bite"))
	{
		if (this.get_u32("next_bite") > getGameTime()) return;
		this.set_u32("next_bite", getGameTime()+bite_freq);

		if (isServer())
			this.server_Hit(this, this.getPosition(), Vec2f_zero, 0.5f, Hitters::bite, false);

		if (isClient() && this.getSprite() !is null)
		{
			this.getSprite().PlaySound("ZombieBite.ogg");
			this.getSprite().PlaySound("TraderScream.ogg", 0.8f, this.getSexNum() == 0 ? 1.0f : 2.0f);
		}
	}
}