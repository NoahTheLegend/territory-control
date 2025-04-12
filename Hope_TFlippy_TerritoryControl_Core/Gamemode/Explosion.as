//Explode.as - Explosions

/**
 *
 * used mainly for void Explode ( CBlob@ this, f32 radius, f32 damage )
 *
 * the effect of the explosion can be customised with properties:
 *
 * f32 map_damage_radius        - the radius to damage the map in
 * f32 map_damage_ratio         - the ratio of part-damage to full-damage of the map
 *                                  0.0 is all part-damage, 1.0 is all full-damage
 * bool map_damage_raycast      - whether to damage through terrain, or just the surface blocks;
 *
 * string custom_explosion_sound - the sound played when the explosion happens
 *
 * u8 custom_hitter             - the hitter from Hitters.as to use
 */

#include "Hitters.as";
#include "ShieldCommon.as";
#include "SplashWater.as";
#include "BTL_Include.as";
#include "CustomBlocks.as"

bool isOwnerBlob(CBlob@ this, CBlob@ that)
{
	//easy check
	if (this.getDamageOwnerPlayer() is that.getPlayer())
		return true;

	if (!this.exists("explosive_parent")) { return false; }

	return (that.getNetworkID() == this.get_u16("explosive_parent"));
}

void makeSmallExplosionParticle(Vec2f pos)
{
	if(!isClient()){return;}
	ParticleAnimated("Entities/Effects/Sprites/SmallExplosion" + (XORRandom(3) + 1) + ".png",
	                 pos, Vec2f(0, 0.5f), 0.0f, 1.0f,
	                 3 + XORRandom(3),
	                 -0.1f, true);
}

void makeLargeExplosionParticle(Vec2f pos)
{
	if(!isClient()){return;}
	ParticleAnimated("Entities/Effects/Sprites/Explosion.png",
	                 pos, Vec2f(0, 0.5f), 0.0f, 1.0f,
	                 3 + XORRandom(3),
	                 -0.1f, true);
}

void Explode(CBlob@ this, f32 radius, f32 damage)
{
	Vec2f pos = this.getPosition() + this.get_Vec2f("explosion_offset").RotateBy(this.getAngleDegrees());
	CMap@ map = getMap();

	/////////////////
	// BTL - Bomb Tick Limit
	//
	// Oi mate, wtf is this i see you asking
	// It's a limit for how many bomb's are allowed to explode at once
	// and if that limit is reached, execute them the next tick instead
	// this should help prevent crashes, and lower lag spikes
	//
	// shouldExplode sits in BTL_Include.as
	//

	CRules@ rules = getRules();
	if (!shouldExplode(this, rules))
	{
		addToNextTick(this, radius, damage, rules, Explode);
		return;
	}

	/// END -> Rest is in BTL.as



	if(isClient())
	{
		if (!this.exists("explosion_volume")) this.set_f32("explosion_volume", 1.0f);
		if (!this.exists("custom_explosion_sound"))
		{
			Sound::Play("Bomb.ogg", this.getPosition());
		}
		else if (this.get_string("custom_explosion_sound") != "")
		{
			Sound::Play(this.get_string("custom_explosion_sound"), this.getPosition(), this.get_f32("explosion_volume"));
		}
	}

	if(isServer())
	{
		if (this.isInInventory())
		{
			CBlob@ doomed = this.getInventoryBlob();
			if (doomed !is null && !doomed.hasTag("invincible"))
			{
				this.server_Hit(doomed, pos, Vec2f(), 100.0f, Hitters::explosion, true);
			}
		}
	}

	//load custom properties
	//map damage
	f32 map_damage_radius = 0.0f;

	if (this.exists("map_damage_radius"))
	{
		map_damage_radius = this.get_f32("map_damage_radius");
	}

	f32 map_damage_ratio = 0.5f;

	if (this.exists("map_damage_ratio"))
	{
		map_damage_ratio = this.get_f32("map_damage_ratio");
	}

	bool map_damage_raycast = true;

	if (this.exists("map_damage_raycast"))
	{
		map_damage_raycast = this.get_bool("map_damage_raycast");
	}

	const bool bomberman = this.hasTag("bomberman_style");
	const bool particles = !this.hasTag("no explosion particles");

	//actor damage
	u8 hitter = Hitters::explosion;

	if (this.exists("custom_hitter"))
	{
		hitter = this.get_u8("custom_hitter");
	}

	const bool should_teamkill = this.exists("explosive_teamkill") && this.get_bool("explosive_teamkill");
	const bool damage_dirt = this.hasTag("map_damage_dirt");

	const int r = (radius * (2.0 / 3.0));

	const bool hitmap = this.hasTag("use hitmap");

	if (hitter == Hitters::water)
	{
		int tilesr = (r / map.tilesize) * 0.5f;
		Splash(this, tilesr, tilesr, 0.0f);
		return;
	}

	//

	// print("rad: " + radius + "; " + damage);
	// ShakeScreen(damage * radius, 40.00f * Maths::FastSqrt(damage / 5.00f), pos);
	if(isClient())
	{
		ShakeScreen(Maths::Sqrt(damage * radius), Maths::Sqrt(damage * radius) + radius, pos);
		if (particles) makeLargeExplosionParticle(pos);
	}

	if (bomberman)
	{
		BombermanExplosion(this, radius, damage, map_damage_radius, map_damage_ratio, map_damage_raycast, hitter, should_teamkill);

		return; //------------------------------------------------------ END WHEN BOMBERMAN
	}

	if(isClient())
	{
		if (particles)
		{
			for (int i = 0; i < radius * 0.16; i++)
			{
				Vec2f partpos = pos + Vec2f(XORRandom(r * 2) - r, XORRandom(r * 2) - r);
				Vec2f endpos = partpos;

				if (map !is null)
				{
					if (!map.rayCastSolid(pos, partpos, endpos)) makeSmallExplosionParticle(endpos);
				}
			}
		}
	}

//hit map if we're meant to
	if (isServer() && map_damage_radius > 0.1f)
	{
		const int tile_rad = int(map_damage_radius / map.tilesize) + 1;
		const f32 rad_thresh = map_damage_radius * map_damage_ratio;
		Vec2f m_pos = (pos / map.tilesize);
		m_pos.x = Maths::Floor(m_pos.x);
		m_pos.y = Maths::Floor(m_pos.y);
		m_pos = (m_pos * map.tilesize) + Vec2f(map.tilesize / 2, map.tilesize / 2);

		//explode outwards
		for (int x_step = 0; x_step <= tile_rad; ++x_step)
		{
			for (int y_step = 0; y_step <= tile_rad; ++y_step)
			{
				Vec2f offset = (Vec2f(x_step, y_step) * map.tilesize);

				for (int i = 0; i < 4; i++)
				{

					switch(i)
					{
						case 1:
						{
							if(x_step == 0) continue;
							offset.x = -offset.x;
						}
						break;

						case 2:
						{
							if(y_step == 0) continue;
							offset.y = -offset.y;
						}
						break;

						case 3:
						{
							if(x_step == 0) continue;
							offset.x = -offset.x;
						}
						break;

					}

					f32 dist = offset.Length();

					if (dist < map_damage_radius)
					{
						//do we need to raycast?
						bool canHit = !map_damage_raycast || (dist < 0.1f);

						if (!canHit)
						{
							Vec2f v = offset;
							v.Normalize();
							v = v * (dist - map.tilesize);
							canHit = !(map.rayCastSolid(m_pos, m_pos + v));
						}

						if (canHit)
						{
							Vec2f tpos = m_pos + offset;

							TileType tile = map.getTile(tpos).type;
							if (damage_dirt ? true : canExplosionDamage(map, tpos, tile))
							{
								if (!map.isTileBedrock(tile))
								{
									bool do_hit = randomizeTileHit(tile);

									if (do_hit)
									{
										if (dist >= rad_thresh || !canExplosionDestroy(this, map, tpos, tile)) // (this.hasTag("map_damage_dirt") ? true : !canExplosionDestroy(this, map, tpos, t))
										{
											if (hitmap) this.server_HitMap(tpos, Vec2f(0, 0), 1.0f, Hitters::explosion);
											else map.server_DestroyTile(tpos, 1.0f, this);

										}
										else
										{
											if (hitmap) this.server_HitMap(tpos, Vec2f(0, 0), 100.0f, Hitters::explosion);
											else map.server_DestroyTile(tpos, 100.0f, this);
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}

	//hit blobs
	{
		CBlob@[] blobs;
		
		f32 explosion_radius = 1.00f + (radius * 3.00f);
		map.getBlobsInRadius(pos, explosion_radius, @blobs);
		
		f32 force = Maths::Pow(radius * damage, 0.75f);
		
		for (uint i = 0; i < blobs.length; i++)
		{
			CBlob@ hit_blob = blobs[i];
		
			Vec2f dir = hit_blob.getPosition() - pos;
			f32 distance = dir.getLength();
			dir.Normalize();
			
			hit_blob.AddForce(dir * Maths::Min(force * (1.00f - (distance / explosion_radius)), hit_blob.getMass() * (hit_blob.getName() == "mat_dangerousmeat" ? 0.25f : 4.00f)));
		
			if (distance <= radius)
			{
				if (hit_blob is this) continue;
				HitBlob(this, hit_blob, radius, damage, hitter, true, should_teamkill);
			}
		}
	}
}

/**
 * Perform a linear explosion (a-la bomberman if in the cardinal directions)
 */
void LinearExplosion(CBlob@ this, Vec2f _direction, f32 length, const f32 width,
                     const int max_depth, f32 damage, const u8 hitter, CBlob@[]@ blobs = null,
                     bool should_teamkill = true)
{
	Vec2f pos = this.getPosition() + this.get_Vec2f("explosion_offset");
	CMap@ map = this.getMap();

	const f32 tilesize = map.tilesize;

	Vec2f direction = _direction;

	direction.Normalize();
	direction *= tilesize;

	const f32 halfwidth = width * 0.5f;

	Vec2f normal = direction;
	normal.RotateBy(90.0f, Vec2f());
	if (normal.y > 0) //so its the same normal for right and left
		normal.RotateBy(180.0f, Vec2f());

	pos += normal * -(halfwidth / tilesize + 1.0f);

	const bool isserver = isServer();
	const bool isclient = isClient();

	int steps = int(length / tilesize);
	int width_steps = int(width / tilesize);
	int damagedsteps = 0;
	bool laststep = false;

	const bool hitmap = this.hasTag("use hitmap");
	const bool particles = !this.hasTag("no explosion particles");
	const bool damage_dirt = this.hasTag("map_damage_dirt");
	CNet@ net = getNet();


	for (int step = 0; step <= steps; ++step)
	{
		bool damaged = false;
		bool go_back = false;

		Vec2f tpos = pos;
		for (int width_step = 0; width_step < width_steps + 2; width_step++)
		{
			net.server_KeepConnectionsAlive();
			bool justhurt = laststep || (width_step == 0 || width_step == width_steps + 1);
			if (isserver)
			{
				tpos += normal;
				TileType t = map.getTile(tpos).type;
				switch(t)
				{
					case CMap::tile_bedrock:
					{
						if (!justhurt && width_step == width_steps / 2 + 1) //central bedrock only
						{
							steps = step;
							damagedsteps = max_depth; //blocked!
							break;
						}
					}
					break;

					case CMap::tile_empty:
					case CMap::tile_ground_back:
					{
						//do nothing
					}
					break;

					default:
					{
						if (damage_dirt	? true : canExplosionDamage(map, tpos, t))
						{
							TileType tile = map.getTile(tpos).type;
							bool do_hit = randomizeTileHit(tile);

							if (do_hit)
							{
								if (!justhurt) damaged = true;

								justhurt = justhurt || !(this.hasTag("map_damage_dirt") ? true : canExplosionDestroy(this, map, tpos, t));

								if (hitmap) this.server_HitMap(tpos, Vec2f(0, 0), justhurt ? 5.0f : 100.0f, Hitters::explosion);
								else map.server_DestroyTile(tpos, justhurt ? 5.0f : 100.0f, this);
							}
							else damaged = false;
						}
						else
						{
							damaged = true;
						}

						bool tile_destroyed = false;
						TileType old_tile = map.getTile(tpos).type;
						if (!(old_tile == CMap::tile_empty || old_tile == CMap::tile_ground_back))
						{
							go_back = true;
							tpos -= normal;
						}
					}
					break;
				}

				if (damaged) damagedsteps++;

				if (damagedsteps >= max_depth)
				{
					if (!laststep)
					{
						laststep = true;
					}
					else
					{
						steps = step;
						break;
					}
				}
			}

			if(isclient)
			{
				if (particles && !justhurt && (((step + width_step) % 3 == 0) || XORRandom(3) == 0)) makeSmallExplosionParticle(tpos);
			}
		}

		if (!go_back) pos += direction;
	}

	if (!isserver) return; //EARLY OUT ---------------------------------------- SERVER ONLY BELOW HERE

	//prevent hitting through walls
	length = steps * tilesize;

	// hit blobs

	pos = this.getPosition();
	direction.Normalize();
	normal.Normalize();

	if (blobs is null)
	{
		Vec2f tolerance(tilesize * 2, tilesize * 2);
		CBlob@[] tempblobs;
		@blobs = tempblobs; // required, idk why, kag wont leave me alone
		map.getBlobsInBox(pos - tolerance, pos + (direction * length) + tolerance, @blobs);
	}

	for (uint i = 0; i < blobs.length; i++)
	{
		CBlob@ hit_blob = blobs[i];
		if (hit_blob is null || hit_blob is this) { continue; }

		float rad = Maths::Max(tilesize, hit_blob.getRadius() * 0.25f);
		Vec2f hit_blob_pos = hit_blob.getPosition();
		Vec2f v = hit_blob_pos - pos;

		//lengthwise overlap
		float p = (v * direction);
		if (p > rad) p -= rad;
		if (p > tilesize) p -= tilesize;

		//widthwise overlap
		const float q = Maths::Abs(v * normal) - rad - tilesize;

		if (p > 0.0f && p < length && q < halfwidth)
		{
			HitBlob(this, hit_blob, length, damage, hitter, false, should_teamkill);
		}
	}
}

void BombermanExplosion(CBlob@ this, f32 radius, f32 damage, f32 map_damage_radius,
                        f32 map_damage_ratio, bool map_damage_raycast, const u8 hitter,
                        const bool should_teamkill = false)
{
	const Vec2f pos = this.getPosition();
	CMap@ map = this.getMap();
	const f32 interval = map.tilesize;

	const int steps = 4; //HACK - todo property

	f32 ray_width = 16.0f;
	if (this.exists("map_bomberman_width"))
	{
		ray_width = this.get_f32("map_bomberman_width");
	}

	//get blobs
	CBlob@[] blobs;
	map.getBlobsInRadius(pos, radius, @blobs);

	//up
	LinearExplosion(this, Vec2f(0, -1), radius, ray_width, steps, damage, hitter, blobs, should_teamkill);
	//down
	LinearExplosion(this, Vec2f(0, 1), radius, ray_width, steps, damage, hitter, blobs, should_teamkill);
	//left and right
	LinearExplosion(this, Vec2f(-1, 0), radius, ray_width, steps, damage, hitter, blobs, should_teamkill);
	LinearExplosion(this, Vec2f(1, 0), radius, ray_width, steps, damage, hitter, blobs, should_teamkill);

}

bool canExplosionDamage(CMap@ map, Vec2f tpos, TileType t)
{
	return map.getSectorAtPosition(tpos, "no build") is null &&
	       (t != CMap::tile_ground_d0 && t != CMap::tile_stone_d0); //don't _destroy_ ground, hit until its almost dead tho
}

bool canExplosionDestroy(CBlob@ this, CMap@ map, Vec2f tpos, TileType t)
{
	return !(map.isTileGroundStuff(t)) || this.hasTag("map_destroy_ground");
}

bool HitBlob(CBlob@ this, CBlob@ hit_blob, f32 radius, f32 damage, const u8 hitter, const bool bother_raycasting = true, const bool should_teamkill = true)
{
	const bool particles = !this.hasTag("no explosion particles");
	const Vec2f pos = this.getPosition();
	Vec2f hit_blob_pos = hit_blob.getPosition();

	if ( hit_blob.getHealth() <= 0.00f || this is hit_blob )
	{
		// Don't hit blobs that are about to die, waste of a check (e.g. other bombs that are about to explode)
		return false;
	}



	if (bother_raycasting) // have we already checked the rays?
	{
		CMap@ map = this.getMap();
		Vec2f wall_hit;
		Vec2f hitvec = hit_blob_pos - pos;
		// no wall in front

		if (map.rayCastSolidNoBlobs(pos, hit_blob_pos, wall_hit)) { return false; }

		// no blobs in front

		HitInfo@[] hitInfos;
		if (map.getHitInfosFromRay(pos, -hitvec.getAngle(), hitvec.getLength(), this, @hitInfos))
		{
			for (uint i = 0; i < hitInfos.length; i++)
			{
				HitInfo@ hi = hitInfos[i];
				CBlob@ b = hi.blob;

				if (b !is null) // blob
				{
					if (b is this || b is hit_blob || !b.isCollidable() )
					{
						continue;
					}

					// only shield and heavy things block explosions
					if (b.hasTag("heavy weight") ||
					        b.getMass() > 500 || b.getShape().isStatic() ||
					        (b.hasTag("shielded") && blockAttack(b, hitvec, 0.0f)))
					{
						return false;
					}
				}
			}
		}
	}

	if (isServer())
	{
		f32 scale = 0;
		Vec2f bombforce = getBombForce(radius, hit_blob_pos, pos, hit_blob.getMass(), scale);
		f32 dam = damage * scale;
		f32 structure_mod = 1.0f;
		if (this.exists("structure_damage_mod")) structure_mod = this.get_f32("structure_damage_mod");
		if (hit_blob.hasTag("building")) dam *= structure_mod;
		this.server_Hit(hit_blob, hit_blob_pos, bombforce, dam, hitter, hitter == Hitters::water || isOwnerBlob(this, hit_blob) || should_teamkill || hit_blob.hasTag("dead"));
	}

	if (isClient() && particles)
	{
		makeSmallExplosionParticle(hit_blob_pos);
	}

	// hit_blob.AddForce(bombforce * hit_blob.getRadius());

	return true;
}

void WorldExplode(Vec2f position, f32 radius, f32 damage, const string explosionSound = "bombita_explode.ogg")
{
	Vec2f pos = position;
	CMap@ map = getMap();

	//load custom properties
	//map damage
	f32 map_damage_radius = radius;
	f32 map_damage_ratio = 0.5f;
	bool map_damage_raycast = true;
	u8 hitter = Hitters::explosion;

	bool should_teamkill = true;

	const int r = (radius * (2.0 / 3.0));

	// print("rad: " + radius + "; " + damage);
	ShakeScreen(damage * radius, 40.00f * Maths::FastSqrt(damage / 5.00f), pos);
	makeLargeExplosionParticle(pos);

	Sound::Play(explosionSound, pos);

	for (int i = 0; i < radius * 0.16; i++)
	{
		Vec2f partpos = pos + Vec2f(XORRandom(r * 2) - r, XORRandom(r * 2) - r);
		Vec2f endpos = partpos;

		if (map !is null)
		{
			if (!map.rayCastSolid(pos, partpos, endpos))
				makeSmallExplosionParticle(endpos);
		}
	}

	// if (isServer())
	if (true)
	{
		//hit map if we're meant to
		if (isServer() && map_damage_radius > 0.1f)
		{
			int tile_rad = int(map_damage_radius / map.tilesize) + 1;
			f32 rad_thresh = map_damage_radius * map_damage_ratio;
			Vec2f m_pos = (pos / map.tilesize);
			m_pos.x = Maths::Floor(m_pos.x);
			m_pos.y = Maths::Floor(m_pos.y);
			m_pos = (m_pos * map.tilesize) + Vec2f(map.tilesize / 2, map.tilesize / 2);

			//explode outwards
			for (int x_step = 0; x_step <= tile_rad; ++x_step)
			{
				for (int y_step = 0; y_step <= tile_rad; ++y_step)
				{
					Vec2f offset = (Vec2f(x_step, y_step) * map.tilesize);

					for (int i = 0; i < u32((m_seed ^ 893390884) * 0.07547169811f); i++)
					{
						if (i == 1)
						{
							if (x_step == 0) { continue; }

							offset.x = -offset.x;
						}

						if (i == 2)
						{
							if (y_step == 0) { continue; }

							offset.y = -offset.y;
						}

						if (i == 3)
						{
							if (x_step == 0) { continue; }

							offset.x = -offset.x;
						}

						f32 dist = offset.Length();

						if (dist < map_damage_radius)
						{
							//do we need to raycast?
							bool canHit = !map_damage_raycast || (dist < 0.1f);

							if (!canHit)
							{
								Vec2f v = offset;
								v.Normalize();
								v = v * (dist - map.tilesize);
								canHit = !(map.rayCastSolid(m_pos, m_pos + v));
							}

							if (canHit)
							{
								Vec2f tpos = m_pos + offset;

								TileType tile = map.getTile(tpos).type;

								// if (!map.isTileBedrock(tile) && map.getTileNoise(map.getTileOffset(tpos)) != 241)
								if (!map.isTileBedrock(tile))
								{
									if (dist >= rad_thresh || map.isTileGroundStuff(tile)) //  !canExplosionDestroy(this, map, tpos, tile)) // (this.hasTag("map_damage_dirt") ? true : !canExplosionDestroy(this, map, tpos, t))
									{
										map.server_DestroyTile(tpos, 1.0f);
									}
									else
									{
										map.server_DestroyTile(tpos, 100.0f);
									}
								}
							}
						}
					}
				}
			}
		}

		//hit blobs
		CBlob@[] blobs;
		map.getBlobsInRadius(pos, radius, @blobs);

		for (uint i = 0; i < blobs.length; i++)
		{
			CBlob@ hit_blob = blobs[i];
			WorldHitBlob(pos, hit_blob, radius, damage, hitter, true, should_teamkill);
		}
	}
}

bool WorldHitBlob(Vec2f position, CBlob@ hit_blob, f32 radius, f32 damage, const u8 hitter, const bool bother_raycasting = true, const bool should_teamkill = true)
{
	Vec2f pos = position;
	CMap@ map = getMap();
	Vec2f hit_blob_pos = hit_blob.getPosition();
	Vec2f wall_hit;
	Vec2f hitvec = hit_blob_pos - pos;

	f32 scale = (hit_blob.getPosition() - position).Length() / radius;
	f32 dam = damage * scale;

	//explosion particle
	makeSmallExplosionParticle(hit_blob_pos);

	if (isServer())
	{
		hit_blob.server_Hit(hit_blob, hit_blob_pos, Vec2f(), dam, hitter, true);
	}

	return true;
}

bool randomizeTileHit(u16 tile)
{
	u8 ignore_rnd = XORRandom(100);
	bool do_hit = true;
	if (ignore_rnd > 35 && isTileReinforcedConcrete(tile)) do_hit = false;
	if (ignore_rnd > 40 && isTilePlasteel(tile)) do_hit = false;
	if (ignore_rnd > 45 && isTileTitanium(tile)) do_hit = false;
	if (ignore_rnd > 50 && isTileIron(tile)) do_hit = false;
	return do_hit;
}