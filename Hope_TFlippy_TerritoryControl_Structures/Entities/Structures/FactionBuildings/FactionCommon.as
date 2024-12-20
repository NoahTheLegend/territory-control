#include "Survival_Structs.as"

f32 faction_control_range = 256.0f;
const u8 MAX_HALL_AMOUNT = 2;
const u8 min_level_to_be_main = 2; // camp is 0

int calc_extra_halls_per_member(TeamData@ team_data)
{
    if (team_data is null) return 0;
    return Maths::Floor(team_data.player_count/2);
}

bool hasOtherHalls(CBlob@ this, CBlob@[] &out other_halls, int team = -1)
{
    if (team == -1) team = this.getTeamNum();
    CBlob@[] halls;
    bool has_other = false;

    getBlobsByTag("faction_base", @halls);
    for (int i = 0; i < halls.size(); i++)
    {
        CBlob@ hall = halls[i];
        if (hall is null || hall is this) continue;

        if (hall.getTeamNum() == team)
        {
            has_other = true;
            other_halls.push_back(@hall);
        }
    }

    return has_other;
}

const string[] nato_alphabet = {
    "Alpha", "Beta", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", 
    "Hotel", "India", "Juliett", "Kilo", "Lima", "Mike", "November", 
    "Oscar", "Prince", "Quebec", "Romeo", "Sierra", "Tango", "Uniform", 
    "Victor", "Whiskey", "X-ray", "Yankee", "Zulu"
};

void MakeGenericName(CBlob@ this)
{
    string[] picked_names;
    CBlob@[] other_halls;

    if (hasOtherHalls(this, other_halls))
    {
        for (int i = 0; i < other_halls.size(); i++)
        {
            CBlob@ hall = other_halls[i];
            if (hall is null) continue;

            string numeric_name = hall.get_string("numeric_camp_name");
            if (numeric_name == "") continue;

            picked_names.push_back(numeric_name);
        }
    }
    
    for (int i = 0; i < nato_alphabet.size(); i++)
    {
        if (picked_names.find(nato_alphabet[i]) == -1)
        {
            string name = "Hall \""+nato_alphabet[i]+"\"";
            this.set_string("new_camp_name", name);
            this.set_string("numeric_camp_name", nato_alphabet[i]);
			this.setInventoryName(this.get_string("new_camp_name"));

            SyncBaseName(this);
            
            //warn("SET NAME "+name+" NUMERIC "+nato_alphabet[i]);
            return;
        }
    }
}

void SetMainHall(CBlob@ this, TeamData@ team_data)
{
    if (team_data is null) return;

    team_data.main_hall_id = this.getNetworkID();
	this.Tag("main_hall");

    SyncMainData(this);
    printf("Set main hall ("+this.getName()+") for team "+team_data.team+": "+this.getNetworkID());
}

bool canBlockBuilding(CBlob@ this)
{
    string name = this.getName();

    if (name == "stronghold"
        || name == "citadel"
        || name == "convent") return true; //todo: rework this to be automatic

    return false;
}

string[] hall_names = {
    "Camp", "Fortress", "Stronghold", "Citadel", "Convent"
};

string getRequiredMainHallName()
{
    return hall_names[min_level_to_be_main];
}

void ResetMainHall(CBlob@ this, u8 team)
{
    if (!isServer()) return;

    TeamData@ team_data;
	GetTeamData(team, @team_data);

	CBlob@[] other_halls;
	if (hasOtherHalls(this, other_halls, team))
	{
		u16 id = 0;
		f32 temp_dist = 9999.0f;

		for (int i = 0; i < other_halls.size(); i++)
		{
			CBlob@ hall = other_halls[i];
			if (hall is null) continue;

			f32 distance_to_this = Maths::Sqrt(hall.getDistanceTo(this));
			if (distance_to_this < temp_dist)
			{
				temp_dist = distance_to_this;
				id = hall.getNetworkID();
			}
		}

		if (id != 0)
		{
			CBlob@ closest_hall = getBlobByNetworkID(id);
			if (closest_hall !is null)
			{
                SetMainHall(closest_hall, team_data);
                SyncMainData(closest_hall);
			}
		}
	}
	else
    {
        team_data.main_hall_id = 0;
        SyncMainData(this, 0); // probably dangerous, its running in onDie() hook
    }
}

const u8 init_sync_from_client_id = 199;
const u8 sync_base_name_id = 200;
const u8 sync_main_data_id = 201;

void SyncBaseName(CBlob@ this)
{
    if (!isServer()) return;

    CBitStream params;
    params.write_string(this.get_string("base_name"));
    params.write_string(this.get_string("new_camp_name"));
    params.write_string(this.get_string("numeric_camp_name"));
    this.SendCommand(sync_base_name_id, params);

    //printf("sent sync-"+sync_base_name_id+" (hall name); "+this.getName()+": "+this.getInventoryName());
}

void SyncMainData(CBlob@ this, int id = -1)
{
    if (!isServer()) return;
    
    CBitStream params;
    params.write_u16(id == 0 ? id : this.getNetworkID());
    params.write_bool(this.hasTag("main_hall"));
    this.SendCommand(sync_main_data_id, params);

    //printf("sent sync-"+sync_main_data_id+" (data); from "+this.getName()+": "+this.hasTag("main_hall"));
}

void SyncMainDataToPlayer(CBlob@ this, int id = -1, u16 pid = 0)
{
    if (!isServer()) return;
    
    CBitStream params;
    params.write_u16(id == 0 ? id : this.getNetworkID());
    params.write_bool(this.hasTag("main_hall"));
    params.write_u16(pid);
    this.SendCommand(sync_main_data_id, params);

    //printf("sent sync-"+sync_main_data_id+" (data); from "+this.getName()+": "+this.hasTag("main_hall"));
}