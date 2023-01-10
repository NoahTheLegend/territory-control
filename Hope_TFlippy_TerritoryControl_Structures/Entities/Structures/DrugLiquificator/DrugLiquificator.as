void onInit(CBlob@ this)
{
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 90;

	this.Tag("builder always hit");


	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("DrugLab_Loop.ogg");
		sprite.SetEmitSoundVolume(0.25f);
		sprite.SetEmitSoundSpeed(0.6f);
		sprite.SetEmitSoundPaused(false);
	}
}

void onInit(CSprite@ this)
{
	this.SetZ(-50);
	CSpriteLayer@ layer = this.addSpriteLayer("layer", "LiquidAnim.png", 12, 12);
	if (layer !is null)
	{
		layer.SetOffset(Vec2f(6.0f, 2.0f));
		Animation@ anim = layer.addAnimation("default", 5, true);
		if (anim !is null)
		{
			int[] frames = {0,1,2};
			anim.AddFrames(frames);
			layer.SetFrameIndex(0);
			layer.SetAnimation(anim);
		}
	}
}

const string[] matNames = { 
	"stimpill-2",
	"fuskpill-2",
	"fusk-3",
	"rippiopill-2",
	"rippio-2",
	"goobypill-2",
	"paxilonpill-2",
	"paxilon-2",
	"love-2",
	"boof-2",
	"mat_ganja-8",
	"mat_protopopov-1"
};

const string[] resultNames = { 
	"stim-1",
	"fusk-1",
	"mat_fusk-10",
	"rippio-1",
	"mat_rippio-25",
	"gooby-1",
	"paxilon-1",
	"mat_paxilon-20",
	"mat_love-15",
	"mat_boof-25",
	"tea-1",
	"mat_acid-50"
};

void onTick(CBlob@ this)
{
	CInventory@ inv = this.getInventory();
	if (inv is null) return;

	for (u16 i = 0; i < matNames.length; i++)
	{
		string[] spl = matNames[i].split("-");
		string[] res_spl = resultNames[i].split("-");
		string name;
		u16 req_amount;
		string result;
		u16 res_amount;
		if (spl.length > 1 && res_spl.length > 1)
		{
			name = spl[0];
			req_amount = parseInt(spl[1]);
			result = res_spl[0];
			res_amount = parseInt(res_spl[1]);
		}
		else continue;

		CBlob@ item = inv.getItem(name);
		if (item is null) continue;
		u16 count = inv.getCount(name);
		
		if (count < req_amount) continue;

		if (isClient())
		{
			this.getSprite().PlaySound("DrugLab_Create_Creamy.ogg", 1.00f, 1.10f);
			this.getSprite().PlaySound("DrugLab_Create_Acidic.ogg", 0.65f, 1.25f);
		}
		if (isServer())
		{
			for (u8 j = 0; j < req_amount; j++)
			{
				CBlob@ take = inv.getItem(name);
				if (take !is null) 
				{
					if (take.getQuantity() > 1 && (take.getQuantity() - req_amount) > 0)
					{
						take.server_SetQuantity(take.getQuantity() - req_amount);
						break;
					}
					else
					{
						this.server_PutOutInventory(take); // otherwise first slot blob doesnt get killed
						take.server_Die();
					}
				}
			}

			CBlob@ res = server_CreateBlob(result, this.getTeamNum(), this.getPosition()+Vec2f(0,12.0f));
			if (res !is null)
			{
				res.server_SetQuantity(res_amount);
				this.server_PutInInventory(res);
			}
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;
	
	if (!blob.isAttached())
	{
		string name;
		for (u16 i = 0; i < matNames.length; i++)
		{
			string[] spl = matNames[i].split("-");
			name = spl[0];
			if (name != blob.getName()) continue;
			if (isServer()) this.server_PutInInventory(blob);
			if (isClient()) this.getSprite().PlaySound("bridge_open.ogg");
		}
	}
}