//Ghost logic

#include "Hitters.as";
#include "Knocked.as";
#include "ThrowCommon.as";
#include "RunnerCommon.as";
#include "Help.as";
#include "Requirements.as"

void onInit(CBlob@ this)
{
	//this.Tag("noBubbles"); this is for disabling emoticons, we won't need that.
	this.Tag("notarget"); //makes AI never target us
	this.Tag("noCapturing");
	this.Tag("truesight");

	this.addCommandID("emote");

	this.Tag("noUseMenu");
	this.set_f32("gib health", -3.0f);

	this.getShape().getConsts().mapCollisions = false;

	this.Tag("player");
	this.Tag("invincible");
	this.Tag("no_invincible_removal");

	CShape@ shape = this.getShape();
	shape.SetRotationsAllowed(true);
	shape.getConsts().net_threshold_multiplier = 0.5f;

	this.set_Vec2f("inventory offset", Vec2f(0.0f, -152.0f));

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";

	if(!isClient()){return;}

	this.set_u8("rot", 1);
	this.set_bool("increment", true);
	this.set_f32("rotation", 0);
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null)
	{
		/*player.server_setTeamNum(-1);
		this.server_setTeamNum(-1);*/
		player.SetScoreboardVars("ScoreboardIcons.png", 1, Vec2f(16, 16));
		//client_AddToChat(player.getUsername() + " has entered the " + (this.getSexNum() == 0 ? "Grandpa" : "Grandma") + " Administrator mode!", SColor(255, 255, 80, 150));
	}
}


void onTick(CBlob@ this)
{
	if (this.isKeyPressed(key_action1)) this.AddForce(this.getAimPos()-this.getPosition());
	CSprite@ sprite = this.getSprite();
	CMap@ map = this.getMap();
	if (map !is null)
	{
		if (this.getPosition().y > map.tilemapheight*8-24) this.AddForce(Vec2f(0, -1000.0f));
	}
	if (sprite !is null)
	{
		//if (this.isKeyPressed(key_action2))
		//{
		//	if (this.isKeyJustPressed(key_action2))
		//	{
		//		this.set_u8("rot", 0);
		//		this.set_bool("increment", true);
		//	}
		//	this.get_bool("increment") ? this.add_u8("rot", 1) : this.add_u8("rot", -1);
		//	if (this.get_u8("rot") >= 60 || this.get_u8("rot") == 0) this.set_bool("increment", !this.get_bool("increment"));
		//	u8 mod = this.get_u8("rot");
		//	u32 gametime = getGameTime();
		//	this.isFacingLeft() ? sprite.RotateBy(-1.0f*mod, Vec2f(0,0)) : sprite.RotateBy(1.0f*mod, Vec2f(0,0));
		//}

	}
	if (this.isInInventory()) return;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return 0;
}
