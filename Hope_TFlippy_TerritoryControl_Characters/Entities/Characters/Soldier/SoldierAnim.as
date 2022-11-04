#include "FireCommon.as"
#include "Requirements.as"
#include "RunnerAnimCommon.as"
#include "RunnerCommon.as"
#include "Knocked.as"
#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "SoldierCommon.as";

const string shiny_layer = "shiny bit";

void onInit(CSprite@ this)
{
	addRunnerTextures(this, "soldat", "Soldier");

	this.getCurrentScript().runFlags |= Script::tick_not_infire;
}

void onPlayerInfoChanged(CSprite@ this)
{
	addRunnerTextures(this, "soldat", "Soldier");
}

void onTick(CSprite@ this)
{
	// store some vars for ease and speed
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	Vec2f pos = blob.getPosition();
	Vec2f aimpos;

	KnightInfo@ knight;
	if (!blob.get("knightInfo", @knight))
	{
		return;
	}

	const u8 knocked = getKnocked(blob);

	bool shieldState = isShieldState(knight.state);
	bool specialShieldState = isSpecialShieldState(knight.state);
	bool swordState = isSwordState(knight.state);

	bool pressed_a1 = blob.isKeyPressed(key_action1);
	bool pressed_a2 = blob.isKeyPressed(key_action2);

	bool walking = (blob.isKeyPressed(key_left) || blob.isKeyPressed(key_right));

	aimpos = blob.getAimPos();
	bool inair = (!blob.isOnGround() && !blob.isOnLadder());

	Vec2f vel = blob.getVelocity();

	if (blob.hasTag("dead"))
	{
		this.SetAnimation("dead");
		return;
	}

	// get the angle of aiming with mouse
	Vec2f vec;
	int direction = blob.getAimDirection(vec);
	
	const bool left = blob.isKeyPressed(key_left);
	const bool right = blob.isKeyPressed(key_right);
	
	if (blob.hasTag("dead"))
	{
		this.SetAnimation("dead");
		Vec2f vel = blob.getVelocity();

		if (vel.y < -1.0f)
		{
			this.SetFrameIndex(0);
		}
		else if (vel.y > 1.0f)
		{
			this.SetFrameIndex(2);
		}
		else
		{
			this.SetFrameIndex(1);
		}
		return;
	}
	else if (knight.state == KnightStates::sword_cut_mid)
	{
		this.SetAnimation("strike_mid");
	}
	else if (knight.state == KnightStates::sword_cut_mid_down)
	{
		this.SetAnimation("strike_mid");
	}
	else if (knight.state == KnightStates::sword_cut_up)
	{
		this.SetAnimation("strike_up");
	}
	else if (knight.state == KnightStates::sword_cut_down)
	{
		this.SetAnimation("strike_down");
	}
	else if (inair)
	{
		RunnerMoveVars@ moveVars;
		if (!blob.get("moveVars", @moveVars))
		{
			return;
		}
		f32 vy = vel.y;
		if (vy < -0.0f && moveVars.walljumped)
		{
			this.SetAnimation("run");
		}
		else
		{
			this.SetAnimation("fall");
			this.animation.timer = 0;

			if (vy < -1.5)
			{
				this.animation.frame = 0;
			}
			else if (vy > 1.5)
			{
				this.animation.frame = 2;
			}
			else
			{
				this.animation.frame = 1;
			}
		}
	}
	else if (right || left)
	{
		this.SetAnimation("run");
	}
	else if (walking ||
	         (blob.isOnLadder() && (blob.isKeyPressed(key_up) || blob.isKeyPressed(key_down))))
	{
		this.SetAnimation("run");
	}
	else if (knocked > 0)
	{
		if (inair)
		{
			this.SetAnimation("knocked_air");
		}
		else
		{
			this.SetAnimation("knocked");
		}
	}
	else if (blob.hasTag("seated") || blob.isKeyPressed(key_down))
	{
		this.SetAnimation("crouch");
	}
	else this.SetAnimation("idle");

	CSpriteLayer@ chop = this.getSpriteLayer("chop");

	bool wantsChopLayer = false;
	s32 chopframe = 0;
	f32 chopAngle = 0.0f;

	if (chop !is null)
	{
		chop.SetVisible(wantsChopLayer);
		if (wantsChopLayer)
		{
			//printf("e");
			f32 choplength = 5.0f;

			chop.animation.frame = chopframe;
			Vec2f offset = Vec2f(choplength, 0.0f);
			offset.RotateBy(chopAngle, Vec2f_zero);
			if (!this.isFacingLeft())
				offset.x *= -1.0f;
			offset.y += this.getOffset().y * 0.5f;

			chop.SetOffset(offset);
			chop.ResetTransform();
			if (this.isFacingLeft())
				chop.RotateBy(180.0f + chopAngle, Vec2f());
			else
				chop.RotateBy(chopAngle, Vec2f());
		}
	}
	//set the head anim
	if (knocked > 0)
	{
		blob.Tag("dead head");
	}
	else if (blob.isKeyPressed(key_action2))
	{
		blob.Tag("attack head");
		blob.Untag("dead head");
	}
	else
	{
		blob.Untag("attack head");
		blob.Untag("dead head");
	}
}

void onGib(CSprite@ this)
{
	if (g_kidssafe)
	{
		return;
	}

	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();
	Vec2f vel = blob.getVelocity();
	vel.y -= 3.0f;
	f32 hp = Maths::Min(Maths::Abs(blob.getHealth()), 2.0f) + 1.0f;
	const u8 team = blob.getTeamNum();
	
	if(!isClient()){return;}
	CParticle@ Body     = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 0, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Arm      = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp - 0.2 , 80), 1, 0, Vec2f(16, 16), 2.0f, 20, "/BodyGibFall", team);
	CParticle@ Shield   = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp , 80), 2, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
	CParticle@ Sword    = makeGibParticle("Entities/Characters/Knight/KnightGibs.png", pos, vel + getRandomVelocity(90, hp + 1 , 80), 3, 0, Vec2f(16, 16), 2.0f, 0, "Sounds/material_drop.ogg", team);
}


// render cursors

void DrawCursorAt(Vec2f position, string& in filename)
{
	position = getMap().getAlignedWorldPos(position);
	if (position == Vec2f_zero) return;
	position = getDriver().getScreenPosFromWorldPos(position - Vec2f(1, 1));
	GUI::DrawIcon(filename, position, getCamera().targetDistance * getDriver().getResolutionScaleFactor());
}

const string cursorTexture = "Entities/Characters/Sprites/TileCursor.png";

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (!blob.isMyPlayer())
	{
		return;
	}
	if (getHUD().hasButtons())
	{
		return;
	}

	// draw tile cursor

	if (blob.isKeyPressed(key_action1))
	{
		CMap@ map = blob.getMap();
		Vec2f position = blob.getPosition();
		Vec2f cursor_position = blob.getAimPos();
		Vec2f surface_position;
		map.rayCastSolid(position, cursor_position, surface_position);
		Vec2f vector = surface_position - position;
		f32 distance = vector.getLength();
		Tile tile = map.getTile(surface_position);

		if ((map.isTileSolid(tile) || map.isTileGrass(tile.type)) && map.getSectorAtPosition(surface_position, "no build") is null && distance < 16.0f)
		{
			DrawCursorAt(surface_position, cursorTexture);
		}
	}
}
