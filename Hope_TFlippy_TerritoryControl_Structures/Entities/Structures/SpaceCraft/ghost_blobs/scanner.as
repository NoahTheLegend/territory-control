void onInit(CSprite@ this)
{
    this.SetEmitSound("Scanner_loop.ogg");
    this.SetEmitSoundVolume(0.05f);
    this.SetEmitSoundSpeed(0.35f);
    this.SetEmitSoundPaused(false);

    if (this.getBlob() !is null)
    {
        this.getBlob().SetLightColor(SColor(255,255,255,255));
        this.getBlob().SetLightRadius(32);
        this.getBlob().SetLight(true);
    }
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
    return false;
}