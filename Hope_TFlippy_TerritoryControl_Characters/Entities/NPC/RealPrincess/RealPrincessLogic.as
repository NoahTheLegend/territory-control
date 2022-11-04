// Knight logic

#include "ThrowCommon.as"
#include "KnightCommon.as";
#include "RunnerCommon.as";
#include "Hitters.as";
#include "HittersTC.as";
#include "ShieldCommon.as";
#include "Knocked.as"
#include "Help.as";
#include "Requirements.as"
#include "ParticleSparks.as";

//attacks limited to the one time per-actor before reset.

void knight_actorlimit_setup(CBlob@ this)
{
	u16[] networkIDs;
	this.set("LimitedActors", networkIDs);
}

bool knight_has_hit_actor(CBlob@ this, CBlob@ actor)
{
	u16[]@ networkIDs;
	this.get("LimitedActors", @networkIDs);
	return networkIDs.find(actor.getNetworkID()) >= 0;
}

u32 knight_hit_actor_count(CBlob@ this)
{
	u16[]@ networkIDs;
	this.get("LimitedActors", @networkIDs);
	return networkIDs.length;
}

void knight_add_actor_limit(CBlob@ this, CBlob@ actor)
{
	this.push("LimitedActors", actor.getNetworkID());
}

void knight_clear_actor_limits(CBlob@ this)
{
	this.clear("LimitedActors");
}

void onInit(CBlob@ this)
{
	this.Tag("no drown");

	KnightInfo knight;
	knight.state = KnightStates::normal;
	knight.swordTimer = 0;
	knight.slideTime = 0;
	knight.doubleslash = false;
	knight.tileDestructionLimiter = 0;
	this.set("knightInfo", @knight);

	CSprite@ sprite = this.getSprite();

	this.set_f32("voice pitch", 2.00f);
	this.set_f32("gib health", -3.0f);
	this.getShape().SetRotationsAllowed(false);
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
	this.Tag("player");
	this.Tag("flesh");
	this.Tag("human");
	this.Tag("gas immune");

	this.set_u8("override head", 102);
	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	this.SetLight(false);
	this.SetLightRadius(64.0f);
	this.SetLightColor(SColor(255, 10, 250, 200));

	this.set_u32("timer", 0);
}

void onInit(CSprite@ this)
{

}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null) player.SetScoreboardVars("", 0, Vec2f(16, 16));
}

void onTick(CSprite@ this)
{

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
		moveVars.walkFactor *= 1.400f;
		moveVars.jumpFactor *= 1.000f;
	}

	u8 knocked = getKnocked(this);
	
	if (this.isInInventory())
		return;

	if (!this.get("moveVars", @moveVars))
	{
		return;
	}

	Vec2f pos = this.getPosition();
	Vec2f aimpos = this.getAimPos();
	const bool inair = (!this.isOnGround() && !this.isOnLadder());

	CMap@ map = getMap();

	bool pressed_a1 = this.isKeyPressed(key_action1) && !this.hasTag("noLMB");
	bool pressed_a2 = this.isKeyPressed(key_action2);
	bool walking = (this.isKeyPressed(key_left) || this.isKeyPressed(key_right));

	const bool myplayer = this.isMyPlayer();

	if (myplayer)
	{
		if (this.isKeyJustPressed(key_action3))
		{
			client_SendThrowOrActivateCommand(this);
		}
	}

	moveVars.walkFactor *= 1.400f;
	moveVars.jumpFactor *= 1.000f;

	if (knocked > 0)
	{
		pressed_a1 = false;
		pressed_a2 = false;
		walking = false;
		
		return;
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	CPlayer@ player = this.getPlayer();

	if (this.hasTag("invincible") || (player !is null && player.freeze)) 
	{
		return 0;
	}

	switch (customData)
	{
		case Hitters::suicide:
			damage *= 0.000f;
			break;

		case Hitters::explosion:
		case Hitters::keg:
		case Hitters::mine:
		case Hitters::mine_special:
		case Hitters::bomb:
		case Hitters::arrow:
		case Hitters::stab:
		case Hitters::sword:
		case Hitters::fall:
			damage *= 0.000f;
			break;

		case HittersTC::bullet_low_cal:
		case HittersTC::bullet_high_cal:
		case HittersTC::shotgun:
		case HittersTC::railgun_lance:
		case HittersTC::plasma:
		case HittersTC::forcefield:
		case HittersTC::electric:
		case HittersTC::radiation:
		case HittersTC::nanobot:
		case HittersTC::magix:
		case HittersTC::staff:
		case HittersTC::hammer:
		case HittersTC::foof:
		case HittersTC::poison:
		case HittersTC::disease:
			damage *= 0.000f;
			break;

		case Hitters::burn:
		case Hitters::fire:
		case Hitters::drown:
		case Hitters::water:
		case Hitters::water_stun:
		case Hitters::water_stun_force:
			damage = 0.000f;
			break;
			
		default:
			damage *= 0.000f;
			break;
	}

	return damage;
}

void onDie(CBlob@ this)
{
	if (isServer()) server_CreateBlob("", this.getTeamNum(), this.getPosition());
}
