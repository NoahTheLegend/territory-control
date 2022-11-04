// a script to detect the attachment bug
void onTick(CBlob@ this)
{
    //if (getGameTime() < this.get_u32("delayed")) return; // immediate pickup triggers the code
    CBlob@ blob = this.getCarriedBlob();
    //if (blob is null)
    //{
    //    this.set_u32("delayed", getGameTime()+3);
    //    return;
    //}
    //if (blob.getName() == "seed") return; // they are picked automatically
    if (blob !is null && blob.getTickSinceCreated() >= 1 && (blob.getPosition() - this.getPosition()).getLength()-this.getRadius() > 12.0f)
    {
        //if (!this.hasTag("broken_attach") || getGameTime()%1800==0)
        //{
        //    printf("ATTACHMENT BUG:\nblob name - "+this.getName()+"\ncarried name - "+blob.getName()+"\ngame time - "+getGameTime()+"\nblob tick time - "+this.getTickSinceCreated()+"\ncarried tick time - "+blob.getTickSinceCreated());
        //}
        
        AttachmentPoint@ ap = blob.getAttachments().getAttachmentPointByName("PICKUP");
        if (ap !is null)
        {
            blob.setPosition(this.getPosition()+ap.offset);
        }

        this.Tag("broken_attach");
    }
}