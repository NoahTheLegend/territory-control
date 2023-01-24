//by noahthelegend and brewskidafixer

//class for data storage
class DrugResults {

	string inName;
	u8 inAmount;
	string outName;
	u8 outAmount;
	
	DrugResults(string inName, u8 inAmount, string outName,	u8 outAmount){
		this.inName= inName;
		this.inAmount =inAmount;
		this.outName =outName;
		this.outAmount =outAmount;
	}
	
	string tostring(){
		return (inName + ":" + inAmount + "->" + outName + ":" + outAmount);
	}
};

DrugResults[] NDrugResults = {
	DrugResults("stimpill",2,"stim",1),
	DrugResults("fuskpill",2,"fusk",1),
	DrugResults("fusk",3,"mat_fusk",10),
	DrugResults("rippiopill",2,"rippio",1),
	DrugResults("rippio",2,"mat_rippio",25),
	DrugResults("goobypill",2,"gooby",1),
	DrugResults("paxilonpill",2,"paxilon",1),
	DrugResults("paxilon",2,"mat_paxilon",20),
	DrugResults("love",2,"mat_love",15),
	DrugResults("boof",2,"mat_boof",25),
	DrugResults("mat_ganja",8,"tea",1),
	DrugResults("mat_protopopov",1,"mat_acid",50),
	DrugResults("crak",2,"mat_crak",25),
	DrugResults("polymorphine",2,"mat_polymorphine",25)
};
//reversed result
DrugResults[] RDrugResults = {
	DrugResults("stim",1,"stimpill",2),
	DrugResults("fusk",1,"fuskpill",2),
	DrugResults("mat_fusk",10,"fusk",3),
	DrugResults("rippio",1,"rippiopill",2),
	DrugResults("mat_rippio",25,"rippio",2),
	DrugResults("gooby",1,"goobypill",2),
	DrugResults("paxilon",1,"paxilonpill",2),
	DrugResults("mat_paxilon",20,"paxilon",2),
	DrugResults("mat_love",15,"love",2),
	DrugResults("mat_boof",25,"boof",2),
	DrugResults("tea",1,"mat_ganja",8),
	DrugResults("mat_acid",50,"mat_protopopov",1),
	DrugResults("mat_crak",25,"crak",2),
	DrugResults("mat_polymorphine",25,"polymorphine",2)
};



void onInit(CBlob@ this)
{
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 90;

	this.Tag("builder always hit");
	this.addCommandID("setnormal");//set normal recipes
	this.addCommandID("setrev");//set reversed recipes
	this.set_bool("isReversed",false);

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("DrugLab_Loop.ogg");
		sprite.SetEmitSoundVolume(0.25f);
		sprite.SetEmitSoundSpeed(0.6f);
		sprite.SetEmitSoundPaused(false);
	}
	
	//test print
	//for(u16 i=0; i<DResults.length;i++){
	//	print (i + ")" + DResults[i].tostring());
	//}
	
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


void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	if(this.get_bool("isReversed")){
		CButton@ button = caller.CreateGenericButton(18, Vec2f(0, 0), this, this.getCommandID("setnormal"), "normal recipe");
	}else{
		CButton@ button = caller.CreateGenericButton(17, Vec2f(0, 0), this, this.getCommandID("setrev"), "reverse recipe");
	}
	

}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("setnormal"))
	{
			this.set_bool("isReversed",false);
			this.Sync("isReversed",true);
	}
	if (cmd == this.getCommandID("setrev"))
	{
			this.set_bool("isReversed",true);
			this.Sync("isReversed",true);
	}
	
}


void onTick(CBlob@ this)
{
	CInventory@ inv = this.getInventory();
	if (inv is null) return;

	DrugResults[]@ DResults = this.get_bool("isReversed") ? @RDrugResults : @NDrugResults ;
	DrugResults@ R;
	for (u16 i = 0; i < DResults.length; i++)
	{
		@R = @DResults[i];
		CBlob@ item = inv.getItem(R.inName);
		if (item is null) continue;
		u16 count = inv.getCount(R.inName);
		
		if (count < R.inAmount) continue;

		
		if (isServer())
		{
			CBlob@ invBlob = inv.getBlob();
			invBlob.TakeBlob(R.inName, R.inAmount);

			CBlob@ res = server_CreateBlob(R.outName, this.getTeamNum(), this.getPosition()+Vec2f(0,12.0f));
			if (res !is null)
			{
				//res.Tag("justmade");
				res.server_SetQuantity(R.outAmount);
				
				//dont put back in inventory as it can process again
				//this.server_PutInInventory(res);
			}
		}
		else if (isClient())
		{
			this.getSprite().PlaySound("DrugLab_Create_Creamy.ogg", 1.00f, 1.10f);
			this.getSprite().PlaySound("DrugLab_Create_Acidic.ogg", 0.65f, 1.25f);
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;
	
	/*if(blob.hasTag("justmade")){
		blob.Untag("justmade");
		return;
	}*/
	if(blob.getTickSinceCreated()<=10){
		return;
	}
	
	if((blob.hasTag("material") || blob.hasTag("hopperable") || blob.hasTag("drug")) && !blob.isAttached()){
		DrugResults[]@ DResults = this.get_bool("isReversed") ? @RDrugResults : @NDrugResults ;
		for (u16 i = 0; i < DResults.length; i++)
		{
			if (DResults[i].inName == blob.getName()){
				if (isServer()) this.server_PutInInventory(blob);
				if (isClient()) this.getSprite().PlaySound("bridge_open.ogg");
				break;
			}
		}
	}
}