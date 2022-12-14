#include "Knocked.as";
#include "RunnerCommon.as";
#include "Hitters.as";
#include "HittersTC.as";
#include "MakeDustParticle.as";

const f32 increment = 1.00f / (30.00f * 30.00f);
const f32 health_increment = 0.25f;

void onInit(CBlob@ this)
{
	f32 pitch = this.getSexNum() == 0 ? 1.0f : 1.5f;
	this.getSprite().PlaySound("eeeeeeeeeeeeeeee.ogg", 1.00f, pitch);
}

void onTick(CBlob@ this)
{
	const f32 value = this.get_f32("gooby_effect");

	if (this.hasTag("dead"))
	{
		this.getCurrentScript().runFlags |= Script::remove_after_this;
		return;
	}

	if (value > 0.00f)
	{
		if (this.getTickSinceCreated() % 4 == 0)
		{
			f32 maxHealth = Maths::Ceil(Maths::Min(this.getInitialHealth() * 10.00f, this.getInitialHealth() + 20));
			if (this.getHealth() < maxHealth)
			{				
				if (isServer())
				{
					this.server_SetHealth(Maths::Min(this.getHealth() + health_increment, maxHealth));
				}
				
				if (isClient())
				{
					if (this.isMyPlayer()) this.getSprite().PlaySound("heart.ogg", 0.50f, 1.00f);
				
					for (int i = 0; i < 4; i++)
					{
						ParticleAnimated("HealParticle.png", this.getPosition() + Vec2f(XORRandom(16) - 8, XORRandom(16) - 8), Vec2f(0, f32(XORRandom(100) * -0.02f)) * 0.25f, 0, 0.5f, 10, 0, true);
					}
				}
			}
		}
	}
	else
	{	
		if (XORRandom(20) == 0)
		{
			if (!this.hasTag("no_suicide")) this.Tag("no_suicide");
		
			if (isClient())
			{
				this.getSprite().PlaySound("Pus_Attack_0.ogg", 1.50f, 1.00f);
				
				ParticleBloodSplat(this.getPosition(), true);
				
				if (this.isMyPlayer())
				{
					SetScreenFlash(255, 100, 0, 0, 0.50f);
					ShakeScreen2(200.0f, 30.0f, this.getPosition());

						if (getBlobByName("info_dead") !is null)
							getMap().CreateSkyGradient("Dead_skygradient.png");	
						else if (getBlobByName("info_magmacore") !is null)
							getMap().CreateSkyGradient("MagmaCore_skygradient.png");	
						else
							getMap().CreateSkyGradient("skygradient.png");	
				}
				
				CSprite@ sprite = this.getSprite();
				sprite.SetEmitSound("Rippio_Scream.ogg");
				sprite.SetEmitSoundVolume(1.50f);
				sprite.SetEmitSoundSpeed((this.getSexNum() == 0 ? 0.0f : 1.0f) + 0.75f + (XORRandom(100) / 400.00f));
				sprite.SetEmitSoundPaused(false);
			}

			if (isServer())
			{
				this.server_Hit(this, this.getPosition(), Vec2f(0, 0), 0.125f, Hitters::stab, true);
			}
		}
		
		Vec2f vel = this.getVelocity();
		if (Maths::Abs(vel.x) > 0.1)
		{
			f32 angle = this.get_f32("angle");
			angle += vel.x * this.getRadius();
			if (angle > 360.0f) angle -= 360.0f;
			else if (angle < -360.0f) angle += 360.0f;
			
			this.set_f32("angle", angle);
			this.setAngleDegrees(angle);
		}
		
		if (isClient())
		{			
			Vec2f pos = this.getPosition();
			for (int i = 0; i < 2; i++)
			{
				Vec2f vel = getRandomVelocity(0, XORRandom(400) * 0.003f * value, 360);
			
				CParticle@ p = ParticleBlood(pos + vel, vel * -1.0f, SColor(255, 126, 0, 0));
				if (p !is null)
				{
					p.timeout = 10 + XORRandom(60);
					p.scale = 2.00f;
					p.fastcollision = true;
					// p.stretches = true;
				}
			}
		
			if (this.isMyPlayer())
			{
				ShakeScreen2(200.0f, 30.0f, this.getPosition());
				SetScreenFlash(50, 100, 0, 0, 0.10f);
			}
		}
	}
			
	// print("" + value);
	this.set_f32("gooby_effect", value - increment);
}