void onInit(CSprite@ this)
{
	this.SetZ(-40); //background

	CBlob@ blob = this.getBlob();
	CSpriteLayer@ front = this.addSpriteLayer("front layer", this.getFilename() , 90, 32, blob.getTeamNum(), blob.getSkinNum());
	front.SetOffset(Vec2f(0.0f, 0.0f));

	if (front !is null)
	{
		Animation@ anim = front.addAnimation("dymlayer", 0, false);
		anim.AddFrame(12);
		front.SetRelativeZ(99);
	}
}
