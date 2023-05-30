#include "Descriptions.as";
#include "MakeMat.as";

const u32 tick_freq = 45*2;

void onInit(CBlob@ this)
{
	this.setPosition(this.getPosition()-Vec2f(0,40));
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;
	
	this.Tag("change team on fort capture");
	this.Tag("extractable");
	this.addCommandID("write");
	this.addCommandID("sync_prop");
	
	this.SetLight(true);
	this.SetLightRadius(250.0f);
	this.SetLightColor(SColor(255, 255, 240, 210));

	this.getSprite().getConsts().accurateLighting = true;
	
	this.set_string("mat_prop", XORRandom(4)==0?"mat_methane":"mat_oil");

	if (isClient())
	{
		CBitStream params;
		params.write_bool(false);
		this.SendCommand(this.getCommandID("sync_prop"), params);
	}

	this.getCurrentScript().tickFrequency=1;//45*2;	//45 oil per minute

	this.Tag("upkeep building");
	this.set_u8("upkeep cap increase", 2);
	this.set_u8("upkeep cost", 0);
	this.Tag("can be captured by neutral");
	
	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("MinimapIcons.png",64,Vec2f(8,8));
	this.SetMinimapRenderAlways(true);

	if (this.hasTag("name_changed"))
	{
		this.setInventoryName(this.get_string("text"));
		this.set_string("shop description", this.get_string("text"));
	}

	this.inventoryButtonPos = Vec2f(30, 34);
}

void onDie(CBlob@ this)
{
	if (isServer())
	{
		if (getBlobByNetworkID(this.get_u16("follow_id")) !is null
			&& getBlobByNetworkID(this.get_u16("follow_id")).getName() == "oilrigcollider")
				getBlobByNetworkID(this.get_u16("follow_id")).server_Die();
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	CSpriteLayer@ front = this.getSpriteLayer("frontlayer");
	if (front !is null)
	{
		CBlob@ local = getLocalPlayerBlob();
		front.SetVisible(local is null || !local.isOverlapping(blob));
	}

	if (isClient() && getGameTime()%(15+XORRandom(30)) == 0)
		ParticleAnimated("LargeSmoke", blob.getPosition() + Vec2f(32, -52), Vec2f((XORRandom(20)-7)*0.01f, -0.75f), 0, 1.00f, 5 + XORRandom(5), 0, false);
	
	if (isClient())
	{
		if (blob.getTickSinceCreated() == 1 || !blob.hasTag("initializded_layers"))
		{
			CBlob@ blob = this.getBlob();
			if (blob is null) return;
			
			this.SetEmitSound("lgenerator_loop.ogg");
			this.SetEmitSoundVolume(0.25f);
			this.SetEmitSoundSpeed(0.75f+XORRandom(50)*0.001f);
			this.SetEmitSoundPaused(false);
			
			// front layer
			CSpriteLayer@ front = this.addSpriteLayer("frontlayer", "OilRig.png", 64, 64);
			if (front !is null)
			{
				front.SetOffset(Vec2f(28, 16));
				front.SetRelativeZ(50);
				Animation@ def = front.addAnimation("def", 0, false);
				if (def !is null)
				{
					def.AddFrame(2);
					front.SetAnimation(def);
					front.SetFrameIndex(0);
				}
			}
			
			// left column
			{
				Vec2f pos = blob.getPosition()-Vec2f(27, -40);
				f32 dist = getMap().tilemapheight*8-pos.y;
			
				HitInfo@[] infos;
				getMap().getHitInfosFromRay(pos, 90,
					getMap().tilemapheight*8-pos.y, blob, @infos);
				for (u32 i = 0; i < infos.length; i++)
				{
					HitInfo@ info = infos[i];
					if (info is null) continue;
					dist = info.distance;
				}
			
				int segments = Maths::Ceil(dist/64);
				for (int i = 0; i < segments; i++)
				{
					CSpriteLayer@ seg = this.addSpriteLayer("leftlayer"+i, "OilRig", 32, 64);
					if (seg is null) continue;
					Animation@ def = seg.addAnimation("def", 0, false);
					if (def is null) continue;
			
					def.AddFrame(6);
					seg.SetAnimation(def);
					seg.SetFrameIndex(0);
					seg.SetLighting(true);
			
					seg.SetVisible(true);
					seg.SetOffset(Vec2f(27, 81 + 64*i));
				}
			}
			// right column
			{
				Vec2f pos = blob.getPosition()-Vec2f(-35, -40);
				f32 dist = getMap().tilemapheight*8-pos.y;
				
				HitInfo@[] infos;
				getMap().getHitInfosFromRay(pos, 90,
					getMap().tilemapheight*8-pos.y, blob, @infos);
				for (u32 i = 0; i < infos.length; i++)
				{
					HitInfo@ info = infos[i];
					if (info is null) continue;
					dist = info.distance;
				}
			
				int segments = Maths::Ceil(dist/64);
				for (int i = 0; i < segments; i++)
				{
					CSpriteLayer@ seg = this.addSpriteLayer("rightlayer"+i, "OilRig", 32, 64);
					if (seg is null) continue;
					Animation@ def = seg.addAnimation("def", 0, false);
					if (def is null) continue;
			
					def.AddFrame(6);
					seg.SetAnimation(def);
					seg.SetFrameIndex(0);
					seg.SetLighting(true);
			
					seg.SetVisible(true);
					seg.SetOffset(Vec2f(-35, 81 + 64*i));
				}
			}
			// drill
			{
				Vec2f pos = blob.getPosition()-Vec2f(-3, -40);
				f32 dist = getMap().tilemapheight*8-pos.y;
			
				HitInfo@[] infos;
				getMap().getHitInfosFromRay(pos, 90,
					getMap().tilemapheight*8-pos.y, blob, @infos);
				for (u32 i = 0; i < infos.length; i++)
				{
					HitInfo@ info = infos[i];
					if (info is null) continue;
					dist = info.distance;
				}
			
				int segments = Maths::Ceil(dist/16);
				for (int i = 0; i < segments; i++)
				{
					CSpriteLayer@ seg = this.addSpriteLayer("midlayer"+i, "OilRig_parts.png", 16, 16);
					if (seg is null) continue;
					Animation@ def = seg.addAnimation("def", 0, false);
					Animation@ extra = seg.addAnimation("extra", 0, false);
					if (def is null || extra is null) continue;
			
					def.AddFrame(0);
					extra.AddFrame(1);
					if (i >= segments-3)
					{
						seg.SetAnimation(extra);
						seg.SetFrameIndex(0);
					}
					else 
					{
						seg.SetAnimation(def);
						seg.SetFrameIndex(0);
					}
			
					seg.SetLighting(true);
					seg.RotateBy(i%2==0?180:0, Vec2f(0,0));
			
					seg.SetVisible(true);
					seg.SetOffset(Vec2f(-3, 58 + 16*i));
				}
			}
			blob.Tag("initializded_layers");
		}
	}
}

void onTick(CBlob@ this)
{
	if (isServer()) 
	{
		if (this.getTickSinceCreated() > 1 && !this.exists("follow_id"))
		{
			CBlob@ b = server_CreateBlob("oilrigcollider", this.getTeamNum(), this.getPosition());
			if (b is null)
				this.server_Die();
			else this.set_u16("follow_id", b.getNetworkID());
		}

		if ((getGameTime()+this.getNetworkID()) % tick_freq == 0)
		{
			CBlob@ storage = FindStorage(this, this.getTeamNum());
			if (storage !is null)
			{
				MakeMat(storage, this.getPosition(), this.get_string("mat_prop"), XORRandom(3));
			}
			else if (this.getInventory().getCount(this.get_string("mat_prop")) < 1600)
			{
				MakeMat(this, this.getPosition(), this.get_string("mat_prop"), XORRandom(3));
			}
		}
	}
}

CBlob@ FindStorage(CBlob@ this, u8 team)
{
	if (team >= 100) return null;
	if (XORRandom(3)==0) return null; // 33% chance not to put oil in ur storage

	CBlob@[] blobs;
	bool is_oil = this.get_string("mat_prop") == "mat_oil";
	getBlobsByName(is_oil?"oiltank":"gastank", @blobs);

	CBlob@[] validBlobs;

	for (u32 i = 0; i < blobs.length; i++)
	{
		if (blobs[i].getTeamNum() == team && blobs[i].getInventory().getCount(this.get_string("mat_prop")) < (is_oil?300:500))
		{
			validBlobs.push_back(blobs[i]);
		}
	}

	if (validBlobs.length == 0) return null;

	return validBlobs[XORRandom(validBlobs.length)];
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	this.set_bool("shop available", false);

	if (caller is null) return;
	if (!this.isOverlapping(caller)) return;

	//rename the oilrig
	CBlob@ carried = caller.getCarriedBlob();
	if(carried !is null && carried.getName() == "paper" && caller.getTeamNum() == this.getTeamNum())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		params.write_u16(carried.getNetworkID());

		CButton@ buttonWrite = caller.CreateGenericButton("$icon_paper$", Vec2f(0, -8), this, this.getCommandID("write"), "Rename the rig.", params);
	}
}

void onAddToInventory(CBlob@ this,CBlob@ blob) //i'll keep it just to be sure
{
	if(blob.getName()!=this.get_string("mat_prop")){
		this.server_PutOutInventory(blob);
	}
}
bool isInventoryAccessible(CBlob@ this,CBlob@ forBlob)
{
	return forBlob.isOverlapping(this) && (forBlob.getCarriedBlob() is null || forBlob.getCarriedBlob().getName()==this.get_string("mat_prop"));
	//return (forBlob.isOverlapping(this));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("write"))
	{
		if (isServer())
		{
			CBlob @caller = getBlobByNetworkID(params.read_u16());
			CBlob @carried = getBlobByNetworkID(params.read_u16());

			if (caller !is null && carried !is null)
			{
				this.set_string("text", carried.get_string("text"));
				this.Sync("text", true);
				this.set_string("shop description", this.get_string("text"));
				this.Sync("shop description", true);
				carried.server_Die();
				this.Tag("name_changed");
			}
		}
		if (isClient())
		{
			this.setInventoryName(this.get_string("text"));
		}
	}
	else if (cmd == this.getCommandID("sync_prop"))
	{
		bool init = params.read_bool();
		bool resend = !init && isServer();

		if (resend)
		{
			CBitStream stream;
			stream.write_bool(true);
			stream.write_string(this.get_string("mat_prop"));
			this.SendCommand(this.getCommandID("sync_prop"), stream);
		}	
		else
		{
			string prop = params.read_string();
			this.set_string("mat_prop", prop);
		}
	}
}