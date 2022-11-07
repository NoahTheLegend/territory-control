#include "VehicleCommon.as"

// Boat logic

//attachment point of the sail
const int sail_index = 0;

void onInit(CBlob@ this)
{
	Vehicle_Setup(this,
	              700.0f, // move speed
	              0.18f,  // turn speed
	              Vec2f(0.0f, -2.5f), // jump out velocity
	              true  // inventory access
	             );
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_SetupWaterSound(this, v, "HoverBike_Loop",  // movement sound
	                        1.25f, // movement sound volume modifier   0.0f = no manipulation
	                        0.05f // movement sound pitch modifier     0.0f = no manipulation
	                       );
	this.getShape().SetOffset(Vec2f(-3, 12));
	this.getShape().SetCenterOfMassOffset(Vec2f(-1.5f, 6.0f));
	this.getShape().getConsts().transports = true;
	this.getShape().getConsts().bullet = false;
	this.set_f32("map dmg modifier", 150.0f);

	//block knight sword
	this.Tag("blocks sword");

	// additional shape

	Vec2f[] frontShape;
	frontShape.push_back(Vec2f(74.0f, -6.0f));
	frontShape.push_back(Vec2f(134.0f, -6.0f));
	frontShape.push_back(Vec2f(128.0f, 0.0f));
	frontShape.push_back(Vec2f(71.0f, 0.0f));
	this.getShape().AddShape(frontShape);

	Vec2f[] backShape;
	backShape.push_back(Vec2f(8.0f, -8.0f));
	backShape.push_back(Vec2f(10.0f, 0.0f));
	backShape.push_back(Vec2f(6.0f, 0.0f));
	this.getShape().AddShape(backShape);

	Vec2f[] upShape;
	upShape.push_back(Vec2f(52.0f, -72.0f));
	upShape.push_back(Vec2f(66.0f, -72.0f));
	upShape.push_back(Vec2f(66.0f, -68.0f));
	upShape.push_back(Vec2f(52.0f, -68.0f));
	this.getShape().AddShape(upShape);

	Vec2f[] upShape2;
	upShape2.push_back(Vec2f(52.0f, -78.0f));
	upShape2.push_back(Vec2f(54.0f, -78.0f));
	upShape2.push_back(Vec2f(54.0f, -68.0f));
	upShape2.push_back(Vec2f(52.0f, -68.0f));
	this.getShape().AddShape(upShape2);

	// add pole ladder
	getMap().server_AddMovingSector(Vec2f(-28.0f, -32.0f), Vec2f(-12.0f, 0.0f), "ladder", this.getNetworkID());
	getMap().server_AddMovingSector(Vec2f(-28.0f, -48.0f), Vec2f(-12.0f, 0.0f), "ladder", this.getNetworkID());
	getMap().server_AddMovingSector(Vec2f(-28.0f, -64.0f), Vec2f(-12.0f, 0.0f), "ladder", this.getNetworkID());
	getMap().server_AddMovingSector(Vec2f(-28.0f, -82.0f), Vec2f(-12.0f, 0.0f), "ladder", this.getNetworkID());

	// sprites

	// add head
	{
		CSpriteLayer@ head = this.getSprite().addSpriteLayer("head", 16, 16);
		if (head !is null)
		{
			Animation@ anim = head.addAnimation("default", 0, false);
			anim.AddFrame(5);
			head.SetOffset(Vec2f(-32, -13));
			head.SetRelativeZ(1.0f);
		}
	}

	if (this.getSprite() !is null) this.getSprite().SetRelativeZ(50.0f);

	//add minimap icon
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 6, Vec2f(16, 8));
}

void onTick(CBlob@ this)
{
	const int time = this.getTickSinceCreated();
	if (this.hasAttached() || time < 30)
	{
		VehicleInfo@ v;
		if (!this.get("VehicleInfo", @v))
		{
			return;
		}
		Vehicle_StandardControls(this, v);

		if (isServer() && !this.hasTag("has mortar"))
		{
			this.Tag("has mortar");
			CBlob@ mortar = server_CreateBlob("incendiarymortar", this.getTeamNum(), this.getPosition());
		}
	}

	if (time % 60 == 0)
		Vehicle_DontRotateInWater(this);

	if (!this.isInWater())
	{
		this.setVelocity(Vec2f(0, this.getVelocity().y));
	}
}

void Vehicle_onFire(CBlob@ this, VehicleInfo@ v, CBlob@ bullet, const u8 charge) {}
bool Vehicle_canFire(CBlob@ this, VehicleInfo@ v, bool isActionPressed, bool wasActionPressed, u8 &out chargeValue) {return false;}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob.getShape().getConsts().platform)
		return false;
	return Vehicle_doesCollideWithBlob_boat(this, blob);
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	const f32 tier1 = this.getInitialHealth() * 0.6f;
	const f32 health = this.getHealth();

	if (health < tier1 && oldHealth >= tier1)
	{
		CSprite@ sprite = this.getSprite();

		CSpriteLayer@ mast = sprite.getSpriteLayer("mast");
		if (mast !is null)
			mast.animation.frame = 1;

		CSpriteLayer@ sail = sprite.getSpriteLayer("sail " + sail_index);
		if (sail !is null)
			sail.SetVisible(false);
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}
	Vehicle_onAttach(this, v, attached, attachedPoint);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	VehicleInfo@ v;
	if (!this.get("VehicleInfo", @v))
	{
		return;
	}

	if (detached !is null && detached.getName() == "incendiarymortar" && detached.getSprite() !is null) detached.getSprite().SetVisible(true);
	Vehicle_onDetach(this, v, detached, attachedPoint);
}
