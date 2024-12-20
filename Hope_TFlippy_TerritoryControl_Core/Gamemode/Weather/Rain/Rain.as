#include "Hitters.as";
#include "Explosion.as";
#include "MakeDustParticle.as";
#include "FireParticle.as";
#include "canGrow.as";
#include "MakeSeed.as";
#include "CustomBlocks.as";

const f32 volume_smooth = 0.001f;
const u16 min_lifetime = 1.5f*60*30;
const f32 fadeout_ttd = min_lifetime;
const f32 fadein_tsc = min_lifetime*1.5f;

void onInit(CBlob@ this)
{
    this.getShape().SetStatic(true);
    this.getCurrentScript().tickFrequency = 1;

    this.getShape().SetRotationsAllowed(true);

    CBlob@ b = getBlobByName("info_dead");
    if (b !is null) this.Tag("acidic rain");

    if (isServer())
    {
        this.server_SetTimeToDie((min_lifetime + XORRandom(3.0f*60*30)) / 30);
    }

	this.addCommandID("sync");

    if (isClient())
    {
        Render::addBlobScript(Render::layer_postworld, this, "Rain.as", "RenderRain");
        if (!Texture::exists("RAIN")) Texture::createFromFile("RAIN", "rain.png");
        if (!Texture::exists("FOG")) Texture::createFromFile("FOG", "pixel.png");
		
        CSprite@ sprite = this.getSprite();
        sprite.getConsts().accurateLighting = false;
        sprite.SetEmitSound("rain_loop.ogg");
        sprite.SetEmitSoundPaused(false);

        uvs = 2048.0f / f32(spritesize);

        Vertex[] BigQuad =
        {
            Vertex(-1024, -1024, -800, 0, 0, 0x90ffffff),
            Vertex(1024, -1024, -800, uvs, 0, 0x90ffffff),
            Vertex(1024, 1024, -800, uvs, uvs, 0x90ffffff),
            Vertex(-1024, 1024, -800, 0, uvs, 0x90ffffff)
        };

        Rain_vs = BigQuad;
        BigQuad[0].z = BigQuad[1].z = BigQuad[2].z = BigQuad[3].z = 1500;
        Fog_vs = BigQuad;
    }

    this.set_f32("min_level", 0.15f);
    this.set_f32("level", 0.15f);
    this.set_f32("max_level", 0.8f);
    this.set_f32("level_increase", 1.0001f + this.getTimeToDie() / 500000);

    if (isClient())
    {
        CBitStream params;
        params.write_bool(false);
        params.write_f32(this.get_f32("level"));
        params.write_f32(this.get_f32("level_increase"));
        params.write_f32(this.getTimeToDie());
        this.SendCommand(this.getCommandID("sync"), params);
    }

    getRules().set_bool("raining", true);
}

const int spritesize = 512;
f32 uvs;
Vertex[] Rain_vs;
Vertex[] Fog_vs;

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

Vec2f rainpos = Vec2f(0, 0);
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

	uvs = 2048.0f/f32(spritesize)*(1.0f+factor/2);

	CMap@ map = getMap();
	if (getGameTime() >= nextWindShift)
	{
		windTarget = 50 + XORRandom(200);
		nextWindShift = getGameTime() + 30 + XORRandom(300);
		
		fogTarget = 30 + XORRandom(20);
	}
	
	wind = Lerp(wind, windTarget * factor, 0.025f);
	fog = Lerp(fog, fogTarget * factor, 0.001f);
		
	sine = (Maths::Sin((getGameTime() * 0.0125f)) * 8.0f);
	Vec2f sineDir = Vec2f(0, 1).RotateBy(sine * 10);
	
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
		
	Vec2f dir = Vec2f(0, 1).RotateBy(35);

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
			rainpos = Vec2f(int(cam_pos.x / spritesize) * spritesize + (spritesize/2), current_h);

			this.setPosition(cam_pos);
			uvMove = (uvMove - 0.075f*(level/1.5f)) % uvs;
			
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
			
			this.getSprite().SetEmitSoundSpeed(0.25f + XORRandom(21)*0.001f + modifier * Maths::Min(max_level, level) * 0.5f);
			f32 fadein_volume = this.getTickSinceCreated() * volume_smooth * level;
			this.getSprite().SetEmitSoundVolume(Maths::Lerp(fadein_volume, level, 0.1f));
		}

		f32 t = map.getDayTime();
		f32 time_mod = (1.0f - (t > 0.9f ? Maths::Abs(t-1.0f) : Maths::Min(0.1f, t))*10);
		this.set_f32("time_mod", time_mod);
		f32 base_darkness = 200;
		fogDarkness = 85;
	}

	if (getGameTime() % (45 - (23 * (level/max_level))) == 0) DecayStuff();
}

void RenderRain(CBlob@ this, int id)
{
	f32 level = Maths::Max(0.2f, this.get_f32("level"));
	if (Rain_vs.size() > 0)
	{
		Render::SetTransformWorldspace();
		Render::SetAlphaBlend(true);
		Rain_vs[0].v = Rain_vs[1].v = uvMove;
		Rain_vs[2].v = Rain_vs[3].v = uvMove + uvs;
		float[] model;
		Matrix::MakeIdentity(model);

		f32 fl = this.get_f32("fl");
		f32 exact_rot = Maths::Max(5, Maths::Abs(5.0f * level*10.0f)) * fl;
		f32 rot = exact_rot + Maths::Sin(getGameTime()*0.01f)*8*level;

		Matrix::SetRotationDegrees(model, 0.00f, 0.00f, rot);
		Matrix::SetTranslation(model, rainpos.x, rainpos.y, 0.00f);
		Render::SetModelTransform(model);
		Render::RawQuads("RAIN", Rain_vs);
		
		f32 tsc = f32(this.getTickSinceCreated());
		f32 tsc_mod = Maths::Min(tsc/fadein_tsc, 1.0f);
		f32 alpha = Maths::Clamp(Maths::Min((tsc-256.0f)*0.1f, Maths::Max(fog, 255) * modifier), 0, 200*Maths::Min(1.0f, level));
		f32 rain_alpha = tsc_mod * Maths::Clamp(255-255*this.get_f32("time_mod"), 10, 120);
		f32 fadeout_ttd_s = fadeout_ttd/30;
		f32 ttd = this.getTimeToDie();
		if (ttd<fadeout_ttd_s)
		{
			rain_alpha *= ttd/fadeout_ttd_s;
			alpha *= ttd/fadeout_ttd_s;
		}

		Rain_vs[0].col.setAlpha(rain_alpha);
		Rain_vs[1].col.setAlpha(rain_alpha);
		Rain_vs[2].col.setAlpha(rain_alpha);
		Rain_vs[3].col.setAlpha(rain_alpha);

		Fog_vs[0].col = Fog_vs[1].col = Fog_vs[2].col = Fog_vs[3].col = SColor(alpha * 0.25f, fogDarkness, fogDarkness, fogDarkness);
		if (current_h >= -512.0f) Render::RawQuads("FOG", Fog_vs);
	}
}

void onDie(CBlob@ this)
{
	getRules().set_bool("raining", false);
	CBlob@ jungle = getBlobByName('info_jungle');

	if (jungle !is null)
	{
		getMap().CreateSkyGradient("skygradient_jungle.png");
	}
	else 
	{
		if (getBlobByName("info_dead") !is null)
			getMap().CreateSkyGradient("Dead_skygradient.png");	
		else if (getBlobByName("info_magmacore") !is null)
			getMap().CreateSkyGradient("MagmaCore_skygradient.png");	
		else
			getMap().CreateSkyGradient("skygradient.png");	
	}
}

const string[] seeds =
{
	"tree_pine",
	"tree_bushy",
	"bush",
	"grain_plant",
	"flowers"
};

void DecayStuff()
{
	CMap@ map = getMap();
	
	{
		Vec2f pos = Vec2f(XORRandom(map.tilemapwidth * map.tilesize), 0);
		Vec2f hit;
		
		if (map.rayCastSolidNoBlobs(pos, Vec2f(pos.x, map.tilemapheight * map.tilesize), hit))
		{
			TileType tile = map.getTile(hit).type;

			switch(tile)
			{
				case CMap::tile_castle:
					map.server_SetTile(hit, CMap::tile_castle_moss);
				break;

				case CMap::tile_castle_back:
					map.server_SetTile(hit, CMap::tile_castle_back_moss);
				break;

				default:
				{
					if (isTileConcrete(tile))
					{
						map.server_SetTile(hit, CMap::tile_mossyconcrete + XORRandom(2));
					}
					else if (isTileBConcrete(tile))
					{
						map.server_SetTile(hit, CMap::tile_mossybconcrete + XORRandom(2));
					}
					else if (isTileIron(tile))
					{
						map.server_SetTile(hit, CMap::tile_rustyiron + XORRandom(2));
					}
				}
				break;
			}	

			for (int j = 0; j < 4 + XORRandom(4); j++)
			{
				pos = Vec2f(XORRandom(map.tilemapwidth * map.tilesize), 0);
				
				if (map.rayCastSolidNoBlobs(pos, Vec2f(pos.x, map.tilemapheight * map.tilesize), hit))
				{
					TileType tile = map.getTile(hit).type;
					switch(tile)
					{
						case CMap::tile_castle_back:
						{
							if (XORRandom(5) == 0) map.server_SetTile(hit, CMap::tile_castle_back_moss); 
							else
							{
								map.server_SetTile(hit, 76 + XORRandom(2)); 
							}
						}
						break;

						case CMap::tile_castle:
						{
							if (XORRandom(5) == 0) map.server_SetTile(hit, CMap::tile_castle_moss);
							else
							{
								map.server_SetTile(hit, 58 + XORRandom(6)); 
							}
						}
						break;

						case CMap::tile_castle_back_moss:
						{
							if (XORRandom(8) == 0)
							{
								if (map.isTileSolid(map.getTile(hit + Vec2f(0, 8)).type))
								{
									if (getTaggedBlobsInRadius(map, hit, 24, "nature") < 3) 
									{
										server_MakeSeed(hit, seeds[XORRandom(seeds.length)]);
									}
								}
								else if (map.isTileSolid(map.getTile(hit + Vec2f(0, -8)).type))
								{
									if (getTaggedBlobsInRadius(map, hit, 12, "nature") == 0) 
									{
										server_CreateBlob("ivy", -1, hit + Vec2f(0, 16));
									}
								}
								else
								{
									if (getTaggedBlobsInRadius(map, hit, 24, "nature") == 0) 
									{
										server_CreateBlob("bush", -1, hit);
										
										for (int k = 0; k < XORRandom(8); k++)
										{
											map.server_DestroyTile(Vec2f(hit.x + (XORRandom(4) - 2) * 8, hit.y + (XORRandom(4) - 2) * 8), 0.5f);
										}
									}
								}
							}
						}
						break;

						case CMap::tile_wood_back:
						{
							if (XORRandom(8) == 0)
							{
								if (map.isTileSolid(map.getTile(hit + Vec2f(0, 8)).type))
								{ 
									if (getTaggedBlobsInRadius(map, hit, 24, "nature") < 4) 
									{
										server_CreateBlob("bush", -1, hit);
										
										for (int k = 0; k < XORRandom(8); k++)
										{
											map.server_DestroyTile(Vec2f(hit.x + (XORRandom(4) - 2) * 8, hit.y + (XORRandom(4) - 2) * 8), 0.5f);
										}
									}
								}
								else if (map.isTileSolid(map.getTile(hit + Vec2f(0, -8)).type))
								{
									if (getTaggedBlobsInRadius(map, hit, 12, "nature") == 0) 
									{
										server_CreateBlob("ivy", -1, hit + Vec2f(0, 16));
										
										for (int k = 0; k < XORRandom(8); k++)
										{
											map.server_DestroyTile(Vec2f(hit.x + (XORRandom(4) - 2) * 8, hit.y + (XORRandom(4) - 2) * 8), 0.5f);
										}
									}
								}
								else
								{
									if (getTaggedBlobsInRadius(map, hit, 24, "nature") == 0) 
									{
										server_CreateBlob("bush", -1, hit);
										
										for (int k = 0; k < XORRandom(8); k++)
										{
											map.server_DestroyTile(Vec2f(hit.x + (XORRandom(4) - 2) * 8, hit.y + (XORRandom(4) - 2) * 8), 0.5f);
										}
									}
								}
							}
						}
						break;

						case CMap::tile_wood:
						{
							for (int j = 0; j < XORRandom(8); j++)
							{
								map.server_DestroyTile(Vec2f(hit.x + (XORRandom(4) - 2) * 8, hit.y + (XORRandom(4) - 2) * 8), 0.5f);
							}
						}
						break;


						default:
						{
							if (isTileConcrete(tile))
							{
								if (XORRandom(5) == 0) map.server_SetTile(hit, CMap::tile_concrete_d0 + XORRandom(3));
								else
								{
									map.server_SetTile(hit, CMap::tile_mossyconcrete + XORRandom(2)); 
								}
							}
							else if (isTileBConcrete(tile))
							{
								if (XORRandom(5) == 0) map.server_SetTile(hit,CMap::tile_bconcrete_d0 + XORRandom(3));
								else
								{
									map.server_SetTile(hit, CMap::tile_mossybconcrete + XORRandom(2)); 
								}
							}
							else if(isTileMossyBConcrete(tile))
							{
								if (XORRandom(8) == 0)
								{
									if (map.isTileSolid(map.getTile(hit + Vec2f(0, 8)).type))
									{
										if (getTaggedBlobsInRadius(map, hit, 24, "nature") < 3) 
										{
											server_MakeSeed(hit, seeds[XORRandom(seeds.length)]);
										}
									}
									else if (map.isTileSolid(map.getTile(hit + Vec2f(0, -8)).type))
									{
										if (getTaggedBlobsInRadius(map, hit, 12, "nature") == 0) 
										{
											server_CreateBlob("ivy", -1, hit + Vec2f(0, 16));
										}
									}
									else
									{
										if (getTaggedBlobsInRadius(map, hit, 24, "nature") == 0) 
										{
											server_CreateBlob("bush", -1, hit);
											
											for (int k = 0; k < XORRandom(8); k++)
											{
												map.server_DestroyTile(Vec2f(hit.x + (XORRandom(4) - 2) * 8, hit.y + (XORRandom(4) - 2) * 8), 0.5f);
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
	}

	CBlob@[] plants;
	getBlobsByTag("nature", @plants);
	
	if (plants !is null && plants.length > 0)
	{
		// u32 count = Maths::Ceil(plants.length * 0.5f); // lolz
		u32 count = Maths::Ceil(plants.length * 0.035f); // lolz
		//if (getGameTime() % 150 == 0) print("rain iteration count: " + count + "/" + plants.length);
				
		for (int i = 0; i < count; i++)
		{
			CBlob@ plant = plants[XORRandom(plants.length)];
			
			Vec2f pos = plant.getPosition();
			Vec2f tilePos = Vec2f(pos.x, pos.y + 8);
			uint16 tile = map.getTile(tilePos).type;
						
			Vec2f grassPos = Vec2f(tilePos.x + ((5 - XORRandom(10)) * 8), tilePos.y + ((4 - XORRandom(8)) * 8));
			TileType grassTileType = map.getTile(grassPos).type;

			Vec2f underGrassPos = Vec2f(grassPos.x, grassPos.y + 8);
			TileType underGrassTileType = map.getTile(underGrassPos).type;
			
			if (map.isTileSolid(underGrassTileType) && (map.isTileGround(underGrassTileType) || underGrassTileType == CMap::tile_castle_moss || isTileMossyConcrete(underGrassTileType)))
			{
				if (grassTileType == CMap::tile_empty)
				{
					map.server_SetTile(grassPos, CMap::tile_grass + XORRandom(3));
				}
				else if (map.isTileGrass(grassTileType))
				{
					CBlob@[] blobs;
					map.getBlobsInRadius(grassPos, 12, @blobs);
				
					if (blobs.length < 3) 
					{
						server_MakeSeed(grassPos, seeds[XORRandom(seeds.length)]);
					}
				}
			}
		}
	}
}

u32 getTaggedBlobsInRadius(CMap@ map, const Vec2f pos, const f32 radius, const string tag)
{
	CBlob@[] blobs;
	map.getBlobsInRadius(pos, radius, @blobs);

	u32 counter = 0;
	
	for (int i = 0; i < blobs.length; i++)
	{
		if (blobs[i].hasTag(tag)) counter++;
	}

	return counter;
}

f32 Lerp(f32 v0, f32 v1, f32 t) 
{
	return v0 + t * (v1 - v0);
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