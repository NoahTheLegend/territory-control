#include "Hitters.as";
#include "HittersTC.as";
#include "Explosion.as";
#include "MakeDustParticle.as";

void onInit(CBlob@ this)
{
	this.set_u32("rotationgun1", 15);
	this.set_u32("rotationgun2", 15);

	this.set_u32("ammo", 0);
	this.set_u32("maxammo", 256);

	this.addCommandID("load_ammo");

	CSprite@ sprite = this.getSprite();

	this.Tag("usable by anyone");

	this.getShape().SetRotationsAllowed(false);
	this.Tag("allow guns");

	AttachmentPoint@ pilot = this.getAttachments().getAttachmentPointByName("PILOT");
	if (pilot !is null)
	{
		pilot.SetKeysToTake(key_left | key_right | key_up | key_down);
		pilot.offset = pilot_offset;
	}
	CBlob@ pilotseat = pilot.getOccupied();
	if (pilotseat !is null) 
	{
		pilotseat.set_u32("timer", 0);
		pilotseat.set_u32("row", 0);
	}

	AttachmentPoint@ gunner1 = this.getAttachments().getAttachmentPointByName("GUNNER1");
	if (gunner1 !is null)
	{
		gunner1.SetKeysToTake(key_up | key_down | key_action1);
	}	

	AttachmentPoint@ gunner2 = this.getAttachments().getAttachmentPointByName("GUNNER2");
	if (gunner2 !is null)
	{
		gunner2.SetKeysToTake(key_up | key_down | key_action1);
	}
	CBlob@ gunnerblob1 = gunner1.getOccupied();
	CBlob@ gunnerblob2 = gunner2.getOccupied();
	if (gunnerblob1 !is null) gunnerblob1.set_u32("timer", 0);
	if (gunnerblob2 !is null) gunnerblob2.set_u32("timer", 0);

	CSpriteLayer@ gun1 = sprite.addSpriteLayer("gun1", "gunner1.png", 36, 7);
	if (gun1 !is null)
	{
		gun1.SetOffset(Vec2f(42, -52));
		gun1.SetRelativeZ(-5.0f);
	}

	CSpriteLayer@ gun2 = sprite.addSpriteLayer("gun2", "gunner2.png", 64, -10);
	if (gun2 !is null)
	{
		gun2.RotateBy(180, Vec2f());
		gun2.SetOffset(Vec2f(44, -10));
		gun2.SetRelativeZ(-5.0f);
	}

/*	this.getShape().SetOffset(Vec2f(0, 4)); // platform on mech body, idk how to make it collidable and keep mech not collidable for blobs

	{
		Vec2f offset(-10, -110);

		Vec2f[] shape =
		{
			Vec2f(0.0f, 0.0f) - offset,
			Vec2f(80.0f, 0.0f) - offset,
			Vec2f(80.0f, 20.0f) - offset,
			Vec2f(0.0f, 14.5f) - offset
		};
		this.getShape().AddShape(shape);
	}*/

	sprite.SetEmitSound("Mech_Loop.ogg");
	sprite.SetEmitSoundVolume(0.50f);
	sprite.SetEmitSoundPaused(false);
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return forBlob.getTeamNum() == this.getTeamNum();
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	CBitStream params;
	CBlob@ carried = caller.getCarriedBlob();
	if (carried !is null && this.get_u32("ammo") < this.get_u32("maxammo"))
	{
		string ammo_name = carried.getName();
		bool isValid = ammo_name == "mat_atcockstammo";
		if (isValid)
		{
			CButton@ button1 = caller.CreateGenericButton("$" + ammo_name + "$", Vec2f(-10.0f, 0), this, this.getCommandID("load_ammo"), "Load " + carried.getInventoryName() + "\n(" + this.get_u32("ammo") + " / " + this.get_u32("maxammo") + ")", params);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("load_ammo"))
	{
		CMap@ map = this.getMap();
		CBlob@[] shell;
		map.getBlobsInRadius(this.getPosition(), 15.0f, shell);

		for (int i = 0; i < shell.length; i++)
		{
			if (shell[i] !is null && shell[i].isAttached() && shell[i].getName() == "mat_atcockstammo")
			{
				shell[i].server_Die();
				int add = shell[i].getQuantity();

				u32 ammo = this.get_u32("ammo");
				u32 maxammo = this.get_u32("maxammo");
				u32 diff = maxammo - ammo;

				this.set_u32("ammo", this.get_u32("ammo") + add);

				shell[i].Tag("dead");
				shell[i].server_Die();
			}
		}
	}
}

void onAttach(CBlob@ this,CBlob@ attached,AttachmentPoint @attachedPoint)
{
	attached.Tag("invincible");
	attached.Tag("invincibilityByVehicle");
}

void onDetach(CBlob@ this,CBlob@ detached,AttachmentPoint@ attachedPoint)
{
	detached.Untag("invincible");
	detached.Untag("invincibilityByVehicle");
}

const Vec2f pilot_offset = Vec2f(3, -1);

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	Vec2f vel = blob.getVelocity();
	
	f32 vellen = Maths::Min(vel.x * 0.40f, 1.00f);

	AttachmentPoint@ pilot = blob.getAttachments().getAttachmentPointByName("PILOT");
	if (pilot !is null)
	{
		Vec2f jitter = Vec2f((XORRandom(100) - 50) * 0.010f, (XORRandom(100) - 50) * 0.010f);
		pilot.offset = jitter + pilot_offset;
		// pilot.SetMouseTaken(true);
	}
}

void getCurrentAmmo(CBlob@ this, u32 ammo, u32 maxammo)
{
	if (this is null || getDriver() is null) return;
	AttachmentPoint@ gun1 = this.getAttachments().getAttachmentPointByName("GUNNER1");
	AttachmentPoint@ gun2 = this.getAttachments().getAttachmentPointByName("GUNNER2");

	if (gun1 is null || gun2 is null) return;

	if (gun1.getOccupied() !is null) gun1.getOccupied().set_u32("ammo", this.get_u32("ammo"));
	if (gun2.getOccupied() !is null) gun2.getOccupied().set_u32("ammo", this.get_u32("ammo"));

	Vec2f pos = getDriver().getScreenPosFromWorldPos(Vec2f(this.getPosition().x, this.getPosition().y-5)+Vec2f(-24.0, 12.0f));
	GUI::SetFont("menu");
	GUI::DrawText("Ammo left: " + ammo + " / " + maxammo, pos, color_white);
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob !is null) 
	{
		AttachmentPoint@ gun1 = blob.getAttachments().getAttachmentPointByName("GUNNER1");
		AttachmentPoint@ gun2 = blob.getAttachments().getAttachmentPointByName("GUNNER2");

		getCurrentAmmo(gun1.getOccupied(), blob.get_u32("ammo"), blob.get_u32("maxammo"));
		getCurrentAmmo(gun2.getOccupied(), blob.get_u32("ammo"), blob.get_u32("maxammo"));
	}
}

void onTick(CBlob@ this)
{
	if (this.get_u32("rotationgun1") > 100) this.set_u32("rotationgun1", 15);
	if (this.get_u32("rotationgun2") > 100) this.set_u32("rotationgun2", 15);

	AttachmentPoint@ seat = this.getAttachments().getAttachmentPointByName("PILOT");
	AttachmentPoint@ gun1 = this.getAttachments().getAttachmentPointByName("GUNNER1");
	AttachmentPoint@ gun2 = this.getAttachments().getAttachmentPointByName("GUNNER2");

	if (seat !is null)
	{
		CBlob@ pilot = seat.getOccupied();
		if (pilot !is null)
		{
			if (pilot.get_u32("timer") > 0) pilot.set_u32("timer", pilot.get_u32("timer") - 1);

			const bool left = seat.isKeyPressed(key_left);
			const bool right = seat.isKeyPressed(key_right);
			const bool up = seat.isKeyPressed(key_up);
			const bool bar = seat.isKeyPressed(key_down);

			if (left && this.isOnGround()) this.AddForce(Vec2f(-65.0f, 0.0f));
				else this.AddForce(Vec2f(-20.0f, 0.0f));
			if (right && this.isOnGround()) this.AddForce(Vec2f(65.0f, 0.0f));
				else this.AddForce(Vec2f(20.0f, 0.0f));
			if (up && this.isOnGround()) this.AddForce(Vec2f(0.0f, -800.0f));

			if (left || this.hasTag("left"))
			{
				if (!this.hasTag("left") && !right)
				{
					CSprite@ sprite = this.getSprite();
					sprite.RemoveSpriteLayer("gun1");
					CSpriteLayer@ sgun1 = sprite.addSpriteLayer("gun1", "gunner1.png", 36, 7);
					if (gun1 !is null)
					{
						sgun1.SetOffset(Vec2f(42, -52));
						sgun1.SetRelativeZ(-5.0f);
					}
					sprite.RemoveSpriteLayer("gun2");
					CSpriteLayer@ sgun2 = sprite.addSpriteLayer("gun2", "gunner2.png", 64, -10);
					if (gun2 !is null)
					{
						sgun2.RotateBy(180, Vec2f());
						sgun2.SetOffset(Vec2f(44, -10));
						sgun2.SetRelativeZ(-5.0f);
					}
					
					this.set_u32("rotationgun1", 15);
					this.set_u32("rotationgun2", 15);
				}

				this.SetFacingLeft(false);
				this.Tag("left");
				this.Untag("right");
			}
			if (right || this.hasTag("right"))
			{
				if (!this.hasTag("right") && !left)
				{
					CSprite@ sprite = this.getSprite();
					sprite.RemoveSpriteLayer("gun1");
					CSpriteLayer@ sgun1 = sprite.addSpriteLayer("gun1", "gunner1.png", 36, 7);
					if (gun1 !is null)
					{
						sgun1.SetOffset(Vec2f(42, -52));
						sgun1.SetRelativeZ(-5.0f);
					}
					sprite.RemoveSpriteLayer("gun2");
					CSpriteLayer@ sgun2 = sprite.addSpriteLayer("gun2", "gunner2.png", 64, -10);
					if (gun2 !is null)
					{
						sgun2.SetOffset(Vec2f(44, -10));
						sgun2.SetRelativeZ(-5.0f);
					}
					this.set_u32("rotationgun1", 15);
					this.set_u32("rotationgun2", 15);
				}

				this.SetFacingLeft(true);
				this.Tag("right");
				this.Untag("left");
			}

			pilot.getSprite().SetEmitSound("FlamethrowerFire.ogg");
			if (!bar) pilot.getSprite().SetEmitSoundPaused(true);

			if (bar && pilot.get_u32("timer") == 0)
			{
				pilot.set_u32("timer", 3);

				if (pilot.get_u32("row") != 2) pilot.set_u32("row", pilot.get_u32("row") + 1);
				else pilot.set_u32("row", 0);

				CInventory@ inv = this.getInventory();
				CBlob@ blob = this.getInventoryBlob();
				if (inv is null) return;
				u32 itemCount = inv.getItemsCount();

				if (itemCount > 0) 
				{
					if (isServer()) 
					{
						for (int i = 0; i < 65; i++)
						{
							if (inv.getItem(i) is null) continue;
							if (inv.getItem(i).getName() != "mat_oil") continue;
							if (inv.getItem(i).getName() == "mat_oil" && inv.getItem(i).getQuantity() > 0)
							{
								CBlob@ item = inv.getItem(i);
								u32 quantity = item.getQuantity();
								CBlob@ oil;

								if (bar) pilot.getSprite().SetEmitSoundPaused(false);

								Vec2f pos;
								Vec2f force;

								switch (pilot.get_u32("row"))
								{
									case 0:
									if (!this.isFacingLeft()) 
									{
										pos = Vec2f(30.0f, -10.0f);
										force = Vec2f(350.0f, -350.0f);
									}
									else
									{
										pos = Vec2f(-30.0f, -10.0f);
										force = Vec2f(-350.0f, -350.0f);
									}
									break;
									case 1:
									if (!this.isFacingLeft()) 
									{
										pos = Vec2f(24.0f, 8.0f);
										force = Vec2f(350.0f, -350.0f);
									}
									else
									{
										pos = Vec2f(-24.0f, 8.0f);
										force = Vec2f(-350.0f, -350.0f);
									}
									break;
									case 2:
									if (!this.isFacingLeft()) 
									{
										pos = Vec2f(24.0f, 24.0f);
										force = Vec2f(350.0f, -350.0f);
									}
									else
									{
										pos = Vec2f(-24.0f, 24.0f);
										force = Vec2f(-350.0f, -350.0f);
									}
									break;
								}

								CBlob@ dropped = server_CreateBlob("flame", this.getTeamNum(), this.getPosition() + pos);
								dropped.server_SetQuantity(1);
								dropped.AddForce(force);
								dropped.Tag("invisiblebomb");
								dropped.SetVisible(false);

								if (quantity > 0)
								{
									item.server_SetQuantity(quantity - 1);
								}
								if (item.getQuantity() == 0) 
								{
									item.server_Die();
								}
								break;
							}
						}
					}
				}
			}
			
			CBlob@[] bombs;
			getBlobsByTag("invisiblebomb", bombs);
			for (int i = 0; i < bombs.length; i++)
			{
				CBlob@ bomb = bombs[i];
				if (bomb is null) continue;
				if (bomb.getTickSinceCreated() > 4)
				{
					bomb.Untag("invisiblebomb");
					bomb.SetVisible(true);
				}
			}
			this.setAimPos(pilot.getAimPos());
		}
	}

	if (gun1 !is null)
	{
		bool facingleft = this.isFacingLeft();

		CBlob@ gunner1 = gun1.getOccupied();
		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ cannon = sprite.getSpriteLayer("gun1");

		if (gunner1 !is null)
		{
			if (gunner1 is null || gunner1.getControls() is null) return;

			if (gunner1.get_u32("timer") > 0) gunner1.set_u32("timer", gunner1.get_u32("timer") - 1);

			bool up;
			bool down;
			bool action = gun1.isKeyPressed(key_action1);

			if (!facingleft)
			{
				up = gun1.isKeyPressed(key_up);
				down = gun1.isKeyPressed(key_down);
			}
			else
			{
				down = gun1.isKeyPressed(key_up);
				up = gun1.isKeyPressed(key_down);
			}

			u32 rotation = this.get_u32("rotationgun1");

			if (up && rotation < 29)
			{
				cannon.RotateBy(2, Vec2f());
				this.set_u32("rotationgun1", rotation + 1);
			}
			else if (down && rotation > 1) 
			{
				cannon.RotateBy(-2, Vec2f());
				this.set_u32("rotationgun1", rotation - 1);
			}

			if (isServer()) 
			{
				if (gunner1.get_u32("timer") == 85) this.set_u32("ammo", this.get_u32("ammo") - 1);
				this.Sync("ammo", true);
			}
			
			if (action && gunner1.get_u32("timer") == 0 && this.get_u32("ammo") > 0)
			{	
				if (isServer())
				{
					if (!this.isFacingLeft()) //== facing left, sprite is mirrored
					{
						CBlob@ shell = server_CreateBlob("atcockstammo", this.getTeamNum(), gun1.getPosition() + Vec2f(-10.0f, -7.0f));
						shell.getSprite().RotateBy(2 * (rotation - 13), Vec2f());
						shell.AddForce(Vec2f(-200.0f, (-rotation + 15) * -5.5 * -1.0f));
						shell.getSprite().SetRelativeZ(-6.0f);
						shell.Tag("invisibleshell");
						shell.SetVisible(false);
						
						gunner1.set_u32("timer", 90);
						Sound::Play("kegexplosion.ogg", gun1.getPosition(), 10.0f);
						ParticleAnimated("Explosion.png", gun1.getPosition() + Vec2f(-38.0f, -5.0f + ((-rotation + 20) * 1.0f)), Vec2f(0,0), 0.0f, 1.0f, 1.5, -0.1f, false);
					}
					else
					{
						CBlob@ shell = server_CreateBlob("atcockstammo", this.getTeamNum(), gun1.getPosition() + Vec2f(10.0f, -7.0f));
						shell.getSprite().RotateBy(-(2 * (rotation - 13)), Vec2f());
						shell.AddForce(Vec2f(200.0f, -((-rotation + 15) * -5.5 * -1.0f)));
						shell.getSprite().SetRelativeZ(-6.0f);
						shell.Tag("invisibleshell");
						shell.SetVisible(false);
						
						gunner1.set_u32("timer", 90);
						Sound::Play("kegexplosion.ogg", gun1.getPosition(), 10.0f);
						ParticleAnimated("Explosion.png", gun1.getPosition() + Vec2f(38.0f, -5.0f + ((-rotation + 20) * 1.0f)), Vec2f(0,0), 0.0f, 1.0f, 1.5, -0.1f, false);
					}
				}
			}
		}
		CBlob@[] shells;
		getBlobsByTag("invisibleshell", shells);
		for (int i = 0; i < shells.length; i++)
		{
			if (shells[i] is null) continue;
			if (shells[i].getTickSinceCreated() > 1) shells[i].SetVisible(true);
		}	
	}

	if (gun2 !is null)
	{
		bool facingleft = this.isFacingLeft();

		CBlob@ gunner2 = gun2.getOccupied();
		CSprite@ sprite = this.getSprite();
		CSpriteLayer@ lowercannon = sprite.getSpriteLayer("gun2");

		if (gunner2 !is null)
		{
			if (gunner2 is null || gunner2.getControls() is null) return;

			if (gunner2.get_u32("timer") > 0) gunner2.set_u32("timer", gunner2.get_u32("timer") - 1);

			bool up;
			bool down;
			bool action = gun2.isKeyPressed(key_action1);

			if (!facingleft)
			{
				up = gun2.isKeyPressed(key_up);
				down = gun2.isKeyPressed(key_down);
			}
			else
			{
				down = gun2.isKeyPressed(key_up);
				up = gun2.isKeyPressed(key_down);
			}

			u32 rotation = this.get_u32("rotationgun2");

			if (up && rotation < 29)
			{
				lowercannon.RotateBy(2, Vec2f());
				this.set_u32("rotationgun2", rotation + 1);
			}
			else if (down && rotation > 1) 
			{
				lowercannon.RotateBy(-2, Vec2f());
				this.set_u32("rotationgun2", rotation - 1);
			}

			if (isServer()) 
			{
				if (gunner2.get_u32("timer") == 145) this.set_u32("ammo", this.get_u32("ammo") - 2);
				this.Sync("ammo", true);
			}

			if (action && gunner2.get_u32("timer") == 0 && this.get_u32("ammo") > 0)
			{	
				if (isServer())
				{
					if (!this.isFacingLeft()) //== facing left, sprite is mirrored
					{
						for (int i = 0; i < 3; i++)
						{
							CBlob@ shell = server_CreateBlob("atcockstammo", this.getTeamNum(), gun2.getPosition() + Vec2f(-10.0f, -7.0f));
							shell.getSprite().RotateBy(2 * (rotation - 13), Vec2f());
							shell.AddForce(Vec2f(-175.0f, (-rotation + 15) * -5.5 * -1.0f));
							shell.getSprite().SetRelativeZ(-6.0f);
							shell.Tag("invisibleshell");
							shell.SetVisible(false);
						}
						gunner2.set_u32("timer", 150);
						if (isClient())
						{
							this.getSprite().PlaySound("KegExplosion.ogg", 5.0f);
							MakeDustParticle(gun2.getPosition() + Vec2f(-50.0f, -5.0f + ((-rotation + 20) * 1.0f)), "Explosion.png");
						}
					}
					else
					{
						for (int i = 0; i < 3; i++)
						{
							CBlob@ shell = server_CreateBlob("atcockstammo", this.getTeamNum(), gun2.getPosition() + Vec2f(10.0f, -7.0f));
							shell.getSprite().RotateBy(-(2 * (rotation - 13)), Vec2f());
							shell.AddForce(Vec2f(175.0f, ((-rotation + 15) * -5.5 * 1.0f)));
							shell.getSprite().SetRelativeZ(-6.0f);
							shell.Tag("invisibleshell");
							shell.SetVisible(false);
						}
						gunner2.set_u32("timer", 150);
						if (isClient())
						{
							this.getSprite().PlaySound("KegExplosion.ogg", 5.0f);
							MakeDustParticle(gun2.getPosition() + Vec2f(50.0f, -5.0f + ((-rotation + 10) * -1.0f)), "Explosion.png");
						}
					}
				}
			}
		}
		CBlob@[] shells;
		getBlobsByTag("invisibleshell", shells);
		for (int i = 0; i < shells.length; i++)
		{
			if (shells[i] is null) continue;
			if (shells[i].getTickSinceCreated() > 1) shells[i].SetVisible(true);
		}	
	}
}

void onDie(CBlob@ this)
{
	this.getSprite().Gib();
	this.getSprite().PlaySound("KegExplosion.ogg", 5.0f);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return false;
}