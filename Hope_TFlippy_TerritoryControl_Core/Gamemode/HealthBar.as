// draws a health bar on mouse hover


void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 1.5f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;
	if (mouseOnBlob)
	{
		//VV right here VV
		Vec2f pos2d = blob.getInterpolatedScreenPos() + Vec2f(0, blob.getHeight()+20);
		Vec2f dim = Vec2f(24, 8);
		
		const f32 zoom = getCamera().targetDistance * getDriver().getResolutionScaleFactor();
		const f32 y = blob.getHeight() * zoom;
		const f32 initialHealth = blob.getInitialHealth();
		const f32 blobHealth = blob.getHealth();
		bool chicken = false;
		if (blob.hasTag("chicken") || blob.hasTag("chicken_turret") || blob.getTeamNum() == 250) chicken = true;
		//bool mecha = false;
		//if (!blob.hasTag("flesh")) mecha = true;
		Vec2f blobpos = (Vec2f(pos2d.x-dim.x,pos2d.y+y)+Vec2f(pos2d.x+dim.x,pos2d.y+y+dim.y))*0.5f;
		bool tutorial = false;
		if (u_showtutorial) tutorial = true;
		
		f32 offset_y_overheal = 12;
		if (u_showtutorial)
		{
			dim = Vec2f(44, 16);
			offset_y_overheal = 20;
		}
		
		if (initialHealth > 0.0f)
		{
			f32 ratio = blob.getHealth() / initialHealth;
			f32 ratio_clamped = Maths::Min(ratio, 1);
		
			if (ratio_clamped >= 0.0f)
			{
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x - 2, pos2d.y + y - 2), Vec2f(pos2d.x + dim.x + 2, pos2d.y + y + dim.y + 2));
				GUI::DrawRectangle(Vec2f(pos2d.x - dim.x + 2, pos2d.y + y + 2), Vec2f(pos2d.x - dim.x + ratio_clamped * 2.0f * dim.x - 2, pos2d.y + y + dim.y - 2), (chicken ? SColor(0xff11301d) : SColor(0xffac1512)));
				//(chicken ? SColor(0xff649b0d) : (mecha ? SColor(0xff877b5c) : SColor(0xffac1512)))
				if (tutorial) GUI::DrawTextCentered(formatFloat((blobHealth <= initialHealth ? blobHealth : initialHealth)*2.0f,'0',3,1)+" Hearts", blobpos+Vec2f(0.0f, 2.0f), SColor(0xffffffff));
			}
			
			if (blobHealth > initialHealth && !blob.hasTag("dead"))
			{
				f32 overheal = blobHealth - initialHealth;
				f32 ratio_overheal = overheal / initialHealth;
				f32 heart_lenght = dim.x/initialHealth*overheal;
				f32 final_overheal_lenght = Maths::Min(Maths::Max((heart_lenght * ratio_overheal), (tutorial ? 16 : 8)), 640);
				
				GUI::DrawRectangle(Vec2f(pos2d.x - final_overheal_lenght - 2, pos2d.y + y - 2 + offset_y_overheal),
					Vec2f(pos2d.x + final_overheal_lenght + 2, pos2d.y + y + dim.y + 2 + offset_y_overheal));
				GUI::DrawRectangle(Vec2f(pos2d.x - final_overheal_lenght + 2, pos2d.y + y + 2 + offset_y_overheal),
					Vec2f(pos2d.x + final_overheal_lenght - 2, pos2d.y + y + dim.y - 2 + offset_y_overheal), SColor(0xfffbb818));
				
				if (tutorial) GUI::DrawTextCentered("+ " + formatFloat(overheal*2.0f,'0',3,1), blobpos+Vec2f(0.0f, 2.0f + offset_y_overheal), SColor(0xffffffff));
				// GUI::DrawRectangle(Vec2f(pos2d.x - (overheal * 12) - 4, pos2d.y + y - 2 + offset_y_overheal), Vec2f(pos2d.x + (overheal * 12) + 4, pos2d.y + y + dim.y + 2 + offset_y_overheal));
				// GUI::DrawRectangle(Vec2f(pos2d.x - (overheal * 12), pos2d.y + y + 2 + offset_y_overheal), Vec2f(pos2d.x + (overheal * 12), pos2d.y + y + dim.y - 2 + offset_y_overheal), SColor(0xfffbb818));
			}
		}
	}
}