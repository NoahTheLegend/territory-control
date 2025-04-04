#include "Hitters.as";
#include "Explosion.as";

const int PRIME_TIME = 3;

void onInit(CBlob@ this)
{
	this.Tag("map_damage_dirt");
	this.getShape().SetStatic(true);
	this.set_f32("map_damage_ratio", 0.125f);

	if (!this.exists("boom_frequency")) this.set_u8("boom_frequency", 1);
	if (!this.exists("boom_start")) this.set_u8("boom_start", 0);
	if (!this.exists("boom_end")) this.set_u8("boom_end", 8);
	if (!this.exists("boom_delay")) this.set_u32("boom_delay", 0);
    if (!this.exists("boom_shrapnel_quantity")) this.set_u32("boom_shrapnel_quantity", 1);
}

void DoExplosion(CBlob@ this)
{
    CRules@ rules = getRules();
	if (!shouldExplode(this, rules))
	{
		addToNextTick(this, rules, DoExplosion);
		return;
	}

    u32 shrapnel_quantity = this.get_u32("boom_shrapnel_quantity");

    if (isServer())
    {
        f32 angle = this.get_f32("bomb angle");
        for (u32 i = 0; i < shrapnel_quantity; i++)
        {
            CBlob@ blob = server_CreateBlob("tankshell", this.getTeamNum(), this.getPosition());
		    blob.setVelocity(getRandomVelocity(angle, 15 + XORRandom(5), 45));
		    blob.server_SetTimeToDie(20 + XORRandom(10));
		    blob.set_u32("primed_time", getGameTime() + PRIME_TIME);
        }
    }
}

void onTick(CBlob@ this)
{
    if (this.get_u8("boom_start") == this.get_u8("boom_end")) 
    {
        if (isServer()) this.server_Die();
        this.Tag("dead");

        return;
    }

    if (this.hasTag("dead")) return;

    u32 ticks = this.getTickSinceCreated();

    if (ticks >= this.get_u32("boom_delay") && ticks % this.get_u8("boom_frequency") == 0 && this.get_u8("boom_start") < this.get_u8("boom_end"))
    {
        DoExplosion(this);
        this.set_u8("boom_start", this.get_u8("boom_start") + 1);
    }
}
