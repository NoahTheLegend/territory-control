#include "CustomBlocks.as";
#include "MapType.as";
#include "TexturePackCommonRules.as";

void onInit(CBlob@ this)
{
	this.getShape().SetGravityScale(0.0f);
	this.getShape().SetStatic(true);
	
	getRules().set_u8("map_type", MapType::desert);
	Sound::Play("amogus.ogg");

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

		for (u8 i = 0; i < getPlayersCount(); i++)
		{
			if (getPlayer(i) !is null && getPlayer(i).getBlob() !is null)
			{
				if (getPlayer(i).getBlob().getName() == "peasant")
				{
					CBlob@ b = getPlayer(i).getBlob();
					CBlob@ newBlob = server_CreateBlob("amogus", b.getTeamNum(), b.getPosition());
					newBlob.server_SetPlayer(getPlayer(i));
					b.server_Die();
				}
			}
		}
	}

	if (isClient())
	{
		SetScreenFlash(255, 255, 255, 255);
	
		CMap@ map = this.getMap();
		map.CreateTileMap(0, 0, 8.0f, "Susik_World.png");
		
		map.CreateSky(color_white, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0);
		map.CreateSkyGradient("skygradient.png");

        map.AddBackground("BackgroundPlains.png", Vec2f(0.0f, -18.0f), Vec2f(0.3f, 0.3f), color_white);
		map.AddBackground("BackgroundTrees.png", Vec2f(0.0f,  -5.0f), Vec2f(0.4f, 0.4f), color_white);
    	map.AddBackground("BackgroundIsland.png", Vec2f(0.0f, 0.0f), Vec2f(0.6f, 0.6f), color_white);

		setTextureSprite(this,TreeTexture,"Susik_Trees.png");
		setTextureSprite(this,BushTexture,"Susik_Bushes.png");
		setTextureSprite(this,IvyTexture,"Susik_Ivy.png");
		swapBlobTextures();	
	}
}