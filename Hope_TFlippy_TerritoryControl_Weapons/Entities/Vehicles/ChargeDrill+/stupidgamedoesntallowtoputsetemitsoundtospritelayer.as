
void onTick(CBlob@ this)
{
	if (isServer() && this.get_u16("id") == 0) this.server_Die();
	CBlob@ amogus = getBlobByNetworkID(this.get_u16("id"));
	if (amogus is null && isServer()) this.server_Die();
	if (amogus !is null && amogus.getName() == "chargedrill") this.setPosition(amogus.getPosition());
}