#include "GunCommon.as";

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.isAttached()) return 0;
	return damage;
}

void onInit(CBlob@ this)
{
	GunSettings settings = GunSettings();

	//General
	//settings.CLIP = 0; //Amount of ammunition in the gun at creation
	settings.TOTAL = 12; //Max amount of ammo that can be in a clip
	settings.FIRE_INTERVAL = 1; //Time in between shots
	settings.RELOAD_TIME = 15; //Time it takes to reload (in ticks)
	settings.AMMO_BLOB = "mat_pistolammo"; //Ammunition the gun takes

	//Bullet
	//settings.B_PER_SHOT = 1; //Shots per bullet | CHANGE B_SPREAD, otherwise both bullets will come out together
	settings.B_SPREAD = 4; //the higher the value, the more 'uncontrollable' bullets get
	settings.B_GRAV = Vec2f(0, 0.001); //Bullet gravity drop
	settings.B_SPEED = 90; //Bullet speed, STRONGLY AFFECTED/EFFECTS B_GRAV
	settings.B_TTL = 12; //TTL = 'Time To Live' which determines the time the bullet lasts before despawning
	settings.B_DAMAGE = 1.5f; //1 is 1 heart
	settings.B_TYPE = HittersTC::bullet_low_cal; //Type of bullet the gun shoots | hitter

	//Recoil
	settings.G_RECOIL = -7; //0 is default, adds recoil aiming up
	settings.G_RANDOMX = true; //Should we randomly move x
	settings.G_RANDOMY = false; //Should we randomly move y, it ignores g_recoil
	settings.G_RECOILT = 4; //How long should recoil last, 10 is default, 30 = 1 second (like ticks)
	settings.G_BACK_T = 3; //Should we recoil the arm back time? (aim goes up, then back down with this, if > 0, how long should it last)

	//Sound
	settings.FIRE_SOUND = "Cock19_Shoot.ogg"; //Sound when shooting
	settings.RELOAD_SOUND = "FugerReload.ogg"; //Sound when reloading

	//Offset
	settings.MUZZLE_OFFSET = Vec2f(-12.5, -3.5); //Where the muzzle flash appears

	this.set("gun_settings", @settings);

	//Custom
	this.Tag("CustomSemiAuto");
	this.set_f32("scope_zoom", 0.005f);

	CSprite@ sprite = this.getSprite();

	CSpriteLayer@ laser = sprite.addSpriteLayer("laser", "Laser_Green.png", 32, 1);
	if (laser !is null)
	{
		Animation@ anim = laser.addAnimation("default", 0, false);
		anim.AddFrame(0);
		laser.SetRelativeZ(-1.0f);
		laser.SetVisible(true);
		laser.setRenderStyle(RenderStyle::additive);
		laser.SetOffset(Vec2f(-5.0f, 1.0f));
	}
}

void onTick(CBlob@ this)
{
	if (this.isAttached())
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (point is null) return;

		CBlob@ holder = point.getOccupied();
		if (holder is null) return;

		Vec2f hitPos;
		f32 length;
		f32 range = 1100.0f;
		bool flip = this.isFacingLeft();
		f32 angle = getAimAngle(this, holder);
		Vec2f dir = Vec2f((this.isFacingLeft() ? -1 : 1), 0.0f).RotateBy(angle);
		Vec2f startPos = this.getPosition();
		Vec2f endPos = startPos + dir * range;

		bool mapHit = getMap().rayCastSolid(startPos, endPos, hitPos);
		length = (hitPos - startPos).Length();

		CSpriteLayer@ laser = this.getSprite().getSpriteLayer("laser");

		if (laser !is null)
		{
			laser.ResetTransform();
			laser.ScaleBy(Vec2f(length / 32.0f - 0.4, 1.0f));
			laser.TranslateBy(Vec2f(length / 2 - 7, 0.0f));
			laser.RotateBy((flip ? 180 : 0), Vec2f());
			laser.SetVisible(true);
		}
	}
	else
	{
		CSpriteLayer@ laser = this.getSprite().getSpriteLayer("laser");

		if (laser !is null)
		{
			laser.SetVisible(false);
		}
	}
	this.Tag("pistol");
}

