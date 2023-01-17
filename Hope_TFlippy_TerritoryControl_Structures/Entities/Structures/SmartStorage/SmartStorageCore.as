// Script by brewskidafixer
#include "SmartStorageHelpers.as";

const u8 MaxItems = 20;
//string[] GitemsArray; //this same global array for all instances of script
//bool Gsynced = false;
void onInit(CBlob@ this)
{
	
	//string[] itemsArray;
	//this.set("itemsArray", @itemsArray);
	//if (isServer()) Gsynced = true;
	
	
	this.set_string("itemsArray", "");
	this.set_u8("itemsnum",0);
	this.addCommandID("sv_withdraw");
	this.addCommandID("sv_delete");
	//this.addCommandID("sv_sync");
	//print("SS start "+this.get_string("itemsArray"));
	//this.addCommandID("sv_store");
	
	string[] GitemsArray;
	this.set("GitemsArray",@GitemsArray);
	
	
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		//print("SS onCollision " +blob.getName()+ " :" +this.get_u32("SS_"+blob.getName()));
		if (this.get_u32("SS_"+blob.getName())>0) smartStorageAdd(this, blob);
		else if (canPickup(this, blob))
		{
			smartStorageAdd(this, blob);
		}
	}
}

bool canPickup(CBlob@ this, CBlob@ blob)
{
	if (this.get_u8("itemsnum") >= MaxItems) return false;
	return !blob.isAttached() && !blob.hasTag("dead") && !blob.hasTag("weapon") && (blob.hasTag("ammo") || blob.hasTag("material") || blob.hasTag("hopperable") || blob.hasTag("drug"));
}



void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("sv_withdraw"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		string blobName = params.read_string();
		if (caller !is null && this.get_u8("itemsnum") > 0)
		{
			if (!caller.getInventory().isFull())
			{
				if (isServer()) 
				{
					u32 cur_quantity = this.get_u32("SS_"+blobName);
					if (cur_quantity > 1)
					{
						cur_quantity = cur_quantity - 1; //remove offset
						CBlob@ blob = server_CreateBlob(blobName, -1, this.getPosition());
						if (blob !is null)
						{
							u16 blobMaxQuantity = Maths::Max(blob.getMaxQuantity(), 1);
							if (!blob.hasTag("drug"))
							{
								u32 quantity = blobMaxQuantity == 1 ? 1 : cur_quantity%(blobMaxQuantity);
								if (quantity == 0) quantity = blobMaxQuantity;

								blob.server_SetQuantity(quantity);
								caller.server_PutInInventory(blob);
								smartStorageTake(this, blobName, quantity);
							}
							else
							{
								caller.server_PutInInventory(blob);
								smartStorageTake(this, blobName, 1);
							}
						}
					}
					
					
				}
			}
		}
	}
	else if (cmd == this.getCommandID("sv_delete"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		string blobName = params.read_string();
		if (isServer()){
			
			string[] @GitemsArray;
			this.get("GitemsArray",@GitemsArray);
			for (u8 i = 0; i < GitemsArray.length(); i++)
			{
				if(GitemsArray[i]==blobName){
					//print("SS deleteing item "+blobName+":"+i+"/"+GitemsArray.length());
					this.set_u32("SS_"+blobName,0);
					GitemsArray.removeAt(i);
					this.set_u8("itemsnum",GitemsArray.length());
					this.set_string("itemsArray", join(GitemsArray,"."));
					this.Sync("SS_"+blobName, true);
					this.Sync("itemsArray", true);
					this.Sync("itemsnum", true);
					//this.Sync("GitemsArray", true);
					//this.SendCommand(this.getCommandID("sv_sync"), params);
					break;
					
				}
			}
			
		}
	}
	/*else if (cmd == this.getCommandID("sv_sync"))
	{
		//print("SS_sync " + this.get_u8("itemsnum") + ":" + this.get_string("itemsArray"));
	}*/
	/*else if (cmd == this.getCommandID("sv_store"))
	{
		if (isServer())
		{
			CBlob@ caller = getBlobByNetworkID(params.read_u16());
			if (caller !is null)
			{
				CInventory @inv = caller.getInventory();
				string bname = caller.getName();
				if (bname == "builder" || bname == "engineer" || bname == "peasant")
				{
					CBlob@ carried = caller.getCarriedBlob();
					if (carried !is null)
					{
						if (carried.hasTag("temp blob"))
						{
							carried.server_Die();
						}
					}
				}
				
				if (inv !is null)
				{
					for (u8 i = 0; i < inv.getItemsCount(); i++)
					{
						CBlob@ item = inv.getItem(i);
						if (item !is null)
						{
							if (canPickup(this, item))
							{
								if (this.exists("SS_"+item.getName()))
								{
									smartStorageAdd(this, item);
									continue;
								}
								else if (canStoreBlob(this, item))
								{
									smartStorageAdd(this, item);
									continue;
								}
							}
							if (!this.server_PutInInventory(item))
							{
								caller.server_PutInInventory(item);
							}
							else i--;
						}
					}
				}
			}
		}
	}*/
}

void smartStorageAdd(CBlob@ this, CBlob@ blob)
{
	//print("smartStorageAdd start");
	if (isServer())
	{
		string blobName = blob.getName();
		u16 blobQuantity = blob.getQuantity();
		//check blobQuantity > 0
		if(blobQuantity<1){
			//print("blobQuantity:" + blobQuantity);
			return;
		}
		
		//check if blobexists
		u32 cur_quantity = 0;
		if (this.exists("SS_"+blobName)) 
		{
			cur_quantity = this.get_u32("SS_"+blobName);
		} 
	
		//if cur_quantity = 0; then adding item to item list (0 = disabled)
		if(cur_quantity == 0)
		{
			//check if at maxitems
			if(this.get_u8("itemsnum") >= MaxItems){
				//print("at maxitems "+this.get_u8("itemsnum"));
				return;
			}
			//
			//string[]@ itemsArray;
			//if(this.get("itemsArray", @itemsArray))
			
			//itemsArray.insertLast(blob.getName());
			string[] @GitemsArray;
			this.get("GitemsArray",@GitemsArray);
			GitemsArray.push_back(blob.getName());
			this.add_u8("itemsnum",1);
			//print("smartStorageAdd array:" + join(GitemsArray,"."));
			this.set_string("itemsArray", join(GitemsArray,"."));
			this.Sync("itemsArray", true);
			this.Sync("itemsnum", true);
			//+1 is used as offset as 0 means disabled
			this.set_u32("SS_"+blobName,blobQuantity+1);
			//this.set("GitemsArray",@GitemsArray);
			//this.Sync("GitemsArray", true);
		
		}
		else{
			//increase storage of item by blobQuantity
			this.add_u32("SS_"+blobName,blobQuantity);
			
		}
		this.Sync("SS_"+blobName, true);
		blob.Tag("dead");
		blob.server_Die();
	}
	
	if (isClient()){
		//this.Sync("SS_"+blobName, true);
		//this.Sync("itemsArray", true);
		//this.Sync("itemsnum", true);
		this.getSprite().PlaySound("bridge_open.ogg");	
		}
	
	
	
}

void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu @gridmenu)
{
	//print("SS onCreateInventoryMenu");
	if (forBlob !is null)
	{
		//string[]@ tokens = text_in.split(" ");
		//u8 listLength = factionStorageMats.length;
		//string[] @GitemsArray;
		//this.get("GitemsArray",@GitemsArray);
		//print("GitemsArray("+GitemsArray.length()+"): " + join(GitemsArray,"."));
		
		u8 itemslength = this.get_u8("itemsnum");
		//print("SS itemslength" + itemslength);
		if( itemslength == 0) return;
		u8 inv_posx = this.getInventory().getInventorySlots().x;
		u8 scale = itemslength/inv_posx;
		Vec2f pos(gridmenu.getUpperLeftPosition().x + 0.5f * (gridmenu.getLowerRightPosition().x - gridmenu.getUpperLeftPosition().x),// - 156.0f,
              gridmenu.getUpperLeftPosition().y - 72 - (24 * scale));
		CGridMenu@ menu = CreateGridMenu(pos, this, Vec2f(inv_posx, 1 + scale), "\n(Secondary Storage)\nItems: (" + itemslength + " / " + MaxItems + ")");
		if (menu !is null)
		{
			
			menu.deleteAfterClick = false;
			u32 cur_quantity;
			//string[]@ itemsArray;
			//if(this.get("itemsArray", @itemsArray))
			string getitemarray = this.get_string("itemsArray");
			//print("SS menu "+getitemarray);
			string[]@ itemsArray = getitemarray.split(".");
			if(itemsArray.length() > 0)
			{
				//print("SS got itemsArray " + itemsArray.length());
				for (u8 i = 0; i < itemsArray.length(); i++)
				{
					string blobName = itemsArray[i];
					cur_quantity = this.get_u32("SS_"+blobName);
					CBitStream params;
					params.write_u16(forBlob.getNetworkID());
					params.write_string(blobName);
					
					/*if (blobName.findFirst("ammo") != -1)
					{
						CGridButton @but = menu.AddButton("$"+blobName.replace("mat" , "icon")+"$", "\nResource Total:\n("+cur_quantity+")", this.getCommandID("sv_withdraw"), params);
					}else
					*/
					//print("ss)"+i+":"+itemsArray[i]);
					if (cur_quantity > 1)
					{
						cur_quantity--;
						CGridButton @but = menu.AddButton("$"+blobName+"$", "\n "+blobName+":\n("+cur_quantity+")", this.getCommandID("sv_withdraw"), params);
					}
					else if (cur_quantity == 1)
					{
						CGridButton @but = menu.AddButton("$"+blobName+"$", "\nRemove " + blobName, this.getCommandID("sv_delete"), params);
					}
					
				}
			}
		}
	}
}

void onDie(CBlob@ this)
{
	if (isServer() )
	{
		u32 cur_quantity;
		//string[]@ itemsArray;
		//if(this.get("itemsArray", @itemsArray))
		//{
			string[] @GitemsArray;
			this.get("GitemsArray",@GitemsArray);	
			for (u8 i = 0; i < GitemsArray.length(); i++)
			{
				cur_quantity = this.get_u32("SS_"+GitemsArray[i]);
				if (cur_quantity > 1)
				{
					cur_quantity--; //remove offset
					CBlob@ blob = server_CreateBlob(GitemsArray[i], -1, this.getPosition());
					if (blob !is null)
					{
						u32 quantity = Maths::Min(cur_quantity, blob.getMaxQuantity()*4);
						blob.server_SetQuantity(quantity);
					}
				}
			}
		//}
	}
}
