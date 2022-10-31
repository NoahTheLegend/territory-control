
SColor[] colors = {
    SColor(255, 155, 155, 0),
    SColor(255, 175, 175, 175),
    SColor(255, 50, 175, 50),
    SColor(255, 25, 25, 25)
};

void onRender(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null) return;
    if (blob.get_bool("inactive")) return;
    bool elec_skip = (blob.hasTag("sentry") && blob.getTeamNum() >= 7);
    if (elec_skip) return;
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	bool mouseOnBlob = (mouseWorld - blob.getPosition()).getLength() < this.getBlob().getRadius();
	u32 elec = blob.get_u32("elec");
	if (mouseOnBlob)
	{
		Vec2f pos = blob.getInterpolatedScreenPos();

		GUI::SetFont("menu");
        if (elec == 0 && blob.hasTag("generator"))
        {
		    if (!blob.hasTag("no fuel hint")) GUI::DrawTextCentered("Requires "+(blob.getName()!="beamtowermirror"?"fuel!":"more sun power!"), Vec2f(pos.x, pos.y + 50 + Maths::Sin(getGameTime() / 5.0f) * 5.0f), SColor(255, 255, 55, 55));
		    if (blob.getName() == "generator") GUI::DrawTextCentered("(Wood or coal)", Vec2f(pos.x, pos.y + 65 + Maths::Sin(getGameTime() / 5.0f) * 5.0f), SColor(255, 255, 55, 55));
            else if (blob.getName() == "lgenerator") GUI::DrawTextCentered("(Oil, methane or fuel)", Vec2f(pos.x, pos.y + 65 + Maths::Sin(getGameTime() / 5.0f) * 5.0f), SColor(255, 255, 55, 55));
            //else if (blob.getName() == "nuclearreactor") GUI::DrawTextCentered("(Enriched mithril)", Vec2f(pos.x, pos.y + 65 + Maths::Sin(getGameTime() / 5.0f) * 5.0f), SColor(255, 255, 55, 55));
        }
        else
        {
            Vec2f lpadoffset = blob.hasTag("launchpad") ? Vec2f(0, 64.0f) : Vec2f(0,0);
            string ispole = blob.getName() != "pole" ? "/"+blob.get_u32("elec_max") : "";
            GUI::DrawTextCentered("Electricity: "+elec+ispole, Vec2f(pos.x, pos.y + 50)+lpadoffset, SColor(255, 220, 220, 0));
        }
    }

    bool drawWire = blob.get_bool("draw_wire");
    SColor color;
    //if (getBlobByName("sandstorm") !is null) color = colors[0];
    //if (getBlobByName("blizzard") !is null) color = colors[1];
    //if (getBlobByName("info_dead") !is null) color = colors[2];
    color = colors[3];

    if (getLocalPlayer() !is null && getLocalPlayer().isMyPlayer() && getMap().getBlobAtPosition(getControls().getMouseWorldPos()) is blob)
    {
        if (drawWire)
        {
            CBlob@ inherit = getBlobByNetworkID(blob.get_u16("inherit_id"));
            if (inherit !is null && blob.getDistanceTo(inherit) < blob.get_f32("max_dist"))
            {
                Vec2f pos = blob.getInterpolatedPosition();
                Vec2f endpos = inherit.getInterpolatedPosition();

                GUI::DrawLine(pos, endpos, color);
            }
        }
        else if (!blob.hasTag("no_wire") && blob.hasTag("consumes energy") && blob.get_u16("feed_id") != 0)
        {
            CBlob@ feeder = getBlobByNetworkID(blob.get_u16("feed_id"));
            if (feeder !is null && blob.get_bool("state"))
            {
                Vec2f pos = blob.getInterpolatedPosition();
                Vec2f endpos = feeder.getInterpolatedPosition();

                GUI::DrawLine(pos + blob.get_Vec2f("wire_offset"), endpos, color);
            }
        }
        else if (!blob.hasTag("no_wire") && blob.hasTag("generator") && blob.get_u16("consume_id") != 0)
        {
            CBlob@ consumer = getBlobByNetworkID(blob.get_u16("consume_id"));
            if (consumer !is null && !consumer.get_bool("inactive"))
            {
                Vec2f pos = blob.getInterpolatedPosition();
                Vec2f endpos = consumer.getInterpolatedPosition();

                GUI::DrawLine(pos + blob.get_Vec2f("wire_offset"), endpos, color);
            }
        }
    }
}