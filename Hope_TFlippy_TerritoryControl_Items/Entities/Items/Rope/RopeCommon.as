
const int MAX_ROPE_SEGMENTS = 30;
const f32 MAX_DISTANCE = 4.0f; // The lower distance the better "treshold" for segments and the shorter rope will be
#include "ArcherCommon.as";

class RopeSegment {
    // Blobs
    CBlob@ blob;
    CBlob@ nextSegment; // next rope segment
    CBlob@ prevSegment; // previous rope segment
    CBlob@ leader; // rope carrier
    CBlob@ hooked; // blob on hook
    u16 leaderid;
    u16 hookedid;
    // Positions
    Vec2f blobPos;
    // Utility
    int segments_left;

    // Attach next segment to this blob
    void Attach(CBlob@ _nextSegment)
    {
        @this.nextSegment = @_nextSegment;
        
        if (this.blob !is null)
        {
            this.blobPos = this.blob.getPosition();

            // Predefine next segment's attachment
            Rope@ nextRopeSegmentSettings;
            if (this.nextSegment !is null)
            {
                if (this.nextSegment.get("RopeSettings", @nextRopeSegmentSettings) && nextRopeSegmentSettings !is null)
                {
                    @nextRopeSegmentSettings.prevSegment = @this.blob;
                }
            }
        }
    }
};

class Rope : RopeSegment {
    void Init()
    {
        if (getNet().isServer() && this.blob !is null && this.segments_left > 0)
        {
            //printf("Initializing rope");
            //printf("Segments left: "+this.segments_left);

            CBlob@ segment = server_CreateBlobNoInit("rope");
            if (segment !is null)
            {
                segment.setPosition(this.blob.getPosition());
                segment.server_setTeamNum(this.blob.getTeamNum());
                segment.Tag("segment");
                segment.Init();

                CSprite@ sprite = segment.getSprite();
	            CSpriteLayer@ chain = sprite.addSpriteLayer("chain", "RopeSegment.png", 4, 2, -1, 0);
	            if (chain !is null)
	            {
	            	chain.SetRelativeZ(-10.0f);
	            }
                
                Rope@ ropeSettings;
                segment.get("RopeSettings", @ropeSettings);
                if (ropeSettings !is null)
                {
                    ropeSettings.segments_left = this.segments_left - 1;
                    if (ropeSettings.segments_left == 0)
                    {
                        segment.Untag("segment");
                        segment.Tag("tail");
                        segment.setInventoryName("Hook");
                        CSpriteLayer@ hook = sprite.addSpriteLayer("hook", "Hook.png", 8, 14);
                        if (hook !is null)
                        {
                            hook.SetRelativeZ(10.0f);
                            hook.SetVisible(true);
                        }
                    }
                    ropeSettings.Init();
                }
                
                // Bind segment to this blob
                this.Attach(segment);
            }
        }
    }
    void Update()
    {
        CBlob@ _nextSegment = this.nextSegment;
        CBlob@ _prevSegment = this.prevSegment;
        this.blobPos = this.blob.getPosition();

        //if (this.blob.hasTag("tail") && _prevSegment !is null && this.blob.isAttached())
        //{
        //    Rope@ prevSegmentSettings;
        //    if (_prevSegment.get("RopeSettings", @prevSegmentSettings))
        //    {
        //        prevSegmentSettings.CarryHook(blobPos);
        //    }
        //}

        if (_nextSegment !is null)
        {
            Rope@ nextSegmentSettings;
            if (_nextSegment.get("RopeSettings", @nextSegmentSettings))
            {
                Vec2f segmentPos = nextSegmentSettings.blob.getPosition();
                Vec2f dir = blobPos - segmentPos;
                f32 mass = this.blob.getMass();
		        f32 distance = dir.Length();
		        dir.Normalize();
                //bool solid = false;
                //if (getMap() !is null && getMap().rayCastSolid(segmentPos, blobPos)) solid = true;
                bool slow = this.blob.getVelocity().Length() <= 0.1f && (this.blob.isOnGround() || this.blob.isOnWall());

                if (distance > MAX_DISTANCE * (slow ? 0.5f : 1.0f) || !this.blob.hasTag("segment")) 
		        {
                    Vec2f approximate_pos = blobPos - dir * MAX_DISTANCE * 0.5f;
                    CMap@ map = getMap();
                    if (map !is null && map.isTileSolid(map.getTile(approximate_pos)))
                    {
                        if (map.isTileSolid(map.getTile(Vec2f(approximate_pos.x, segmentPos.y))))
                            approximate_pos = Vec2f(segmentPos.x, approximate_pos.y);
                        if (map.isTileSolid(map.getTile(Vec2f(segmentPos.x, approximate_pos.y))))
                            approximate_pos = Vec2f(approximate_pos.x, segmentPos.y);
                    }
		        	nextSegmentSettings.blob.setPosition(approximate_pos);
		        	nextSegmentSettings.blob.setVelocity(dir/3);
                    if (slow) nextSegmentSettings.blob.setVelocity(Vec2f(nextSegmentSettings.blob.getVelocity().x,0));
                }

                if (nextSegmentSettings.segments_left == 0 && nextSegmentSettings.blob.getSprite() !is null)
                {
                    CSpriteLayer@ hook = nextSegmentSettings.blob.getSprite().getSpriteLayer("hook");
                    if (hook !is null)
                    {
                        hook.ResetTransform();
    	                hook.RotateBy(-dir.Angle()+90, Vec2f());
                    }
                }
                else if (nextSegmentSettings.blob.getSprite() !is null)
                {
                    DrawLine(nextSegmentSettings.blob.getSprite(), blobPos, distance / 4, -dir.Angle(), true);
                }

                nextSegmentSettings.Update();
            }
        }
    }
    void CarryHook(Vec2f pos) // wind up rope when grabbed hook
    {
        this.blob.setPosition(pos);
        CBlob@ _prevSegment = this.prevSegment;
        if (_prevSegment is null) return;
        Rope@ prevSegmentSettings;
        if (_prevSegment.get("RopeSettings", @prevSegmentSettings))
        {
            prevSegmentSettings.CarryHook(pos);
        }
    }
    void SetCarrier(CBlob@ _carry)
    {
        @this.leader = @_carry;
        if (this.leader !is null)
            this.leaderid = this.leader.getNetworkID();
        else this.leaderid = 0;
        CBlob@ _nextSegment = this.nextSegment;
        if (_nextSegment is null) return;
        Rope@ nextSegmentSettings;
        if (_nextSegment.get("RopeSettings", @nextSegmentSettings))
        {
            nextSegmentSettings.SetHooked(@this.leader);
        }
    }
    void SetHooked(CBlob@ _hooked)
    {
        @this.hooked = @_hooked;
        if (hooked !is null)
            this.hookedid = this.hooked.getNetworkID();
        else this.hookedid = 0;
        CBlob@ _prevSegment = this.prevSegment;
        if (_prevSegment is null) return;
        Rope@ prevSegmentSettings;
        if (_prevSegment.get("RopeSettings", @prevSegmentSettings))
        {
            prevSegmentSettings.SetHooked(@this.hooked);
        }
    }
    void DrawLine(CSprite@ this, Vec2f startPos, f32 length, f32 angle, bool flip)
    {
    	CSpriteLayer@ chain = this.getSpriteLayer("chain");

        if (chain is null) return;
    	chain.SetVisible(true);
    
    	chain.ResetTransform();
    	chain.ScaleBy(Vec2f(1.0f, 1.0f));
    	chain.TranslateBy(Vec2f(length * 2.0f, 0.0f));
    	chain.RotateBy(angle + (flip ? 180 : 0), Vec2f());
    }
};