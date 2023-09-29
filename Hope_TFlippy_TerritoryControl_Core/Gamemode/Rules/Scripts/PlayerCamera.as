
// set camera on local player
// this just sets the target, specific camera vars are usually set in StandardControls.as

#define CLIENT_ONLY

#include "Spectator.as"

int deathTime = 0;
Vec2f deathLock;
int helptime = 0;
bool spectatorTeam;

void Reset(CRules@ this)
{
	SetTargetPlayer(null);
	CCamera@ camera = getCamera();
	if (camera !is null)
	{
		camera.setTarget(null);
		// start fairly unzoomed, so we have a nice zoom-in effect
		camera.targetDistance = 0.25f;
	}

	currentTarget = 0;
	switchTarget = 0;

	//initially position camera to view entire map
	ViewEntireMap();
	// force lock camera position immediately, even if not cinematic
	posActual = posTarget;

	panEaseModifier = 1.0f;
	zoomEaseModifier = 1.0f;
	zoomTarget = 1.0f;
}

void ViewEntireMap()
{
	CMap@ map = getMap();

	if (map !is null)
	{
		Vec2f mapDim = map.getMapDimensions();
		posTarget = mapDim / 2.0f;
		zoomTarget = 1.0f;
	}
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	helptime = 0;
	Reset(this);
}

void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	CCamera@ camera = getCamera();
	if (camera !is null && player !is null && player is getLocalPlayer())
	{
		posActual = blob.getPosition();
		camera.setPosition(posActual);
		camera.setTarget(blob);
		camera.mousecamstyle = 1; //follow
	}
}

//change to spectator cam on team change
void onPlayerChangedTeam(CRules@ this, CPlayer@ player, u8 oldteam, u8 newteam)
{
	CCamera@ camera = getCamera();
	CBlob@ playerBlob = player is null ? player.getBlob() : null;

	if (camera !is null && newteam == this.getSpectatorTeamNum() && getLocalPlayer() is player)
	{
		resetHelpText();
		spectatorTeam = true;
		camera.setTarget(null);
		if (playerBlob !is null)
		{
			playerBlob.ClearButtons();
			playerBlob.ClearMenus();

			posActual = playerBlob.getPosition();
			camera.setPosition(posActual);
			deathTime = getGameTime();
		}
	}
	else if (getLocalPlayer() is player)
	{
		spectatorTeam = false;
	}
}

void resetHelpText()
{
	helptime = getGameTime();
}

//Change to spectator cam on death
void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	CCamera@ camera = getCamera();
	CBlob@ victimBlob = victim !is null ? victim.getBlob() : null;
	CBlob@ attackerBlob = attacker !is null ? attacker.getBlob() : null;

	//Player died to someone
	if (camera !is null && victim is getLocalPlayer())
	{
		// let's only bother with the info pane on switching to spec
		// resetHelpText();

		//Player killed themselves
		if (victim is attacker || attacker is null)
		{
			camera.setTarget(null);
			if (victimBlob !is null)
			{
				victimBlob.ClearButtons();
				victimBlob.ClearMenus();
				deathLock = victimBlob.getPosition();
			}
		}
		else
		{
			if (victimBlob !is null)
			{
				victimBlob.ClearButtons();
				victimBlob.ClearMenus();
			}

			if (attackerBlob !is null)
			{
				SetTargetPlayer(attackerBlob.getPlayer());
				deathLock = victimBlob.getPosition();
			}
			else
			{
				camera.setTarget(null);
			}
		}

		deathTime = getGameTime() + 1 * getTicksASecond();
	}
}

void SpecCamera(CRules@ this)
{
	//death effect
	CCamera@ camera = getCamera();
	if (camera !is null && getLocalPlayerBlob() is null && getLocalPlayer() !is null)
	{
		const int diffTime = deathTime - getGameTime();
		// death effect
		if (!spectatorTeam && diffTime > 0)
		{
			//lock camera
			posActual = deathLock;
			camera.setPosition(deathLock);
			//zoom in for a bit
			const float zoom_target = 1.0f;
			const float zoom_speed = 5.0f;
			camera.targetDistance = Maths::Min(zoom_target, camera.targetDistance + zoom_speed * getRenderDeltaTime());
		}
		else
		{
			Spectator(this);
		}
	}
}

void onRender(CRules@ this)
{
	if (!v_capped)
	{
		SpecCamera(this);
	}

	if (targetPlayer() !is null && getLocalPlayerBlob() is null)
	{
		GUI::SetFont("menu");
		GUI::DrawText(
			getTranslatedString("Following {CHARACTERNAME} ({USERNAME})")
			.replace("{CHARACTERNAME}", targetPlayer().getCharacterName())
			.replace("{USERNAME}", targetPlayer().getUsername()),
			Vec2f(getScreenWidth() / 2 - 90, getScreenHeight() * (0.2f)),
			Vec2f(getScreenWidth() / 2 + 90, getScreenHeight() * (0.2f) + 30),
			SColor(0xffffffff), true, true
		);
	}

	if (getLocalPlayerBlob() !is null)
	{
		return;
	}
}

void onTick(CRules@ this)
{
	if (v_capped)
	{
		SpecCamera(this);
	}
}
