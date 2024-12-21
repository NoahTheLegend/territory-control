void onInit(CBlob@ this)
{
	this.Tag("builder always hit");
	this.getSprite().SetZ(-5.00f);

    CSpriteLayer@ l = this.getSprite().addSpriteLayer("l", "ClanBannerDecal.png", 16, 32);
    
    this.addCommandID("load_image");
    this.addCommandID("sync");
    this.addCommandID("init_sync");

    if (isClient())
    {
        CBitStream params;
        this.SendCommand(this.getCommandID("init_sync"), params);
    }

    int cb_id = Render::addBlobScript(Render::layer_objects, this, "ClanBanner.as", "renderCanvas");
}

void renderCanvas(CBlob@ this, int id)
{
    if (!this.hasTag("created_texture")) return;
    Vec2f pos = this.getPosition() - Vec2f(4,10);

    Vec2f[] v_pos;
	Vec2f[] v_uv;

    v_uv.push_back(Vec2f(0,0)); v_pos.push_back(pos + Vec2f(0,0)); //tl
    v_uv.push_back(Vec2f(1,0)); v_pos.push_back(pos + Vec2f(8,0)); //tr
    v_uv.push_back(Vec2f(1,1)); v_pos.push_back(pos + Vec2f(8,16)); //br
    v_uv.push_back(Vec2f(0,1)); v_pos.push_back(pos + Vec2f(0,16)); //bl

    Render::Quads("banner"+this.getNetworkID(), 1.0f, v_pos, v_uv);

    v_pos.clear();
	v_uv.clear();
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
    if (cmd == this.getCommandID("sync"))
    {
        if (!isClient()) return;
        string tex_name = "banner"+this.getNetworkID();

        if(!Texture::createBySize(tex_name, 8, 16))
		{
			warn("Texture creation failed!");
		}

        ImageData@ data = Texture::data(tex_name);

        if (data is null)
        {
            warn("Image data is null!");
            return;
        }

        for (u8 i = 0; i < 128; i++)
        {
            int step;
            if (!params.saferead_s32(step))
            {
                continue;
            }

            data.put(i%8, Maths::Floor(i/8), SColor(step));
        }
        
        printf("Created texture '"+tex_name+"', size "+data.width()+" x "+data.height());

        if(!Texture::update(tex_name, data))
		{
			warn("Texture update failed!");
		}

        this.Tag("created_texture");
    }
    else if (cmd == this.getCommandID("init_sync"))
    {
        if (!isServer()) return;

        Sync(this);
    }
    else if (cmd == this.getCommandID("load_image"))
    {
        if (!isServer()) return;
        int[] canvas;
    
        for (u8 i = 0; i < 128; i++)
        {
            int step;
            if (!params.saferead_s32(step))
            {
                canvas.push_back(0x00000000);
                continue;
            }
            canvas.push_back(step);
        }
        this.set("canvas", @canvas);

        Sync(this);
    }
}

void Sync(CBlob@ this)
{
    int[]@ canvas;
    if (!this.get("canvas", @canvas) || canvas.size() != 128)
    {
        warn("Failed to load banner canvas array on sync");
        return;
    }

    CBitStream params;
    for (u8 i = 0; i < 128; i++)
    {
        params.write_s32(canvas[i]);
    }
    
    this.SendCommand(this.getCommandID("sync"), params);
}

void onTick(CBlob@ this)
{
    if (isClient())
    {
        if (this.getTicksToDie() < 120)
        {
            if (this.exists("cData"))
            {
                CSprite@ s = this.getSprite();
                s.ReloadSprite(this.get_string("cData")+ ".png");
				s.SetZ(-5.00f);
                this.doTickScripts = false;
            }
        }
        else
        {
            this.doTickScripts = false;
        }
    }
}


bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}