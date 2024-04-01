#include "Requirements.as";
#include "Requirements_Tech.as";
#include "ShopCommon.as";
#include "DeityCommon.as";
#include "MakeSeed.as";

string lt_nam = "Genocide fruit";
	
void onInit(CBlob@ this)
{
	this.set_u8("deity_id", Deity::leutnant);
	this.set_Vec2f("shop menu size", Vec2f(4, 2));
	this.set_f32("deity_power", 0);

	this.addCommandID("turn_sounds");
	this.addCommandID("update my fanatics");
	this.addCommandID("sync_deity");
	
	this.SetLight(true);
	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 255, 0, 0));
	
	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("WdS_Whistle-Version.ogg");
	sprite.SetEmitSoundVolume(1.000f);
	sprite.SetEmitSoundSpeed(1.000f);
	sprite.SetEmitSoundPaused(false);
	
	addTokens(this);
	shopMenu(this);
	
	if (!isServer()) return;
	
	string[] fanatics;
	this.set("fanatics", fanatics);
}

void shopMenu(CBlob@ this)
{	
	AddIconToken("$icon_onepoint$", "AltarLeutnant_Icons.png", Vec2f(24, 24), 0);
	{
		ShopItem@ s = addShopItem(this, lt_nam, "$icon_onepoint$", "onepoint", "Gain 1 GENOCIDAL POINT by offering massacred Untermensch.");
		AddRequirement(s.requirements, "blob", "peasant", "Peasant's Corpse", 1);
		s.customButton = true;
		s.buttonwidth = 1;	
		s.buttonheight = 1;
		
		s.spawnNothing = true;
	}
	
	AddIconToken("$icon_threepoints$", "AltarLeutnant_Icons.png", Vec2f(24, 24), 2);
	{
		ShopItem@ s = addShopItem(this, lt_nam, "$icon_threepoints$", "threepoints", "Gain 3 GENOCIDAL POINTS by offering massacred Untermensch.");
		AddRequirement(s.requirements, "blob", "bandit", "Bandit's Corpse", 1);
		s.customButton = true;
		s.buttonwidth = 1;	
		s.buttonheight = 1;
		
		s.spawnNothing = true;
	}
	
	AddIconToken("$icon_stahlhelm$", "stahlhelm_icon.png", Vec2f(24, 24), 0);
	{
		ShopItem@ s = addShopItem(this, "Stahlhelm M42", "$icon_stahlhelm$", "stahlhelm", "Best combat helmet in the world!\n\nDoesn't require any repair!!!");
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 20);
		//AddRequirement(s.requirements, "coin", "", "Coins", 500);
		s.customButton = true;
		s.buttonwidth = 1;	
		s.buttonheight = 1;
		
		s.spawnNothing = true;
	}
	
	{
		ShopItem@ s = addShopItem(this, "Very stylish cool-looking offiziers Cap!", "$villaincap$", "villaincap", "Peaked Cap for good commanders.\n\nMakes chicken soldiers friendly");
		AddRequirement(s.requirements, "coin", "", "Coins", 3000);
		s.customButton = true;
		s.buttonwidth = 1;	
		s.buttonheight = 1;
		
		s.spawnNothing = true;
	}
	
	{
		ShopItem@ s = addShopItem(this, "Mustard Gas (100)", "$icon_mustard$", "mat_mustard", "A bottle of a highly poisonous gas. Causes blisters, blindness and lung damage.");
		AddRequirement(s.requirements, "coin", "", "Coins", 700);;
		
		s.spawnNothing = true;
	}
	
	{
		ShopItem@ s = addShopItem(this, "Ultimate tool of genocide", "$icon_gasweapon$", "gasthrower", "Gas your enemies and national minorities today.\n\nWith love~");
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 18);
		AddRequirement(s.requirements, "blob", "mat_rippio", "Rippio Gas", 50);
		AddRequirement(s.requirements, "blob", "love", "Love", 1);
		//AddRequirement(s.requirements, "coin", "", "Coins", 1000);
		s.customButton = true;
		s.buttonwidth = 3;	
		s.buttonheight = 1;
		
		s.spawnNothing = true;
	}
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;
	
	const f32 power = blob.get_f32("deity_power");
	f32 soundspeed = Maths::Max(1 - (power / 10000), 0.10f);
	f32 soundvolume = Maths::Min(0.5f + (power / 10000), 6.00f);
	
	this.SetEmitSoundSpeed(soundspeed);
	this.SetEmitSoundVolume(soundvolume);
}

void addTokens(CBlob@ this)
{
	int teamnum = this.getTeamNum();
	if (teamnum > 6)teamnum = 7;
	
	AddIconToken("$peasant$", "AltarLeutnant_Icons.png", Vec2f(24, 24), 0, teamnum);
	AddIconToken("$engineer$", "AltarLeutnant_Icons.png", Vec2f(24, 24), 1, teamnum);
	AddIconToken("$bandit$", "AltarLeutnant_Icons.png", Vec2f(24, 24), 2, teamnum);
	AddIconToken("$icon_soldat$", "Soldat_Icons.png", Vec2f(24, 24), 1, teamnum);
	AddIconToken("$icon_gasweapon$", "GasThrower.png", Vec2f(24, 13), 0, teamnum);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (caller is null) return;
 	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton(27, Vec2f(0, -10), this, this.getCommandID("turn_sounds"), "Turn sounds off/on", params);
	
	int teamnum = this.getTeamNum();
	if (teamnum > 6)
	{
		this.set_bool("shop available", true);
	}
	else
	{
		this.set_bool("shop available", teamnum == caller.getTeamNum());
	}
}

void onTick(CBlob@ this)
{
	const bool server = isServer();
	const bool client = isClient();
	const f32 power = this.get_f32("deity_power");
	int fakemax = 100;
	if ((power/100) >= 80)this.getSprite().SetAnimation("bloody");
	
	f32 soundspeed = Maths::Max(1 - (power / 10000), 0.10f);
	
	if (server)
	{	
		string[] new_fanatics;
		if (!this.get("fanatics", new_fanatics)) return;
		//print("got there");

		for (int idx = 0; idx < new_fanatics.size(); idx++)
		{
			CPlayer@ player = getPlayerByUsername(new_fanatics[idx]);
			if (player is null) continue;
			
			//print("syncing this guy "+player.getUsername());
			
			CBlob@ player_blob = player.getBlob();
			
			if (player_blob is null) continue;
			
			//player_blob.set_u8("deity_id", Deity::leutnant);
			//player_blob.set_f32("deity_power", this.get_f32("deity_power"));
			
			CBitStream params;
			params.write_f32(power);
			params.write_u8(Deity::leutnant);
			params.write_u16(player_blob.getNetworkID());
			this.SendCommand(this.getCommandID("update my fanatics"), params);
		}
	}
	u32 genocidal_points = Maths::Min(power / 100, fakemax);
	f32 additional_defense_percent = genocidal_points*0.001*5;
	
	this.setInventoryName("Altar of Skemonde" +
		"\n\nGENOCIDAL POINTS: " + (Maths::Min(power / 100, fakemax)) + "/" + fakemax +
		"\nStahlhelm gunfire defense: "+((0.5f+additional_defense_percent)*100) + "%" +
		"\nPassive Effect: Mustard Immunity" + 
		"\nMusic speed: " + (soundspeed * 100) + "%");
}

void onDie( CBlob@ this )
{
	if (!isServer()) return;	
	string[] new_fanatics;
	if (!this.get("fanatics", new_fanatics)) return;

	for (int idx = 0; idx < new_fanatics.size(); idx++)
	{
		CPlayer@ player = getPlayerByUsername(new_fanatics[idx]);
		if (player is null) continue;
		
		CBlob@ player_blob = player.getBlob();
		
		if (player_blob is null) continue;
		
		CBitStream params;
		params.write_f32(0);
		params.write_u8(0);
		params.write_u16(player_blob.getNetworkID());
		this.SendCommand(this.getCommandID("update my fanatics"), params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	addTokens(this);
	if (cmd == this.getCommandID("update my fanatics"))
	{
		f32 power; if (!params.saferead_f32(power)) return;
		u8 deity_id; if (!params.saferead_u8(deity_id)) return;
		u16 netid; if (!params.saferead_u16(netid)) return;
		
		CBlob@ player_blob = getBlobByNetworkID(netid);
		if (player_blob is null) return;
		
		player_blob.set_u8("deity_id", deity_id);
		player_blob.set_f32("deity_power", power);
	}
	if (cmd == this.getCommandID("turn_sounds"))
	{
		u16 caller;
		if (params.saferead_netid(caller))
		{
			CBlob@ b = getBlobByNetworkID(caller);
			if (isClient() && b.isMyPlayer() && this.getSprite() !is null)
			{
				this.getSprite().SetEmitSoundPaused(!this.getSprite().getEmitSoundPaused());
			}
		}
	}
	else if (cmd == this.getCommandID("sync_deity"))
	{
		if (isClient())
		{
			u8 deity;
			u16 blobid;

			if (!params.saferead_u8(deity)) return;
			if (!params.saferead_u16(blobid)) return;
			
			CBlob@ b = getBlobByNetworkID(blobid);
			if (b is null) return;
			b.set_u8("deity_id", deity);
			if (b.getPlayer() is null) return;
			b.getPlayer().set_u8("deity_id", deity);
		}
	}
	else if (cmd == this.getCommandID("shop made item"))
	{
		u16 caller, item;
		if (params.saferead_netid(caller) && params.saferead_netid(item))
		{
			string data = params.read_string();
			CBlob@ callerBlob = getBlobByNetworkID(caller);
			if (callerBlob !is null)
			{
				CPlayer@ callerPlayer = callerBlob.getPlayer();
				if (callerPlayer !is null)
				{
					if (isServer()) {
						string[] new_fanatics;
						if (!this.get("fanatics", new_fanatics)) return;
						//print("got there");
						if (new_fanatics.find(callerPlayer.getUsername())<0) {
							
							new_fanatics.push_back(callerPlayer.getUsername());
							//print("got there 2");
							//print("sdf "+new_fanatics.size());
						}
						this.set("fanatics", new_fanatics);
					}
					
					if (data == "onepoint")
					{
						this.add_f32("deity_power", 100);
						
						if (isClient())
						{
							CBlob@ localBlob = getLocalPlayerBlob();
							if (localBlob !is null)
							{
								if (this.getDistanceTo(localBlob) < 128)
								{
									this.getSprite().PlaySound("levelup", 3.00f, 1.00f);
								}
							}
						}
						
						if (isServer())
						{
							callerPlayer.set_u8("deity_id", Deity::leutnant);
							callerBlob.set_u8("deity_id", Deity::leutnant);

							CBitStream params;
							params.write_u8(Deity::leutnant);
							params.write_u16(callerBlob.getNetworkID());
							this.SendCommand(this.getCommandID("sync_deity"), params);
						}
					}
					else
					{
						if (data == "threepoints")
						{
							this.add_f32("deity_power", 300);
						
							if (isClient())
							{
								CBlob@ localBlob = getLocalPlayerBlob();
								if (localBlob !is null)
								{
									if (this.getDistanceTo(localBlob) < 128)
									{
										this.getSprite().PlaySound("levelup", 3.00f, 1.00f);
									}
								}
							}
						
							if (isServer())
							{
								callerPlayer.set_u8("deity_id", Deity::leutnant);
								callerBlob.set_u8("deity_id", Deity::leutnant);

								CBitStream params;
								params.write_u8(Deity::leutnant);
								params.write_u16(callerBlob.getNetworkID());
								this.SendCommand(this.getCommandID("sync_deity"), params);
							}
						}
						else
						{
							if (data == "stahlhelm")
							{
								CBlob@ callerBlob = getBlobByNetworkID(caller);
								
								if (isClient())
								{
									this.getSprite().PlaySound("ConstructShort");
								}
							
								if (isServer())
								{
									CBlob@ blob = server_CreateBlob("stahlhelm", callerBlob.getTeamNum(), this.getPosition());
									if (blob is null) return;
	
									if (!blob.canBePutInInventory(callerBlob))
									{
										callerBlob.server_Pickup(blob);
									}
									else if (callerBlob.getInventory() !is null && !callerBlob.getInventory().isFull())
									{
										callerBlob.server_PutInInventory(blob);
									}
								}
							}
							else
							{
								if (data == "villaincap")
								{
									CBlob@ callerBlob = getBlobByNetworkID(caller);
									
									if (isClient())
									{
										this.getSprite().PlaySound("ConstructShort");
									}
								
									if (isServer())
									{
										CBlob@ blob = server_CreateBlob("villaincap", callerBlob.getTeamNum(), this.getPosition());
										if (blob is null) return;
		
										if (!blob.canBePutInInventory(callerBlob))
										{
											callerBlob.server_Pickup(blob);
										}
										else if (callerBlob.getInventory() !is null && !callerBlob.getInventory().isFull())
										{
											callerBlob.server_PutInInventory(blob);
										}
									}
								}
								else
								{
									if (data == "gasthrower")
									{
										CBlob@ callerBlob = getBlobByNetworkID(caller);
										
										this.add_f32("deity_power", 100);
										
										if (isClient())
										{
											CBlob@ localBlob = getLocalPlayerBlob();
											if (localBlob !is null)
											{
												if (this.getDistanceTo(localBlob) < 128)
												{
													this.getSprite().PlaySound("levelup", 3.00f, 1.00f);
												}
											}
										}
										
										if (isServer())
										{
											callerPlayer.set_u8("deity_id", Deity::leutnant);
											callerBlob.set_u8("deity_id", Deity::leutnant);
				
											CBitStream params;
											params.write_u8(Deity::leutnant);
											params.write_u16(callerBlob.getNetworkID());
											this.SendCommand(this.getCommandID("sync_deity"), params);
										}
										
										if (isClient())
										{
											this.getSprite().PlaySound("ConstructShort");
										}
									
										if (isServer())
										{
											CBlob@ blob = server_CreateBlob("gasthrower", callerBlob.getTeamNum(), this.getPosition());
											if (blob is null) return;
			
											if (!blob.canBePutInInventory(callerBlob))
											{
												callerBlob.server_Pickup(blob);
											}
											else if (callerBlob.getInventory() !is null && !callerBlob.getInventory().isFull())
											{
												callerBlob.server_PutInInventory(blob);
											}
										}
									}
									else
									{
										if (data == "mat_mustard")
										{
											CBlob@ callerBlob = getBlobByNetworkID(caller);
											
											if (isClient())
											{
												this.getSprite().PlaySound("ConstructShort");
											}
										
											if (isServer())
											{
												CBlob@ blob = server_CreateBlob("mat_mustard", callerBlob.getTeamNum(), this.getPosition());
												if (blob is null) return;
												blob.server_SetQuantity(100);
				
												if (!blob.canBePutInInventory(callerBlob))
												{
													callerBlob.server_Pickup(blob);
												}
												else if (callerBlob.getInventory() !is null && !callerBlob.getInventory().isFull())
												{
													callerBlob.server_PutInInventory(blob);
												}
											}
										}
									}
								}
							}
						}
					}
				}				
			}
		}
	}
}