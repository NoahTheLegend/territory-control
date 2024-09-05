
class GramophoneRecord
{
	string name;
	string filename;
	f32 volume;

	GramophoneRecord(string name, string filename)
	{
		this.volume = 1.0f;
		this.name = name;
		this.filename = filename;
	}

	GramophoneRecord(string name, string filename, f32 volume)
	{
		this.name = name;
		this.filename = filename;
		this.volume = volume;
	}
};

const GramophoneRecord@[] records =
{
	GramophoneRecord("Mountain King", "Disc_MountainKing.ogg"),//0
	GramophoneRecord("Avignon", "Disc_Avignon.ogg"),//1
	GramophoneRecord("Liberty Bell March", "Disc_LibertyBellMarch.ogg"),//2
	GramophoneRecord("It is a Mystery", "Disc_Mystery.ogg"),//3
	GramophoneRecord("No Hushing", "Disc_NoHushing.ogg"),//4
	GramophoneRecord("Sacred War", "Disc_SacredWar.ogg"),//5
	GramophoneRecord("As The Years Go Passing", "Disc_AsTheYearsGoPassing.ogg"),//6
	GramophoneRecord("Maple Leaf", "Disc_MapleLeaf.ogg"),//7
	GramophoneRecord("Drunken Sailor", "Disc_DrunkenSailor.ogg"),//8
	GramophoneRecord("Suite Punta del Este", "Disc_SuitePuntaDelEste.ogg"),//9
	GramophoneRecord("Fly Me to the Moon", "Disc_FlyMeToTheMoon.ogg"),//10
	GramophoneRecord("Shakin' All Over", "Disc_ShakinAllOver.ogg"),//11
	GramophoneRecord("Welcome to My Lair", "Disc_WelcomeToMyLair.ogg"),//12
	GramophoneRecord("Viva Las Vegas", "Disc_VivaLasVegas.ogg"),//13
	GramophoneRecord("Daddy Cool", "Disc_DaddyCool.ogg"),//14
	GramophoneRecord("Odd Couple", "Disc_OddCouple.ogg"),//15
	GramophoneRecord("Bandit Radio", "Disc_Bandit.ogg"),//16
	GramophoneRecord("Let the Sunshine in", "Disc_LetTheSunshineIn.ogg"),//17
	GramophoneRecord("Tea for Two", "Disc_TeaForTwo.ogg"),//18
	GramophoneRecord("Keep on Running", "Disc_KeepOnRunning.ogg"),//19
	GramophoneRecord("Big Iron", "Disc_BigIron.ogg"),//20
	GramophoneRecord("Metallic Monks", "Disc_MetallicMonks.ogg"),//21
	GramophoneRecord("Fortunate Son", "Disc_FortunateSon.ogg"),//22
	GramophoneRecord("Money", "Disc_Money.ogg"),//23
	GramophoneRecord("A Man Who Resembles The Dark Side of Moon", "Disc_Moon.ogg"),//24
	GramophoneRecord("7 Year Bitch", "Disc_7YearBitch.ogg"),//25
	GramophoneRecord("Homeward Bound", "Disc_HomewardBound.ogg"),//26
	GramophoneRecord("Carry on Wayward Son", "Disc_CarryOnWaywardSon.ogg"),//27
	GramophoneRecord("Pirate Tavern", "Disc_PirateTavern.ogg"),
	GramophoneRecord("Famous Opera", "Disc_Opera.ogg", 1.5f),
	GramophoneRecord("II Magnifico Cornuto (M11)", "Disc_II-Magnifico-Cornuto(M11).ogg"),
	GramophoneRecord("Circus Ambience", "Disc_CircusMusic.ogg"),
	GramophoneRecord("Luftwaffe Anthem", "Disc_LuftwaffeAnthem.ogg"),
	GramophoneRecord("Erica", "Disc_Erica.ogg", 2.5f),
	GramophoneRecord("Wir Sind Des Geyers Schwarzer Haufen", "Disc_WirSindDesGeyersSchwarzerHaufen.ogg", 2.25f),
	GramophoneRecord("Wo Alle Strassen Enden", "Disc_WoAlleStrassenEnden.ogg"),
	GramophoneRecord("Arbeiter, Bauern, nehmt die Gewehre", "Disc_ArbeiterBauernnehmtdieGewehr.ogg"),
	GramophoneRecord("Марш речников - March of Rivermen | Leonid Kostritsa", "Disc_March_Rechnikov-March_of_Rivermen.ogg", 0.9f),
	GramophoneRecord("Потому, потому что мы - пилоты - Because we are pilots | Leonid Kostritsa", "Disc_Potomu_chto_mi_-_piloti-Because_we_are_-_pilots.ogg", 0.9f),
	GramophoneRecord("Вернулся я на родину - I'm back to my homeland | Leonid Kostritsa", "Disc_Vernuls'a_ya_na_rodinu-Returned_to_my_homeland.ogg"),
	GramophoneRecord("J'aime L'oignon", "Disc_JaimeLoignon.ogg"),
	GramophoneRecord("Bella Ciao", "Disc_BellaCiao.ogg"),
	GramophoneRecord("Warszawianka", "Disc_Warszawianka.ogg"),
	GramophoneRecord("Deus Pátria Rei", "Disc_DeusPatriaRei.ogg"),
	GramophoneRecord("Kitasakaba", "Disc_Kitasakaba.ogg"),
	GramophoneRecord("Battotai - Imperial Japanese Army March", "Disc_Battotai.ogg"),
	GramophoneRecord("Super Idol", "SUPER_IDOL!!11!!!1.ogg"),
	GramophoneRecord("Red Sun in The Sky", "Disc_RedSunInTheSky.ogg", 1.5f),
	GramophoneRecord("Puppy Love", "Disc_PuppyLove.ogg", 1.5f),
	GramophoneRecord("Moyuru ōzora - Burning sky", "Disc_MoyuruOzora.ogg"),
	GramophoneRecord("Cannon Fodder Intro", "Disc_CannonFodderIntro.ogg", 1.5f),
	GramophoneRecord("Devil's Lab ", "Disc_DevilsLab.ogg"),
	//GramophoneRecord("Against The Odds", "Disc_AgainstTheOdds.ogg"),
	GramophoneRecord("Guillaume David - Caestus Metalican (W40k)", "Disc_CaestusMetalican.ogg", 2.0f),
	GramophoneRecord("Guillaume David - Noosphere (W40k)", "Disc_Noosphere.ogg", 1.5f),
	GramophoneRecord("Johny", "Disc_Johny.ogg", 1.5f),
	GramophoneRecord("Lucky Lucky Lucky Me", "Disc_LuckyLuckyLuckyMe.ogg", 3.0f),
	GramophoneRecord("A man without love", "Disc_AManWithoutLove.ogg", 1.75f),
	GramophoneRecord("Gimme Gimme Gimme!", "Disc_GimmeGimmeGimme.ogg", 2.0f),
	GramophoneRecord("Crapa Pelada", "Disc_CrapaPelada.ogg", 1.0f),
	GramophoneRecord("Boss Fight", "Disc_Cube.ogg"),
	GramophoneRecord("Megalovania", "Disc_Megalovania.ogg", 1.25f),
	GramophoneRecord("Beethoven - Moonlight Sonata", "Disc_BeethovenMoonlightSonata.ogg"),
	GramophoneRecord("Beethoven - Symphony No. 5", "Disc_BeethovenSymphony5.ogg", 1.5f),
	GramophoneRecord("Tchaikovsky - Nutcracker", "Disc_TchaikovskyNutcraker.ogg", 1.5f),
	GramophoneRecord("Tchaikovsky - Swan Lake", "Disc_TchaikovskySwanLake.ogg", 1.5f),
	GramophoneRecord("Vivaldi - The Four Seasons No. 4", "Disc_VivaldiTheFourSeasonsN4.ogg", 1.75f),
	GramophoneRecord("Chopin - Nocturne No. 2", "Disc_ChopinNocturneN2.ogg", 1.75f),
	GramophoneRecord("Handel - Andante", "Disc_HandelAndante.ogg", 1.5f),
	GramophoneRecord("Bach - Toccata and Fugue", "Disc_BachToccataAndFugue.ogg", 1.33f),
	GramophoneRecord("Strauss - An Der Schönen", "Disc_StraussAnDerSchonen.ogg", 1.5f),
	GramophoneRecord("Beethoven - Fur Elise", "Disc_BeethovenFurElise.ogg"),
	GramophoneRecord("Dmitry Shostakovich - Waltz No. 2", "Disc_ShostakovichWaltzN2.ogg")
};

// type !disc NUMBER_OF_TRACK_FROM_LIST_ABOVE
// example: !disc 0 will give you mountain king