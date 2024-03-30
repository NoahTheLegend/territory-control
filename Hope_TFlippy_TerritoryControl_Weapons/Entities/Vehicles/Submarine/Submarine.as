void onInit(CBlob@ this)
{
	//Vec2f[] upShape2;
	//upShape2.push_back(Vec2f(52.0f, -78.0f));
	//upShape2.push_back(Vec2f(54.0f, -78.0f));
	//upShape2.push_back(Vec2f(54.0f, -68.0f));
	//upShape2.push_back(Vec2f(52.0f, -68.0f));
	//this.getShape().AddShape(upShape2);

	this.set_Vec2f("force", Vec2f_zero);

	// add pole ladder
	//getMap().server_AddMovingSector(Vec2f(-28.0f, -32.0f), Vec2f(-12.0f, 0.0f), "ladder", this.getNetworkID());

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("DRIVER");
	if (ap is null) return;
	ap.SetKeysToTake(key_left | key_right | key_up | key_down);

	this.getSprite().SetRelativeZ(-50.0f);
	this.getShape().SetRotationsAllowed(false);
}

const f32 damp = 0.8f;
const Vec2f force_horizontal = Vec2f(0.1f, -0.1f); // right left
const Vec2f force_vertical = Vec2f(-0.1f, 0.1f); // up down
const f32 max_speed = 10.0f;
const f32 turn_speed = 0.5f;

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

	//target_force = Vec2f_lerp(force, target_force, 0.5f);
	target_force *= damp;

	this.set_Vec2f("force", target_force);
	this.AddForce(target_force * this.getMass());
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}