// CommonBuilderBlocks.as

//////////////////////////////////////
// Builder menu documentation
//////////////////////////////////////

// To add a new page;

// 1) initialize a new BuildBlock array, 
// example:
// BuildBlock[] my_page;
// blocks.push_back(my_page);

// 2) 
// Add a new string to PAGE_NAME in 
// BuilderInventory.as
// this will be what you see in the caption
// box below the menu

// 3)
// Extend BuilderPageIcons.png with your new
// page icon, do note, frame index is the same
// as array index

// To add new blocks to a page, push_back
// in the desired order to the desired page
// example:
// BuildBlock b(0, "name", "icon", "description");
// blocks[3].push_back(b);


//#include "LoaderUtilities.as";
#include "BuildBlock.as";
#include "Requirements.as";
#include "Descriptions.as";
#include "CustomBlocks.as";

const string blocks_property = "blocks";
const string inventory_offset = "inventory offset";

void addCommonBuilderBlocks(BuildBlock[][]@ blocks, int teamnum = 7)
{
	AddIconToken("$glass_block$", "World.png", Vec2f(8, 8), CMap::tile_glass);
	AddIconToken("$bglass_block$", "World.png", Vec2f(8, 8), CMap::tile_bglass);
	AddIconToken("$concrete_block$", "World.png", Vec2f(8, 8), CMap::tile_concrete);
	AddIconToken("$bconcrete_block$", "World.png", Vec2f(8, 8), CMap::tile_bconcrete);
	AddIconToken("$iron_block$", "World.png", Vec2f(8, 8), CMap::tile_iron);
	AddIconToken("$biron_block$", "World.png", Vec2f(8, 8), CMap::tile_biron);
	AddIconToken("$reinforcedconcrete_block$", "World.png", Vec2f(8, 8), CMap::tile_reinforcedconcrete);
	AddIconToken("$titanium_block$", "World.png", Vec2f(8, 8), CMap::tile_titanium);
	AddIconToken("$ground_block$", "World.png", Vec2f(8, 8), 16);
	AddIconToken("$plasteel_block$", "World.png", Vec2f(8, 8), CMap::tile_plasteel);
	AddIconToken("$bplasteel_block$", "World.png", Vec2f(8, 8), CMap::tile_bplasteel);
	AddIconToken("$icon_stone_door$", "1x1StoneDoor.png", Vec2f(16, 8), 0, teamnum);
	AddIconToken("$icon_wooden_door$", "1x1WoodDoor.png", Vec2f(16, 8), 0, teamnum);
	AddIconToken("$icon_trapblock$", "TrapBlock.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$icon_irontrapblock$", "IronTrapBlock.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$icon_iron_door$", "1x1IronDoor.png", Vec2f(16, 8), 0, teamnum);
	AddIconToken("$icon_plasteel_door$", "1x1PlasteelDoor.png", Vec2f(16, 8), 0, teamnum);
	AddIconToken("$wood_triangle$", "WoodTriangle.png", Vec2f(8, 8), 0);
	AddIconToken("$stone_triangle$", "StoneTriangle.png", Vec2f(8, 8), 0);
	AddIconToken("$concrete_triangle$", "ConcreteTriangle.png", Vec2f(8, 8), 0);
	AddIconToken("$iron_triangle$", "IronTriangle.png", Vec2f(8, 8), 0);
	AddIconToken("$stone_halfblock$", "StoneHalfBlock.png", Vec2f(8, 8), 0);
	AddIconToken("$bricks_back_block$", "World.png", Vec2f(8, 8), CMap::tile_bricks_back);
	AddIconToken("$iron_halfblock$", "IronHalfBlock.png", Vec2f(8, 8), 0);
	AddIconToken("$icon_ironplatform$", "IronPlatform.png", Vec2f(8, 8), 0);
	AddIconToken("$icon_ironladder$", "IronLadder_Icon.png", Vec2f(16, 16), 0, teamnum);
	AddIconToken("$tnt_block$", "World.png", Vec2f(8, 8), CMap::tile_tnt);
	AddIconToken("$brick_block$", "World.png", Vec2f(8, 8), 412);
	AddIconToken("$sand_block$", "World.png", Vec2f(8, 8), 220);
	AddIconToken("$kudzu_block$", "World.png", Vec2f(8, 8), CMap::tile_kudzu);
	AddIconToken("$kudzu_back_block$", "World.png", Vec2f(8, 8), CMap::tile_kudzu_back);
	AddIconToken("$goldingot_block$", "World.png", Vec2f(8, 8), CMap::tile_goldingot);
	AddIconToken("$mithrilingot_block$", "World.png", Vec2f(8, 8), CMap::tile_mithrilingot);
	AddIconToken("$copperingot_block$", "World.png", Vec2f(8, 8), CMap::tile_copperingot);
	AddIconToken("$steelingot_block$", "World.png", Vec2f(8, 8), CMap::tile_steelingot);
	AddIconToken("$ironingot_block$", "World.png", Vec2f(8, 8), CMap::tile_ironingot);
	AddIconToken("$bricks_block$", "World.png", Vec2f(8, 8), CMap::tile_bricks);
	AddIconToken("$castle_moss_block$", "World.png", Vec2f(8, 8), CMap::tile_castle_moss);
	AddIconToken("$castle_back_moss_block$", "World.png", Vec2f(8, 8), CMap::tile_castle_back_moss);
	AddIconToken("$icon_buildershop$", "BuilderShop.png", Vec2f(40, 24), 0, teamnum);
	AddIconToken("$icon_quarters$", "Quarters.png", Vec2f(40, 24), 2, teamnum);
	AddIconToken("$icon_tinkertable$", "TinkerTable.png", Vec2f(40, 24), 0, teamnum);
	AddIconToken("$icon_armory$", "Armory.png", Vec2f(40, 24), 0, teamnum);
	AddIconToken("$icon_gunsmith$", "Gunsmith.png", Vec2f(40, 24), 0, teamnum);
	AddIconToken("$icon_advancedweaponshop$", "AdvancedWS.png", Vec2f(40,24), 0, teamnum);
	AddIconToken("$icon_upfweaponshop$", "UPFWeaponShop.png", Vec2f(40,24), 0, teamnum);
	AddIconToken("$icon_bombshop$", "BombShop.png", Vec2f(40, 24), 0, teamnum);
	AddIconToken("$icon_gunsell$", "GunSell.png", Vec2f(40, 24), 0, teamnum);
	AddIconToken("$icon_classchange$", "ClassChange.png", Vec2f(40, 24), 0, teamnum);
	AddIconToken("$icon_storage$", "Storage.png", Vec2f(40, 24), 3, teamnum);
	AddIconToken("$icon_forge$", "Forge.png", Vec2f(24, 24), 0, teamnum);
	AddIconToken("$constructionyard$", "ConstructionYardIcon.png", Vec2f(16, 16), 0, teamnum);
	AddIconToken("$icon_camp$", "CampIcon.png", Vec2f(64, 24), 0, teamnum);
	AddIconToken("$icon_patreonshop$", "Present.png", Vec2f(24, 24), 0, teamnum);
	AddIconToken("$icon_nursery$","Nursery.png",Vec2f(40, 32), 5, teamnum);
	AddIconToken("$icon_library$", "Library.png", Vec2f(40, 24), 0, teamnum);
	AddIconToken("$icon_workshop$", "Building.png", Vec2f(40, 24), 0);
	AddIconToken("$icon_mostwantedshop$", "MostWantedShop.png", Vec2f(40, 24), 0, teamnum);
	AddIconToken("$icon_bountiesterminal$", "BountiesTerminal.png", Vec2f(40, 24), 0, teamnum);
	AddIconToken("$icon_hatshop$", "HatShop.png", Vec2f(40, 24), 0, teamnum);
	AddIconToken("$icon_discshop$", "DiscShop.png", Vec2f(40, 24), 0, teamnum);
	AddIconToken("$icon_conveyor$", "Conveyor.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$icon_separator$", "Seperator.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$icon_filter$", "Filter.png", Vec2f(24, 8), 0, teamnum);
	AddIconToken("$icon_invcleaner$", "InvCleaner.png", Vec2f(24, 24), 0, teamnum);
	AddIconToken("$icon_launcher$", "Launcher.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$icon_jumper$", "Jumper.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$icon_autoforge$", "AutoForge.png", Vec2f(24, 32), 0, teamnum);
	AddIconToken("$icon_inductionfurnace$", "InductionFurnace.png", Vec2f(40, 32), 0, teamnum);
	AddIconToken("$icon_electricfurnace$", "ElectricFurnace.png", Vec2f(40, 32), 0, teamnum);
	AddIconToken("$icon_assembler$", "Assembler.png", Vec2f(40, 24), 0, teamnum);
	AddIconToken("$icon_hopper$", "Hopper.png", Vec2f(24, 24), 0, teamnum);
	AddIconToken("$icon_fetcher$", "Fetcher.png", Vec2f(24, 24), 0, teamnum);
	AddIconToken("$icon_extractor$", "Extractor.png", Vec2f(16, 24), 0);
	AddIconToken("$icon_filterextractor$", "FilterExtractor.png", Vec2f(24, 24), 0, teamnum);
	AddIconToken("$icon_grinder$", "Grinder.png", Vec2f(40, 24), 0, teamnum);
	AddIconToken("$icon_stonepile$", "StonePile.png", Vec2f(24, 40), 3, teamnum);
	AddIconToken("$icon_packer$", "Packer.png", Vec2f(24, 16), 0, teamnum);
	AddIconToken("$icon_compactor$", "Compactor.png", Vec2f(24, 32), 0, teamnum);
	AddIconToken("$icon_crusher$", "Crusher.png", Vec2f(24, 32), 0, teamnum);
	AddIconToken("$icon_inserter$", "Inserter.png", Vec2f(16, 16), 0);
	AddIconToken("$icon_stackseparator$", "StackSeparator.png", Vec2f(24, 24), 0);
	AddIconToken("$icon_treecapitator$", "Treecapitator.png", Vec2f(24, 8), 0);
	AddIconToken("$icon_chickenassembler$", "ChickenAssembler.png", Vec2f(56, 24), 0, teamnum);
	AddIconToken("$icon_oiltank$","OilTank.png",Vec2f(32, 16), 0, teamnum);
	AddIconToken("$icon_gastank$","GasTank.png",Vec2f(16, 24), 0, teamnum);
	AddIconToken("$icon_chemlab$","ChemLab.png",Vec2f(56, 24), 0, teamnum);
	AddIconToken("$icon_itemtrasher$","ItemTrasher.png",Vec2f(24, 24), 0, teamnum);
	AddIconToken("$plasteelconveyor$", "PlasteelConveyor.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$plasteelfilter$", "PlasteelFilter.png", Vec2f(24, 8), 0, teamnum);
	AddIconToken("$plasteeljumper$", "PlasteelJumper.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$plasteellauncher$", "PlasteelLauncher.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$plasteelseparator$", "PlasteelSeperator.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$icon_plasteelfurnace$", "PlasteelFurnace.png", Vec2f(40, 32), 0, teamnum);
	AddIconToken("$icon_rconveyor$", "ConveyorR.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$icon_rfilter$", "FilterR.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$icon_rclimber$", "ClimberR.png", Vec2f(8, 8), 5, teamnum);
	AddIconToken("$icon_rseparator$", "SeparatorR.png", Vec2f(8, 8), 5, teamnum);
	AddIconToken("$icon_rjumper$", "JumperR.png", Vec2f(8, 16), 0, teamnum);
	AddIconToken("$icon_rextractor$", "AutomationIcons.png", Vec2f(24, 48), 0, teamnum);
	AddIconToken("$icon_invcleaner$", "AutomationIcons.png", Vec2f(24, 48), 1, teamnum);
	AddIconToken("$icon_rhoppacker$", "HoppackerR.png", Vec2f(24, 24), 4, teamnum);
	AddIconToken("$icon_rcompactor$", "CompactorR.png", Vec2f(24, 32), 0, teamnum);
	AddIconToken("$icon_lamppost$", "LampPost.png", Vec2f(8, 24), 0, teamnum);
	AddIconToken("$icon_ironlocker$", "IronLocker.png", Vec2f(16, 24), 0, teamnum);
	AddIconToken("$icon_woodchest$", "WoodChest.png", Vec2f(16, 16), 0, teamnum);
	AddIconToken("$barbedwire$", "BarbedWire.png", Vec2f(16, 16), 0);
	AddIconToken("$icon_teamlamp$", "TeamLamp.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$icon_industriallamp$", "IndustrialLamp.png", Vec2f(8, 8), 0, teamnum);
	AddIconToken("$icon_safe$", "Safe.png", Vec2f(32, 32), 0, teamnum);
	AddIconToken("$icon_drillrig$", "DrillRig.png", Vec2f(24, 24), 0, teamnum);
	AddIconToken("$icon_siren$", "Siren.png", Vec2f(24, 32), 0, teamnum);
	AddIconToken("$icon_textsign$", "TextSign_Large.png", Vec2f(64, 16), 0, teamnum);
	AddIconToken("$icon_smallsign$","sign.png",Vec2f(16, 16), 0);
	AddIconToken("$icon_securitystation$", "SecurityStation.png", Vec2f(24, 24), 0, teamnum);
	AddIconToken("$icon_ceilinglamp$", "CeilingLamp.png", Vec2f(16, 8), 0);
	AddIconToken("$icon_1x5blastdoor$", "1x5BlastDoor.png", Vec2f(8, 40), 0, teamnum);
	AddIconToken("$icon_gate$", "Gate.png", Vec2f(8, 40), 1, teamnum);
	AddIconToken("$icon_beamtower$", "BeamTower.png", Vec2f(32, 48), 0, teamnum);
	AddIconToken("$icon_beamtowermirror$", "BeamTowerMirror.png", Vec2f(16, 24), 0);
	AddIconToken("$icon_metaldetector$", "MetalDetector.png", Vec2f(24, 24), 0, teamnum);
	AddIconToken("$icon_mithrilreactor$", "MithrilReactor.png", Vec2f(24, 24), 0);
	AddIconToken("$icon_banner$","ClanBanner.png",Vec2f(16, 32), 0, teamnum);
	AddIconToken("$icon_druglab$","DrugLab.png",Vec2f(32, 40), 0);
	AddIconToken("$icon_liquificator$","DrugLiquificator.png",Vec2f(24, 32), 0);
	AddIconToken("$icon_altar$", "Altar.png", Vec2f(24, 32), 0, teamnum);
	AddIconToken("$icon_tavern_for_not_peasants$", "Vodka.png", Vec2f(8, 16), 0, teamnum);
    AddIconToken("$bannerchicken$", "BannerChicken.png", Vec2f(16, 32), 0, teamnum);
    AddIconToken("$adminbuilder$", "EngineerIcon.png", Vec2f(24, 24), 0, teamnum);
	AddIconToken("$icon_launchpad$", "LaunchpadIcon.png", Vec2f(45, 29), 0, teamnum);
	AddIconToken("$icon_launchpadmini$", "LaunchpadMiniIcon.png", Vec2f(45, 29), 0, teamnum);
	AddIconToken("$icon_generator$", "Generator.png", Vec2f(32, 24), 0);

	BuildBlock[] page_0;
	blocks.push_back(page_0);
	{
		BuildBlock b(CMap::tile_castle, "stone_block", "$stone_block$", "Stone Block:\n\nBasic building block");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 5);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_castle_back, "back_stone_block", "$back_stone_block$", "Back Stone Wall:\n\nExtra support");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_wood, "wood_block", "$wood_block$", "Wood Block:\n\nCheap block\nwatch out for fire!");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 5);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_wood_back, "back_wood_block", "$back_wood_block$", "Back Wood Wall:\n\nCheap extra support");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_glass, "glass_block", "$glass_block$", "Glass:\n\nFancy and fragile.");
		AddRequirement(b.reqs, "coin", "", "Coins", 10);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_bglass, "bglass_block", "$bglass_block$", "Background Glass:\n\nFancy and fragile.");
		AddRequirement(b.reqs, "coin", "", "Coins", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_concrete, "concrete_block", "$concrete_block$", "Concrete Block:\n\nSlightly more durable than stone.");
		AddRequirement(b.reqs, "blob", "mat_concrete", "Concrete", 4);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_bconcrete, "bconcrete_block", "$bconcrete_block$", "Background Concrete Block:\n\nSlightly more durable than stone.");
		AddRequirement(b.reqs, "blob", "mat_concrete", "Concrete", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_iron, "iron_block", "$iron_block$", "Iron Plating:\n\nA durable metal block. Unbreakable by peasants.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingots", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_biron, "biron_block", "$biron_block$", "Background Iron Plating:\n\nA durable background support. Unbreakable by peasants.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingots", 1);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_reinforcedconcrete, "reinforcedconcrete_block", "$reinforcedconcrete_block$", "Reinforced Concrete Block:\n\nMore durable than concrete.");
		AddRequirement(b.reqs, "blob", "mat_concrete", "Concrete", 10);
		AddRequirement(b.reqs, "blob", "mat_steelingot", "Steel Ingot", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_titanium, "titanium_block", "$titanium_block$", "Titanium:\n\nStronger but lighter than iron and more resistant to acid.\nDrills will mine this block slower.");
		AddRequirement(b.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_plasteel, "plasteel_block", "$plasteel_block$", "Plasteel Panel:\n\nAn advanced composite material. Nearly indestructible.");
		AddRequirement(b.reqs, "blob", "mat_plasteel", "Plasteel Sheet", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_bplasteel, "bplasteel_block", "$bplasteel_block$", "Background Plasteel Panel:\n\nAn advanced composite material. Nearly indestructible.");
		AddRequirement(b.reqs, "blob", "mat_plasteel", "Plasteel Sheet", 1);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "stone_door", "$icon_stone_door$", "Stone Door:\n\nPlace next to walls");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 50);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "wooden_door", "$icon_wooden_door$", "Wooden Door:\n\nPlace next to walls");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 30);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "ladder", "$ladder$", "Ladder:\n\nAnyone can climb it");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 10);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "ironladder", "$icon_ironladder$", "Iron Ladder:\n\nAnyone can climb it like the regular ladder, but it's more durable.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 3);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "wooden_platform", "$wooden_platform$", "Wooden Platform:\n\nOne way platform");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 15);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "spikes", "$spikes$", "Spikes:\n\nPlace on Stone Block\nfor Retracting Trap");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 30);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "trap_block", "$icon_trapblock$", "Trap Block:\n\nOnly enemies can pass it.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 25);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "iron_trap_block", "$icon_irontrapblock$", "Trap Block:\n\nOnly enemies can pass it like the regular trap block, but it's more durable.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron ingot", 12);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "iron_door", "$icon_iron_door$", "Iron Door:\n\nDoesn't have to be placed next to walls!");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingots", 8);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "plasteel_door", "$icon_plasteel_door$", "Plasteel Door:\n\nAn extremely durable plasteel door.\nDoesn't have to be placed next to walls!");
		AddRequirement(b.reqs, "blob", "mat_plasteel", "Plasteel Sheet", 8);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "wood_triangle", "$wood_triangle$", "Wooden Triangle");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "stone_triangle", "$stone_triangle$", "Stone Triangle");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "concrete_triangle", "$concrete_triangle$", "Concrete Triangle");
		AddRequirement(b.reqs, "blob", "mat_concrete", "Concrete", 4);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "iron_triangle", "$iron_triangle$", "Iron Triangle");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingots", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "stone_halfblock", "$stone_halfblock$", "Stone Half Block:\n\nLets bullets pass through!");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(0, "iron_platform", "$icon_ironplatform$", "Iron Platform:\n\nReinforced one-way platform. Unbreakable by peasants.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingots", 3);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_kudzu, "kudzu", "$kudzu_block$", "Decorative kudzu leaves.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 20);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_kudzu_back, "kudzu_back", "$kudzu_back_block$", "Decorative background kudzu leaves.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 5);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_goldingot, "goldingot", "$goldingot_block$", "Mostly decorative block made from gold ingots \n ");
		AddRequirement(b.reqs, "blob", "mat_goldingot", "Gold Ingots", 3);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_mithrilingot, "mithrilingot", "$mithrilingot_block$", "Mostly decorative block made from mithril ingots \n ");
		AddRequirement(b.reqs, "blob", "mat_mithrilingot", "Mithril Ingots", 3);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_copperingot, "copperingot", "$copperingot_block$", "Mostly decorative block made from copper ingots \n ");
		AddRequirement(b.reqs, "blob", "mat_copperingot", "Copper Ingots", 3);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_steelingot, "steelingot", "$steelingot_block$", "Mostly decorative block made from steel ingots \n ");
		AddRequirement(b.reqs, "blob", "mat_steelingot", "Steel Ingots", 3);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_ironingot, "ironingot", "$ironingot_block$", "Mostly decorative block made from iron ingots \n ");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingots", 3);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_bricks, "bricks", "$bricks_block$", "Fancy and cheap bricks \n ");
		AddRequirement(b.reqs, "blob", "mat_dirt", "Dirt", 5);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_bricks_back, "bricks_back", "$bricks_back_block$", "Fancy and cheap bricks wall.\n");
		AddRequirement(b.reqs, "blob", "mat_dirt", "Dirt", 2);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_castle_moss, "castle_moss", "$castle_moss_block$", "Mosus stone block \n ");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 10);
		blocks[0].push_back(b);
	}
	{
	    BuildBlock b(CMap::tile_castle_back_moss, "castle_back_moss", "$castle_back_moss_block$", "Mosus stone block \n ");
	    AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 5);
		blocks[0].push_back(b);
	}
	{
		BuildBlock b(CMap::tile_ground, "ground_block", "$ground_block$", "Dirt:\n\nFairly resistant to explosions.\nMay be only placed on dirt backgrounds or damaged dirt.");
		AddRequirement(b.reqs, "blob", "mat_dirt", "Dirt", 30);
		blocks[0].push_back(b);
	}
	
	BuildBlock[] page_1;
	blocks.push_back(page_1);
	{
		BuildBlock b(0, "quarters", "$icon_quarters$", "Quarters:\n\n" + descriptions[59]);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 50);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "buildershop", "$icon_buildershop$", "Builder Workshop:\n\nConstruct several building utilities.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 100);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "tinkertable", "$icon_tinkertable$", "Mechanist's Workshop:\n\nA place where you can construct various trinkets and advanced machinery.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 70);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 150);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "armory", "$icon_armory$", "Armory:\n\nA workshop where you can craft cheap equipment.\n$GREEN$Automatically stores nearby dropped weapons and armor.$GREEN$");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 100);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 200);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "gunsmith", "$icon_gunsmith$", "Gunsmith's Workshop:\n\nA workshop for those who enjoy making holes.\n$GREEN$Slowly produces ammunition.$GREEN$");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 150);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 250);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	{
	    BuildBlock b(0, "advancedweaponshop", "$icon_advancedweaponshop$", "Advanced Weapon Shop:\n\nA workshop for advanced weapons.\nContains bullets crafting.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 350);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 200);
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 16);
		AddRequirement(b.reqs, "blob", "mat_copperingot", "Copper Ingot", 6);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}	
	{
	    BuildBlock b(0, "upfweaponshop", "$icon_upfweaponshop$", "UPF Weapon Shop:\n\nA workshop for UPF chicken weapons.\nContains cheaper bullets.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 200);
		AddRequirement(b.reqs, "blob", "bp_weapons", "Blueprint (Weapons)", 1);
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 30);
		AddRequirement(b.reqs, "blob", "mat_steelingot", "Steel Ingot", 16);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "bombshop", "$icon_bombshop$", "Demolitionist's Workshop:\n\nFor those with an explosive personality.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 100);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 250);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "forge", "$icon_forge$", "Forge:\n\nEnables you to process raw metals into pure ingots and alloys.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 150);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 70);
		b.buildOnGround = true;
		b.size.Set(24, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "construction_yard", "$constructionyard$", "Construction Yard:\n\nUsed to construct various vehicles.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 75);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 200);
		b.buildOnGround = true;
		b.size.Set(64, 56);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "storage", "$icon_storage$", "Storage:\n\nA storage for keeping materials and items.\nCan be only accessed by the owner team.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 250);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 100);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "library", "$icon_library$", "Library:\n\nBuy and sell various blueprints.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 125);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 250);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "classchange", "$icon_classchange$", "Wardrobe:\n\nWant a smoking? Here's hazmat!");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 250);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 200);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "smartstorage", "$smartstorage$", "Smart storage:\n\nAn advanced storage for storing multiple amount of different items.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 16);
		AddRequirement(b.reqs, "blob", "mat_steelingot", "Steel Ingot", 16);
		AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper Wire", 50);

		// AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);
		b.buildOnGround = true;
		b.size.Set(24, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "camp", "$icon_camp$", "Camp:\n\nA basic faction base. Can be upgraded to gain\nspecial functions and more durability.\n\n$GREEN$Increases Upkeep cap by 1.$GREEN$");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 325);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 175);
		AddRequirement(b.reqs, "coin", "", "Coins", 100);
		b.buildOnGround = true;
		b.size.Set(80, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "nursery", "$icon_nursery$", "Nursery:\n\nRaise plants and crops for various purposes.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 75);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 200);
		AddRequirement(b.reqs, "blob", "mat_dirt", "Dirt", 50);
		b.buildOnGround = true;
		b.size.Set(40, 32);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "hatshop", "$icon_hatshop$", "Hat Shop:\n\nBuy different types of hat.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 150);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 150);
		AddRequirement(b.reqs, "coin", "", "Coins", 100);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "discshop", "$icon_discshop$", "Disc Shop:\n\nBuy your favorite records here!\nRequires electricity.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 200);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 100);
		AddRequirement(b.reqs, "coin", "", "Coins", 100);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "gunsell", "$icon_gunsell$", "Gun sell market:\n\nA workshop with a hecking gull inside!! Where does it come from?");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 250);
		AddRequirement(b.reqs, "coin", "", "Coins", 500);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "bountiesterminal", "$icon_bountiesterminal$", "Bounties Terminal:\n\nHave illegal access to Bounty system, hacker fee included in the price.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 150);
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 2);
		AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper Wire", 1);
		AddRequirement(b.reqs, "coin", "", "Coins", 200);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	{
		BuildBlock b(0, "mostwantedshop", "$icon_mostwantedshop$", "Most Wanted Shop:\n\nWant to kill a wanted player? Increase his bounty here.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 250);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 50);
		AddRequirement(b.reqs, "coin", "", "Coins", 100);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[1].push_back(b);
	}
	
	 
	BuildBlock[] page_2;
	blocks.push_back(page_2);
	//PRODUCTION
	{
		BuildBlock b(0, "autoforge", "$icon_autoforge$", "Auto-Forge:\n\nProcesses raw materials and alloys just for you. Has a chance for a double yield.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 200);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 100);
		b.buildOnGround = true;
		b.size.Set(24, 32);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "inductionfurnace", "$icon_inductionfurnace$", "Industrial Furnace:\n\nA heavy-duty furnace that produces up to 4x more ingots at cost of lower speed. Requires coal to smelt.\n\nHas a multiplier mode that increases output for cost of smelting speed.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 50);
		AddRequirement(b.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 8);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 1000);
		b.buildOnGround = true;
		b.size.Set(40, 32);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "electricfurnace", "$icon_electricfurnace$", "Electric furnace:\n\nAn advanced analogue for induction furnace. Smelts ore up to 3x ingots and does not require coal for smelting. Also has toggle mode.\n\nHas a multiplier mode that increases output for cost of smelting speed.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 50);
		AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper wire", 40);
		AddRequirement(b.reqs, "blob", "mat_battery", "Voltron Battery Plus", 50);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);
		b.buildOnGround = true;
		b.size.Set(40, 32);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "crusher", "$icon_crusher$", "Crusher\nSmashes rocks into concrete and dirt into sulphur with a lower yield");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 12);
		AddRequirement(b.reqs, "blob", "mat_copperingot", "Copper Ingot", 8);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);
		b.buildOnGround = true;
		b.size.Set(24, 32);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "grinder", "$icon_grinder$", "Grinder:\n\nA dangerous machine capable of destroying almost everything.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 250);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 150);
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingots", 5);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "assembler", "$icon_assembler$", "Assembler:\n\nAn elaborate piece of machinery that manufactures items.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 50);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 200);
		b.buildOnGround = true;
		b.size.Set(40, 24);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "druglab", "$icon_druglab$", "Chemical Laboratory:\n\nA laboratory used for production of chemicals, ranging from methane to various kinds of drugs.");
		AddRequirement(b.reqs, "blob", "mat_steelingot", "Steel Ingot", 10);
		AddRequirement(b.reqs, "blob", "mat_copperingot", "Copper Ingot", 30);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);
		b.buildOnGround = true;
		b.size.Set(32, 40);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "chickenassembler", "$icon_chickenassembler$", "UPF Assembly Line:\n\nA reverse-engineered assembly line used to manufacture some of the UPF products.");
		AddRequirement(b.reqs, "blob", "mat_steelingot", "Steel Ingot", 20);
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 10);
		AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper Wire", 10);
		AddRequirement(b.reqs, "blob", "bp_automation_advanced", "Blueprint (Advanced Automation)", 1);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);
		b.buildOnGround = true;
		b.size.Set(56, 24);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "drillrig", "$icon_drillrig$", "Driller Mole:\n\nAn automatic drilling machine that mines resources underneath.");
		AddRequirement(b.reqs, "blob", "drill", "Drill", 1);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 250);
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 16);
		b.buildOnGround = true;
		b.size.Set(24, 24);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "chemlab", "$icon_chemlab$", "Chemical Production Machine:\n\nA machine capable of manufacturing basic drugs and chemicals.");
		AddRequirement(b.reqs, "blob", "mat_steelingot", "Steel Ingot", 20);
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 10);
		AddRequirement(b.reqs, "blob", "mat_copperingot", "Copper Ingot", 40);
		AddRequirement(b.reqs, "blob", "bp_chemistry", "Blueprint (Chemistry)", 1);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);
		b.buildOnGround = true;
		b.size.Set(48, 24);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "lgenerator", "$lgenerator$", "Liquid fuel generator.\nConverts methane into oil.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 24);
		AddRequirement(b.reqs, "blob", "mat_copperingot", "Copper Ingot", 12);
		AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper wire", 20);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);
		b.buildOnGround = true;
		b.size.Set(28, 16);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "mithrilreactor", "$icon_mithrilreactor$", "Mithril Irradiator:\n\nA small reactor used for mithril enrichment and synthesis using gold.\nBecomes more stable when submerged in deep water.\n$mat_gold$$DEFEND_RIGHT$$mat_mithril_10x$$DEFEND_RIGHT$$mat_mithrilenriched_10x$\n\n\n$RED$Careless usage may result in\nan irradiated crater.$RED$\n");
		AddRequirement(b.reqs, "blob", "mat_steelingot", "Steel Ingot", 20);
		AddRequirement(b.reqs, "blob", "mat_mithril", "Mithril", 100);
		AddRequirement(b.reqs, "blob", "mat_mithrilingot", "Mithril Ingot", 5);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);
		b.buildOnGround = true;
		b.size.Set(24, 24);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "nuclearreactor", "$nuclearreactor$", "Nuclear Reactor:\n\nConverts enriched mithril into default with bigger yield.\nProduces wilmet material on higher temperatures.\n\nHas a control panel with password check. Can be sabotaged.\n\nRequires enriched mithril as fuel, mithril also increases heat.\n\nYou can set up a catalyzer or refrigerant into the utility slot (also remove them with a wrench) to get certain modifications.\n\nExplodes with an insane power when heated up too much.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 100);
		AddRequirement(b.reqs, "blob", "mat_steelingot", "Steel Ingot", 40);
		AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper Wire", 150);
		AddRequirement(b.reqs, "blob", "mat_concrete", "Concrete", 1000);
		AddRequirement(b.reqs, "blob", "mat_mithrilingot", "Mithril Ingot", 20);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);

		b.buildOnGround = true;
		b.size.Set(64, 48);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "safe", "$icon_safe$", "Steel safe:\n\nHas personal access with share option (insert paper with username). Also being provided as remote storage for neutrals.");
		AddRequirement(b.reqs, "blob", "mat_steelingot", "Steel Ingot", 20);
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 16);
		b.buildOnGround = true;
		b.size.Set(32, 32);
		blocks[2].push_back(b);
	}
	{
		BuildBlock b(0, "liquificator", "$icon_liquificator$", "Drug Liquificator:\n\nConverts various solid drugs into liquified to syringes, and liquified drugs to gases.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 12);
		AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper Wire", 20);
		AddRequirement(b.reqs, "blob", "mat_mithrilingot", "Mithril Ingot", 8);
		b.buildOnGround = true;
		b.size.Set(24, 32);
		blocks[2].push_back(b);
	}
	

	//{
	//	BuildBlock b(0, "collector", "$collector$", "Collector:\n\nGathers energy from closest generators and transfers to electric poles. Only one collector can take energy from single generators. Must be put away from other generators to be active.\n\nDistance: 8 blocks\nCan be toggled off");
	//	AddRequirement(b.reqs, "blob", "mat_steelingot", "Steel Ingot", 2);
	//	AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper wire", 10);
	//	b.size.Set(8,8);
	//	blocks[2].push_back(b);
	//}
	//{
	//	BuildBlock b(0, "generator", "$icon_generator$", "Solid fuel generator (produces: 75-150; max: 1500):\n\nGenerates energy in exchange for wood or coal.");
	//	AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 16);
	//	AddRequirement(b.reqs, "blob", "mat_copperingot", "Copper Ingot", 4);
	//	AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper wire", 10);
	//	b.buildOnGround = true;
	//	b.size.Set(32, 24);
	//	blocks[2].push_back(b);
	//}
	//{
	//	BuildBlock b(0, "lgenerator", "$lgenerator$", "Liquid fuel generator (produces: 350-700; max: 4500):\n\nGenerates more energy in exchange for oil, methane or fuel.");
	//	AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 32);
	//	AddRequirement(b.reqs, "blob", "mat_copperingot", "Copper Ingot", 12);
	//	AddRequirement(b.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 4);
	//	AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper wire", 20);
	//	b.buildOnGround = true;
	//	b.size.Set(28, 16);
	//	blocks[2].push_back(b);
	//}
	//{
	//	BuildBlock b(0, "beamtowermirror", "$icon_beamtowermirror$", "Solar panel (produces: 10-17; max: 500):\n\nGenerates a small amount of energy during the day.");
	//	AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 16);
	//	AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper wire", 30);
	//	b.buildOnGround = true;
	//	b.size.Set(16, 24);
	//	blocks[2].push_back(b);
	//}
	//{
	//	BuildBlock b(0, "pole", "$pole$", "Electric pole:\n\nTransfers energy and supplies closest energy consumptions.\n\nOnly one pole can supply energy to single consumptions.\n\nDistance: 8 blocks");
	//	AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 2);
	//	AddRequirement(b.reqs, "blob", "mat_copperingot", "Copper Ingot", 2);
	//	AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper wire", 5);
	//	b.size.Set(8, 8);
	//	blocks[2].push_back(b);
	//}
	//{
	//	BuildBlock b(0, "vbarbedwire", "$vbarbedwire$", "High-voltaged barbed wire:\n\nBurns away flesh on touch, but only if it has electricity!\n\nElectricity amount is hidden to disguise its behavior.");
	//	AddRequirement(b.reqs, "blob", "mat_copperingot", "Copper Ingot", 8);
	//	AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper wire", 10);
	//	b.size.Set(8, 8);
	//	blocks[2].push_back(b);
	//}
	
	BuildBlock[] page_3;
	blocks.push_back(page_3);
	{
		BuildBlock b(0, "woodchest", "$icon_woodchest$", "Wooden Chest:\n\nA regular wooden chest used for storage.\nCan be accessed by anyone.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 100);
		b.buildOnGround = true;
		b.size.Set(16, 16);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "smallsign", "$icon_smallsign$", "Sign:\n\nType '!write -text-' in chat and then use it on the sign. Writing on a piece of paper costs 50 coins.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 60);
		b.buildOnGround = true;
		b.size.Set(16, 16);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "textsign", "$icon_textsign$", "Sign:\n\nType '!write -text-' in chat and then use it on the sign. Writing on a piece of paper costs 50 coins.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 150);
		b.buildOnGround = true;
		b.size.Set(64, 16);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "tavern", "$icon_tavern_for_not_peasants$", "Tavern:\n\nA poorly built cozy tavern.\nNeutrals may set their team here, paying you 20 coins for each spawn.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 350);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 200);
		b.buildOnGround = true;
		b.size.Set(56, 32);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "banner", "$icon_banner$", "Banner:\n\nBanner to show off your team's color.");
		AddRequirement(b.reqs, "coin", "", "Coins", 150);
		b.size.Set(16, 32);
		blocks[3].push_back(b);
	}
	{	
		BuildBlock b(0, "fireplace", "$fireplace$", "Campfire:\n\nCan be used to cook various foods.");
		AddRequirement(b.reqs, "blob", "lantern", "Lantern", 1);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 50);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 200); //This is more expensive than for peasants as the fireplace is an amazing lightsource better than most other lightsources
		b.buildOnGround = true;
		b.size.Set(16, 16);
		blocks[3].push_back(b);
    }
	{
		BuildBlock b(0, "teamlamp", "$icon_teamlamp$", "Team Lamp:\n\nGlows with your team's spirit.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 50);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "industriallamp", "$icon_industriallamp$", "Industrial Lamp:\n\nA sturdy lamp to ligthen up the mood in your factory.\nActs as a support block.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 50);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "ceilinglamp", "$icon_ceilinglamp$", "Ceiling Lamp:\n\nIt's quite bright.\n\nCan be toggled by a Security Station.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 2);
		AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper Wire", 2);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);

		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "lamppost", "$icon_lamppost$", "Lamp Post:\n\nA fancy light.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 40);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 25);
		AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper Wire", 1);
		b.buildOnGround = true;
		b.size.Set(8, 24);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "barbedwire", "$barbedwire$", "Barbed Wire:\n\nHurts anyone who passes through it. Good at preventing people from climbing over walls.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 4);
		// AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);

		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "shifter", "$shifter$", "Shifter:\n\nMoves things in a set direction, has a cooldown.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 50);
		AddRequirement(b.reqs, "blob", "mat_goldingot", "Gold Ingot", 1);
		AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper Wire", 4);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);
		
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "glider", "$glider$", "Glider:\n\nHolds players and bots above itself.");
		AddRequirement(b.reqs, "blob", "mat_copperingot", "Copper Ingot", 2);
		AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper wire", 10);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);

		b.size.Set(8, 8);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "ironlocker", "$icon_ironlocker$", "Personal Locker:\n\nA more secure way to store your items.\nCan be only accessed by the first person to claim it.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingots", 6);
		
		b.buildOnGround = true;
		b.size.Set(16, 24);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "altar", "$icon_altar$", "Altar:\n\nWorship your idols here. Needs to be carved first.");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 2000);
		AddRequirement(b.reqs, "coin", "", "Coins", 250);
		b.buildOnGround = true;
		b.size.Set(24, 32);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "gate", "$icon_gate$", "Wooden Gate:\n\nHeavy door.\n\nCan be only opened from inside.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 2);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 750);
		// AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);
		b.size.Set(8, 40);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "1x5blastdoor", "$icon_1x5blastdoor$", "Blast Door:\n\nA large heavy blast door.\n\nCan be only opened by a Security Station.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 20);
		AddRequirement(b.reqs, "blob", "mat_steelingot", "Steel Ingot", 16);
		AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper Wire", 20);

		b.size.Set(8, 40);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "siren", "$icon_siren$", "Air Raid Siren:\n\nWarns of incoming enemy aerial vehicles within 75 block radius.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 100);
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 25);
		AddRequirement(b.reqs, "blob", "mat_goldingot", "Gold Ingot", 2);
		b.buildOnGround = true;
		b.size.Set(24, 32);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "securitystation", "$icon_securitystation$", "Security Station:\n\nProvides remote control and linking of various security devices, such as blast doors and turrets.\n\nCreates a unique Security Card upon construction, which can be used to limit  control of devices exclusively to this machine.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 20);
		AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper Wire", 10);
		// AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);

		b.buildOnGround = true;
		b.size.Set(24, 24);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "metaldetector", "$icon_metaldetector$", "Danger Detector:\n\nScans people passing through it for dangerous items, such as weapons, explosives or ill-tempered animals.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 8);
		b.buildOnGround = true;
		b.size.Set(24, 24);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "patreonshop", "$icon_patreonshop$", "Gift Shop:\n\nA special souvenir shop!");
		AddRequirement(b.reqs, "blob", "mat_stone", "Stone", 75);
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 200);
		AddRequirement(b.reqs, "blob", "mat_goldingot", "Gold Ingot", 200);
		b.buildOnGround = true;
		b.size.Set(40, 40);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "beamtower", "$icon_beamtower$", "Solar Death Ray Tower:\n\nSolar energy has never been so much fun!\n\nRequires batteries to shoot!");
		AddRequirement(b.reqs, "coin", "", "Coins", 1000);
		AddRequirement(b.reqs, "blob", "mat_steelingot", "Steel Ingot", 20);
		AddRequirement(b.reqs, "blob", "mat_mithril", "Mithril", 100);
		AddRequirement(b.reqs, "blob", "mat_battery", "Battery", 100);
		AddRequirement(b.reqs, "blob", "bp_energetics", "Blueprint (Energetics)", 1);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);

		b.buildOnGround = true;
		b.size.Set(24, 96);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "launchpadmini", "$icon_launchpadmini$", "Launch an asteroid harvester...\nTo an asteroid!\n\nReverts a rich on metals crate after finishing expedition.");
		AddRequirement(b.reqs, "blob", "mat_wood", "Wood", 500);
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 125);
		AddRequirement(b.reqs, "blob", "mat_copperingot", "Copper Ingot", 30);
		AddRequirement(b.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 50);
		AddRequirement(b.reqs, "blob", "wrench", "Wrench", 1);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);
		b.buildOnGround = true;
		b.size.Set(71, 96);
		blocks[3].push_back(b);
	}
	{
		BuildBlock b(0, "launchpad", "$icon_launchpad$", "Launch a rocket to an asteroid, moon or another planet to get alien technologies and weapons.\nYou can increase rocket efficiency with building modules (optionally): leave certain items in the compartment before crafting\nlast 4 sections before nose.\n\nModules:\nDrill station: increases amount of loot - 10 power mithril drills.\nFuel tanker: allows rocket to reach an exoplanet - 500 fuel.\nDetailed scanner: increases amount of enemies and falling debris from crate - 1 phone.\nWeapon pack: decreases amount of enemies from crate - 8 UPF UZI.");
		AddRequirement(b.reqs, "blob", "mat_ironingot", "Iron Ingot", 200);
		AddRequirement(b.reqs, "blob", "mat_steelingot", "Steel Ingot", 150);
		AddRequirement(b.reqs, "blob", "mat_copperingot", "Copper Ingot", 50);
		AddRequirement(b.reqs, "blob", "mat_titaniumingot", "Titanium Ingot", 75);
		AddRequirement(b.reqs, "blob", "mat_copperwire", "Copper wires", 100);
		AddRequirement(b.reqs, "blob", "adminbuilder", "You have to be an Engineer", 1);

		b.buildOnGround = true;
		b.size.Set(96, 192);
		blocks[3].push_back(b);
	}
}