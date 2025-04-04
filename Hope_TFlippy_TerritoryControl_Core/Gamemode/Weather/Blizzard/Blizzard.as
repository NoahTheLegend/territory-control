#include "Hitters.as";
#include "Explosion.as";
#include "MakeDustParticle.as";
#include "FireParticle.as";
#include "canGrow.as";
#include "MakeSeed.as";
#include "CustomBlocks.as";

const f32 volume_smooth = 0.00015f;
const u16 min_lifetime = 2.0f*60*30;
const f32 fadeout_ttd = min_lifetime;
const f32 fadein_tsc = min_lifetime;

void onInit(CBlob@ this)
{
	this.getShape().SetStatic(true);
	this.getCurrentScript().tickFrequency = 1;
	
	this.getShape().SetRotationsAllowed(true);
	current_h = -1024.0f;

	if (isServer())
	{
		this.server_SetTimeToDie((min_lifetime + XORRandom(5.0f*60*30)) / 30);
	}

	if (isClient())
	{
		Render::addBlobScript(Render::layer_postworld, this, "Blizzard.as", "RenderBlizzard");
		if(!Texture::exists("BLIZZARD")) Texture::createFromFile("BLIZZARD", "blizzard.png");
		if(!Texture::exists("FOG")) Texture::createFromFile("FOG", "pixel.png");
	}

	this.addCommandID("sync");

	f32 fl = this.getNetworkID()%2==0 ? -1:1;
	this.set_f32("fl", fl);

	this.set_f32("min_level", 0.15f);
	this.set_f32("level", 0.15f);
	this.set_f32("max_level", 1.25f);
	this.set_f32("level_increase", 1.0001f + this.getTimeToDie()/500000);

	if (isClient())
	{
		CBitStream params;
		params.write_bool(false);
		params.write_f32(this.get_f32("level"));
		params.write_f32(this.get_f32("level_increase"));
		params.write_f32(this.getTimeToDie());
		this.SendCommand(this.getCommandID("sync"), params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("sync"))
	{
		bool sync = params.read_bool();
		if (isServer() && !sync)
		{
			CBitStream params1;
			params1.write_bool(true);
			params1.write_f32(this.get_f32("level"));
			params1.write_f32(this.get_f32("level_increase"));
			params1.write_f32(this.getTimeToDie());
			this.SendCommand(this.getCommandID("sync"), params1);
		}
		if (isClient() && sync)
		{
			f32 level = params.read_f32();
			f32 increase = params.read_f32();
			f32 ttd = params.read_f32();

			this.set_f32("level", level);
			this.set_f32("level_increase", increase);
			this.server_SetTimeToDie(ttd);
		}
	}
}

const int spritesize = 128;
f32 uvs;
Vertex[] Blizzard_vs;
Vertex[] Fog_vs;

void onInit(CSprite@ this)
{
	this.getConsts().accurateLighting = false;
	Setup(this);
}

void onReload(CBlob@ this)
{
	Setup(this.getSprite());
}

void Setup(CSprite@ this)
{
	if (isClient())
	{
		this.SetEmitSound("Blizzard_Loop.ogg");
		this.SetEmitSoundVolume(0);
		this.SetEmitSoundPaused(false);
		CMap@ map = getMap();
		uvs = 2048.0f/f32(spritesize);
		
		Vertex[] BigQuad = 
		{
			Vertex(-1024,	-1024, 	-800,	0,		0,		0x90ffffff),
			Vertex(1024,	-1024,	-800,	uvs,	0,		0x90ffffff),
			Vertex(1024,	1024,	-800,	uvs,	uvs,	0x90ffffff),
			Vertex(-1024,	1024,	-800,	0,		uvs,	0x90ffffff)
		};
		
		Blizzard_vs = BigQuad;
		BigQuad[0].z = BigQuad[1].z = BigQuad[2].z = BigQuad[3].z = 1500;
		Fog_vs = BigQuad;
	}
}

f32 sine;

f32 windTarget = 0;	
f32 wind = 0;	
u32 nextWindShift = 0;

f32 fog = 0;
f32 fogTarget = 0;

f32 modifier = 1;
f32 modifierTarget = 1;

f32 fogHeightModifier = 0;
f32 fogDarkness = 0;

Vec2f blizzardpos = Vec2f(0,0);
f32 uvMove = 0;

f32 current_h = -1024.0f;

void onTick(CBlob@ this)
{
	f32 max_level = this.get_f32("max_level");
	f32 level = Maths::Max(this.get_f32("level"), this.get_f32("min_level"));
	f32 level_increase = this.get_f32("level_increase");

	getRules().set_bool("raining", true);

	this.set_f32("level", Maths::Min(max_level, level*level_increase));
	if (level_increase > 1.000f && this.getTimeToDie() <= 60 && this.getTickSinceCreated() > min_lifetime)
	{
		this.set_f32("level_increase", 1.0f/level_increase); // reverse it for fadeout
	}

	f32 factor = level / max_level;

	uvs = 2048.0f/f32(spritesize);

	CMap@ map = getMap();
	if (getGameTime() >= nextWindShift)
	{
		windTarget = 50 + XORRandom(200);
		nextWindShift = getGameTime() + 30 + XORRandom(300);
		
		fogTarget = 50 + XORRandom(150);
	}
	
	wind = Lerp(wind, windTarget * factor, 0.025f);
	fog = Lerp(fog, fogTarget, 0.001f);
		
	sine = (Maths::Sin((getGameTime() * 0.0125f)) * 8.0f);
	Vec2f sineDir = Vec2f(0, 1).RotateBy(sine * 20);
	
	CBlob@[] vehicles;
	getBlobsByTag("aerial", @vehicles);
	for (u32 i = 0; i < vehicles.length; i++)
	{
		CBlob@ blob = vehicles[i];
		if (blob !is null)
		{
			Vec2f pos = blob.getPosition();
			if (map.rayCastSolidNoBlobs(Vec2f(pos.x, 0), pos)) continue;
		
			blob.AddForce(sineDir * blob.getRadius() * wind * 0.01f);
		}
	}

	if (getGameTime() % Maths::Clamp(150 - (149 * factor), 0, 150) == 0)
	{
		Snow(this);
	}
	Vec2f dir = Vec2f(0, 1).RotateBy(70);

	if (isClient())
	{	
		CCamera@ cam = getCamera();
		fogHeightModifier = 0.00f;
		CBlob@ local = getLocalPlayerBlob();

		if (cam !is null && uvs > 0)
		{
			Vec2f cam_pos = local !is null ? local.getPosition() : cam.getPosition();

			f32 h = Maths::Lerp(current_h, int(cam_pos.y / spritesize) * spritesize + (spritesize/2), 0.001f);
			current_h = h;
			blizzardpos = Vec2f(int(cam_pos.x / spritesize) * spritesize + (spritesize/2), current_h);

			this.setPosition(cam_pos);
			uvMove = (uvMove - 0.075f*level) % (uvs*level);
			
			Vec2f hit;
			if (getMap().rayCastSolidNoBlobs(Vec2f(cam_pos.x, 0), cam_pos, hit))
			{
				f32 depth = Maths::Abs(cam_pos.y - hit.y) / 8.0f;
				modifierTarget = 1.0f - Maths::Clamp(depth / 8.0f, 0.00f, 1);
			}
			else
			{
				modifierTarget = 1;
			}
			
			modifier = Lerp(modifier, modifierTarget, 0.10f);
			fogHeightModifier = 1.00f - (cam_pos.y / (map.tilemapheight * map.tilesize));
			
			if (level > 0.5f && getGameTime() % 5 == 0) ShakeScreen(Maths::Abs(wind) * 0.01f * level * modifier, 90 * level, cam.getPosition());
			
			this.getSprite().SetEmitSoundSpeed(0.5f + modifier * Maths::Min(max_level, level) * 0.5f);
			f32 fadein_volume = this.getTickSinceCreated() * volume_smooth * level;
			this.getSprite().SetEmitSoundVolume(level > 0.5f ? Maths::Lerp(fadein_volume, level, 0.1f) : Maths::Min(level, fadein_volume));
		}

		f32 t = map.getDayTime();
		f32 time_mod = (1.0f - (t > 0.9f ? Maths::Abs(t-1.0f) : Maths::Min(0.1f, t))*10);
		this.set_f32("time_mod", time_mod);
		f32 base_darkness = 200;
		fogDarkness = Maths::Clamp(base_darkness - base_darkness*time_mod/4 * (fog * 0.25f), 0, 255);
	}
}

const int max_snow_difference = 4;

void Snow(CBlob@ this)
{
	if (isServer())
	{
		CMap@ map = getMap();
		Vec2f dir = Vec2f(0, 1); //.RotateBy(10);
		
		for (int i = 0; i < 5; i++)
		{
			Vec2f start_pos = Vec2f(XORRandom(map.tilemapwidth) * 8, XORRandom(map.tilemapheight * 0.75f) * 8);
			Vec2f end_pos = start_pos + (dir * 10000);
			Vec2f hit_pos;
			
			if (map.rayCastSolidNoBlobs(start_pos, end_pos, hit_pos))
			{
				Vec2f pos_c = hit_pos + Vec2f(+0.00f, -8.00f);
				if (!map.isInWater(pos_c))
				{
					Vec2f pos_l = pos_c + Vec2f(-8.00f, 0.00f);
					Vec2f pos_r = pos_c + Vec2f(+8.00f, 0.00f);
					
					const Tile tile_c = map.getTile(pos_c);
					const Tile tile_l = map.getTile(pos_l);
					const Tile tile_r = map.getTile(pos_r);
					
					const TileType tileType_c = tile_c.type;
					const TileType tileType_l = tile_l.type;
					const TileType tileType_r = tile_r.type;
					
					if (map.isTileGroundBack(tileType_c))
					{
						// do nothing
					}
					else if ((tileType_c == CMap::tile_empty || map.isTileBackground(tile_c)) && map.getBlobAtPosition(pos_c) is null)
					{
						map.server_SetTile(pos_c, CMap::tile_snow_pile_v5);
					}
					else if (map.isTileGrass(tileType_c))
					{
						map.server_SetTile(pos_c, CMap::tile_snow_pile_v2);
					}
					else 
					{
						const bool valid_l = (isTileSnowPile(tileType_l) && Maths::Abs(tileType_l - tileType_c + 1) < max_snow_difference) || (tile_l.flags & Tile::SOLID != 0);
						const bool valid_r = (isTileSnowPile(tileType_r) && Maths::Abs(tileType_r - tileType_c + 1) < max_snow_difference) || (tile_r.flags & Tile::SOLID != 0);
					
						if (isTileSnowPile(tileType_c - 1) && (valid_l && valid_r))
						{
							map.server_SetTile(pos_c, tileType_c - 1);
						}
						else if (tileType_c == CMap::tile_snow_pile) 
						{
							map.server_SetTile(pos_c, CMap::tile_snow);
						}
					}
					
					const TileType tiletype_c = tile_c.type;
				}
			}
		}
	}
}

void RenderBlizzard(CBlob@ this, int id)
{
	f32 level = Maths::Max(0.2f, this.get_f32("level"));
	if (Blizzard_vs.size() > 0)
	{
		Render::SetTransformWorldspace();
		Render::SetAlphaBlend(true);
		Blizzard_vs[0].v = Blizzard_vs[1].v = uvMove;
		Blizzard_vs[2].v = Blizzard_vs[3].v = uvMove + uvs;
		float[] model;
		Matrix::MakeIdentity(model);

		f32 fl = this.get_f32("fl");
		f32 exact_rot = Maths::Max(5, Maths::Abs(5.0f * level*10.0f)) * fl;
		f32 rot = exact_rot + Maths::Sin(getGameTime()*0.01f)*8*level;

		Matrix::SetRotationDegrees(model, 0.00f, 0.00f, rot);
		Matrix::SetTranslation(model, blizzardpos.x, blizzardpos.y, 0.00f);
		Render::SetModelTransform(model);
		Render::RawQuads("BLIZZARD", Blizzard_vs);
		
		f32 tsc = f32(this.getTickSinceCreated());
		f32 tsc_mod = Maths::Min(tsc/fadein_tsc, 1.0f);
		f32 alpha = Maths::Clamp(Maths::Min((tsc-256.0f)*0.1f, Maths::Max(fog, 255) * modifier), 0, 200*Maths::Min(1.0f, level));
		f32 snow_alpha = tsc_mod * Maths::Clamp(255-255*this.get_f32("time_mod"), 0, 255);
		f32 fadeout_ttd_s = fadeout_ttd/30;
		f32 ttd = this.getTimeToDie();
		if (ttd<fadeout_ttd_s)
		{
			snow_alpha *= ttd/fadeout_ttd_s;
			alpha *= ttd/fadeout_ttd_s;
		}

		Blizzard_vs[0].col.setAlpha(snow_alpha);
		Blizzard_vs[1].col.setAlpha(snow_alpha);
		Blizzard_vs[2].col.setAlpha(snow_alpha);
		Blizzard_vs[3].col.setAlpha(snow_alpha);

		Fog_vs[0].col = Fog_vs[1].col = Fog_vs[2].col = Fog_vs[3].col = SColor(alpha, fogDarkness, fogDarkness, fogDarkness);
		if (current_h >= -512.0f) Render::RawQuads("FOG", Fog_vs);
	}
}

f32 Lerp(f32 v0, f32 v1, f32 t) 
{
	return v0 + t * (v1 - v0);
}

void onDie(CBlob@ this)
{
	getRules().set_bool("raining", false);
}