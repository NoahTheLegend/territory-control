#include "MakeMat.as";
#include "FilteringCommon.as";
#include "Hitters.as";

void onInit(CSprite@ this)
{
	// Building
	this.SetZ(-50);

	this.RemoveSpriteLayer("gear");
	CSpriteLayer@ gear = this.addSpriteLayer("gear", "Cogs.png" , 16, 16, this.getBlob().getTeamNum(), this.getBlob().getSkinNum());

	if (gear !is null)
	{
		Animation@ anim = gear.addAnimation("default", 0, false);
		anim.AddFrame(1);
		gear.SetOffset(Vec2f(-0.5f, -9.0f));
		gear.SetAnimation("default");
		gear.SetRelativeZ(-5);
	}
}

float Reach = 48.0f;
Vec2f Mid = Vec2f(0,-7);


void onRender(CSprite@ this)
{
	CPlayer@ p = getLocalPlayer();
	if (p is null || !p.isMyPlayer()) return;

	CBlob@ blob = this.getBlob();
	CBlob@ pblob = p.getBlob();
	if (pblob is null) return;
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	bool mouseOnBlob = (mouseWorld - blob.getPosition()).getLength() < this.getBlob().getRadius();
	
	if (mouseOnBlob)
	{
		if (pblob.isKeyPressed(key_action3))
		{
			for (u16 i = 0; i < 360; i++)
			{
				CParticle@ par = ParticlePixelUnlimited(blob.getPosition() + (Vec2f(Reach+8.0f, 0.0f).RotateBy(i)), Vec2f(0,0), SColor(255, 255, 255, 255), true);
				if (par !is null)
				{
					par.Z = 200;
					par.gravity = Vec2f(0, 0.0f);
					par.growth = 1.50f;
					par.timeout = 1;
				}
			}
		}
	}
}

void onTick(CSprite@ this)
{
	for(int i = 0;i < this.getSpriteLayerCount();i++){
		CSpriteLayer@gear = this.getSpriteLayer(i);
		if(gear !is null){
			
			if(gear.name.findFirst("connection_") >= 0){
				CBlob @connection = getBlobByNetworkID(parseInt(gear.name.substr(11)));
				if(connection is null){
					this.RemoveSpriteLayer(gear.name);
				} else {
					//if(!connection.getShape().isStatic()){
						Vec2f dif = (this.getBlob().getPosition()+Mid)-connection.getPosition();
						dif = Vec2f(-dif.x,dif.y);
						int dis = Maths::Max(dif.Length(),8);
						if(dis <= Reach){
							gear.ResetTransform();
							gear.ScaleBy(dis/float(gear.getFrameWidth()),1);
							gear.RotateBy(dif.getAngleDegrees()+180, Vec2f(0.5f,-0.5f));
							gear.SetOffset(-Vec2f(dif.x/2,dif.y/2)+Mid);
						} else {
							this.RemoveSpriteLayer(gear.name);
						}
					//}
				}
			} else {
				gear.RotateBy(5.0f*(this.getBlob().exists("gyromat_acceleration") ? this.getBlob().get_f32("gyromat_acceleration") : 1), Vec2f(0.5f,-0.5f));
			}
		}
	}
	
}

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 10;

	this.Tag("ignore extractor");
	this.Tag("builder always hit");
	this.set_string("Owner", "");

	this.addCommandID("sv_setowner");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (this.getMap().rayCastSolid(caller.getPosition(), this.getPosition())) return;
	
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	
	if (caller.getPlayer() is null) return; 
	
	if (caller.isOverlapping(this) && this.get_string("Owner") == "")
	{	
		CButton@ buttonOwner = caller.CreateGenericButton(9, Vec2f(0, -8), this, this.getCommandID("sv_setowner"), "Claim", params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (isServer())
	{
		if (cmd == this.getCommandID("sv_setowner"))
		{
			if (this.get_string("Owner") != "") return;
		
			CBlob@ caller = getBlobByNetworkID(params.read_u16());
			if (caller is null) return;
			
			CPlayer@ player = caller.getPlayer();
			if (player is null) return;
			
			this.set_string("Owner", player.getUsername());
			this.server_setTeamNum(player.getTeamNum());
			this.Sync("Owner", true);

			// print("Set owner to " + this.get_string("Owner") + "; Team: " + this.getTeamNum());
		}
	}
}

void onTick(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 60.0f / (this.exists("gyromat_acceleration") ? this.get_f32("gyromat_acceleration") : 1);

	if (isServer())
	{
		CBlob@[] blobs;
		if (this.getMap().getBlobsInRadius(this.getPosition()+Mid, Reach, @blobs))
		//if (getMap().getBlobsInBox(this.getPosition() + Vec2f(-40, -40), this.getPosition() + Vec2f(40, 40), @blobs))
		{
			for (uint i = 0; i < blobs.length; i++)
			{
				CBlob@ b = blobs[i];
				if (b.getInventory() !is null && b.hasTag("player") && (b.getTeamNum() == this.getTeamNum() || (b.getPlayer() !is null && b.getPlayer().getUsername() == this.get_string("Owner")))) {

					if (b.getInventory().getItemsCount() > 0)
					{
						for (int i = 0; i < b.getInventory().getItemsCount(); i++)
						{
							CBlob@ item = b.getInventory().getItem(i);
							if(server_isItemAccepted(this, item.getName()))
							{
								b.server_PutOutInventory(item);
								item.setPosition(this.getPosition());
								break;
							}
						}
					}
				}
			}
		}
	}
	
	if (isClient())
	{
		int transferTime =  this.getCurrentScript().tickFrequency;
		CSprite @sprite = this.getSprite();
		CBlob@[] blobs;
		if (this.getMap().getBlobsInRadius(this.getPosition()+Mid, Reach, @blobs))
		{
			for (uint i = 0; i < blobs.length; i++)
			{
				CBlob@ b = blobs[i];
				if (b.getInventory() !is null && b.hasTag("player") && b.getTeamNum() == this.getTeamNum()) {

					CSpriteLayer @layer = sprite.getSpriteLayer("connection_"+b.getNetworkID());

					Vec2f dif = (this.getPosition()+Mid)-b.getPosition();
					int dis = Maths::Max(dif.Length(),8);
					if(layer is null){
						
						int frameSpacing = 64/dis;
						
						CSpriteLayer@ gear = sprite.addSpriteLayer("connection_"+b.getNetworkID(),"ExtractorPipeR.png",dis,6);
						if(gear !is null){
							Animation@ anim = gear.addAnimation("default", transferTime/(dis/2), false);
							for(int i = 0;i < dis/2+2;i++)anim.AddFrame(i*frameSpacing);
							
							//gear.ScaleBy(dif.Length()/64, 1);
							
							dif = Vec2f(-dif.x,dif.y);
							gear.RotateBy(dif.getAngleDegrees()+180, Vec2f(0.5f,-0.5f));
							gear.SetOffset(-Vec2f(dif.x/2,dif.y/2)+Mid);
							
							
							gear.SetAnimation("default");
							gear.SetRelativeZ(-10);
							
						}
					} else {
						CSpriteLayer@ gear = sprite.getSpriteLayer("connection_"+b.getNetworkID());
						if(gear !is null){
							Animation @anim = gear.getAnimation("default");
							if(anim !is null)anim.timer = transferTime/(dis/2);
							gear.SetFrameIndex(0);
						}
					}
				}
			}
		}
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return forBlob.isOverlapping(this) && (forBlob.getCarriedBlob() is null || forBlob.getCarriedBlob().getName() == "gyromat");
	//return (forBlob.isOverlapping(this));
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::builder) damage *= 10.0f;
	return damage;
}