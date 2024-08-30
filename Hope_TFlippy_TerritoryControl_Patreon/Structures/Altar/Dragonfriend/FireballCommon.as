const f32 fireball_max_power = 1000000.0f;

f32 getFireballPower(CBlob@ this)
{
    f32 power = this.get_f32("deity_power");;
    if (this.getName() == "meteor") power = this.get_f32("power");

    return 1.00f + Maths::Sqrt(Maths::Min(power, fireball_max_power) * 0.00001f);
}