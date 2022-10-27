//trap block script for devious builders

#include "Hitters.as"
#include "MapFlags.as"
#include "ParticleSparks.as";
#include "MinableMatsCommon.as";

int openRecursion = 0;

void onInit(CBlob@ this)
{

	this.getShape().SetRotationsAllowed( false );
    this.getSprite().getConsts().accurateLighting = false;  
	this.Tag("builder always hit");
	
    //this.Tag("place norotate");
    
    //block knight sword
	this.Tag("blocks sword");

	this.Tag("blocks water");
	
	this.getShape().SetOffset(Vec2f(4, 0));
	
	this.getCurrentScript().runFlags |= Script::tick_not_attached;	

	string name = this.getName();
	HarvestBlobMat[] mats = {};
	if (name == "stone_thick") mats.push_back(HarvestBlobMat(1.0f, "mat_stone"));
	this.set("minableMats", mats);			 
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return false;
}
