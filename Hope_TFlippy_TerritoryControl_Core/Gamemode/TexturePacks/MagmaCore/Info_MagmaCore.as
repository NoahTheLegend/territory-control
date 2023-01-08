#include "CustomBlocks.as";
#include "MapType.as";
#include "TexturePackCommonRules.as";

void onInit(CBlob@ this)
{
	this.getShape().SetGravityScale(0.0f);
	this.getShape().SetStatic(true);
	
	getRules().set_u8("map_type", MapType::magmacore);

	this.Tag("infos");
	if (isServer())
	{
		CBlob@[] infos;
		getBlobsByTag("infos", @infos);
		for (u8 i = 0; i < infos.length; i++)
		{
			CBlob@ b = infos[i];
			if (b is null) continue;
			if (b is this) continue;
			b.server_Die();
		}
	}

	if (isClient())
	{
		//SetScreenFlash(255, 255, 255, 255);
	
		CMap@ map = this.getMap();
		map.CreateTileMap(0, 0, 8.0f, "MagmaCore_world.png");
		
		map.CreateSky(color_white, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0);
		map.CreateSkyGradient("MagmaCore_skygradient.png"); // override sky color with gradient

		map.AddBackground("MagmaCore_Backgroundtrees.png", Vec2f(0.0f, 32.0f), Vec2f(0.2f, 0.2f), color_white);
		map.AddBackground("MagmaCore_BackgroundPlains.png", Vec2f(0.0f, -18.0f), Vec2f(0.3f, 0.3f), color_white);
		map.AddBackground("MagmaCore_BackgroundIsland.png", Vec2f(0.0f, 0.0f), Vec2f(0.5f, 0.5f), color_white);

		setTextureSprite(this,TreeTexture,"MagmaCore_Trees.png");
		setTextureSprite(this,BushTexture,"MagmaCore_Bushes.png");
		setTextureSprite(this,IvyTexture,"MagmaCore_Ivy.png");
		swapBlobTextures();	
	}
}

void onTick(CBlob@ this)
{
	if (getMap() !is null)
	{
		getMap().SetDayTime(0.3);
	}
}