// Knight logic

#include "ThrowCommon.as"
#include "Knocked.as"
#include "Help.as";
#include "Requirements.as"
//attacks limited to the one time per-actor before reset.

void onInit(CBlob@ this)
{
	this.Tag("no drown");

	CSprite@ sprite = this.getSprite();

	this.set_f32("voice pitch", 1.11f);

	this.getShape().SetRotationsAllowed(false);
	this.Tag("player");
	this.Tag("flesh");
	this.Tag("human");
	this.Tag("gas immune");

	this.set_u32("timer", 0);

	if (getBlobByName('cube') is null || !isClient()) return;

	for (u8 i = 0; i < 200; i++)
	{
		CSpriteLayer@ l = sprite.addSpriteLayer("l"+i, this.getSprite().getConsts().filename, 24, 24);
		if (l !is null)
		{
			l.SetRelativeZ(sprite.getRelativeZ()-2000+i*20);
			l.SetOffset(sprite.getOffset());
		}
	}
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null) player.SetScoreboardVars("AmogusPlushie.png", 0, Vec2f(16, 16));
}

void onTick(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	u8 knocked = getKnocked(this);
	
	if (this.isInInventory())
		return;

	Vec2f pos = this.getPosition();
	Vec2f aimpos = this.getAimPos();
	const bool inair = (!this.isOnGround() && !this.isOnLadder());

	if (isClient() && getBlobByName('cube') !is null)
	{
		for (u8 i = 0; i < 200; i++)
		{
			CSpriteLayer@ l = sprite.getSpriteLayer("l"+i);
			if (l !is null)
			{
				l.SetFrameIndex(sprite.getFrameIndex());
				f32 t = (getGameTime() + i) * 0.1f;
				f32 x = Maths::Sin(t) * 15+Maths::Sin(t)*20;
				f32 y = Maths::Sin(2 * t) * 15;
				l.SetOffset(sprite.getOffset() + Vec2f(x, y));
			}
		}
		sprite.SetVisible(false);
	}
	else sprite.SetVisible(false);

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

	if (knocked > 0)
	{
		pressed_a1 = false;
		pressed_a2 = false;
		walking = false;
		
		return;
	}
}

void onDie(CBlob@ this)
{
	if (isServer()) server_CreateBlob("amogusplushie", this.getTeamNum(), this.getPosition());
}
