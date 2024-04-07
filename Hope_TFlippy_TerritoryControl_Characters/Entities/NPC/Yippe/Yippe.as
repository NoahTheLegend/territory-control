#include "AnimalConsts.as";

const u8 DEFAULT_PERSONALITY = AGGRO_BIT;

void onInit(CSprite@ this)
{
	this.ReloadSprites(0, 0); //always blue
	this.addSpriteLayer("isOnScreen","NoTexture.png",1,1);
	this.ScaleBy(Vec2f(0.5f,0.5f));

}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	if (!blob.hasTag("dead"))
	{
		if(!this.getSpriteLayer("isOnScreen").isOnScreen()){
			return;
		}

		Vec2f vel=blob.getVelocity();
		if(vel.x!=0.0f)
		{
			this.SetFacingLeft(vel.x < 0.0f ? true : false);
		}
		f32 x = blob.getVelocity().x;
		if (Maths::Abs(x) > 0.2f)
		{
			this.SetAnimation("walk");
		}
		else
		{
			this.SetAnimation("idle");
		}
	}
	else
	{
		this.SetAnimation("dead");
		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}

void onInit(CBlob@ this)
{
	//for EatOthers
	string[] tags = {"player"};
	this.set("tags to eat", tags);

	this.set_u32("next_sound", 0);
	this.Tag("grapplable");

	//brain
	this.set_u8(personality_property, DEFAULT_PERSONALITY);
	this.set_u8("random move freq", 5);
	this.set_f32(target_searchrad_property, 320.0f);
	this.set_f32(terr_rad_property, 85.0f);
	this.set_u8(target_lose_random, 34);
	
	if (!this.exists("voice_pitch")) this.set_f32("voice pitch", 4.50f);

	// this.getCurrentScript().removeIfTag = "dead";

	this.getBrain().server_SetActive(true);

	//for shape
	this.getShape().SetRotationsAllowed(false);

	//for flesh hit
	this.set_f32("gib health", -0.0f);

	this.Tag("flesh");
	this.Tag("dangerous");

	this.set_u8("number of steaks", 3);

	this.getShape().SetOffset(Vec2f(0, 0));

	this.getCurrentScript().runFlags |= Script::tick_blob_in_proximity;
	this.getCurrentScript().runProximityTag = "player";
	this.getCurrentScript().runProximityRadius = 320.0f;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;

	//movement
	AnimalVars@ vars;
	if (!this.get("vars", @vars))
		return;
	vars.walkForce.Set(64.0f, -7.4f);
	vars.runForce.Set(128.0f, -55.0f);
	vars.slowForce.Set(16.0f, 0.0f);
	vars.jumpForce.Set(0.0f, -300.0f);
	vars.maxVelocity = 2.75f;

	AttachmentPoint@[] aps;
	if (this.getAttachmentPoints(@aps))
	{
		for (uint i = 0; i < aps.length; i++)
		{
			AttachmentPoint@ ap = aps[i];
			ap.offsetZ = 10.0f;
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return this.getHealth() < 5.0f && !this.hasAttached(); 
}

void onTick(CBlob@ this)
{
	if (!this.hasTag("dead"))
	{
		if (this.get_u32("next_sound") < getGameTime())
		{
			this.set_u32("next_sound", getGameTime()+8+XORRandom(23));
			this.getSprite().PlaySound("yippe.ogg", 1.0f, 1.0f + XORRandom(11)*0.001f);
			if (this.isOnGround()) this.AddForce(Vec2f(0,-4)*this.getMass());
		}

		if (this.getHealth() < 3.0)
		{
			this.Tag("dead");
		}

		Vec2f vel = this.getVelocity();
		if (vel.x != 0.0f)
		{
			this.SetFacingLeft(vel.x < 0.0f);
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	MadAt(this, hitterBlob);
	return damage;
}

void MadAt(CBlob@ this, CBlob@ hitterBlob)
{
	if (hitterBlob is null) return;

	this.set_u8(personality_property, DEFAULT_PERSONALITY | AGGRO_BIT);
	this.set_u8(state_property, MODE_TARGET);

	if (hitterBlob !is this && hitterBlob.getName() != this.getName()) this.set_netid(target_property, hitterBlob.getNetworkID());
}

#include "Hitters.as";

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !blob.hasTag("flesh");
}

void onDie(CBlob@ this)
{
	if (this.getName() == "yippedanger")
	{
		if (isServer())
		{
			CBlob@ b = server_CreateBlob("mat_explodium", -1, this.getPosition());
			if (b !is null) b.server_Die();
		}
	}
	else
	{
		u8 rnd = XORRandom(1); // add something else later
		if (rnd == 0)
		{
			if (isServer())
			{
				for (u8 i = 0; i < 5 + XORRandom(10); i++)
				{
					CBlob@ b = server_CreateBlob("amogusplushie", XORRandom(7), this.getPosition());
					if (b !is null)
					{
						b.setVelocity(Vec2f(4+XORRandom(16), 0).RotateBy(XORRandom(360)));
						b.server_SetTimeToDie(10 + XORRandom(10));
					}
				}
			}
			if (isClient())
			{

			}
		}
	}
}