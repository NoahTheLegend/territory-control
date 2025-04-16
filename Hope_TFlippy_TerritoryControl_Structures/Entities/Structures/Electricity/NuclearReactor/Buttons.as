void ResetButtons(CBlob@ this)
{
    Vec2f[] a_empty;
    this.set("button_areas", @a_empty);
    
    Button@[] empty;
    this.set("buttons", empty);
}

void registerButton(CBlob@ this, Button@ button)
{
    if (button is null) return;

    Button@[]@ buttons;
    if (!this.get("buttons", @buttons))
    {
        ResetButtons(this);
        this.get("buttons", @buttons);
    }
    if (buttons is null) return;

    Vec2f[]@ areas; // pairs
    this.get("button_areas", @areas);
    if (areas is null) return;

    Vec2f tl = button.pos;
    Vec2f br = button.pos + button.size;
    areas.push_back(tl);
    areas.push_back(br);
    
    button.id = buttons.size();
    buttons.push_back(button);
}

class Button
{
    u16 blob_id;
    u8 id;
	string name;
	string icon;
	u8 icon_index;
	Vec2f icon_dim;
    f32 icon_scale;
    f32 icon_scale_const;
    Vec2f icon_offset;
	string tooltip;
	Vec2f pos;
	Vec2f size;
    Vec2f size_const;
	string cmd;
	
	SColor color;
	SColor border_color;
    SColor icon_color;
	u8 border_width;

    bool active;
    bool just_pressed;

    f32 tooltip_alpha;
    f32 tooltip_lerp;
    f32 customData;

	Button(u16 blob_id, string name, string icon, u8 icon_index, Vec2f icon_dim, f32 icon_scale, Vec2f icon_offset,
        string tooltip, Vec2f pos, Vec2f size, string cmd,
		SColor color = SColor(0, 255, 255, 255), SColor border_color = SColor(255, 0, 0, 0), u8 border_width = 2)
	{
        id = 0;
        active = false;
        just_pressed = false;
        customData = 0;
        this.icon_color = SColor(255, 255, 255, 255);

        this.blob_id = blob_id;
		this.name = name;
		this.icon = icon;
		this.icon_index = icon_index;
		this.icon_dim = icon_dim;
        this.icon_scale = icon_scale;
        this.icon_scale_const = icon_scale;
        this.icon_offset = icon_offset;
		this.tooltip = tooltip;
		this.id = id;
		this.pos = pos;
		this.size = size;
        this.size_const = size;
		this.cmd = cmd;
		this.color = color;
		this.border_color = border_color;
		this.border_width = border_width;

        tooltip_alpha = 0.0f;
        tooltip_lerp = 0.5f * getRenderExactDeltaTime() * 60;
	}

	void render(u8 alpha, bool hover = false, bool press = false)
	{
		Vec2f offset = Vec2f(0, 0);

        if (hover && just_pressed && !press && cmd != "")
        {
            CBlob@ local = getLocalPlayerBlob();
            if (local is null) return;

            CBlob@ blob = getBlobByNetworkID(blob_id);
            if (blob is null) return;

            CBitStream params;
            params.write_u16(local.getNetworkID());
            params.write_f32(customData);
            blob.SendCommand(blob.getCommandID(cmd), params);
        }

		if (hover && press && active)
        {
            just_pressed = true;
            offset = Vec2f(0, 1);
        }
        else just_pressed = false;

		SColor current_color = color;
		current_color.setAlpha(alpha);
		
		SColor current_border_color = border_color;
		current_border_color.setAlpha(alpha);

		// border without offset
        Vec2f border_offset = hover ? Vec2f(1, 0) : Vec2f(0, 0);
		GUI::DrawPane(pos + border_offset, pos + size - border_offset, current_border_color);

		// canvas
		if (color.getAlpha() != 0)
        {
			GUI::DrawPane(pos + offset + Vec2f(border_width, border_width), pos + size + offset - Vec2f(border_width, border_width), current_color);
        }
		// icon
		if (icon != "")
		{
            Vec2f centering = (size / 2 - Vec2f(icon_dim.x + icon_offset.x, icon_dim.y + icon_offset.y)) * icon_scale;
			GUI::DrawIconByName(icon, pos + offset + centering, icon_scale, icon_scale, 255, SColor(alpha, icon_color.getRed(), icon_color.getGreen(), icon_color.getBlue()));
		}

        if (!active)
        {
            tooltip_alpha = 0;
            return;
        }

        // tooltip
        if (hover) tooltip_alpha = Maths::Lerp(tooltip_alpha, 255, tooltip_lerp);
        else tooltip_alpha = Maths::Lerp(tooltip_alpha, 0, tooltip_lerp);
        if (tooltip_alpha > 1) DrawTooltip(pos, Maths::Min(alpha, tooltip_alpha));
	}

	void DrawTooltip(Vec2f pos, u8 alpha)
	{
        GUI::SetFont("menu");

		Vec2f dim;
		GUI::GetTextDimensions(tooltip, dim);

		Vec2f text_pos = pos + Vec2f(0, size.y);
		GUI::DrawPane(text_pos, text_pos + dim + Vec2f(8, 6), SColor(alpha, 100, 100, 100));
		GUI::DrawText(tooltip, text_pos + Vec2f(2,2), SColor(alpha, 255, 255, 255));

        GUI::SetFont("default");
	}
}

bool isInArea(Vec2f pos, Vec2f tl, Vec2f br)
{
    // debug
    //GUI::DrawRectangle(tl, br, SColor(255, 255, 0, 0));
    return pos.x >= tl.x && pos.x <= br.x && pos.y >= tl.y && pos.y <= br.y;
}