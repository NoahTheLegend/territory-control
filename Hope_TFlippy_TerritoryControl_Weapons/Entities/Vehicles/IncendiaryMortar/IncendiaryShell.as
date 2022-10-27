#include "Hitters.as";
#include "ShieldCommon.as";
#include "Explosion.as";

const f32 modifier = 1;

const string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

void onInit(CBlob@ this)
{
	this.server_SetTimeToDie(20);

	this.getShape().getConsts().mapCollisions = false;
	this.getShape().getConsts().bullet = true;
	this.getShape().getConsts().net_threshold_multiplier = 4.0f;

	this.Tag("map_damage_dirt");
	this.Tag("explosive");

	this.set_f32("map_damage_radius", 1.0f);
	this.set_f32("map_damage_ratio", 0.1f);

	this.Tag("projectile");
	this.getSprite().SetFrame(0);
	this.getSprite().getConsts().accurateLighting = false;
	this.getSprite().SetFacingLeft(!this.getSprite().isFacingLeft());

	this.SetMapEdgeFlags(CBlob::map_collide_left | CBlob::map_collide_right);
	this.sendonlyvisible = false;
	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		sprite.SetEmitSound("Shell_Whistle.ogg");
		sprite.SetEmitSoundPaused(false);
		sprite.SetEmitSoundVolume(0.0f);
	}
}

void onTick(CBlob@ this)
{
	Vec2f velocity = this.getVelocity();
	f32 angle = velocity.Angle();
	if (isServer()) Pierce(this, velocity, angle);

	this.setAngleDegrees(-angle + 90.0f);

	// this.getSprite().SetEmitSoundPaused(this.getVelocity().y < 0);
	if (isClient())
	{
		f32 modifier = Maths::Max(0, this.getVelocity().y * 0.02f);
		this.getSprite().SetEmitSoundVolume(Maths::Max(0, modifier));
	}
}

void Pierce(CBlob@ this, Vec2f velocity, const f32 angle)
{
	CMap@ map = this.getMap();

	const f32 speed = velocity.getLength();

	Vec2f direction = velocity;
	direction.Normalize();

	Vec2f position = this.getPosition();
	Vec2f tip_position = position + direction * 4.0f;
	Vec2f tail_position = position + direction * -4.0f;

	const Vec2f[] positions =
	{
		position,
		tip_position,
		tail_position
	};

	for (uint i = 0; i < positions.length; i ++)
	{
		Vec2f temp_position = positions[i];
		TileType type = map.getTile(temp_position).type;
		const u32 offset = map.getTileOffset(temp_position);

		if (map.hasTileFlag(offset, Tile::SOLID))
		{
			onCollision(this, null, true);
		}
	}

	HitInfo@[] infos;

	if (map.getHitInfosFromArc(tail_position, -angle, 10, (tip_position - tail_position).getLength(), this, false, @infos))
	{
		for (uint i = 0; i < infos.length; i ++)
		{
			CBlob@ blob = infos[i].blob;
			Vec2f hit_position = infos[i].hitpos;

			if (blob !is null)
			{
				onCollision(this, blob, false);
			}
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob !is null) return (this.getTickSinceCreated() > 5 && this.getTeamNum() != blob.getTeamNum() && blob.isCollidable());
	else return false;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (isServer() && getGameTime() >= this.get_u32("primed_time"))
	{
		if (blob !is null && doesCollideWithBlob(this, blob)) this.server_Die();
		else if (solid) this.server_Die();
	}
}

void onDie(CBlob@ this)
{
	DoExplosion(this);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::explosion) return 0;
	return damage;
}

void DoExplosion(CBlob@ this)
{
	CRules@ rules = getRules();
	if (!shouldExplode(this, rules))
	{
		addToNextTick(this, rules, DoExplosion);
		return;
	}

	f32 random = XORRandom(16);
	f32 modifier = 1 + Maths::Log(this.getQuantity());
	f32 angle = this.getAngleDegrees() - this.get_f32("bomb angle");

	this.set_f32("map_damage_radius", 1.0f);
	this.set_f32("map_damage_ratio", 0.1f);

	Explode(this, 40.0f + random, 15.0f);

	for (int i = 0; i < 4 * modifier; i++) 
	{
		Vec2f dir = getRandomVelocity(angle, 1, 120);
		dir.x *= 2;
		dir.Normalize();

		LinearExplosion(this, dir, 8.0f + XORRandom(16) + (modifier * 8), 8 + XORRandom(24), 3, 0.125f, Hitters::explosion);
	}

	Vec2f pos = this.getPosition();
	CMap@ map = getMap();

	if (isServer())
	{
		CBlob@[] blobs;

		if (map.getBlobsInRadius(pos, 128.0f, @blobs))
		{
			for (int i = 0; i < blobs.length; i++)
			{
				CBlob@ blob = blobs[i];
				if (blob !is null && (blob.hasTag("flesh") || blob.hasTag("plant"))) 
				{
					map.server_setFireWorldspace(blob.getPosition(), true);
					blob.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), 0.5f, Hitters::fire);
				}
			}
		}

		for (int i = 0; i < (7 + XORRandom(5)) * modifier; i++)
		{
			CBlob@ blob = server_CreateBlob("flame", -1, this.getPosition());
			blob.setVelocity(Vec2f(XORRandom(10) - 5, -XORRandom(10)));
			blob.server_SetTimeToDie(20 + XORRandom(10));
		}
		for(int a = 0; a < 80; a++)
		{
			map.server_setFireWorldspace(pos + Vec2f(8 - XORRandom(16), 8 - XORRandom(16)) * 8, true);
		}
	}

	if (isClient() && this.isOnScreen())
	{
		for (int i = 0; i < 80; i++)
		{

			MakeParticle(this, Vec2f( XORRandom(64) - 32, XORRandom(80) - 60), getRandomVelocity(angle, XORRandom(400) * 0.01f, 70), particles[XORRandom(particles.length)]);
			// ParticleAnimated("Entities/Effects/Sprites/FireFlash.png", this.getPosition() + Vec2f(0, -4), Vec2f(0, 0.5f), 0.0f, 1.0f, 2, 0.0f, true);
		}
		this.getSprite().Gib();
	}
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(4), XORRandom(100) * -0.00005f, true);
}
