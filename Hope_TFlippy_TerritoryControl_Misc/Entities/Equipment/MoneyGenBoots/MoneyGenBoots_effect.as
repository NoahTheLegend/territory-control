#include "hitters.as";
#include "Knocked.as";
#include "RunnerCommon.as";

void onInit(CBlob@ this)
{
    this.set_u32("fuel_countboots", 0);
    this.addCommandID("load_fuelboots");
}

void onInit(CRules@ this)
{
    this.addCommandID("load_fuelboots");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBitStream params;
	CBlob@ carried = caller.getCarriedBlob();
	if (carried !is null)
	{
		string fuel_name = carried.getName();
		bool isValid = fuel_name == "mat_wood" || fuel_name == "mat_coal";
		if (isValid)
		{
			CButton@ button = caller.CreateGenericButton("$" + fuel_name + "$", Vec2f(0, 0), this, this.getCommandID("load_fuelboots"), "Load " + carried.getInventoryName() + "\nFuel left: " + this.get_u32("fuel_countboots"), params);
		}
	}
}

void onTick(CBlob@ this)
{
    if (this !is null)
    {
        if (this.isOnGround() && !this.isOnLadder())
        {
            if (Maths::Abs(this.getVelocity().x) > 0.5f
            && getGameTime() % 6 == 0 && this.get_u32("fuel_countboots") > 25)
            {
                if (this.getPlayer() !is null) this.getPlayer().server_setCoins(this.getPlayer().getCoins() + XORRandom(15));
                if (this.get_u32("fuel_countboots") >= 25) this.set_u32("fuel_countboots", this.get_u32("fuel_countboots") - 6+XORRandom(5));
                else this.set_u32("fuel_countboots", 0);
                this.getSprite().PlaySound("LotteryTicket_Kaching.ogg", 0.5f, 1.5f);
                ParticleAnimated("Smoke.png", this.getPosition()+Vec2f(0, 0),
	            Vec2f(0, 0), 0.0f, 1.0f, 3, 0.0f, false);
            }
        }
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("load_fuelboots"))
	{
		CMap@ map = this.getMap();
		CBlob@[] fuel;
		map.getBlobsInRadius(this.getPosition(), 5.0f, fuel);

		for (int i = 0; i < fuel.length; i++)
		{
			if (fuel[i] !is null && fuel[i].isAttached())
			{
                CBlob@ carried = fuel[i];
				int add = fuel[i].getQuantity();

				u32 fuel = this.get_u32("fuel_countboots");

				if (carried.getName() == "mat_wood") this.set_u32("fuel_countboots", fuel + add);
                else if (carried.getName() == "mat_coal") this.set_u32("fuel_countboots", fuel + add * 20);

				carried.Tag("dead");
				carried.server_Die();
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
    return damage;
}