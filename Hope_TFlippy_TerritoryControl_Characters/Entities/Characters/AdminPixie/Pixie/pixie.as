#include "godCommon.as"//

SColor[] colors =
{
	SColor(255, 50, 20, 255), // Blue
	SColor(255, 255, 50, 20), // Red
	SColor(255, 50, 255, 20), // Green
	SColor(255, 255, 20, 255), // Purple
	SColor(255, 255, 128, 20), // Orange
	SColor(255, 20, 255, 255), // Cyan
	SColor(255, 128, 128, 255), // Violet
};

void onInit(CBlob@ this)
{
    this.set_bool("gravity",false);
    this.set_bool("noclip",true);
    this.Tag("notarget"); //makes AI never target us
	this.Tag("noCapturing");
	//this.Tag("truesight");
	this.set_f32("voice pitch", 2.00f);
	this.Tag("no_invincible_removal");
	
	this.SetLight(true);
	this.SetLightRadius(80.0f);
	this.SetLightColor(this.getTeamNum() < colors.length ? colors[this.getTeamNum()] : SColor(255, 255, 255, 255));
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null)
	{
		player.SetScoreboardVars("PixieIcon.png", 0, Vec2f(16, 16));
	}
}

void onTick(CBlob@ this)
{
    CShape@ shape = this.getShape();
    shape.SetGravityScale(this.get_bool("gravity") ? 1 : 0);
    shape.getConsts().mapCollisions = !this.get_bool("noclip");
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}

f32 onHit( CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData )
{
    this.getSprite().PlaySound("PixieHit.ogg",1,(XORRandom(15)/10.0) + 0.5);

    return 0;
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	this.SetLightColor(this.getTeamNum() < colors.length ? colors[this.getTeamNum()] : SColor(255, 255, 255, 255));
}