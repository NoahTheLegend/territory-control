shared class CInspect : CEffectModeBase
{
	string getType(){return "Inspect";}
    uint _selectedBlob;
    bool followingSelected = false;

    Vec2f offset = Vec2f_zero;

    CBlob@ selectedBlob
    {
        get{return getBlobByNetworkID(_selectedBlob);}
        set
        {
            if(getBlobByNetworkID(_selectedBlob) !is null)
            {
                getBlobByNetworkID(_selectedBlob).getSprite().setRenderStyle(RenderStyle::Style::normal);
            }
            if(value is null){_selectedBlob = 0;}
            else {_selectedBlob = value.getNetworkID();}
            if(getBlobByNetworkID(_selectedBlob) !is null)
            {
                getBlobByNetworkID(_selectedBlob).getSprite().setRenderStyle(RenderStyle::Style::shadow);
                CBitStream params;
                params.write_u16(getBlobByNetworkID(_selectedBlob).getNetworkID());
                blob.SendCommand(blob.getCommandID("setSelectedBlob"),params);
            }
            else
            {
                blob.SendCommand(blob.getCommandID("resetSelectedBlob"));
            }
        }
    }
    CBlob@ hoveredBlob;
    CMap@ map;

    void init(CBlob@ blob) override
    {
        @map = getMap();
        blob.addCommandID("setSelectedBlob");
        blob.addCommandID("resetSelectedBlob");


        CEffectModeBase::init(blob);
    }
	void onTick() override
    {
        if(blob.getPlayer() !is null && blob.getPlayer().isLocal())
        {
            CControls@ controls = getControls();

            if(hoveredBlob !is null && hoveredBlob !is selectedBlob)
            {
                hoveredBlob.getSprite().setRenderStyle(RenderStyle::Style::normal);
            }
            @hoveredBlob = map.getBlobAtPosition(this.blob.getAimPos());
            if(hoveredBlob !is null)
            {
                this.hoveredBlob.getSprite().setRenderStyle(RenderStyle::Style::outline);
            }

            if(controls.isKeyJustPressed(KEY_LBUTTON))
            {
                @selectedBlob = hoveredBlob;//it's ok if hoverBlob is null, allows to unselect something
            }
            if(controls.isKeyJustPressed(KEY_KEY_L))
            {
                followingSelected = !followingSelected;
            }
        }

        if(followingSelected && selectedBlob !is null)
        {
            offset.x = Maths::Sin(getGameTime()/10.5) * 4;
            offset.y = Maths::Cos(getGameTime()/10) * 4;
            blob.setPosition(selectedBlob.getPosition() + offset + Vec2f(0,-12));
        }
        CEffectModeBase::onTick();
    }
	void render(CSprite@ sprite, f32 scale)
    {

        CEffectModeBase::render(sprite,scale);
    }
	void processCommand(u8 cmd, CBitStream @params)
    {
        if(cmd == blob.getCommandID("setMode"))
        {
            if(hoveredBlob !is null)
            {
                hoveredBlob.getSprite().setRenderStyle(RenderStyle::Style::normal);
            }
        }
        else if(cmd == blob.getCommandID("setSelectedBlob"))
        {
            CBlob@ sblob = getBlobByNetworkID(params.read_u16());
            if(sblob !is null)
            {
                _selectedBlob = sblob.getNetworkID();
            }
        }
        else if(cmd == blob.getCommandID("resetSelectedBlob"))
        {
            _selectedBlob = 0;
        }

        CEffectModeBase::processCommand(cmd, @params);
    }
}