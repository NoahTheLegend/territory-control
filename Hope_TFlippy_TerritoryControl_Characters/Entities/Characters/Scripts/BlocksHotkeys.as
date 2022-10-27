#include "BuildBlock.as";
#include "CommonBuilderBlocks.as";

u16 idk;
u16 idklast;

void onInit(CBlob@ this)
{
    for (u8 i = 0; i < 10; i++)
    {
        this.addCommandID("open_bindings"+i);
    }
    
    this.addCommandID("open_preset");
    this.addCommandID("reset_binding");

    if (this.getName() == "peasant")
    {
        idk = 64;
        idklast = 99;
    }
    else if (this.getName() == "engineer")
    {
        idk = 56;
        idklast = 98;
    }
    else if (this.getName() == "advancedengineer")
    {
        idk = 59;
        idklast = 99;
    }
    else
    {
        idk = 58;
        idklast = 98;
    }

    AddIconToken("$bicon$", "World.png", Vec2f(8, 8), 49);
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
    if (player is null) return;
    if (isClient())
	{
		CPlayer@ l = getLocalPlayer();
		if (player is l)
		{
            ConfigFile@ cfg = ConfigFile();
            cfg.loadFile("../Cache/TCBlocks.cfg");
            for (u8 i = 0; i < 10; i++)
            {
                if (cfg.exists("b"+i)) this.set_string("b"+i, cfg.read_string("b"+i));
                else cfg.add_string("b"+i, ""+i);
            }
            cfg.saveFile("TCBlocks.cfg");
        }
    }
}

Vec2f MENU_POS;

void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu@ gridmenu)
{
	const string name = this.getName();

    CBitStream params;
	params.write_u16(this.getNetworkID());

    Vec2f ul = gridmenu.getUpperLeftPosition();
	if (name == "peasant") MENU_POS = ul + Vec2f(-36, -460);
    else if (name == "builder") MENU_POS = ul + Vec2f(-84, -386);
    else if (name == "rockman") MENU_POS = ul + Vec2f(-84, -364);
	else MENU_POS = ul + Vec2f(-36, -386);

	CGridMenu@ cgm = CreateGridMenu(MENU_POS, this, Vec2f(1, 1), "Bindings");

	if (cgm !is null)
	{
		cgm.SetCaptionEnabled(false);
		cgm.deleteAfterClick = false;

		if (this !is null && this.isMyPlayer())
		{
			CGridButton@ bindings = cgm.AddButton("$bicon$", "\n", this.getCommandID("open_preset"), Vec2f(1, 1), params);
			if (bindings !is null)
			{
				bindings.SetHoverText("Open blocks bindings");
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    CInventory@ inv = this.getInventory();
    if (inv is null) return;
    if (!this.isMyPlayer()) return;

    if (cmd == this.getCommandID("open_preset"))
    {
        u16 netid;
        if (!params.saferead_u16(netid)) return;
        CBlob@ caller = getBlobByNetworkID(netid);
        if (caller is null) return;
        //printf("name: "+caller.getName());
        if (!caller.isMyPlayer()) return;
        this.ClearGridMenus();
        CGridMenu@ cgm = CreateGridMenu(MENU_POS, this, Vec2f(5, 2), "Bindings");
        if (cgm is null) return;
        
        for (u8 i = 0; i < 10; i++)
        {
            BuildBlock[][] blocks;
            addCommonBuilderBlocks(blocks, this.getTeamNum());
	        this.get(blocks_property, blocks);
            if (blocks is null) continue;
            BuildBlock@ bl = blocks[0][parseInt(this.get_string("b"+i))];
            if (bl is null) continue;
            CGridButton@ b = cgm.AddButton(bl.icon, "\n", this.getCommandID("open_bindings"+i), Vec2f(1, 1), params);
			if (b !is null)
			{
				b.SetHoverText("Open blocks bindings");
			}
        }
    }
    else if (cmd == this.getCommandID("reset_binding"))
    {
        this.set_bool("binding", false);
		this.Sync("binding", true);
    }
    for (u8 i = 0; i < 10; i++)
    {
        if (cmd == this.getCommandID("open_bindings"+i))
        {
            //printf("cmd "+this.getCommandID("open_bindings"+i));
            this.set_u8("bind_req", i);
            this.Sync("bind_req", true);

            u32 wd = getDriver().getScreenWidth();
            u32 ht = getDriver().getScreenHeight();

            MakeBlocksMenu(inv, Vec2f(wd/2, ht));
        }
    }
}

const u8 GRID_SIZE = 48;
const u8 GRID_PADDING = 12;

void MakeBlocksMenu(CInventory@ this, const Vec2f &in INVENTORY_CE)
{
	CBlob@ blob = this.getBlob();
	if(blob is null) return;
    blob.ClearGridMenus();
    blob.set_bool("binding", true);
    blob.Sync("binding", true);

	int teamnum = blob.getTeamNum();
	if (blob.getTeamNum() > 6) teamnum = 7;

	BuildBlock[][] blocks;
	addCommonBuilderBlocks(blocks, teamnum);
	blob.get(blocks_property, blocks);
	if(blocks is null) return;

    Vec2f MENU_SIZE;
    if (blob.getName() == "peasant") MENU_SIZE = Vec2f(4, 8);
    else MENU_SIZE = Vec2f(6, 8);

	const Vec2f MENU_CE = Vec2f(0, MENU_SIZE.y * -GRID_SIZE - GRID_PADDING + 48) + INVENTORY_CE;

	CGridMenu@ menu = CreateGridMenu(MENU_CE, blob, MENU_SIZE, "Bindings");
	if(menu !is null)
	{
		menu.deleteAfterClick = true;

		for(u8 i = 0; i < blocks[0].length; i++)
		{
			BuildBlock@ b = blocks[0][i];
			if(b is null) continue;
            
			CGridButton@ button = menu.AddButton(b.icon, "Bindings", idk + i);

			if(button is null) continue;

			button.selectOneOnClick = true;
		}
	}
}

void onTick(CBlob@ this)
{
    CPlayer@ p = getLocalPlayer();
    if (p is null) return;
    if (!p.isMyPlayer()) return;

    if (this.hasTag("reload blocks"))
	{
		this.Untag("reload blocks");
		onInit(this);
	}

	CControls@ controls = getControls();
	if (controls.ActionKeyPressed(AK_BUILD_MODIFIER))
	{
		for (uint i = 0; i < 10; i++)
		{
			if (controls.isKeyJustPressed(KEY_KEY_1 + i))
			{
				this.SendCommand(idk + parseInt(this.get_string("b"+i)));
			}
		}
	}
}