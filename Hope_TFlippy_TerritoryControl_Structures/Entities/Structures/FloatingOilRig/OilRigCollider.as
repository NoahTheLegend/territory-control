void onInit(CBlob@ this)
{
	this.getShape().SetOffset(Vec2f(3, -52));
	this.getShape().SetStatic(true);
	this.getShape().getConsts().mapCollisions = false;

	u16 netid = this.getNetworkID();
	CMap@ map = getMap();
	map.server_AddMovingSector(Vec2f(-58.0f, -24.0f), Vec2f(-8.0f, -12.0f), "ladder", netid);
	map.server_AddMovingSector(Vec2f(-58.0f, 7.0f), Vec2f(-8.0f, 18.0f), "ladder", netid);
	map.server_AddMovingSector(Vec2f(-56.0f, 34.0f), Vec2f(56.0f, 44.0f), "ladder", netid);
	map.server_AddMovingSector(Vec2f(16.0f, -8.0f), Vec2f(56.0f, 3.0f), "ladder", netid);
	map.server_AddMovingSector(Vec2f(-6.0f, -66.0f), Vec2f(12.0f, 32.0f), "ladder", netid);

	Vec2f offset = Vec2f(-52, -3);
	{
		Vec2f pos_off = Vec2f(2, 100)+offset;
		{
			Vec2f[] shape = { Vec2f(0.0f, 0.0f) + pos_off,
			                  Vec2f(112.0f,  0.0f) + pos_off,
			                  Vec2f(112.0f,  6.0f) + pos_off,
			                  Vec2f(0.0f, 6.0f) + pos_off
			                };
			this.getShape().AddShape(shape);
		}
	}
	{
		Vec2f pos_off = Vec2f(0, 72)+offset;
		{
			Vec2f[] shape = { Vec2f(0.0f, 0.0f) + pos_off,
			                  Vec2f(48.0f, 0.0f) + pos_off,
			                  Vec2f(48.0f, 3.0f) + pos_off,
			                  Vec2f(0.0f, 3.0f) + pos_off
			                };
			this.getShape().AddShape(shape);
		}
	}
	{
		Vec2f pos_off = Vec2f(0, 42)+offset;
		{
			Vec2f[] shape = { Vec2f(0.0f, 0.0f) + pos_off,
			                  Vec2f(48.0f, 0.0f) + pos_off,
			                  Vec2f(48.0f, 5.0f) + pos_off,
			                  Vec2f(0.0f, 5.0f) + pos_off
			                };
			this.getShape().AddShape(shape);
		}
	}
	{
		Vec2f pos_off = Vec2f(72, 58)+offset;
		{
			Vec2f[] shape = { Vec2f(0.0f, 0.0f) + pos_off,
			                  Vec2f(40.0f, 0.0f) + pos_off,
			                  Vec2f(40.0f, 6.0f) + pos_off,
			                  Vec2f(0.0f, 6.0f) + pos_off
			                };
			this.getShape().AddShape(shape);
		}
	}
}
