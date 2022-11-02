#include "CustomBlocks.as";
#include "MapType.as";
#include "TexturePackCommonRules.as";

void onInit(CBlob@ this)
{
	this.getShape().SetGravityScale(0.0f);
	this.getShape().SetStatic(true);
	
	getRules().set_u8("map_type", 0);

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
		map.CreateTileMap(0, 0, 8.0f, "world.png");
		
		map.CreateSky(color_white, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0);

		map.AddBackground("BackgroundPlains.png", Vec2f(0.0f, -18.0f), Vec2f(0.3f, 0.3f), color_white);
		map.AddBackground("BackgroundTrees.png", Vec2f(0.0f,  -5.0f), Vec2f(0.4f, 0.4f), color_white);
		map.AddBackground("BackgroundIsland.png", Vec2f(0.0f, 0.0f), Vec2f(0.6f, 0.6f), color_white);

		setTextureSprite(this,TreeTexture,"Trees.png");
		setTextureSprite(this,BushTexture,"Bushes.png");
		setTextureSprite(this,IvyTexture,"Ivy.png");
		swapBlobTextures();	
	}
}