#include "PixelOffsets.as"
#include "RunnerTextures.as"

const u16 MAX_FUEL = 50;

void onInit(CBlob@ this)
{
    this.addCommandID("nvd_refuel");
    this.addCommandID("nvd_switch");

	if (this.get_string("reload_script") != "nvd")
		UpdateScript(this);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
    if (caller is null) return;
    if (caller.isMyPlayer() && caller is this)
    {
	    CBlob@ carried = caller.getCarriedBlob();
        CBitStream params;
        params.write_u16(caller.getNetworkID());
        if (carried !is null && carried.getName() == "mat_mithril")
        {
            CButton@ button = caller.CreateGenericButton("$mat_mithril$", Vec2f(0, -16.0f), this, this.getCommandID("nvd_refuel"), "Refill the NVD ("+caller.get_u16("nvd_fuel")+")", params);
        }
        else
        {
            CButton@ button = caller.CreateGenericButton(8, Vec2f(0, -16.0f), this, this.getCommandID("nvd_switch"), this.get_bool("nvd_state") ? "Disable NVD" : "Enable NVD", params);
        }
    }
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("nvd_refuel"))
	{
        u16 blobid = params.read_u16();
        CBlob@ blob = getBlobByNetworkID(blobid);
        if (blob !is null)
        {
            CBlob@ carried = blob.getCarriedBlob();
            if (carried is null || carried.getName() != "mat_mithril") return;
            u16 quantity = carried.getQuantity();
            u16 fuel = blob.get_u16("nvd_fuel");
            u16 diff = MAX_FUEL - fuel;

            if (quantity<=diff)
            {
                blob.add_u16("nvd_fuel", quantity);
                if (isServer()) carried.server_Die();
            }
            else
            {
                blob.add_u16("nvd_fuel", diff);
                if (isServer()) carried.server_SetQuantity(quantity - diff);
            }

            if (blob.get_u16("nvd_fuel") > MAX_FUEL) blob.set_u16("nvd_fuel", MAX_FUEL);
            blob.Sync("nvd_fuel", true);
        }
    }
    else if (cmd == this.getCommandID("nvd_switch"))
    {
        u16 blobid = params.read_u16();
        CBlob@ blob = getBlobByNetworkID(blobid);
        if (blob !is null)
        {
            if (blob.get_u16("nvd_fuel") == 0) return;
            blob.set_bool("nvd_state", !blob.get_bool("nvd_state"));
            CSprite@ sprite = this.getSprite();
		    if (!blob.get_bool("nvd_state"))
            {
                if (isClient() && this.isMyPlayer())
		{
			if (getBlobByName("info_dead") !is null)
				getMap().CreateSkyGradient("Dead_skygradient.png");	
			else if (getBlobByName("info_magmacore") !is null)
				getMap().CreateSkyGradient("MagmaCore_skygradient.png");	
			else
				getMap().CreateSkyGradient("skygradient.png");	
		}
                blob.Tag("NoFlash");
                if (this.isMyPlayer()) SetScreenFlash(65, 0, 255, 0, 0.1);
                if (sprite !is null) sprite.PlaySound("nvd.ogg", 1.5f, 2.0f);
            }
            else
            {
                if (this.isMyPlayer()) getMap().CreateSkyGradient("skygradient_stim.png");
                blob.Untag("NoFlash");
                if (sprite !is null) sprite.PlaySound("nvd.ogg", 1.5f, 1.0f);
            }
        }
    }
}

void onTick(CBlob@ this)
{
    if (this.get_string("reload_script") == "nvd")
    {
		this.set_string("reload_script", "");
        UpdateScript(this);
    }

    if (this.get_u16("nvd_fuel") == 0) this.set_bool("nvd_state", false);

    if (getGameTime()%450==0 && this.get_bool("nvd_state") && this.get_u16("nvd_fuel") > 0)
    {
        this.add_u16("nvd_fuel", -1);
        if (this !is null) this.Sync("nvd_fuel", true);
    }

    CSpriteLayer@ milhelmet = this.getSprite().getSpriteLayer("nvd");
    if (milhelmet !is null)
    {
        Vec2f headoffset(this.getSprite().getFrameWidth() / 2, -this.getSprite().getFrameHeight() / 2);
        Vec2f head_offset = getHeadOffset(this, -1, 0);
       
        headoffset += this.getSprite().getOffset();
        headoffset += Vec2f(-head_offset.x, head_offset.y);
        headoffset += Vec2f(0, -1);
        milhelmet.SetOffset(headoffset);
    }

    if (this.get_f32("nvd_health") >= 80.0f)
    {
        this.getSprite().PlaySound("ricochet_" + XORRandom(3));
        this.set_string("equipment_head", "");
        this.set_f32("nvd_health", 79.9f);
		if (milhelmet !is null)
		{
			this.getSprite().RemoveSpriteLayer("nvd");
		}
        this.RemoveScript("nvd_effect.as");
    }
}

void onRender(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob !is null && !blob.hasTag("NoFlash") && blob.isMyPlayer() && blob.get_u16("nvd_fuel") > 0)
    {
		SetScreenFlash(65, 65, 255, 65, 99);
    }
}

void UpdateScript(CBlob@ this) // the same as onInit, works one time when get equiped
{
    CSpriteLayer@ milhelmet = this.getSprite().addSpriteLayer("nvd", "Nvd.png", 16, 16);
   
    if (milhelmet !is null)
    {
		milhelmet.SetVisible(true);
        milhelmet.SetRelativeZ(200);
        if (this.getSprite().isFacingLeft())
            milhelmet.SetFacingLeft(true);
    }
}
 
void onDie(CBlob@ this)
{
	if (this.getSprite().getSpriteLayer("nvd") !is null) this.getSprite().RemoveSpriteLayer("nvd");
    if (this.get_bool("nvd_state"))
    {
        if (this.isMyPlayer())
        {
            SetScreenFlash(65, 0, 255, 0, 1);
            
		{
			if (getBlobByName("info_dead") !is null)
				getMap().CreateSkyGradient("Dead_skygradient.png");	
			else if (getBlobByName("info_magmacore") !is null)
				getMap().CreateSkyGradient("MagmaCore_skygradient.png");	
			else
				getMap().CreateSkyGradient("skygradient.png");	
		}
        }
    }
    this.RemoveScript("nvd_effect.as");
}