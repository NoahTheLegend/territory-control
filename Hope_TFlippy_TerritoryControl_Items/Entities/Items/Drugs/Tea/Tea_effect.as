//Script by Gingerbeard 
//fixed and simplified by brewskidafixer 2023
#include "HittersTC.as";

const string[] scriptnames = 
{
	"Drunk_Effect.as",
	"Fiksed.as",
	"Dominoed.as",
	//"Babbyed.as",
	"Bobonged.as",
	//"Bobomaxed.as",
	"Boofed.as",
	//"Crak_Effect.as",
	"Foofed.as",
	//"Pooted.as",
	"Fusk_Effect.as",
	//"Gooby_Effect.as",
	//"Paxilon_Effect.as",
	"Propeskoed.as",
	"Radpilled.as",
	//"Rippioed.as",
	"Schisked.as",
	"Stimed.as",
	"Polymorphine_Effect.as",
	"Sturded.as",
	"Mustardeffect.as",
	//"Pigger_Pregnant.as"
};

void onTick(CBlob@ this)
{
	//check for effects that just need removing
	for (int i = 0; i < scriptnames.length; i++)
	{
		string scriptname = scriptnames[i];
		if (this.hasScript(scriptname))
		{
			this.RemoveScript(scriptname);
		}
	}
	if (this.hasScript("Paxilon_Effect.as"))
	{
		// Remove sleeping effects
		CSprite@ sprite = this.getSprite();
		sprite.SetEmitSoundPaused(true);

		CSpriteLayer@ layer = sprite.getSpriteLayer("paxilon_zzz");
		if (layer !is null) layer.SetVisible(false);
		this.RemoveScript("Paxilon_Effect.as");
	}
	if (this.hasScript("Pigger_Pregnant.as"))
	{
		// Stop pigger sequence
		this.Untag("pigger_pregnant");
		this.RemoveScript("Pigger_Pregnant.as");
	}
	if (this.hasScript("Crak_Effect.as" ))
	{
		this.set_f32("crak_effect", 0.00f);
		this.Tag("remove_crak"); //will make crak run remove code and remove its script
				
		// Reset player angle and noise
		this.setAngleRadians(0.0f);
		this.getSprite().SetEmitSoundPaused(true);
		
	}
	if (this.hasScript("Gooby_Effect.as"))
	{
		this.set_f32("Gooby_Effect", 0.00f);
		this.setAngleRadians(0.0f);
		this.getSprite().SetEmitSoundPaused(true);
		this.Untag("no_suicide");
		this.RemoveScript("Gooby_Effect.as");
	}
	if (this.hasScript("Rippioed.as"))
	{
		this.set_f32("rippioed", 0.00f);
		this.setAngleRadians(0.0f);
		this.getSprite().SetEmitSoundPaused(true);
		this.RemoveScript("Rippioed.as");
	}
	if (this.hasScript("Pooted.as"))
	{
		this.set_f32("Pooted", 0.00f);
		this.setAngleRadians(0.0f);
		this.getSprite().SetEmitSoundPaused(true);
		this.RemoveScript("Pooted.as");
	}
	if (this.hasScript("Babbyed.as"))
	{
		this.Untag("no_suicide");
		this.set_f32("babbyed", 0);
		this.RemoveScript("Babbyed.as");
	}
	if (this.hasScript("Bobomaxed.as"))
	{
		if (isClient()) this.getSprite().PlaySound("methane_explode");
		if (isServer()) this.server_Hit(this, this.getPosition(), Vec2f(0, 0), 50.0, HittersTC::poison, true);
		this.RemoveScript("Bobomaxed.as");
	}




	if (isClient())
	{
		if (this.isMyPlayer())
		{
			SetScreenFlash(40, 40, 100, 0);
			getMap().CreateSkyGradient("skygradient.png");
		}
	}

	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
