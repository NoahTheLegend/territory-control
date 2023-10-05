// Flesh hit

#include "Hitters.as";
#include "HittersTC.as";

void onInit(CBlob@ this)
{
	this.Tag("flesh");
}

f32 getGibHealth(CBlob@ this)
{
	if (this.exists("gib health"))
	{
		return this.get_f32("gib health");
	}

	return 0.0f;
}

void onTick(CBlob@ this)
{
	if (!this.isAttached() && getGameTime() % 300 == 0 && !this.hasTag("no_invincible_removal")) this.Untag("invincible");
	if (isServer() && getGameTime()%15==0 && this.getName() != "hazmat" && this.getName() != "exosuit")
	{
		if (this.hasTag("combat chicken")) return;
		CBlob@ b = getBlobByName("info_dead");
		
		if (isServer() && b !is null)
		{
			CBlob@ r = getBlobByName("rain");
			if (r !is null)
			{
				if (r.hasTag("acidic rain") && XORRandom(15)==0)
				{
					if (getMap() !is null && !getMap().rayCastSolidNoBlobs(Vec2f(this.getPosition().x, 0), this.getPosition()))
						this.server_Hit(this, this.getPosition(), Vec2f(0, 0), 0.125f, Hitters::burn);
				}
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 dmg = damage;

	switch (customData)
	{
		// TC		
		case HittersTC::bullet_low_cal:
		case HittersTC::bullet_high_cal:
		case HittersTC::shotgun:
			dmg *= 1.00f;
			break;
			
		case HittersTC::radiation:
			// dmg = Maths::Max((dmg * 2.00f) * (this.get_u8("radpilled") * 0.10f), 0);
			dmg *= Maths::Floor(2.00f / (1.00f + this.get_u8("radpilled") * 0.25f));
			break;
		// Vanilla
		case Hitters::builder:
			dmg *= 1.75f;
			break;

		case Hitters::spikes:
		case Hitters::sword:
		case Hitters::arrow:
		case Hitters::stab:
			dmg *= 1.25f;
			break;

		case Hitters::drill:
		case Hitters::bomb_arrow:
		case Hitters::bomb:
			dmg *= 1.50f;
			break;

		case Hitters::keg:
		case Hitters::explosion:
		case Hitters::crush:
			dmg *= 2.00f;
			break;

		case Hitters::cata_stones:
		case Hitters::flying: // boat ram
			dmg *= 4.00f;
			break;
		
		case Hitters::fire:
			dmg *= 2.75f;
			break;

		case Hitters::burn:
			dmg *= 2.50f;
			break;

	}

	if (isServer())
	{
		if (customData == HittersTC::radiation)
		{
			if (this.hasTag("human") && !this.hasTag("transformed") && this.getHealth() <= 0.125f && XORRandom(2) == 0)
			{
				CBlob@ man = server_CreateBlob("mithrilman", this.getTeamNum(), this.getPosition());
				if (this.getPlayer() !is null) man.server_SetPlayer(this.getPlayer());
				this.Tag("transformed");
				this.server_Die();
			}
		}
	}
	
	if (this.hasTag("equipment support"))
	{
		bool isBullet = (
			customData == HittersTC::bullet_low_cal || customData == HittersTC::bullet_high_cal || 
			customData == HittersTC::shotgun || customData == HittersTC::railgun_lance);
		
		string headname = this.get_string("equipment_head");
		string torsoname = this.get_string("equipment_torso");
		string torso2name = this.get_string("equipment2_torso");
		string bootsname = this.get_string("equipment_boots");
		
		if (headname != "" && this.exists(headname+"_health"))
		{
			//print("head '"+headname+"'");
			f32 armorMaxHealth = 100.0f;
			f32 ratio = 0.0f;

			if (headname == "militaryhelmet" || headname == "nvd") armorMaxHealth = 80.0f;
			else if (headname == "carbonhelmet") armorMaxHealth = 190.0f;
			else if (headname == "wilmethelmet") armorMaxHealth = 120.0f;
			else if (headname == "scubagear") armorMaxHealth = 10.0f;
			else if (headname == "bucket") armorMaxHealth = 10.0f;
			else if (headname == "pumpkin") armorMaxHealth = 5.0f;
			else if (headname == "minershelmet") armorMaxHealth = 10.0f;

			if ((headname == "militaryhelmet" || headname == "nvd") && customData != HittersTC::radiation)
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
						ratio = 0.75f;
						break;

					case HittersTC::bullet_high_cal:
					case HittersTC::railgun_lance:
						ratio = 0.6f;
						break;

					default:
						ratio = 0.20f;
						break;
				}
			}
			else if (headname == "stahlhelm" && customData != HittersTC::radiation)
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
						ratio = 0.8f;
						break;

					case HittersTC::bullet_high_cal:
					case HittersTC::railgun_lance:
						ratio = 0.7f;
						break;

					default:
						ratio = 0.1f;
						break;
				}
			}
			else if ((headname == "carbonhelmet") && customData != HittersTC::radiation)
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
					case Hitters::explosion:
					case Hitters::sword:
					case Hitters::keg:
					case Hitters::mine:
					case Hitters::mine_special:
					case Hitters::bomb:
						ratio = 0.8f;
						break;

					case HittersTC::bullet_high_cal:
					case HittersTC::railgun_lance:
						ratio = 0.45f;
						break;

					default:
						ratio = 0.15f;
						break;
				}
			}
			else if ((headname == "wilmethelmet"))
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
					case HittersTC::bullet_high_cal:
						ratio = 0.65f;
						break;

					case HittersTC::railgun_lance:
					case HittersTC::plasma:
					case HittersTC::electric:
						ratio = 0.85f;
						break;

					case Hitters::explosion:
						ratio = 0.35f;
						break;

					default:
						ratio = 0.15f;
						break;
				}
			}
			else if (headname == "scubagear" || headname == "bucket" || headname == "pumpkin" || headname == "minershelmet")
					ratio = 0.20f;
			
			if (headname != "stahlhelm") {
				f32 armorHealth = armorMaxHealth - this.get_f32(headname+"_health");
				if (armorHealth < armorMaxHealth/3.5f) armorHealth = armorMaxHealth/3.5f;
				ratio *= armorHealth / armorMaxHealth;
	
				this.add_f32(headname+"_health", (ratio*dmg)/2);
			}
			
			f32 playerDamage = Maths::Clamp((1.00f - ratio) * dmg, 0, dmg);
			dmg = playerDamage;
		}
		if (torsoname != "" && this.exists(torsoname+"_health"))
		{
			f32 armorMaxHealth = 100.0f;
			f32 ratio = 0.0f;

			if (torsoname == "bulletproofvest") armorMaxHealth = 100.0f;
			else if (torsoname == "carbonvest") armorMaxHealth = 200.0f;
			else if (torsoname == "wilmetvest") armorMaxHealth = 146.0f;
			else if (torsoname == "keg") armorMaxHealth = 10.0f;

			if (torsoname == "bulletproofvest" && customData != HittersTC::radiation)
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
						ratio = 0.75f;
						break;

					case HittersTC::bullet_high_cal:
					case HittersTC::railgun_lance:
						ratio = 0.6f;
						break;

					default:
						ratio = 0.35f;
						break;
				}
			}
			else if (torsoname == "carbonvest" && customData != HittersTC::radiation)
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
					case Hitters::explosion:
					case Hitters::sword:
					case Hitters::keg:
					case Hitters::mine:
					case Hitters::mine_special:
					case Hitters::bomb:
					case Hitters::arrow:
						ratio = 0.8f;
						break;

					case HittersTC::bullet_high_cal:
					case HittersTC::railgun_lance:
						ratio = 0.45f;
						break;

					default:
						ratio = 0.15f;
						break;
				}
			}
			else if (torsoname == "wilmetvest")
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
					case HittersTC::bullet_high_cal:
					case Hitters::sword:
					case Hitters::keg:
					case Hitters::mine:
					case Hitters::mine_special:
					case Hitters::bomb:
					case Hitters::arrow:
						ratio = 0.65f;
						break;

					case HittersTC::railgun_lance:
					case HittersTC::plasma:
					case HittersTC::electric:
					case HittersTC::radiation:
						ratio = 0.85f;
						break;

					case Hitters::explosion:
						ratio = 0.35f;
						break;

					default:
						ratio = 0.35f;
						break;
				}
			}
			else if (torsoname == "keg" && !isBullet && customData != HittersTC::radiation)
			{
				if ((customData == Hitters::fire || customData == Hitters::burn || customData == Hitters::explosion || 
					customData == Hitters::bomb || customData == Hitters::bomb_arrow) && this.get_f32("keg_explode") == 0.0f)
				{
					this.set_f32("keg_explode", getGameTime() + (30.0f * 1.0f));
					this.SetLightRadius(this.get_f32("explosive_radius") * 0.5f);
					this.getSprite().PlaySound("/Sparkle.ogg", 1.00f, 1.00f);
					this.getSprite().PlaySound("MigrantScream1.ogg", 1.00f, this.getSexNum() == 0 ? 1.0f : 2.0f);
					ratio = 1.0f;
				}
				else ratio = 0.45f;
			}
			f32 armorHealth = armorMaxHealth - this.get_f32(torsoname+"_health");
			if (armorHealth < armorMaxHealth/3.5f) armorHealth = armorMaxHealth/3.5f;
			ratio *= armorHealth / armorMaxHealth;

			this.add_f32(torsoname+"_health", (ratio*dmg)/2);
			f32 playerDamage = Maths::Clamp((1.00f - ratio) * dmg, 0, dmg);
			dmg = playerDamage;
		}

		if (torso2name != "" && this.exists(torso2name+"_health"))
		{
			f32 armorMaxHealth = 100.0f;
			f32 ratio = 0.0f;

			if (torso2name == "bulletproofvest") armorMaxHealth = 100.0f;
			else if (torso2name == "carbonvest") armorMaxHealth = 200.0f;
			else if (torso2name == "wilmetvest") armorMaxHealth = 146.0f;
			else if (torso2name == "keg") armorMaxHealth = 10.0f;

			if (torso2name == "bulletproofvest" && customData != HittersTC::radiation)
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
						ratio = 0.75f;
						break;

					case HittersTC::bullet_high_cal:
					case HittersTC::railgun_lance:
						ratio = 0.6f;
						break;

					default:
						ratio = 0.35f;
						break;
				}
			}
			else if (torso2name == "carbonvest" && customData != HittersTC::radiation)
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
					case Hitters::explosion:
					case Hitters::sword:
					case Hitters::keg:
					case Hitters::mine:
					case Hitters::mine_special:
					case Hitters::bomb:
					case Hitters::arrow:
						ratio = 0.8f;

					case HittersTC::bullet_high_cal:
					case HittersTC::railgun_lance:
						ratio = 0.45f;
						break;

					default:
						ratio = 0.15f;
						break;
				}
			}
			else if (torso2name == "wilmetvest")
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
					case HittersTC::bullet_high_cal:
					case Hitters::sword:
					case Hitters::keg:
					case Hitters::mine:
					case Hitters::mine_special:
					case Hitters::bomb:
					case Hitters::arrow:
						ratio = 0.65f;
						break;

					case HittersTC::railgun_lance:
					case HittersTC::plasma:
					case HittersTC::electric:
					case HittersTC::radiation:
						ratio = 0.85f;
						break;

					case Hitters::explosion:
						ratio = 0.35f;
						break;

					default:
						ratio = 0.35f;
						break;
				}
			}
			else if (torso2name == "keg" && !isBullet && customData != HittersTC::radiation)
			{
				if ((customData == Hitters::fire || customData == Hitters::burn || customData == Hitters::explosion || 
					customData == Hitters::bomb || customData == Hitters::bomb_arrow) && this.get_f32("keg_explode") == 0.0f)
				{
					this.set_f32("keg_explode", getGameTime() + (30.0f * 1.0f));
					this.SetLightRadius(this.get_f32("explosive_radius") * 0.5f);
					this.getSprite().PlaySound("/Sparkle.ogg", 1.00f, 1.00f);
					this.getSprite().PlaySound("MigrantScream1.ogg", 1.00f, this.getSexNum() == 0 ? 1.0f : 2.0f);
					ratio = 1.0f;
				}
				else ratio = 0.45f;
			}
			f32 armorHealth = armorMaxHealth - this.get_f32(torso2name+"_health");
			if (armorHealth < armorMaxHealth/3.5f) armorHealth = armorMaxHealth/3.5f;
			ratio *= armorHealth / armorMaxHealth;

			this.add_f32(torso2name+"_health", (ratio*dmg)/2);
			f32 playerDamage = Maths::Clamp((1.00f - ratio) * dmg, 0, dmg);
			dmg = playerDamage;
		}

		if (bootsname != "" && this.exists(bootsname+"_health"))
		{
			f32 armorMaxHealth = 48.0f;
			f32 ratio = 0.0f;
			if (bootsname == "combatboots") armorMaxHealth = 48.0f;
			else if (bootsname == "carbonboots") armorMaxHealth = 98.0f;
			else if (bootsname == "wilmetboots") armorMaxHealth =  85.0f;
			if (bootsname == "combatboots" && customData != HittersTC::radiation)
			{
				switch (customData)
				{
					case Hitters::fall:
					case Hitters::explosion:
						ratio = 0.30f;
						break;

					default: ratio = 0.15f;
						break;
				}
			}
			else if (bootsname == "carbonboots" && customData != HittersTC::radiation)
			{
				switch (customData)
				{
					case Hitters::explosion:
						ratio = 0.5f;
						break;

					default: ratio = 0.1f;
						break;
				}
			}
			else if (bootsname == "wilmetboots")
			{
				switch (customData)
				{
					case Hitters::fall:
					case HittersTC::radiation:
						ratio = 0.99f;
						break;

					default: ratio = 0.15f;
						break;
				}
			}

			f32 armorHealth = armorMaxHealth - this.get_f32(bootsname+"_health");
			if (armorHealth < armorMaxHealth/3.5f) armorHealth = armorMaxHealth/3.5f;
			ratio *= armorHealth / armorMaxHealth;

			this.add_f32(bootsname+"_health", (ratio*dmg)/2);
			f32 playerDamage = Maths::Clamp((1.00f - ratio) * dmg, 0, dmg);
			dmg = playerDamage;
		}
	}
	
	// if (this.get_f32("crak_effect") > 0) dmg *= 0.30f;
	
	this.Damage(dmg, hitterBlob);

	f32 gibHealth = getGibHealth(this);

	if (this.getHealth() <= gibHealth)
	{
		this.getSprite().Gib();
		this.Tag("do gib");
		
		this.server_Die();
	}

	return 0.0f; //done, we've used all the damage
}

void onDie(CBlob@ this)
{
	if (this.hasTag("do gib"))
	{
		f32 count = 2 + XORRandom(4);
		int frac = Maths::Min(250, this.getMass() / count) * 0.50f;
		f32 radius = this.getRadius();
		
		f32 explodium_amount = this.get_f32("propeskoed") * 0.50f / count;
		
		for (int i = 0; i < count; i++)
		{
			if (isClient())
			{
				this.getSprite().PlaySound("Pigger_Gore.ogg", 0.3f, 0.9f);
				ParticleBloodSplat(this.getPosition() + getRandomVelocity(0, radius, 360), true);
			}
		
			if (isServer())
			{
				Vec2f vel = Vec2f(XORRandom(4) - 2, -2 - XORRandom(4));
				
				if (explodium_amount > 0.00f)
				{
					CBlob@ blob = server_CreateBlob("mat_dangerousmeat", this.getTeamNum(), this.getPosition());
					blob.server_SetQuantity(1 + (frac * 0.60f + XORRandom(frac)));
					//blob.setVelocity(vel);
				}
				else
				{
					CBlob@ blob = server_CreateBlob("mat_meat", this.getTeamNum(), this.getPosition());

					if (blob !is null)
					{
					//if (explodium_amount > 0.00f) blob.set_f32("explodium_amount", explodium_amount);

					// print("" + explodium_amount);
				
					blob.server_SetQuantity(1 + (frac * 0.25f + XORRandom(frac)));
					if (this.hasTag("badger"))
						blob.server_SetQuantity(blob.getQuantity() * 0.25);
						
					blob.setVelocity(vel);
					}
				}
			}
		}
	}
}
