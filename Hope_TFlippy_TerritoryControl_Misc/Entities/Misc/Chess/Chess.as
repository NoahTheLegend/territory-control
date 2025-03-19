// README
// secondary seat (black) has fixed facepos of attachment point, after including this file in a mod, you should
// perform changes to Seats.as using "seat turn around" tag to avoid hard setting occupied facepos
// made by NoahTheLegend

namespace Chess
{
	enum PieceType
	{
		EMPTY = 0,
		PAWN = 1,
		BISHOP = 2,
		KNIGHT = 3,
		ROOK = 4,
		QUEEN = 5,
		KING = 6
	}
}

string[] piece_names = {"empty", "pawn", "bishop", "knight", "rook", "queen", "king"};

const u8 sync_delay = 30;
void onInit(CBlob@ this)
{
	// "signal" commands to communicate between server and client 
	this.addCommandID("sync");
	this.addCommandID("reset");
	this.addCommandID("sync_log");
	this.server_setTeamNum(255);

	// first initialize, if we're client send a request for individual sync
	ResetBoard(this);
    RequestSync(this);

	// misc tags
	this.Tag("builder always hit");
	this.Tag("heavy weight");
	this.Tag("seat turn around");
	
	// init props
	this.set_u8("selected_white", 64 - 4);
	this.set_u8("selected_black", 4);
	this.set_s8("captured_white", -1);
	this.set_s8("captured_black", -1);
	this.set_bool("reset_white", false); // both of players should send the command
	this.set_bool("reset_black", false);
	this.set_u32("sync_time", 0);
	this.set_u16("sync_pid", 0);
	this.set_string("last_player_attached_0", "none");
	this.set_string("last_player_attached_1", "none");

	if (isClient()) this.set_f32("tilesize", 24.0f * getCamera().targetDistance); // getCamera() doesnt exist serverside
	this.getSprite().SetRelativeZ(-50);

	AttachmentPoint@ ap0 = this.getAttachments().getAttachmentPointByName("PLAYER0");
	AttachmentPoint@ ap1 = this.getAttachments().getAttachmentPointByName("PLAYER1");

	if (ap0 is null || ap1 is null) return;

	// capture input
	ap0.SetKeysToTake(key_left | key_right | key_up | key_down | key_action1 | key_action2);
	ap1.SetKeysToTake(key_left | key_right | key_up | key_down | key_action1 | key_action2);

	// initialize log props
	ResetGameLog(this);
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;
}

void onTick(CBlob@ this)
{
	u8 sw = this.get_u8("selected_white");
	s8 cw = this.get_s8("captured_white");
	u8 sb = this.get_u8("selected_black");
	s8 cb = this.get_s8("captured_black");
	
	// visuals
	if (this.isAttached())
	{
		this.setAngleDegrees(this.isFacingLeft() ? 90 : -90);
	}

	AttachmentPoint@ ap0 = this.getAttachments().getAttachmentPointByName("PLAYER0");
	AttachmentPoint@ ap1 = this.getAttachments().getAttachmentPointByName("PLAYER1");

	if (ap0 is null || ap1 is null) return;

	Table@ table;
	if (!this.get("Table", @table)) return;

	CBlob@ p0 = ap0.getOccupied();
	CBlob@ p1 = ap1.getOccupied();

	bool localhost = isServer() && isClient();

	// white controls
	if (p0 !is null)
	{
		bool my_p0 = p0.isMyPlayer();
		if (my_p0)
		{
			CControls@ controls = getControls();
			if (controls.isKeyJustPressed(KEY_END))
			{
				CBitStream params;
				params.write_s8(0);
				this.SendCommand(this.getCommandID("reset"), params);
			}
		}
		
		// not yet ended the match
		if (!table.end)
		{
			u16 p0_id = p0.getNetworkID();
			u16 cplayer_id = p0.getPlayer() is null ? 0 : p0.getPlayer().getNetworkID();

			if (ap0.isKeyJustPressed(key_left) && sw % 8 != 0) sw -= 1;
			if (ap0.isKeyJustPressed(key_right) && sw % 8 != 7) sw += 1;
			if (ap0.isKeyJustPressed(key_up) && Maths::Floor(sw/8) != 0) sw -= 8;
			if (ap0.isKeyJustPressed(key_down) && Maths::Floor(sw/8) != 7) sw += 8;

			if (ap0.isKeyJustPressed(key_action1) && (localhost || table.turn_white)) 
			{
				Board@ target = @table.board_pieces[sw%8][Maths::Floor(sw/8)];
				bool not_null = target !is null;
				bool not_empty = not_null && target.type != Chess::EMPTY;

				if (cw != -1 && not_null && target.color != 0)
				{
					if (target.move_to(cw, sw, false, cplayer_id))
					{
						if (isServer())
						{
							cw = -1;
							Sync(this);
						}
					}

				}
				else if (cw == -1 && not_empty && target.color == 0)
				{
					if (isServer())
					{
						cw = sw;
						Sync(this, false, p0_id);
					}
					if (isClient() && my_p0)
					{
						this.getSprite().PlaySound("board_select.ogg", 0.25f, 1.1f+getRandomPitch());
					}
				}
			}
			else if (ap0.isKeyJustPressed(key_action2))
			{
				if (isClient() && cw != -1 && my_p0)
				{
					this.getSprite().PlaySound("board_fail_select.ogg", 0.25f, 1.0f+getRandomPitch());
				}
				if (isServer())
				{
					cw = -1;
					Sync(this, false, p0_id);
				}
			}
		}
	}

	// black controls
	if (p1 !is null)
	{
		bool my_p1 = p1.isMyPlayer();
		if (my_p1)
		{
			CControls@ controls = getControls();
			if (controls.isKeyJustPressed(KEY_END))
			{
				CBitStream params;
				params.write_s8(1);
				this.SendCommand(this.getCommandID("reset"), params);
			}
		}

		if (!table.end)
		{
			u16 p1_id = p1.getNetworkID();
			u16 cplayer_id = p1.getPlayer() is null ? 0 : p1.getPlayer().getNetworkID();

			if (ap1.isKeyJustPressed(key_right) && sb % 8 != 0) sb -= 1;
			if (ap1.isKeyJustPressed(key_left) && sb % 8 != 7) sb += 1;
			if (ap1.isKeyJustPressed(key_down) && Maths::Floor(sb/8) != 0) sb -= 8;
			if (ap1.isKeyJustPressed(key_up) && Maths::Floor(sb/8) != 7) sb += 8;

			if (ap1.isKeyJustPressed(key_action1) && (localhost || !table.turn_white))
			{
				Board@ target = @table.board_pieces[sb%8][Maths::Floor(sb/8)];
				bool not_null = target !is null;
				bool not_empty = not_null && target.type != Chess::EMPTY;

				if (cb != -1 && not_null && target.color != 1)
				{
					if (target.move_to(cb, sb, false, cplayer_id))
					{
						if (isServer())
						{
							cb = -1;
							Sync(this);
						}
					}

				}
				else if (cb == -1 && not_empty && target.color == 1)
				{
					if (isServer())
					{
						cb = sb;
						Sync(this, false, p1_id);
					}
					if (isClient() && my_p1)
					{
						this.getSprite().PlaySound("board_select.ogg", 0.25f, 1.1f+getRandomPitch());
					}
				}
			}
			else if (ap1.isKeyJustPressed(key_action2))
			{
				if (isClient() && cb != -1 && my_p1)
				{
					this.getSprite().PlaySound("board_fail_select.ogg", 0.25f, 1.0f+getRandomPitch());
				}
				if (isServer())
				{
					cb = -1;
					Sync(this, false, p1_id);
				}
			}
		}
	}

	if (isServer())
	{
		// the delay for sync (hack, read TODO)
		if (this.get_u32("sync_time") >= getGameTime())
		{
			SendSyncFromServer(this);

			this.set_u32("sync_time", 0);
			this.set_u16("sync_pid", 0);
		}

		this.set_u8("selected_white", sw);
		this.Sync("selected_white", true);
		this.set_s8("captured_white", cw);
		this.Sync("captured_white", true);
		this.set_u8("selected_black", sb);
		this.Sync("selected_black", true);
		this.set_s8("captured_black", cb);
		this.Sync("captured_black", true);
	}
}

const SColor col_white = SColor(215,255,255,255);
const SColor col_black = SColor(215,15,15,15);
const SColor col_selection = SColor(140,255,255,0);
const SColor col_selection_disabled = col_enemy;
const SColor col_captured = SColor(140,55,55,255);
const SColor col_enemy = SColor(140,255,0,0);
const SColor col_path = SColor(140,0,255,0);
const SColor col_recent_from = SColor(215,155,155,255);
const SColor col_recent_to = SColor(215,225,135,135);
const SColor col_check = SColor(215,255,0,0);
const string[] cols = {"A","B","C","D","E","F","G","H"};

f32 old_factor = 0;
void onRender(CSprite@ sprite)
{
	CBlob@ this = sprite.getBlob();
	if (this is null) return;

	// zoom transition
	f32 zoom = getCamera().targetDistance;
	f32 tilesize = Maths::Lerp(this.get_f32("tilesize"), 24.0f * zoom, 0.2f);
	this.set_f32("tilesize", tilesize);

	Table@ table;
	if (!this.get("Table", @table)) return;
	
	Driver@ driver = getDriver();
	Vec2f thispos = this.getPosition();

	Vec2f offset = Vec2f(0, -24.0f);
	f32 area = tilesize * 8;

	// position on screen
	Vec2f pos2d = driver.getScreenPosFromWorldPos(Vec2f_lerp(this.getOldPosition() + offset, thispos + offset, getInterpolationFactor()));	
	CBlob@ local = getLocalPlayerBlob();

	AttachmentPoint@ ap0 = this.getAttachments().getAttachmentPointByName("PLAYER0");
	AttachmentPoint@ ap1 = this.getAttachments().getAttachmentPointByName("PLAYER1");

	if (ap0 is null || ap1 is null) return;
	CBlob@ p0 = ap0.getOccupied();
	CBlob@ p1 = ap1.getOccupied();

	bool my_p0 = p0 !is null && p0.isMyPlayer();
	bool my_p1 = p1 !is null && p1.isMyPlayer();

	// defining canvas area
	Vec2f tl = pos2d - Vec2f(area/2, area);
	Vec2f br = pos2d + Vec2f(area/2, 0);
	f32 factor = tilesize/24.0f*0.5f;

	// disable visual render
	bool rendering = local !is null;
	if (local !is null && !local.isAttachedTo(this))
	{
		Vec2f mpos = driver.getWorldPosFromScreenPos(getControls().getInterpMouseScreenPos());
		if ((mpos-thispos).Length() > this.getRadius()+4.0f) rendering = false;
	}

	if (rendering)
	{
		// fancy borders
		Vec2f frameoffset = Vec2f(4,4);
		GUI::DrawFramedPane(tl-frameoffset+Vec2f(0,frameoffset.y), tl+Vec2f(0,area)); // left
		GUI::DrawFramedPane(tl-frameoffset-Vec2f(frameoffset.x, 0), tl+Vec2f(area+frameoffset.x*2, 0)); // top
		GUI::DrawFramedPane(br-Vec2f(area+frameoffset.x*2, 0), br+frameoffset+Vec2f(frameoffset.x,0)); // bottom
		GUI::DrawFramedPane(br-Vec2f(0, area), br+frameoffset-Vec2f(0,frameoffset.y)); // right

		// rows
		GUI::SetFont("menu");

		if (my_p1)
		{
			for (u8 i = 0; i < 8; i++)
			{
				f32 row_offset = (area/8)*(8-i);
				GUI::DrawTextCentered(""+(8-i), tl+Vec2f(-16, row_offset - (area/8)/2 - 1.5f), SColor(225,255,255,255));
			}

			// cols
			for (u8 i = 0; i < 8; i++)
			{
				f32 col_offset = (area/8)*i;
				GUI::DrawTextCentered(cols[7-i], tl+Vec2f(col_offset + (area/8)/2 - 3.0f, area + 16 - 4.0f), SColor(225,255,255,255));
			}
		}
		else
		{
			for (u8 i = 0; i < 8; i++)
			{
				f32 row_offset = (area/8)*(i+1);
				GUI::DrawTextCentered(""+(i+1), tl+Vec2f(-16, area - row_offset + (area/8)/2 - 1.5f), SColor(225,255,255,255));
			}

			// cols
			for (u8 i = 0; i < 8; i++)
			{
				f32 col_offset = (area/8)*i;
				GUI::DrawTextCentered(cols[i], tl+Vec2f(col_offset + (area/8)/2 - 3.0f, area + 16 - 4.0f), SColor(225,255,255,255));
			}
		}

		bool turn_white = table.turn_white;
		bool turn_black = !table.turn_white;
		s8 recent_enemy_move_from = -1;
		s8 recent_enemy_move_to = -1;

		// movement history + mark recent enemy move
		string[]@ chess_player;
		u32[] game_from;
		u32[] game_to;
		s32[] taken_pieces;
		if (this.get("chess_player", @chess_player) && this.get("game_from", game_from) && this.get("game_to", game_to)
			&& chess_player.size() == game_from.size() && chess_player.size() == game_to.size()
			&& this.get("taken_pieces", taken_pieces) && chess_player.size() == taken_pieces.size())
		{
			int size = chess_player.size();
			int s = Maths::Min(size, 8);
			int start_index = Maths::Max(0, size - 8); 

			for (s8 i = 0; i < s; i++)
			{
			    int actual_index = Maths::Max(0, start_index + i);
			    f32 row_offset = (area / 8) * (s - i);

			    s8 from_x = game_from[actual_index] % 8;
			    s8 from_y = 8 - Maths::Floor(game_from[actual_index] / 8);

			    s8 to_x = game_to[actual_index] % 8;
			    s8 to_y = 8 - Maths::Floor(game_to[actual_index] / 8);

				if (i == s-1)
				{
					recent_enemy_move_from = game_from[actual_index];
					recent_enemy_move_to = game_to[actual_index];
				}

			    string[] spl = chess_player[actual_index].split("_");
			    string text = spl[0]+": " + cols[from_x] + from_y + " - " + cols[to_x] + to_y;
				if (taken_pieces[actual_index] > 0) text += " (captured "+piece_names[taken_pieces[actual_index]]+")";
				
			    GUI::DrawText(text, tl + Vec2f(area + 16, row_offset - (area / 8) + 1.5f), SColor(225, 255, 255, 255));
			}
		}

		if (table.end)
			GUI::DrawTextCentered((table.turn_white ? "Black" : "White") + " team won. Press [END] key to restart.", tl + Vec2f(area/2, -20), SColor(255, 255, 255, 255));
		else
			GUI::DrawTextCentered(my_p0 && turn_white ? "Your turn" : my_p1 && turn_black ? "Your turn" : "Enemy's turn", tl + Vec2f(area/2, -20), SColor(255, 255, 255, 255));

		// F1 help menu
		bool reset = my_p0 ? this.get_bool("reset_white") : my_p1 ? this.get_bool("reset_black") : false;
		if ((reset || u_showtutorial) && (my_p0 || my_p1))
		{
			GUI::DrawTextCentered(reset ? "Waiting for opponent to reset the game..."
				: "Press [END] key to reset the game\n     (Both players should press)", tl + Vec2f(area/2, area+128.0f), SColor(100,255,255,255));

			if (u_showtutorial) GUI::DrawTextCentered("WASD - movement, LMB - select / place, RMB - unselect", tl + Vec2f(area/2, area+152.0f), SColor(100,255,255,255));
		}

		bool draw_path = false; // green tiles

		u8 sw = this.get_u8("selected_white");
		s8 cw = this.get_s8("captured_white");

		u8 sb = this.get_u8("selected_black");
		u8 cb = this.get_s8("captured_black");

		u8 check_index = table.check_index;

		// draw tiles
		for (u8 i = 0; i < 64; i++)
		{
			u8 x = i % 8;
			u8 y = Maths::Floor(i / 8);

			SColor col = (y % 2 == 0 ? i % 2 : (i + 1) % 2) == 0 ? col_white : col_black;
			Board@ p = @table.board_pieces[x][y];
			bool not_empty = p !is null && p.type != Chess::EMPTY;

			if (my_p0)
			{
				bool selected = x == sw % 8 && y == Maths::Floor(sw / 8);
				bool captured = x == cw % 8 && y == Maths::Floor(cw / 8) && not_empty;

				if (selected)
				{
					col = table.turn_white ? col_selection : col_selection_disabled;
				}
				if (captured)
				{
					col = col_captured;
					draw_path = true;
				}
			}

			if (my_p1)
			{
				bool selected = x == sb % 8 && y == Maths::Floor(sb / 8);
				bool captured = x == cb % 8 && y == Maths::Floor(cb / 8) && not_empty;

				if (selected)
				{
					col = !table.turn_white ? col_selection : col_selection_disabled;
				}
				if (captured)
				{
					col = col_captured;
					draw_path = true;
				}
			}

			if ((i == recent_enemy_move_from || i == recent_enemy_move_to)
				&& ((!my_p0 && !my_p1) || (my_p0 && turn_white) || (my_p1 && turn_black)))
			{
				col = i == recent_enemy_move_from ? col_recent_from : col_recent_to;
			}

			Vec2f tile_offset = Vec2f(f32(x) * tilesize, f32(y) * tilesize) + tl;
			if (my_p1) // Mirror the board for black player
			{
				tile_offset = Vec2f(f32(7 - x) * tilesize, f32(7 - y) * tilesize) + tl;
			}
			GUI::DrawRectangle(tile_offset, tile_offset + Vec2f(tilesize, tilesize), col);
		}

		// draw check
		if (check_index != 255 && check_index != (my_p0 ? cw : cb))
		{
			u8 x = check_index % 8;
			u8 y = Maths::Floor(check_index / 8);

			Vec2f tile_offset = Vec2f(f32(x) * tilesize, f32(y) * tilesize) + tl;
			if (my_p1) // Mirror the board for black player
			{
				tile_offset = Vec2f(f32(7 - x) * tilesize, f32(7 - y) * tilesize) + tl;
			}
			GUI::DrawRectangle(tile_offset, tile_offset + Vec2f(tilesize, tilesize), col_check);
		}

		// draw selection & captured
		if (draw_path && (my_p0 || my_p1))
		{
			u8 s = my_p0 ? sw : sb;
			u8 c = my_p0 ? cw : cb;

			u8 x = c % 8;
			u8 y = Maths::Floor(c / 8);

			Board@ p = @table.board_pieces[x][y];
			bool not_empty = p !is null && p.type != Chess::EMPTY;

			s8[] enemy_tiles;
			s8[] move_tiles = p.get_move_tiles(c, p.color, enemy_tiles);

			for (u8 j = 0; j < move_tiles.size(); j++)
			{
				s8 tile = move_tiles[j];
				if (tile == s) continue;

				Vec2f special_tile_offset = Vec2f(f32(tile % 8) * tilesize, f32(Maths::Floor(tile / 8)) * tilesize) + tl;
				if (my_p1) // Mirror the board for black player
				{
					special_tile_offset = Vec2f(f32(7 - (tile % 8)) * tilesize, f32(7 - Maths::Floor(tile / 8)) * tilesize) + tl;
				}
				GUI::DrawRectangle(special_tile_offset, special_tile_offset + Vec2f(tilesize, tilesize), col_path);
			}

			for (u8 j = 0; j < enemy_tiles.size(); j++)
			{
				s8 tile = enemy_tiles[j];
				if (tile == s) continue;

				Vec2f special_tile_offset = Vec2f(f32(tile % 8) * tilesize, f32(Maths::Floor(tile / 8)) * tilesize) + tl;
				if (my_p1) // Mirror the board for black player
				{
					special_tile_offset = Vec2f(f32(7 - (tile % 8)) * tilesize, f32(7 - Maths::Floor(tile / 8)) * tilesize) + tl;
				}
				GUI::DrawRectangle(special_tile_offset, special_tile_offset + Vec2f(tilesize, tilesize), col_enemy);
			}
		}
	}

	f32 lerp = this.isAttached() ? 0.66f : 0.33f;
	f32 rdt_factor = 60.0f * getRenderExactDeltaTime();
	lerp *= rdt_factor;

	if (this.hasTag("team1_rotate_immediately"))
	{
		lerp = 1;
		this.Untag("team1_rotate_immediately");
	}

	// draw icons
	for (u8 i = 0; i < 64; i++)
	{
		u8 x = i % 8;
		u8 y = Maths::Floor(i / 8);

		Board@ p = @table.board_pieces[x][y];
		bool not_empty = p !is null && p.type != Chess::EMPTY;

		Vec2f tile_offset = Vec2f(f32(x) * tilesize, f32(y) * tilesize) + tl;
		if (my_p1) // Mirror the board for black player
		{
			tile_offset = Vec2f(f32(7 - x) * tilesize, f32(7 - y) * tilesize) + tl;
		}
		if (not_empty)
		{
			Vec2f pos = driver.getWorldPosFromScreenPos(tile_offset - Vec2f(7, 8) * factor);
			if (p.icon_pos == Vec2f_zero) p.icon_pos = pos;

			p.icon_pos = Vec2f_lerp(p.icon_pos, pos, lerp);
			if (rendering) p.render_icon(factor);
		}
	}

	old_factor = factor;
}

class Table
{
	u16 id; // CBlob id
	bool can_castle_white;
	bool can_castle_black;
	u8 castling_rook_moved_white;
	u8 castling_rook_moved_black;
	bool turn_white;
	u8 check_index;
	array<array<Board@>> board_pieces();
	bool end;
	u8 last_turn_from;
	u8 last_turn_to;
	s8 last_piece_taken;

	Table()
	{
		id = 0;
		can_castle_white = true;
		can_castle_black = true;
		castling_rook_moved_white = 0;
		castling_rook_moved_black = 0;
		turn_white = true;
		check_index = 255;
		board_pieces = array<array<Board@>>(8, array<Board@>(8, MakePieceOnBoard(@this, 0, -1)));
		end = false;
		last_turn_from = 255;
		last_turn_to = 255;
		s8 last_piece_taken = -1;
	}

	Board@[][] get_board()
	{
		return this.board_pieces;
	}

	void set_board(Board@[][] board)
	{
		this.board_pieces = board;
	}
}

Board@ MakePieceOnBoard(Table@ table, u8 type, s8 color) // piece factory
{
	switch(type)
	{
		case 1: return cast<Board@>(@pawn(table, color));
		case 2: return cast<Board@>(@bishop(table, color));
		case 3: return cast<Board@>(@knight(table, color));
		case 4: return cast<Board@>(@rook(table, color));
		case 5: return cast<Board@>(@queen(table, color));
		case 6: return cast<Board@>(@king(table, color));
	}

	return @Board(table, type, color);
}

const Vec2f up = Vec2f(0, -1); 
const Vec2f right = Vec2f(1, 0);
const Vec2f down = Vec2f(0, 1);
const Vec2f left = Vec2f(-1, 0);

class Board // breaks solid, but who cares
{
	Table@ table;
	u8 type; s8 color; 				// Board, team
	Vec2f icon_pos;					// pos on screen

	Board()
	{
		icon_pos = Vec2f_zero;
		type = 0; color = -1;
	}

	Board(Table@ _table, s8 _type, s8 _color)
	{
		Board();
		@table = @_table;
		type = _type;
		color = _color;
	}

	void render_icon(f32 factor)
	{
		GUI::DrawIcon("ChessPieces.png", type-1+color*6, Vec2f(32,32), getDriver().getScreenPosFromWorldPos(icon_pos), factor);
	}

	Board@[][] get_board()
	{
		return table.get_board();
	}

	void set_board(Board@[][] board)
	{
		table.set_board(board);
	}

	// returns true if dest is out of 8x8 board area (with intepreting 1d array to 2d)
	bool is_out_of_bounds(s8 pos, Vec2f dest)
	{
	    s8 x = pos % 8;
	    s8 y = Maths::Floor(pos / 8);

	    s8 new_x = x + int(dest.x);
	    s8 new_y = y + int(dest.y);

	    if (new_x < 0 || new_x > 7 || new_y < 0 || new_y > 7)
	    {
	        return true;
	    }

	    return false;
	}

	// returns -1 if tile is empty, 0 if tile is ours, and 1 if enemy's
	s8 has_obstacle(s8 pos, s8 team)
	{
		if (pos < 0 || pos >= 64) return -1;
		Board@[][] board_pieces = get_board();
		
		s8 x = pos%8;
		s8 y = Maths::Floor(pos/8);

		Board@ p = @board_pieces[x][y];
		if (p is null || p.type == Chess::EMPTY) return -1;

		return team == p.color ? 0 : 1;
	}

	// returns tiles in one array, iterating directions assigned to pieces
	// ^ additionally separates enemy tiles into another array
	s8[] get_move_tiles(s8 pos, s8 team, s8[] &out enemies, u8 override_type = 0)
	{
		s8[] arr;
		Board@[][] board_pieces = get_board();
		
		s8 x = pos%8;
		s8 y = Maths::Floor(pos/8);

		Board@ p = @board_pieces[x][y];
		if (p is null) return arr;

		u8 type = override_type == Chess::EMPTY ? p.type : override_type;
		bool inf = type == 2 || type == 4 || type == 5;

		bool is_pawn = type == 1;
		bool first_pawn_move = is_pawn && (p.color == 0 ? y == 6 : y == 1);

		if (is_pawn)
		{
			if (team == 0) // white
			{
				// top left enemy check
				{
					if (x != 0)
					{
						bool left_pawn = false;
						Board@ neighbour = @board_pieces[x-1][y];
						if (neighbour !is null && neighbour.type == Chess::PAWN && neighbour.color == 1)
							left_pawn = true;

						if (table.last_turn_to == pos - 1 && table.last_turn_from == pos - 17 && left_pawn) // en passant
							enemies.push_back(pos-9);
					}

					s8 obstacle = has_obstacle(pos - 9, team);
					if (obstacle != -1 && obstacle == 1 && !is_out_of_bounds(pos, Vec2f(up)+left))
						enemies.push_back(pos-9);
					
				}
				// top right enemy check
				{
					if (x != 7)
					{
						bool right_pawn = false;
						Board@ neighbour = @board_pieces[x+1][y];
						if (neighbour !is null && neighbour.type == Chess::PAWN && neighbour.color == 1)
							right_pawn = true;

						if (table.last_turn_to == pos + 1 && table.last_turn_from == pos - 15 && right_pawn) // en passant
							enemies.push_back(pos-7);
					}

					s8 obstacle = has_obstacle(pos - 7, team);
					if (obstacle != -1 && obstacle == 1 && !is_out_of_bounds(pos, Vec2f(up)+right))
						enemies.push_back(pos-7);
				}
			}
			else // black
			{
				// bottom left enemy check (top right for team 1)
				{
					if (x != 0)
					{
						bool left_pawn = false;
						Board@ neighbour = @board_pieces[x-1][y];
						if (neighbour !is null && neighbour.type == Chess::PAWN && neighbour.color == 0)
							left_pawn = true;

						if (table.last_turn_to == pos - 1 && table.last_turn_from == pos + 15 && left_pawn) // en passant
							enemies.push_back(pos+7);
					}
					
					s8 obstacle = has_obstacle(pos + 7, team);
					if (obstacle != -1 && obstacle == 1 && !is_out_of_bounds(pos, Vec2f(down)+left))
						enemies.push_back(pos+7);
				}
				// bottom right enemy check (top left for team 1)
				{
					if (x != 7)
					{
						bool right_pawn = false;
						Board@ neighbour = @board_pieces[x+1][y];
						if (neighbour !is null && neighbour.type == Chess::PAWN && neighbour.color == 0)
							right_pawn = true;

						if (table.last_turn_to == pos + 1 && table.last_turn_from == pos + 17 && right_pawn) // en passant
							enemies.push_back(pos+9);
					}

					s8 obstacle = has_obstacle(pos + 9, team);
					if (obstacle != -1 && obstacle == 1 && !is_out_of_bounds(pos, Vec2f(down)+right))
						enemies.push_back(pos+9);
				}
			}
		}
	
		if (type == 1) // pawn
		{
			for (s8 j = 0; j < (first_pawn_move ? 2 : 1); j++) // tiles in line
			{
				Vec2f dir_vec = team == 0 ? Vec2f(up) * (j + 1) : Vec2f(down) * (j + 1);
				if (is_out_of_bounds(pos, dir_vec)) continue;

				s8 pos_dir = pos + int(dir_vec.x) + int(dir_vec.y) * 8;
				s8 obstacle = has_obstacle(pos_dir, team);

				if (obstacle == 0)
				{
					break;
				}
				else if (obstacle == 1)
				{
					break;
				}

				arr.push_back(pos_dir);
			}
		}
		if (type == 3) // knight
		{
			Vec2f[] knight_dirs = {
				Vec2f(up) + up + left, Vec2f(up) + up + right, Vec2f(right) + right + up, Vec2f(right) + right + down,
				Vec2f(down) + down + right, Vec2f(down) + down + left, Vec2f(left) + left + down, Vec2f(left) + left + up
			};

			for (s8 j = 0; j < knight_dirs.size(); j++)
			{
				Vec2f dir = knight_dirs[j];

				if (is_out_of_bounds(pos, dir)) continue;

				s8 tile = pos + int(dir.x) + int(dir.y) * 8;

				s8 obstacle = has_obstacle(tile, team);
				if (obstacle == 0) continue;
				else if (obstacle == 1)
				{
					enemies.push_back(tile);
					continue;
				}

				arr.push_back(tile);
			}
		}
		if (type == 2 || type == 5 || type == 6) // bishop, queen, king (diagonal)
		{
			Vec2f[] directions = {Vec2f(up) + right, Vec2f(down) + right, Vec2f(down) + left, Vec2f(up) + left};
			for (s8 i = 0; i < directions.size(); i++)
			{
				bool do_break = false;
				for (s8 j = 0; j < (inf ? 8 : 1); j++) // tiles in line
				{
					if (do_break) continue;

					Vec2f dir_vec = directions[i] * (j + 1);
					if (is_out_of_bounds(pos, dir_vec)) continue;

					s8 pos_dir = pos + int(dir_vec.x) + int(dir_vec.y) * 8;
					s8 obstacle = has_obstacle(pos_dir, team);

					if (obstacle == 0)
					{
						do_break = true;
						continue;
					}
					else if (obstacle == 1)
					{
						enemies.push_back(pos_dir);
						do_break = true;
						continue;
					}

					arr.push_back(pos_dir);
				}
			}
		}
		if (type == 4 || type == 5 || type == 6) // rook, queen, king (straight)
		{
			Vec2f[] directions = {up, right, down, left};
			for (s8 i = 0; i < directions.size(); i++)
			{
				bool do_break = false;
				for (s8 j = 0; j < (inf ? 8 : 1); j++) // tiles in line
				{
					if (do_break) continue;

					Vec2f dir_vec = directions[i] * (j + 1);
					if (is_out_of_bounds(pos, dir_vec)) continue;

					s8 pos_dir = pos + int(dir_vec.x) + int(dir_vec.y) * 8;
					s8 obstacle = has_obstacle(pos_dir, team);

					if (obstacle == 0)
					{
						do_break = true;
						continue;
					}
					else if (obstacle == 1)
					{
						enemies.push_back(pos_dir);
						do_break = true;
						continue;
					}
					arr.push_back(pos_dir);
				}
			}
		}
		if (type == 6 && override_type == 0) // king (castling)
		{
			s8 safe_sides = get_safe_castling_sides(pos, team);
			if (safe_sides == -1) return arr;

			if (color == 0 && table.can_castle_white)
			{
				bool can_castle_left = false;
				bool can_castle_right = false;

				bool clear_left = has_obstacle(pos-1, team) == -1 && has_obstacle(pos-2, team) == -1 && has_obstacle(pos-3, team) == -1;
				bool clear_right = has_obstacle(pos+1, team) == -1 && has_obstacle(pos+2, team) == -1;

				s8 safe_sides = get_safe_castling_sides(pos, team);

				if (table.castling_rook_moved_white < 3)
				{
					// none of left & right rooks moved yet
					if (table.castling_rook_moved_white == 0)
					{
						can_castle_left = clear_left && (safe_sides == 0 || safe_sides == 2);
						can_castle_right = clear_right && (safe_sides == 1 || safe_sides == 2);
					}
					// left rook moved
					if (!can_castle_right && table.castling_rook_moved_white == 1)
					{
						can_castle_right = clear_right && (safe_sides == 1 || safe_sides == 2);
					}
					// right rook moved
					if (!can_castle_left && table.castling_rook_moved_white == 2)
					{
						can_castle_left = clear_left && (safe_sides == 0 || safe_sides == 2);
					}
				}

				if (can_castle_left) arr.push_back(pos-2);
				if (can_castle_right) arr.push_back(pos+2);
			}
			else if (color == 1 && table.can_castle_black)
			{
				bool can_castle_left = false;
				bool can_castle_right = false;

				bool clear_left = has_obstacle(pos-1, team) == -1 && has_obstacle(pos-2, team) == -1 && has_obstacle(pos-3, team) == -1;
				bool clear_right = has_obstacle(pos+1, team) == -1 && has_obstacle(pos+2, team) == -1;

				s8 safe_sides = get_safe_castling_sides(pos, team);

				if (table.castling_rook_moved_black < 3)
				{
					// none of left & right rooks moved yet
					if (table.castling_rook_moved_black == 0)
					{
						can_castle_left = clear_left && (safe_sides == 0 || safe_sides == 2);
						can_castle_right = clear_right && (safe_sides == 1 || safe_sides == 2);
					}
					// left rook moved
					if (!can_castle_right && table.castling_rook_moved_black == 1)
					{
						can_castle_right = clear_right && (safe_sides == 1 || safe_sides == 2);
					}
					// right rook moved
					if (!can_castle_left && table.castling_rook_moved_black == 2)
					{
						can_castle_left = clear_left && (safe_sides == 0 || safe_sides == 2);
					}
				}

				if (can_castle_left) arr.push_back(pos-2);
				if (can_castle_right) arr.push_back(pos+2);
			}
		}
	
		return arr;
	}

	// can this tile attack enemy king?
	u8 approximate_check(s8 pos, s8 team)
	{
		if (pos < 0 || pos >= 64) return 255;

		Board@[][] board_pieces = get_board();
		s8 x = pos % 8;
		s8 y = Maths::Floor(pos / 8);

		Board@ p = @board_pieces[x][y];
		if (p is null) return 255;
		
		if (p.type != Chess::KING)
		{
			s8[] enemies;
			s8[] move_tiles = p.get_move_tiles(pos, team, enemies);

			for (u8 i = 0; i < enemies.size(); i++)
			{
				s8 nx = enemies[i] % 8;
				s8 ny = Maths::Floor(enemies[i] / 8);

				Board@ p = @board_pieces[nx][ny];
				if (p is null) continue;

				if (p.type == Chess::KING && p.color != team)
					return enemies[i];
			}
		}
		else return approximate_hit(pos, team) ? pos : 255;

		return 255;
	}

	// can this tile be hit by enemy?
	bool approximate_hit(s8 pos, s8 team)
	{
		if (pos < 0 || pos >= 64) return false;

		Board@[][] board_pieces = get_board();
		s8 x = pos % 8;
		s8 y = Maths::Floor(pos / 8);

		Board@ p = @board_pieces[x][y];
		if (p is null) return false;

		// check if there are enemy bishops, queens at diagonal paths
		s8[] diagonal_dirs;
		p.get_move_tiles(pos, team, diagonal_dirs, 2);

		for (s8 i = 0; i < diagonal_dirs.size(); i++)
		{
			s8 nx = diagonal_dirs[i] % 8;
			s8 ny = Maths::Floor(diagonal_dirs[i] / 8);

			Board@ p = @board_pieces[nx][ny];
			if (p is null) continue;

			if (p.type == Chess::BISHOP || p.type == Chess::QUEEN)
			{
				if (p.color != team)
				{
					return true;
				}
			}
		}

		// check if there are enemy rooks, queens at straight paths
		s8[] straight_dirs;
		p.get_move_tiles(pos, team, straight_dirs, 4);
		
		for (s8 i = 0; i < straight_dirs.size(); i++)
		{
			s8 nx = straight_dirs[i] % 8;
			s8 ny = Maths::Floor(straight_dirs[i] / 8);

			Board@ p = @board_pieces[nx][ny];
			if (p is null) continue;

			if (p.type == Chess::ROOK || p.type == Chess::QUEEN)
			{
				if (p.color != team)
				{
					return true;
				}
			}
		}

		// check if there are enemy knights
		s8[] knight_dirs;
		p.get_move_tiles(pos, team, knight_dirs, 3);

		for (s8 i = 0; i < knight_dirs.size(); i++)
		{
			s8 nx = knight_dirs[i] % 8;
			s8 ny = Maths::Floor(knight_dirs[i] / 8);

			Board@ p = @board_pieces[nx][ny];
			if (p is null) continue;

			if (p.type == Chess::KNIGHT)
			{
				if (p.color != team)
				{
					return true;
				}
			}
		}

		// check if there are enemy pawns
		s8[] pawn_dirs;
		p.get_move_tiles(pos, team, pawn_dirs, 1);

		for (s8 i = 0; i < pawn_dirs.size(); i++)
		{
			s8 nx = pawn_dirs[i] % 8;
			s8 ny = Maths::Floor(pawn_dirs[i] / 8);

			Board@ p = @board_pieces[nx][ny];
			if (p is null) continue;

			if (p.type == Chess::PAWN)
			{
				if (p.color != team)
				{
					return true;
				}
			}
		}

		// check if there is enemy king
		s8[] king_dirs;
		p.get_move_tiles(pos, team, king_dirs, 6);

		for (s8 i = 0; i < king_dirs.size(); i++)
		{
			s8 nx = king_dirs[i] % 8;
			s8 ny = Maths::Floor(king_dirs[i] / 8);

			Board@ p = @board_pieces[nx][ny];
			if (p is null) continue;

			if (p.type == Chess::KING)
			{
				if (p.color != team)
				{
					return true;
				}
			}
		}
		
		return false;
	}

	// returns -1 if no castling, 0 if left, 1 if right and 2 if both
	s8 get_safe_castling_sides(s8 pos, s8 team)
	{
		if (pos == table.check_index) return -1;

		Board@[][] board_pieces = get_board();
		s8 x = pos % 8;
		s8 y = Maths::Floor(pos / 8);

		bool can_castle_left = !approximate_hit(pos - 1, team) && !approximate_hit(pos - 2, team);
		bool can_castle_right = !approximate_hit(pos + 1, team) && !approximate_hit(pos + 2, team);

		if (can_castle_left && can_castle_right) return 2;
		else if (can_castle_left) return 0;
		else if (can_castle_right) return 1;

		return -1;
	}

	// sets the pointer of a Board@ object (chess piece) into another tile and creates an empty tile at old pos
	// ^ returns true if piece was moved
	// ^ bool "force", if set to true, will disable game rules limitations
	bool move_to(s8 pos, s8 dest, bool force = false, const u16 pid = 0)
	{
		Board@[][] board_pieces = get_board();
		
		s8 x = pos%8;
		s8 y = Maths::Floor(pos/8);

		s8 dest_x = dest%8;
		s8 dest_y = Maths::Floor(dest/8);
		
		Board@ on_pos  = @board_pieces[x][y];
		Board@ on_dest = @board_pieces[dest_x][dest_y];

		if (on_pos is null || on_pos.type == Chess::EMPTY)
		{
			error("Tried to move null piece: ["+x+"]["+y+"] - ["+dest_x+"]["+dest_y+"]");
			return false;
		}

		bool localhost = isServer() && isClient();
		if (!localhost && (table.turn_white ? on_pos.color == 1 : on_pos.color == 0))
		{
			return false;
		}

		CBlob@ blob = getBlobByNetworkID(table.id);
		s8[] enemy_tiles;
		s8[] move_tiles = on_pos.get_move_tiles(pos, on_pos.color, enemy_tiles);
		if (!force && enemy_tiles.find(dest) == -1 && move_tiles.find(dest) == -1)
		{
			warn("Tried to move piece to wrong position: ["+x+"]["+y+"] - ["+dest_x+"]["+dest_y+"]");
			return false;
		}

		s8 obstacle = has_obstacle(dest, on_pos.color);
		if (obstacle == 0)
		{
			error("Tried to move piece at friendly occupied tile: ["+x+"]["+y+"] - ["+dest_x+"]["+dest_y+"]");
			return false;
		}

		if (isClient() && blob !is null)
		{
			if (on_dest !is null && on_dest.type != Chess::EMPTY)
				blob.getSprite().PlaySound("board_cap.ogg", 0.33f, 1.0f+getRandomPitch());
			else
				blob.getSprite().PlaySound("board_move.ogg", 0.33f, 1.0f+getRandomPitch());
		}

		// Disable castling if a rook on its initial place is killed
		if (on_dest !is null && on_dest.type == Chess::ROOK)
		{
			if (on_dest.color == 0)
			{
				if (dest_x == 0 && dest_y == 7) table.castling_rook_moved_white |= 0x01;
				if (dest_x == 7 && dest_y == 7) table.castling_rook_moved_white |= 0x02;
			}
			else if (on_dest.color == 1)
			{
				if (dest_x == 0 && dest_y == 0) table.castling_rook_moved_black |= 0x01;
				if (dest_x == 7 && dest_y == 0) table.castling_rook_moved_black |= 0x02;
			}
		}

		table.last_piece_taken = on_dest.type;
		@board_pieces[dest_x][dest_y] = @on_pos;
		@board_pieces[x][y] = MakePieceOnBoard(table, 0, -1);
		
		set_board(board_pieces);
		on_move_tile(pos, dest, !force);
		
		table.check_index = approximate_check(dest, on_pos.color);
		log(blob, pos, dest, pid, on_pos.color);

		if (on_dest.type == Chess::KING) end_game(on_dest.color);
		return true;
	}
	
	void on_move_tile(s8 pos, s8 dest, bool do_end_turn)
	{
		Board@[][] board_pieces = get_board();

		u8 old_x = pos%8;
		u8 old_y = Maths::Floor(dest/8);

		u8 x = dest%8;
		u8 y = Maths::Floor(dest/8);
		
		Board@ p = @board_pieces[x][y];
		if (p is null) return;

		// pawn 
		if (p.type == Chess::PAWN)
		{
			// reached the end, transform into queen
			if ((p.color == 0 ? y == 0 : y == 7))
			{
				Board@ np = MakePieceOnBoard(table, 5, p.color);
				@board_pieces[x][y] = np;

				set_board(board_pieces);
			}
			
			// en passant check to remove enemy pawn
			if (p.color == 0)
			{
				Board@ enemy = @board_pieces[x][y+1];
				if (enemy !is null && enemy.type == Chess::PAWN && enemy.color == 1
					&& table.last_turn_from == dest - 8 && table.last_turn_to == dest + 8)
				{
					@board_pieces[x][y+1] = MakePieceOnBoard(table, 0, -1);
					table.last_piece_taken = Chess::PAWN;
					set_board(board_pieces);
				}
			}
			else if (p.color == 1)
			{
				Board@ enemy = @board_pieces[x][y-1];
				if (enemy !is null && enemy.type == Chess::PAWN && enemy.color == 0
					&& table.last_turn_from == dest + 8 && table.last_turn_to == dest - 8)
				{
					@board_pieces[x][y-1] = MakePieceOnBoard(table, 0, -1);
					table.last_piece_taken = Chess::PAWN;
					set_board(board_pieces);
				}
			}
		}
		else if (p.type == Chess::KING) // castling king
		{
			if (p.color == 0)
			{
				if (table.can_castle_white)
				{
					bool can_move_left = old_x == 4 && x == 2;
					bool can_move_right = old_x == 4 && x == 6;

					if (can_move_left)
					{
						Board@ rook = @table.board_pieces[0][7];
						if (rook !is null && rook.move_to(56, 59, true))
						{}
					}
					if (can_move_right)
					{
						Board@ rook = @table.board_pieces[7][7];
						if (rook !is null && rook.move_to(63, 61, true))
						{}
					}

					CBlob@ blob = getBlobByNetworkID(table.id);
					if (blob !is null) Sync(blob);
				}

				table.can_castle_white = false;
			}
			else
			{
				if (table.can_castle_black)
				{
					bool can_move_left = old_x == 4 && x == 2;
					bool can_move_right = old_x == 4 && x == 6;

					if (can_move_left)
					{
						Board@ rook = @table.board_pieces[0][0];
						if (rook !is null && rook.move_to(0, 3, true))
						{}
					}
					if (can_move_right)
					{
						Board@ rook = @table.board_pieces[7][0];
						if (rook !is null && rook.move_to(7, 5, true))
						{}
					}

					CBlob@ blob = getBlobByNetworkID(table.id);
					if (blob !is null) Sync(blob);
				}

				table.can_castle_black = false;
			}
		}
		else if (p.type == Chess::ROOK) // rook validation, if moved at least once - disable castling at its side
		{
			if (p.color == 0)
			{
				u8 r_id = table.castling_rook_moved_white;
				//printf("r_id old " + r_id);
				r_id |= old_x == 0 && (r_id & 0x01) == 0 ? 0x01 : old_x == 7 && (r_id & 0x02) == 0 ? 0x02 : 0;
				//printf("r_id new " + r_id);
				table.castling_rook_moved_white = r_id;
			}
			else if (p.color == 1)
			{
				u8 r_id = table.castling_rook_moved_black;
				r_id |= old_x == 0 && (r_id & 0x01) == 0 ? 0x01 : old_x == 7 && (r_id & 0x02) == 0 ? 0x02 : 0;
				table.castling_rook_moved_black = r_id;
			}
		}
		
		if (do_end_turn) end_turn(p.color);
		table.last_turn_from = pos;
		table.last_turn_to = dest;
	}

	// another unnecessary hook
	void end_turn(s8 team)
	{
		table.turn_white = !table.turn_white;
	}

	// another unnecessary hook x2
	void end_game(s8 team)
	{
		table.end = true;
		cache(getBlobByNetworkID(table.id));
	}

	// logging for tcpr bot and recent moves history
	void log(CBlob@ blob, s8 pos, s8 dest, s8 pid = 0, const s8 team = -1)
	{
		if (!isServer()) return;

		string[]@ chess_player;
		u32[] game_from;
		u32[] game_to;
		s32[] taken_pieces;
		if (blob !is null && blob.get("chess_player", @chess_player)
			&& blob.get("game_from", game_from) && blob.get("game_to", game_to)
			&& blob.get("taken_pieces", taken_pieces))
		{
			string text = team == 0 ? "White" : team == 1 ? "Black" : "Rules";

			s8 moved_from = Maths::Clamp(pos, 0, 63);
			s8 moved_to = Maths::Clamp(dest, 0, 63);

			chess_player.push_back(text);
			game_from.push_back(moved_from);
			game_to.push_back(moved_to);
			taken_pieces.push_back(table.last_piece_taken);

			blob.set("chess_player", @chess_player);
			blob.set("game_from", game_from);
			blob.set("game_to", game_to);
			blob.set("taken_pieces", taken_pieces);

			CBitStream params;
			params.write_string(text);
			params.write_u8(moved_from);
			params.write_u8(moved_to);
			params.write_s8(table.last_piece_taken);
			blob.SendCommand(blob.getCommandID("sync_log"), params);
		}
	}

	// store the game to cache when match ended and player is attached
	void cache(CBlob@ blob)
	{
		if (!isClient()) return;
		
		CBlob@ local = getLocalPlayerBlob();
		if (local is null) return;
		
		if (blob is null) return;
		if (!local.isAttachedTo(blob)) return;

		const int max_cache = 3;
		int local_time = Time_Local(); // time in seconds

		string year =  "" + Time_Year();
		string month = "" + Time_Month();
		if (month.size() == 1) month = "0" + month;
		string day =   "" + Time_MonthDate();
		if (day.size() == 1) day = "0" + day;

		string parsed_hour =   "" + (local_time / 3600) % 24;
		if (parsed_hour.size() == 1) parsed_hour = "0" + parsed_hour;
		string parsed_minute = "" + (local_time % 3600) / 60;
		if (parsed_minute.size() == 1) parsed_minute = "0" + parsed_minute;
		string parsed_second = "" + local_time % 60;
		if (parsed_second.size() == 1) parsed_second = "0" + parsed_second;
		
		int index = 0;
		string local_date = month + "-" + day + "-" + year + "_" + parsed_hour + "-" + parsed_minute + "-" + parsed_second;
		
		// parse back into int
		int[] dates;
		u8 matches = 0;
		for (u8 i = 0; i < max_cache; i++)
		{
			string match = CFileMatcher("../Cache/"+i+"_chess_2025_").getFirst();
			print("found? "+match);

			string[] split = match.split("_");
			if (split.size() >= 4)
			{
				string date = split[2];
				string[] parsed = date.split("-");
				if (parsed.size() >= 6)
				{
					int year = parseInt(parsed[2]);
					int month = parseInt(parsed[0]);
					int day = parseInt(parsed[1]);
					int hour = parseInt(parsed[3]);
					int minute = parseInt(parsed[4]);
					int second = parseInt(parsed[5]);
					
					int time = (year * 31536000) + (month * 2592000) + (day * 86400) + (hour * 3600) + (minute * 60) + second;
					dates.push_back(time);
					matches++;
				}
			}
		}

		if (matches == max_cache)
		{
			// define the oldest cache to replace
			int temp_time = local_time;
			for (u8 i = 0; i < dates.size(); i++)
			{
				if (dates[i] < temp_time)
				{
					temp_time = dates[i];
					index = i;
				}
			}
		}
		else index = matches;
	
		ConfigFile cfg;
		cfg.loadFile(CFileMatcher(index+"_chess").getFirst());
		string new_cfg_name = index+"_"+"chess"+"_"+local_date;
		
		u32[] game_from;
		u32[] game_to;
		if (blob.get("game_from", game_from) && blob.get("game_to", game_to)
			&& game_from.size() == game_to.size())
		{
			string last_player_attached_0 = blob.get_string("last_player_attached_0");
			string last_player_attached_1 = blob.get_string("last_player_attached_1");

			string[] split_0 = last_player_attached_0.split("/");
			string[] split_1 = last_player_attached_1.split("/");
			
			string username_0 = "none";
			string username_1 = "none";

			if (split_0.size() == 2) username_0 = split_0[1].substr(0, split_0[1].size() - 1);
			if (split_1.size() == 2) username_1 = split_1[1].substr(0, split_1[1].size() - 1);
			
			string text = "";
			for (u8 i = 0; i < game_from.size(); i++)
			{
				s8 from_x = game_from[i] % 8;
			    s8 from_y = 8 - Maths::Floor(game_from[i] / 8);

			    s8 to_x = game_to[i] % 8;
			    s8 to_y = 8 - Maths::Floor(game_to[i] / 8);

				text += cols[from_x] + from_y + "-" + cols[to_x] + to_y + " ";
			}
			
			string full_cfg_name = new_cfg_name + "_" + username_0 + "_vs_" + username_1 + ".cfg";
			cfg.add_string("Match of "+last_player_attached_0 + " versus "+last_player_attached_1+": ", text);
			cfg.saveFile(full_cfg_name);

			print("Saved the match to config: "+full_cfg_name);
		}
		else error("Failed to cache the match moves");
	}
};

class pawn : Board
{
	pawn(Table@ table, s8 color)
	{
		super(table, 1, color);
	}
};

class bishop : Board
{
	bishop(Table@ table, s8 color)
	{
		super(table, 2, color);
	}
};

class knight : Board
{
	knight(Table@ table, s8 color)
	{
		super(table, 3, color);
	}
};

class rook : Board
{
	rook(Table@ table, s8 color)
	{
		super(table, 4, color);
	}
};

class queen : Board
{
	queen(Table@ table, s8 color)
	{
		super(table, 5, color);
	}
};

class king : Board
{
	king(Table@ table, s8 color)
	{
		super(table, 6, color);
	}
};

// sent by client, makes server send a sync specifically for us
void RequestSync(CBlob@ this)
{
	if (!isClient()) return;
	
	CPlayer@ local = getLocalPlayer();
	if (local is null) return;

	CBitStream params;
	params.write_bool(true);
	params.write_u16(local.getNetworkID());
	this.SendCommand(this.getCommandID("sync"), params);
}

// set the sync to a timer
void Sync(CBlob@ this, bool immediate = false, u16 pid = 0)
{
	if (!isServer()) return;

	this.set_u32("sync_time", getGameTime()+(immediate ? 1 : sync_delay));
	this.set_u16("sync_pid", pid);
}

// send the sync
void SendSyncFromServer(CBlob@ this)
{
	if (!isServer()) return;
	u16 pid = this.get_u16("sync_pid");
	
	CPlayer@ p = pid == 0 ? null : getPlayerByNetworkId(pid);

	Table@ table;
	if (!this.get("Table", @table)) return;

	CBitStream params1;
	params1.write_bool(false);
	params1.write_u16(0);
	params1.write_u8(this.get_u8("selected_white"));
	params1.write_u8(this.get_u8("selected_black"));
	params1.write_s8(this.get_s8("captured_white"));
	params1.write_s8(this.get_s8("captured_black"));
	params1.write_bool(table.can_castle_white);
	params1.write_bool(table.can_castle_black);
	params1.write_u8(table.castling_rook_moved_white);
	params1.write_u8(table.castling_rook_moved_black);
	params1.write_bool(this.get_bool("reset_white"));
	params1.write_bool(this.get_bool("reset_black"));
	params1.write_u8(table.check_index);
	params1.write_bool(table.turn_white);
	params1.write_bool(table.end);
	params1.write_u8(table.last_turn_from);
	params1.write_u8(table.last_turn_to);
	params1.write_s8(table.last_piece_taken);
	params1.write_string(this.get_string("last_player_attached_0"));
	params1.write_string(this.get_string("last_player_attached_1"));

	for (u8 i = 0; i < 64; i++)
	{
		s8 x = i%8;
		s8 y = Maths::Floor(i/8);

		Vec2f icon_pos = Vec2f_zero;
		u8 type = 0;
		s8 color = -1;

		Board@ p = @table.board_pieces[x][y];
		if (p !is null)
		{
			icon_pos = p.icon_pos;
			type = p.type;
			color = p.color;
		}

		params1.write_Vec2f(icon_pos);
		params1.write_u8(type);
		params1.write_u8(color);
	}

	if (pid != 0 && p !is null) // sync to caster
		this.server_SendCommandToPlayer(this.getCommandID("sync"), params1, p);
	else // sync to all
		this.SendCommand(this.getCommandID("sync"), params1);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("sync"))
	{
		//
		bool init = params.read_bool();
		u16 send_to = params.read_u16();
		
		if (isServer() && init)
		{
			Sync(this, true, send_to);
		}
		if (isClient() && !init)
		{
			Table@ table;
			if (!this.get("Table", @table)) return;

			//
			u8 selected_white = params.read_u8();
			u8 selected_black = params.read_u8();
			s8 captured_white = params.read_s8();
			s8 captured_black = params.read_s8();

			this.set_u8("selected_white", selected_white);
			this.set_u8("selected_black", selected_black);
			this.set_s8("captured_white", captured_white);
			this.set_s8("captured_black", captured_black);

			//
			bool can_castle_white = params.read_bool();
			bool can_castle_black = params.read_bool();
			u8 castling_rook_moved_white = params.read_u8();
			u8 castling_rook_moved_black = params.read_u8();

			table.can_castle_white = can_castle_white;
			table.can_castle_black = can_castle_black;
			table.castling_rook_moved_white = castling_rook_moved_white;
			table.castling_rook_moved_black = castling_rook_moved_black;

			//
			bool reset_white = params.read_bool();
			bool reset_black = params.read_bool();

			this.set_bool("reset_white", reset_white);
			this.set_bool("reset_black", reset_black);

			//
			table.check_index = params.read_u8();
			table.turn_white = params.read_bool();
			table.end = params.read_bool();

			table.last_turn_from = params.read_u8();
			table.last_turn_to = params.read_u8();
			table.last_piece_taken = params.read_s8();

			this.set_string("last_player_attached_0", params.read_string());
			this.set_string("last_player_attached_1", params.read_string());

			for (s8 i = 0; i < 64; i++)
			{
				s8 x = i%8;
				s8 y = Maths::Floor(i/8);

				Vec2f icon_pos = Vec2f_zero;
				u8 type = 0;
				s8 color = -1;

				if (!params.saferead_Vec2f(icon_pos) || !params.saferead_u8(type) || !params.saferead_s8(color))
				{
					error("Error while syncing board at ["+x+"]["+y+"]");
				}

				@table.board_pieces[x][y] = MakePieceOnBoard(table, type, color);
				table.board_pieces[x][y].icon_pos = icon_pos;
			}

			this.set("Table", @table);
		}
	}
	else if (cmd == this.getCommandID("sync_log"))
	{
		if (isClient() && isServer()) return; // prevent localhost from executing this twice
		if (!isClient()) return;

		string text = params.read_string();
		u8 moved_from = params.read_u8();
		u8 moved_to = params.read_u8();
		s8 taken_piece = params.read_s8();

		string[]@ chess_player;
		u32[] game_from;
		u32[] game_to;
		s32[] taken_pieces;

		bool assign = this.get("chess_player", @chess_player) && this.get("game_from", game_from) && this.get("game_to", game_to) && this.get("taken_pieces", taken_pieces);
		if (!assign) return;

		chess_player.push_back(text);
		game_from.push_back(moved_from);
		game_to.push_back(moved_to);
		taken_pieces.push_back(0);

		this.set("chess_player", @chess_player);
		this.set("game_from", game_from);
		this.set("game_to", game_to);
		this.set("taken_pieces", taken_pieces);
	}
	else if (cmd == this.getCommandID("reset"))
	{
		if (!isServer()) return;
		s8 side = -1;

		if (!params.saferead_s8(side))
		{
			error("Could not read side of resetting board ["+this.getNetworkID()+"]");
			return;
		}

		if (side == 0)
		{
			this.set_bool("reset_white", !this.get_bool("reset_white"));
			this.Sync("reset_white", true);
		}
		else if (side == 1)
		{
			this.set_bool("reset_black", !this.get_bool("reset_black"));
			this.Sync("reset_black", true);
		}

		// reset event check
		if (this.get_bool("reset_white") && this.get_bool("reset_black"))
		{
			PrintGameLog(this);
			ResetGameLog(this);

			this.set_bool("reset_white", false);
			this.set_bool("reset_black", false);

			ResetBoard(this);
			Sync(this);
		}
	}
}

// send log to tcpr bot
void PrintGameLog(CBlob@ this)
{
	Table@ table;
	if (!this.get("Table", @table)) return;
	
	bool was_white_king = false;
	bool was_black_king = false;

	for (s8 i = 0; i < 64; i++)
	{
		s8 x = i%8;
		s8 y = Maths::Floor(i/8);

		Board@ p = @table.board_pieces[x][y];
		if (p is null || p.type != Chess::KING) continue;

		if (p.color == 0) was_white_king = true;
		else if (p.color == 1) was_black_king = true;
	}

	if ((!was_white_king && !was_black_king) || (was_white_king && was_black_king))
	{
		print("Chess game ["+this.getNetworkID()+"] was finished incorrectly");
		return; // game was reset at incorrect state
	}

	string text = "Chess game log ["+this.getNetworkID()+"]";
	string tcpr_text = "gamelog";

	string[]@ chess_player;
	u32[] game_from;
	u32[] game_to;
	s32[] taken_pieces;
	bool assign = this.get("chess_player", @chess_player) && this.get("game_from", game_from) && this.get("game_to", game_to) && this.get("taken_pieces", taken_pieces);
	
	if (assign && game_from.size() == game_to.size() && game_from.size() == chess_player.size() && game_from.size() == taken_pieces.size())
	{
		for (int i = 0; i < game_from.size(); i++)
		{
			string conc = chess_player[i]+"-"+game_from[i]+"-"+game_to[i];
			tcpr_text = tcpr_text + "_" + conc;
			text = text+"\n"+conc;
		}
		
		//print(text);
		//print(tcpr_text);
		//tcpr(tcpr_text);
	}
}

void ResetGameLog(CBlob@ this)
{
	string[] chess_player;
	u32[] game_from;
	u32[] game_to;
	s32[] taken_pieces;

	this.set("chess_player", @chess_player);
	this.set("game_from", game_from);
	this.set("game_to", game_to);
	this.set("taken_pieces", taken_pieces);
}

void ResetBoard(CBlob@ this)
{
	Table table();
	table.id = this.getNetworkID();

	this.set_u8("selected_white", 64 - 4);
	this.set_u8("selected_black", 4);
	this.set_s8("captured_white", -1);
	this.set_s8("captured_black", -1);

	// white
	@table.board_pieces[0][7] = MakePieceOnBoard(table, 4, 0);
	@table.board_pieces[1][7] = MakePieceOnBoard(table, 3, 0);
	@table.board_pieces[2][7] = MakePieceOnBoard(table, 2, 0);
	@table.board_pieces[3][7] = MakePieceOnBoard(table, 5, 0);
	@table.board_pieces[4][7] = MakePieceOnBoard(table, 6, 0);
	@table.board_pieces[5][7] = MakePieceOnBoard(table, 2, 0);
	@table.board_pieces[6][7] = MakePieceOnBoard(table, 3, 0);
	@table.board_pieces[7][7] = MakePieceOnBoard(table, 4, 0);

	for (u8 i = 0; i < 8; i++)
	{
		@table.board_pieces[i][6] = MakePieceOnBoard(table, 1, 0);
	}

	// black
	@table.board_pieces[0][0] = MakePieceOnBoard(table, 4, 1);
	@table.board_pieces[1][0] = MakePieceOnBoard(table, 3, 1);
	@table.board_pieces[2][0] = MakePieceOnBoard(table, 2, 1);
	@table.board_pieces[3][0] = MakePieceOnBoard(table, 5, 1);
	@table.board_pieces[4][0] = MakePieceOnBoard(table, 6, 1);
	@table.board_pieces[5][0] = MakePieceOnBoard(table, 2, 1);
	@table.board_pieces[6][0] = MakePieceOnBoard(table, 3, 1);
	@table.board_pieces[7][0] = MakePieceOnBoard(table, 4, 1);

	for (u8 i = 0; i < 8; i++)
	{
		@table.board_pieces[i][1] = MakePieceOnBoard(table, 1, 1);
	}

    this.set("Table", @table);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.hasAttached();
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return false;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob !is null && !blob.hasTag("flesh") && !blob.hasTag("arrow") && !blob.hasTag("explosive");
}

// avoid shitty exploiting when two objects are plugged into each other
void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	CPlayer@ p = attached.getPlayer();
	if (p !is null)
		this.set_string("last_player_attached_"+attachedPoint.name.substr(attachedPoint.name.length()-1, 1), "["+p.getCharacterName()+" / "+p.getUsername()+"]");
	
	if (attached !is this && attached.isMyPlayer() && attachedPoint.name == "PLAYER1")
	{
		// hack lerp for immediate board rotation
		this.Tag("team1_rotate_immediately");
	}

	if (attached is this)
	{
		this.setAngleDegrees(this.isFacingLeft() ? 90 : -90);

		AttachmentPoint@ ap0 = this.getAttachments().getAttachmentPointByName("PLAYER0");
		AttachmentPoint@ ap1 = this.getAttachments().getAttachmentPointByName("PLAYER1");

		if (ap0 is null || ap1 is null) return;

		CBlob@ p0 = ap0.getOccupied();
		CBlob@ p1 = ap1.getOccupied();

		if (p0 !is null) p0.server_DetachFrom(this);
		if (p1 !is null) p1.server_DetachFrom(this);
	}
}

// reset visuals
void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached !is this && detached.isMyPlayer() && attachedPoint.name == "PLAYER1")
	{
		// hack lerp for immediate board rotation
		this.Tag("team1_rotate_immediately");
	}

	this.setAngleDegrees(0);
}

f32 getRandomPitch()
{
	return (XORRandom(6)-5)*0.01f;
}