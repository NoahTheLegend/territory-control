#include "Hitters.as";
#include "HittersTC.as";
#include "MakeMat.as";
#include "MaterialCommon.as";
#include "Explosion.as";
#include "Buttons.as";

const string fuel_name = "mat_mithrilenriched";
const u8 fuel_consumption = 1;

const Vec2f terminal_size = Vec2f(650, 356);
const Vec2f chart_size = Vec2f(terminal_size.x, terminal_size.y / 2);
const SColor chart_canvas_color = SColor(255,55,55,55);
const f32 danger_zone_width = terminal_size.x / 10.0f;

const u8 chart_steps = 50;
const u8 chart_update_rate = 30;
const u8 processing_generating_resource_rate = 150;

const f32 negative_danger_zone_irradiate_heat = -220.0f;
const f32 positive_danger_zone_irradiate_heat = 1700.0f;
const f32 danger_zone_explosion_heat = 2000.0f;
const f32 max_irradiate_damage = 0.5f;
const f32 max_irradiate_radius = 156.0f;
const f32 reactor_explosion_reduction = 50;

const f32 lerp_open = 0.5f;
const f32 lerp_close = 0.4f;
const f32 heat_lerp = 0.001f;
const f32 heat_lerp_gain_per_enriched = 0.00001f;

const f32 mithril_heat_factor = 0.25f;
const f32 mithril_catalyzer_max_heat_boost = 1.0f;
const f32 enriched_mithril_heat_factor = 2.0f;
const f32 refrigerant_mithril_heat_mod = 1.0f;
const f32 instability_factor = 50.0f;
const f32 conversion_enriched_to_mithril_chance = 0.25f;
const f32 conversion_enriched_to_mithril_max_amount = 25;
const f32 conversion_enriched_to_mithril_chance_positive_chance_extra = 0.5f;
const f32 conversion_enriched_to_mithril_chance_positive_amount_extra = 50;

const f32 min_temp_c = -273.15f;
const f32 min_temp_f = -459.67f;
const f32 min_temp_k = 0;
const f32 max_temp_c = 2500.0f;
const f32 max_temp_f = max_temp_c * 9.0f / 5.0f + 32.0f;
const f32 max_temp_k = max_temp_c + 273.15f;

const u8 row_items = materials.size();
const u8 max_utility_slots = 2;
const u8 material_update_rate = 90;
const u8 attached_update_rate = 30;

const f32 base_mithril_heat_accumulation = 300; // instability reduction
const f32 base_enriched_heat_accumulation = 100;

const f32 footer_text_gap = terminal_size.x / 4;
const f32 footer_height = 24;

const string[] accepted_utilities = { // accepted utilities
	"catalyzer",
	"refrigerant"
};

const string[] materials = { // materials on the bar
	"mat_mithril",
	"mat_titanium",
	"mat_iron",
	"mat_copper",
	"mat_gold",
	"mat_wilmet"
};

const string[] material_names = {
	"Mithril",
	"Titanium",
	"Iron",
	"Copper",
	"Gold",
	"Wilmet"
};

const string[][] requirements = {
	{"refrigerant", "cold-infernalstone"},
	{"refrigerant", "cold-infernalstone"},
	{"refrigerant"},
	{},
	{"catalyzer"},
	{"catalyzer", "infernalstone"}
};

const string[] material_tooltips = { // tooltips for materials
	"Requires a heat absorber, a refrigerant and heat "+material_generation_ranges[0][0]+" - "+material_generation_ranges[0][1]+"°C",
	"Requires a heat absorber, a refrigerant and heat "+material_generation_ranges[1][0]+" - "+material_generation_ranges[1][1]+"°C",
	"Requires a refrigerant and heat "+material_generation_ranges[2][0]+" - "+material_generation_ranges[2][1]+"°C",
	"Requires heat "+material_generation_ranges[3][0]+" - "+material_generation_ranges[3][1]+"°C",
	"Requires a catalyzer and heat "+material_generation_ranges[4][0]+" - "+material_generation_ranges[4][1]+"°C",
	"Requires a catalyzer, a burner and heat "+material_generation_ranges[5][0]+" - "+material_generation_ranges[5][1]+"°C"
};

const string[] material_icons = {
	"$mithril_req$",
	"$titanium_req$",
	"$iron_req$",
	"$copper_req$",
	"$gold_req$",
	"$wilmet_req$"
};

const f32[] ratios = { // how much materials per synthesis to create
	22.5f,
	75.0f,
	90.0f,
	65.0f,
	35.0f,
	25.0f
};

const f32[][] material_generation_ranges = { // difference in degrees (width for generation) for each material in celsius
	{min_temp_c, min_temp_c + 55},
	{min_temp_c + 100, min_temp_c + 125},
	{-75, -30},
	{280, 530},
	{1300, 1500},
	{1800, max_temp_c - 300}
};

const string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

void onInit(CBlob@ this)
{
	this.addCommandID("switch");
	this.addCommandID("set_password");
	this.addCommandID("login");
	this.addCommandID("reset_password");
	this.addCommandID("sabotage");
	this.addCommandID("desabotage");
	this.addCommandID("open_console");
	this.addCommandID("set_codebreaker");
	this.addCommandID("lock_console");
	this.addCommandID("request_terminal_for_local");
	this.addCommandID("interact_utility");
	this.addCommandID("interact_fuel");
	this.addCommandID("sync_prep");
	this.addCommandID("sync");
	this.addCommandID("remove_from_attached");
	this.addCommandID("set_temp_mode");

	if (isClient())
	{
		Vec2f screen_center = Vec2f(getDriver().getScreenWidth() / 2, getDriver().getScreenHeight() / 2);
		Vec2f t_size = terminal_size;

		this.set_Vec2f("terminal_tl", screen_center - t_size / 2);
		this.set_Vec2f("terminal_br", screen_center + t_size / 2);

		UpdateTerminalSize(this);
	}

	SetButtons(this);
	ResetAttached(this);

	this.Tag("no fuel hint");
	this.Tag("builder always hit");
	this.Tag("generator");
	this.Tag("extractable");

	this.set_u32("switch_cooldown", 0);
	this.set_u32("set_temp_mode_cooldown", 0);
	this.set_u32("interact_utility_cooldown", 0);
	this.set_string("override_anim", "");

	this.set_u16("consume_id", 0);
	this.set_string("password", "");
	this.set_bool("enabled", false);
	this.set_bool("locked", false);
	this.set_bool("sabotage", false);
	this.set_u32("sabotage_time", 0);
	this.set_bool("codebreaking", false);
	this.set_u32("codebreaking_time", 0);
	this.set_bool("catalyzer", false);
	this.set_bool("refrigerant", false);
	this.set_u8("temp_mode", 2); // kelvin, fahrenheit, celsius
	this.set_f32("mithril_heat", 0.0f);
	this.set_f32("enriched_heat", 0.0f);
	this.set_u8("current_resource_generation", 255);
	this.set_f32("current_resource_precision", 0.0f);
	this.set_f32("sound_windup", 0.0f);
	this.set_f32("sound_speed", 1);
	this.set_f32("explosion_factor", 0.0f);

	f32[] chart_temp_history;
	this.set("chart_temp_history", @chart_temp_history);
	UpdateChart(this);

	this.set_string("mithril_text", "");
	this.set_string("enriched_mithril_text", "");
	this.set_f32("render_factor", 0.0f);

	AddIconToken("$icon0$", "Coins.png", Vec2f(16, 16), 5);
	AddIconToken("$icon1$", "ExtraIcons.png", Vec2f(12, 11), 0);
	AddIconToken("$icon2$", "ExtraIcons.png", Vec2f(12, 11), 1);
	AddIconToken("$icon3$", "ExtraIcons.png", Vec2f(12, 11), 2);
	AddIconToken("$icon4$", "ExtraIcons.png", Vec2f(12, 11), 3);

	AddIconToken("$temp0$", "TemperatureIcons.png", Vec2f(16, 16), 0);
	AddIconToken("$temp1$", "TemperatureIcons.png", Vec2f(16, 16), 1);
	AddIconToken("$temp2$", "TemperatureIcons.png", Vec2f(16, 16), 2);

	AddIconToken("$danger_explode$", "SmallExplosion2.png", Vec2f(24, 24), 1);
	AddIconToken("$danger_mithril$", "FalloutGas.png", Vec2f(32, 32), 2);
	AddIconToken("$catalyzer_icon$", "CatalyzerIcon.png", Vec2f(16, 16), 0);
	AddIconToken("$refrigerant_icon$", "RefrigerantIcon.png", Vec2f(16, 16), 0);

	AddIconToken(material_icons[0], "ReactorRequirements.png", Vec2f(48, 16), 0);
	AddIconToken(material_icons[1], "ReactorRequirements.png", Vec2f(48, 16), 1);
	AddIconToken(material_icons[2], "ReactorRequirements.png", Vec2f(48, 16), 2);
	AddIconToken(material_icons[3], "ReactorRequirements.png", Vec2f(48, 16), 3);
	AddIconToken(material_icons[4], "ReactorRequirements.png", Vec2f(48, 16), 4);
	AddIconToken(material_icons[5], "ReactorRequirements.png", Vec2f(48, 16), 5);

	AddIconToken("$mithril_icon$", "Material_Mithril.png", Vec2f(16, 16), 3);
	AddIconToken("$enriched_icon$", "Material_Mithrilenriched.png", Vec2f(16, 16), 3);

	server_Sync(this);
	this.getShape().getConsts().mapCollisions = false;
	this.inventoryButtonPos = Vec2f(-40, 16);

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("MithrilReactor_Loop-Reverse_.ogg");
		sprite.SetEmitSoundVolume(0.25f);
		sprite.SetEmitSoundSpeed(0.85f);
		sprite.SetEmitSoundPaused(true);

		sprite.getConsts().accurateLighting = true;
		sprite.SetRelativeZ(-10.0f);

		CSpriteLayer@ console = sprite.addSpriteLayer("console", "Console.png", 32, 32);
		if (console !is null)
		{
			console.SetOffset(Vec2f(-1, 20));
			console.SetRelativeZ(2.0f);
			console.ScaleBy(0.5f, 0.5f);
			
			{Animation@ anim = console.addAnimation("idle_off", 0, false);
			int[] frames = {0};
			anim.AddFrames(frames);
			if (anim !is null) console.SetAnimation(anim);}

			{Animation@ anim = console.addAnimation("off", 4, false);
			int[] frames = {3,0};
			anim.AddFrames(frames);}

			{Animation@ anim = console.addAnimation("start", 4, true);
			int[] frames = {0,1,2,3};
			anim.AddFrames(frames);}

			{Animation@ anim = console.addAnimation("idle", 4, true);
			int[] frames = {8,9,10,11,12,13,14,15,14,12};
			anim.AddFrames(frames);}

			{Animation@ anim = console.addAnimation("locked", 0, false);
			int[] frames = {16};
			anim.AddFrames(frames);}

			{Animation@ anim = console.addAnimation("warning", 4, true);
			int[] frames = {17,18};
			anim.AddFrames(frames);}

			{Animation@ anim = console.addAnimation("breakage", 4, true);
			int[] frames = {19,20};
			anim.AddFrames(frames);}
		}
	}
}

void onTick(CBlob@ this)
{
	if (isServer() && this.hasTag("require_sync"))
	{
		this.Untag("require_sync");
		server_Sync(this);
	}

	if (isClient())
	{
		CRules@ rules = getRules();
		if (rules is null || !rules.exists("terminal_id")) return;

		u16 id = rules.get_u16("terminal_id");
		bool closing = id != this.getNetworkID();
		if (closing) return;
	}

	if (this.get_string("password") == "") this.set_bool("locked", false);
	
	CInventory@ inv = this.getInventory();
	if (inv is null) return;

	TerminalTick(this, inv);

	const f32 mithril_count = inv.getCount("mat_mithril");
	const f32 enriched_count = inv.getCount("mat_mithrilenriched");
	
	CBlob@ infstone = inv.getItem("infernalstone");
	const bool has_infstone = infstone !is null;
	const bool burning_infstone = has_infstone && !infstone.hasTag("cold");

	const bool has_catalyzer = this.get_bool("catalyzer");
	const bool has_refrigerant = this.get_bool("refrigerant");

	const bool enabled = this.get_bool("enabled");
	const bool locked = this.get_bool("locked");
	const bool codebreaking = this.get_bool("codebreaking");

	const f32 max_heat = max_temp_c;
	UpdateHeat(this);

	f32 old_heat = this.get_f32("heat");
	f32 mithril_heat = this.get_f32("mithril_heat");
	f32 enriched_mithril_heat = this.get_f32("enriched_heat");

	f32 heat = mithril_heat + enriched_mithril_heat;
	if (isServer()
		&& (heat != this.get_f32("heat") || this.getTickSinceCreated() % processing_generating_resource_rate == 0))
	{
		DefineResourceGenerating(this);
		server_Sync(this);
	}
	
	if (has_infstone)
	{
		if (old_heat >= 2000 && !burning_infstone)
		{
			infstone.Untag("cold");
			if (isServer()) infstone.Sync("cold", true);
		}
		else if (old_heat < -250 && burning_infstone)
		{
			infstone.Tag("cold");
			if (isServer()) infstone.Sync("cold", true);
		}
	}

	if (!enabled) heat = 0;
	this.set_f32("heat", Maths::Clamp(Maths::Lerp(old_heat, heat, heat_lerp + enriched_count * heat_lerp_gain_per_enriched), min_temp_c, max_temp_c));

	const bool sabotaging = this.get_bool("sabotage");
	f32 irradiate_factor = old_heat < 0
						? old_heat > negative_danger_zone_irradiate_heat ? 0 : Maths::Clamp(Maths::Abs(old_heat - negative_danger_zone_irradiate_heat) / Maths::Abs(min_temp_c - negative_danger_zone_irradiate_heat), 0.0f, 1.0f)
						: old_heat < positive_danger_zone_irradiate_heat ? 0 : Maths::Clamp((old_heat - positive_danger_zone_irradiate_heat) / (max_temp_c - positive_danger_zone_irradiate_heat), 0.0f, 1.0f);
	const u8 irradiation_rate = 300 - 270 * irradiate_factor;
	const u8 creation_rate = 150 - Maths::Min(90, enriched_count / 5);

	f32 explosion_chance_factor = Maths::Clamp((old_heat - danger_zone_explosion_heat) / (max_temp_c - danger_zone_explosion_heat), 0.0f, 1.0f);
	int explosion_chance = 100 * explosion_chance_factor;

	this.set_f32("explosion_factor", explosion_chance_factor);
	bool explosion_condition = XORRandom(100) < explosion_chance;

	if ((sabotaging && this.get_u32("sabotage_time") <= getGameTime())
		|| (explosion_condition && this.getTickSinceCreated() % creation_rate == 0))
	{
		if (sabotaging) this.add_f32("heat", 2500);

		this.Tag("dead");
		this.Tag("DoExplode");
		if (isServer()) this.server_Die();
	}

	if (irradiate_factor > 0.0f)
	{
		server_Irradiate(this, max_irradiate_damage * irradiate_factor, max_irradiate_radius * irradiate_factor);
	}

	if (enabled && this.getTickSinceCreated() % creation_rate == 0) // rework later
	{
		CBlob@ fuel = inv.getItem("mat_mithrilenriched");
		if (isServer() && fuel !is null)
		{
			u16 quantity = fuel.getQuantity();
			fuel.server_SetQuantity(quantity - 1);

			f32 count = (mithril_count / 100) + (enriched_count / 10);
			this.set_u8("boom_end", u8(count));

			// generate mithril randomly
			f32 producing_heat_factor = Maths::Clamp(old_heat / max_temp_c, 0, 1);
			int extra_chance = conversion_enriched_to_mithril_chance_positive_chance_extra * producing_heat_factor * 100;
			int chance_to_spawn_mithril = conversion_enriched_to_mithril_chance * 100 + extra_chance;
			
			bool spawn_mithril = XORRandom(100) < chance_to_spawn_mithril;
			if (spawn_mithril)
			{
				int extra_quantity = conversion_enriched_to_mithril_chance_positive_amount_extra * producing_heat_factor;
				int producing_quantity = XORRandom(conversion_enriched_to_mithril_max_amount) + 1;
				
				CBlob@ mat = server_CreateBlob("mat_mithril", -1, this.getPosition() + Vec2f(0, 0));
				if (mat !is null)
				{
					mat.server_SetQuantity(producing_quantity);
					this.server_PutInInventory(mat);
				}
			}

			u8 current_material_producing_index = this.get_u8("current_resource_generation");
			if (current_material_producing_index < materials.size())
			{
				f32 precision = this.get_f32("current_resource_precision");
				int producing_quantity = ratios[current_material_producing_index] * precision;

				CBlob@ mat = server_CreateBlob(materials[current_material_producing_index], -1, this.getPosition() + Vec2f(0, 0));
				if (mat !is null)
				{
					mat.server_SetQuantity(producing_quantity);
					this.server_PutInInventory(mat);
				}
			}
		}
	}

	if (isClient())
	{
		f32 sound_windup = this.get_f32("sound_windup");
		this.set_f32("sound_windup", Maths::Lerp(sound_windup, enabled ? 1.0f : 0, 0.01f));

		CSprite@ sprite = this.getSprite();
		if (sprite !is null)
		{
			f32 sound_speed = this.get_f32("sound_speed");
			sound_speed = Maths::Lerp(sound_speed, ((1.8f + heat / 20000.00f) * (heat/max_heat < 0.5f ? heat/max_heat+0.35f : 1.0f)), 0.1f);
			this.set_f32("sound_speed", sound_speed);

			sprite.SetEmitSoundPaused(sound_windup <= 0.05f);
			sprite.SetEmitSoundVolume(0.35f * sound_windup);
			sprite.SetEmitSoundSpeed(sound_speed * sound_windup);
			
			bool wait_for_anim_end = true;
			string override_anim = this.get_string("override_anim");
			string animation = "idle_off";

			string anim_name = "";
			if (sprite.animation !is null) anim_name = sprite.animation.name;

			if (override_anim != "")
			{
				this.set_string("override_anim", "");
				animation = override_anim;
				wait_for_anim_end = false;
			}
			else if (anim_name != "off" && anim_name != "start")
			{
				if (enabled)
				{
					if (locked)
					{
						animation = "locked";
						wait_for_anim_end = false;
					}
					else animation = "idle";
				}

				if (codebreaking || explosion_condition)
				{
					wait_for_anim_end = false;
					animation = "breakage";
				}

				if (sabotaging)
				{
					wait_for_anim_end = false;
					animation = "warning";
				}
			}

			CSpriteLayer@ console = sprite.getSpriteLayer("console");
			if (console !is null)
			{
				if (!wait_for_anim_end || console.isAnimationEnded())
				{
					bool same_anim = console.animation.name == animation;
					console.SetAnimation(animation);
					if (!same_anim && console.animation.name != "") console.animation.frame = 0;
				}
			}
		}

		if (sabotaging)
		{
			if (this.getTickSinceCreated() % 30 == 0)
			{
				this.add_u8("sustimer", 1);
				if (this.get_u8("sustimer") == 2)
				{
					sprite.PlaySound("SusMeltdown.ogg", 5.0f);

					this.SetLight(true);
					this.SetLightRadius(128.0f);
					this.SetLightColor(SColor(255, 255, 0, 0));

					this.set_u8("sustimer", 0);
				}
				else this.SetLight(false);
			}
		}
	}
}

void DefineResourceGenerating(CBlob@ this)
{
	if (!this.get_bool("enabled"))
	{
		this.set_u8("current_resource_generation", 255);
		this.set_f32("current_resource_precision", 0.0f);
		return;
	}

	const f32 heat = this.get_f32("heat");
	const f32 half_track = 1.0f;
	f32 precision = 0;

	for (int i = 0; i < materials.size(); i++)
	{
		f32[] area = material_generation_ranges[i];
		f32 min = area[0];
		f32 max = area[1];

		f32 min_factor = min < 0
						? Maths::Abs(min) / Maths::Abs(min_temp_c)
						: min / max_temp_c;
		
		f32 max_factor = max < 0
						? Maths::Abs(max) / Maths::Abs(min_temp_c)
						: max / max_temp_c;
		
		f32 min_x = min < 0
					? -half_track * min_factor
					: half_track * min_factor;

		f32 max_x = max < 0
					? -half_track * max_factor
					: half_track * max_factor;

		if (heat >= min && heat <= max)
		{
			bool has_req = RequirementsMet(this, i);
			if (!has_req) continue;
			
			precision = 1.0f - Maths::Abs((heat - min) / (max - min) - 0.5f) * 2.0f;
			this.set_f32("current_resource_precision", precision);
			this.set_u8("current_resource_generation", i);
			return;
		}
	}
	
	this.set_u8("current_resource_generation", 255);
}

bool RequirementsMet(CBlob@ this, u8 index)
{
	CInventory@ inv = this.getInventory();
	if (inv is null) return false;

	if (!this.hasBlob(fuel_name, fuel_consumption)) return false;

	string[] reqs = requirements[index];
	if (reqs.size() == 0) return true;
	
	for (u8 i = 0; i < reqs.size(); i++)
	{
		if (reqs[i].find("inf") != -1)
		{
			CBlob@ inf_stone = inv.getItem("infernalstone");
			if (inf_stone is null) return false;
			
			if (reqs[i].find("cold") != -1)
			{
				if (!inf_stone.hasTag("cold")) return false;
			}
			else
			{
				if (inf_stone.hasTag("cold")) return false;
			}
		}
		else if (!this.get_bool(reqs[i]))
		{
			return false;
		}
	}

	return true;
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
				CButton@ button = caller.CreateGenericButton("$paper$", Vec2f(-10, 8), this, this.getCommandID("set_password"), "\nSet a password", params);
			}
			else
			{
				CButton@ button = caller.CreateGenericButton("$icon4$", Vec2f(-10, 8), this, this.getCommandID("set_password"), "\nSet a password with a paper", params);
				if (button !is null) button.SetEnabled(false);
			}
		}
	}
	if (is_codebreaker && !this.get_bool("codebreaking"))
	{
		CButton@ button = caller.CreateGenericButton("$codebreaker$", Vec2f(0, 8), this, this.getCommandID("set_codebreaker"), "\nLaunch codebreaker", params);
	}
	if (this.get_bool("codebreaking"))
	{
		CButton@ button = caller.CreateGenericButton("$codebreaker$", Vec2f(0, 8), this, this.getCommandID("set_codebreaker"), "\nStop codebreaking", params);
	}

	if (!this.get_bool("locked") && !is_codebreaker && !this.get_bool("codebreaking"))
	{
		CButton@ button = caller.CreateGenericButton("$icon1$", Vec2f(0, 8), this, this.getCommandID("open_console"), "\nConsole", params);
	}
}

void ConsoleMenu(CBlob@ this, CBlob@ caller)
{
	if (caller !is null && caller.isMyPlayer())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f), this, Vec2f(5, 1), "Console");
		
		if (menu !is null)
		{
			menu.deleteAfterClick = true;
			
			CGridButton@ buttonlock = menu.AddButton("$icon0$", "Lock console", this.getCommandID("lock_console"), Vec2f(1, 1), params);
			CGridButton@ buttonresetpassword = menu.AddButton("$icon4$", "Reset password", this.getCommandID("reset_password"), Vec2f(1, 1), params);
			CGridButton@ buttonterminal = menu.AddButton("$icon1$", "Terminal", this.getCommandID("request_terminal_for_local"), Vec2f(1, 1), params);

			CGridButton@ buttonsabotage = menu.AddButton("$icon2$", "Overload reactor\nSets a timer for a minute to explode the reactor", this.getCommandID("sabotage"), Vec2f(1, 1), params);
			if (buttonsabotage !is null && this.get_bool("sabotage")) buttonsabotage.SetEnabled(false);
			
			CGridButton@ buttondesabotage = menu.AddButton("$icon3$", "Unload reactor\nStabilizes reactor and cancels overload", this.getCommandID("desabotage"), Vec2f(1, 1), params);
			if (buttondesabotage !is null && !this.get_bool("sabotage")) buttondesabotage.SetEnabled(false);
		}
	}
}

void onRender(CSprite@ this)
{	
	CBlob@ blob = this.getBlob();
	DrawTerminal(blob);

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

bool isLocalAttachedToTerminal(CBlob@ this, CBlob@ local)
{
	CRules@ rules = getRules();
	if (rules is null) return false;
	
	if (rules.exists("terminal_id") && rules.get_u16("terminal_id") != 0)
	{
		CBlob@ b = getBlobByNetworkID(rules.get_u16("terminal_id"));
		if (b !is null) return true; // other reactor is still alive
	}

	return false;
}

void SetTerminalForLocal(CBlob@ this, u16 pid)
{
	if (!isClient()) return;

	CBlob@ local = getLocalPlayerBlob();
	if (local is null) return;

	CPlayer@ p = local.getPlayer();
	if (p is null || p.getNetworkID() != pid) return;

	CRules@ rules = getRules();
	if (rules is null) return;

	if (isLocalAttachedToTerminal(this, local)) return;
	this.getSprite().PlaySound("TerminalOpen.ogg", 0.5f, 1.0f + XORRandom(100) * 0.001f);
	
	rules.set_u16("terminal_id", this.getNetworkID());
}

void CloseTerminal(CBlob@ this, bool all_terminals = false)
{
	if (!isClient()) return;
	
	CRules@ rules = getRules();
	if (rules is null
		|| (rules.get_u16("terminal_id") != this.getNetworkID() && !all_terminals)) return;


	CPlayer@ p = getLocalPlayer();
	if (p is null) return;

	if (all_terminals || (rules.exists("terminal_id") && rules.get_u16("terminal_id") == this.getNetworkID()))
	{
		if (!all_terminals || rules.get_u16("terminal_id") == this.getNetworkID())
			this.getSprite().PlaySound("TerminalClose.ogg", 0.5f, 1.0f + XORRandom(100) * 0.001f);

		if (p.isMyPlayer())
		{
			CBitStream params;
			params.write_u16(p.getNetworkID());
			this.SendCommand(this.getCommandID("remove_from_attached"), params);
		}
		rules.set_u16("terminal_id", 0);
	}
}

void UpdateHeat(CBlob@ this)
{
	u16 mithril_count = this.get_u16("mithril_count");
	u16 enriched_count = this.get_u16("enriched_count");
	
	u8 temp_mode = this.get_u8("temp_mode");
	f32 heat = this.get_f32("heat");

	bool has_catalyzer = this.get_bool("catalyzer");
	bool has_refrigerant = this.get_bool("refrigerant");

	const f32 max_heat = max_temp_c;
	const f32 heating_factor = (this.get_f32("heat") / max_heat);
	const f32 negative_heating_factor = (Maths::Abs(this.get_f32("heat")) / Maths::Abs(min_temp_c));
	const f32 instability = XORRandom(10 + enriched_count / instability_factor) * heating_factor;

	f32 mithril_heat = Maths::Pow(mithril_count * mithril_heat_factor * (has_refrigerant ? refrigerant_mithril_heat_mod : 1.0f), 2) / (base_mithril_heat_accumulation - instability * (has_catalyzer ? 10 : 5));
	if (has_catalyzer)
	{
		mithril_heat *= 1.0f + (mithril_catalyzer_max_heat_boost * heating_factor);
	}
	f32 enriched_mithril_heat = Maths::Pow(enriched_count * enriched_mithril_heat_factor, 2) / (base_enriched_heat_accumulation - instability * (has_catalyzer ? 3 : 1));
	if (has_refrigerant)
	{
		mithril_heat *= -0.1f; // ~10% of negative
		enriched_mithril_heat *= -0.1f;
	}

	this.set_f32("mithril_heat", mithril_heat);
	this.set_f32("enriched_heat", enriched_mithril_heat);
}

void UpdateMaterialsCount(CBlob@ this, CInventory@ inv)
{
	u16 mithril_count = inv.getCount("mat_mithril");
	u16 enriched_count = inv.getCount("mat_mithrilenriched");
	u16 wilmet_count = inv.getCount("mat_wilmet");

	this.set_u16("mithril_count", mithril_count);
	this.set_u16("enriched_count", enriched_count);
	this.set_u16("wilmet_count", wilmet_count);

	UpdateHeat(this);
	
	// render update
	f32 mithril_heat = this.get_f32("mithril_heat");
	f32 enriched_mithril_heat = this.get_f32("enriched_heat");
	u8 temp_mode = this.get_u8("temp_mode");

	f32 total_heat = Maths::Round((mithril_heat + enriched_mithril_heat) * 10) / 10.0f;
	f32 target_heat_factor = Maths::Clamp(total_heat >= 0 ? (total_heat / max_temp_c) * 0.5f : -(Maths::Abs(total_heat) / Maths::Abs(min_temp_c)) * 0.5f, -0.5f, 0.5f);
	this.set_f32("target_heat_factor", target_heat_factor);
	string target_heat_text = "~ "+formatTemp(total_heat, temp_mode);
	this.set_string("target_heat_text", target_heat_text);
}

void MouseHandlerTick(CBlob@ this)
{
	if (!isClient()) return;
	CBlob@ local = getLocalPlayerBlob();

	if (local is null) return;
	bool a1 = local.isKeyPressed(key_action1) || local.isKeyPressed(key_action2);
	this.set_bool("buttons_a1", a1);

	Vec2f[]@ areas; // pairs
	this.get("button_areas", @areas);
	if (areas is null || areas.size() % 2 != 0) return;

	this.set_u8("button_index_hover", 255); // reset hover index
	Vec2f mpos = getControls().getInterpMouseScreenPos();
	this.set_Vec2f("mouse_pos", mpos);

	for (int i = 0; i < areas.size(); i += 2)
	{
		Vec2f tl = areas[i];
		Vec2f br = areas[i + 1];

		if (isInArea(mpos, tl, br))
		{
			this.set_u8("button_index_hover", i / 2);
			break;
		}
	}
}

void TerminalTick(CBlob@ this, CInventory@ inv)
{
	CBlob@ local = getLocalPlayerBlob();
	if (isClient())
	{
		if (local is null || local.getDistanceTo(this) > this.getRadius()
			|| (local.isKeyPressed(key_left) || local.isKeyPressed(key_right)
			|| local.isKeyPressed(key_up) || local.isKeyPressed(key_down)
			|| local.isKeyJustPressed(key_use) || local.isKeyJustPressed(key_pickup)))
		{
			CloseTerminal(this, true);
		}
	}

	if (isClient() && this.getTickSinceCreated() % chart_update_rate == 0)
	{
		UpdateChart(this);
	}

	u8 temp_mode = this.get_u8("temp_mode");
	f32 heat = this.get_f32("heat");

	// render update
	f32 rounded_heat = Maths::Round(heat * 10) / 10.0f;
	string heat_text = formatTemp(rounded_heat, temp_mode);
	this.set_f32("rounded_heat", rounded_heat);
	this.set_string("heat_text", heat_text);

	// debug
	//if (isClient() && local !is null && local.isOverlapping(this) && local.isKeyJustPressed(key_eat))
	//{
	//	CBitStream params;
	//	params.write_u16(local.getNetworkID());
	//	this.SendCommand(this.getCommandID("request_terminal_for_local"), params);
	//}

	if (this.getTickSinceCreated() % material_update_rate == 0)
		UpdateMaterialsCount(this, inv);

	if (this.getTickSinceCreated() % attached_update_rate == 0)
	{
		string[]@ attached;
		this.get("attached", @attached);

		if (attached !is null)
		{
			bool sync = false;
			for (int i = 0; i < attached.size(); i++)
			{	
				bool remove = false;
				bool p_null = false;

				CPlayer@ p = getPlayerByUsername(attached[i]);
				if (p is null)
				{
					remove = true;
					p_null = true;
				}

				if (!p_null)
				{
					CBlob@ blob = p.getBlob();
					if (blob is null || blob.getDistanceTo(this) > this.getRadius())
					{
						remove = true;
					}
				}

				if (remove)
				{
					if (isServer())
					{
						attached.removeAt(i);
						sync = true;
					}

					if (!p_null && p.isMyPlayer())
					{
						CloseTerminal(this);
						break;
					}
				}
			}

			if (sync)
			{
				server_Sync(this);
			}
		}
	}

	#ifndef STAGING
	MouseHandlerTick(this);
	#endif
}

void SetButtons(CBlob@ this, bool register = true)
{
	u16 net_id = this.getNetworkID();
	Vec2f tl = this.get_Vec2f("terminal_tl");
	Vec2f br = this.get_Vec2f("terminal_br");
	Vec2f material_button_dim = Vec2f(terminal_size.x / row_items, terminal_size.y / 10) - Vec2f(1.0f - 1.0f / materials.size(), 0);
	Vec2f screen_center = getDriver().getScreenCenterPos();
	Vec2f slider_pos = this.get_Vec2f("slider_track_pos"); // breakpoint
	Vec2f slider_dim = this.get_Vec2f("slider_track_dim");

	if (register)
	{
		// materials
		for (u8 i = 0; i < materials.size(); i++)
		{
			Vec2f pos_material = Vec2f(screen_center.x - terminal_size.x / 2 + (i * material_button_dim.x), screen_center.y - terminal_size.y / 2);

			Button@ button = Button(net_id, materials[i], material_icons[i], 0, Vec2f(16, 16), 1, Vec2f(0,4), material_tooltips[i], pos_material, material_button_dim, "", SColor(255, 100, 155, 255));
			registerButton(this, button);
		}

		// temp mode switchers at left side
		Vec2f tsize = terminal_size;
		Vec2f pos = Vec2f(screen_center.x - tsize.x / 2, screen_center.y - tsize.y / 2 + chart_size.y + tsize.y * 0.2f - 8);
		Vec2f size = Vec2f(material_button_dim.x / 2, screen_center.y + terminal_size.y / 2 - pos.y - footer_height);

		{Button@ button = Button(net_id, "Celsius", "$temp0$", 0, Vec2f(16, 16), 1, Vec2f_zero, "Measure as Celsius", pos, size, "set_temp_mode", SColor(255, 100, 155, 255));
		button.customData = 2;
		registerButton(this, @button);}

		{Button@ button = Button(net_id, "Fahrenheit", "$temp1$", 0, Vec2f(16, 16), 1, Vec2f_zero, "Measure as Fahrenheit", pos + Vec2f(size.x, 0), size, "set_temp_mode", SColor(255, 100, 155, 255));
		button.customData = 1;
		registerButton(this, @button);}

		{Button@ button = Button(net_id, "Kelvin", "$temp2$", 0, Vec2f(16, 16), 1, Vec2f_zero, "Measure as Kelvin", pos + Vec2f(size.x * 2, 0), size, "set_temp_mode", SColor(255, 100, 155, 255));
		button.customData = 0;	
		registerButton(this, @button);}

		// utilities
		{Button@ button = Button(net_id, "Refrigerant", "$refrigerant_icon$", 0, Vec2f(16, 16), 1, Vec2f_zero, "Set Refrigerant", pos + Vec2f(size.x * 3, 0), size, "interact_utility", SColor(255, 100, 155, 255));
		button.customData = 1;
		registerButton(this, @button);}

		{Button@ button = Button(net_id, "Catalyzer", "$catalyzer_icon$", 0, Vec2f(16, 16), 1, Vec2f_zero, "Set Catalyzer", pos + Vec2f(size.x * 4, 0), size, "interact_utility", SColor(255, 100, 155, 255));
		button.customData = 0;
		registerButton(this, @button);}

		{Button@ button = Button(net_id, "Take Mithril", "$mithril_icon$", 0, Vec2f(16, 16), 1, Vec2f_zero, "Take Mithril", pos + Vec2f(size.x * 5, 0), size, "interact_fuel", SColor(255, 100, 155, 255));
		button.customData = 0;
		registerButton(this, @button);}

		{Button@ button = Button(net_id, "Add Mithril", "$mithril_icon$", 0, Vec2f(16, 16), 1, Vec2f_zero, "Add Mithril", pos + Vec2f(size.x * 6, 0), size, "interact_fuel", SColor(255, 100, 155, 255));
		button.customData = 1;
		registerButton(this, @button);}

		{Button@ button = Button(net_id, "Take Enriched", "$enriched_icon$", 0, Vec2f(16, 16), 1, Vec2f_zero, "Take Enriched Mithril", pos + Vec2f(size.x * 7, 0), size, "interact_fuel", SColor(255, 100, 155, 255));
		button.customData = 2;
		registerButton(this, @button);}

		{Button@ button = Button(net_id, "Add Enriched", "$enriched_icon$", 0, Vec2f(16, 16), 1, Vec2f_zero, "Add Enriched Mithril", pos + Vec2f(size.x * 8, 0), size, "interact_fuel", SColor(255, 100, 155, 255));
		button.customData = 3;
		registerButton(this, @button);}

		{Button@ button = Button(net_id, "Turn on/off", "", 0, Vec2f(16, 16), 1, Vec2f_zero, "Turn on", pos + Vec2f(terminal_size.x - size.x * 3, 0), size * 2, "switch", SColor(255, 100, 155, 255));
		registerButton(this, @button);}
	}
	else // update positions
	{
		u8 current_material_producing_index = 255;
		f32 heat = this.get_f32("heat");

		material_button_dim.y = Maths::Min(material_button_dim.y, br.y - tl.y);

		Button@[]@ buttons;
		if (!this.get("buttons", @buttons)) return;
		if (buttons is null) return;
		f32 factor = this.get_f32("render_factor");

		// materials
		for (u8 i = 0; i < row_items; i++)
		{
			Button@ button = buttons[i];
			if (button is null) continue;

			Vec2f scaled_size = (button.size_const * factor);
			Vec2f pos_material = Vec2f(tl.x + (i * scaled_size.x), tl.y);

			button.pos = pos_material;
			button.icon_scale = button.icon_scale_const * factor;
			button.icon_offset = Vec2f(34, -2);
			button.size = scaled_size;
		}

		// temp mode switchers at left side
		Vec2f tsize = br - tl;
		f32 side_height_factor = Maths::Max(0, factor - 0.9f) / 0.1f;
		Vec2f pos = Vec2f(tl.x+2, tl.y + chart_size.y * side_height_factor + (br.y - tl.y) * 0.2f - 8);
		Vec2f size = Vec2f(material_button_dim.x / 2, br.y - pos.y - footer_height) * side_height_factor;

		bool has_catalyzer = this.get_bool("catalyzer");
		bool has_refrigerant = this.get_bool("refrigerant");

		u8 temp_mode = this.get_u8("temp_mode");
		bool enabled = this.get_bool("enabled");

		{Button@ button = buttons[materials.size() + 9]; // turn on / off
		button.pos = Vec2f_lerp(pos, pos + Vec2f(tsize.x - size.x * 3 - 2, 0), side_height_factor);
		button.size = Vec2f(size.x * 3, size.y);
		button.color = enabled ? SColor(255, 55, 255, 55) : SColor(255, 255, 55, 55);
		button.tooltip = enabled ? "Turn off" : "Turn on";
		button.icon_scale = button.icon_scale_const * factor;}

		//take mithril and enriched
		{Button@ button = buttons[materials.size() + 8]; // add enriched
		button.pos = Vec2f_lerp(pos, pos + Vec2f(size.x * 8, 0), side_height_factor);
		button.size = size;
		button.icon_scale = button.icon_scale_const * factor;}

		{Button@ button = buttons[materials.size() + 7]; // take enriched
		button.pos = Vec2f_lerp(pos, pos + Vec2f(size.x * 7, 0), side_height_factor);
		button.size = size;
		button.icon_color.setRed(125);
		button.icon_color.setGreen(125);
		button.icon_color.setBlue(125);
		button.icon_scale = button.icon_scale_const * factor;}

		{Button@ button = buttons[materials.size() + 6]; // add mithril
		button.pos = Vec2f_lerp(pos, pos + Vec2f(size.x * 6, 0), side_height_factor);
		button.size = size;
		button.icon_scale = button.icon_scale_const * factor;}

		{Button@ button = buttons[materials.size() + 5]; // take mithril
		button.pos = Vec2f_lerp(pos, pos + Vec2f(size.x * 5, 0), side_height_factor);
		button.size = size;
		button.icon_color.setRed(125);
		button.icon_color.setGreen(125);
		button.icon_color.setBlue(125);
		button.icon_scale = button.icon_scale_const * factor;}

		{Button@ button = buttons[materials.size() + 4]; // Catalyzer
		button.pos = Vec2f_lerp(pos, pos + Vec2f(size.x * 4, 0), side_height_factor);
		button.size = size;
		button.icon_color.setRed(255 * (has_catalyzer ? 1 : 0.25f));
		button.icon_color.setGreen(255 * (has_catalyzer ? 1 : 0.25f));
		button.icon_color.setBlue(255 * (has_catalyzer ? 1 : 0.25f));
		button.icon_offset = has_catalyzer ? Vec2f(9, 16) * factor : Vec2f(1, 0);
		button.tooltip = has_catalyzer ? "Remove Catalyzer" : "Add Catalyzer";
		button.icon_scale = button.icon_scale_const * factor * (has_catalyzer ? 1.5f : 1);}

		{Button@ button = buttons[materials.size() + 3]; // Refrigerant
		button.pos = Vec2f_lerp(pos, pos + Vec2f(size.x * 3, 0), side_height_factor);
		button.size = size;
		button.icon_color.setRed(255 * (has_refrigerant ? 1 : 0.25f));
		button.icon_color.setGreen(255 * (has_refrigerant ? 1 : 0.25f));
		button.icon_color.setBlue(255 * (has_refrigerant ? 1 : 0.25f));
		button.icon_offset = has_refrigerant ? Vec2f(8, 16) * factor : Vec2f(0, 0);
		button.tooltip = has_refrigerant ? "Remove Refrigerant" : "Add Refrigerant";
		button.icon_scale = button.icon_scale_const * factor * (has_refrigerant ? 1.5f : 1);}
		
		{Button@ button;
		@button = buttons[materials.size() + 2]; // Kelvin
		button.pos = Vec2f_lerp(pos, pos + Vec2f(size.x * 2, 0), side_height_factor);
		button.size = size;
		button.icon_offset = temp_mode == 0 ? Vec2f(8, 15) * factor : Vec2f(0, 0);
		button.icon_scale = button.icon_scale_const * side_height_factor * (temp_mode == 0 ? 1.5f : 1);}
		
		{Button@ button = buttons[materials.size() + 1]; // Fahrenheit
		button.pos = Vec2f_lerp(pos, pos + Vec2f(size.x, 0), side_height_factor);
		button.size = size;
		button.icon_offset = temp_mode == 1 ? Vec2f(8, 15) * factor : Vec2f(0, 0);
		button.icon_scale = button.icon_scale_const * side_height_factor * (temp_mode == 1 ? 1.5f : 1);}

		{Button@ button = buttons[materials.size()]; // Celsius
		button.pos = Vec2f_lerp(pos, pos, side_height_factor);
		button.size = size;
		button.icon_offset = temp_mode == 2 ? Vec2f(8, 15) * factor : Vec2f(0, 0);
		button.icon_scale = button.icon_scale_const * side_height_factor * (temp_mode == 2 ? 1.5f : 1);}
	}
}

// updates every frame even if factor is > 0, couldn't fix tl/br being at 0,0 before opening the terminal
void UpdateTerminalSize(CBlob@ this)
{
	if (!isClient()) return;
	
	CRules@ rules = getRules();
	if (rules is null) return;
	if (!rules.exists("terminal_id")) return;

	u16 id = rules.get_u16("terminal_id");
	bool closing = id != this.getNetworkID();
	f32 factor = this.get_f32("render_factor");
	f32 delta = getRenderDeltaTime();
	f32 lerp_close_with_delta = 60 * delta * lerp_close;
	f32 lerp_open_with_delta = 60 * delta * lerp_open;

	Vec2f screen_center = getDriver().getScreenCenterPos();
	Vec2f size = terminal_size;

	if (closing) factor = Maths::Clamp(Maths::Lerp(factor, 0.0f, lerp_close_with_delta), 0.0f, 1.0f);
	else factor = Maths::Clamp(Maths::Lerp(factor, 1.0f, lerp_open_with_delta), 0.0f, 1.0f);
	this.set_f32("render_factor", factor);

	Vec2f tl = this.get_Vec2f("terminal_tl");
	Vec2f br = this.get_Vec2f("terminal_br");

	// open terminal horizontally first half, then vertically, and close reversively
	if (closing)
	{
		Vec2f target_tl = screen_center;
		Vec2f target_br = screen_center;

		tl.x = Maths::Lerp(tl.x, target_tl.x, lerp_close_with_delta);
		br.x = Maths::Lerp(br.x, target_br.x, lerp_close_with_delta);

		tl.y = Maths::Lerp(tl.y, target_tl.y, lerp_close_with_delta);
		br.y = Maths::Lerp(br.y, target_br.y, lerp_close_with_delta);
	}
	else
	{
		Vec2f target_tl = screen_center - size / 2;
		Vec2f target_br = screen_center + size / 2;

		tl.x = Maths::Lerp(tl.x, target_tl.x, lerp_open_with_delta);
		br.x = Maths::Lerp(br.x, target_br.x, lerp_open_with_delta);

		if (tl.x <= target_tl.x + 1)
		{
			tl.y = Maths::Lerp(tl.y, target_tl.y, lerp_open_with_delta);
			br.y = Maths::Lerp(br.y, target_br.y, lerp_open_with_delta);
		}
	}
	
	tl.x = Maths::Floor(tl.x);
	tl.y = Maths::Floor(tl.y);
	br.x = Maths::Floor(br.x);
	br.y = Maths::Floor(br.y);

	this.set_Vec2f("terminal_tl", tl);
	this.set_Vec2f("terminal_br", br);
}

void DrawTerminal(CBlob@ this)
{
	#ifdef STAGING
	MouseHandlerTick(this);
	#endif

	CRules@ rules = getRules();
	if (rules is null) return;
	if (!rules.exists("terminal_id"))
		rules.set_u16("terminal_id", 0);

	u16 id = rules.get_u16("terminal_id");
	bool closing = id != this.getNetworkID();

	UpdateTerminalSize(this);
	f32 factor = this.get_f32("render_factor");
	u8 alpha = u8(255 * factor);
	
	if (alpha >= 254) alpha = 255;
	else if (alpha <= 1) alpha = 0;
	if (alpha == 0) return;

	Vec2f screen_center = getDriver().getScreenCenterPos();
	Vec2f size = terminal_size;

	SetButtons(this, false);
	DrawAttached(this, alpha);

	Vec2f tl = this.get_Vec2f("terminal_tl");
	Vec2f br = this.get_Vec2f("terminal_br");
	
	Button@[]@ buttons;
	if (!this.get("buttons", @buttons)) return;
	if (buttons is null) return;
	
	f32 heat = this.get_f32("heat");
	u16 mithril_count = this.get_u16("mithril_count");
	u16 enriched_count = this.get_u16("enriched_count");
	u16 wilmet_count = this.get_u16("wilmet_count");
	u8 current_resource_generation = this.get_u8("current_resource_generation");
	
	u8 button_index_hover = this.get_u8("button_index_hover");
	bool a1 = this.get_bool("buttons_a1");
	Vec2f mpos = this.get_Vec2f("mouse_pos");

	// draw background canvas
	Vec2f extra = Vec2f(2, 2);
	Vec2f tl_extra = tl - extra;
	Vec2f br_extra = br + extra;
	GUI::DrawPane(tl_extra, br_extra, SColor(alpha, 100, 155, 255));

	// draw canvas
	GUI::DrawPane(tl, br, SColor(alpha, 32, 116, 167));
	DrawChart(this);
	DrawMaterialsCount(this);

	// draw heat slider track
	const Vec2f material_button_dim = Vec2f((terminal_size.x / row_items) * factor, (terminal_size.y / 10) * factor) - Vec2f(1, 0);
	Vec2f track_dim = Vec2f((br.x - tl.x), material_button_dim.y * 0.75f * factor);
	Vec2f track_pos = tl + Vec2f(0, material_button_dim.y);
	Vec2f slider_dim = Vec2f(material_button_dim.x / 2, track_dim.y);
	Vec2f slider_dim_thin = Vec2f(8, slider_dim.y);

	this.set_Vec2f("slider_track_pos", track_pos);
	this.set_Vec2f("slider_track_dim", track_dim);

	GUI::DrawPane(track_pos, track_pos + track_dim, SColor(alpha, 100, 155, 255));

	if (!v_fastrender)
	{
		// draw decorator segments for negative heat
		for (int i = 0; i < track_dim.x / 2; i += 8)
		{
			Vec2f pos = track_pos + Vec2f(i, 0);
			GUI::DrawRectangle(pos, pos + Vec2f(2, track_dim.y / (i%40!=0?4:3)), SColor(alpha, 0, 0, 0));
		}

		// draw decorator segments for positive heat with lesser gap
		for (int i = 0; i < track_dim.x / 2 - 4; i += 4)
		{
			Vec2f pos = track_pos + Vec2f(i + track_dim.x / 2, 0);
			GUI::DrawRectangle(pos, pos + Vec2f(2, track_dim.y / (i%20!=0?4:3)), SColor(alpha, 0, 0, 0));
		}
	}

	// material generation ranges
	for (int i = 0; i < materials.size(); i++)
	{
		f32[] area = material_generation_ranges[i];
		f32 min = area[0];
		f32 max = area[1];
		f32 half_track = track_dim.x / 2;

		f32 min_factor = min < 0
						? Maths::Abs(min) / Maths::Abs(min_temp_c)
						: min / max_temp_c;
		
		f32 max_factor = max < 0
						? Maths::Abs(max) / Maths::Abs(min_temp_c)
						: max / max_temp_c;
		
		f32 min_x = min < 0
					? -half_track * min_factor
					: half_track * min_factor;

		f32 max_x = max < 0
					? -half_track * max_factor
					: half_track * max_factor;

		GUI::DrawPane(track_pos + Vec2f(half_track + min_x, track_dim.y - 2), track_pos + Vec2f(half_track + max_x, track_dim.y + 8), SColor(alpha, 255, 0, 255));
	}

	// danger zones
	Vec2f danger_zone_dim = Vec2f(danger_zone_width, track_dim.y);
	Vec2f danger_zone_pos_left = track_pos;
	Vec2f danger_zone_pos_right = track_pos + Vec2f(track_dim.x - danger_zone_dim.x, 0);
	GUI::DrawPane(danger_zone_pos_left, danger_zone_pos_left + danger_zone_dim, SColor(alpha, 55, 200, 55)); // left radiation
	GUI::DrawPane(track_pos + Vec2f(track_dim.x * 5 / 6, 0), track_pos + Vec2f(track_dim.x, danger_zone_dim.y), SColor(alpha, 55, 200, 55)); // right radiation
	GUI::DrawPane(danger_zone_pos_right, danger_zone_pos_right + danger_zone_dim, SColor(alpha, 255, 155, 0)); // right explosion
	
	// left danger_mithril
	f32 danger_mithril_scale = 0.66f * factor;
	GUI::DrawIconByName("$danger_mithril$", track_pos + Vec2f(danger_zone_dim.x * danger_mithril_scale - danger_zone_dim.x / 2 + 2, -5), danger_mithril_scale, danger_mithril_scale, 0, SColor(alpha, 255, 255, 255));

	// right danger_mithril
	f32 danger_mithril_scale_right = 0.5f * factor;
	GUI::DrawIconByName("$danger_mithril$", track_pos + Vec2f(track_dim.x - danger_zone_dim.x * danger_mithril_scale_right - danger_zone_dim.x / 2 - 35, -1), danger_mithril_scale_right, danger_mithril_scale_right, 0, SColor(alpha, 255, 255, 255));

	// right danger_explode
	f32 danger_explode_scale = 0.75f * factor;
	GUI::DrawIconByName("$danger_explode$", track_pos + Vec2f(track_dim.x - danger_zone_dim.x*danger_explode_scale, 0) - Vec2f(4,6), danger_explode_scale, danger_explode_scale, 0, SColor(alpha, 255, 255, 255));
	
	GUI::SetFont("default");

	// draw target heat text
	f32 target_heat_factor = this.get_f32("target_heat_factor");
	string target_heat_text = this.get_string("target_heat_text");
	Vec2f target_slider_pos = track_pos + Vec2f(track_dim.x / 2, 0) + Vec2f((target_heat_factor * track_dim.x) - 4, (track_dim.y - slider_dim.y) / 2);

	GUI::DrawPane(target_slider_pos + Vec2f(0, slider_dim_thin.y / 2), target_slider_pos + Vec2f(slider_dim_thin.x, slider_dim_thin.y), SColor(alpha, 255, 0, 0));
	GUI::DrawTextCentered(target_heat_text, target_slider_pos + slider_dim_thin / 2 + Vec2f(-2, slider_dim_thin.y + 12), SColor(alpha, 255, 255, 255));

	// draw heat slider on the track
	f32 heat_factor = heat >= 0 ? (heat / max_temp_c) * 0.5f : -(Maths::Abs(heat) / Maths::Abs(min_temp_c)) * 0.5f;
	heat_factor = Maths::Clamp(heat_factor, -0.5f, 0.5f); // from 0 to 1
	Vec2f slider_pos = track_pos + Vec2f(track_dim.x / 2, 0) + Vec2f((heat_factor * track_dim.x) - 4, (track_dim.y - slider_dim.y) / 2);

	GUI::DrawPane(slider_pos, slider_pos + slider_dim_thin, SColor(alpha, 255, 0, 0));

	// heat text
	u8 temp_mode = this.get_u8("temp_mode");
	f32 rounded_heat = this.get_f32("rounded_heat");
	string heat_text = this.get_string("heat_text");
	GUI::DrawTextCentered(heat_text, slider_pos + slider_dim_thin / 2 + Vec2f(-2, slider_dim_thin.y - 2), SColor(alpha, 255, 255, 255));
	
	for (u8 i = 0; i < buttons.size(); i++)
	{
		Button@ button = buttons[i];
		if (button is null) continue;

		button.active = alpha == 255;
		if (i < materials.size()) button.color = button.id == current_resource_generation ? SColor(alpha, 255, 0, 255) : SColor(alpha, 100, 155, 255);
		button.render(alpha, button.id == button_index_hover, a1);
	}

	// slider track hover temperature
	if (isInArea(mpos, track_pos, track_pos + track_dim))
	{
		Vec2f hover_pos = mpos + Vec2f(48, 24);
		SColor bg = SColor(alpha, 0, 0, 0);
		SColor tx = SColor(alpha, 255, 255, 255);
		
		// mid to left - negative from 0 to min_temp_c
		// mid to right - positive from 0 to max_temp_c
		f32 temperature_at_mouse = (mpos.x < screen_center.x) 
			? Maths::Lerp(min_temp_c, 0.0f, (mpos.x - tl.x) / (screen_center.x - tl.x)) 
			: Maths::Lerp(0.0f, max_temp_c, (mpos.x - screen_center.x) / (br.x - screen_center.x));
		temperature_at_mouse = Maths::Round(temperature_at_mouse * 10) / 10.0f;
		
		string hover_text = ""+(temp_mode == 0 ? temperature_at_mouse + 273.1f : temp_mode == 1 ? (temperature_at_mouse * 9.0f / 5.0f) + 32 : temperature_at_mouse) + "°" + (temp_mode == 0 ? "K" : temp_mode == 1 ? "F" : "C");
		Vec2f hover_text_size;
		GUI::GetTextDimensions(hover_text, hover_text_size);

		// draw rectangle arrow on the track
		f32 r_arrow_width = 2;
		Vec2f r_arrow_tl = Vec2f(mpos.x - r_arrow_width / 2, track_pos.y);
		Vec2f r_arrow_br = Vec2f(mpos.x + r_arrow_width / 2, track_pos.y + track_dim.y);
		GUI::DrawRectangle(r_arrow_tl, r_arrow_br, SColor(alpha, 255, 0, 0));

		Vec2f hover_text_pos = hover_pos - Vec2f(hover_text_size.x / 2 - 1, hover_text_size.y / 2 - 1);
		GUI::DrawPane(hover_text_pos - Vec2f(0, 2), hover_text_pos + hover_text_size + Vec2f(2, 2), bg);
		GUI::DrawText(hover_text, hover_text_pos, tx);
	}
}

void UpdateChart(CBlob@ this)
{
	if (!isClient()) return;

	f32[]@ chart_data;
	if (!this.get("chart_data", @chart_data))
	{
		f32[] empty;
		this.set("chart_data", @empty);
	}

	if (!this.get("chart_data", @chart_data)) return;
	if (chart_data is null) return;

	f32 temp = this.get_f32("heat");
	if (temp > max_temp_c) temp = max_temp_c;
	else if (temp < min_temp_c) temp = min_temp_c;
	
	// debug randomize from min to max
	//temp = XORRandom(max_temp_c - min_temp_c) + min_temp_c;
	// debug randomize from 0 to max
	//temp = XORRandom(max_temp_c);
	// debug randomize from 0 to min
	//temp = -XORRandom(Maths::Abs(min_temp_c));

	if (chart_data.size() > chart_steps) chart_data.removeAt(0);
	chart_data.push_back(temp);

	u16 mithril_count = this.get_u16("mithril_count");
	u16 enriched_count = this.get_u16("enriched_count");
	u8 temp_mode = this.get_u8("temp_mode");
	bool has_refrigerant = this.get_bool("refrigerant");

	f32 mithril_heat = this.get_f32("mithril_heat");
	f32 enriched_heat = this.get_f32("enriched_heat");

	u8 current_material_producing_index = this.get_u8("current_resource_generation");
	f32 producing_factor = this.get_f32("current_resource_precision");

	string mithril_text = mithril_count + " M > " + formatTemp(mithril_heat, temp_mode);
	string enriched_text = enriched_count + " EM > " + formatTemp(enriched_heat, temp_mode);
	string producing_text = "";
	string explosion_text = "Overload > "+(Maths::Round(this.get_f32("explosion_factor") * 1000) / 10.0f + "%");

	if (current_material_producing_index < materials.size())
	{
		producing_text = int(ratios[current_material_producing_index] * producing_factor)+" "+material_names[current_material_producing_index] + " at " + (Maths::Round(producing_factor * 1000.0f) / 10.0f) + "%";
	}
	else producing_text = "Incorrect condition";

	this.set_string("mithril_text", mithril_text);
	this.set_string("enriched_mithril_text", enriched_text);
	this.set_string("producing_text", producing_text);
	this.set_string("explosion_text", explosion_text);
}

string formatTemp(f32 heat, u8 mode) {
	f32 rounded = Maths::Round(heat * 10) / 10.0f;
	return (mode == 0 ? (rounded + 273.1f) + " °K" :
	        mode == 1 ? (rounded * 9.0f / 5.0f + 32.0f) + " °F" :
	                    rounded + " °C");
}

void DrawChart(CBlob@ this)
{
	f32[]@ chart_data;
	if (!this.get("chart_data", @chart_data) || chart_data is null) return;

	f32 rfactor = this.get_f32("render_factor");
	rfactor = Maths::Max(0, rfactor - 0.9f) / 0.1f;
	if (rfactor <= 0.0f) return;

	f32 heat = this.get_f32("heat");
	if (heat < min_temp_c) heat = min_temp_c;
	else if (heat > max_temp_c) heat = max_temp_c;

	Vec2f tl = this.get_Vec2f("terminal_tl");
	Vec2f br = this.get_Vec2f("terminal_br");

	Vec2f slider_pos = this.get_Vec2f("slider_track_pos");
	Vec2f slider_dim = this.get_Vec2f("slider_track_dim");
	Vec2f chart_dim = chart_size;
	Vec2f chart_pos = slider_pos + Vec2f(0, slider_dim.y * rfactor) + Vec2f(2, 0);
	Vec2f chart_pos_end = (chart_pos + Vec2f(chart_dim.x, chart_dim.y * rfactor)) - Vec2f(6, 0);

	SColor canvas_color = chart_canvas_color;
	canvas_color.setAlpha(u8(rfactor * 255));
	GUI::DrawPane(chart_pos, chart_pos_end, canvas_color);
	SColor col_decorator = SColor(u8(rfactor * 255), 255, 255, 255);
	
	if (!v_fastrender)
	{
		f32 offsetx = 1;
		f32 offsety = -5;
		const int gap = 8;
		for (int i = Maths::Floor(Maths::Abs(offsety * gap) / gap) * gap / 4; i < chart_size.y * rfactor; i += gap)
		{
			i -= i % gap;
			GUI::DrawRectangle(chart_pos + Vec2f(offsetx, offsety) + Vec2f(0, i), chart_pos + Vec2f(offsetx + 4 + (i % (gap * 5) == 0 ? 4 : 0), offsety + i + 1), col_decorator);
		}
	}

	f32 zero_heat_y = chart_pos.y + (1.0f - ((0 - min_temp_c) / (max_temp_c - min_temp_c))) * chart_size.y * rfactor;
	GUI::DrawLine2D(Vec2f(chart_pos.x, zero_heat_y), Vec2f(chart_pos_end.x, zero_heat_y), col_decorator);

	u32 chart_steps = chart_data.size();
	f32 x_step = chart_size.x / chart_steps;
	f32 y_range = max_temp_c - min_temp_c;

	for (u32 i = 0; i < chart_steps; i++)
	{
		f32 temp = Maths::Clamp(chart_data[i], min_temp_c, max_temp_c);
		f32 factor = (temp - min_temp_c) / y_range;

		Vec2f pos = chart_pos + Vec2f(i * x_step, (1.0f - factor) * chart_size.y * rfactor);
		Vec2f pos_next = (i > 0)
			? chart_pos + Vec2f((i - 1) * x_step, (1.0f - ((chart_data[i - 1] - min_temp_c) / y_range)) * chart_size.y * rfactor)
			: pos;

		SColor col = SColor(u8(rfactor * 255), u8(255 * factor), u8(heat < 0 ? 255 * (1.0f - factor) * 0.5f : 255 * (1.0f - factor)), u8(heat < 0 ? 255 * (1.0f-factor) * 0.75f : 255 * factor / 2));
		GUI::DrawLine2D(pos, pos_next, col);
	}
}

void DrawMaterialsCount(CBlob@ this)
{
	// draw a row of materials (mithril, enriched mithril)
	f32 factor = this.get_f32("render_factor");
	factor = (factor - 0.9f) / 0.1f;
	if (factor <= 0.0f) return;

	Vec2f tl = this.get_Vec2f("terminal_tl");
	Vec2f br = this.get_Vec2f("terminal_br");
	Vec2f screen_center = getDriver().getScreenCenterPos();

	Vec2f material_button_dim = Vec2f(terminal_size.x / row_items, terminal_size.y / 10) - Vec2f(1.0f - 1.0f / materials.size(), 0);
	Vec2f pos = Vec2f(tl.x + 7, br.y - footer_height);
	Vec2f size = Vec2f(material_button_dim.x / 2, material_button_dim.y) * factor;
	
	GUI::DrawPane(Vec2f(tl.x, br.y - 28), Vec2f(br.x, br.y), chart_canvas_color);
	GUI::SetFont("menu");

	string mithril_text = this.get_string("mithril_text");
	string enriched_mithril_text = this.get_string("enriched_mithril_text");
	string producing_text = this.get_string("producing_text");
	string explosion_text = this.get_string("explosion_text");

	GUI::DrawText(mithril_text, pos, SColor(255, 255, 255, 255));
	GUI::DrawText(enriched_mithril_text, pos + Vec2f(footer_text_gap, 0), SColor(255, 255, 255, 255));
	GUI::DrawText(producing_text, pos + Vec2f(footer_text_gap * 2, 0), SColor(255, 255, 255, 255));
	GUI::DrawText(explosion_text, pos + Vec2f(footer_text_gap * 3, 0), SColor(255, 255, 255, 255));
}

void DrawAttached(CBlob@ this, u8 alpha)
{
	Vec2f tl = this.get_Vec2f("terminal_tl");
	Vec2f br = this.get_Vec2f("terminal_br");

	GUI::SetFont("menu");

	f32 max_width = 0;
	f32 height = 0;

	string[]@ attached;
	if (!this.get("attached", @attached)) return;
	if (attached is null) return;
	
	Vec2f sc = getDriver().getScreenCenterPos();

	if (attached.size() == 0) return;
	for (int i = 0; i < attached.size(); i++)
	{
		string name = attached[i];
		if (name != "")
		{
			Vec2f text_size;
			GUI::GetTextDimensions(name, text_size);
			if (text_size.x > max_width) max_width = text_size.x;
			height += text_size.y;
		}
	}

	Vec2f tl_attached = Vec2f(tl.x - max_width - 8.0f, tl.y - 2);
	Vec2f br_attached = Vec2f(tl.x, tl.y + height + 2);
	GUI::DrawPane(tl_attached, br_attached, SColor(alpha, 75, 75, 75));

	for (int i = 0; i < attached.size(); i++)
	{
		string name = attached[i];
		if (name != "")
		{
			Vec2f pos = Vec2f(tl_attached.x + 2.0f, tl_attached.y + 2.0f + i * 16.0f);
			GUI::DrawText(name, pos - Vec2f(1,1), SColor(alpha, 255, 255, 255));
		}
	}
}

void ResetAttached(CBlob@ this)
{
	string[] empty;
	this.set("attached", @empty);
}

void AttachUsername(CBlob@ this, CPlayer@ target)
{
	if (!isServer()) return;
	if (target is null || target.getBlob() is null || target.isBot()) return;

	string[]@ attached;
	if (!this.get("attached", @attached)) ResetAttached(this);
	if (!this.get("attached", @attached)) return;

	if (attached.find(target.getUsername()) == -1)
	{
		attached.push_back(target.getUsername());
		server_Sync(this);
	}
}

void server_Sync(CBlob@ this)
{
    if (!isServer()) return;

    CBitStream params;
	params.write_f32(this.get_f32("heat"));
	params.write_u8(this.get_u8("current_resource_generation"));
	params.write_f32(this.get_f32("current_resource_precision"));
	params.write_string(this.get_string("password"));
	params.write_bool(this.get_bool("enabled"));
	params.write_bool(this.get_bool("sabotage"));
	params.write_u32(this.get_u32("sabotage_time"));
	params.write_bool(this.get_bool("codebreaking"));
	params.write_u32(this.get_u32("codebreaking_time"));
	params.write_bool(this.get_bool("catalyzer"));
	params.write_bool(this.get_bool("refrigerant"));
	params.write_u8(this.get_u8("temp_mode"));

	string[]@ attached;
	if (!this.get("attached", @attached))
	{
		warn("Nuclear Reactor: attached array not found!");
		ResetAttached(this);
		return;
	}

	params.write_u8(attached.size());
	for (int i = 0; i < attached.size(); i++)
	{
		params.write_string(attached[i]);
	}

    this.SendCommand(this.getCommandID("sync"), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("request_terminal_for_local"))
	{
		u16 id = params.read_u16();
		
		CBlob@ blob = getBlobByNetworkID(id);
		if (blob is null) return;

		CPlayer@ player = blob.getPlayer();
		if (player is null) return;

		if (isServer()) AttachUsername(this, player);
		SetTerminalForLocal(this, player.getNetworkID());
	}
	else if (cmd == this.getCommandID("remove_from_attached"))
	{
		if (!isServer()) return;
		u16 id = params.read_u16();

		CPlayer@ player = getPlayerByNetworkId(id);
		if (player is null) return;

		string[]@ attached;
		if (!this.get("attached", @attached)) return;
		if (attached is null) return;

		int index = attached.find(player.getUsername());
		if (index != -1)
		{
			attached.removeAt(index);
			server_Sync(this);
		}
	}
	else if (cmd == this.getCommandID("set_temp_mode"))
	{
		if (this.get_u32("set_temp_mode_cooldown") > getGameTime()) return;
		this.set_u32("set_temp_mode_cooldown", getGameTime() + 15);
		
		u16 id = params.read_u16();
		f32 mode = params.read_f32();

		CBlob@ local = getBlobByNetworkID(id);
		if (local !is null && local.isMyPlayer())
		{
			this.getSprite().PlaySound("Security_TurnOn", 0.25f, 0.95f + XORRandom(50) * 0.001f);
		}

		if (isClient())
		{
			UpdateHeat(this);
			UpdateMaterialsCount(this, this.getInventory());
		}

		this.set_u8("temp_mode", int(mode));
		if (isServer()) this.Sync("temp_mode", true);
	}
	else if (cmd == this.getCommandID("switch"))
	{
		if (this.get_u32("switch_cooldown") > getGameTime()) return;
		this.set_u32("switch_cooldown", getGameTime() + 150);

		u16 id = params.read_u16();

		bool enabled = this.get_bool("enabled");
		this.set_bool("enabled", !enabled);

		if (isClient())
		{
			this.set_string("override_anim", enabled ? "off" : "start");
			if (enabled) this.getSprite().PlaySound("PowerDown.ogg", 3.0f, 0.65f);
			else this.getSprite().PlaySound("PowerUp.ogg", 2.0f, 0.55f);
		}

		if (isServer())
			this.Tag("require_sync");
	}
	else if (cmd == this.getCommandID("interact_utility"))
	{
		if (this.get_u32("interact_utility_cooldown") > getGameTime()) return;
		this.set_u32("interact_utility_cooldown", getGameTime() + 15);	

		u16 id = params.read_u16();
		f32 customData = params.read_f32();
		if (customData > 1) return; // cancel

		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		string blobname = (customData == 0) ? "catalyzer" : "refrigerant";
		bool sync = false;

		bool has_blob = this.get_bool(blobname);
		bool caller_has_blob = caller.hasBlob(blobname, 1);

		if (has_blob)
		{
			if (isClient())
			{
				this.getSprite().PlaySound("LeverToggle.ogg", 1.0f, 1.25f);
			}
			
			if (isServer())
			{
				this.set_bool(blobname, false);

				CBlob@ blob = server_CreateBlob(blobname, caller.getTeamNum(), caller.getPosition());
				if (blob !is null)
				{
					caller.server_PutInInventory(blob);
				}
				sync = true;
			}
		}
		else
		{
			if (caller_has_blob)
			{
				this.set_bool(blobname, true);

				if (isClient())
				{
					this.getSprite().PlaySound("buttonclick.ogg", 1.0f, 1.0f);
				}

				if (isServer())
				{
					this.set_bool(blobname, true);
					caller.TakeBlob(blobname, 1);
					sync = true;
				}
			}
		}

		if (sync && isServer())
		{
			server_Sync(this);
		}
	}
	else if (cmd == this.getCommandID("interact_fuel"))
	{
		this.set_u32("interact_fuel_time", getGameTime());

		u16 id = params.read_u16();
		f32 customData = params.read_f32();
		if (customData > 3) return;

		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		string blobname = customData <= 1 ? "mat_mithril" : "mat_mithrilenriched";
		bool take = customData == 0 || customData == 2;

		if (take)
		{
			CInventory@ inv = this.getInventory();
			if (inv is null) return;
			if (inv.getCount(blobname) == 0) return;

			int mithril_amount = inv.getCount("mat_mithril");
			int enriched_amount = inv.getCount("mat_mithrilenriched");

			if (isClient())
			{
				this.getSprite().PlaySound("geiger"+(XORRandom(2)+1)+".ogg", 0.75f, 1.2f+XORRandom(100)*0.001f);
			}
			
			if (isServer())
			{
				CBlob@ blob = inv.getItem(blobname);
				if (blob !is null && blob.canBePutInInventory(caller))
				{
					this.server_PutOutInventory(blob);
					caller.server_PutInInventory(blob);
				}
			}

			UpdateChart(this);
		}
		else // add fuel
		{
			CInventory@ inv = caller.getInventory();
			if (inv is null) return;
			if (inv.getCount(blobname) == 0) return;

			int mithril_amount = inv.getCount("mat_mithril");
			int enriched_amount = inv.getCount("mat_mithrilenriched");

			if (isClient())
			{
				this.getSprite().PlaySound("geiger"+(XORRandom(2)+1)+".ogg", 0.75f, 1.2f+XORRandom(100)*0.001f);
			}

			if (isServer())
			{
				CBlob@ blob = inv.getItem(blobname);
				if (blob !is null && blob.canBePutInInventory(this))
				{
					caller.server_PutOutInventory(blob);
					this.server_PutInInventory(blob);
				}
			}

			UpdateChart(this);
		}
	}
	else if (cmd == this.getCommandID("sync"))
	{
		if (isClient())
		{
			f32 heat;
			u8 current_resource_generation;
			f32 current_resource_precision;
			string password;
			bool enabled;
			bool sabotage;
			u32 sabotage_time;
			bool codebreaking;
			u32 codebreaking_time;
			bool catalyzer;
			bool refrigerant;
			u8 temp_mode;
			int attached_count;

			if (!params.saferead_f32(heat)) return;
			if (!params.saferead_u8(current_resource_generation)) return;
			if (!params.saferead_f32(current_resource_precision)) return;
			if (!params.saferead_string(password)) return;
			if (!params.saferead_bool(enabled)) return;
			if (!params.saferead_bool(sabotage)) return;
			if (!params.saferead_u32(sabotage_time)) return;
			if (!params.saferead_bool(codebreaking)) return;
			if (!params.saferead_u32(codebreaking_time)) return;
			if (!params.saferead_bool(catalyzer)) return;
			if (!params.saferead_bool(refrigerant)) return;
			if (!params.saferead_u8(temp_mode)) return;
			if (!params.saferead_u8(attached_count)) return;

			this.set_f32("heat", heat);
			this.set_u8("current_resource_generation", current_resource_generation);
			this.set_f32("current_resource_precision", current_resource_precision);
			this.set_string("password", password);
			this.set_bool("enabled", enabled);
			this.set_bool("sabotage", sabotage);
			this.set_u32("sabotage_time", sabotage_time);
			this.set_bool("codebreaking", codebreaking);
			this.set_u32("codebreaking_time", codebreaking_time);
			this.set_bool("catalyzer", catalyzer);
			this.set_u8("temp_mode", temp_mode);
			this.set_bool("refrigerant", refrigerant);

			string[] new_attached;
			for (int i = 0; i < attached_count; i++)
			{
				string name = params.read_string();
				if (name != "") new_attached.push_back(name);
			}
			this.set("attached", @new_attached);
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
	else if (cmd == this.getCommandID("lock_console"))
	{
		u16 id = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(id);
		if (caller is null) return;

		this.set_bool("locked", true);
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
	}
}

void server_Irradiate(CBlob@ this, const f32 damage, const f32 radius)
{
	if (!isServer()) return;

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

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	if (!isClient()) return;
	
	CInventory@ inv = this.getInventory();
	if (inv is null) return;

	UpdateMaterialsCount(this, inv);
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	if (!isClient()) return;

	CInventory@ inv = this.getInventory();
	if (inv is null) return;

	UpdateMaterialsCount(this, inv);
}

void onDie(CBlob@ this)
{
	CRules@ rules = getRules();
	if (isClient()) CloseTerminal(this);
	
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
			bool has_catalyzer = this.get_bool("catalyzer");

			boom.setPosition(this.getPosition());
			boom.set_u8("boom_start", 0);
			boom.set_u8("boom_end", (0 + (this.get_f32("heat") + (has_catalyzer ? 1000.0f : 0.0f)) / reactor_explosion_reduction));
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
	return (this.getTeamNum() == forBlob.getTeamNum() || this.getTeamNum() >= 7)
		&& !this.getMap().rayCastSolid(forBlob.getPosition(), this.getPosition())
		&& !this.get_bool("locked");
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 1 + XORRandom(200) * 0.01f, 2 + XORRandom(5), XORRandom(100) * -0.00005f, true);
}