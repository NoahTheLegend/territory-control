
void onTick(CBlob@ this)
{
    CBlob@ blob = this.getCarriedBlob();
    if (blob is null) return;
    if ((blob.getPosition() - this.getPosition()).getLength()-this.getRadius() > 12.0f)
    {
        if (!this.hasTag("broken_attach"))
        {
            printf("ATTACHMENT BUG:\nblob name - "+this.getName()+"\ncarried name - "+blob.getName()+"\ngame time - "+getGameTime());
        }
        
        AttachmentPoint@ ap = blob.getAttachments().getAttachmentPointByName("PICKUP");
        if (ap !is null)
        {
            blob.setPosition(this.getPosition()+ap.offset);
        }

        this.Tag("broken_attach");
    }
}