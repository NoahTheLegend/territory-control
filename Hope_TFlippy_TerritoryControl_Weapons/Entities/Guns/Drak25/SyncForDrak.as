
void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("sync_heat"))
	{
		bool init = params.read_bool();
		if (!init && isClient())
		{
			f32 heat = params.read_f32();
			this.set_f32("heat", heat);
		}
		if (init && isServer())
		{
			f32 heat = params.read_f32();
			this.set_f32("heat", heat);

			CBitStream params;
			params.write_bool(false);
			params.write_f32(heat);
			this.SendCommand(this.getCommandID("sync_heat"), params);
		}
	}
}