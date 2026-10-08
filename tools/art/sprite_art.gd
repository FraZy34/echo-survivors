extends RefCounted
## Pixel art du jeu, dessiné à la main sous forme de grilles (voir pixel_canvas.gd pour la palette).
## Les personnages sont découpés en « haut du corps » + « jambes » pour composer les animations.

# --- Héros -------------------------------------------------------------------------------

const HERO := [
	"....rr....",
	"...rrr....",
	"..GGGGGG..",
	".GwGGGGGg.",
	".GGssssGg.",
	".gskssksg.",
	"..ssssss..",
	".bbGbbGbb.",
	"sbbbyybbbs",
	"sbbbbbbbbs",
	".BBBBBBBB.",
]
const HERO_LEGS := {
	"idle": ["..nn..nn..", "..KK..KK.."],
	"stride_a": [".nn...nn..", "KK.....KK."],
	"pass": ["...nn.nn..", "...KK.KK.."],
	"stride_b": ["..nn...nn.", "..KK....KK"],
}

# --- L'Écho (mage spectral) ------------------------------------------------------------

const ECHO := [
	".....p....",
	"....pp....",
	"....ppv...",
	"...ppppp..",
	"..pppyppp.",
	".PPPPPPPPP",
	"..wssssw..",
	"..skssks..",
	"..wwwwww..",
	".cwwwwwwc.",
	"cccwwwwccc",
	".cCccccCc.",
]
const ECHO_TAILS := [
	["..cc..cc..", "...c...c.."],
	["...cc..cc.", "..c...c..."],
	["..cc..cc..", "..c...c..."],
	[".cc..cc...", "..c...c..."],
]

# --- Monstres de la forêt ---------------------------------------------------------------

const RAT := [
	"..........SS..",
	"....ggggggSg..",
	"...ggggggggkg.",
	"..gggGGGGggggm",
	"mmggggggggggg.",
]
const RAT_LEGS := [["....S.S...S.S."], [".....SS....SS."]]

const BAT := [
	[
		"p............p",
		"pp...P..P...pp",
		"ppp..PPPP..ppp",
		".pppPrPPrPppp.",
		"..ppPPPPPPpp..",
		".....PwwP.....",
	],
	[
		".....P..P.....",
		".....PPPP.....",
		"...pPrPPrPp...",
		".ppppPPPPpppp.",
		"ppp..PwwP..ppp",
		"pp..........pp",
	],
]

const SPIDER := [
	[
		".K.........K.",
		"..K..KKK..K..",
		"...KKgKKKK...",
		"KK.KKKKKKK.KK",
		"..KKrKKKrKK..",
		"KK.KKKKKKK.KK",
		"...K.KKK.K...",
		"..K.......K..",
	],
	[
		"..K.......K..",
		".K...KKK...K.",
		"..KKKgKKKKK..",
		".KKKKKKKKKKK.",
		"K.KKrKKKrKK.K",
		".KKKKKKKKKKK.",
		"..KK.KKK.KK..",
		".K.........K.",
	],
]

const SLIME := [
	[
		"....llll....",
		"..llllllll..",
		".lwwllllllll",
		".lwllllllll.",
		"lllkllllklll",
		"llllllllllll",
		"lllllEElllll",
		"eellllllllee",
		".eeeeeeeeee.",
	],
	[
		"...llllll...",
		".llwwllllll.",
		"llwllllllll.",
		"lllkllllklll",
		"lllllEEllll.",
		"eellllllllee",
		"eeeeeeeeeeee",
	],
]

const BANDIT := [
	"...eeee...",
	"..eeeeeee.",
	"..ssssss..",
	"..skssks..",
	"..EEEEEE..",
	".nnnnnnnn.",
	"snnnYnnnns",
	"snnnnnnnns",
	".NNNNNNNN.",
]
const BANDIT_LEGS := [["..NN..NN..", "..KK..KK.."], [".NN...NN..", "KK.....KK."]]

const CYCLOPS := [
	"...tttttt...",
	"..tttttttt..",
	".ttwwwwwwtt.",
	".ttwwkkwwtt.",
	".ttwwkkwwtt.",
	".tttwwwwttt.",
	".ttSkkkkStt.",
	"..ttSwwStt..",
	"SttttttttttS",
	"tt.tttttt.tt",
	"tt.nnnnnn.tt",
	"...nNnnNn...",
]
const CYCLOPS_LEGS := [["...tt..tt...", "..NNN..NNN.."], ["..tt....tt..", ".NNN....NNN."]]

# --- Monstres des neiges ------------------------------------------------------------------

const GHOST := [
	"...wwww...",
	".wwwwwwww.",
	".wkkwwkkw.",
	"wwkkwwkkww",
	"wwwwwwwwww",
	"wwwwkkwwww",
	"Gwwwwwwwww",
	"GGwwwwwwwG",
	"GGGwwwwwGG",
]
const GHOST_TAILS := [["G.GG.GGw.G"], [".GG.GG.GG."]]

const SKIER := [
	[
		"....rrrw....",
		"...rrrrr....",
		"...ssssss...",
		"...cCccCc...",
		"...ssssss...",
		"..oooooooo..",
		".soooYoooos.",
		".g.oooooo.g.",
		".g.BBBBBB.g.",
		".g.BB..BB.g.",
		"KKKKK..KKKKK",
	],
	[
		"....rrrw....",
		"...rrrrr....",
		"...ssssss...",
		"...cCccCc...",
		"...ssssss...",
		"..oooooooo..",
		"soooooYooooo",
		"g..oooooo..g",
		"g..BBBBBB..g",
		"g..BB..BB..g",
		"KKKKK..KKKKK",
	],
]

const WOLF := [
	"..........g.g.",
	".........gggg.",
	"g........gGkGG",
	".ggggggggGGGGk",
	"..GGGGGGGGGGg.",
	"..GwwwwwwwGG..",
]
const WOLF_LEGS := [["..g.g....g.g..", "..g.g....g.g.."], ["...gg....gg...", "..g..g..g..g.."]]

const SNOWMAN := [
	[
		"....KKK....",
		"....KKK....",
		"...KKKKK...",
		"...wwwww...",
		"..wwkwkww..",
		"..wwwoowi..",
		"...wwwww...",
		"..rrrrrrr..",
		"n.wwwkwww.n",
		".nwwwwwwwn.",
		"..wwwkwww..",
		".wwwwwwwww.",
		".iwwwwwwwi.",
		"..iiiiiii..",
	],
	[
		"....KKK....",
		"....KKK....",
		"...KKKKK...",
		"...wwwww...",
		"..wwkwkww..",
		"..wwwoowi..",
		"n..wwwww..n",
		".nrrrrrrrn.",
		"..wwwkwww..",
		"..wwwwwww..",
		"..wwwkwww..",
		".wwwwwwwww.",
		".iwwwwwwwi.",
		"..iiiiiii..",
	],
]

const YETI := [
	"...wwwwww...",
	"..wwwwwwwww.",
	".wwIIIIIIww.",
	".wIKIIIIKIw.",
	".wIIIIIIIIw.",
	".wwIkkkkIww.",
	"wwwwIwwIwwww",
	"wwwwwwwwwwww",
	"iwwwwwwwwwwi",
	"iiwwwwwwwwii",
	".iwwwwwwwwi.",
]
const YETI_ROAR := [
	"...wwwwww...",
	"..wwwwwwwww.",
	".wwIIIIIIww.",
	".wIKIIIIKIw.",
	".wIIkkkkIIw.",
	".wwkrrrrkww.",
	"wwwwkwwkwwww",
	"wwwwwwwwwwww",
	"iwwwwwwwwwwi",
	"iiwwwwwwwwii",
	".iwwwwwwwwi.",
]
const YETI_LEGS := [["..ww....ww..", ".iii....iii."], ["...ww..ww...", "..iii.iii..."]]

# --- Monstres de la crypte ------------------------------------------------------------------

const WRAITH := [
	"...gggg...",
	"..gggggg..",
	".ggKKKKgg.",
	".gKcKKcKg.",
	".gKKKKKKg.",
	"gggKKKKggg",
	"gggggggggg",
	"Gggggggggg",
	".gggggggg.",
]
const WRAITH_TAILS := [[".g.gg.gg.g"], ["..gg.gg.gg"]]

const CULTIST := [
	"...PPPP.....",
	"..PPPPPP..v.",
	"..PKKKKP.vmv",
	"..PKrKrP..v.",
	"..PPKKPP..n.",
	".PPPPPPPPsn.",
	"PPpPPPPpP.n.",
	"PPpPPPPpP.n.",
	".PPpPPpPP.n.",
	".PPPPPPPP.n.",
]
const CULTIST_LEGS := [["..PP..PP..n."], [".PP....PP.n."]]

const CRAB := [
	[
		".oo......oo.",
		"o.oo....oo.o",
		"oo.o....o.oo",
		".ooo....ooo.",
		"...oooooo...",
		"..oyyooyyo..",
		".oooooooooo.",
		"oRooooooooRo",
		".RoRRRRRRoR.",
		"R.R.R..R.R.R",
	],
	[
		"..oo....oo..",
		".ooo....ooo.",
		".oo......oo.",
		"..oo....oo..",
		"...oooooo...",
		"..oyyooyyo..",
		".oooooooooo.",
		"oRooooooooRo",
		".RoRRRRRRoR.",
		".R.R.RR.R.R.",
	],
]

const DEMON := [
	"x..........x",
	"xx........xx",
	".xx.rrrr.xx.",
	"..rrrrrrrr..",
	".rrRyrryRrr.",
	".rrrrrrrrrr.",
	".rrkwkwkwrr.",
	"..rrrrrrrr..",
	"rrRrrrrrrRrr",
	"rr.rrmmrr.rr",
	"r..rrmmrr..r",
	"...rRrrRr...",
]
const DEMON_LEGS := [["...rr..rr...", "..RRR..RRR.."], ["..rr....rr..", ".RRR....RRR."]]

# --- Projectiles, objets et icônes ----------------------------------------------------------

const ITEMS := {
	"dagger": [
		"..w..", ".wGG.", ".wGg.", ".wGg.", ".wGg.", ".wGg.", "YyyyY", "..n..", "..N..", "..Y..",
	],
	"arrow": ["rr.......g..", ".rrnnnnnnGGG", "rr.......g.."],
	"axe": [
		".GG...GG.", "GwG.n.GwG", "GGGGnGGGG", "GgG.n.GgG", ".gg.n.gg.", "....n....", "....n....", "....N....",
	],
	"bomb": [
		"......y.", ".....yoy", "....n.y.", "..KKnK..", ".KKKKKK.", "KgKKKKKK", "KgKKKKKK", "KKKKKKKK",
		".KKKKKK.", "..KKKK..",
	],
	"orb": ["..GwwG..", ".GwwwwG.", "GwwwwwwG", "GwwwwwGG", "GGwwwGGG", ".GGGGGg.", "..gggg.."],
	"gem_small": ["..c..", ".cwb.", "cwbbB", ".bbB.", "..B.."],
	"gem_mid": ["...l...", "..lwl..", ".lwlee.", "lwleeeE", ".leeeE.", "..eeE..", "...E..."],
	"gem_big": ["..rrrr..", ".rwwrrR.", "rwrrrrRR", "RrrrrRRR", ".RrrRRR.", "..RRRR.."],
	"potion": ["..NN..", "..nn..", "..GG..", ".GrrG.", "GrwrrG", "GrrrrG", "GRrrRG", ".GGGG."],
	"bell": ["...n...", "..yyy..", ".ywyyy.", ".ywyyy.", ".yyyyY.", "yyyyyYY", "YYYYYYY", "...Y..."],
	"meat": [".....nnn", "...nnntn", "..nntttn", ".nntttnn", ".nttnnn.", "x.nnn...", "xx......"],
	"chest": [".nnnnnnnn.", "nNNNNNNNNn", "nnnnyynnnn", "NNNNyyNNNN", "nnnnnnnnnn", "nnnnnnnnnn", "NNNNNNNNNN"],
	"bow": [
		"..nn......", ".n..G.....", "n...G.....", "n...G.....", "rrnnnnnnGG", "n...G.....", "n...G.....",
		".n..G.....", "..nn......",
	],
	"flame": [
		"....o....", "...oo....", "..ooo..o.", "..oyoo.o.", ".ooyyooo.", ".oyyyyoo.", "ooyywyyoo",
		"oyywwwyyo", ".oyywyyo.", "..ooooo..",
	],
	"thunder_staff": ["......yy", ".....yy.", "....yyyy", "......y.", ".....y..", "...nn...", "..nn....", ".nn.....", "nn......"],
	"orb_wand": [".....pp.", "....pvwp", "....pvvp", ".....pp.", "....n...", "...n....", "..n.....", ".n......", "n......."],
	"sword": [
		"........wG", ".......wG.", "......wG..", ".....wG...", "....wG....", "y..wG.....", ".yyG......",
		".yy.......", "n..y......",
	],
	"heart": [".rr..rr.", "rwrrrrrr", "rwrrrrrR", "rrrrrrRR", ".rrrrRR.", "..rrRR..", "...RR..."],
	"cross": ["..lll..", "..lwl..", "lllwlll", "lwwwwwl", "lllwlll", "..lwl..", "..lll.."],
	"shield": ["GGGGGGG", "GwbbbbG", "GbbybbG", "GbyyybG", "GbbybbG", ".GbbbG.", "..GGG.."],
	"hourglass": ["nnnnnnn", ".wyyyw.", "..wyw..", "...y...", "..w.w..", ".wyyyw.", "nnnnnnn"],
	"boot": ["...nnn...", "ww.nnn...", ".wwnnn...", "..wnnn...", "...nnnnn.", "...nnnnnn", "...NNNNNN"],
	"expand": ["yy....yy", "y......y", "..y..y..", "...yy...", "...yy...", "..y..y..", "y......y", "yy....yy"],
	"feather": ["......w", ".....ww", "....wwG", "...wwG.", "..wwG..", ".wwG...", "nG.....", "n......"],
	"candle": ["...y...", "..yoy..", "...o...", "..www..", "..wGw..", "..www..", "..wGw..", ".nnnnn."],
	"magnet": ["GG...GG", "rr...rr", "rr...rr", "rr...rr", "rrr.rrr", ".rrrrr.", "..rrr.."],
	"book": ["bbbbbbb.", "bwwwwwbb", "bwGGGwbb", "bwwwwwbb", "bwGGGwbb", "bwwwwwbb", "bbbbbbbb", ".BBBBBBB"],
	"triple": ["w..w..w", "G..G..G", "G..G..G", "G..G..G", "y..y..y", "n..n..n"],
	"mirror": ["..YYY..", ".YcwcY.", "YccwccY", "YcccccY", "YccCccY", ".YcCcY.", "..YYY..", "...Y...", "..YYY.."],
	"pulse": [
		"...cccc...", "..c....c..", ".c..CC..c.", "c..C..C..c", "c..C.wC..c", ".c..CC..c.", "..c....c..", "...cccc...",
	],
	"skull": [".xxxxx.", "xxxxxxx", "xkkxkkx", "xkkxkkx", "xxxkxxx", ".xxxxx.", ".x.x.x."],
}

# --- Décors ------------------------------------------------------------------------------------

const DECOR := {
	"oak": [
		"....eeeee.....", "..eellleeee...", ".eelllleeeee..", ".elllleeeeeEe.", "eellleeeeeeEe.",
		"eeleeeeeeeEEe.", "eeeeeeeeeEEEe.", ".eeeeeeeEEEe..", "..EEeeeEEEE...", ".....nnn......",
		".....nnn......", "....nNnnn.....",
	],
	"pine": [
		".....l.....", "....ell....", "...eeell...", "....eel....", "..eeeeell..", ".eeeeeeell.",
		"...eeeel...", "..eeeeeell.", ".eeeeeeeeel", "EEEEeeeeeee", "....nnn....", "....nnn....",
	],
	"bush": ["...eeee...", ".eellleee.", "eellllleee", "eleeeeeeEe", "eeeeeeeEEe", ".EEEEEEEE."],
	"mushroom": ["..rrrr......", ".rwrrwr.....", "rrrrrrrr.rr.", "..xxxx..rwrr", "..xxxx...x..", "..xxxx...x.."],
	"flowers": [".y.....m..", "yoy...mwm.", ".y..b..m..", ".e.bwb.e..", ".e..b..e..", "ee..e.ee.."],
	"rock": ["...gggg...", ".gGGGggg..", "gGGgggggg.", "gggggggKgg", ".KKKKKKKK."],
	"stump": [".nnnnnn.", "nttttttn", "ntnnnntn", "nttttttn", "nNnnnnNn", "NNnNNnNN"],
	"dead_tree": [
		"n....n....", ".n..n..n..", "..n.n.n...", "...nnn..n.", "n...nn.n..", ".n..nnn...", "..nnnn....",
		"....nn....", "....nn....", "...nNnn...",
	],
	"ice_rock": ["...iiii...", ".iIwiiiI..", "iwwiiIIII.", "iiiIIIIzII", ".zzzzzzzz."],
	"snow_pile": ["...www....", ".wwwwwww..", "wwwwwwiwww", "iiwwwiiiii"],
	"tomb": ["..GGGG..", ".GGGGGG.", "GGGgGGGg", "GGgggGGg", "GGGgGGGg", "GGGgGGGg", "GGGGGGgg", "gggggggg", "KKKKKKKK"],
	"stone_cross": ["...GG...", "...GG...", ".GGGGGG.", ".gggGGg.", "...GG...", "...Gg...", "...Gg...", "..gggg.."],
	"bones": ["..xxxx....", ".xxxxxx...", ".xkxxkx...", ".xxxxxx.x.", "..xxxx..xx", "x.x.x..xx.", ".xxxxxxx..", "x......x.."],
	"candle": ["...y...", "..yoy..", "...y...", "..xxx..", "..xxx..", "..xxx..", ".nnnnn.", "nnnnnnn"],
	"pillar": ["..G.G...", ".GGGGG..", ".GGgGg..", ".GGgGg..", ".GGgGg..", ".GGgGg..", "gggggggg"],
	"urn": ["..nnnn..", "...nn...", "..nnnn..", ".nnttnn.", "nnttttnn", "nntyyynn", "nnttttnn", ".nnnnnn.", "..NNNN.."],
}
