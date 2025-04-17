#include "Knocked.as";
#include "RunnerCommon.as";
#include "Hitters.as";

const u32 update_rate = 30;
const f32 lerp_overdosing = 0.2f;

const f32 slowness = 1.0f;
const f32 max_slowness = 2.0f;

const f32 self_dot = 2.0f;
const f32 max_self_dot = 2.5f;
const f32 self_dot_rate = 30;
const f32 self_dot_damage = 0.25f;
const f32 self_dot_damage_random = 0.25f;

const f32 vision = 3.0f;
const f32 max_vision = 4.0f;

const f32 stun = 4.0f;
const f32 max_stun = 5.0f;
const f32 max_stun_chance = 50;
const f32 stun_rate = 30;
const f32 min_stun_time = 5;
const f32 max_stun_time = 90;

void onTick(CBlob@ this)
{
    if (this.getTickSinceCreated() % update_rate == 0)
    {
        UpdateStatus(this);
    }

    f32 overdosing = this.get_f32("overdosing");
    if (overdosing <= slowness) return;
    
    bool my_p = this.isMyPlayer();
    bool server = isServer();
    bool my_p_or_server = my_p || server;

    if (my_p_or_server && overdosing > slowness) // slowing down from 1.0f to 2.0f
    {
        RunnerMoveVars@ moveVars;
        if (this.get("moveVars", @moveVars))
        {
            f32 factor = Maths::Clamp((overdosing - slowness) / (max_slowness - slowness), 0.0f, 1.0f);
            moveVars.walkFactor *= 1.0f - factor * 0.5f;
            moveVars.jumpFactor *= 1.0f - factor * 0.33f;
        }
    }

    if (server && overdosing > self_dot) // self dot from 2.0f to 2.5f
    {
        if (this.getTickSinceCreated() % self_dot_rate == 0)
        {
            f32 factor = Maths::Clamp((overdosing - self_dot) / (max_self_dot - self_dot), 0.0f, 1.0f);
            this.server_Hit(this, this.getPosition(), Vec2f(0, 0), factor * self_dot_damage + XORRandom(self_dot_damage_random * 100) / 100.0f, Hitters::fall, true);
        }
    }

    if (my_p && overdosing > vision) // vision from 3.0f to 4.0f
    {
        f32 factor = Maths::Clamp((overdosing - vision) / (max_vision - vision), 0.0f, 1.0f);
        
        CCamera@ camera = getCamera();
        if (camera !is null)
        {
            camera.targetDistance = Maths::Lerp(camera.targetDistance, 1.0f + factor * 1.0f, 0.25f);
        }
    }

    if (overdosing > stun) // stun from 4.0f to 5.0f
    {
        if (this.getTickSinceCreated() % stun_rate == 0)
        {
            f32 factor = Maths::Clamp((overdosing - stun) / (max_stun - stun), 0.0f, 1.0f);
            if (XORRandom(100) < max_stun_chance * factor)
            {
                SetKnocked(this, Maths::Max(min_stun_time, max_stun_time * factor));
            }
        }
    }
}

const string[] scripts = {
    "Drunk_Effect.as"
    "Fiksed.as",
    "Dominoed.as",
    "Stimed.as",
    "Propeskoed.as",
    "Babbyed.as",
    "Bobomaxed.as",
    "Crak_Effect.as",
    "Paxilon_Effect.as",
    "Sturded.as",
    "Foofed.as",
    "Dew_Effect.as"
};

const f32[][] drug_weights = { // min (has script), max, drug max effect, formula is clamp(max * drug max effect, min, max)
    {0.0f,  2.0f, 50.0f}, // Drunk_Effect
    {0.25f, 0.5f, 4.0f}, // Fiksed
    {1.0f,  1.0f, 5.0f}, // Dominoed
    {1.0f,  3.0f, 12.0f}, // Stimed
    {1.0f,  1.0f, 1.0f}, // Propeskoed
    {-0.5f, -1.0f, 5.0f}, // Babbyed
    {-0.5f, -1.0f, 1.0f}, // Bobomaxed
    {1.0f,  1.5f, 2.0f}, // Crak_Effect
    {-1.5f, -3.0f, 2.0f}, // Paxilon_Effect
    {0.2f,  0.8f, 6.0f} // Sturded
};

const string[] effects = {
    "drunk_effect",
    "fiksed",
    "dominoed",
    "stimed",
    "propeskoed",
    "babbyed",
    "bobomaxed",
    "crak_effect",
    "paxilon_effect",
    "sturded"
};

bool UpdateStatus(CBlob@ this)
{
    f32 weight = 0;
    bool has_any_effect = false;

    for (uint i = 0; i < effects.length(); i++)
    {
        bool has_current_script = this.hasScript(effects[i]);
        has_any_effect = has_current_script;

        if (has_current_script)
        {
            f32 factor = this.get_f32(effects[i]) / drug_weights[i][2];
            f32 min = drug_weights[i][0];
            f32 max = drug_weights[i][1];
            if (max < min)
            {
                f32 temp = min;
                min = max;
                max = temp;
            }
            weight += Maths::Clamp(drug_weights[i][1] * factor, min, max);
        }
    }

    this.set_f32("overdosing", Maths::Lerp(this.get_f32("overdosing"), weight, lerp_overdosing));
    return weight > 0;
}