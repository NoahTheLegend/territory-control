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
	CSprite@ sprite = this.getSprite();

	KnightInfo knight;

	knight.state = KnightStates::normal;
	knight.swordTimer = 0;
	knight.slideTime = 0;
	knight.doubleslash = false;
	knight.tileDestructionLimiter = 0;

	this.set("knightInfo", @knight);

	this.set_f32("gib health", -3.0f);
	knight_actorlimit_setup(this);
	this.getShape().SetRotationsAllowed(false);
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
	this.Tag("player");
	this.Tag("flesh");
	this.Tag("human");
	this.Tag("gas immune");
	this.Tag("no beamtower damage");

	this.set_u32("next warp", 0);
	// this.set_u32("last hit", 0);

	this.set_u8("override head", 124);

	this.set_Vec2f("inventory offset", Vec2f(0.0f, 0.0f));

	this.getSprite().PlaySound("scyther-intro.ogg", 0.25, 0.75f);

	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	this.SetLight(false);
	this.SetLightRadius(16.0f);
	this.SetLightColor(SColor(255, 255, 155, 55));

	this.set_u32("timer", 0);
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null) player.SetScoreboardVars("ScoreboardIcons.png", 28, Vec2f(16, 16));
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	u32 time = getGameTime();

	// this.setRenderStyle(blob.get_u32("last hit") + 10 > time ? RenderStyle::additive : RenderStyle::normal);

	// this.setRenderStyle(blob.isKeyPressed(key_action1) && !blob.hasTag("noLMB") ? RenderStyle::shadow : RenderStyle::normal);
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

	u8 knocked = getKnocked(this);

	if (this.isInInventory()) return;

	if (!this.get("moveVars", @moveVars)) return;

	u32 time = getGameTime();
	if (isServer() && time % 90 == 0)
	{
		f32 maxHealth = this.getInitialHealth();
		if (this.getHealth() < maxHealth)
		{
			this.server_SetHealth(Maths::Min(this.getHealth() + 0.125f, maxHealth));
		}
	}

	Vec2f pos = this.getPosition();
	Vec2f aimpos = this.getAimPos();
	const bool inair = (!this.isOnGround() && !this.isOnLadder());

	CMap@ map = getMap();

	bool pressed_a1 = this.isKeyPressed(key_action1) && !this.hasTag("noLMB");
	bool pressed_a2 = this.isKeyPressed(key_action2) && !this.hasTag("noRMB");
	bool walking = (this.isKeyPressed(key_left) || this.isKeyPressed(key_right));

	const bool myplayer = this.isMyPlayer();

	if (myplayer)
	{
		if (this.isKeyJustPressed(key_action3))
		{
			client_SendThrowOrActivateCommand(this);
		}
	}

	moveVars.walkFactor *= 1.15f;
	moveVars.jumpFactor *= 1.25f;

	this.SetLight(pressed_a1);

	// if (isServer() && time % 90 == 0) this.server_Heal(0.25f); // OP

	if (knocked > 0)
	{
		// pressed_a1 = false;
		pressed_a2 = false;
		walking = false;

		return;
	}

	if (pressed_a2 && getMap() !is null && this.get_u32("next_ability") < getGameTime())
	{
		Vec2f thisPos = this.getPosition();
		Vec2f blobPos;

		CBlob@[] blobs;
		f32 radius = 92.0f;
		getMap().getBlobsInRadius(this.getPosition(), radius, @blobs);
		u16 zaps_amount;
		
		for (u16 i = 0; i < blobs.length; i++)
		{
			zaps_amount++;
			CBlob@ b = blobs[i];
			if (b is null || b.hasTag("dead") || !b.hasTag("flesh") || b is this) continue;
			
			blobPos = b.getPosition();
			f32 mod = (radius/3) * ((92.0f-(thisPos - blobPos).Length()) / (radius/30));
			Vec2f dir = blobPos - thisPos;
			f32 dist = Maths::Abs(dir.Length());
			dir.Normalize();

			b.AddForce(Vec2f(1, 0).RotateBy(-dir.Angle()) * mod);

			if (isClient())
			{
				bool flip = this.isFacingLeft();

				CSpriteLayer@ zap = this.getSprite().addSpriteLayer("zap"+i, "Zapper_Lightning.png", 128, 12);
				if (zap !is null)
				{
					zap.ResetTransform();
					zap.SetFrameIndex(0);
					zap.ScaleBy(Vec2f(dist / 128.0f - 0.1f, 1.0f));
					zap.TranslateBy(Vec2f((dist / 2), 2.0f));
					zap.RotateBy(-dir.Angle(), Vec2f());
					zap.SetVisible(true);
				}
			}
		}

		this.getSprite().PlaySound("Exosuit_Teleport.ogg", 1.0f, 0.75f+(XORRandom(15)*0.01f));

		this.set_u16("zaps_amount", zaps_amount);
		this.set_u32("next_ability", getGameTime()+225);
	}
	if (getGameTime() >= this.get_u32("next_ability")-223)
	{
		if (this.get_u16("zaps_amount") > 1000) this.set_u16("zaps_amount", 0);
		for (u16 i = 0; i < this.get_u16("zaps_amount"); i++)
		{
			CSpriteLayer@ l = this.getSprite().getSpriteLayer("zap"+i);
			if (l !is null) l.SetVisible(false);
			this.getSprite().RemoveSpriteLayer("zap"+i);
		}
		this.set_u16("zaps_amount", 0);
	}
}

void DrawGhost(CSprite@ this, u8 index, Vec2f startPos, f32 length, f32 angle, bool flip)
{
	CSpriteLayer@ ghost = this.getSpriteLayer("ghost");

	ghost.ResetTransform();
	//ghost.ScaleBy(Vec2f(length, 1.0f));
	ghost.TranslateBy(Vec2f(length * (flip ? 1 : -1), 0));
	ghost.SetOffset(Vec2f(32, 0));
	ghost.RotateBy(angle + (flip ? 180 : 0), Vec2f(32 * (flip ? 1 : -1), 0.0f));
	ghost.SetVisible(true);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	CPlayer@ player = this.getPlayer();

	if (this.hasTag("invincible") || (player !is null && player.freeze)) 
	{
		return 0;
	}

	bool recursionPrevent = false;

	switch (customData)
	{
		case Hitters::stomp:
			recursionPrevent = true;
			break;

		case Hitters::suicide:
			damage *= 10.0f;
			break;

		case Hitters::stab:
		case Hitters::sword:
			damage *= 0.75f;
			break;

		case Hitters::explosion:
		case Hitters::keg:
		case Hitters::mine:
		case Hitters::mine_special:
		case Hitters::bomb:
		case Hitters::fall:
			damage *= 0.85f;
			this.getSprite().PlaySound("Exosuit_Hit.ogg", 1, 1);
			break;

		case Hitters::arrow:
			damage *= 0.1f; 
			break;

		case Hitters::burn:
		case Hitters::fire:
		case HittersTC::radiation:
			damage = 0.15f;
			break;

		case HittersTC::electric:
			damage = 5.00f;
			break;

		default:
			damage *= 0.6f;
			this.getSprite().PlaySound("Exosuit_Hit.ogg", 1.0f, 0.85f);
			break;
	}

	if (hitterBlob !is null && hitterBlob !is this && this.isKeyPressed(key_action1) && !this.hasTag("noLMB"))
	{
		f32 damage_received = 0;
		f32 damage_reflected = 0;

		switch (customData)
		{
			case HittersTC::railgun_lance:
			case HittersTC::hammer:
			case Hitters::crush:
			case Hitters::fall:
				damage_received = damage * 0.85f;
				break;

			case Hitters::spikes:
			case Hitters::builder:
			case Hitters::arrow:
				damage_received = damage * 0.65f;
				break;

			case HittersTC::bullet_high_cal:
			case HittersTC::electric:
				damage_received = damage * 0.65f;
				break;

			case HittersTC::shotgun:
			case HittersTC::bullet_low_cal:
				damage_received = damage * 0.35f;
				break;

			default:
				damage_received = 0.05f;
				break;
		}

		return damage_received;
	}
	else
	{
		return damage;
	}
}

void onDie(CBlob@ this)
{
	if (isServer()) server_CreateBlob("robosuititem", this.getTeamNum(), this.getPosition());
}
