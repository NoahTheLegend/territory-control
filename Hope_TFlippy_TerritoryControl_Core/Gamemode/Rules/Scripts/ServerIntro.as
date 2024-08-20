int time = 0;

void onInit( CRules@ this )
{
	time = 0;
}

void onRender( CRules@ this )
{
	CPlayer@ player = getLocalPlayer();
	if (player is null || player.get_bool("no_dashboard")) return;
	
	CBlob@ local = player.getBlob();
	if (local !is null && local.getName() != "peasant")
	{
		return;
	}

	time++;
    const int endTime1 = getTicksASecond() * 20;
	const int endTime2 = getTicksASecond() * 70;

	bool draw = false;
	Vec2f ul, lr;
	string text = "";

	ul = Vec2f( 30, 3*getScreenHeight()/4 );

    if (time < endTime1) {
        text = "Welcome to [Territory Control: A New Hope]\n\n" +
		"This is a modded version of the official Territory Control.";
        
		Vec2f size;
		GUI::GetTextDimensions(text, size);
		lr = ul + size;
		draw = true;
    }
	else if (time < endTime2) {
		text =  "Mod Rules:\n\n"+
				" - Don't block neutral spawn, only wood or stone can be used but the player should be allowed to leave it.\n\n"+
				" - Faction grief is bannable, but also you are responsible for who you are letting in.\n\n"+
				" - Don't intentionally lag the server.\n\n"+
				" - Players genocide and enslavement is permitted.\n\n"+
				"For more information about server, press TAB and check the links.";
		Vec2f size;
		GUI::GetTextDimensions(text, size);
		lr = ul + size;
		lr.y -= 32.0f;
		draw = true;
	}

	if(draw)
	{
		f32 wave = Maths::Sin(getGameTime() / 10.0f) * 2.0f;
		ul.y += wave;
		lr.y += wave;
		GUI::DrawButtonPressed( ul - Vec2f(10,10), lr + Vec2f(10,10) );
		GUI::DrawText( text, ul, SColor(0xffffffff) );
	}
}