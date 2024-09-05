
void LoadDefaultMapLoaders()
{
	printf("############ GAMEMODE " + sv_gamemode);
	RegisterFileExtensionScript("Scripts/MapLoaders/LoadTCPNG.as", "png");
}
