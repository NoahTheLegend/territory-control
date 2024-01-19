#include "CustomBlocks.as";
#include "MapType.as";

const string[] OffiMaps = {
	"Vamfistorio_Noah",
	"TFlippy_TC_Thomas",
    "Xeno_Plains&Hills",
	"Xeno_TC_Graveyard",
	"TFlippy_TC_Reign",
	"TFlippy_TC_Mesa",
	"TFlippy_TC_Bobox",
	"TFlippy_TC_Derpo",
	"TFlippy_TC_Fug",
	"TFlippy_TC_Tenshi_Lakes",
	"TFlippy_TC_Valley",
	"TFlippy_Rob_TC_Socks",
	"Imbalol_TC_OilRig",
	"Imbalol_TC_UPFCargo",
	"Ginger_TC_Bridge",
	"Ginger_TC_Ridgelands_V2",
	"Ginger_TC_Royale_V3",
	"Ginger_Tenshi_TC_Generations_V1",
	"Ginger_TC_Drudgen",
	"Ginger_TC_Bombardment_V2",
	"Ginger_TC_Dehydration",
	"Ginger_TC_Murderholes_V2",
	"Ginger_TC_Aether",
	"Ginger_TC_Royale",
	"Ginger_TC_Highlands_V4",
	"Ginger_TC_Samurai.png",
	"Ginger_TC_Cove_v2",
	"JmD_TC_Poultry_v6",
	"Sylw_LawrenceSlum",
	"Tenshi_TC_WellOiledMachine_v2",
	"Goldy_TC_Sewers_v2",
	"Goldy_TC_Netherland_v2",
	"Skemonde_TC_Gooby_v3fM",
	"Skemonde_TC_Morgenland_v3",
	"NoahTheLegend_Deadborn.png"
};

const string[] MemeMaps = {
	"TFlippy_THD_TC_Foghorn",
	//"Goldy_TC_DoubleVision", //too laggy to use
	//"Goldy_TC_ThomsMega_Smoll", //E bug
	//"Imbalol_TC_City_v1",
	"Imbalol_TC_LongForgotten",
	//"Maybe_Cool_Tc_Map",
	//"Naime_TC_Land",
	"Ginger_TC_Mookcity",
	"Ginger_TC_Bebop",
	//"Imbalol_TC_Joker2",
	"TFlippy_UncleBen_v5",
	"WorldsCollide",
	"Goldy_TC_Hollows",
	//"Xeno_TC_BlackMarket",
	"Xeno_TC_AncientTemple",
	"Vamistorio_TC_IkoPit_v2"
};

const string[] OldMaps = {
	"Ginger_TC_Pirates",
	"Imbalol_TC_ChickenKingdom_v2",
	"Tenshi_TC_DeadEchoSeven_v1",
	"Ginger_TC_Seaside",
	"Ginger_TC_Highlands",
	"Goldy_TC_Netherland_v2", //a bit unstable
	"TFlippy_TC_Nostalgia",
	"Goldy_TC_Propesko",
	"Xeno_TC_AncientTemple",
	"Imbalol_TC_OilRig",
	"Imbalol_TC_UPFCargo",
	"TFlippy_TC_Skynet",
	"TFlippy_THD_TC_Kagtorio",
	"Ginger_Tenshi_TC_Extinction",
	"Goldy_TC_Hollows",
	"Goldy_TC_Basement_v2",
	"Ginger_TC_Equinox",
	"Ginger_TC_Lagoon",
	"TFlippy_TC_Thomas"
};

void onInit(CRules@ this)
{
	Reset(this, getMap());

	this.set("maptypes-offi", OffiMaps);
	this.set("maptypes-meme", MemeMaps);
	this.set("maptypes-old", OldMaps);

}

void onRestart(CRules@ this)
{
	Reset(this, getMap());
}

void onRulesRestart(CMap@ this, CRules@ rules)
{
	Reset(rules, this);
}

void Reset(CRules@ this, CMap@ map)
{
	if (map !is null)
	{
		if (!this.exists("map_type")) this.set_u8("map_type", MapType::normal);
	}
}
