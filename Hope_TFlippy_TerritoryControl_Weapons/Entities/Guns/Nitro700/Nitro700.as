#include "GunCommon.as";

void onInit(CBlob@ this)
{
	GunSettings settings = GunSettings();

	//General
	settings.CLIP = 2; //Amount of ammunition in the gun at creation
	settings.TOTAL = 2; //Max amount of ammo that can be in a clip
	settings.FIRE_INTERVAL = 30; //Time in between shots
	settings.RELOAD_TIME = 55; //Time it takes to reload (in ticks)
	settings.AMMO_BLOB = "mat_sniperammo"; //Ammunition the gun takes

	//Bullet
	settings.B_PER_SHOT = 4; //Shots per bullet | CHANGE B_SPREAD, otherwise both bullets will come out together
	//settings.B_SPREAD = 4; //the higher the value, the more 'uncontrollable' bullets get
	settings.B_GRAV = Vec2f(0, 0.01); //Bullet gravity drop
	settings.B_SPEED = 110; //Bullet speed, STRONGLY AFFECTED/EFFECTS B_GRAV
	settings.B_TTL = 10; //TTL = 'Time To Live' which determines the time the bullet lasts before despawning
	settings.B_DAMAGE = 2.50f; //1 is 1 heart
	settings.B_TYPE = HittersTC::bullet_high_cal; //Type of bullet the gun shoots | hitter

	//Recoil
	settings.G_RECOIL = -50; //0 is default, adds recoil aiming up
	settings.G_RANDOMX = true; //Should we randomly move x
	//settings.G_RANDOMY = false; //Should we randomly move y, it ignores g_recoil
	settings.G_RECOILT = 15; //How long should recoil last, 10 is default, 30 = 1 second (like ticks)
	settings.G_BACK_T = 2; //Should we recoil the arm back time? (aim goes up, then back down with this, if > 0, how long should it last)

	//Sound
	settings.FIRE_SOUND = "Nitro700Fire.ogg"; //Sound when shooting
	settings.RELOAD_SOUND = "BoomstickReload.ogg"; //Sound when reloading

	//Offset
	settings.MUZZLE_OFFSET = Vec2f(-23.5, -2); //Where the muzzle flash appears

	this.set("gun_settings", @settings);
	this.set_u8("CustomKnock", 6);
	//Custom
	this.Tag("CustomSemiAuto");
	this.Tag("medium weight");
	this.Tag("sniper");
}