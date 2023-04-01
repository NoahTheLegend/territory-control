void onInit(CBlob@ this)
{
	this.Tag("furniture");
	this.Tag("heavy weight");

	this.addCommandID("rest");
	AddIconToken("$rest$", "InteractionIcons.png", Vec2f(32, 32), 29);
	
	this.set_f32("pickup_priority", 8.00f);
}

void onInit(CSprite@ this)
{
	CSpriteLayer@ zzz = this.addSpriteLayer("zzz", "Quarters.png", 8, 8);
	if (zzz !is null)
	{
		{
			zzz.addAnimation("default", 15, true);
			int[] frames = {96, 97, 98, 98, 99};
			zzz.animation.AddFrames(frames);
		}
		zzz.SetOffset(this.isFacingLeft() ? -Vec2f(-8, 9) : Vec2f(-2, -9));
		if (this.isFacingLeft()) zzz.SetFacingLeft(true);
		zzz.SetLighting(false);
		zzz.SetVisible(false);
		zzz.SetRelativeZ(-5.0f);
	}

	CSpriteLayer@ backpack = this.addSpriteLayer("backpack", "Quarters.png", 16, 16);
	if (backpack !is null)
	{
		{
			backpack.addAnimation("default", 0, false);
			int[] frames = {26};
			backpack.animation.AddFrames(frames);
		}
		backpack.SetOffset(this.isFacingLeft() ? -Vec2f(16, -1) : Vec2f(-16, 1));
		backpack.SetVisible(false);
		if (this.isFacingLeft()) backpack.SetFacingLeft(false);
			else backpack.SetFacingLeft(true);
		backpack.SetRelativeZ(45.0f);
	}

	this.SetEmitSound("MigrantSleep.ogg");
	this.SetEmitSoundPaused(true);
	this.SetEmitSoundVolume(0.5f);
}

void onTick(CBlob@ this)
{
	if (isServer())
	{
		if(getGameTime()%30==0)
			this.server_Heal(1.0f);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	// TODO: fix GetButtonsFor Overlapping, when detached this.isOverlapping(caller) returns false until you leave collision box and re-enter
	Vec2f tl, br, c_tl, c_br;
	this.getShape().getBoundingRect(tl, br);
	caller.getShape().getBoundingRect(c_tl, c_br);
	bool isOverlapping = br.x - c_tl.x > 0.0f && br.y - c_tl.y > 0.0f && tl.x - c_br.x < 0.0f && tl.y - c_br.y < 0.0f;
	if (this.isAttached()) return;
	if(!isOverlapping || !bedAvailable(this) || !requiresTreatment(caller))
	{
		this.set_Vec2f("shop offset", Vec2f_zero);
	}
	else
	{
		this.set_Vec2f("shop offset", Vec2f(6, 0));
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		caller.CreateGenericButton("$rest$", Vec2f(-6, 0), this, this.getCommandID("rest"), "Rest", params);
	}
	this.set_bool("shop available", isOverlapping);
}

bool requiresTreatment(CBlob@ caller)
{
	return true;
}

bool bedAvailable(CBlob@ this)
{
	AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
	if (bed !is null)
	{
		CBlob@ patient = bed.getOccupied();
		if (patient !is null)
		{
			return false;
		}
	}
	return true;
}

const string default_head_path = "Entities/Characters/Sprites/Heads.png";

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	if (this.isAttached()) return;
	AttachmentPoint@ b = this.getAttachments().getAttachmentPointByName("BED");
	AttachmentPoint@ p = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (isServer() && this.isAttached() && b !is null && b.getOccupied() !is null) this.server_DetachAll();

	attached.getShape().getConsts().collidable = false;
	attached.SetFacingLeft(true);
	attached.AddScript("WakeOnHit.as");

	string texName = default_head_path;
	CSprite@ attached_sprite = attached.getSprite();
	if (attached_sprite !is null && isClient())
	{
		attached_sprite.SetVisible(false);
		attached_sprite.PlaySound("GetInVehicle.ogg");
		CSpriteLayer@ head = attached_sprite.getSpriteLayer("head");
		if (head !is null)
		{
			texName = head.getFilename();
		}
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		updateLayer(sprite, "bed", 1, true, false);
		updateLayer(sprite, "zzz", 0, true, false);
		updateLayer(sprite, "backpack", 0, true, false);

		sprite.SetEmitSoundPaused(false);
		sprite.RewindEmitSound();

		if (isClient())
		{
			CSpriteLayer@ bed_head = sprite.addSpriteLayer("bed head", texName, 16, 16, attached.getTeamNum(), attached.getSkinNum());
			if (bed_head !is null)
			{
				Animation@ anim = bed_head.addAnimation("default", 0, false);

				anim.AddFrame(2);

				// if (texName == default_head_path)
				// {
					// // anim.AddFrame(getHeadFrame(attached, attached.getHeadNum()) + 2);
				// }
				// else
				// {
					// anim.AddFrame(2);
				// }

				bed_head.SetAnimation(anim);
				bed_head.SetFacingLeft(true);
				bed_head.RotateBy(this.isFacingLeft() ? -80 : 80, Vec2f_zero);
				bed_head.SetRelativeZ(2);
				bed_head.SetOffset(this.isFacingLeft() ? -Vec2f(-8, 3) : Vec2f(8, -3));
				if (this.isFacingLeft()) bed_head.SetFacingLeft(false);
				bed_head.SetVisible(true);
			}
		}
	}
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	detached.getShape().getConsts().collidable = true;
	detached.AddForce(Vec2f(0, -20));
	detached.RemoveScript("WakeOnHit.as");

	CSprite@ detached_sprite = detached.getSprite();
	if (detached_sprite !is null)
	{
		detached_sprite.SetVisible(true);
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		updateLayer(sprite, "bed", 0, true, false);
		updateLayer(sprite, "zzz", 0, false, false);
		updateLayer(sprite, "bed head", 0, false, true);
		updateLayer(sprite, "backpack", 0, false, false);

		sprite.SetEmitSoundPaused(true);
	}
}

void updateLayer(CSprite@ sprite, string name, int index, bool visible, bool remove)
{
	if (sprite !is null)
	{
		CSpriteLayer@ layer = sprite.getSpriteLayer(name);
		if (layer !is null)
		{
			if (remove == true)
			{
				sprite.RemoveSpriteLayer(name);
				return;
			}
			else
			{
				layer.SetFrameIndex(index);
				layer.SetVisible(visible);
			}
		}
	}
}

bool canBePickedUp( CBlob@ this, CBlob@ byBlob )
{
    return this.getAttachments().getAttachmentPointByName("BED").getOccupied() is null;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	const bool is_server = (isServer());

	if (cmd == this.getCommandID("rest"))
	{
		if (this.isAttached()) return;
		u16 caller_id;
		if (!params.saferead_netid(caller_id))
			return;

		CBlob@ caller = getBlobByNetworkID(caller_id);
		if (caller !is null)
		{
			AttachmentPoint@ bed = this.getAttachments().getAttachmentPointByName("BED");
			if (bed !is null && bedAvailable(this))
			{
				caller.SetVisible(false);
				CBlob@ carried = caller.getCarriedBlob();
				if (is_server)
				{
					if (carried !is null)
					{
						if (!caller.server_PutInInventory(carried))
						{
							carried.server_DetachFrom(caller);
						}
					}
					this.server_AttachTo(caller, "BED");
				}
			}
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob !is null && blob.hasTag("player")) return false;
	return true;
}