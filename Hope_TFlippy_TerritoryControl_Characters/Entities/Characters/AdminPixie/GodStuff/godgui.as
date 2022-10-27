//#include "GUICommon.as"
#include "godCommon.as"

void onRender( CSprite@ this )
{
    f32 scale = 1;

    CBlob@ blob = this.getBlob();

    IEffectMode@ mode;
    blob.get("mode",@mode);
    if(mode !is null && !blob.hasTag("nogod"))
    {
        mode.render(this,scale);
    }
}