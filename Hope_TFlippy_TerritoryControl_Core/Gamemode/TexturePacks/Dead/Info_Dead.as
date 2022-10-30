#include "CustomBlocks.as";
#include "MapType.as";
#include "TexturePackCommonRules.as";

void onInit(CBlob@ this)
{
	this.getShape().SetGravityScale(0.0f);
	this.getShape().SetStatic(true);
	
	getRules().set_u8("map_type", MapType::dead);

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
	
	if (isServer())
	{
		CBlob@[] nature;
		//getBlobsByName("bush", @nature);
		//getBlobsByName("ivy", @nature);
		getBlobsByName("piglet", @nature);
		getBlobsByName("chicken", @nature);
		getBlobsByName("bison", @nature);
		getBlobsByName("badger", @nature);
		getBlobsByName("flower", @nature);
		getBlobsByName("badgerden", @nature);
		getBlobsByName("grain_plant", @nature);
		getBlobsByName("pumpkin_plant", @nature);
		getBlobsByName("grain", @nature);
		getBlobsByName("seed", @nature);
		
		for (int i = 0; i < nature.length; i++)
		{
			CBlob@ b = nature[i];
			// Disabled to reduce lag
			// if (XORRandom(8) == 0)
			// {
			// 	switch (XORRandom(3))
			// 	{
			// 		case 0:
			// 			server_CreateBlob("mithrilman", b.getTeamNum(), b.getPosition());
			// 		case 1:
			// 			server_CreateBlob("bagel", b.getTeamNum(), b.getPosition());
			// 		case 3:
			// 			if (XORRandom(1) == 0) server_CreateBlob("cowo", b.getTeamNum(), b.getPosition());
			// 	}
			// }
			
			b.Tag("no drop");
			b.server_Die();
		}
	}

	if (isClient())
	{
		//SetScreenFlash(255, 255, 255, 255);
	
		CMap@ map = this.getMap();
		map.CreateTileMap(0, 0, 8.0f, "Dead_world.png");
		
		map.CreateSky(color_white, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0);
		map.CreateSkyGradient("Dead_skygradient.png"); // override sky color with gradient

		map.AddBackground("Dead_BackgroundPlains.png", Vec2f(0.0f, -18.0f), Vec2f(0.3f, 0.3f), color_white);
		map.AddBackground("Dead_BackgroundTrees.png", Vec2f(0.0f,  -5.0f), Vec2f(0.4f, 0.4f), color_white);
		map.AddBackground("Dead_BackgroundIsland.png", Vec2f(0.0f, 0.0f), Vec2f(0.6f, 0.6f), color_white);

		setTextureSprite(this,TreeTexture,"Dead_Trees.png");
		setTextureSprite(this,BushTexture,"Dead_Bushes.png");
		setTextureSprite(this,IvyTexture,"Dead_Ivy.png");
		swapBlobTextures();	
	}
}