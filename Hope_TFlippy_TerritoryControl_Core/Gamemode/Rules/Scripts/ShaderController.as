// Might do more here later

void onInit(CRules@ this)
{
    //Shader inits stuff here
    Driver@ driver = getDriver();
    driver.ForceStartShaders();

    if (!isClient())
    {
        this.RemoveScript("ShaderController.as");
    }
}

void onTick(CRules@ this)
{
    Driver@ driver = getDriver();

    if (!driver.ShaderState()) 
    {
        driver.ForceStartShaders(); // force enable shaders at all times
    }
}

void onSetPlayer( CRules@ this, CBlob@ blob, CPlayer@ player )
{
    if (player is getLocalPlayer())
    {
        //getDriver().SetShader("drunk", false);
        //getDriver().SetShader("bobomax", false);
    }
}