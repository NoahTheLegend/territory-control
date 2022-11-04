
void onInit(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null) return;

	// Building
	this.SetZ(-50); //-60 instead of -50 so sprite layers are behind ladders

    this.addAnimation("dynamicanim", 0, false);
    Animation@ anim = this.getAnimation("dynamicanim");
    if (anim !is null)
    {
        int[] frames = {0,1,2,3,4,5,6,7,8,9,10,11,12,13};
        anim.AddFrames(frames);
        this.SetAnimation(anim);
    }

    blob.set_u8("frame", 0);
    blob.set_u8("type", 255);
}

void onTick(CBlob@ this)
{
    if (!this.get_bool("state")) return; //|| this.get_u32("elec") <= 100) return;
    f32 gyromat_acceleration = this.get_f32("gyromat_acceleration") - 1;
    u8 diff = gyromat_acceleration;
    if (diff < 1) diff = 0;
    else if (diff > 5) diff = 5;

    if (getGameTime()%(6-diff)==0)
    {
        CSprite@ sprite = this.getSprite();
        if (sprite is null) return;

        CInventory@ inv = this.getInventory();
        if (inv is null) return;

        bool stop = false;

        if (inv.getItemsCount() == 0)
        {
            sprite.SetFrameIndex(0);
            stop = true;
            return;
        }
        if (!stop)
        {
            bool has_stone;
            bool has_dirt;
            u8 frame = this.get_u8("frame");
            if (frame == 0) frame = 1;

            CBlob@ stone = inv.getItem("mat_stone");
            CBlob@ dirt = inv.getItem("mat_dirt");
            if (stone !is null && stone.getQuantity() < 100) @stone = null;
            if (dirt !is null && dirt.getQuantity() < 100) @dirt = null;

            if (stone !is null && dirt is null) // stone
                this.set_u8("type", 0);
            else if (stone is null && dirt !is null) // dirt
                this.set_u8("type", 1);
            else 
                this.set_u8("type", 0);

            u8 type = this.get_u8("type");

            switch (type)
            {
                case 0:
                {
                    if (stone !is null) sprite.SetFrameIndex(frame);
                    break;
                }
                case 1:
                {
                    if (dirt !is null) sprite.SetFrameIndex(7+frame);
                    break;
                }
            }
            //printf("frame: "+this.get_u8("frame"));

            this.set_u8("frame", frame + 1);
            if (frame > 6)
            {
                sprite.SetFrameIndex(0);
                this.set_u8("frame", 0);
                this.set_u8("type", 255);
            }
        }
    }  
}