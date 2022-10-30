#include "Hitters.as"
#include "TreeCommon.as"

void onInit(CBlob @ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);

	this.getShape().SetRotationsAllowed(false);
	this.Tag("place norotate");
	this.Tag("builder always hit");
	this.Tag("extractable");

	this.getCurrentScript().tickFrequency = 30;

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("Treecapicator_Idle.ogg");
		sprite.SetEmitSoundVolume(0.05f);
		sprite.SetEmitSoundSpeed(0.8f);
		sprite.SetEmitSoundPaused(false);
	}
}

void onTick(CBlob@ this)
{
	if (this.getInventory().isFull()) return;
	if (!this.getShape().isStatic()) return;

	if (isServer())
	{
		CMap@ map = getMap();

		CBlob@[] blobs;
		map.getBlobsAtPosition(this.getPosition() + Vec2f(8, 0), @blobs);
		map.getBlobsAtPosition(this.getPosition() + Vec2f(-8, 0), @blobs);

		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			if (b !is null && (b.hasTag("nature") || b.getName() == "log"))
			{
				string bname = b.getName();

				if (b.hasTag("tree"))
				{
					TreeVars@ tree;
					b.get("TreeVars", @tree);
					if (tree !is null)
					{
						if (tree.height == tree.max_height)
						{
							this.server_Hit(b, b.getPosition(), Vec2f(0, 0), 1.00f, Hitters::saw);
						}
					}
				}
				else if (bname == "log")
				{
					this.server_PutInInventory(b);
				}
				else if (bname == "pumpkin_plant" || bname == "ganja_plant" || bname == "grain_plant" )
				{
					if (b.hasTag("has pumpkin") || b.hasTag("has pod") || b.hasTag("has grain"))
					{
						this.server_Hit(b, b.getPosition(), Vec2f(0, 0), 0.5f, Hitters::saw);
						this.server_Hit(this, this.getPosition(), Vec2f(0,0), 0.25f, Hitters::saw); // slightly break structure
					}
				}
				else if (!b.getShape().isStatic())
				{
					this.server_Hit(b, b.getPosition(), Vec2f(0, 0), 0.50f, Hitters::saw);
				}
			}
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.getName() == "pumpkin" || blob.getName() == "grain"
	|| blob.getName() == "mat_ganja" || blob.getName() == "ganjapod") 
		return false;
	return true;
}