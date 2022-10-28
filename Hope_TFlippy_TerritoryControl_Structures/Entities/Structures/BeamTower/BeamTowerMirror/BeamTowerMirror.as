// A script by TFlippy & Pirate-Rob

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";
#include "BuilderHittable.as";
#include "Hitters.as";

const u32 ELECTRICITY_MAX = 500;
const u32 ELECTRICITY_PROD = 15;

void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 30;

	this.Tag("ignore extractor");
	this.Tag("builder always hit");
	this.Tag("generator");

	this.addCommandID("sync_prep");
	this.addCommandID("sync");

	this.set_u32("elec_max", ELECTRICITY_MAX);
	this.set_u16("consume_id", 0);
	this.set_Vec2f("wire_offset", Vec2f(0, 4));

	this.set_u32("elec", 0);
	server_Sync(this);
}

void onInit(CSprite@ this)
{
	CSpriteLayer@ mirror = this.addSpriteLayer("mirror", "BeamTowerMirror.png", 16, 24);
	if (mirror !is null)
	{
		mirror.SetOffset(Vec2f(0.0f, -8.0f));
		mirror.SetRelativeZ(1.00f);
		mirror.SetFrameIndex(1);
		mirror.RotateBy(50.0f, Vec2f(0,0));
	}
}

void onTick(CBlob@ this)
{
	CMap@ map = this.getMap();
	if (map is null) return;

	f32 time = map.getDayTime();
	if (time < 0.2f || time > 0.9f) return;

	Vec2f pos = this.getPosition();
	if (map.rayCastSolidNoBlobs(Vec2f(pos.x, 0), pos)) return;

	u16 prod = ELECTRICITY_PROD;
	if (time > 0.3f && time <= 0.4f) prod *= 1.25f;
	else if (time > 0.4f && time <= 0.5f) prod *= 1.5f;
	else if (time > 0.5f && time <= 0.6f) prod *= 1.75f;
	else if (time > 0.6f && time <= 0.7f) prod *= 1.5f;
	else if (time > 0.7f && time <= 0.8f) prod *= 1.25f;
	
	if (this.get_u32("elec") < ELECTRICITY_MAX-prod)
	{
		this.add_u32("elec", prod);
	}

	CSprite@ sprite = this.getSprite();
}

void server_Sync(CBlob@ this)
{
    if (isServer())
    {
        CBitStream params;
        params.write_u32(this.get_u32("elec"));
        this.SendCommand(this.getCommandID("sync"), params);
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("sync"))
	{
		if (isClient())
		{
			u32 elec;
            if (!params.saferead_u32(elec)) return;
			this.set_u32("elec", elec);
		}
	}
}