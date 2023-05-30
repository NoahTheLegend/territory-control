#include "RunnerCommon.as"
#include "MakeDustParticle.as";
#include "Knocked.as";
#include "FireParticle.as";
#include "VehicleFuel.as";

void onInit(CBlob@ this)
{
	//if (this.get_string("reload_script") != "jetpackv2")
	//	UpdateScript(this);
	this.set_u32("timer", 0);
	this.addCommandID("load_fuel");
	this.set_f32("fuel_count", 0);
	this.set_f32("max_fuel", 2250);
}

/*void UpdateScript(CBlob@ this)
{
	CSpriteLayer@ jetpack = this.getSprite().addSpriteLayer("jetpackм2", "jetpackv2_icon.png", 24, 24);

	if (jetpack !is null)
	{
		jetpack.SetVisible(true);
		jetpack.SetRelativeZ(-2);
		jetpack.SetOffset(Vec2f(2, 0));
		if (this.getSprite().isFacingLeft())
		jetpack.SetFacingLeft(true);
	}
}*/

void MakeParticle(CBlob@ this, const Vec2f pos, const string filename)
{
	this.getSprite().SetEmitSoundPaused(false);
	if (!this.isOnScreen()) {return;}
	ParticleAnimated(filename, pos, Vec2f(0, 1.0f), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(4), XORRandom(100) * -0.00005f, true);
	//ParticleAnimated(filename, this.getPosition() + pos, Vec2f(0, 1.0f), float(XORRandom(360)), 0.5f + XORRandom(100) * 0.01f, 1 + XORRandom(4), XORRandom(100) * -0.00005f, true);
}

void onTick(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	CControls@ controls = this.getControls();
	CInventory@ inv = this.getInventory();
	if (controls is null) return;
	bool shift = this.isMyPlayer() && (controls.isKeyPressed(KEY_LSHIFT) || controls.isKeyPressed(KEY_RSHIFT));
	if (controls !is null) 
		if (shift)
			if (this.get_f32("fuel_count") > 0)
			{
				this.set_f32("fuel_count", this.get_f32("fuel_count") - 3);
				if (this.get_f32("fuel_count") < 0) this.set_f32("fuel_count", 0);
			}
	//if (this.get_u32("timer") > 0) this.set_u32("timer", this.get_u32("timer") - 1);
	//if (this.get_string("reload_script") == "jetpack")
	//{
	//	UpdateScript(this);
	//	this.set_string("reload_script", "");
	//}
	u8 particlesrandom = XORRandom(3);
	if (controls !is null)
		if (!shift || this.get_f32("fuel_count") < 1) sprite.SetEmitSoundPaused(true);
	if (controls !is null)
	if (controls !is null && shift && this.get_f32("fuel_count") > 0)
	{
		Vec2f vel = this.getVelocity();
		if (this.getCarriedBlob() !is null && this.getCarriedBlob().hasTag("weapon"))
		{
			if (vel.y > -(XORRandom(5.0) + 2.0f)) this.AddForce(Vec2f(0, -25.0f));
		}
		else if (this.get_f32("fuel_count") < 500 && this.get_f32("fuel_count") > 0)
		{
			if (vel.y > -(XORRandom(5.0) + 2.0f)) this.AddForce(Vec2f(0, -40.0f) + Vec2f(0, XORRandom(10.0)));
		}
		else if (this.get_f32("fuel_count") > 0)
		{
			if (vel.y > -(XORRandom(5.0) + 2.0f)) this.AddForce(Vec2f(0, -40.0f));
		}

		Vec2f pos = this.getPosition() + Vec2f(0.0f, 2.0f);

		if (getGameTime()%15==0 && controls.isKeyPressed(KEY_LSHIFT))
		{
			CBitStream params;
			params.write_bool(true);
			this.SendCommand(this.getCommandID("jetpackv2_effects"), params);
		}

		f32 fl = this.isFacingLeft() ? 1.0f : -1.0f;
		switch (particlesrandom)
		{
			case 0:
				MakeParticle(this, pos + Vec2f(fl*5.0f, 8.0f), "SmallExplosion1.png");
				break;
			case 1:
				MakeParticle(this, pos + Vec2f(fl*5.0f, 8.0f), "SmallExplosion2.png");
				if (this.get_f32("fuel_count") < 500 && this.get_f32("fuel_count") > 0)
				{
					MakeParticle(this, pos + Vec2f(fl*5.0f, 8.0f), "SmallSteam.png");
					this.getSprite().PlaySound("DrillOverheat.ogg");
				}
				break;
			case 2:
				MakeParticle(this, pos + Vec2f(fl*5.0f, 8.0f), "SmallExplosion3.png");
				break;
		}
			

		if (this.get_u32("timer") == 0) 
		{
			//sprite.PlaySound("FlamethrowerFire.ogg", 0.4f);
			sprite.SetEmitSound("FlamethrowerFire.ogg");
			sprite.SetEmitSoundSpeed(1.1f);
			sprite.SetEmitSoundPaused(false);
			if (this.get_u32("timer") < 1) this.set_u32("timer", 45);
		}
	}
	else
	{
		if (controls.isKeyJustReleased(KEY_LSHIFT))
		{
			CBitStream params;
			params.write_bool(false);
			this.SendCommand(this.getCommandID("jetpackv2_effects"), params);
		}
	}
}

void drawInfo(CBlob@ this)
{
	Vec2f pos2d1 = this.getInterpolatedScreenPos() - Vec2f(0, 10);
	Vec2f pos2d = this.getInterpolatedScreenPos() - Vec2f(0, 60);

	Vec2f dim = Vec2f(20, 8);
	const f32 y = this.getHeight() * 2.4f;
	f32 charge_percent = 1.0f;

	Vec2f ul = Vec2f(pos2d.x - dim.x, pos2d.y + y);
	Vec2f lr = Vec2f(pos2d.x - dim.x + charge_percent * 2.0f * dim.x, pos2d.y + y + dim.y);

	if (this.isFacingLeft())
	{
		ul -= Vec2f(8, 0);
		lr -= Vec2f(8, 0);

		f32 max_dist = ul.x - lr.x;
		ul.x += max_dist + dim.x * 2.0f;
		lr.x += max_dist + dim.x * 2.0f;
	}

	f32 dist = lr.x - ul.x;
	Vec2f upperleft((ul.x + (dist / 2.0f)) + 4.0f, pos2d1.y + this.getHeight() + 30);
	Vec2f lowerright((ul.x + (dist / 2.0f)), upperleft.y + 20);

	int fuel = this.get_f32("fuel_count");
	string fuelText = "Fuel: " + fuel + " / " + this.get_f32("max_fuel");

	GUI::SetFont("menu");
	GUI::DrawTextCentered(fuelText, this.getInterpolatedScreenPos() + Vec2f(0, 40), color_white);

	// CMap@ map = getMap();
	// s32 landY = map.getLandYAtX(this.getPosition().x / 8.00f);
	// s32 height = Maths::Max(landY - (this.getPosition().y / 8.00f) - 2, 0);

	//f32 velocity = this.get_f32("velocity");
	//f32 taken = velocity / fuel_factor * this.get_f32("fuel_consumption_modifier") * (30.00f / 5.00f);

	//GUI::DrawTextCentered("Speed: " + int(this.getVelocity().getLength() * 3.60f) + " km/h", this.getInterpolatedScreenPos() + Vec2f(0, 56), color_white);
	//GUI::DrawTextCentered("Consumption: " + taken + "/s", this.getInterpolatedScreenPos() + Vec2f(-8, 68), color_white);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBitStream params;
	CBlob@ carried = caller.getCarriedBlob();
	if (carried !is null && this.get_f32("fuel_count") < this.get_f32("max_fuel"))
	{
		string fuel_name = carried.getName();
		bool isValid = fuel_name == "mat_oil";
		if (isValid)
		{
			CButton@ button = caller.CreateGenericButton("$" + fuel_name + "$", Vec2f(0, 0), this, this.getCommandID("load_fuel"), "Load " + carried.getInventoryName() + "\n(" + this.get_f32("fuel_count") + " / " + this.get_f32("max_fuel") + ")", params);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("load_fuel"))
	{
		CMap@ map = this.getMap();
		CBlob@[] oil;
		map.getBlobsInRadius(this.getPosition(), 5.0f, oil);

		for (int i = 0; i < oil.length; i++)
		{
			if (oil[i] !is null && oil[i].isAttached())
			{
				int add = oil[i].getQuantity() * 10;

				u32 amount = oil[i].getQuantity();
				f32 fuel = this.get_f32("fuel_count");
				f32 max_fuel = this.get_f32("max_fuel");
				s32 fuel_consumed = (s32(max_fuel) - s32(this.get_f32("fuel_count"))) / 15;
				f32 remain = Maths::Max(0, s32(amount) - fuel_consumed);

				this.set_f32("fuel_count", this.get_f32("fuel_count") + add);

				oil[i].Tag("dead");
				oil[i].server_Die();
			}
		}
	}
}

void onDie(CBlob@ this)
{
	f32 fuel = this.get_f32("fuel_count");
	Vec2f pos = this.getPosition();

	if (isServer())
	{
		CBlob@ returnoil = server_CreateBlob("mat_oil", -1, pos);
		returnoil.server_SetQuantity(fuel / 15);
		returnoil.setVelocity(Vec2f(0, 0));
	}
}