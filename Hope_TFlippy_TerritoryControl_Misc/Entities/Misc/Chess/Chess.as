// LIST OF KNOWN BUGS
// ====================================
// render_icon interpolation does not work properly due to Sync: board on client is fully rebuilt when synced
// ^ find out a better hack or save signatures of all pieces in a board instead of creating new ones (kinda easy to ruin in AS)
// ^ currently Sync() is delayed for sync_delay amount of ticks
// ------------------------------------
// when attached to player and chess blob is partially inside map, the rendered board microshakes until finished
// colliding with map at least once
// ------------------------------------

// README
// secondary seat (black) has fixed facepos of attachment point, after including this file in a mod, you should
// perform changes to Seats.as using "seat turn around" tag to avoid hard setting occupied facepos

const u8 sync_delay = 30;
void onInit(CBlob@ this)
{
	// "signal" commands to communicate between server and client 
	this.addCommandID("sync");
	this.addCommandID("reset");

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
}

void onTick(CBlob@ this)
{
	if (isServer())
	{
		// the delay for sync (hack, read TODO)
		if (this.get_u32("sync_time") >= getGameTime())
		{
			SendSyncFromServer(this);

			this.set_u32("sync_time", 0);
			this.set_u16("sync_pid", 0);
		}
	}
	
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

			u8 sw = this.get_u8("selected_white");
			s8 cw = this.get_s8("captured_white");

			if (ap0.isKeyJustPressed(key_left) && sw % 8 != 0) sw -= 1;
			if (ap0.isKeyJustPressed(key_right) && sw % 8 != 7) sw += 1;
			if (ap0.isKeyJustPressed(key_up) && Maths::Floor(sw/8) != 0) sw -= 8;
			if (ap0.isKeyJustPressed(key_down) && Maths::Floor(sw/8) != 7) sw += 8;

			if (ap0.isKeyJustPressed(key_action1) && (localhost || table.turn_white)) 
			{
				Board@ target = @table.board_pieces[sw%8][Maths::Floor(sw/8)];
				bool not_null = target !is null;
				bool not_empty = not_null && target.type != 0;

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

			// not needed to sync the whole board
			if (isServer())
			{
				this.set_u8("selected_white", sw);
				this.Sync("selected_white", true);
				this.set_s8("captured_white", cw);
				this.Sync("captured_white", true);
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

			u8 sb = this.get_u8("selected_black");
			s8 cb = this.get_s8("captured_black");

			if (ap1.isKeyJustPressed(key_left) && sb % 8 != 0) sb -= 1;
			if (ap1.isKeyJustPressed(key_right) && sb % 8 != 7) sb += 1;
			if (ap1.isKeyJustPressed(key_up) && Maths::Floor(sb/8) != 0) sb -= 8;
			if (ap1.isKeyJustPressed(key_down) && Maths::Floor(sb/8) != 7) sb += 8;

			if (ap1.isKeyJustPressed(key_action1) && (localhost || !table.turn_white))
			{
				Board@ target = @table.board_pieces[sb%8][Maths::Floor(sb/8)];
				bool not_null = target !is null;
				bool not_empty = not_null && target.type != 0;

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

			if (isServer())
			{
				this.set_u8("selected_black", sb);
				this.Sync("selected_black", true);
				this.set_s8("captured_black", cb);
				this.Sync("captured_black", true);
			}
		}
	}
}

const SColor col_white = SColor(215,255,255,255);
const SColor col_black = SColor(215,15,15,15);
const SColor col_selection = SColor(140,255,255,0);
const SColor col_selection_disabled = col_enemy;
const SColor col_captured = SColor(140,0,0,255);
const SColor col_enemy = SColor(140,255,0,0);
const SColor col_path = SColor(140,0,255,0);
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
	bool rendering = true;
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
		for (u8 i = 0; i < 8; i++)
		{
			f32 row_offset = (area/8)*(i+1);
			GUI::DrawTextCentered(""+(i+1), tl+Vec2f(-16, area - row_offset + (area/8)/2 - 1.5f), SColor(225,255,255,255));
		}

		// cols
		for (u8 i = 0; i < 8; i++)
		{
			f32 col_offset = (area/8)*i;
			GUI::DrawTextCentered(cols[i], tl+Vec2f(col_offset + (area/8)/2, area + 16 - 4.0f), SColor(225,255,255,255));
		}

		// movement history
		string[]@ chess_player;
		u8[] game_from;
		u8[] game_to;
		if (this.get("chess_player", @chess_player) && this.get("game_from", game_from) && this.get("game_to", game_to))
		{
			s8 s = Maths::Min(chess_player.size(), 8);
			s8 start_index = Maths::Max(0, chess_player.size() - 8); 

			for (s8 i = 0; i < s; i++)
			{
			    s8 actual_index = start_index + i;
			    f32 row_offset = (area / 8) * (s - i);

			    s8 from_x = game_from[actual_index] % 8;
			    s8 from_y = 8 - Maths::Floor(game_from[actual_index] / 8);

			    s8 to_x = game_to[actual_index] % 8;
			    s8 to_y = 8 - Maths::Floor(game_to[actual_index] / 8);

			    string[] spl = chess_player[actual_index].split("_");
			    string text = (spl[0] == "-1" ? "Rules" : spl[0] == "0" ? "White" : "Black") + ": " + cols[from_x] + "" + from_y + " - " + cols[to_x] + "" + to_y;

			    GUI::DrawText(text, tl + Vec2f(area + 16, row_offset - (area / 8) + 1.5f), SColor(225, 255, 255, 255));
			}
		}

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

		// draw tiles
		for (u8 i = 0; i < 64; i++)
		{
			u8 x = i%8;
			u8 y = Maths::Floor(i/8);

			SColor col = (y%2==0 ? i%2 : (i+1)%2) == 0 ? col_white : col_black;
			Board@ p = @table.board_pieces[x][y];
			bool not_empty = p !is null && p.type != 0;

			if (my_p0)
			{
				bool selected = x == sw%8 && y == Maths::Floor(sw/8);
				bool captured = x == cw%8 && y == Maths::Floor(cw/8) && not_empty;

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
				bool selected = x == sb%8 && y == Maths::Floor(sb/8);
				bool captured = x == cb%8 && y == Maths::Floor(cb/8) && not_empty;

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

			Vec2f tile_offset = Vec2f(f32(x) * tilesize, f32(y) * tilesize) + tl;
			GUI::DrawRectangle(tile_offset, tile_offset + Vec2f(tilesize, tilesize), col);
		}

		// draw selection & captured
		if (draw_path && (my_p0 || my_p1))
		{
			u8 s = my_p0 ? sw : sb;
			u8 c = my_p0 ? cw : cb;

			u8 x = c%8;
			u8 y = Maths::Floor(c/8);

			Board@ p = @table.board_pieces[x][y];
			bool not_empty = p !is null && p.type != 0;

			s8[] enemy_tiles;
			s8[] move_tiles = p.get_move_tiles(c, p.color, enemy_tiles);

			for (u8 j = 0; j < move_tiles.size(); j++)
			{
				s8 tile = move_tiles[j];
				if (tile == s) continue;

				Vec2f special_tile_offset = Vec2f(f32(tile%8) * tilesize, f32(Maths::Floor(tile/8)) * tilesize) + tl;
				GUI::DrawRectangle(special_tile_offset, special_tile_offset + Vec2f(tilesize, tilesize), col_path);
			}

			for (u8 j = 0; j < enemy_tiles.size(); j++)
			{
				s8 tile = enemy_tiles[j];
				if (tile == s) continue;

				Vec2f special_tile_offset = Vec2f(f32(tile%8) * tilesize, f32(Maths::Floor(tile/8)) * tilesize) + tl;
				GUI::DrawRectangle(special_tile_offset, special_tile_offset + Vec2f(tilesize, tilesize), col_enemy);
			}
		}
	}

	// draw icons
	for (u8 i = 0; i < 64; i++)
	{
		u8 x = i%8;
		u8 y = Maths::Floor(i/8);

		Board@ p = @table.board_pieces[x][y];
		bool not_empty = p !is null && p.type != 0;

		Vec2f tile_offset = Vec2f(f32(x) * tilesize, f32(y) * tilesize) + tl;
		if (not_empty)
		{
			Vec2f pos = driver.getWorldPosFromScreenPos(tile_offset - Vec2f(7,8) * factor);
			if (p.icon_pos == Vec2f_zero) p.icon_pos = pos;

			p.icon_pos = Vec2f_lerp(p.icon_pos, pos, 0.33f);
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
	array<array<Board@>> board_pieces();
	bool end;

	Table()
	{
		id = 0;
		can_castle_white = true;
		can_castle_black = true;
		castling_rook_moved_white = 0;
		castling_rook_moved_black = 0;
		turn_white = true;
		board_pieces = array<array<Board@>>(8, array<Board@>(8, MakePieceOnBoard(@this, 0, -1)));
		end = false;
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

Board@ MakePieceOnBoard(Table@ table, u8 type, s8 color)
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

	return @Board(table, type, color, false);
}

const Vec2f up = Vec2f(0, -1); 
const Vec2f right = Vec2f(1, 0);
const Vec2f down = Vec2f(0, 1);
const Vec2f left = Vec2f(-1, 0);

class Board // breaks solid, but who cares
{
	Table@ table;
	u8 type; s8 color; 				// Board, team
	s8[] dirs; bool inf;			// 0 = top, 1 = top right, 2 = right ... 8 = knight, 9 = castling
	Vec2f icon_pos;					// pos on screen

	Board()
	{
		icon_pos = Vec2f_zero;
		type = 0; color = -1; inf = false;
	}

	Board(Table@ _table, s8 _type, s8 _color, bool _inf)
	{
		Board();
		@table = @_table;
		type = _type;
		color = _color;
		inf = _inf;
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

	void add_direction(s8 dir)
	{
		dirs.push_back(dir);
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
		if (p is null || p.type == 0) return -1;

		return team == p.color ? 0 : 1;
	}

	// returns tiles in one array, iterating directions assigned to pieces
	// ^ additionally separates enemy tiles into another array
	s8[] get_move_tiles(s8 pos, s8 team, s8[] &out enemies)
	{
		s8[] arr;
		Board@[][] board_pieces = get_board();
		
		s8 x = pos%8;
		s8 y = Maths::Floor(pos/8);

		Board@ p = @board_pieces[x][y];
		if (p is null) return arr;

		bool is_pawn = p.type == 1;
		bool first_pawn_move = is_pawn && (p.color == 0 ? y == 6 : y == 1);

		if (is_pawn)
		{
			if (team == 0) // white
			{
				// top left enemy check
				{
					s8 obstacle = has_obstacle(pos - 9, team);
					if (obstacle != -1 && obstacle == 1 && !is_out_of_bounds(pos, Vec2f(up)+left))
						enemies.push_back(pos-9);
				}
				// top right
				{
					s8 obstacle = has_obstacle(pos - 7, team);
					if (obstacle != -1 && obstacle == 1 && !is_out_of_bounds(pos, Vec2f(up)+right))
						enemies.push_back(pos-7);
				}
			}
			else // black
			{
				{
					s8 obstacle = has_obstacle(pos + 9, team);
					if (obstacle != -1 && obstacle == 1 && !is_out_of_bounds(pos, Vec2f(down)+right))
						enemies.push_back(pos + 9);
				}
				{
					s8 obstacle = has_obstacle(pos + 7, team);
					if (obstacle != -1 && obstacle == 1 && !is_out_of_bounds(pos, Vec2f(down)+left))
						enemies.push_back(pos + 7);
				}
			}	
		}
	
		for (s8 i = 0; i < dirs.size(); i++) // direction types
		{
			s8 dir = dirs[i];
			if (dir < 8) // straight & diagonal
			{
				bool do_break = false;
				for (s8 j = 0; j < (inf ? 8 : first_pawn_move ? 2 : 1); j++) // tiles in line
				{
					if (do_break) continue;
	
					Vec2f[] directions = {
						up, Vec2f(up) + right, right, Vec2f(down) + right,
						down, Vec2f(down) + left, left, Vec2f(up) + left
					};
	
					Vec2f dir_vec = directions[dir];
					if (is_pawn && team == 1) dir_vec *= -1;
					dir_vec = dir_vec * (j + 1);
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
						if (is_pawn) break; // stop if it's next to some thing

						enemies.push_back(pos_dir);
						do_break = true;
						continue;
					}
	
					arr.push_back(pos_dir);
				}
			}
			else if (dir == 8) // knight
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
			else if (dir == 9) // castling
			{
				if (color == 0 && table.can_castle_white)
				{
					bool can_castle_left = false;
					bool can_castle_right = false;

					bool clear_left = has_obstacle(pos-1, team) == -1 && has_obstacle(pos-2, team) == -1 && has_obstacle(pos-3, team) == -1;
					bool clear_right = has_obstacle(pos+1, team) == -1 && has_obstacle(pos+2, team) == -1;

					if (table.castling_rook_moved_white < 3)
					{
						// none of left & right rooks moved yet
						if (table.castling_rook_moved_white == 0)
						{
							can_castle_left = clear_left;
							can_castle_right = clear_right;
						}
						// left rook moved
						if (!can_castle_right && table.castling_rook_moved_white == 1)
						{
							can_castle_right = clear_right;
						}
						// right rook moved
						if (!can_castle_left && table.castling_rook_moved_white == 2)
						{
							can_castle_left = clear_left;
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

					if (table.castling_rook_moved_black < 3)
					{
						// none of left & right rooks moved yet
						if (table.castling_rook_moved_black == 0)
						{
							can_castle_left = clear_left;
							can_castle_right = clear_right;
						}
						// left rook moved
						if (!can_castle_right && table.castling_rook_moved_black == 1)
						{
							can_castle_right = clear_right;
						}
						// right rook moved
						if (!can_castle_left && table.castling_rook_moved_black == 2)
						{
							can_castle_left = clear_left;
						}
					}

					if (can_castle_left) arr.push_back(pos-2);
					if (can_castle_right) arr.push_back(pos+2);
				}
			}
		}
	
		return arr;
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

		if (on_pos is null || on_pos.type == 0)
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
			if (on_dest !is null && on_dest.type != 0)
				blob.getSprite().PlaySound("board_cap.ogg", 0.33f, 1.0f+getRandomPitch());
			else
				blob.getSprite().PlaySound("board_move.ogg", 0.33f, 1.0f+getRandomPitch());
		}

		@board_pieces[dest_x][dest_y] = @on_pos;
		@board_pieces[x][y] = MakePieceOnBoard(table, 0, -1);
		
		set_board(board_pieces);
		on_move_tile(pos, dest);
		log(blob, pos, dest, pid, on_pos.color);

		if (on_dest.type == 6) end_game(on_dest.color);
		return true;
	}
	
	// default hook to semantically separate code
	void on_move_tile(s8 pos, s8 dest)
	{
		Board@[][] board_pieces = get_board();

		u8 old_x = pos%8;
		u8 old_y = Maths::Floor(dest/8);

		u8 x = dest%8;
		u8 y = Maths::Floor(dest/8);
		
		Board@ p = @board_pieces[x][y];
		if (p is null) return;

		// pawn reached the end, transform into queen
		if (p.type == 1 && (p.color == 0 ? y == 0 : y == 7))
		{
			Board@ np = MakePieceOnBoard(table, 5, p.color);
			@board_pieces[x][y] = np;
			set_board(board_pieces);
		}
		else if (p.type == 6) // castling king
		{
			if (p.color == 0)
			{
				if (table.can_castle_white)
				{
					bool can_move_any = table.castling_rook_moved_white == 0;
					bool can_move_left = table.castling_rook_moved_white == 2 || can_move_any;
					bool can_move_right = table.castling_rook_moved_white == 1 || can_move_any;

					if (can_move_left && old_x == 4 && x == 2)
					{
						Board@ rook = @table.board_pieces[0][7];
						if (rook !is null && rook.move_to(56, 59, true))
						{}
					}
					if (can_move_right && old_x == 4 && x == 6)
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
					bool can_move_any = table.castling_rook_moved_black == 0;
					bool can_move_left = table.castling_rook_moved_black == 2 || can_move_any;
					bool can_move_right = table.castling_rook_moved_black == 1 || can_move_any;

					if (can_move_left && old_x == 4 && x == 2)
					{
						Board@ rook = @table.board_pieces[0][0];
						if (rook !is null && rook.move_to(0, 3, true))
						{}
					}
					if (can_move_right && old_x == 4 && x == 6)
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
		else if (p.type == 4) // rook validation, if moved at least once - disable castling at its side
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
		
		if (p.color == 0 || p.color == 1) end_turn(p.color);
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
	}

	// logging for tcpr bot
	void log(CBlob@ blob, s8 pos, s8 dest, s8 pid = 0, s8 team = -1)
	{
		string[]@ chess_player;
		u8[] game_from;
		u8[] game_to;
		if (blob !is null && blob.get("chess_player", @chess_player) && blob.get("game_from", game_from) && blob.get("game_to", game_to))
		{
			CPlayer@ player = pid == 0 ? null : getPlayerByNetworkId(pid);

			chess_player.push_back(pid == 0 ? "-1_Chess rules" : (player !is null ? team+"_"+player.getUsername() : "-1_Unknown"));
			game_from.push_back(Maths::Clamp(pos, 0, 63));
			game_to.push_back(Maths::Clamp(dest, 0, 63));

			blob.set("chess_player", @chess_player);
			blob.set("game_from", game_from);
			blob.set("game_to", game_to);
		}
	}
};

class pawn : Board
{
	pawn(Table@ table, s8 color)
	{
		super(table, 1, color, false);
		add_direction(0);
	}
};

class bishop : Board
{
	bishop(Table@ table, s8 color)
	{
		super(table, 2, color, true);
		add_direction(1);add_direction(3);add_direction(5);add_direction(7);
	}
};

class knight : Board
{
	knight(Table@ table, s8 color)
	{
		super(table, 3, color, false);
		add_direction(8);
	}
};

class rook : Board
{
	rook(Table@ table, s8 color)
	{
		super(table, 4, color, true);
		add_direction(0);add_direction(2);add_direction(4);add_direction(6);
	}
};

class queen : Board
{
	queen(Table@ table, s8 color)
	{
		super(table, 5, color, true);
		add_direction(0);add_direction(2);add_direction(4);add_direction(6);
		add_direction(1);add_direction(3);add_direction(5);add_direction(7);
	}
};

class king : Board
{
	king(Table@ table, s8 color)
	{
		super(table, 6, color, false);
		add_direction(0);add_direction(2);add_direction(4);add_direction(6);
		add_direction(1);add_direction(3);add_direction(5);add_direction(7);
		add_direction(9);
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
	params1.write_bool(table.turn_white);
	params1.write_bool(table.end);

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
			table.turn_white = params.read_bool();
			table.end = params.read_bool();

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
		if (p is null || p.type != 6) continue;

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
	u8[] game_from;
	u8[] game_to;
	bool assign = this.get("chess_player", @chess_player) && this.get("game_from", game_from) && this.get("game_to", game_to);
	
	if (assign && game_from.size() == game_to.size() && game_from.size() == chess_player.size())
	{
		for (int i = 0; i < game_from.size(); i++)
		{
			string conc = chess_player[i]+"-"+game_from[i]+"-"+game_to[i];
			tcpr_text = tcpr_text + "_" + conc;
			text = text+"\n"+conc;
		}
		
		print(text);
		//print(tcpr_text);
		tcpr(tcpr_text);
	}
}

void ResetGameLog(CBlob@ this)
{
	string[] chess_player;
	u8[] game_from;
	u8[] game_to;

	this.set("chess_player", @chess_player);
	this.set("game_from", game_from);
	this.set("game_to", game_to);
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
    for (s8 i = 0; i < 8; i++)
    {
        @table.board_pieces[i][6] = MakePieceOnBoard(table, 1, 0);
    }
    @table.board_pieces[0][7] = MakePieceOnBoard(table, 4, 0);
    @table.board_pieces[7][7] = MakePieceOnBoard(table, 4, 0);
    @table.board_pieces[1][7] = MakePieceOnBoard(table, 3, 0);
    @table.board_pieces[6][7] = MakePieceOnBoard(table, 3, 0);
    @table.board_pieces[2][7] = MakePieceOnBoard(table, 2, 0);
    @table.board_pieces[5][7] = MakePieceOnBoard(table, 2, 0);
    @table.board_pieces[3][7] = MakePieceOnBoard(table, 5, 0);
    @table.board_pieces[4][7] = MakePieceOnBoard(table, 6, 0);

	// black
    for (s8 i = 0; i < 8; i++)
    {
        @table.board_pieces[i][1] = MakePieceOnBoard(table, 1, 1);
    }
    @table.board_pieces[0][0] = MakePieceOnBoard(table, 4, 1);
    @table.board_pieces[7][0] = MakePieceOnBoard(table, 4, 1);
    @table.board_pieces[1][0] = MakePieceOnBoard(table, 3, 1);
    @table.board_pieces[6][0] = MakePieceOnBoard(table, 3, 1);
    @table.board_pieces[2][0] = MakePieceOnBoard(table, 2, 1);
    @table.board_pieces[5][0] = MakePieceOnBoard(table, 2, 1);
    @table.board_pieces[3][0] = MakePieceOnBoard(table, 5, 1);
    @table.board_pieces[4][0] = MakePieceOnBoard(table, 6, 1);

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
	return false;
}

// avoid shitty exploiting when two objects are plugged into each other
void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint@ attachedPoint)
{
	if (attached is this)
	{
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
	this.setAngleDegrees(0);
}

f32 getRandomPitch()
{
	return (XORRandom(6)-5)*0.01f;
}