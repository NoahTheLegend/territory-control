// OneClassAvailable.as

#include "StandardRespawnCommand.as";
#include "DeityCommon.as";

const string req_class = "required class";
const string req_tag = "required tag";

void onInit(CBlob@ this)
{
	AddIconToken("$change_class$", "/GUI/InteractionIcons.png", Vec2f(32, 32), 12, 2);

	this.Tag("change class drop inventory");
	if(!this.exists("class offset"))
		this.set_Vec2f("class offset", Vec2f_zero);

	if(!this.exists("class button radius"))
	{
		CShape@ shape = this.getShape();
		if(shape !is null)
		{
			this.set_u8("class button radius", Maths::Max(this.getRadius(), (shape.getWidth() + shape.getHeight())));
		}
		else
		{
			this.set_u8("class button radius", 16);
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if(!this.exists(req_class))
	{
		return;
	}

	if (caller.hasTag("exploding")) return;

	bool CanChange = true;
	
	if(this.exists(req_tag)){
		if(!caller.hasTag(this.get_string(req_tag))) CanChange = false;
	}

	string cfg = this.get_string(req_class);
	if (canChangeClass(this, caller) && caller.getName() != cfg && CanChange)
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		write_classchange(params, caller.getNetworkID(), cfg);

		u8 deity_id = caller.get_u8("deity_id");
		bool tried_use_only_faction = this.hasTag("only faction") && caller.getTeamNum() > 6 && deity_id != Deity::gregor;

		CButton@ button = caller.CreateGenericButton(
		"$change_class$",                           // icon token
		this.get_Vec2f("class offset"),             // button offset
		this,                                       // button attachment
		SpawnCmd::changeClass,                      // command id
		tried_use_only_faction ? "Only for factioneers" : "Swap Class",                               // description
		params);                                    // bit stream

		if (tried_use_only_faction)
		{
			button.SetEnabled(false);
		}

		button.enableRadius = this.get_u8("class button radius");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (this.hasTag("dead")) return;

	u16 id = params.read_u16();
	CBlob@ caller = getBlobByNetworkID(id);
	if (caller !is null)
		if (caller.hasTag("exploding")) return;
	
	onRespawnCommand(this, cmd, params);

	if (this.hasTag("kill on use"))
	{
		this.Tag("dead");

		if (isServer()) 
		{
			this.server_Die();
		}
	}
}
