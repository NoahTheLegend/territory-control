
void onInit(CSprite@ this)
{
    CBlob@ b = this.getBlob();

    this.SetZ(1450);// draw over ground
    CSpriteLayer@ s = this.addSpriteLayer("glow","team_color_circle",100,100);
    s.ScaleBy(Vec2f(0.1,0.1));
    s.SetRelativeZ(-1);
    b.set_f32("soft_frame",0);
}

const f32 speedConst = 0.1; //this is an arbitrary value :D

void onTick(CSprite@ this)
{
    if(this.getBlob().getPlayer() is getLocalPlayer())
    {
        getHUD().SetCursorImage("arrow_cursor.png");
    }

    CSpriteLayer@ glow = this.getSpriteLayer("glow");

    glow.setRenderStyle(RenderStyle::Style::light);//done every tick so that it doesn't break on team change, probably bad /shrug

    CBlob@ b = this.getBlob();
    if(b is null) return;
    Vec2f vel = b.getVelocity();
    f32 speed = Maths::Abs(vel.x) + Maths::Abs(vel.y) + 1; //const is to keep it moving when hovering
    speed = speed > 6 ? 6 : speed;//cap it

    f32 softframe = b.add_f32("soft_frame", speed * speedConst);

    if(softframe > 4)
    {
        b.set_f32("soft_frame",0);
    }
    b.set_u16("frame",softframe);
    this.SetFrame(b.get_u16("frame"));
}

void onRender(CSprite@ this)
{
    f32 scale = 1;
    Vec2f mpos = getControls().getMouseScreenPos();
    CBlob@ blob = this.getBlob();
    if(getLocalPlayer() is blob.getPlayer())
    {
        int width = 93 * 2;
        int height = 44;
        int teamNum = blob.getTeamNum();

        Vec2f checkbox1 = Vec2f(57,8) * scale;
        Vec2f checkbox2 = Vec2f(57,26) * scale;

        Vec2f mainPos = Vec2f(getScreenWidth() - width * scale - 20, 20);
        GUI::DrawIcon("MainGui.png",0, Vec2f(width,height), mainPos, scale, teamNum);

        if(!blob.get_bool("noclip"))
        {
            GUI::DrawIcon("CheckBoxUnchecked.png",0, Vec2f(11,11),mainPos + checkbox1*2,scale);
        }
        if(!blob.get_bool("gravity"))
        {
            GUI::DrawIcon("CheckBoxUnchecked.png",0, Vec2f(11,11), mainPos + checkbox2*2,scale);
        }
    }
}