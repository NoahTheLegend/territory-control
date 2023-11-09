// referencing some code made by GoldenGuy for KIWI mod

#include "Hitters.as";
#include "HittersTC.as";
#include "Knocked.as";

const f32 sharpness_factor = 0.5f; // linear scale narrow, last segment will be 50% less thick
const u16 whip_length = 20; // how many segments
const u16 swipe_time = 20; // delay for damage, also anim speed
const f32 idle_radius = 8.0f; // radius while twisted
const f32 atk_radius = 2.5f; // modifier to radius \ atk distance
const f32 swipe_speed = 8.0f; // modifier to swipe time, only affects distance and visuals
const f32 swipe_accel_in = 4; // acceleration in
const f32 swipe_accel_out = 2; // acceleration out
const f32 max_angle = -90; // huge skill issue, set it manually to disrupt animation

void onInit(CBlob@ this)
{
	this.Tag("ignore fall");
	this.set_u32("next attack", 0);

	AttachmentPoint@ ap = this.getAttachments().getAttachmentPointByName("PICKUP");
	if (ap !is null)
	{
		ap.SetKeysToTake(key_action1 | key_action2);
	}

	Whip whip("RopeSegment.png", Vec2f_zero, 16.0f);
	whip.Idle();
    this.set("whip", @whip);
	int render_id = Render::addBlobScript(Render::layer_prehud, this, "Whip.as", "DrawWhip");
}

class Whip
{
    string segment_texture;
    Segment@[] segments;
    Vertex[] verts;
    Vec2f rotation_offset;
    float[] mat;
    float angle;
    float facing;
    SColor color;
    float prev_anim_timer;
    float anim_timer;
    float anim_dist;
    float time_delta;

    Vec2f vert1;
    Vec2f vert2;
    Vec2f vert3;
    Vec2f vert4;

	u32 start_time;
	bool was_fl;
	bool next_idle;

    Whip(string tex, Vec2f _offset, float _anim_dist)
    {
        segment_texture = tex;
        if(!Texture::exists(segment_texture))
            Texture::createFromFile(segment_texture, CFileMatcher(segment_texture).getFirst());
        int width = Texture::width(segment_texture);
        int height = Texture::height(segment_texture);
        Vec2f size_half = Vec2f(width, height)/2.0f;

        vert1 = Vec2f(-size_half.x,-size_half.y);
        vert2 = Vec2f(size_half.x,-size_half.y);
        vert3 = Vec2f(size_half.x,size_half.y);
        vert4 = Vec2f(-size_half.x,size_half.y);

		prev_anim_timer = 0;
		anim_timer = 0;
		time_delta = 0;

        rotation_offset = _offset;
        anim_dist = _anim_dist;
		start_time = 0;
		was_fl = false;
		next_idle = false;
    }

	void Idle()
	{
		start_time = 0;
		next_idle = false;

		Segment@[] reset;
		segments = reset;

		Vec2f[] points;
		for (u8 i = 0; i < whip_length; i++)
		{
			points.push_back(Vec2f(idle_radius,0).RotateBy(i*8));
		}

		verts.set_length(points.size()*4);

        Vec2f a, b, c, d;
        for(int i = 0; i < points.size(); i++)
        {
            Vec2f a = i-1 < 0 ? points[points.size()-1] : points[i-1];
            Vec2f b = points[i];
            Vec2f c = i+1 == points.size() ? points[0] : points[i+1];
            Vec2f d = i+2 >= points.size() ? (i+1 == points.size() ? points[1] : points[0]) : points[i+2];
			
			f32 seg_rot = i*4;
            Segment segment(a,b,c,d,i,seg_rot);
            @segment.sys = @this;
            segments.push_back(@segment);
        }
	}

	void Start()
	{
		start_time = getGameTime();
	}

	bool isIdle()
	{
		return start_time == 0;
	}

	void Update(CBlob@ blob)
	{
		if (next_idle || getGameTime() > start_time + swipe_time)
		{
			Idle();
			return;
		} 
		
		bool fl = blob.isFacingLeft();
		f32 facing = fl ? -1 : 1;
		int diff = getGameTime()-start_time;
		f32 dfc = f32(diff)/f32(swipe_time); // diff factor from 0 to 1
		if (isClient())
		{
			Vec2f[] points;

			f32 accel = (diff < swipe_time/2 ? swipe_accel_in : swipe_accel_out);
			f32 mod = (swipe_speed-(swipe_speed*2*dfc)) * accel;
			f32 stfc = Maths::Min(1.0f, f32(diff)/(swipe_time/3)); // start factor to deal with shitty visual desegmentation

			for (u8 i = 0; i < whip_length; i++)
			{
				f32 rot = i * mod * stfc;
				points.push_back(Vec2f(idle_radius+i*(atk_radius*2*(dfc>0.5f?1.0f-dfc:dfc)), 0).RotateBy(facing*rot, Vec2f(0,facing * (diff > swipe_time/2 ? swipe_time*2-diff : 0))));
				if (rot < max_angle) next_idle = true;
			}
			verts.set_length(points.size()*4);

        	Vec2f a, b, c, d;
        	for(int i = 0; i < points.size(); i++)
        	{
				points[i].y *= -1;
        	    Vec2f a = i-1 < 0 ? points[points.size()-1] : points[i-1];
        	    Vec2f b = points[i];
        	    Vec2f c = i+1 == points.size() ? points[0] : points[i+1];
        	    Vec2f d = i+2 >= points.size() ? (i+1 == points.size() ? points[1] : points[0]) : points[i+2];

				f32 seg_rot = i > 0 ? -(points[i-1]-points[i]).Angle() : 0;
        	    segments[i] = Segment(a,b,c,d,i,seg_rot);
				@segments[i].sys = @this;
        	}
		}

		if (diff == swipe_time/2) // center
		{
			u8 team = blob.getTeamNum();

			if (blob.getSprite() !is null)
			{
				blob.getSprite().PlaySound("whiphit.ogg", 2.0f, 0.9f+XORRandom(21)*0.01f);
			}
			
			HitInfo@[] hitInfos;
			if (getMap().getHitInfosFromArc(blob.getPosition(), blob.isFacingLeft()?180:0, 45, whip_length*4 - 8.0f * atk_radius, blob, @hitInfos))
			{
				for (uint i = 0; i < hitInfos.length; i++)
				{
					CBlob@ target = hitInfos[i].blob;
					if (target !is null && target.hasTag("flesh"))
					{
						u8 knock;
						bool do_damage = true;
					
						if (target.getName() == "slave")
						{
							knock = 90 + (1.0f - (target.getHealth() / target.getInitialHealth())) * (30 + XORRandom(50)) * 4.0f;
							do_damage = false;
							SetKnocked(target, knock);
						}
										
						AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("PICKUP");
						CBlob@ holder = point.getOccupied();

						if (isServer())
						{
							if (holder !is null)
								holder.server_Hit(target, target.getPosition(), Vec2f(), do_damage ? 0.25f : 0.0f, HittersTC::staff, true);
						}
					}
				}
			}
		}
	}

	void Render(CBlob@ this)
    {
        float render_anim_time = Maths::Lerp(prev_anim_timer, anim_timer, time_delta);
        Vec2f pos = this.getInterpolatedPosition();
		bool fl = this.isFacingLeft();
		facing = fl ? -1.0f : 1.0f;

        Matrix::MakeIdentity(mat);
        float[] _mat = mat;
        Matrix::SetTranslation(mat, rotation_offset.x*(-facing), rotation_offset.y, 0);
        Matrix::SetRotationDegrees(_mat, 0, 0, 0);
        Matrix::MultiplyImmediate(mat, _mat);

        Matrix::MultiplyImmediate(_mat, mat);

        Matrix::SetTranslation(mat, pos.x, pos.y, 0);
        Matrix::MultiplyImmediate(mat, _mat);
        Render::SetModelTransform(mat);

        for(int i = 0; i < segments.size(); i++)
        {
            segments[i].Render(render_anim_time % 1.0f, i*4);
        }

        Render::RawQuads(segment_texture, verts);
        Render::SetTransformWorldspace();

        time_delta += getRenderDeltaTime()*getTicksASecond();
    }
}

void DrawWhip(CBlob@ this, int id)
{
	if (!this.isAttached()) return;
    Whip@ whip;
    if (this.get("whip", @whip))
    	whip.Render(this);
}

class Segment
{
    Whip@ sys;

    Vec2f a, b, c, d;
    bool should_bump;
	u16 num;
	f32 rot;
	f32 sf;

    Segment(Vec2f p0, Vec2f p1, Vec2f p2, Vec2f p3, u16 _num, f32 _rot)
    {
        // Calculate the coefficients of the spline
        a = p1 * 2.0f;
        b = p2 - p0;
        c = p0 * 2.0f - p1 * 5.0f + p2* 4.0f - p3;
        d = -p0 + p1 * 3.0f - p2 * 3.0f + p3;

		num = _num;
		rot = _rot;
		sf = 1.0f - sharpness_factor * num/whip_length;
    }

    void calculateCatmullRomSpline(float t, Vec2f&out position)
    {
		//printf("a:"+a+" b:"+b+" c:"+c+" d:"+d+" t:"+t);
        position = (a + (b * t) + (c * (t * t)) + (d * (t * t * t))) * 0.5f;
    }

    void Render(float render_anim_time, int index)
    {
        Vec2f new_point = Vec2f_zero;
        calculateCatmullRomSpline(sys.facing == 1.0f ? render_anim_time : 1.0f - render_anim_time, new_point);
        new_point.x *= sys.facing;

        sys.verts[index  ] = Vertex(new_point + Vec2f(sys.vert1.x*sys.facing, sys.vert1.y * sf).RotateBy(rot), 0, Vec2f(0,0), sys.color);
        sys.verts[index+1] = Vertex(new_point + Vec2f(sys.vert2.x*sys.facing, sys.vert2.y * sf).RotateBy(rot), 0, Vec2f(1,0), sys.color);
        sys.verts[index+2] = Vertex(new_point + Vec2f(sys.vert3.x*sys.facing, sys.vert3.y * sf).RotateBy(rot), 0, Vec2f(1,1), sys.color);
        sys.verts[index+3] = Vertex(new_point + Vec2f(sys.vert4.x*sys.facing, sys.vert4.y * sf).RotateBy(rot), 0, Vec2f(0,1), sys.color);
    }
}

void onTick(CBlob@ this)
{
	bool can_upd = false;
    Whip@ whip;
    if (this.get("whip", @whip))
    	can_upd = true;
	
	if (can_upd)
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		CBlob@ holder = point.getOccupied();
		
		if (holder is null) return;
		
		if (getKnocked(holder) <= 0)
		{
			if (point.isKeyJustPressed(key_action1) || whip.start_time > 0)
			{
				if (whip.start_time == 0) whip.Start();
				whip.Update(this);
			}
			else if (point.isKeyJustReleased(key_action1))
			{
				whip.Idle();
			}
		}
	}
}

void onDetach(CBlob@ this,CBlob@ detached,AttachmentPoint@ attachedPoint)
{
	detached.Untag("noLMB");

    Whip@ whip;
    if (this.get("whip", @whip))
		whip.Idle();
}

void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{
	attached.Tag("noLMB");

    Whip@ whip;
    if (this.get("whip", @whip))
		whip.Idle();
}