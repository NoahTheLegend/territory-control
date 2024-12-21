#include "Survival_Structs.as";
#include "FactionCommon.as";

void onInit(CBlob@ this)
{
	if (isServer())
	{
		TeamData@ team_data;
	    GetTeamData(this.getTeamNum(), @team_data);
		if (team_data is null) return;
		
		if (team_data.main_hall_id == 0
	    	|| getBlobByNetworkID(team_data.main_hall_id) is null)
	    {
	    	SetMainHall(this, team_data);
			SyncMainData(this);
	    }
	}
}

void onTick(CBlob@ this)
{
	if (isClient() && this.getTickSinceCreated() == 1)
	{
		CPlayer@ local = getLocalPlayer();
		if (local !is null)
		{
        	CBitStream params;
			params.write_u16(local.getNetworkID());
        	this.SendCommand(init_sync_from_client_id, params);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ inParams)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		u16 caller, item;

		if(!inParams.saferead_netid(caller) || !inParams.saferead_netid(item)) return;
		string data = inParams.read_string();

		if (data == "fortress" || data == "stronghold" || data == "citadel" || data == "convent")
		{
			Vec2f pos = this.getPosition();
			u8 team = this.getTeamNum();

			this.Tag("upgrading");
			this.getSprite().PlaySound("/Construct.ogg");
			this.getSprite().getVars().gibbed = true;

			if (isServer())
			{
				CBlob@ newBlob = server_CreateBlobNoInit(data);
				newBlob.server_setTeamNum(team);
				newBlob.setPosition(pos);
				newBlob.Init();

				if (this.hasTag("main_hall"))
				{
					TeamData@ team_data;
	   				GetTeamData(this.getTeamNum(), @team_data);
					if (team_data !is null)
					{
						SetMainHall(newBlob, team_data);
						SyncMainData(newBlob);
					}
				}

				newBlob.set_string("base_name", this.get_string("base_name"));
				newBlob.set_string("new_camp_name", this.get_string("new_camp_name"));
				newBlob.set_string("numeric_camp_name", this.get_string("numeric_camp_name"));
				newBlob.Tag("need_sync");

				this.MoveInventoryTo(newBlob);
				this.server_Die();
			}
		}
	}
    if (cmd == init_sync_from_client_id)
    {
        if (!isServer()) return;

		u16 pid = 0;
		if (!inParams.saferead_u16(pid)) {}

        TeamData@ team_data;
	    GetTeamData(this.getTeamNum(), @team_data);
		if (team_data is null) return;

        if (this.getName() == "camp")
        {
            this.set_string("numeric_camp_name", "init");
	        if (this.getTeamNum() < 7) MakeGenericName(this);
        }

	    if (team_data.main_hall_id == 0
	    	|| getBlobByNetworkID(team_data.main_hall_id) is null)
	    {
	    	SetMainHall(this, team_data);
	    }

		SyncBaseName(this);
		if (pid == 0) SyncMainData(this);
		else SyncMainDataToPlayer(this, -1, pid);
    }
	else if (cmd == sync_main_data_id)
	{
		if (!isClient()) return;

		u16 id = inParams.read_u16();
		bool do_tag = inParams.read_bool();

		u16 pid = 0;
		if (!inParams.saferead_u16(pid)) {}

		if (pid != 0 && getPlayer(pid) !is null && !getPlayer(pid).isMyPlayer())
			return;

		TeamData@ team_data;
		GetTeamData(this.getTeamNum(), @team_data);
		if (team_data is null) return;

		team_data.main_hall_id = id;
		if (do_tag) this.Tag("main_hall");
		else this.Untag("main_hall");
	}
	else if (cmd == sync_base_name_id)
	{
		if (!isClient()) return;

		string name = inParams.read_string();
		string hall_name = inParams.read_string();
		string numeric_name = inParams.read_string();

		this.set_string("base_name", name);
		this.set_string("new_camp_name", hall_name);
        this.set_string("numeric_camp_name", numeric_name);

		this.setInventoryName(hall_name);
	}
}