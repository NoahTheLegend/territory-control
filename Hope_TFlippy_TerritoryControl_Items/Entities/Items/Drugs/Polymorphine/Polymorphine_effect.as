#include "Knocked.as";
#include "RunnerCommon.as";
#include "Hitters.as";
#include "HittersTC.as";
#include "EmotesCommon.as";
#include "RgbStuff.as";

const int polymorphine_duration = 45 * 8 * 1.30f;
const f32 polymorphine_step = 1.00f / polymorphine_duration;

void onInit(CBlob@ this)
{
	this.add_f32("polymorphine_effect", 1.00f);
	this.set_f32("voice pitch", 1.1f);

	if (isClient() && this.isMyPlayer()) 
	{
		CSprite@ sprite = this.getSprite();
		sprite.SetEmitSound("Disc_Kitasakaba.ogg");
		sprite.SetEmitSoundVolume(0.01f);
		sprite.SetEmitSoundSpeed(2.0f);
		sprite.SetEmitSoundPaused(false);
	}
}

const string[] randomBlobs = {
	"pus",
	"jellyfish",
	"fishy",
	"drone",
	"peasant",
	"builder",
	"rockman",
	"mithrilman",
	"mithrilguy",
	"pigger",
	"bagel",
	"shark",
	"badger",
	"civillianchicken",
	"commanderchicken",
	"soldierchicken",
	"amogus",
	"freak",
	"mound",
	"hoob"
};

void onTick(CBlob@ this)
{
	if (this.hasTag("dead") || !this.hasTag("flesh"))
	{
		CSprite@ sprite = this.getSprite();
		if (sprite !is null) sprite.SetEmitSoundPaused(true);
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("Disc_Kitasakaba.ogg");
		sprite.SetEmitSoundVolume(Maths::Min(sprite.getEmitSoundVolume() + 0.0005f, 0.25f));
	}

	f32 true_level = this.get_f32("polymorphine_effect");		
	f32 level = 0.50f + true_level;
	f32 withdrawal = 1.00f - Maths::Min(true_level, 1);

	if (true_level <= 0.00f)
	{
		if (isServer() && !this.hasTag("transformed"))
		{
			string blobName = randomBlobs[XORRandom(randomBlobs.length)];
			if (this.getConfig() != blobName)
			{
				CBlob@ blob = server_CreateBlob(blobName, this.getTeamNum(), this.getPosition());
				if (this.getPlayer() !is null) 
				{
					blob.server_SetPlayer(this.getPlayer());
				}

			}
			
			this.getSprite().PlaySound("Pigger_Gore", 0.50f, 1.00f);

			this.Tag("transformed");
			this.server_Die();
		}

		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
	else
	{
		if (true_level < 1.50f)
		{
			if (this.getTickSinceCreated() % (30 + XORRandom(60)) == 0)
			{
				SetKnocked(this, 20);
				if (isClient())
				{
					this.getSprite().PlaySound("TraderScream.ogg", 1.0f, 2.65f+XORRandom(115)*0.01f);
					
					if (this.isMyPlayer())
					{
						ShakeScreen(150.0f * (withdrawal + 0.10f), 1, this.getPosition());
					}
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
		}
		else
		{
			if (isClient())
			{
				if (this.isMyPlayer())
				{
					ShakeScreen(15.0f * (withdrawal + 0.10f), 1, this.getPosition());
					
					if (XORRandom(100 * true_level) == 0)
					{
						u8 emote = 0;
						if (true_level < 1.40f) emote = Emotes::dismayed;
						else if (true_level < 1.80f) emote = Emotes::question;
						else if (true_level < 2.60f) emote = Emotes::question;
						else emote = Emotes::heart;
						set_emote(this, emote);
					}
				}
			}
		}
		
		this.add_f32("polymorphine_effect", -polymorphine_step);
	}
}
