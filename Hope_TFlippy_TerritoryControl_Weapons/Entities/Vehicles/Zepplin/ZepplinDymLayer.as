void onInit(CSprite@ this)
{
	this.SetZ(-40); //background

	CBlob@ blob = this.getBlob();
	CSpriteLayer@ front = this.addSpriteLayer("front layer", this.getFilename() , 181, 90, blob.getTeamNum(), blob.getSkinNum());
	front.SetOffset(Vec2f(0.0f, 8.0f));

	if (front !is null)
	{
		Animation@ anim = front.addAnimation("default", 0, false);
		anim.AddFrame(1);
		front.SetRelativeZ(1000);
	}
}
