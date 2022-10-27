void onTick(CSprite@ this)
{
	if (!blob.isOnGround())
    {
     this.SetAnimation("walk");
    }
}