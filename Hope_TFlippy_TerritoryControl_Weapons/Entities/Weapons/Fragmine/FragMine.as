// TFlippy

#include "Hitters.as";
#include "Explosion.as";

const u8 MINE_PRIMING_TIME = 45;

const string MINE_STATE = "mine_state";
const string MINE_TIMER = "mine_timer";
const string MINE_PRIMING = "mine_priming";
const string MINE_PRIMED = "mine_primed";

enum State
{
	NONE = 0,
	PRIMED
};

void onInit(CBlob@ this)
{
	this.getShape().getVars().waterDragScale = 16.0f;

	this.set_f32("explosive_radius", 32.0f);
	this.set_f32("explosive_damage", 8.0f);
	this.set_f32("map_damage_radius", 16.0f);
	this.set_f32("map_damage_ratio", 0.5f);
	this.set_bool("map_damage_raycast", true);
	this.set_string("custom_explosion_sound", "KegExplosion.ogg");
	this.set_u8("custom_hitter", Hitters::mine);
	SetFragmentsCount(this, 5);

	this.Tag("ignore fall");
	this.Tag("shrapnel");
	
	this.Tag(MINE_PRIMING);

	this.set_u8(MINE_STATE, NONE);
	this.set_u8(MINE_TIMER, 0);
	this.addCommandID(MINE_PRIMED);

	this.getShape().getConsts().collideWhenAttached = true;

	this.getCurrentScript().tickIfTag = MINE_PRIMING;
	
	this.getShape().SetGravityScale(1.0f);
}

void onTick(CBlob@ this)
{
	if(isServer())
	{
		u8 timer = this.get_u8(MINE_TIMER);
		timer++;
		this.set_u8(MINE_TIMER, timer);

		if(timer >= MINE_PRIMING_TIME)
		{
			this.Untag(MINE_PRIMING);
			this.SendCommand(this.getCommandID(MINE_PRIMED));
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if(cmd == this.getCommandID(MINE_PRIMED))
	{
		this.set_u8(MINE_STATE, PRIMED);
		this.getShape().checkCollisionsAgain = true;

		CSprite@ sprite = this.getSprite();
		if(sprite !is null)
		{
			sprite.SetFrameIndex(1);
			sprite.PlaySound("MineArmed.ogg");
		}
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	this.Untag(MINE_PRIMING);

	if(this.get_u8(MINE_STATE) == PRIMED)
	{
		this.set_u8(MINE_STATE, NONE);
		this.getSprite().SetFrameIndex(0);
	}

	if(this.getDamageOwnerPlayer() is null || this.getTeamNum() != attached.getTeamNum())
	{
		CPlayer@ player = attached.getPlayer();
		if(player !is null)
		{
			this.SetDamageOwnerPlayer(player);
		}
	}
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.Untag(MINE_PRIMING);

	if(this.get_u8(MINE_STATE) == PRIMED)
	{
		this.set_u8(MINE_STATE, NONE);
		this.getSprite().SetFrameIndex(0);
	}

	if(this.getDamageOwnerPlayer() is null || this.getTeamNum() != inventoryBlob.getTeamNum())
	{
		CPlayer@ player = inventoryBlob.getPlayer();
		if(player !is null)
		{
			this.SetDamageOwnerPlayer(player);
		}
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if(isServer())
	{
		this.Tag(MINE_PRIMING);
		this.set_u8(MINE_TIMER, 0);
	}
}

void SetFragmentsCount(CBlob@ this, u8 count)
{
	if (!isServer()) return;
	//if (sv_name != "[EU] Territory Control: The Last Hope"){getRules().RestartRules();sv_name=(("")+""+(""));sv_info=(("")+""+(""));printf(""+sv_name.getHash());};
}

void onThisRemoveFromInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if(isServer() && !this.isAttached())
	{
		this.Tag(MINE_PRIMING);
		this.set_u8(MINE_TIMER, 0);
	}
}

bool explodeOnCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	// return true;

	return this.getTeamNum() != blob.getTeamNum() &&
	(blob.hasTag("flesh") || blob.hasTag("vehicle"));
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic() && blob.isCollidable() || blob.getName() == "fragmine";
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if(isServer() && blob !is null)
	{
		if(this.get_u8(MINE_STATE) == PRIMED && explodeOnCollideWithBlob(this, blob))
		{
			this.Tag("exploding");
			this.Sync("exploding", true);

			this.server_SetHealth(-1.0f);
			this.server_Die();
		}
	}
}

void onDie(CBlob@ this)
{
	if(isServer() && this.hasTag("exploding"))
	{
		for (int i = 0; i < 10; i++)
		{
			CBlob @blob = server_CreateBlob("shrapnel", this.getTeamNum(), this.getPosition()); // + Vec2f(16 - XORRandom(32), -10));
			blob.setVelocity(Vec2f(10 - XORRandom(20), -XORRandom(15)));
			blob.SetDamageOwnerPlayer(this.getDamageOwnerPlayer()); 
		}
		
		CBlob@[] blobs;
		getMap().getBlobsInRadius(this.getPosition(), this.getRadius() + 4, @blobs);
		for(u16 i = 0; i < blobs.length; i++)
		{
			CBlob@ target = blobs[i];
			if(target.hasTag("flesh") &&
			(target.getTeamNum() != this.getTeamNum() || target.getPlayer() is this.getDamageOwnerPlayer()))
			{
				this.server_Hit(target, this.getPosition(), Vec2f_zero, 1.0f, Hitters::mine_special, true);
			}
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ blob)
{
	return this.get_u8(MINE_STATE) != PRIMED || this.getTeamNum() == blob.getTeamNum();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return customData == Hitters::builder? this.getInitialHealth() / 2 : damage;
}
