#include "Requirements.as";
#include "Requirements_Tech.as";
#include "ShopCommon.as";
#include "DeityCommon.as";
#include "MakeSeed.as";

void onInit(CBlob@ this)
{
	this.set_u8("deity_id", Deity::foghorn);
	this.set_Vec2f("shop menu size", Vec2f(2, 2));
	
	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("Disc_Money.ogg");
	sprite.SetEmitSoundVolume(0.40f);
	sprite.SetEmitSoundSpeed(1.00f);
	sprite.SetEmitSoundPaused(false);
	
	this.SetLight(true);
	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 170, 255, 61));
	
	AddIconToken("$icon_trollbird_follower$", "InteractionIcons.png", Vec2f(32, 32), 11);
	{
		ShopItem@ s = addShopItem(this, "Become a real master of trolling", "$icon_trollbird_follower$", "follower", "I bet, it IS a worth investment!");
		AddRequirement(s.requirements, "blob", "mat_goldingot", "Gold ingot", 1000);

		s.customButton = true;
		s.buttonwidth = 2;	
		s.buttonheight = 2;
		
		s.spawnNothing = true;
	}

	this.set_f32("deity_power", 0);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		if (isClient())
		{
			this.getSprite().PlaySound("littletrolling", 3.00f, 1.00f);
		}
	}
}