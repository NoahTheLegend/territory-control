void onInit(CSprite@ this)
{
	this.SetEmitSound("Mystical_EnergySwordHumLoop5.ogg");
    this.SetEmitSoundVolume(1.0f);
    this.SetEmitSoundSpeed(0.25f);
    this.SetEmitSoundPaused(false);

	f32 d = -90.0f;
	for (u8 i = 0; i < 4; i++)
	{	
		CSpriteLayer@ f = this.addSpriteLayer("turbinefire"+i, "Effect_Fire", 40, 16);
		if (f !is null)
		{
			Animation@ fanim = f.addAnimation("fsize", 3, true);
			if (fanim !is null)
			{
				int[] frames = {0,1,2};
				fanim.AddFrames(frames);
				f.SetAnimation(fanim);
			}
			f.RotateByDegrees(d, Vec2f(0,0));
			f.SetOffset(Vec2f(i == 0 ? -8 : i == 1 ? 8 : i == 2 ? 22 : -22, 106));
			f.ScaleBy(i < 2 ? Vec2f(0.75,0.75) : Vec2f(0.6,0.6));
			f.SetVisible(false);
		}
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	if (isClient() && blob.get_u32("preptimer") == getGameTime())
	{
		for (u8 i = 0; i < 4; i++)
		{
			CSpriteLayer@ fire = this.getSpriteLayer("turbinefire"+i);
			if (fire !is null)
			{
				fire.SetVisible(true);
				fire.SetAnimation("fsize");
			}
		}
		
		blob.SetLight(true);
		blob.SetLightRadius(256.0f);
		blob.SetLightColor(SColor(255, 255, 100, 0));
	}
}

void MakeParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	Vec2f offset = Vec2f(XORRandom(49)-24, 100+XORRandom(16));

	if (!isClient()) return;
    for (u8 i = 0; i < 10; i++)
    {
	    ParticleAnimated(filename, this.getPosition() + offset, Vec2f(0, 0.5+XORRandom(10)/10), float(XORRandom(360)), 1.5f, 2 + XORRandom(3), 0.25f, false);
    }
}