// Peasant logic
const s32 hit_frame = 1;
const f32 hit_damage = 1.5f;
void onInit(CBlob@ this)
{
	//this.Tag("human");

	this.set_f32("mining_multiplier", 0.00f);
	this.set_u8("mining_hardness", 100);
	this.set_f32("max_build_length", 7.00f);
	this.set_u32("build delay", 1);
	this.Tag("no_invincible_removal");
	
	//this.Tag("player");
	this.Tag("admin");
	
	//this.Tag("notarget"); //makes AI never target us
}

void onTick(CBlob@ this)
{
	this.Tag("invincible");
	this.Tag("invincibilityByVehicle");
	this.Tag("gas immune");
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null) player.SetScoreboardVars("AmogusPlushie.png", 0, Vec2f(16, 16));
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return 0;
}

void onDie(CBlob@ this)
{
	if (isServer()) server_CreateBlob("amogusplushie", this.getTeamNum(), this.getPosition());
}
