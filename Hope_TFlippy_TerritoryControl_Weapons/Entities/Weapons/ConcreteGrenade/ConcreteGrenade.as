#include "Hitters.as";
#include "Knocked.as";
#include "Explosion.as";

const f32 max_range = 128.00f;

void onInit(CBlob@ this)
{
	this.getSprite().PlaySound("grenade_pinpull.ogg");

	this.Tag("projectile");
	//this.server_SetTimeToDie(3);
	this.set_u8("death_timer", 3);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (!solid)
	{
		return;
	}

	const f32 vellen = this.getOldVelocity().Length();
	if (vellen > 1.7f)
	{
		Sound::Play("/BombBounce.ogg", this.getPosition(), Maths::Min(vellen / 8.0f, 1.1f), 1.2f);
	}
}

void onDie(CBlob@ this)
{
	if (isServer()) 
	{
		CBlob@ blob = server_CreateBlob("liquidconcrete", -1, this.getPosition());
	}
	Explode(this, 0.01f, 0.00f);
}

void DoExplosion(CBlob@ this)
{
	CRules@ rules = getRules();
	if (!shouldExplode(this, rules))
	{
		addToNextTick(this, rules, DoExplosion);
		return;
	}

	if (this.hasTag("dead")) return;

	f32 random = XORRandom(50)+50;
	f32 modifier = 1 + Maths::Log(this.getQuantity());
	f32 angle = -this.get_f32("bomb angle");
	// print("Modifier: " + modifier + "; Quantity: " + this.getQuantity());

	this.set_f32("map_damage_radius", (0.5f + random) * modifier);
	this.set_f32("map_damage_ratio", 0.05f);

	for (int i = 0; i < 4 * modifier; i++)
	{
		Vec2f dir = getRandomVelocity(angle, 1, 120);
		dir.x *= 2;
		dir.Normalize();

		LinearExplosion(this, dir, 8.0f + XORRandom(16) + (modifier * 8), 8 + XORRandom(24), 3, 0.125f, Hitters::explosion);
	}

	Vec2f pos = this.getPosition();
	CMap@ map = getMap();

	const u32 count = 200;
	const f32 seg = 360.00f / count;

	for (int i = 0; i < count; i++)
	{
		Vec2f dir = Vec2f(Maths::Cos(i * seg), Maths::Sin(i * seg));
		Vec2f ppos = pos + dir * 4.00f;
		f32 vel = XORRandom(100) / 5.00f;

		CParticle@ p = ParticlePixelUnlimited(ppos, dir * vel, SColor(255, XORRandom(255), XORRandom(255), XORRandom(255)) + SColor(255, XORRandom(255), XORRandom(255), XORRandom(255)), true);
		if (p !is null)
		{
			p.gravity = Vec2f(0, 1.0f);
			p.scale = 3.00f + (XORRandom(100) / 25.00f);
			p.growth = 1.50f;
			p.timeout = 120;
		}
	}

	CBlob@ local = getLocalPlayerBlob();
	if (local !is null && Maths::Abs(local.getPosition().x - pos.x) < 100)
	{
		SColor c = SColor(255, XORRandom(255), XORRandom(255), XORRandom(255)) + SColor(255, XORRandom(255), XORRandom(255), XORRandom(255));
	}


	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (point !is null)
	{
		CBlob@ holder = point.getOccupied();
		if (holder !is null)
		{
			SetKnocked(holder, 90);
		}
	}


	this.Tag("dead");
	this.getSprite().Gib();
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (inventoryBlob is null) return;

	CInventory@ inv = inventoryBlob.getInventory();

	if (inv is null) return;

	this.doTickScripts = true;
	inv.doTickScripts = true;
}