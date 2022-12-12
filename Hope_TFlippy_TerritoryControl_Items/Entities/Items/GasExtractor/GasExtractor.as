#include "MakeMat.as";
#include "Knocked.as";
#include "GunCommon.as";
#include "Hitters.as";

f32 maxDistance = 80;
const uint splash_halfwidth = 6.0f / 2;
const uint splash_halfheight = 2.0f / 2;
const f32 splash_offset = 0.0f;

void onInit(CBlob@ this)
{
	this.Tag("no shitty rotation reset");

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1 | key_action2);
	}

	this.getCurrentScript().tickFrequency = 1;
	this.getCurrentScript().runFlags |= Script::tick_attached;
}

void onTick(CBlob@ this)
{
	if (this.isAttached())
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (point is null) {return;}

		CBlob@ holder = point.getOccupied();
		if (holder is null) {return;}

		this.setAngleDegrees(getAimAngle(this, holder));

		if (getKnocked(holder) <= 0)
		{
			CSprite@ sprite = this.getSprite();

			bool lmb = point.isKeyPressed(key_action1);
			bool rmb = point.isKeyPressed(key_action2);

			if ((!rmb && point.isKeyJustPressed(key_action1)) || (!lmb && point.isKeyJustPressed(key_action2)))
			{
				this.getSprite().PlaySound("/gasextractor_start.ogg");
			}
			else if (lmb || rmb)
			{
				sprite.SetEmitSound("/gasextractor_loop.ogg");
				sprite.SetEmitSoundPaused(false);
				sprite.SetEmitSoundSpeed(1.0f);
				sprite.SetEmitSoundVolume(0.4f);

				Vec2f aimDir = holder.getAimPos() - this.getPosition();
				aimDir.Normalize();

				// if (getGameTime() % 2 == 0) 
				// {
					// if (lmb) makeSteamParticle(this, this.getPosition() + aimDir * 100, -aimDir * 8);
					// else makeSteamParticle(this, this.getPosition(), aimDir * 8);
				// }

				bool is_water;
				if (rmb)
				{
					AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
					if (ap !is null && ap.getOccupied() !is null)
					{
						CInventory@ inv = ap.getOccupied().getInventory();
						if (inv !is null)
						{
							CBlob@ bucket = inv.getItem("bucket");
							if (bucket !is null && bucket.get_u8("filled") > 0)
							{
								f32 rot = this.isFacingLeft() ? this.getAngleDegrees() : this.getAngleDegrees()+180;
								if (getGameTime()%10==0) Splash(this, splash_halfwidth, splash_halfheight, splash_offset, false, rot);
							}
						}
					}
				}

				HitInfo@[] hitInfos;
				if (getMap().getHitInfosFromArc(this.getPosition(), -(aimDir).Angle(), 35, maxDistance, this, @hitInfos))
				{
					for (uint i = 0; i < hitInfos.length; i++)
					{
						CBlob@ blob = hitInfos[i].blob;
						if (blob !is null)
						{
							Vec2f dir = this.getPosition() - blob.getPosition();
							f32 dist = dir.Length();
							dir.Normalize();

							if (rmb)
							{
								dir = -dir;
								if (!is_water)
								{
									AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
									if (ap !is null && ap.getOccupied() !is null)
									{
										CInventory@ inv = ap.getOccupied().getInventory();
										if (inv !is null)
										{
											CBlob@ bucket = inv.getItem("bucket");
											if (bucket !is null && bucket.get_u8("filled") > 0)
											{
												is_water = true;
											}
										}
									}
								}
								else if (getGameTime()%10==0)
								{
									if (blob.getName() == "flame")
									{
										blob.getSprite().PlaySound("DrillOverheat.ogg");
										blob.server_Die();
									}
									if (blob.getName() == "meteor" && blob.get_s32("heat") > 0)
									{
										blob.add_s32("heat", -100);
										blob.getSprite().PlaySound("DrillOverheat.ogg");
									}
								}
							}

							// print("" + blob.getMass());
							blob.AddForce(dir * Maths::Min(50, blob.getMass()) * ((maxDistance - dist) / maxDistance * 1.30f));

							

							if (lmb)
							{
								if (dist < 16 && blob.canBePutInInventory(holder))
								{
									if (blob.hasTag("gas") && !holder.getInventory().isFull())
									{
										if (isServer())
										{
											if (blob.getName() == "mustard" || blob.getName() == "methane")
											{
												MakeMat(holder, this.getPosition(), "mat_" + blob.getName(), 1 + XORRandom(5));
											}
											else
											{
												MakeMat(holder, this.getPosition(), "mat_" + blob.getName().replace("gas" , ""), 1 + XORRandom(3));
											}
											blob.server_Die();
										}

										sprite.PlaySound("/gasextractor_load.ogg");
									}
									else if (blob.canBePickedUp(holder) && !holder.getInventory().isFull())
									{
										sprite.PlaySound("/gasextractor_load.ogg");
										if (isServer()) holder.server_PutInInventory(blob);
									}
								}
							}
						}
					}
				}
			}

			if ((!rmb && point.isKeyJustReleased(key_action1)) || (!lmb && point.isKeyJustReleased(key_action2)))
			{
				sprite.PlaySound("/gasextractor_end.ogg");
				sprite.SetEmitSoundPaused(true);
				sprite.SetEmitSoundVolume(0.0f);
				sprite.RewindEmitSound();
			}
		}
	}
}

void makeSteamParticle(CBlob@ this, Vec2f pos, const Vec2f vel)
{
	if (!isClient()){ return;}

	const f32 rad = this.getRadius();
	Vec2f random = Vec2f(XORRandom(128) - 64, XORRandom(128) - 64) * 0.04 * rad;
	ParticleAnimated("MediumSteam", pos + random, vel, float(XORRandom(360)), 1.0f, 2, 0, false);
}

void onDetach(CBlob@ this,CBlob@ detached,AttachmentPoint@ attachedPoint)
{
	detached.Untag("noLMB");
	detached.Untag("noShielding");

	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSoundPaused(true);
	sprite.SetEmitSoundVolume(0.0f);
	sprite.RewindEmitSound();
}

void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{
	attached.Tag("noLMB");
	attached.Tag("noShielding");
}

#include "Hitters.as";

void Splash(CBlob@ this, const uint splash_halfwidth, const uint splash_halfheight,
            const f32 splash_offset, const bool shouldStun = true, f32 rotation = 0.0f)
{
	//extinguish fire
	CMap@ map = this.getMap();
	Sound::Play("SplashSlow.ogg", this.getPosition(), 3.0f);


    //bool raycast = this.hasTag("splash ray cast");

	if (map !is null)
	{
		bool is_server = getNet().isServer();
		Vec2f pos = this.getPosition() +
		            Vec2f(this.isFacingLeft() ?
		                  -splash_halfwidth * map.tilesize*splash_offset :
		                  splash_halfwidth * map.tilesize * splash_offset,
		                  0);

		for (int x_step = -splash_halfwidth - 2; x_step < splash_halfwidth + 2; ++x_step)
		{
			for (int y_step = -splash_halfheight - 2; y_step < splash_halfheight + 2; ++y_step)
			{
				Vec2f wpos = pos + Vec2f((x_step-4) * map.tilesize, y_step * map.tilesize).RotateBy(rotation, Vec2f(0,0));
				Vec2f outpos;

				//extinguish the fire at this pos
				if (is_server)
				{
					map.server_setFireWorldspace(wpos, false);
				}

				//make a splash!
				bool random_fact = ((x_step + y_step + getGameTime() + 125678) % 7 > 3);

				if (x_step >= -splash_halfwidth && x_step < splash_halfwidth &&
				        y_step >= -splash_halfheight && y_step < splash_halfheight &&
				        (random_fact || y_step == 0 || x_step == 0))
				{
					map.SplashEffect(wpos, Vec2f(0, 10), 8.0f);
				}
			}
		}

		const f32 radius = Maths::Max(splash_halfwidth * map.tilesize + map.tilesize, splash_halfheight * map.tilesize + map.tilesize);

		u8 hitter = shouldStun ? Hitters::water_stun : Hitters::water;

		Vec2f offset = Vec2f(splash_halfwidth * map.tilesize + map.tilesize, splash_halfheight * map.tilesize + map.tilesize);
		Vec2f tl = pos - offset * 0.5f;
		Vec2f br = pos + offset * 0.5f;
		if (is_server)
		{
			CBlob@ ownerBlob;
			CPlayer@ damagePlayer = this.getDamageOwnerPlayer();
			if (damagePlayer !is null)
			{
				@ownerBlob = damagePlayer.getBlob();
			}

			CBlob@[] blobs;
			map.getBlobsInBox(tl, br, @blobs);
			for (uint i = 0; i < blobs.length; i++)
			{
				CBlob@ blob = blobs[i];

				bool hitHard = blob.getTeamNum() != this.getTeamNum() || ownerBlob is blob;

				Vec2f hit_blob_pos = blob.getPosition();
				f32 scale;
				Vec2f bombforce = getBombForce(this, radius, hit_blob_pos, pos, blob.getMass(), scale);

				if (shouldStun && (ownerBlob is blob || (this.isOverlapping(blob) && hitHard)))
				{
					this.server_Hit(blob, pos, bombforce, 0.0f, Hitters::water_stun_force, true);
				}
				else if (hitHard)
				{
					this.server_Hit(blob, pos, bombforce, 0.0f, hitter, true);
				}
				else //still have to hit teamies so we can put them out!
				{
					this.server_Hit(blob, pos, bombforce, 0.0f, Hitters::water, true);
				}
			}
		}
	}
}

// copied from Explosion.as ...... should be in bombcommon?
Vec2f getBombForce(CBlob@ this, f32 radius, Vec2f hit_blob_pos, Vec2f pos, f32 hit_blob_mass, f32 &out scale)
{
	Vec2f offset = hit_blob_pos - pos;
	f32 distance = offset.Length();
	//set the scale (2 step)
	scale = (distance > (radius * 0.7)) ? 0.5f : 1.0f;
	//the force, copy across
	Vec2f bombforce = offset;
	bombforce.Normalize();
	bombforce *= 2.0f;
	bombforce.y -= 0.2f; // push up for greater cinematic effect
	bombforce.x = Maths::Round(bombforce.x);
	bombforce.y = Maths::Round(bombforce.y);
	bombforce /= 2.0f;
	bombforce *= hit_blob_mass * (3.0f) * scale;
	return bombforce;
}
