#include "Hitters.as";
#include "HittersTC.as";
#include "MakeMat.as";
#include "MaterialCommon.as";
#include "Explosion.as";
#include "Logging.as";

// A script by TFlippy

void onInit(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("DrugLab_Loop.ogg");
		sprite.SetEmitSoundVolume(0.25f);
		sprite.SetEmitSoundSpeed(1.0f);
		sprite.SetEmitSoundPaused(false);
	}

	this.inventoryButtonPos = Vec2f(7, 13);

	this.Tag("builder always hit");
	this.Tag("extractable");

	this.getCurrentScript().tickFrequency = 10;
	this.getSprite().SetZ(-10.0f);

	this.set_f32("pressure", 0.00f);
	this.set_f32("pressure_max", 150000.00f);
	this.set_string("inventory_name", "Chemical Laboratory");
	this.set_Vec2f("disable_button_offset", Vec2f(3.5,-2));

	if (this.hasTag("upgraded"))
		this.set_f32("upgrade", this.get_f32("upgrade"));
	else
		this.set_f32("upgrade", 0.00f);

	u16 synclevel = 0;
	if (isServer() && this.get_u16("level") > 1)
		synclevel = this.get_u16("level");

	this.set_u16("level", 1);
	if (synclevel > 1)
		this.set_u16("level", synclevel);

	this.addCommandID("lab_react");
	this.addCommandID("lab_add_heat");
	this.addCommandID("upgrade");

	this.set_u32("next_react", getGameTime());

	this.addCommandID("initsync_pressure");
	this.addCommandID("sync_pressure");
	if (isClient())
	{
		CBitStream params;
		this.SendCommand(this.getCommandID("initsync_pressure"), params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("initsync_pressure"))
	{
		if (isServer())
		{
			CBitStream params1;
			params1.write_f32(this.get_f32("pressure"));
			params1.write_f32(this.get_f32("pressure_max"));
			params1.write_f32(this.get_f32("upgrade"));
			params1.write_u16(this.get_u16("level"));

			this.SendCommand(this.getCommandID("sync_pressure"), params1);
		}
	}
	else if (cmd == this.getCommandID("sync_pressure"))
	{
		if (isClient())
		{
			f32 pressure; f32 maxpressure; f32 upgrade; u16 level;
			if (!params.saferead_f32(pressure)) return;
			if (!params.saferead_f32(maxpressure)) return;
			if (!params.saferead_f32(upgrade)) return;
			if (!params.saferead_u16(level)) return;

			this.set_f32("pressure", pressure);
			this.set_f32("pressure_max", maxpressure);
			this.set_f32("upgrade", upgrade);
			this.set_u16("level", level);
		}
	}
	else if (cmd == this.getCommandID("lab_react"))
	{
		React(this);
	}
	else if (cmd == this.getCommandID("lab_add_heat"))
	{
		this.add_f32("heat", 100);

		CInventory@ inv = this.getInventory();
		if (inv !is null)
		{
			const f32 mithril_count = inv.getCount("mat_mithril");
			const f32 e_mithril_count = inv.getCount("mat_mithrilenriched");
			const f32 methane_count = inv.getCount("mat_methane");
			const f32 fuel_count = inv.getCount("mat_fuel");
			const f32 acid_count = inv.getCount("mat_acid");
			const f32 mustard_count = inv.getCount("mat_mustard");
			const f32 heat = this.get_f32("heat") + Maths::Pow((mithril_count * 3.00f) + (e_mithril_count * 15.00f), 2) / 20000.00f;
			const f32 pressure = Maths::Pow(1000 + (methane_count * 75) + (fuel_count * 100) + (acid_count * 75) + (mustard_count * 25), Maths::Max(1, 1.00f + (heat * 0.0002f)));

			//print_log(this, "Heat; P: " + pressure + "; H: " + heat);
		}
	}
	else if (cmd == this.getCommandID("upgrade"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			CBlob@ carried = caller.getCarriedBlob();
			u16 level = this.get_u16("level");
			if (carried !is null && carried.getName() == "mat_copperingot")
			{
				if (carried.getQuantity() >= 10 * level)
				{
					
					int remain = carried.getQuantity() - 10 * level;
					if (remain > 0)
					{
						carried.server_SetQuantity(remain);
					}
					else
					{
						carried.Tag("dead");
						carried.server_Die();
					}
					this.add_f32("upgrade", 20000.00f);
					this.Tag("upgraded");
					if (level < 30) this.set_u16("level", level+1);
				}
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (this.isOverlapping(caller))
	{
		CBitStream params;

		{
			CButton@ button = caller.CreateGenericButton(11, Vec2f(-4, -2), this, this.getCommandID("lab_react"), "React", params);
			button.SetEnabled(getGameTime() >= this.get_u32("next_react"));
		}
		{
			CButton@ button = caller.CreateGenericButton(11, Vec2f(-4, 6.5f), this, this.getCommandID("lab_add_heat"), "Increase Heat", params);
			button.deleteAfterClick = false;
		}
		{
			CBlob@ carried = caller.getCarriedBlob();

			if (carried != null && carried.getName() == "mat_copperingot")
			{
				CBitStream params;
				params.write_u16(caller.getNetworkID());
				CButton@ button = caller.CreateGenericButton(23, Vec2f(3, -2), this, this.getCommandID("upgrade"), "Upgrade Druglab for "+(10*this.get_u16("level"))+" Copper Ingots", params);
				button.deleteAfterClick = false;
			}
		}
	}
}


void React(CBlob@ this)
{
	if (getGameTime() >= this.get_u32("next_react"))
	{
		CInventory@ inv = this.getInventory();
		if (inv !is null)
		{
			const f32 heat = this.get_f32("heat") + Maths::Pow((getCount(this, "mat_mithril") * 3.00f) + (getCount(this, "mat_mithrilenriched") * 15.00f), 2) / 20000.00f;
			const f32 pressure = Maths::Pow(1000 + (getCount(this, "mat_methane") * 75) + (getCount(this, "mat_fuel") * 100) + (getCount(this, "mat_acid") * 75) + (getCount(this, "mat_mustard") * 25), Maths::Max(1, 1.00f + (heat * 0.0002f)));

			//print_log(this, "React; P: " + pressure + "; H: " + heat);

			CBlob@ oil_blob = inv.getItem("mat_oil");
			CBlob@ methane_blob = inv.getItem("mat_methane");
			CBlob@ acid_blob = inv.getItem("mat_acid");
			CBlob@ fuel_blob = inv.getItem("mat_fuel");
			CBlob@ mustard_blob = inv.getItem("mat_mustard");
			CBlob@ meat_blob = inv.getItem("mat_meat");
			CBlob@ dangermeat_blob = inv.getItem("mat_dangerousmeat");
			CBlob@ mithril_blob = inv.getItem("mat_mithril");
			CBlob@ sulphur_blob = inv.getItem("mat_sulphur");
			CBlob@ dirt_blob = inv.getItem("mat_dirt");
			CBlob@ e_mithril_blob = inv.getItem("mat_mithrilenriched");
			CBlob@ coal_blob = inv.getItem("mat_coal");
			CBlob@ steel_blob = inv.getItem("mat_steelingot");
			CBlob@ protopopov_blob = inv.getItem("mat_protopopov");
			CBlob@ protopopovBulb_blob = inv.getItem("protopopovbulb");
			CBlob@ vodka_blob = inv.getItem("vodka");
			CBlob@ fiks_blob = inv.getItem("fiks");
			CBlob@ domino_blob = inv.getItem("domino");
			CBlob@ stim_blob = inv.getItem("stim");
			CBlob@ love_blob = inv.getItem("love");
			CBlob@ grain_blob = inv.getItem("grain");
			CBlob@ rippio_blob = inv.getItem("rippio");
			CBlob@ rippiogas_blob = inv.getItem("mat_rippio");
			CBlob@ ganja_blob = inv.getItem("mat_ganja");
			CBlob@ ganjapod_blob = inv.getItem("ganjapod");
			CBlob@ steroid_blob = inv.getItem("steroid");
			CBlob@ pumpkin_blob = inv.getItem("pumpkin");
			CBlob@ mat_boof = inv.getItem("mat_boof");

			bool hasOil = oil_blob !is null;
			bool hasMethane = methane_blob !is null;
			bool hasFuel = fuel_blob !is null;
			bool hasAcid = acid_blob !is null;
			bool hasMithrilEnriched = e_mithril_blob !is null;
			bool hasMeat = meat_blob !is null;
			bool hasDangerMeat = dangermeat_blob !is null;
			bool hasDirt = dirt_blob !is null;
			bool hasSulphur = sulphur_blob !is null;
			bool hasMustard = mustard_blob !is null;
			bool hasMithril = mithril_blob !is null;
			bool hasCoal = coal_blob !is null;
			bool hasSteel = steel_blob !is null;
			bool hasProtopopov = protopopov_blob !is null;
			bool hasProtopopovBulb = protopopovBulb_blob !is null;
			bool hasVodka = vodka_blob !is null;
			bool hasFiks = fiks_blob !is null;
			bool hasDomino = domino_blob !is null;
			bool hasStim = stim_blob !is null;
			bool hasLove = love_blob !is null;
			bool hasGrain = grain_blob !is null;
			bool hasRippio = rippio_blob !is null;
			bool hasRippioGas = rippiogas_blob !is null;
			bool hasGanja = ganja_blob !is null;
			bool hasGanjaPod = ganjapod_blob !is null;
			bool hasSteroid = steroid_blob !is null;
			bool hasPumpkin = pumpkin_blob !is null;
			bool hasBoof = mat_boof !is null;
			// Boof Gas Recipe
			if (pressure > 1000 && heat > 700 && hasGanjaPod)
			{
				if (isServer())
				{
					ganjapod_blob.server_Die();

					Material::createFor(this, "mat_boof", 10 + XORRandom(5));
					Material::createFor(this, "boof", 1);
				}

				ShakeScreen(20.0f, 30, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Gas.ogg", 1.00f, 1.00f);
			}
			// Boof Recipe
			if (pressure > 1000 && heat < 500 && hasGanja && hasDirt && getCount(this, "mat_ganja") >= 20 && getCount(this, "mat_dirt") >= 20)
			{
				if (isServer())
				{
					ganja_blob.server_SetQuantity(Maths::Max(ganja_blob.getQuantity() - 20, 0));
					dirt_blob.server_SetQuantity(Maths::Max(dirt_blob.getQuantity() - 20, 0));

					Material::createFor(this, "boof", 1 + XORRandom(2));
				}

				ShakeScreen(20.0f, 30, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Creamy.ogg", 1.00f, 1.00f);
			}
			// Gooby Recipe
			if (pressure > 25000 && heat > 1000 && hasRippio && hasFiks && hasDangerMeat && getCount(this, "mat_dangerousmeat") >= 45)
			{
				if (isServer())
				{
					rippio_blob.server_Die();
					fiks_blob.server_Die();
					dangermeat_blob.server_SetQuantity(Maths::Max(dangermeat_blob.getQuantity() - 45, 0));

					Material::createFor(this, "goobypill", 2 + XORRandom(2));
					if (XORRandom(100) < 33) Material::createFor(this, "gooby", 1 + XORRandom(2));
				}

				ShakeScreen(20.0f, 30, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Solid.ogg", 1.00f, 1.00f);
			}

			if (heat < 300 && hasDangerMeat && getCount(this, "mat_dangerousmeat") >= 15)
			{
				if (isServer())
				{
					dangermeat_blob.server_SetQuantity(Maths::Max(dangermeat_blob.getQuantity() - 15, 0));
					Material::createFor(this, "mat_explodium", 1 + XORRandom(2));
					Material::createFor(this, "mat_meat", 9 + XORRandom(5));
				}

				ShakeScreen(40.0f, 30, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Gas.ogg", 1.00f, 1.00f);
			}

			if (heat > 1000 && hasGrain)
			{
				if (isServer())
				{
					if (grain_blob.getQuantity() <= 2) grain_blob.server_Die();
					else grain_blob.server_SetQuantity(Maths::Max(grain_blob.getQuantity() - 2, 0));
					Material::createFor(this, "vodka", 1+XORRandom(2));
				}

				ShakeScreen(30.0f, 15, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Acidic.ogg", 1.00f, 1.00f);
			}

			if (heat < 500 && pressure > 5000 && hasPumpkin)
			{
				if (isServer())
				{
					if (pumpkin_blob.getQuantity() == 1) pumpkin_blob.server_Die();
					else pumpkin_blob.server_SetQuantity(Maths::Max(pumpkin_blob.getQuantity() - 1, 0));
					Material::createFor(this, "cider", 1);
				}

				ShakeScreen(30.0f, 15, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Acidic.ogg", 1.00f, 1.00f);
			}

			if (pressure < 5000 && heat > 500  && hasFiks)
			{
				if (isServer())
				{
					if (XORRandom(100) < 30)
					{
						fiks_blob.server_Die();
						Material::createFor(this, "crak", 1);
					}
					else
					{
						Material::createFor(this, "mat_coal", 3 + XORRandom(10));
					}
				}

				ShakeScreen(60.0f, 15, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Solid.ogg", 1.00f, 1.00f);
			}

			if (pressure > 50000 && heat > 1500 && hasFuel && hasCoal && hasVodka && getCount(this, "mat_fuel") >= 50 && getCount(this, "mat_coal") >= 50)
			{
				if (isServer())
				{
					fuel_blob.server_SetQuantity(Maths::Max(fuel_blob.getQuantity() - 50, 0));
					coal_blob.server_SetQuantity(Maths::Max(coal_blob.getQuantity() - 50, 0));
					vodka_blob.server_Die();

					Material::createFor(this, "sosek", 2 + XORRandom(3));
				}

				ShakeScreen(20.0f, 30, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Solid.ogg", 1.00f, 1.00f);
			}

			if (pressure > 100000 && heat > 500 && hasFuel && hasAcid && hasCoal && getCount(this, "mat_fuel") >= 50 && getCount(this, "mat_acid") >= 50 && getCount(this, "mat_coal") >= 50)
			{
				if (isServer())
				{
					fuel_blob.server_SetQuantity(Maths::Max(fuel_blob.getQuantity() - 50, 0));
					acid_blob.server_SetQuantity(Maths::Max(acid_blob.getQuantity() - 50, 0));
					coal_blob.server_SetQuantity(Maths::Max(coal_blob.getQuantity() - 50, 0));

					Material::createFor(this, "fumes", 2 + XORRandom(5));
				}

				ShakeScreen(20.0f, 30, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Solid.ogg", 1.00f, 1.00f);
			}

			if (pressure > 10000 && heat < 500 && hasProtopopov && hasAcid && hasMithril && getCount(this, "mat_protopopov") >= 50 && getCount(this, "mat_acid") >= 50 && getCount(this, "mat_mithril") >= 25)
			{
				if (isServer())
				{
					protopopov_blob.server_SetQuantity(Maths::Max(protopopov_blob.getQuantity() - 50, 0));
					acid_blob.server_SetQuantity(Maths::Max(acid_blob.getQuantity() - 50, 0));
					mithril_blob.server_SetQuantity(Maths::Max(mithril_blob.getQuantity() - 25, 0));

					Material::createFor(this, "dew", 2 + XORRandom(4));
				}

				ShakeScreen(20.0f, 30, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Acidic.ogg", 1.00f, 1.00f);
			}

			if (heat > 1400 && hasProtopopovBulb)
			{
				if (isServer())
				{
					protopopovBulb_blob.server_Die();

					Material::createFor(this, "mat_acid", 50 + XORRandom(75));
					Material::createFor(this, "mat_oil", 25 + XORRandom(100));

					if (XORRandom(100) < 30)
					{
						Material::createFor(this, "fuskpill", 1 + XORRandom(2));
					}
				}

				ShakeScreen(60.0f, 15, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Solid.ogg", 1.00f, 1.00f);
			}

			if (pressure > 40000 && heat > 750 && hasOil && hasMethane)
			{
				f32 count = Maths::Min(Maths::Min(getCount(this, "mat_methane"), getCount(this, "mat_oil")), pressure * 0.0002f);

				if (isServer())
				{
					oil_blob.server_SetQuantity(Maths::Max(oil_blob.getQuantity() - count, 0));
					methane_blob.server_SetQuantity(Maths::Max(methane_blob.getQuantity() - count, 0));
					Material::createFor(this, "mat_fuel", count * 1.50f);
				}

				ShakeScreen(60.0f, 30, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Gas.ogg", 1.00f, 1.00f);
			}

			if (pressure > 70000 && heat > 1300 && hasCoal && !hasSteel)
			{
				f32 count = Maths::Min(getCount(this, "mat_coal"), pressure * 0.0002f);
				//print("coal");

				if (isServer())
				{
					coal_blob.server_SetQuantity(Maths::Max(coal_blob.getQuantity() - count, 0));
					Material::createFor(this, "mat_oil", count * 1.75f);
				}

				ShakeScreen(20.0f, 15, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Viscous.ogg", 1.00f, 1.00f);
			}

			if (pressure >= 100000 && heat > 1000 && hasCoal && getCount(this, "mat_steelingot") >= 6)
			{
				f32 count = Maths::Min(getCount(this, "mat_coal"), pressure * 0.0002f);
				//print("coal");

				if (isServer())
				{
					steel_blob.server_SetQuantity(Maths::Max(steel_blob.getQuantity() - 6, 0));
					coal_blob.server_SetQuantity(Maths::Max(coal_blob.getQuantity() - count, 0));
					Material::createFor(this, "mat_carbon", count * 1.75f);
				}

				ShakeScreen(10.0f, 15, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Viscous.ogg", 1.50f, 1.00f);
			}

			if (pressure > 20000 && heat > 300 && hasMustard && hasFuel)
			{
				f32 count = Maths::Min(Maths::Min(getCount(this, "mat_mustard"), getCount(this, "mat_fuel")), pressure * 0.00015f);

				if (isServer())
				{
					mustard_blob.server_SetQuantity(Maths::Max(mustard_blob.getQuantity() - count, 0));
					fuel_blob.server_SetQuantity(Maths::Max(fuel_blob.getQuantity() - count, 0));
					Material::createFor(this, "mat_acid", count * 2.00f);
				}

				ShakeScreen(20.0f, 90, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Acidic.ogg", 1.00f, 1.00f);
			}

			if (pressure > 1000 && heat > 300 && hasMeat)
			{
				f32 count = Maths::Min(getCount(this, "mat_meat"), pressure * 0.001f);

				if (isServer())
				{
					meat_blob.server_SetQuantity(Maths::Max(meat_blob.getQuantity() - count * 0.25f, 0));
					Material::createFor(this, "mat_methane", count * 0.75f);
					Material::createFor(this, "mat_acid", count * 0.75f);
				}

				ShakeScreen(10.0f, 20, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Fart.ogg", 1.00f, 1.00f);
			}

			if (pressure > 10000 && pressure < 50000 && heat > 1000 && hasOil)
			{
				f32 count = Maths::Min(getCount(this, "mat_oil"), pressure * 0.0004f);

				if (isServer())
				{
					oil_blob.server_SetQuantity(Maths::Max(oil_blob.getQuantity() - count * 0.50f, 0));
					Material::createFor(this, "mat_fuel", count * 0.75f);
					Material::createFor(this, "mat_acid", count * 0.25f);
					Material::createFor(this, "mat_dirt", count * 0.50f);
				}

				ShakeScreen(10.0f, 10, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Viscous.ogg", 1.00f, 1.00f);
			}

			if (pressure > 25000 && heat > 1500 && hasMithril && hasAcid && getCount(this, "mat_mithril") >= 50 && getCount(this, "mat_acid") >= 25)
			{
				if (isServer())
				{
					mithril_blob.server_SetQuantity(Maths::Max(mithril_blob.getQuantity() - 50, 0));
					acid_blob.server_SetQuantity(Maths::Max(acid_blob.getQuantity() - 25, 0));
					Material::createFor(this, "domino", 3 + XORRandom(6));
					Material::createFor(this, "mat_mithrilenriched", XORRandom(10));
					Material::createFor(this, "mat_fuel", XORRandom(40));
				}

				ShakeScreen(20.0f, 15, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Solid.ogg", 1.00f, 1.00f);
			}

			if (pressure > 25000 && heat > 400 && hasSulphur && hasAcid && getCount(this, "mat_sulphur") >= 50 && getCount(this, "mat_acid") >= 25)
			{
				if (isServer())
				{
					sulphur_blob.server_SetQuantity(Maths::Max(sulphur_blob.getQuantity() - 50, 0));
					acid_blob.server_SetQuantity(Maths::Max(acid_blob.getQuantity() - 25, 0));
					Material::createFor(this, "stimpill", 4 + XORRandom(3));
					if (XORRandom(100) < 50) Material::createFor(this, "stim", 1 + XORRandom(2));
					Material::createFor(this, "mat_dirt", XORRandom(15));
					Material::createFor(this, "mat_mustard", 5 + XORRandom(15));
				}

				ShakeScreen(10.0f, 15, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Liquid.ogg", 1.00f, 1.00f);
			}

			if (pressure > 40000 && heat > 700 && hasAcid && hasMethane && hasMithrilEnriched && hasMeat && getCount(this, "mat_acid") > 25 && getCount(this, "mat_methane") >= 25 && getCount(this, "mat_mithrilenriched") >= 5 && getCount(this, "mat_meat") >= 10)
			{
				if (isServer())
				{
					acid_blob.server_SetQuantity(Maths::Max(acid_blob.getQuantity() - 25, 0));
					methane_blob.server_SetQuantity(Maths::Max(methane_blob.getQuantity() - 25, 0));
					e_mithril_blob.server_SetQuantity(Maths::Max(e_mithril_blob.getQuantity() - 5, 0));
					meat_blob.server_SetQuantity(Maths::Max(meat_blob.getQuantity() - 10, 0));

					Material::createFor(this, "poot", 1 + XORRandom(2));
					Material::createFor(this, "bobomax", XORRandom(2));
					Material::createFor(this, "mat_oil", XORRandom(25));
				}

				ShakeScreen(20.0f, 15, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Solid.ogg", 1.00f, 1.00f);
			}

			if (heat > 500 && hasDirt && hasMeat && hasAcid && getCount(this, "mat_dirt") >= 50 && getCount(this, "mat_meat") > 15 && getCount(this, "mat_acid") >= 25)
			{
				if (isServer())
				{
					dirt_blob.server_SetQuantity(Maths::Max(dirt_blob.getQuantity() - 50, 0));
					meat_blob.server_SetQuantity(Maths::Max(meat_blob.getQuantity() - 15, 0));
					acid_blob.server_SetQuantity(Maths::Max(acid_blob.getQuantity() - 25, 0));

					Material::createFor(this, "bobongo", 3 + XORRandom(5));
					Material::createFor(this, "mat_methane", XORRandom(50));

					if (XORRandom(100) < 5)
					{
						Material::createFor(this, "fuskpill", 2 + XORRandom(2));
						if (XORRandom(100) < 33) Material::createFor(this, "fusk", 1);
					}
				}

				ShakeScreen(20.0f, 15, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Creamy.ogg", 1.00f, 1.00f);
			}

			if (pressure < 50000 && heat > 100 && hasAcid && !hasMeat)
			{
				f32 count = Maths::Min(Maths::Min(getCount(this, "mat_acid") * 0.25f, getCount(this, "mat_acid")), pressure * 0.00025f);

				if (isServer())
				{
					acid_blob.server_SetQuantity(Maths::Max(acid_blob.getQuantity() - count * 0.25f, 0));
					Material::createFor(this, "mat_dirt", count * 3.00f);
				}

				ShakeScreen(20.0f, 30, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Acidic.ogg", 1.00f, 1.00f);
			}

			if (pressure > 20000 && heat > 1000 && heat < 2000 && hasAcid && hasOil && getCount(this, "mat_acid") >= 25 && getCount(this, "mat_oil") >= 20)
			{
				CBlob@ bobomax = inv.getItem("bobomax");
				if (bobomax !is null)
				{
					if (isServer())
					{
						acid_blob.server_SetQuantity(Maths::Max(acid_blob.getQuantity() - 25, 0));
						oil_blob.server_SetQuantity(Maths::Max(oil_blob.getQuantity() - 20, 0));
						bobomax.server_Die();

						Material::createFor(this, "foof", 3 + XORRandom(7));
					}

					ShakeScreen(60.0f, 15, this.getPosition());
					this.getSprite().PlaySound("DrugLab_Create_Solid.ogg", 1.00f, 1.00f);
				}
			}

			if (heat > 2250 && hasOil && getCount(this, "mat_oil") >= 25)
			{
				CBlob@ stim = inv.getItem("stim");
				if (stim !is null)
				{
					if (isServer())
					{
						oil_blob.server_SetQuantity(Maths::Max(oil_blob.getQuantity() - 25, 0));
						stim.server_Die();

						Material::createFor(this, "rippiopill", 2 + XORRandom(2));
						if (XORRandom(100) < 50) Material::createFor(this, "rippio", 1 + XORRandom(2));
						//Material::createFor(this, "mat_rippio", 15 + XORRandom(35));

						if (XORRandom(100) < 30)
						{
							Material::createFor(this, "love", 2);
						}
					}

					ShakeScreen(100.0f, 15, this.getPosition());
					this.getSprite().PlaySound("DrugLab_Create_Acidic.ogg", 1.00f, 1.00f);
				}
			}

			if (heat > 1000 && hasProtopopovBulb && hasRippioGas && getCount(this, "mat_rippio") >= 25)
			{
				if (isServer())
				{
					rippiogas_blob.server_SetQuantity(Maths::Max(rippiogas_blob.getQuantity() - 25, 0));
					protopopovBulb_blob.server_Die();
					Material::createFor(this, "mat_love", 15 + XORRandom(11));
					if (XORRandom(100) < 50)
					{
						Material::createFor(this, "love", XORRandom(2)+1);
					}
				}

				ShakeScreen(30.0f, 60, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Creamy.ogg", 1.1f, 0.8f);
			}

			if (pressure < 25000 && heat > 500 && heat < 2000 && hasAcid && hasMithril && getCount(this, "mat_acid") >= 15 && getCount(this, "mat_mithril") >= 5)
			{
				if (isServer())
				{
					acid_blob.server_SetQuantity(Maths::Max(acid_blob.getQuantity() - 15, 0));
					mithril_blob.server_SetQuantity(Maths::Max(mithril_blob.getQuantity() - 5, 0));

					Material::createFor(this, "fiks", 4 + XORRandom(4));
					Material::createFor(this, "domino", XORRandom(7));
				}

				ShakeScreen(30.0f, 60, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Solid.ogg", 1.00f, 1.00f);
			}

			if (pressure < 20000 && heat > 100 && heat < 500 && hasAcid && hasCoal && getCount(this, "mat_acid") >= 20 && getCount(this, "mat_coal") >= 15)
			{
				if (isServer())
				{
					acid_blob.server_SetQuantity(Maths::Max(acid_blob.getQuantity() - 20, 0));
					coal_blob.server_SetQuantity(Maths::Max(coal_blob.getQuantity() - 15, 0));

					Material::createFor(this, "babby", 2 + XORRandom(3));
				}

				ShakeScreen(10.0f, 10, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Solid.ogg", 1.00f, 1.00f);
			}

			if (pressure < 100000 && heat > 500 && hasAcid && hasCoal && hasSulphur && getCount(this, "mat_acid") >= 50 && getCount(this, "mat_sulphur") >= 250 && getCount(this, "mat_coal") >= 100)
			{
				if (isServer())
				{
					acid_blob.server_SetQuantity(Maths::Max(acid_blob.getQuantity() - 50, 0));
					sulphur_blob.server_SetQuantity(Maths::Max(sulphur_blob.getQuantity() - 250, 0));
					coal_blob.server_SetQuantity(Maths::Max(coal_blob.getQuantity() - 100, 0));

					Material::createFor(this, "propesko", 1 + XORRandom(2));
					if (XORRandom(100) < 10)
					{
						Material::createFor(this, "love", 2);
					}
				}

				ShakeScreen(60.0f, 90, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Creamy.ogg", 1.00f, 1.00f);
			}

			if (pressure > 40000 && heat > 2000 && hasOil && hasMithril && getCount(this, "mat_oil") >= 25 && getCount(this, "mat_mithril") >= 25)
			{
				if (isServer())
				{
					oil_blob.server_SetQuantity(Maths::Max(oil_blob.getQuantity() - 15, 0));
					mithril_blob.server_SetQuantity(Maths::Max(mithril_blob.getQuantity() - 5, 0));

					Material::createFor(this, "schisk", 2 + XORRandom(3));
					Material::createFor(this, "bobomax", 1 + XORRandom(3));
				}

				ShakeScreen(30.0f, 60, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Solid.ogg", 1.00f, 1.00f);
			}

			if (heat > 500 && hasOil && getCount(this, "mat_oil") >= 25 && hasVodka)
			{
				CBlob@ vodka = inv.getItem("vodka");
				if (vodka !is null)
				{
					if (isServer())
					{
						oil_blob.server_SetQuantity(Maths::Max(oil_blob.getQuantity() - 25, 0));
						vodka.server_Die();

						Material::createFor(this, "paxilonpill", 2 + XORRandom(2));
						//Material::createFor(this, "mat_paxilon", 15 + XORRandom(35));

						if (XORRandom(100) < 5)
						{
							Material::createFor(this, "fuskpill", 2 + XORRandom(2));
						}
					}

					ShakeScreen(100.0f, 15, this.getPosition());
					this.getSprite().PlaySound("DrugLab_Create_Acidic.ogg", 1.00f, 1.00f);
				}
			}

			if (pressure < 100000 && heat >= 500 && hasLove && hasMustard && getCount(this, "mat_mustard") >= 50)
			{
				if (isServer())
				{
					mustard_blob.server_SetQuantity(Maths::Max(mustard_blob.getQuantity() - 50, 0));
					love_blob.server_Die();

					Material::createFor(this, "mat_gae", 100 + XORRandom(50));
				}

				ShakeScreen(30.0f, 60, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Solid.ogg", 1.00f, 1.00f);
			}

			if (pressure < 50000 && heat >= 1200 && hasRippio && hasAcid && getCount(this, "mat_acid") >= 25)
			{
				if (isServer())
				{
					acid_blob.server_SetQuantity(Maths::Max(acid_blob.getQuantity() - 25, 0));
					rippio_blob.server_Die();

					Material::createFor(this, "love", 1 + XORRandom(1));
				}

				ShakeScreen(30.0f, 60, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Solid.ogg", 1.00f, 1.00f);
			}
			// Steroid recipe
			if (heat >= 2000 && hasFiks && hasDomino && hasStim)
			{
				if (isServer())
				{
					fiks_blob.server_Die();
					domino_blob.server_Die();
					stim_blob.server_Die();

					Material::createFor(this, "steroid", 1 + XORRandom(2));
				}

				ShakeScreen(30.0f, 60, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Solid.ogg", 1.00f, 1.00f);
			}
			// Sturd recipe
			if (heat >= 500 && hasFiks && hasPumpkin && getCount(this, "pumpkin") >= 2)
			{
				if (isServer())
				{
					fiks_blob.server_Die();
					pumpkin_blob.server_Die();

					Material::createFor(this, "sturd", 1 + (XORRandom(3) == 0 ? 1 : 0));
				}

				ShakeScreen(30.0f, 60, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Creamy.ogg", 1.00f, 1.00f);
			}
			// Polymorphine recipe
			if (heat <= 500 && hasMithrilEnriched && getCount(this, "mat_mithrilenriched") >= 10 && hasSteroid && getCount(this, "mat_boof") >= 25)
			{
				if (isServer())
				{
					steroid_blob.server_Die();
					mat_boof.server_SetQuantity(Maths::Max(mat_boof.getQuantity() - (25-XORRandom(11)), 0));
					e_mithril_blob.server_SetQuantity(Maths::Max(e_mithril_blob.getQuantity() - 10, 0));

					Material::createFor(this, "polymorphine", 1 + (XORRandom(4) == 0 ? 1 : 0));
					if (XORRandom(6) == 0)
					{
						Material::createFor(this, "mat_polymorphine", 10+XORRandom(11));
					}
				}

				ShakeScreen(30.0f, 60, this.getPosition());
				this.getSprite().PlaySound("DrugLab_Create_Acidic.ogg", 1.00f, 1.00f);
			}
		}
	}

	this.set_u32("next_react", getGameTime() + 15);
}

f32 getCount(CBlob@ this, string name)
{
	CInventory@ inv = this.getInventory();
	if (inv !is null)
	{
		return inv.getCount(name);
	}
	return 0;
}

void onRender(CSprite@ this)
{
	CBlob@ local = getLocalPlayerBlob();
	CBlob@ b = this.getBlob();
	if(local !is null && local.isMyPlayer() && getMap().getBlobAtPosition(getControls().getMouseWorldPos()) is b)
	{
		GUI::SetFont("MENU");
		GUI::DrawText(b.get_string("drawText"), b.getInterpolatedScreenPos() + Vec2f(16,-24), SColor(255,255,50,50).getInterpolated(SColor(255,50,255,50), b.get_f32("percentageToMax")));
	}
}

void onTick(CBlob@ this)
{
	if (this.hasTag("dead")) return;

	CInventory@ inv = this.getInventory();
	if (inv !is null)
	{
		const f32 mithril_count = inv.getCount("mat_mithril");
		const f32 e_mithril_count = inv.getCount("mat_mithrilenriched");
		const f32 fuel_count = inv.getCount("mat_fuel");
		const f32 acid_count = inv.getCount("mat_acid");
		const f32 methane_count = inv.getCount("mat_methane");
		const f32 mustard_count = inv.getCount("mat_mustard");
		bool hasRefrigerant = inv.getItem("refrigerant") !is null;
		bool hasCatalyzer = inv.getItem("catalyzer") !is null;

		f32 modifier = 1.00f;
		const f32 max_pressure = (hasCatalyzer?1.5f:1.0f)*this.get_f32("pressure_max") + this.get_f32("upgrade");

		const f32 heat = this.get_f32("heat") + (!hasRefrigerant ? Maths::Pow((mithril_count * 3.00f) + (e_mithril_count * 15.00f), 2) / 20000.00f : 0);
		const f32 pressure = Maths::Pow(1000 + (methane_count * 75) + (fuel_count * 100) + (acid_count * 75) + (mustard_count * 25), Maths::Max(1, 1.00f + (heat * 0.0002f)));
		
		//this.setInventoryName();
		this.set_string("drawText",this.get_string("inventory_name") + "\n\nPressure: " + Maths::Round(pressure) + " / " + max_pressure + "\nHeat: " + heat);
		this.set_f32("percentageToMax", pressure/max_pressure);
		if (isClient())
		{
			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
			{
				sprite.SetEmitSoundVolume(0.30f);
				sprite.SetEmitSoundSpeed(0.75f + pressure / 50000.00f);
			}
		}

		this.set_f32("pressure", pressure);
		this.set_f32("heat", Maths::Max(25, heat - 7));

		if (pressure > max_pressure)
		{
			this.Tag("dead");
			if (isServer())
			{
				print_log(this, "Exploding due to overheating; P: " + pressure + "; H: " + heat);
				for (int i = 0; i < 2; i++)
				{
					CBlob@ blob = server_CreateBlob("firegas", -1, this.getPosition());
				}
				Explode(this, Maths::Sqrt(this.get_f32("pressure") * 0.005f), this.get_f32("pressure") * 0.0001f);

				this.server_Die();
			}
		}
		else if (pressure > max_pressure * 0.50f)
		{
			const f32 rmod = (pressure - (max_pressure * 0.50f)) / (max_pressure * 0.50f);

			if (isClient())
			{
				ShakeScreen(20 * rmod, 100 * rmod, this.getPosition());
			}
		}
	}
}

// void onDie(CBlob@ this)
// {
// 	if (isServer())
// 	{
// 		for (int i = 0; i < 2; i++)
// 		{
// 			CBlob@ blob = server_CreateBlob("firegas", -1, this.getPosition());
// 			blob.server_SetTimeToDie(60 + XORRandom(60));
// 		}
// 	}

// 	Explode(this, Maths::Sqrt(this.get_f32("pressure") * 0.005f), this.get_f32("pressure") * 0.0001f);
// }

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return !this.getMap().rayCastSolid(forBlob.getPosition(), this.getPosition());
}
