const f32 MAX_LENGTH = 56.0f; // max hook distance, if more it cuts off
#include "RopeCommon.as";

void onInit(CBlob@ this)
{
    this.Tag("hook_attachable");
    this.addCommandID("attach_rope");
    this.addCommandID("detach_rope");
    this.addCommandID("detach_hook");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBlob@ carried = caller.getCarriedBlob();
	CBitStream params;
	params.write_u16(caller.getNetworkID());

	if (carried !is null && carried.getName() == "rope")
    {
        CButton@ button = caller.CreateGenericButton(17, Vec2f(0, 0), this, this.getCommandID("attach_rope"), "Attach "+carried.getInventoryName(), params);
        if (button !is null)
        {
            if ((carried.getPosition()-this.getPosition()).Length() > MAX_LENGTH-8.0f) button.SetEnabled(false);
        }
    }
    if ( this.get_u16("ropeid") > 0)
    {
        CButton@ button = caller.CreateGenericButton(16, Vec2f(0, 0), this, this.getCommandID("detach_rope"), "Detach rope", params);
    }
    if (this.get_u16("hookid") > 0)
    {
        CButton@ button = caller.CreateGenericButton(16, Vec2f(0, 0), this, this.getCommandID("detach_hook"), "Detach hook", params);
    }
}

void onTick(CBlob@ this)
{
    if (this.get_u16("hookid") != 0)
    {
        CBlob@ blob = getBlobByNetworkID(this.get_u16("hookid"));
        if (blob !is null)
        {
            Vec2f dir = blob.getPosition()-this.getPosition();
            if (dir.Length() > MAX_LENGTH || this.isAttached())
            {
                Rope@ SegmentSettings;
                if (blob.get("RopeSettings", @SegmentSettings)) SegmentSettings.SetHooked(null);
                this.set_u16("hookid", 0);
            }
            dir.Normalize();
            f32 mass = this.getMass();
            this.setPosition(blob.getPosition());
            this.AddForce(Vec2f((dir.x*mass)/3,dir.y*mass));
        }
    }
    if (this.get_u16("ropeid") != 0)
    {
        CBlob@ blob = getBlobByNetworkID(this.get_u16("ropeid"));
        if (blob !is null)
        {
            blob.setPosition(this.getPosition());
        }
    }
    if (this.get_u16("ropeid") != 0 && this.get_u16("hookid") != 0)
    {
        CBlob@ rope = getBlobByNetworkID(this.get_u16("ropeid"));
        CBlob@ hook = getBlobByNetworkID(this.get_u16("hookid"));
        if (rope !is null && hook !is null)
        {

        }
    }
}  

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("attach_rope"))
	{
        u16 id;
        if (!params.saferead_u16(id)) return;
        CBlob@ caller = getBlobByNetworkID(id);
        if (caller is null) return;
        CBlob@ carried = caller.getCarriedBlob();
        if (carried is null || carried.getName() != "rope") return;

        bool is_hook =  carried.getInventoryName() == "Hook";

        if (is_hook)
        {
            this.set_u16("hookid", carried.getNetworkID());
            carried.server_DetachFromAll();

            Rope@ SegmentSettings;
            if (carried.get("RopeSettings", @SegmentSettings))
            {
                SegmentSettings.SetHooked(@this);
            }
        }
        else
        {
            this.set_u16("ropeid", carried.getNetworkID());
            carried.server_DetachFromAll();

            Rope@ SegmentSettings;
            if (carried.get("RopeSettings", @SegmentSettings))
            {
                SegmentSettings.SetCarrier(@this);
            }
        }
    }
    else if (cmd == this.getCommandID("detach_rope"))
    {
        u16 param;
        u16 id;
        if (!params.saferead_u16(id)) return;
        CBlob@ caller = getBlobByNetworkID(id);
        if (caller is null) return;
        CBlob@ carried = getBlobByNetworkID(this.get_u16("ropeid"));
        if (carried is null) return;

        this.set_u16("ropeid", 0);
        Rope@ SegmentSettings;
        if (carried.get("RopeSettings", @SegmentSettings))
        {
            SegmentSettings.SetCarrier(null);
        }
    }
    else if (cmd == this.getCommandID("detach_hook"))
    {
        u16 param;
        u16 id;
        if (!params.saferead_u16(id)) return;
        CBlob@ caller = getBlobByNetworkID(id);
        if (caller is null) return;
        CBlob@ carried = getBlobByNetworkID(this.get_u16("hookid"));
        if (carried is null) return;

        this.set_u16("hookid", 0);
        Rope@ SegmentSettings;
        if (carried.get("RopeSettings", @SegmentSettings))
        {
            SegmentSettings.SetHooked(null);
        }
    }
}