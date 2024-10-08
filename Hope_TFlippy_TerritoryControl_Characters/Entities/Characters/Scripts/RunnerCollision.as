// character was placed in crate

void onThisAddToInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	this.doTickScripts = true; // run scripts while in crate
	this.getMovement().server_SetActive(true);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	// when dead, collide only if its moving and some time has passed after death
	if (this.hasTag("dead"))
	{
        CShape@ oShape = blob.getShape();
		bool slow = (this.getShape().vellen < 1.5f);
        //static && collidable should be doors/platform etc             fast vel + static and !player = other entities for a little bit (land on the top of ballistas).
		return (oShape.isStatic() && oShape.getConsts().collidable) || (!slow && oShape.isStatic() && !blob.hasTag("player"));
	}
	else // collide only if not a player or other team member, or crouching
	{
		if (this.hasTag("seated"))
		{
			return false;
		}

		if (blob.hasTag("woodengate"))
		{
			return blob.isCollidable() || blob.getShape().getConsts().collidable;
		}

		if (this.hasTag("no_flesh_collision"))
		{
			if (blob.hasTag("flesh") || blob.hasTag("player") || blob.hasTag("combat chicken")) return false;
		}

		//other team member
		if (blob.hasTag("player") && (this.getTeamNum()==blob.getTeamNum() && (this.getTeamNum()>=0 && this.getTeamNum()<7)))
		{
			//knight shield up logic

			//we're a platform if they aren't pressing down
			bool thisplatform = this.hasTag("shieldplatform") &&
			                    !blob.isKeyPressed(key_down);

			if (thisplatform || blob.getName() == "knight")
			{
				Vec2f pos = this.getPosition();
				Vec2f bpos = blob.getPosition();

				const f32 size = 9.0f;

				if (thisplatform)
				{
					if (bpos.y < pos.y - size && thisplatform)
					{
						return true;
					}
				}

				if (bpos.y > pos.y + size && blob.hasTag("shieldplatform"))
				{
					return true;
				}
			}

			return false;
		}

		if (blob.hasTag("migrant"))
		{
			return false;
		}

		const bool still = (this.getShape().vellen < 0.01f);

		if (this.isKeyPressed(key_down) &&
		        this.isOnGround() && still)
		{
			CShape@ s = blob.getShape();
			if (s !is null && !s.isStatic() &&
			        !blob.hasTag("ignore crouch"))
			{
				return false;
			}
		}

	}

	return true;
}