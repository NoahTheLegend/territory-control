
u32 smartStorageTake(CBlob@ this, string blobName, u32 quantity)
{
	u32 max_quantity;
	for (u8 i = 0; i < maxQuantities.length; i++)
	{
		string[] spl = maxQuantities[i].split("-");
		if (spl.length > 1)
		{
			string name = spl[0];
			u32 value = parseInt(spl[1]);
			if (name == blobName) max_quantity = value;
			break;
		}
		else max_quantity = 1;
	}
	u32 cur_quantity = this.get_u32("Storage_"+blobName);
	if (cur_quantity > 0)
	{
		u32 amount = Maths::Min(cur_quantity, quantity);
		if (isServer())
		{
			if ((cur_quantity - quantity)%max_quantity == 0)
			{
				this.sub_u16("smart_storage_quantity", 1);
				this.Sync("smart_storage_quantity", true);
			}
			this.sub_u32("Storage_"+blobName, amount);
			this.Sync("Storage_"+blobName, true);
		}
		return cur_quantity;
	}
	return 0;
}

u32 smartStorageCheck(CBlob@ this, string blobName)
{
	if (this.exists("Storage_"+blobName)) return this.get_u32("Storage_"+blobName);
	return 0;
}

const string[] factionStorageMats =
{
	"mat_copperingot",
	"mat_ironingot",
	"mat_steelingot",
	"mat_goldingot",
	"mat_mithrilingot",
	"mat_titaniumingot",
	"mat_wood",
	"mat_stone",
	"mat_plasteel",
	"mat_concrete",
	"mat_dirt",
	"mat_sulphur",
	"mat_copperwire",
	"mat_iron",
	"mat_copper",
	"mat_titanium",
	"mat_gold",
	"mat_coal",
	"mat_carbon",
	"mat_mithril",
	"mat_mithrilenriched",
	"mat_wilmet",
	"mat_matter",
	"mat_meat",
	"mat_battery",
	"mat_sammissile",
	"foodcan",
	"pumpkin",
	"grain",
	"ganjapod",
	"mat_ganja",
	"vodka",
	"mat_acid",
	"mat_oil",
	"mat_methane",
	"mat_fuel",
	"mat_smallrocket",
	"mat_grenade",
	"mat_pistolammo",
	"mat_rifleammo",
	"mat_gatlingammo",
	"mat_shotgunammo",
	"mat_banditammo",
	"mat_sniperammo"
};
const string[] maxQuantities =
{
	"mat_copperingot-300",
	"mat_ironingot-300",
	"mat_steelingot-300",
	"mat_goldingot-300",
	"mat_mithrilingot-300",
	"mat_titaniumingot-300",
	"mat_wood-2000",
	"mat_stone-2000",
	"mat_plasteel-500",
	"mat_concrete-3000",
	"mat_dirt-1000",
	"mat_sulphur-500",
	"mat_copperwire-200",
	"mat_iron-1000",
	"mat_copper-1000",
	"mat_titanium-1000",
	"mat_gold-500",
	"mat_coal-250",
	"mat_carbon-250",
	"mat_mithril-250",
	"mat_mithrilenriched-50",
	"mat_wilmet-500",
	"mat_matter-250",
	"mat_meat-250",
	"mat_battery-50",
	"mat_sammissile-3",
	"foodcan-2",
	"pumpkin-2",
	"grain-5",
	"ganjapod",
	"mat_ganja-250",
	"vodka",
	"mat_acid-50",
	"mat_oil-50",
	"mat_methane-100",
	"mat_fuel-50",
	"mat_smallrocket-3",
	"mat_grenade-4",
	"mat_pistolammo-200",
	"mat_rifleammo-150",
	"mat_gatlingammo-500",
	"mat_shotgunammo-80",
	"mat_banditammo-40",
	"mat_sniperammo-50"
};