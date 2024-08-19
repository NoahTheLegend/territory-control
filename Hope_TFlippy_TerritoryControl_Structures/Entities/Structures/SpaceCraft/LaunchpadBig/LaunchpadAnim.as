void onInit(CSprite@ this)
{
    this.SetRelativeZ(-15);

    CSpriteLayer@ scr = this.addSpriteLayer("screen", "RocketStateScreens.png", 13, 11);
	if (scr !is null)
	{
        Animation@ state = scr.addAnimation("state", 0, false);
        for (u8 i = 0; i < 30; i++)
        {
            state.AddFrame(i);
        }
        scr.SetRelativeZ(-8);
        scr.SetOffset(Vec2f(-36.5f, 80.5f));
        scr.SetVisible(false);
        scr.SetAnimation("state");
    }

    CSpriteLayer@ locator = this.addSpriteLayer("locator", "RocketsLocator.png", 32, 24);
	if (locator !is null)
	{
		Animation@ anim = locator.addAnimation("spin", 10, true);
		for (int i = 0; i < 4; i++)
		{
			anim.AddFrame(i);
		}
		
		locator.SetVisible(true);
		locator.SetOffset(Vec2f(-28, 84));
		locator.SetRelativeZ(-10);
        if (isServer() && this.getBlob() !is null)
        {
            CBlob@ blob = server_CreateBlob("scanner_ghost");
            blob.setPosition(this.getBlob().getPosition()+Vec2f(34, 80));
            this.getBlob().set_netid("scanner", blob.getNetworkID());
            blob.getShape().SetStatic(true);
        }
	}
    Animation@ ranim = this.addAnimation("building", 0, false);
    int[] frames = {0,1,2,3,4,5,6,7,8,9,10,11};
    ranim.AddFrames(frames);
    this.SetAnimation("building");

    this.SetEmitSound("Mystical_EnergySwordHumLoop5.ogg");
    this.SetEmitSoundVolume(1.0f);
    this.SetEmitSoundSpeed(0.25f);
    this.SetEmitSoundPaused(true);
}

void onTick(CSprite@ sprite)
{
    CBlob@ this = sprite.getBlob();
    if (this is null) return;

    CSpriteLayer@ screen = sprite.getSpriteLayer("screen");
    if (screen !is null)
    {
        if (this.get_u32("time_to_arrival") < 30) screen.SetVisible(false);
    }
    if (getGameTime()%90==0 && this.get_u8("frameindex") >= 2) sprite.SetEmitSoundPaused(false);
    CSpriteLayer@ locator = sprite.getSpriteLayer("locator");
    if (getGameTime()%5==0 && locator !is null)
    {
        locator.SetAnimation("spin");
    }
    sprite.SetFrameIndex(this.get_u8("frameindex"));

    int[] frames = {0,1,2,3};
    for (u8 i = 0; i < 4; i++)
    {
        CSpriteLayer@ module = sprite.getSpriteLayer("module"+(i+1));
        if (module is null)
        {
            CSpriteLayer@ module = sprite.addSpriteLayer("module"+(i+1), "modules.png", 19, 12);
            Vec2f offset = Vec2f(3.5, -23.0f-(15.0f*i)-(i==0?1.0f:0));

            module.SetOffset(offset);
            Animation@ manim = sprite.addAnimation("modules", 0, false);
            manim.AddFrames(frames);
            module.SetAnimation("modules");
            module.SetVisible(false);
        }
        else if (this.get_u8("frameindex") >= 7 && this.get_u8("frameindex") < 12 && this.get_u16("rocketid") == 0 && this.get_u16("ETA") == 0)
        {
            module.SetVisible(true);
            string modulestr = this.get_string("module"+(i+1));

            if (modulestr == "drillstation")
                module.SetFrameIndex(0);
            else if (modulestr == "fueltank")
                module.SetFrameIndex(2);
            else if (modulestr == "detailedscanner")
                module.SetFrameIndex(1);
            else if (modulestr == "weaponpack")
                module.SetFrameIndex(3);
            else
            {
                module.SetVisible(false);
            }
        }
        else module.SetVisible(false);
    }
}