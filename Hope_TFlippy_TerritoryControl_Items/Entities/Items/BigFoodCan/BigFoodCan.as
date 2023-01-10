#include "Knocked.as"

const u8 food_max = 20;

void onInit(CBlob@ this)
{
	//this.Tag("food");
	this.getShape().SetRotationsAllowed(false);
	this.addCommandID("food_eat");
	//this.getCurrentScript().tickFrequency = 10;

	this.set_u8("food_amount", food_max);
	this.set_bool("shouldheal", true);
	this.set_u16("next_use", 0);
	this.set_u16("hooman", 0);
	this.setInventoryName("Scrub's Chow XL (" + this.get_u8("food_amount") + "/" + food_max + ")");
	this.SetInventoryIcon("BigFoodCan.png", food_max - this.get_u8("food_amount"), Vec2f(24, 24));
}
/*
void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null) return;

	if (caller.getHealth() < caller.getInitialHealth())
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());

		CButton@ button = caller.CreateGenericButton(22, Vec2f(0, 0), this, this.getCommandID("food_eat"), "Eat (" + this.get_u8("food_amount") + "/" + food_max + ")", params);
		button.enableRadius = 32.0f;
	}
}
*/

void onTick (CBlob@ this)
{
	if (this.isAttached())
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (point !is null)
		{
			CBlob@ holder = point.getOccupied();
			if (holder !is null)
			{
				this.set_u16("hooman", holder.getNetworkID());
				if (this !is null) holder.set_u16("bighoodcan_netid", this.getNetworkID());
				//client_AddToChat("amogus", SColor(255, 39, 26, 255));
				//CBitStream params;
				//params.write_u16(holder.getNetworkID());
			}
		}
	}
	this.set_bool("shouldheal", true);
	//u16 blob_id;
	//if (!params.saferead_u16(blob_id)) return;	
	const bool can_heal = getGameTime() > this.get_u16("next_use");
	
	if (this.get_u16("hooman") != 0 && can_heal)
	{
		CBlob@ blob = getBlobByNetworkID(this.get_u16("hooman"));
		if (blob is null) return;
		
		CInventory @inv = blob.getInventory();
		if (inv is null) return;
		
		if (inv.getItemsCount() > 0)
		{
			for (int i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob @item = inv.getItem(i);
				if (item.hasTag("food"))
				{
					this.set_bool("shouldheal", false);
				}
			}
		}
		
		CControls@ controls = blob.getControls();
		if (controls is null) return;
		if (blob.getHealth() < blob.getInitialHealth() && blob.isKeyPressed(key_eat) && can_heal && this.get_bool("shouldheal"))
		{
			//&& can_heal
			//&& this.get_bool("shouldheal")
			if (this.getNetworkID() == blob.get_u16("bighoodcan_netid") && blob.isMyPlayer() && this.get_u32("next_heal") < getGameTime())
			{
				this.SendCommand(this.getCommandID("food_eat"));
				this.set_u32("next_heal", getGameTime()+10);
			}
		}
	/*
		this.getSprite().PlaySound("Eat.ogg");
		this.setInventoryName("Scrub's Chow XL (" + this.get_u8("food_amount") + "/" + food_max + ")");
		this.SetInventoryIcon("BigFoodCan.png", food_max - this.get_u8("food_amount"), Vec2f(24, 24));
		
		if (isServer())
		{
			CBlob@ b = getBlobByNetworkID(this.get_u16("hooman"));
			if (b is null) return;
			if (b.getHealth() < b.getInitialHealth())
			{
				//client_AddToChat("health", SColor(255, 39, 26, 255));
				if(b.isKeyJustPressed(key_eat))
				{
					//client_AddToChat("Bing Chilling", SColor(255, 39, 26, 255));
					b.server_Heal(5.0f);
					
					if (this.get_u8("food_amount") <= 1) this.server_Die();
					else
					{
						this.set_u8("food_amount", this.get_u8("food_amount") - 1);
						this.Sync("food_amount", true);
						
						/*
						CSprite@ sprite = this.getSprite();
						if (sprite is null) return;
					
						Animation@ animation = sprite.getAnimation("food_can_icon");
						if (animation is null) return;
					
						sprite.animation.frame = 20 - this.get_u8("food_amount");
						
					}
				}
			}
		}
	*/
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	const bool can_heal = getGameTime() > this.get_u16("next_use");
	if (cmd == this.getCommandID("food_eat") && can_heal)
	{
		this.setInventoryName("Scrub's Chow XL (" + this.get_u8("food_amount") + "/" + food_max + ")");
		this.SetInventoryIcon("BigFoodCan.png", food_max - this.get_u8("food_amount"), Vec2f(24, 24));

		if (isServer())
		{
			//u16 blob_id;
			//if (!params.saferead_u16(blob_id)) return;
			CBlob@ blob = getBlobByNetworkID(this.get_u16("hooman"));

			if (blob !is null)
			{
				blob.server_Heal(2.0f);
				//blob.setKeyPressed(key_eat, false);
					
				if (this.get_u8("food_amount") <= 1)
				{
					this.getSprite().PlaySound("dig_stone.ogg", 1.0f, 0.8f);
					this.server_Die();
				}
				else
				{
					this.set_u8("food_amount", this.get_u8("food_amount") - 1);
					this.Sync("food_amount", true);
				}
				this.set_u16("next_use", getGameTime() + 10);
			}
		}
		if (getGameTime() + 20 > this.get_u16("next_use")) this.getSprite().PlaySound("Eat.ogg");
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint)
{
	this.set_u16("hooman", 0);
}

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	if (inventoryBlob is null) return;

	CInventory@ inv = inventoryBlob.getInventory();

	if (inv is null) return;
	
	this.set_u16("hooman", inventoryBlob.getNetworkID());
	this.doTickScripts = true;
	inv.doTickScripts = true;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic();
}
