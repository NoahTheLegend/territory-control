shared interface IEffectMode
{
	string getType();
	void init(CBlob@ blob);
	void onTick();
	void render(CSprite@ sprite, f32 scale);
	void processCommand(u8 cmd, CBitStream @params);
}

shared class CEffectModeBase : IEffectMode
{
	string getType() {return "base";}

	CBlob@ blob;
	void onTick()
	{
		
	}
	void init(CBlob@ blob)
	{
		@this.blob = blob;
	}
	void render(CSprite@ sprite,f32 scale){}
	void processCommand(u8 cmd, CBitStream @params){}
}