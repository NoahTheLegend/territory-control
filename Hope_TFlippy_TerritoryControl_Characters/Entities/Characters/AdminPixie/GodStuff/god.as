#include "godCommon.as"
#include "CForce.as"
#include "CMusic.as"
#include "CInspect.as"

void onInit(CBlob@ this)
{
    this.addCommandID("setMode");

    this.set_f32("effectRadius", 8*5); //5 block radius

    CInspect inspect;
    inspect.init(this);
    this.set("inspect",@inspect);

	CForce force;
    force.init(this,@inspect);//force makes use of inspect
    this.set("force",@force);

    CMusic music;
    music.init(this);
    this.set("music",@music);

	this.set("mode",@force);

    this.addCommandID("removegod");
}

void onTick(CBlob@ this)
{
    IEffectMode@ mode;
	this.get("mode",@mode);
    if(mode !is null || this.hasTag("nogod"))
	{
        mode.onTick();
    }

    if(this.getPlayer() !is null && this.getPlayer().isLocal())
    {
        CControls@ c = getControls();

        if(c.isKeyPressed(KEY_LSHIFT))
        {
            if(c.isKeyJustPressed(KEY_KEY_1))
            {
                CBitStream params;
                params.write_string("force");
                this.SendCommand(this.getCommandID("setMode"),params);
            }
            else if (c.isKeyJustPressed(KEY_KEY_2))
            {
                CBitStream params;
                params.write_string("inspect");
                this.SendCommand(this.getCommandID("setMode"),params);
            }
            else if(c.isKeyJustPressed(KEY_KEY_3))
            {
                CBitStream params;
                params.write_string("music");
                this.SendCommand(this.getCommandID("setMode"),params);
            }
        }
    }
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    IEffectMode@ mode;
	this.get("mode",@mode);
    if(mode !is null)
    mode.processCommand(cmd, params);

    if(cmd == this.getCommandID("setMode"))
    {
        string type = params.read_string();
        if(type == "force")
        {
            this.get("force",@mode);
            this.set("mode",@mode);
        }
        else if (type == "inspect")
        {
            this.get("inspect",@mode);
            this.set("mode",@mode);
        }
        else if (type == "music")
        {
            this.get("music",@mode);
            this.set("mode",@mode);
        }
    }
    else if(cmd == this.getCommandID("removegod"))
    {
        this.RemoveScript("godgui.as");
        this.RemoveScript("god.as");
        this.Tag("nogod");
    }
}