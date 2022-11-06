//Slave ball logic

#include "Hitters.as";

f32 maxDistance = 64.0f;

void onInit(CBlob@ this)
{
	this.Tag("heavy weight");
	this.Tag("ignore fall");
	this.Tag("vehicle");
	
	CSprite@ sprite = this.getSprite();
	
	sprite.RemoveSpriteLayer("chain");
	CSpriteLayer@ chain = sprite.addSpriteLayer("chain", "SlaveBall_Chain.png", 32, 2, this.getTeamNum(), 0);

	if (chain !is null)
	{
		Animation@ anim = chain.addAnimation("default", 0, false);
		anim.AddFrame(0);
		chain.SetRelativeZ(-10.0f);
		chain.SetVisible(false);
	}
}

void onTick(CBlob@ this)
{
	CBlob@ slave = getBlobByNetworkID(this.get_u16("slave_id"));
	
	if (slave !is null && slave.getName() == "slave")
	{		
		const string slavesname = "Slave";//slave.getName();
		this.setInventoryName(slavesname+"'s Ball\n"+(Maths::Round(this.getHealth()/this.getInitialHealth()*1000.0f)/10.0f)+"% HP");
		
		Vec2f dir = (this.getPosition() - slave.getPosition());
		f32 distance = dir.Length();
		dir.Normalize();
		
		if (distance > maxDistance) 
		{
			slave.setPosition(this.getPosition() - dir * maxDistance * 0.999f);
			
			slave.setVelocity(dir*3.0f);
			this.setVelocity(-dir);
		}
		
		if (isClient()) DrawLine(this.getSprite(), this.getPosition(), distance / 32, -dir.Angle(), true);
	}
	else
	{
		if (isServer()) this.server_Die();
		if (isClient()) this.getSprite().getSpriteLayer("chain").SetVisible(false);
	}
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return false;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return byBlob.getName() != "slave";// || this.isOverlapping(byBlob);
}

void DrawLine(CSprite@ this, Vec2f startPos, f32 length, f32 angle, bool flip)
{
	CSpriteLayer@ chain = this.getSpriteLayer("chain");
	
	chain.SetVisible(true);
	
	chain.ResetTransform();
	chain.ScaleBy(Vec2f(length, 1.0f));
	chain.TranslateBy(Vec2f(length * 16.0f, 0.0f));
	chain.RotateBy(angle + (flip ? 180 : 0), Vec2f());
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob !is null && hitterBlob.getName() == "slave") return 0.1f;
	switch (customData)
	{
		case Hitters::builder:
			damage *= 0.0033f;
			break;
	}
	
	return damage;

}

void onDie( CBlob@ this ){
	if (isServer()){
		CBlob@ slave = getBlobByNetworkID(this.get_u16("slave_id"));
		
		if (slave !is null && slave.getName() == "slave"){
			CBlob@ peasant = server_CreateBlob("peasant", slave.getTeamNum(), slave.getPosition());

			if (peasant !is null){
				if (slave.getPlayer() !is null) peasant.server_SetPlayer(slave.getPlayer());
				slave.server_Die();
			}
		}
	}
}