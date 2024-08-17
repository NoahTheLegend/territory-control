
void onInit(CBlob@ this)
{
	this.set_Vec2f("force", Vec2f_zero);

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("DRIVER");
	if (ap is null)
    
	ap.SetKeysToTake(key_left | key_right | key_up | key_down);

	this.getSprite().SetRelativeZ(-50.0f);
	this.getShape().SetRotationsAllowed(false);
	CSprite@ sprite = this.getSprite();

	sprite.SetEmitSound("MethaneCollector_Loop.ogg");
	sprite.SetEmitSoundVolume(0.7f);
	sprite.SetEmitSoundSpeed(1.0f);
	sprite.SetEmitSoundPaused(false);

	this.SetLight(true);
	this.SetLightRadius(64.0f);
	this.SetLightColor(SColor(255, 255, 240, 210));

	CSpriteLayer@ decal = sprite.addSpriteLayer("screw", "Screw.png", 4, 19);
	if (decal !is null)
	{
		Animation@ def = decal.addAnimation("default", 3, true);
		int[] frames = {0,1,2,3,4,5,6,7};
		def.AddFrames(frames);

		decal.SetRelativeZ(49.0f);
		decal.SetOffset(Vec2f(43, 0.0f));
		decal.SetAnimation(def);
	}	

	Vec2f pos_off(-15, -16);
	{
		Vec2f[] shape = { Vec2f(0.0f, 0.0f) - pos_off,
		                  Vec2f(60.0f,  0.0f) - pos_off,
		                  Vec2f(60.0f,  2.0f) - pos_off,
		                  Vec2f(0.0f, 2.0f) - pos_off
		                };
		this.getShape().AddShape(shape);
	}

	{
		Vec2f[] shape = { Vec2f( -20.0f,  -25.0f ) -pos_off,
						  Vec2f( 0.0f,  -25.0f ) -pos_off,
						  Vec2f( 0.0f,  2.0f ) -pos_off,
						  Vec2f( -20.0f,  2.0f ) -pos_off 
						};
		this.getShape().AddShape( shape );
	}
	
	{
		Vec2f[] shape = { Vec2f( 58.0f,  -25.0f ) -pos_off,
						  Vec2f( 60.0f,  -25.0f ) -pos_off,
						  Vec2f( 60.0f,  2.0f ) -pos_off,
						  Vec2f( 65.0f,  2.0f ) -pos_off 
						};
		this.getShape().AddShape( shape );
	}

	{
		Vec2f[] shape = { Vec2f(40.0f, -25.0f) - pos_off,
		                  Vec2f(60.0f,  -23.0f) - pos_off,
		                  Vec2f(60.0f,  -25.0f) - pos_off,
		                  Vec2f(40.0f, -25.0f) - pos_off
		                };
		this.getShape().AddShape(shape);
	}
}

void makeBubbleParticle(CBlob@ this, const Vec2f vel, const string filename = "Bubble")
{
	if (!isClient()) return;
	const f32 rad = this.getRadius();
	if (this.isFacingLeft())
	{
	   {
	     Vec2f random = Vec2f(43.0f, 3.0f);
		 Vec2f sus = getRandomVelocity(90.0f, 3.0f, 90.0f);
	     ParticleAnimated(filename, this.getPosition() + random + sus, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
	   }
	return;
	}   
	Vec2f random = Vec2f(-43.0f, 3.0f);
	Vec2f sus = getRandomVelocity(90.0f, 3.0f, 90.0f);
	ParticleAnimated(filename, this.getPosition() + random + sus, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}

const f32 damp = 0.8f;
const Vec2f force_horizontal = Vec2f(0.2f, -0.2f); // right left
const Vec2f force_vertical = Vec2f(-0.1f, 0.1f); // up down
const f32 max_speed = 10.0f;
const f32 turn_speed = 1.2f;

void onTick(CBlob@ this)
{
	bool inwater = this.isInWater();

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("DRIVER");
	if (ap is null) return;

	CShape@ shape = this.getShape();
	if (shape is null) return;

	const Vec2f vel = this.getVelocity();
	shape.SetGravityScale(inwater ? 0 : 1);

	Vec2f force = this.get_Vec2f("force");
	Vec2f target_force = force;

	CBlob@ pilot = ap.getOccupied();
	if (inwater && pilot !is null && shape.vellen < max_speed)
	{
		bool left = ap.isKeyPressed(key_left);
		bool right = ap.isKeyPressed(key_right);
		bool up = ap.isKeyPressed(key_up);
		bool down = ap.isKeyPressed(key_down);

		if (up) target_force += Vec2f(0, force_vertical.x);
		if (down) target_force += Vec2f(0, force_vertical.y);
		if (left) target_force += Vec2f(force_horizontal.y, 0);
		if (right) target_force += Vec2f(force_horizontal.x, 0);

		if (left && vel.x < -turn_speed) this.SetFacingLeft(true);
		if (right && vel.x > turn_speed) (this.SetFacingLeft(false));
	}

	target_force *= damp;

	this.set_Vec2f("force", target_force);
	this.AddForce(target_force * this.getMass());

	AttachmentPoint@[] aps;

	if (this.isInWater())
	{
		if (!isClient()){ return;}
		makeBubbleParticle(this, Vec2f(), XORRandom(100) > 50 ? "Bubble" : "SmallBubble1");
	}

	if (ap.isKeyPressed(key_left) || ap.isKeyPressed(key_right) || ap.isKeyPressed(key_up) || ap.isKeyPressed(key_down))
	{    
		this.getSprite().PlaySound("HoverBike_Loop.ogg", 0.4f, 0.4f);
	}	
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}