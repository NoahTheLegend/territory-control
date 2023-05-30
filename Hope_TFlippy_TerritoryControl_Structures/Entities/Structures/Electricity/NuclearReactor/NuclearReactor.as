#include "Hitters.as";
#include "HittersTC.as";
#include "MakeMat.as";
#include "MaterialCommon.as";
#include "Explosion.as";

const u32 ELECTRICITY_MAX = 100000;
const u32 ELECTRICITY_PROD = 300;

const string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

void onInit(CBlob@ this)
{
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 30;

	this.Tag("no fuel hint");
	this.Tag("builder always hit");
	this.Tag("generator");
	this.Tag("extractable");

	this.set_u32("elec_max", ELECTRICITY_MAX);
	this.set_u16("consume_id", 0);
	this.set_Vec2f("wire_offset", Vec2f(0.5, 0));
	this.set_bool("locked", true);

	this.set_Vec2f("wire_offset", Vec2f(0, 12.0f));
	
	this.set_string("password", "");
	this.set_bool("sabotage", false);
	this.set_u32("sabotage_time", 0);
	this.set_bool("codebreaking", false);
	this.set_u32("codebreaking_time", 0);
	this.set_string("utility", "");

	AddIconToken("$icon0$", "Coins.png", Vec2f(16, 16), 5);
	AddIconToken("$icon1$", "ExtraIcons.png", Vec2f(12, 12), 0);
	AddIconToken("$icon2$", "ExtraIcons.png", Vec2f(12, 12), 1);
	AddIconToken("$icon3$", "ExtraIcons.png", Vec2f(12, 12), 2);

	this.set_u32("elec", 0);
	server_Sync(this);

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("MithrilReactor_Loop-Reverse_.ogg");
		sprite.SetEmitSoundVolume(0.25f);
		sprite.SetEmitSoundSpeed(0.85f);
		sprite.SetEmitSoundPaused(false);

		sprite.getConsts().accurateLighting = false;

		CSpriteLayer@ console = sprite.addSpriteLayer("console", "Console.png", 13, 21);
		if (console !is null)
		{
			console.SetOffset(Vec2f(18, 14));
			console.SetRelativeZ(2.0f);
			Animation@ anim = console.addAnimation("default", 0, false);
			int[] frames = {0,1,2,3};
			anim.AddFrames(frames);
			if (anim !is null) console.SetAnimation(anim);
		}
		CSpriteLayer@ catalyzer = sprite.addSpriteLayer("catalyzer", "CatalyzerIcon.png", 8, 8);
		if (catalyzer !is null)
		{
			catalyzer.SetVisible(false);
			catalyzer.SetOffset(Vec2f(10,20));
			catalyzer.SetRelativeZ(1.0f);
		}
		CSpriteLayer@ refrigerant = sprite.addSpriteLayer("refrigerant", "RefrigerantIcon.png", 8, 14);
		if (refrigerant !is null)
		{
			refrigerant.SetVisible(false);
			refrigerant.SetOffset(Vec2f(11,17));
			refrigerant.SetRelativeZ(1.0f);
		}
	}

	this.addCommandID("set_password");
	this.addCommandID("login");
	this.addCommandID("reset_password");
	this.addCommandID("sabotage");
	this.addCommandID("desabotage");
	this.addCommandID("open_console");
	this.addCommandID("set_codebreaker");
	this.addCommandID("set_utility");
	this.addCommandID("lock_console");
	this.addCommandID("sync_prep");
	this.addCommandID("sync");
}

void onInit(CSprite@ this)
{
	this.SetZ(-50);
}

void server_Irradiate(CBlob@ this, const f32 damage, const f32 radius)
{
	if (isServer())
	{
		// print("radius: " + radius + "; damage: " + damage);
	
		CBlob@[] blobsInRadius;
		if (this.getMap().getBlobsInRadius(this.getPosition(), radius, @blobsInRadius))
		{
			for (int i = 0; i < blobsInRadius.length; i++)
			{
				CBlob@ blob = blobsInRadius[i];
				if ((blob.hasTag("flesh") || blob.hasTag("nature")) && !blob.hasTag("dead"))
				{
					Vec2f pos = this.getPosition();
					Vec2f dir = blob.getPosition() - pos;
					f32 len = dir.Length();
					dir.Normalize();

					int counter = 1;

					for(int i = 0; i < len; i += 8)
					{
						if (getMap().isTileSolid(pos + dir * i)) counter++;
					}
					
					f32 distMod = Maths::Max(0, (1.00f - ((this.getPosition() - blob.getPosition()).Length() / radius)));
					
					if (XORRandom(100) < 100.0f * distMod) 
					{
						this.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), damage / counter, HittersTC::radiation, true);
					}
				}
			}
		}
	}
}

void onTick(CBlob@ this)
{
	//this.set_u32('elec', 0);
	//u32 elec = this.get_u32("elec");
	CInventory@ inv = this.getInventory();
	if (inv is null) return;

	if (this.get_string("password") == "") this.set_bool("locked", false);

	const f32 mithril_count = inv.getCount("mat_mithril");
	const f32 e_mithril_count = inv.getCount("mat_mithrilenriched");

	const f32 irradiation = (this.get_string("utility") == "catalyzer" ? 5000.0f : 0.0f) + Maths::Pow((mithril_count * (this.get_string("utility") == "refrigerant" ? 0.15f : 0.5f)) + (e_mithril_count * 4.00f) + (5.00f), 2) / (100.00f-(XORRandom(3) == 0 && this.get_string("utility") != "refrigerant" ? XORRandom(10+e_mithril_count/50) : 0));
	const f32 max_irradiation = 15000.00f + (this.get_string("utility") == "refrigerant" ? 5000.0f : 0.0f);

	this.set_f32("irradiation", irradiation);

	if (this.get_bool("codebreaking") && this.get_u32("codebreaking_time") <= getGameTime())
	{
		this.set_string("password", "");
		this.set_bool("locked", false);
		this.set_bool("codebreaking", false);
		this.set_u32("codebreaking_time", 0);

		if (this.getSprite() !is null) this.getSprite().PlaySound("Security_TurnOn", 1.0f);
	}

	//this.setInventoryName("Nuclear Reactor\nHeat: " + Maths::Round(irradiation) + " / " + max_irradiation);

	if (irradiation > max_irradiation * 0.75f)
	{
		const f32 rmod = (irradiation - (max_irradiation * 0.20f)) / (max_irradiation * 0.20f);
		// print("" + rmod);
	
		if (isServer()) 
		{
			server_Irradiate(this, irradiation / max_irradiation * rmod, irradiation / 1500.00f * rmod);
		}
	}

	if (irradiation > max_irradiation+(this.get_string("utility") == "catalyzer" ? 7500.0f : 0.0f) || (this.get_bool("sabotage") && this.get_u32("sabotage_time") <= getGameTime()))
	{
		if (this.get_bool("sabotage")) this.add_f32("irradiation", 5000);
		this.Tag("dead");
		this.Tag("DoExplode");
		if (isServer())
		{	
			this.server_Die();
		}
	}

	if (isClient())
	{
		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			sprite.SetEmitSoundVolume(0.25f);
			sprite.SetEmitSoundSpeed((1.8f + irradiation / 20000.00f) * (irradiation/max_irradiation < 0.5f ? irradiation/max_irradiation+0.35f : 1.0f));
		
			if (this.get_bool("sabotage"))
			{
				this.add_u8("sustimer", 1);
				if (this.get_u8("sustimer") == 2)
				{
					sprite.PlaySound("SusMeltdown.ogg", 5.0f);

					this.SetLight(true);
					this.SetLightRadius(80.0f);
					this.SetLightColor(SColor(255, 255, 0, 0));
					
					this.set_u8("sustimer", 0);
				}
				else this.SetLight(false);
			}

			CSpriteLayer@ console = sprite.getSpriteLayer("console");
			if (console !is null)
			{
				u8 frame = 3;
				if (irradiation < max_irradiation/10) frame = 0;
				else if (irradiation < max_irradiation/5) frame = 1;
				else if (irradiation < max_irradiation/1.5) frame = 2;
				if (frame > 0 && XORRandom(3) == 0)
				{
					f32 vol = 0.25f;
					if (frame > 1) vol = 0.75f;
					else if (frame > 2) vol = 2.0f;
					for (u8 i = 0; i < frame; i++)
						Sound::Play("geiger" + XORRandom(3) + ".ogg", this.getPosition(), vol, 1.0f+0.025f*frame);
				}
				console.SetFrameIndex(frame);
			}
			
			CSpriteLayer@ catalyzer = sprite.getSpriteLayer("catalyzer");
			CSpriteLayer@ refrigerant = sprite.getSpriteLayer("refrigerant");

			if (this.get_string("utility") == "catalyzer")
			{
				if (catalyzer !is null) catalyzer.SetVisible(true);
				if (refrigerant !is null) refrigerant.SetVisible(false);
			}
			else if (this.get_string("utility") == "refrigerant")
			{
				if (refrigerant !is null) refrigerant.SetVisible(true);
				if (catalyzer !is null)  catalyzer.SetVisible(false);
			}
			else
			{
				if (catalyzer !is null) catalyzer.SetVisible(false);
				if (refrigerant !is null) refrigerant.SetVisible(false);
			}
		}
	}

	if (isServer())
	{
		f32 count = (mithril_count / 100) + (e_mithril_count / 10);
		// print("" + count);
	
		this.set_u8("boom_end", u8(count)); // Hack
	
		if (irradiation / 50.00f > XORRandom(100)) //&& this.get_u32("elec") < this.get_u32("elec_max"))
		{	
			CBlob@ mithril_blob = inv.getItem("mat_mithril");
			CBlob@ e_mithril_blob = inv.getItem("mat_mithrilenriched");
			
			if (e_mithril_blob !is null)
			{
				const u32 mithril_quantity = e_mithril_blob.getQuantity();
				const f32 amount = mithril_count / (this.get_string("utility") == "refrigerant" ? 250.0f : 200.0f)+XORRandom(25);
			
				const f32 amount_em = irradiation / 1150.0f;
				
				Material::createFor(this, "mat_mithril", irradiation >= max_irradiation ? Maths::Ceil(amount_em) : Maths::Ceil(amount_em) / 4);

				if (irradiation >= max_irradiation*0.75f) Material::createFor(this, "mat_wilmet", XORRandom(Maths::Ceil(amount_em)/(3.5f - (this.get_string("utility") == "catalyzer" ? 2.5f : 0.0f))));
			}
		}
	}

	CBlob@ fuel = inv.getItem("mat_mithrilenriched");
	if (fuel is null) return;

	bool matching = fuel.getName() == "mat_mithrilenriched";

	//CBlob@ feeder = getBlobByNetworkID(this.get_u16("consume_id"));
	//if (this.get_u16("consume_id") != 0 && feeder is null)
	//{
	//    this.set_u16("consume_id", 0);
	//}

	if (matching) //&& elec <= ELECTRICITY_MAX-ELECTRICITY_PROD)
	{
		//u16 diff = ELECTRICITY_MAX - elec;
		u16 quantity = fuel.getQuantity();

		//if (diff <= ELECTRICITY_PROD) // set to max if last step will make energy over max value
		//{
		//	this.set_u32("elec", ELECTRICITY_MAX);
		//}
		//else
		//{
		//	f32 elec_mod = ELECTRICITY_PROD/2 * (Maths::Pow(0.5f+irradiation/max_irradiation, 5));
		//	if (this.get_string("utility") == "catalyzer") elec_mod *= 1.5f;
		//	this.add_u32("elec", ELECTRICITY_PROD*(0.5f*irradiation/max_irradiation)+elec_mod);
		//}

		//if (this.get_u32("elec") > this.get_u32("elec_max")) this.set_u32("elec", this.get_u32("elec_max"));

		if (isServer() && XORRandom(3) < 2)
		{
			fuel.server_SetQuantity(quantity-1);
		}
	}
}

void onDie(CBlob@ this)
{
	CRules@ rules = getRules();
	if (!shouldExplode(this, rules))
	{
		addToNextTick(this, rules, DoExplosion);
		return;
	}
	
	if (this.hasTag("DoExplode"))
	{
		DoExplosion(this);
	}
}

void DoExplosion(CBlob@ this)
{
	if (isServer())
	{
		CBlob@ boom = server_CreateBlobNoInit("nukeexplosion");
		if (boom !is null)
		{
			boom.setPosition(this.getPosition());
			boom.set_u8("boom_start", 0);
			boom.set_u8("boom_end", (0 + (this.get_f32("irradiation") + (this.get_string("utility") == "catalyzer" ? 5000.0f : 0.0f)) / 300));
			boom.set_u8("boom_frequency", 4);
			boom.set_u32("boom_delay", 0);
			boom.set_u32("flash_delay", 0);
			boom.set_f32("mithril_amount", 3);
			boom.set_f32("flash_distance", 2500);
			boom.Init();
		}
	}

	if (isClient())
	{
		f32 angle = this.get_f32("bomb angle");
		Vec2f pos = this.getPosition();
		CMap@ map = getMap();
		
		for (int i = 0; i < 15; i++)
		{
			MakeParticle(this, Vec2f( XORRandom(128) - 64, XORRandom(100) - 50), getRandomVelocity(angle, XORRandom(350) * 0.01f, 90), particles[XORRandom(particles.length)]);
		}
		
		this.getSprite().Gib();
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return (this.getTeamNum() == forBlob.getTeamNum() || this.getTeamNum() >= 7) && !this.getMap().rayCastSolid(forBlob.getPosition(), this.getPosition());
}

void server_Sync(CBlob@ this)
{
    if (isServer())
    {
        CBitStream params;
        //params.write_u32(this.get_u32("elec"));
		params.write_f32(this.get_f32("heat"));
		params.write_string(this.get_string("password"));
		params.write_bool(this.get_bool("sabotage"));
		params.write_u32(this.get_u32("sabotage_time"));
		params.write_bool(this.get_bool("codebreaking"));
		params.write_u32(this.get_u32("codebreaking_time"));
		params.write_string(this.get_string("utility"));

        this.SendCommand(this.getCommandID("sync"), params);
    }
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBlob@ carried = caller.getCarriedBlob();

	CBitStream params;
	params.write_u16(caller.getNetworkID());

	bool has_password = this.get_string("password") != "";

	bool is_paper = carried !is null && carried.getName() == "paper";
	bool is_codebreaker = has_password && carried !is null && carried.getName() == "codebreaker";
	bool utility = carried !is null && (carried.getName() == "wrench" || carried.getName() == "catalyzer" || carried.getName() == "refrigerant");

	if ((this.get_bool("locked") || !has_password) && !is_codebreaker)
	{
		if (has_password)
		{
			string button_name = "\nLogin to console";
			if (!is_paper)
				button_name = "\nInsert a paper with password";
			CButton@ button = caller.CreateGenericButton(17, Vec2f(0, 8), this, this.getCommandID("login"), button_name, params);
			if (!is_paper && button !is null)
				button.SetEnabled(false); 
		}
		else
		{
			if (is_paper)
			{
				CButton@ button = caller.CreateGenericButton("$paper$", Vec2f(0, 8), this, this.getCommandID("set_password"), "\nSet password", params);
			}
			else
			{
				CButton@ button = caller.CreateGenericButton("$paper$", Vec2f(0, 8), this, this.getCommandID("set_password"), "\nSet password with a paper", params);
				if (button !is null) button.SetEnabled(false);
			}
		}
	}
	if (is_codebreaker && !this.get_bool("codebreaking"))
	{
		CButton@ button = caller.CreateGenericButton("$codebreaker$", Vec2f(-10, 8), this, this.getCommandID("set_codebreaker"), "\nLaunch codebreaker", params);
	}
	if (this.get_bool("codebreaking"))
	{
		CButton@ button = caller.CreateGenericButton("$codebreaker$", Vec2f(-10, 8), this, this.getCommandID("set_codebreaker"), "\nStop codebreaking", params);
	}

	if (!this.get_bool("locked") && !is_codebreaker && !this.get_bool("codebreaking"))
	{
		CButton@ button = caller.CreateGenericButton("$paper$", Vec2f(-10, 8), this, this.getCommandID("open_console"), "\nConsole", params);
	}

	if (utility && carried !is null)
	{
		CButton@ button = caller.CreateGenericButton("$"+carried.getName()+"$", Vec2f(0, -8), this, this.getCommandID("set_utility"), (carried.getName() == "wrench" ? "\nRemove the utility" : "\nSet an utility"), params);
	}
}


void ConsoleMenu(CBlob@ this, CBlob@ caller)
{
	if (caller !is null && caller.isMyPlayer())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f), this, Vec2f(4, 1), "Console");
		
		if (menu !is null)
		{
			menu.deleteAfterClick = true;

			CGridButton@ buttonlock = menu.AddButton("$icon0$", "Lock console", this.getCommandID("lock_console"), Vec2f(1, 1), params);
			CGridButton@ buttonresetpassword = menu.AddButton("$icon1$", "Reset password", this.getCommandID("reset_password"), Vec2f(1, 1), params);
			CGridButton@ buttonsabotage = menu.AddButton("$icon2$", "Overload reactor\nSets a timer of a minute, until reactor explodes", this.getCommandID("sabotage"), Vec2f(1, 1), params);
			if (buttonsabotage !is null)
			{
				if (this.get_bool("sabotage")) buttonsabotage.SetEnabled(false);
			}
			CGridButton@ buttondesabotage = menu.AddButton("$icon3$", "Unload reactor\nStabilizes reactor and cancels overload", this.getCommandID("desabotage"), Vec2f(1, 1), params);
			if (buttondesabotage !is null)
			{
				if (!this.get_bool("sabotage")) buttondesabotage.SetEnabled(false);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("sync"))
	{
		if (isClient())
		{
			//u32 elec;
			f32 heat;
			string password;
			bool sabotage;
			u32 sabotage_time;
			bool codebreaking;
			u32 codebreaking_time;
			string utility;
            //if (!params.saferead_u32(elec)) return;
			if (!params.saferead_f32(heat)) return;
			if (!params.saferead_string(password)) return;
			if (!params.saferead_bool(sabotage)) return;
			if (!params.saferead_u32(sabotage_time)) return;
			if (!params.saferead_bool(codebreaking)) return;
			if (!params.saferead_u32(codebreaking_time)) return;
			if (!params.saferead_string(utility)) return;
			//this.set_u32("elec", elec);
			this.set_f32("heat", heat);
			this.set_string("password", password);
			this.set_bool("sabotage", sabotage);
			this.set_u32("sabotage_time", sabotage_time);
			this.set_bool("codebreaking", codebreaking);
			this.set_u32("codebreaking_time", codebreaking_time);
			this.set_string("utility", utility);
		}
	}
	else if (cmd == this.getCommandID("set_password"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;
		CBlob@ b = caller.getCarriedBlob();
		if (b is null || b.getName() != "paper") return;

		this.set_string("password", b.get_string("text"));
		this.set_bool("locked", true);
	}
	else if (cmd == this.getCommandID("login"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;
		CBlob@ b = caller.getCarriedBlob();
		if (b is null || b.getName() != "paper") return;

		if (b.get_string("text") == this.get_string("password")) this.set_bool("locked", false);
	}
	else if (cmd == this.getCommandID("reset_password"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		this.set_string("password", "");
		this.set_bool("locked", false);
	}
	else if (cmd == this.getCommandID("sabotage"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		this.set_bool("sabotage", true);
		this.set_u32("sabotage_time", getGameTime()+30*60); // 1 min
	}
	else if (cmd == this.getCommandID("desabotage"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		this.set_bool("sabotage", false);
		this.set_u32("sabotage_time", 0);
		this.set_u8("sustimer", 0);
		this.SetLight(false);
	}
	else if (cmd == this.getCommandID("open_console"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		ConsoleMenu(this, caller);
	}
	else if (cmd == this.getCommandID("set_codebreaker"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		this.set_bool("codebreaking", !this.get_bool("codebreaking"));
		this.set_u32("codebreaking_time", getGameTime()+30*15); // 15 seconds
		if (!this.get_bool("codebreaking")) this.set_u32("codebreaking_time", 0);

		this.getSprite().PlaySound(this.get_bool("codebreaking") ? "Security_TurnOn" : "Security_TurnOff", 0.30f, 1.00f);
		//printf(""+this.get_bool("codebreaking"));
	}
	else if (cmd == this.getCommandID("set_utility"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		CBlob@ b = caller.getCarriedBlob();
		if (b !is null && (b.getName() == "wrench" || b.getName() == "catalyzer" || b.getName() == "refrigerant"))
		{
			string utility = this.get_string("utility");
			this.set_string("utility", "");
			bool wrench = b.getName() == "wrench";

			if (isServer())
			{
				server_CreateBlob(utility, caller.getTeamNum(), this.getPosition());
				if (!wrench) b.server_Die();
			}

			if (!wrench) this.set_string("utility", b.getName());
		}
	}
	else if (cmd == this.getCommandID("lock_console"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		this.set_bool("locked", true);
	}
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 1 + XORRandom(200) * 0.01f, 2 + XORRandom(5), XORRandom(100) * -0.00005f, true);
}

void onRender(CSprite@ this)
{	
	CBlob@ blob = this.getBlob();

	Vec2f pos = getDriver().getScreenPosFromWorldPos(this.getBlob().getPosition() + Vec2f(0, -32));
	GUI::SetFont("menu");
	
	if (blob.get_bool("sabotage") && blob.get_u32("sabotage_time") > getGameTime())
	{
		u32 secs = ((blob.get_u32("sabotage_time")-getGameTime())/30);
		string units = ((secs != 1) ? "seconds" : "second");
		string text = "Detonation in " + secs + " " + units + "!";
		GUI::DrawTranslatedTextCentered(text, pos, SColor(255, 255, 0, 0));
	}
	if (blob.get_bool("codebreaking")) GUI::DrawProgressBar(pos-Vec2f(32.0f, 0), pos+Vec2f(32.0f, 8.0f), 1.0f - ((blob.get_u32("codebreaking_time")-getGameTime())/450.0f));
}