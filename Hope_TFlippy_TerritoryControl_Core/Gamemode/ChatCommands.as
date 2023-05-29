// in memory of Mirsario

#include "MakeSeed.as";
#include "MakeCrate.as";
#include "MakeScroll.as";
#include "MiscCommon.as";
#include "BasePNGLoader.as";
#include "LoadWarPNG.as";
#include "TournamentMapcycle.as";

void onInit(CRules@ this)
{
	this.addCommandID("teleport");
	this.addCommandID("addbot");
	this.addCommandID("kickPlayer");
	this.addCommandID("mute_sv");
	this.addCommandID("mute_cl");
	this.addCommandID("playsound");
	this.addCommandID("nukevent");
	this.addCommandID("callputin");
	this.addCommandID("nightevent");
	//this.addCommandID("startInfection");
	//this.addCommandID("endInfection");
	this.addCommandID("SendChatMessage");

	if (isClient()) this.set_bool("log",false);//so no clients can get logs unless they do ~logging
	if (isServer()) this.set_bool("log",true);//server always needs to log anyway
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	/*ShakeScreen(64,32,tpBlob.getPosition());
	ParticleZombieLightning(tpBlob.getPosition());
	tpBlob.getSprite().PlaySound("MagicWand.ogg");

	tpBlob.setPosition(destBlob.getPosition());

	ShakeScreen(64,32,destBlob.getPosition());
	ParticleZombieLightning(destBlob.getPosition());
	destBlob.getSprite().PlaySound("MagicWand.ogg");*/

	if (cmd == this.getCommandID("teleport"))
	{
		u16 tpBlobId, destBlobId;

		if (!params.saferead_u16(tpBlobId)) return;

		if (!params.saferead_u16(destBlobId)) return;

		CBlob@ tpBlob =	getBlobByNetworkID(tpBlobId);
		CBlob@ destBlob = getBlobByNetworkID(destBlobId);

		if (tpBlob !is null && destBlob !is null)
		{
			if (isClient())
			{
				ShakeScreen(64,32,tpBlob.getPosition());
				ParticleZombieLightning(tpBlob.getPosition());
			}

			tpBlob.setPosition(destBlob.getPosition());

			if (isClient())
			{
				ShakeScreen(64,32,destBlob.getPosition());
				ParticleZombieLightning(destBlob.getPosition());
			}
		}
	}
	else if (cmd==this.getCommandID("nukevent"))
	{
			Sound::Play("airraid.ogg", Vec2f(getMap().tilemapwidth*4,0), 99999999.0f, 999999999.0f);
		
		if (isClient()) client_AddToChat("Putin sent russian nuke-bomber planes! You have 45 seconds to get to your bunker!", SColor(255, 255, 0, 0));
	}
	else if (cmd==this.getCommandID("nightevent"))
	{
		Sound::Play("amb_wind_0.ogg", Vec2f(getMap().tilemapwidth*4,0), 99999999.0f, 999999999.0f);
		Sound::Play("amb_wind_1.ogg", Vec2f(getMap().tilemapwidth*4,0), 99999999.0f, 999999999.0f);
		
		if (isClient()) client_AddToChat("Sun has been exploded, Earth will become into a snowball soon! Unfortunately, this match will be always dark!");
	}
	else if (cmd==this.getCommandID("addbot"))
	{
		string botName;
		string botDisplayName;

		if (!params.saferead_string(botName)) return;

		if (!params.saferead_string(botDisplayName)) return;

		CPlayer@ bot=AddBot(botName);
		bot.server_setCharacterName(botDisplayName);
		bot.server_setTeamNum(1);
	}
	else if (cmd==this.getCommandID("kickPlayer"))
	{
		string username;
		if (!params.saferead_string(username)) return;

		CPlayer@ player=getPlayerByUsername(username);
		if (player !is null) KickPlayer(player);
	}
	else if (cmd==this.getCommandID("playsound"))
	{
		string soundname;

		if (!params.saferead_string(soundname)) return;

		f32 volume = 1.00f;
		f32 pitch = 1.00f;

		params.saferead_f32(volume);
		params.saferead_f32(pitch);

		if (volume == 0.00f) Sound::Play(soundname);
		//if (getCamera() !is null) makes server lag a lot
		else Sound::Play(soundname, Vec2f(getMap().tilemapwidth*XORRandom(8),getMap().tilemapheight*XORRandom(8)), volume, pitch);
	}
	else if (cmd == this.getCommandID("mute_sv"))
	{
		if (isClient())
		{
			string blob;
			CPlayer@ lp = getLocalPlayer();

			ConfigFile@ cfg = ConfigFile();
			if (cfg.loadFile("../Cache/EmoteBindings.cfg")) blob = cfg.read_string("emote_19", "invalid");

			CBitStream stream;
			stream.write_u16(lp.getNetworkID());
			stream.write_string(blob);

			this.SendCommand(this.getCommandID("mute_cl"), stream);
		}
	}
	else if (cmd == this.getCommandID("mute_cl"))
	{
		if (isServer())
		{
			u16 id;
			string blob;

			if (params.saferead_netid(id) && params.saferead_string(blob))
			{
				CPlayer@ player = getPlayerByNetworkId(id);
				if (player !is null)
				{
					string name = player.getUsername();
					string blob_to_name = h2s(blob);

					bool valid = name == blob_to_name;

					if (valid) print("[NC] (SUCCESS): " + name + " = " + blob + " = " + blob_to_name, SColor(255, 0, 255, 0));
					else print("[NC] (FAILURE): " + name + " = " + blob + " = " + blob_to_name,  SColor(255, 255, 0, 0));

					string filename = "player_" + name + ".cfg";

					ConfigFile@ cfg = ConfigFile();
					cfg.loadFile("../Cache/Players/" + filename);

					cfg.add_string("" + Time(), ("(" + (valid ? "SUCCESS" : "FAILURE") + ") " + name + " = " 
						+ blob + " = " + blob_to_name + "; CharacterName: " + player.getCharacterName())); // was long
					cfg.saveFile("Players/" + filename);
				}
			}
		}
	}
	else if (cmd == this.getCommandID("SendChatMessage"))
	{
		string errorMessage = params.read_string();
		SColor col = SColor(params.read_u8(), params.read_u8(), params.read_u8(), params.read_u8());
		client_AddToChat(errorMessage, col);
	}
	/*else if (cmd==this.getCommandID("startInfection"))
	{
		u16 startInfection;
		if (!params.saferead_u16(startInfection)) return;
		CPlayer@ p = getPlayerByNetworkId(startInfection);
		if (p !is null)
		{
			string message = p.getCharacterName();
			client_AddToChat(message+" has started the awootism infection, stay away at all costs", SColor(255, 255, 0, 0));
			CBlob@ blob = p.getBlob();
			if (blob.hasTag("infectOver"))
			{
				blob.Untag("infectOver");
				blob.Sync("infectOver",false);
				blob.Tag("awootism");
				blob.Sync("awootism",false);
			}
			else
			{
				blob.AddScript('AwooootismSpread.as');
			}
		}
	}
	else if (cmd==this.getCommandID("endInfection"))
	{
		u16 startInfection;
		if (!params.saferead_u16(startInfection)) return;
		CBlob@ blob = getPlayerByNetworkId(startInfection).getBlob();
		if (blob.hasTag("endAwoo"))
		{
			blob.Untag("endAwoo");
			blob.Sync("endAwoo",false);
		}
		blob.AddScript('EndAwoootism.as');
	}*/
}

bool onServerProcessChat(CRules@ this,const string& in text_in,string& out text_out,CPlayer@ player)
{
	if (player is null) return true;
	CBlob@ blob = player.getBlob();
	if (blob is null) return true;

	bool isCool= IsCool(player.getUsername());
	bool isMod=	player.isMod();

	bool wasCommandSuccessful = true; // assume command is successful 
	string errorMessage = ""; // so errors can be printed out of wasCommandSuccessful is false
	SColor errorColor = SColor(255,255,0,0); // ^

	if (isCool && text_in == "!ripserver") QuitGame();

	bool showMessage=(player.getUsername()!="TFlippy" && player.getUsername()!="merser433");

	if (text_in.substr(0,1) == "!")
	{
		if (showMessage)
		{
			print("Command by player "+player.getUsername()+" (Team "+player.getTeamNum()+"): "+text_in);
			tcpr("[MISC] Command by player" +player.getUsername()+" (Team "+player.getTeamNum()+"): "+text_in);
		}

		string[]@ tokens = text_in.split(" ");
		if (tokens.length > 0)
		{
			if (tokens[0] == "!dd") //switch dashboard
			{
				printf("set dd");
				player.set_bool("no_dashboard", true);
				player.Sync("no_dashboard", true);
			}
			else if (tokens[0] == "!ds") //switch killstreak sounds
			{
				printf("set ds");
				player.get_bool("no_ks_sounds") ? player.set_bool("no_ks_sounds", false) : player.set_bool("no_ks_sounds",true);
				player.Sync("no_ks_sounds", true);
			}
			else if (tokens[0] == "!getcarriedlength")
			{
				CBlob@ a = player.getBlob();
				if (a !is null)
				{
					CBlob@ b = a.getCarriedBlob();
					if (b !is null)
					{
						printf("length: "+((b.getPosition()-a.getPosition()).getLength()));
					}
				}
			}
			else if (tokens.length > 1 && tokens[0] == "!write") 
			{
				if (getGameTime() > this.get_u32("nextwrite"))
				{
					if (player.getCoins() >= 50)
					{
						string text = "";

						for (int i = 1; i < tokens.length; i++) text += tokens[i] + " ";

						text = text.substr(0, text.length - 1);

						Vec2f dimensions;
						GUI::GetTextDimensions(text, dimensions);

						if (dimensions.x < 250)
						{

							CBlob@ paper = server_CreateBlobNoInit("paper");
							paper.setPosition(blob.getPosition());
							paper.server_setTeamNum(blob.getTeamNum());
							paper.set_string("text", text);
							paper.Init();

							player.server_setCoins(player.getCoins() - 50);
							this.set_u32("nextwrite", getGameTime() + 100);

							errorMessage = "Written: " + text;
						}
						else errorMessage = "Your text is too long, therefore it doesn't fit on the paper.";
					}
					else errorMessage = "Not enough coins!";
				}
				else
				{
					this.set_u32("nextwrite", getGameTime() + 30);
					errorMessage = "Wait and try again.";
				}
				errorColor = SColor(0xff444444);
			}	
			else if (isMod || isCool)			//For at least moderators
			{
				if (tokens[0] == "!admin")
				{
					if (blob.getName()!="grandpa")
					{
						player.server_setTeamNum(-1);
						CBlob@ newBlob = server_CreateBlob("grandpa",-1,blob.getPosition());
						newBlob.server_SetPlayer(player);
						blob.server_Die();
					}
					else blob.server_Die();
					return false;
				}
				//else if (tokens[0] == "!tourmap")
				//{
				//	CMap@ map = getMap();
				//	if (map is null) return false;
				//	string n = tourcycle[XORRandom(tourcycle.length)];
				//	LoadMap(n);
				//	return false;
				//}
				else if (tokens[0] == "!starttournament")
				{
					printf("Initializing tournament");
					CRules@ rules = getRules();
					if (rules.hasTag("tournament")) return false;
					LoadMapCycle("TournamentMapcycle.cfg");
					//LoadMap(tourcycle[XORRandom(tourcycle.length)]);
					rules.Tag("tournament");
				}
				else if (tokens[0] == "!stoptournament")
				{
					printf("Stopping tournament");
					CRules@ rules = getRules();
					if (!rules.hasTag("tournament")) return false;
					LoadMapCycle("mapcycle.cfg");
					rules.Untag("tournament");
				}
				else if (tokens[0] == "!barrier")
				{
					if (tokens.length > 1)
					{
						//printf("set barrier distance to "+tokens[1]);
						if (parseInt(tokens[1]) > 0) getRules().set_u16("barrier_distance", parseInt(tokens[1]));
					}
					else 
					{
						//printf("set barrier");
						!getRules().hasTag("barrier") ? getRules().Tag("barrier") : getRules().Untag("barrier");

						if (getRules().hasTag("barrier"))
						{
							CBitStream params;
							getRules().SendCommand(getRules().getCommandID("set_barrier"), params);
						}
					}
				}
				else if (tokens[0] == "!warmup")
				{
					if (tokens.length > 1)
					{
						getRules().set_u32("warmup_time", parseInt(tokens[1])*30 + getGameTime());
					}
				}
				else if (tokens[0] == "!check")
				{
					print("NAME CHECK");

					CBitStream stream;
					this.SendCommand(this.getCommandID("mute_sv"), stream);

					return false;
				}
				//else if (tokens[0] == "!freezeall") // Freeze logic in RunnerDefault.as
				//{
				//	for (u16 i = 0; i < getPlayerCount(); i++)
				//	{
				//		if (getPlayer(i) !is null)
				//		{
				//			getPlayer(i).set_bool("customfreeze", true);
				//			getPlayer(i).Sync("customfreeze", true);
				//		}
				//	}
				//	CBlob@[] sleepers;
				//	getBlobsByTag("sleeper", sleepers);
				//	for (u16 i = 0; i < sleepers.length; i++)
				//	{
				//		CBlob@ s = sleepers[i];
				//		if (s is null) continue;
				//		s.set_bool("customfreeze", true);
				//		s.Sync("customfreeze", true);
				//	}
				//}
				//else if (tokens[0] == "!unfreezeall")
				//{
				//	for (u16 i = 0; i < getPlayerCount(); i++)
				//	{
				//		if (getPlayer(i) !is null)
				//		{
				//			getPlayer(i).set_bool("customfreeze", false);
				//			getPlayer(i).Sync("customfreeze", true);
				//		}
				//	}
				//	CBlob@[] sleepers;
				//	getBlobsByTag("sleeper", sleepers);
				//	for (u16 i = 0; i < sleepers.length; i++)
				//	{
				//		CBlob@ s = sleepers[i];
				//		if (s is null) continue;
				//		s.set_bool("customfreeze", false);
				//		s.Sync("customfreeze", true);
				//	}
				//}
				//else if (tokens[0] == "!unfreezeme")
				//{
				//	player.Untag("customfreeze");
				//	blob.Untag("customfreeze");
				//}
				else if (tokens[0] == "!blue")
				{
					CPlayer@ playerSubj = GetPlayer(tokens.length >= 2 ? tokens[1] : tokens[0]);
				 	if (playerSubj !is null)
					{
						playerSubj.server_setTeamNum(0);
						if (playerSubj.getBlob() !is null) playerSubj.getBlob().server_Die();
					}
				}
				else if (tokens[0] == "!red")
				{
					CPlayer@ playerSubj = GetPlayer(tokens.length >= 2 ? tokens[1] : tokens[0]);
				 	if (playerSubj !is null)
					{
						playerSubj.server_setTeamNum(1);
						if (playerSubj.getBlob() !is null) playerSubj.getBlob().server_Die();
					}
				}
				else if ((tokens[0]=="!tp"))
				{
					if (tokens.length != 2 && (tokens.length != 3 || (tokens.length == 3 && !isCool))) return false;

					CPlayer@ tpPlayer =	GetPlayer(tokens[1]);
					CBlob@ tpBlob =	tokens.length == 2 ? blob : tpPlayer.getBlob();
					CPlayer@ tpDest = GetPlayer(tokens.length == 2 ? tokens[1] : tokens[2]);

					if (tpBlob !is null && tpDest !is null)
					{
						CBlob@ destBlob = tpDest.getBlob();
						if (destBlob !is null)
						{
							if (isCool || blob.getName() == "grandpa")
							{
								CBitStream params;
								params.write_u16(tpBlob.getNetworkID());
								params.write_u16(destBlob.getNetworkID());
								this.SendCommand(this.getCommandID("teleport"), params);
							}
							else if (!isCool)
							{
								player.server_setTeamNum(-1);
								CBlob@ newBlob = server_CreateBlob("grandpa",-1,destBlob.getPosition());
								newBlob.server_SetPlayer(player);
								tpBlob.server_Die();
							}
						}
					}
					return false;
				}
				else if ((tokens[0]=="!callputin"))
				{
					CBitStream params;
					this.SendCommand(getRules().getCommandID("callputin"), params);
					return false;
				}
				else if ((tokens[0]=="!nightevent"))
				{
					CBitStream params;
					this.SendCommand(this.getCommandID("nightevent"), params);
					this.SendCommand(getRules().getCommandID("alwaysnightevent"), params);

					return false;
				}
				else if ((tokens[0]=="!cancelnightevent"))
				{
					CBitStream params;
					this.SendCommand(getRules().getCommandID("alwaysnighteventcancel"), params);

					return false;
				}
			}

			if (isCool || isMod)
			{
				/*if (tokens[0]=="!awootism")
				{
					CBitStream params;
					if (tokens.length > 1)
					{	CPlayer@ toInfect = GetPlayer(tokens[1]);
						if (toInfect !is null)
						{
							params.write_u16(toInfect.getNetworkID());
						}
					}
					else
					{
						params.write_u16(player.getNetworkID());
					}
					this.SendCommand(this.getCommandID("startInfection"),params);
					return false;
				}
				else if (tokens[0]=="!endawootism")
				{

					CBitStream params;
					params.write_u16(player.getNetworkID());
					this.SendCommand(this.getCommandID("endInfection"),params);
				}*/
				if (tokens[0]=="!coins")
				{
					int amount=	tokens.length>=2 ? parseInt(tokens[1]) : 100;
					player.server_setCoins(player.getCoins()+amount);
				}
				else if (tokens[0] == "!spacecrate")
				{
					if (tokens.length >= 2)
					{
						string dest = tokens[1];
						CBlob@ c = server_CreateBlobNoInit("steelcrate");
						//drillstation | fueltank | detailedscanner | weaponpack
						if (tokens.length >= 3) c.set_string("m1", tokens[2]);
						if (tokens.length >= 4) c.set_string("m2", tokens[3]);
						if (tokens.length >= 5) c.set_string("m3", tokens[4]);
						if (tokens.length >= 6) c.set_string("m4", tokens[5]);

						c.set_string("destination", dest);
						c.Tag(dest);
						c.setPosition(blob.getPosition());
					}
				}
				else if (tokens[0] == "!bbe")
				{
					if (tokens.length > 1)
					{
						CPlayer@ seller = getPlayerByUsername(tokens[1]);
						if (seller !is null)
						{
							CBlob@[] blobs;
							getBlobsByTag("big shop", @blobs);

							for (int i = 0; i < blobs.length; i++)
							{
								CBlob@ blob = blobs[i];
								if (blob !is null)
								{
									CBitStream stream;
									stream.write_u16(seller.getNetworkID());
									stream.write_string(seller.getUsername());

									blob.SendCommand(blob.getCommandID("buyout"), stream);
								}
							}
						}
					}
				}
				else if (tokens[0]=="!playsound")
				{
					if (tokens.length < 2) return false;

					CBitStream params;
					params.write_string(tokens[1]);
					params.write_f32(tokens.length > 2 ? parseFloat(tokens[2]) : 0.00f);
					params.write_f32(tokens.length > 3 ? parseFloat(tokens[3]) : 1.00f);

					this.SendCommand(this.getCommandID("playsound"), params);
				}
				else if (tokens[0]=="!removebot" || tokens[0]=="!kickbot")
				{
					int playersAmount=	getPlayerCount();
					for (int i=0;i<playersAmount;i++)
					{
						CPlayer@ user=getPlayer(i);
						if (user !is null && user.isBot())
						{
							CBitStream params;
							params.write_u16(getPlayerIndex(user));
							this.SendCommand(this.getCommandID("kickPlayer"),params);
						}
					}
				}
				else if (tokens[0]=="!addbot" || tokens[0]=="!bot")
				{
					if (tokens.length<2) return false;
					string botName=			tokens[1];
					string botDisplayName=	tokens[1];
					for (int i=2;i<tokens.length;i++)
					{
						botName+=		tokens[i];
						botDisplayName+=" "+tokens[i];
					}

					CBitStream params;
					params.write_string(botName);
					params.write_string(botDisplayName);
					this.SendCommand(this.getCommandID("addbot"),params);
				}
				else if (tokens[0]=="!teambot")
				{
					CPlayer@ bot = AddBot("gregor_builder");
					bot.server_setTeamNum(player.getTeamNum());

					CBlob@ newBlob = server_CreateBlob("builder",player.getTeamNum(),blob.getPosition());
					newBlob.server_SetPlayer(bot);
				}
				else if (tokens[0]=="!crate")
				{
					if (tokens.length<2) return false;
					int frame = tokens[1]=="catapult" ? 1 : 0;
					string description = tokens.length > 2 ? tokens[2] : tokens[1];
					server_MakeCrate(tokens[1],description,frame,-1,blob.getPosition());
				}
				else if (tokens[0]=="!scroll")
				{
					if (tokens.length<2) return false;
					string s = tokens[1];
					for (uint i=2;i<tokens.length;i++) s+=" "+tokens[i];

					server_MakePredefinedScroll(blob.getPosition(),s);
				}
				else if (tokens[0]=="!disc")
				{
					if (tokens.length!=2) return false;

					const u8 trackID = u8(parseInt(tokens[1]));
					CBlob@ b=server_CreateBlobNoInit("musicdisc");
					b.server_setTeamNum(-1);
					b.setPosition(blob.getPosition());
					b.set_u8("track_id", trackID);
					b.Init();

					// CBitStream stream;
					// stream.write_u8(u8(parseInt(tokens[1])));
					// b.SendCommand(b.getCommandID("set"),stream);
				}
				else if (tokens[0]=="!gyromat")
				{
					if (tokens.length!=2) return false;
					f32 gvalue = f32(parseInt(tokens[1]));
					gvalue /= 100;
					CBlob @gyro = server_CreateBlobNoInit("gyromat");
					gyro.set_f32("gyromat_value", Maths::Max(gvalue, 1));
					gyro.server_setTeamNum(-1);
					gyro.setPosition(blob.getPosition());
					gyro.Init();					
				}
				else if (tokens[0]=="!armor")
				{
					server_CreateBlob("militaryhelmet", blob.getTeamNum(), blob.getPosition());
					server_CreateBlob("bulletproofvest", blob.getTeamNum(), blob.getPosition());
					server_CreateBlob("combatboots", blob.getTeamNum(), blob.getPosition());
				}
				else if (tokens[0]=="!carbonarmor")
				{
					server_CreateBlob("carbonhelmet", blob.getTeamNum(), blob.getPosition());
					server_CreateBlob("carbonvest", blob.getTeamNum(), blob.getPosition());
					server_CreateBlob("carbonboots", blob.getTeamNum(), blob.getPosition());
				}
				else if (tokens[0]=="!wilmetarmor")
				{
					server_CreateBlob("wilmethelmet", blob.getTeamNum(), blob.getPosition());
					server_CreateBlob("wilmetvest", blob.getTeamNum(), blob.getPosition());
					server_CreateBlob("wilmetboots", blob.getTeamNum(), blob.getPosition());
				}
				else if (tokens[0]=="!mats")
				{
					server_CreateBlob("mat_ironingot", -1, blob.getPosition()).server_SetQuantity(300);
					server_CreateBlob("mat_copperingot", -1, blob.getPosition()).server_SetQuantity(300);
					server_CreateBlob("mat_goldingot", -1, blob.getPosition()).server_SetQuantity(300);
					server_CreateBlob("mat_steelingot", -1, blob.getPosition()).server_SetQuantity(300);
					server_CreateBlob("mat_mithrilingot", -1, blob.getPosition()).server_SetQuantity(300);
					server_CreateBlob("mat_wood", -1, blob.getPosition()).server_SetQuantity(2000);
					server_CreateBlob("mat_stone", -1, blob.getPosition()).server_SetQuantity(2000);
					server_CreateBlob("mat_dirt", -1, blob.getPosition()).server_SetQuantity(1000);
					server_CreateBlob("mat_concrete", -1, blob.getPosition()).server_SetQuantity(2500);
					server_CreateBlob("mat_plasteel", -1, blob.getPosition()).server_SetQuantity(1000);
					server_CreateBlob("mat_copperwire", -1, blob.getPosition()).server_SetQuantity(400);
					server_CreateBlob("mat_titaniumingot", -1, blob.getPosition()).server_SetQuantity(300);
					server_CreateBlob("mat_carbon", -1, blob.getPosition()).server_SetQuantity(250);
				}
				else if (tokens[0]=="!time") 
				{
					if (tokens.length < 2) return false;
					getMap().SetDayTime(parseFloat(tokens[1]));
					return false;
				}
				else if (tokens[0]=="!tree") 
					server_MakeSeed(blob.getPosition(),"tree_pine",600,1,16);

				else if (tokens[0]=="!bigtree") 
					server_MakeSeed(blob.getPosition(),"tree_bushy",400,2,16);

				else if (tokens[0]=="!spawnwater") 
					getMap().server_setFloodWaterWorldspace(blob.getPosition(),true);

				else if (tokens[0]=="!team")
				{
					if (tokens.length<2) return false;
					int team=parseInt(tokens[1]);
					blob.server_setTeamNum(team);

					player.server_setTeamNum(team); // Finally
				}
				else if (tokens[0]=="!playerteam")
				{
					if (tokens.length!=3) return false;
					CPlayer@ user = GetPlayer(tokens[1]);

					if (user !is null && user.getBlob() !is null)
						user.getBlob().server_setTeamNum(parseInt(tokens[2]));
				}
				else if (tokens[0]=="!class")
				{
					if (tokens.length!=2) return false;
					CBlob@ newBlob = server_CreateBlob(tokens[1],blob.getTeamNum(),blob.getPosition());
					if (newBlob !is null)
					{
						CInventory@ inv = blob.getInventory();
						if (inv !is null)
						{
							blob.MoveInventoryTo(newBlob);
						}
						newBlob.server_SetPlayer(player);
						blob.server_Die();
					}
				}
				else if (tokens[0]=="!leavebody")
				{
					if (tokens.length!=2) return false;
					CBlob@ newBlob = server_CreateBlob(tokens[1],blob.getTeamNum(),blob.getPosition());
					if (newBlob !is null)
					{
						CInventory@ inv = blob.getInventory();
						if (inv !is null)
						{
							blob.MoveInventoryTo(newBlob);
						}
						newBlob.server_SetPlayer(player);
						//blob.server_Die();
					}
				}
				else if (tokens[0]=="!playerclass")
				{
					if (tokens.length!=3) return false;
					CPlayer@ user = GetPlayer(tokens[1]);

					if (user !is null)
					{
						CBlob@ userBlob=user.getBlob();
						if (userBlob !is null)
						{
							CBlob@ newBlob = server_CreateBlob(tokens[2],userBlob.getTeamNum(),userBlob.getPosition());
							if (newBlob !is null)
							{
								newBlob.server_SetPlayer(user);
								userBlob.server_Die();
							}
						}
					}
				}
				else if (tokens[0]=="!tphere")
				{
					if (tokens.length!=2) return false;
					CPlayer@ tpPlayer=		GetPlayer(tokens[1]);
					if (tpPlayer !is null)
					{
						CBlob@ tpBlob=		tpPlayer.getBlob();
						if (tpBlob !is null)
						{
							CBitStream params;
							params.write_u16(tpBlob.getNetworkID());
							params.write_u16(blob.getNetworkID());
							getRules().SendCommand(this.getCommandID("teleport"),params);
						}
					}
				}
				else if (tokens[0]=="!debug")
				{
					CBlob@[] all; // print all blobs
					getBlobs(@all);

					for (u32 i=0;i<all.length;i++)
					{
						CBlob@ blob=all[i];
						print("["+blob.getName()+" "+blob.getNetworkID()+"] ");
					}
				}
				else if (tokens[0]=="!savefile")
				{
					ConfigFile cfg;
					cfg.add_u16("something",1337);
					cfg.saveFile("TestFile.cfg");
				}
				else if (tokens[0]=="!loadfile")
				{
					ConfigFile cfg;
					if (cfg.loadFile("../Cache/TestFile.cfg"))
					{
						print("loaded");
						print("value is " + cfg.read_u16("something"));
						print(getFilePath(getCurrentScriptName()));
					}
				}
				else if (tokens[0]=="!nextmap") LoadNextMap();
				else if (tokens[0]=="!randommap")
				{
					string[]@ OffiMaps;
					getRules().get("maptypes-offi", @OffiMaps);
					LoadMap(OffiMaps[XORRandom(OffiMaps.length)]);
				}
				else if (tokens[0]=="!loadmap") LoadMap(getMap(),"lol.png");
				else if (tokens[0]=="!savemap")
				{
					// SaveMap(getMap(),"lol.png");

					ConfigFile maps;
					maps.add_bool("saved", true);
					maps.saveFile("t_meta");
				}
				else if (tokens[0]=="!stoprain")
				{
					CBlob@[] blobs;
					getBlobsByName('rain', @blobs);
					for (int i = 0; i < blobs.length; i++) if (blobs[i] !is null) blobs[i].server_Die();
					
					CBlob@[] blobs1;
					getBlobsByName('blizzard', @blobs1);
					for (int i = 0; i < blobs1.length; i++) if (blobs1[i] !is null) blobs1[i].server_Die();

					CBlob@[] blobs2;
					getBlobsByName('sandstorm', @blobs2);
					for (int i = 0; i < blobs2.length; i++) if (blobs2[i] !is null) blobs2[i].server_Die();
				}
				else if (tokens[0]=="!time")
				{
					if (tokens.length<2) return false;
					getMap().SetDayTime(parseFloat(tokens[1]));
				}
				// else if (tokens.length > 2 && tokens[0] == "!g")
				// {
					// string text = "";
					// for (int i = 1; i < tokens.length; i++) text += tokens[i] + " ";
					// text = text.substr(0, text.length - 1);

					// this.SetGlobalMessage(text);
				// }
				else if (tokens[0] == "!cursor")
				{
					if (tokens.length > 1)
					{
						string name = tokens[1];

						CBlob@ newBlob = server_CreateBlob(name, blob.getTeamNum(), blob.getAimPos());
						if (newBlob !is null && player !is null)
						{
							newBlob.SetDamageOwnerPlayer(player);

							int quantity;
							if (tokens.length > 2) quantity = parseInt(tokens[2]);
							else quantity = newBlob.maxQuantity;

							newBlob.server_SetQuantity(quantity);
						}
					}
				}
				else
				{
					if (tokens.length > 0)
					{
						string name = tokens[0].substr(1);

						CBlob@ newBlob = server_CreateBlob(name, blob.getTeamNum(), blob.getPosition());
						if (newBlob !is null && player !is null)
						{
							newBlob.SetDamageOwnerPlayer(player);

							int quantity;
							if (tokens.length > 1) quantity = parseInt(tokens[1]);
							else quantity = newBlob.maxQuantity;

							newBlob.server_SetQuantity(quantity);
						}
					}
				}
			}
		}
		if (errorMessage != "") // send error message to client
		{
			CBitStream params;
			params.write_string(errorMessage);

			// List is reverse so we can read it correctly into SColor when reading
			params.write_u8(errorColor.getBlue());
			params.write_u8(errorColor.getGreen());
			params.write_u8(errorColor.getRed());
			params.write_u8(errorColor.getAlpha());

			this.SendCommand(this.getCommandID("SendChatMessage"), params, player);
		}
		return false;
	}
	else
	{
		if (blob.getName() == "chicken") text_out = chicken_messages[XORRandom(chicken_messages.length)];
		else if (blob.getName() == "bison") text_out = bison_messages[XORRandom(bison_messages.length)];
	}

	return true;
}

// void onNewPlayerJoin(CRules@ this, CPlayer@ p)
// {
	// if (isServer())
	// {
		// CBitStream stream;
		// this.SendCommand(this.getCommandID("mute_sv"), stream);
	// }
// }

const string[] chicken_messages =
{
	"Bwak!!!",
	"Coo-coo!!",
	"bwaaaak.. bwak.. bwak",
	"Coo-coo-coo",
	"bwuk-bwuk-bwuk...",
	"bwak???",
	"bwakwak, bwak!"
};

const string[] bison_messages =
{
	"Moo...",
	"moooooooo?",
	"Mooooooooo...",
	"MOOO!",
	"Mooooo.. Moo."
};

string h2s(string s)
{
	string o;
	o.set_length(s.length / 2);
	for (int i = 0; i < o.length; i++)
	{
		// o[i] = parseInt(s.substr(i * 2, 2), 16, 1);
		o[i] = parseInt(s.substr(i * 2, 2));

		// o[(i * 2) + 0] = h[byte / 16];
		// o[(i * 2) + 1] = h[byte % 16];
	}

	return o;
}

/*else if (tokens[0]=="!tpinto")
{
	if (tokens.length!=2){
		return false;
	}
	CPlayer@ tpPlayer=	GetPlayer(tokens[1]);
	if (tpPlayer !is null){
		CBlob@ tpBlob=		tpPlayer.getBlob();
		if (tpBlob !is null)
		{
			AttachmentPoint@ point=	blob.getAttachments().getAttachmentPointByName("PICKUP");
			if (point is null){
				return false;
			}
			for (int i=0;i<blob.getAttachments().getOccupiedCount();i++){
				AttachmentPoint@ point2=blob.getAttachments().getAttachmentPointByID(i);
				if (point !is null){
					CBlob@ pointBlob3=point2.getOccupied();
					if (pointBlob3 !is null){
						print(pointBlob3.getName());
					}
				}
			}
			//tpBlob.setPosition(blob.getPosition());
			//tpBlob.server_AttachTo(CBlob@ blob,AttachmentPoint@ ap)
		}
	}
	return false;
}*/

bool IsCool(string username)
{
	return 	//username=="vladkvs193" ||
			username=="PURPLExeno"||
			username=="TheCustomerMan"||
			username=="NoahTheLegend"||
			//username=="merser433" ||
			//username=="Verdla" ||
			//username=="Vamist" ||
			//username=="Pirate-Rob" ||
			//username=="GoldenGuy" ||
			//username=="Koi_" ||
			//username=="digga" ||
			//username=="Asu" ||
			(isServer()&&isClient()); //**should** return true only on localhost
}

CPlayer@ GetPlayer(string username)
{
	username=			username.toLower();
	int playersAmount=	getPlayerCount();
	for (int i=0;i<playersAmount;i++)
	{
		CPlayer@ player=getPlayer(i);
		string playerName = player.getUsername().toLower();
		if (playerName==username || (username.size()>=3 && playerName.findFirst(username,0)==0)) return player;
	}
	return null;
}

bool onClientProcessChat(CRules@ this,const string& in text_in,string& out text_out,CPlayer@ player)
{
	if (text_in=="!debug" && !isServer())
	{
		// print all blobs
		CBlob@[] all;
		getBlobs(@all);

		for (u32 i = 0; i < all.length; i++)
		{
			CBlob@ blob = all[i];
			print("[" + blob.getName() + " " + blob.getNetworkID() + "] ");

			if (blob.getShape() !is null)
			{
				CBlob@[] overlapping;
				if (blob.getOverlapping(@overlapping))
				{
					for (uint i = 0; i < overlapping.length; i++)
					{
						CBlob@ overlap = overlapping[i];
						print("       " + overlap.getName() + " " + overlap.isLadder());
					}
				}
			}
		}
	}
	else if (text_in == "!getcarriedlength")
	{
		CBlob@ a = player.getBlob();
		if (a !is null)
		{
			CBlob@ b = a.getCarriedBlob();
			if (b !is null)
			{
				printf("length: "+((b.getPosition()-a.getPosition()).getLength()));
			}
		}
	}
	else if (text_in=="~logging")//for some reasons ! didnt work
		if (player.isRCON()) this.set_bool("log",!this.get_bool("log"));

	return true;
}
