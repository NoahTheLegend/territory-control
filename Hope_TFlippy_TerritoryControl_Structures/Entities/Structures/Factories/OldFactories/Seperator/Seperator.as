// TrapBlock.as

#include "Hitters.as";
#include "MapFlags.as";
#include "MinableMatsCommon.as";

int openRecursion = 0;

void onInit(CBlob@ this)
{
	this.getSprite().SetZ(10);

	this.getShape().SetRotationsAllowed(false);

	this.set_bool("open", false);
	this.set_bool("reversed", false);
	this.addCommandID("reverse");
	this.Tag("place norotate");

	//block knight sword
	this.Tag("blocks sword");
	this.Tag("blocks water");

	this.set_TileType("background tile", CMap::tile_castle_back);

	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	this.Tag("ignore extractor");
	this.Tag("builder always hit");

	HarvestBlobMat[] mats = {};
	mats.push_back(HarvestBlobMat(10.0f, "mat_stone")); 
	mats.push_back(HarvestBlobMat(5.0f, "mat_wood"));
	this.set("minableMats", mats);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.getConsts().accurateLighting = true;

	if (!isStatic) return;

	this.getSprite().PlaySound("/build_door.ogg");
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return true;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBitStream params;

	if (this !is null)
	{
		CButton@ button = caller.CreateGenericButton(17, Vec2f(0, 3.0f), this, this.getCommandID("reverse"), "Reverse logic filter \nAlready reversed: " + this.get_bool("reversed"), params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("reverse"))
	{
		if (this !is null)
		{
			if (!this.get_bool("reversed"))
				this.set_bool("reversed", true);
			else
				this.set_bool("reversed", false);
			printf("" + this.get_bool("reversed"));
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null || blob.hasTag("player")) return;
	if (blob.getPosition().y > this.getPosition().y) return;
	
	if (this.get_bool("reversed"))
	{
		if (!this.hasBlob(blob.getName(), 0))
		{
			blob.setVelocity(Vec2f(this.isFacingLeft() ? -1 : 1, -6));
			if(isClient()) this.getSprite().PlaySound("/launcher_boing" + XORRandom(2) + ".ogg", 0.5f, 0.9f);
		}
		else if (Maths::Abs(blob.getVelocity().y) < 2.0f) blob.setVelocity(Vec2f(this.isFacingLeft() ? -1 : 1, -1.0f));
	}
	else if (!this.get_bool("reversed"))
	{
		if (this.hasBlob(blob.getName(), 0))
		{
			blob.setVelocity(Vec2f(this.isFacingLeft() ? -1 : 1, -6));
			if(isClient()) this.getSprite().PlaySound("/launcher_boing" + XORRandom(2) + ".ogg", 0.5f, 0.9f);
		}
		else if (Maths::Abs(blob.getVelocity().y) < 2.0f) blob.setVelocity(Vec2f(this.isFacingLeft() ? -1 : 1, -1.0f));
	}
	else return;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}