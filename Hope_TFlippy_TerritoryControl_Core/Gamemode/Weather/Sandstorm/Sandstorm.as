#include "Hitters.as";
#include "Explosion.as";
#include "MakeDustParticle.as";
#include "FireParticle.as";
#include "canGrow.as";
#include "MakeSeed.as";
#include "CustomBlocks.as";

void onInit(CBlob@ this)
{
	this.getShape().SetStatic(true);
	this.getCurrentScript().tickFrequency = 1;
	
	this.getShape().SetRotationsAllowed(true);

	getMap().CreateSkyGradient("skygradient_sandstorm.png");

	if (isServer())
	{
		this.server_SetTimeToDie(125 + XORRandom(150));
	}
	
	if (isClient())
	{
		Render::addBlobScript(Render::layer_postworld, this, "Sandstorm.as", "RenderRain");
		if(!Texture::exists("SANDSTORM"))
			Texture::createFromFile("SANDSTORM", "Sandstorm.png");
		if(!Texture::exists("FOG"))
			Texture::createFromFile("FOG", "pixel.png");

		client_AddToChat("A sandstorm has formed! Sudden tornadoes will happen.", SColor(255, 255, 0, 0));

		CSprite@ sprite = this.getSprite();
		sprite.getConsts().accurateLighting = false;
		sprite.SetEmitSound("sandstorm_loop.ogg");
		sprite.SetEmitSoundPaused(false);
		CMap@ map = getMap();
		uvs = 2048.0f/f32(spritesize);
		
		Vertex[] BigQuad = 
		{
			Vertex(-1024,	-1024, 	-800,	0,		0,		0x90ffffff),
			Vertex(1024,	-1024,	-800,	uvs,	0,		0x90ffffff),
			Vertex(1024,	1024,	-800,	uvs,	uvs,	0x90ffffff),
			Vertex(-1024,	1024,	-800,	0,		uvs,	0x90ffffff)
		};
		
		Rain_vs = BigQuad;
		BigQuad[0].z = BigQuad[1].z = BigQuad[2].z = BigQuad[3].z = 1500;
		Fog_vs = BigQuad;
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

Vec2f rainpos = Vec2f(0,0);
f32 uvMove = 0;
f32 last_uvMove = 0;
f32 lastFrameTime = 0;

void onTick(CBlob@ this)
{
	CMap@ map = getMap();
	if (getGameTime() >= nextWindShift)
	{
		windTarget = XORRandom(1000) - 500;
		nextWindShift = getGameTime() + 30 + XORRandom(300);
		
		fogTarget = 50 + XORRandom(150);
	}
	
	wind = Maths::Lerp(wind, windTarget, 0.02f);
	fog = Maths::Lerp(fog, fogTarget, 0.01f);
		
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

	if (isClient())
	{	
		lastFrameTime = 0;
		CCamera@ cam = getCamera();
		fogHeightModifier = 0.00f;
		
		if (cam !is null && uvs > 0)
		{
			Vec2f cam_pos = cam.getPosition();
			rainpos = Vec2f(int(cam_pos.x / spritesize) * spritesize + (spritesize/2), int(cam_pos.y / spritesize) * spritesize + (spritesize/2));
			this.setPosition(cam_pos);

			uvMove -= 0.05f;
			
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
			
			modifier = Maths::Lerp(modifier, modifierTarget, 0.10f);
			fogHeightModifier = 1.00f - ((cam_pos.y*2) / (map.tilemapheight * map.tilesize));
			
			//if (getGameTime() % 5 == 0) ShakeScreen(Maths::Abs(wind) * 0.03f * modifier, 90, cam_pos);
			
			this.getSprite().SetEmitSoundSpeed(0.25f + modifier * 0.3f);
			this.getSprite().SetEmitSoundVolume(0.75f + 0.15f * modifier);
		}
		
		
		
		fogDarkness = Maths::Clamp(500 + (fog * 0.10f), 0, 150);
		//if (modifier > 0.01f) SetScreenFlash(Maths::Clamp(Maths::Max(fog, 255 * fogHeightModifier * 1.20f) * modifier, 0, 190), fogDarkness, fogDarkness, fogDarkness);
		
		// print("" + modifier);
		
		// print("" + (fog * modifier));
		
		//this.getShape().SetAngleDegrees(10 + sine);
	}
	
	if (isServer())
	{
		CMap@ map = getMap();
		u32 rand = XORRandom(4000);
		
		if (rand == 0)
		{
			f32 x = XORRandom(map.tilemapwidth);
			Vec2f pos = Vec2f(x, map.getLandYAtX(x)) * 8;
			
			CBlob@ blob = server_CreateBlob("tornado", -1, pos);
		}	
		
		if (XORRandom(25) == 0)
		{
			CBlob@[] blobs;
			getBlobsByTag("gas", @blobs);
			
			if (blobs.length > 0)
			{
				CBlob@ b = blobs[XORRandom(blobs.length - 1)];
				if (b !is null)
				{
					Vec2f pos = b.getPosition();
					if (!map.rayCastSolidNoBlobs(Vec2f(pos.x, 0), pos))
					{
						b.server_Die();
					}
				}
			}
		}
	}
}

void RenderRain(CBlob@ this, int id)
{
	Render::SetTransformWorldspace();
	Render::SetAlphaBlend(true);
	
	lastFrameTime += getRenderDeltaTime() * getTicksASecond();  // We are using this because ApproximateCorrectionFactor is lerped

	last_uvMove = Maths::Lerp(last_uvMove, uvMove, lastFrameTime);

	Rain_vs[0].v = Rain_vs[1].v = last_uvMove;
	Rain_vs[2].v = Rain_vs[3].v = last_uvMove + uvs;
	float[] model;
	Matrix::MakeIdentity(model);
	Matrix::SetRotationDegrees(model,
		0,
		0,
		90.0f + sine
	);
	Matrix::SetTranslation(model,
		rainpos.x,
		rainpos.y,
		0
	);
	Render::SetModelTransform(model);
	Render::RawQuads("SANDSTORM", Rain_vs);
	f32 alpha = Maths::Clamp(Maths::Max(fog, 255 * fogHeightModifier * 1.8f) * modifier, 0, 190);
	Fog_vs[0].col = Fog_vs[1].col = Fog_vs[2].col = Fog_vs[3].col = SColor(alpha,fogDarkness+95,fogDarkness+40,fogDarkness);
	Render::RawQuads("FOG", Fog_vs);
}


void onCommand(CBlob@ this,u8 cmd,CBitStream @params)
{
	if(cmd==this.getCommandID("removeAwootism")) 
	{
		u16 blob1,player1;

		if(!params.saferead_u16(blob1)) {
			return;
		}
		if(!params.saferead_u16(player1)) {
			return;
		}

		CBlob@ ourBlob = getBlobByNetworkID(blob1);
		CPlayer@ player = getPlayerByNetworkId(player1);

		player.Untag("awootism");
		player.Sync("awootism",false);
		ourBlob.Tag("infectOver");
		ourBlob.Sync("infectOver",false);
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
