extends SceneTree
## Génère TOUS les assets du jeu à partir de code : planches de sprites, tuiles de décor,
## effets sonores et musiques. Aucun fichier graphique ou sonore externe n'est utilisé.
##
## Utilisation (depuis le dossier du projet) :
##   godot --headless --path . --script res://tools/generate_assets.gd
##
## Produit dans assets/ : sprites/*.png, audio/*.wav, music/*.wav et sprites/manifest.json
## (nom de chaque sprite → indice de tuile, utile pour remplir les ressources .tres).

const Canvas := preload("res://tools/art/pixel_canvas.gd")
const Art := preload("res://tools/art/sprite_art.gd")
const Floors := preload("res://tools/art/floor_painter.gd")
const Bank := preload("res://tools/audio/sound_bank.gd")

var manifest := {}


func _init() -> void:
	for dir in ["res://assets/sprites", "res://assets/audio", "res://assets/music"]:
		DirAccess.make_dir_recursive_absolute(dir)
	_characters()
	_items()
	_tiles()
	_sounds()
	var file := FileAccess.open("res://assets/sprites/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t", false))
	file.close()
	print("Assets générés.")
	quit()


func _record(sheet: String, canvas: Canvas) -> void:
	canvas.save("res://assets/sprites/%s.png" % sheet)
	manifest[sheet] = canvas.names


# --- Personnages ------------------------------------------------------------------------------

func _with_legs(top: Array, legs: Array) -> Array:
	return top + legs


func _characters() -> void:
	var c := Canvas.new(8, 12)
	# Héros : immobile + cycle de marche en 4 temps.
	var legs: Dictionary = Art.HERO_LEGS
	c.add("hero_idle", _with_legs(Art.HERO, legs.idle))
	c.add("hero_walk_0", _with_legs(Art.HERO, legs.stride_a))
	c.add("hero_walk_1", _with_legs(Art.HERO, legs.pass))
	c.add("hero_walk_2", _with_legs(Art.HERO, legs.stride_b))
	c.add("hero_walk_3", _with_legs(Art.HERO, legs.pass))
	# L'Écho : 4 images de flottement.
	for i in Art.ECHO_TAILS.size():
		c.add("echo_%d" % i, _with_legs(Art.ECHO, Art.ECHO_TAILS[i]))

	# Forêt
	for i in 2:
		c.add("rat_%d" % i, _with_legs(Art.RAT, Art.RAT_LEGS[i]))
	for i in 2:
		c.add("bat_%d" % i, Art.BAT[i], "center", {"p": "n", "P": "N"})
	for i in 2:
		c.add("spider_%d" % i, Art.SPIDER[i], "center")
	for i in 2:
		c.add("slime_%d" % i, Art.SLIME[i])
	for i in 2:
		c.add("bandit_%d" % i, _with_legs(Art.BANDIT, Art.BANDIT_LEGS[i]))
	for i in 2:
		c.add("cyclops_%d" % i, _with_legs(Art.CYCLOPS, Art.CYCLOPS_LEGS[i]))

	# Neige
	for i in 2:
		c.add("ice_ghost_%d" % i, _with_legs(Art.GHOST, Art.GHOST_TAILS[i]), "bottom", {"w": "i", "G": "I"})
	for i in 2:
		c.add("ice_bat_%d" % i, Art.BAT[i], "center", {"p": "b", "P": "B"})
	for i in 2:
		c.add("skier_%d" % i, Art.SKIER[i])
	for i in 2:
		c.add("wolf_%d" % i, _with_legs(Art.WOLF, Art.WOLF_LEGS[i]))
	for i in 2:
		c.add("snowman_%d" % i, Art.SNOWMAN[i])
	for i in 2:
		c.add("yeti_%d" % i, _with_legs(Art.YETI, Art.YETI_LEGS[i]))
	# Le Grand Yéti : yeux rouges, fourrure plus sombre et cornes.
	var boss_fur := {"K": "r", "I": "z", "i": "I"}
	var horns := ["x..........x", "xx.wwwwww.xx"]
	for i in 2:
		c.add("yeti_boss_%d" % i, _with_legs(horns + Art.YETI.slice(1), Art.YETI_LEGS[i]), "bottom", boss_fur)
	c.add("yeti_boss_roar", _with_legs(horns + Art.YETI_ROAR.slice(1), Art.YETI_LEGS[0]), "bottom", boss_fur)

	# Crypte
	for i in 2:
		c.add("wraith_%d" % i, _with_legs(Art.WRAITH, Art.WRAITH_TAILS[i]))
	for i in 2:
		c.add("soul_%d" % i, _with_legs(Art.GHOST, Art.GHOST_TAILS[i]), "bottom", {"w": "l", "G": "e"})
	for i in 2:
		c.add("tomb_spider_%d" % i, Art.SPIDER[i], "center", {"K": "P", "g": "p", "r": "c"})
	for i in 2:
		c.add("cultist_%d" % i, _with_legs(Art.CULTIST, Art.CULTIST_LEGS[i]))
	for i in 2:
		c.add("crab_%d" % i, Art.CRAB[i])
	for i in 2:
		c.add("vampire_%d" % i, Art.BAT[i], "center", {"p": "r", "P": "R", "r": "y"})
	for i in 2:
		c.add("demon_%d" % i, _with_legs(Art.DEMON, Art.DEMON_LEGS[i]))
	_record("characters", c)
	_icon(c, c.names["echo_0"])


## Icône du jeu (128x128) : l'Écho agrandi sur fond nuit.
func _icon(c: Canvas, frame: int) -> void:
	var sprite := c.image.get_region(Rect2i((frame % c.columns) * 16, (frame / c.columns) * 16, 16, 16))
	sprite.resize(112, 112, Image.INTERPOLATE_NEAREST)
	var icon := Image.create_empty(128, 128, false, Image.FORMAT_RGBA8)
	icon.fill(Color("1e1530"))
	icon.blend_rect(sprite, Rect2i(0, 0, 112, 112), Vector2i(8, 4))
	icon.save_png("res://assets/icon.png")


# --- Objets, projectiles, icônes ------------------------------------------------------------

func _items() -> void:
	var c := Canvas.new(8, 8)
	for key: String in Art.ITEMS:
		c.add(key, Art.ITEMS[key], "center")
	# Icônes composées à partir d'autres sprites.
	c.add("echo_face", Art.ECHO.slice(0, 9), "center")
	_record("items", c)


# --- Tuiles de décor (sol + éléments) ---------------------------------------------------------

func _tiles() -> void:
	var forest := Canvas.new(8, 4)
	forest.add_image("floor_plain", Floors.grass("plain", 1))
	forest.add_image("floor_tufts", Floors.grass("tufts", 2))
	forest.add_image("floor_flowers", Floors.grass("flowers", 3))
	forest.add_image("floor_pebbles", Floors.grass("pebbles", 4))
	for key in ["oak", "pine", "bush", "mushroom", "flowers", "rock", "stump"]:
		forest.add(key, Art.DECOR[key])
	_record("tiles_forest", forest)

	var snow := Canvas.new(8, 4)
	snow.add_image("floor_plain", Floors.snow("plain", 5))
	snow.add_image("floor_sparkle", Floors.snow("sparkle", 6))
	snow.add_image("floor_drift", Floors.snow("drift", 7))
	snow.add("snowy_pine", Art.DECOR.pine, "bottom", {"l": "w", "e": "e"})
	snow.add("dead_tree", Art.DECOR.dead_tree)
	snow.add("ice_rock", Art.DECOR.ice_rock)
	snow.add("snow_pile", Art.DECOR.snow_pile)
	snow.add("frozen_bush", Art.DECOR.bush, "bottom", {"l": "w", "e": "I", "E": "z"})
	_record("tiles_snow", snow)

	var crypt := Canvas.new(8, 4)
	crypt.add_image("floor_plain", Floors.crypt("plain", 8))
	crypt.add_image("floor_cracked", Floors.crypt("cracked", 9))
	crypt.add_image("floor_moss", Floors.crypt("moss", 10))
	for key in ["tomb", "stone_cross", "bones", "candle", "pillar", "urn"]:
		crypt.add(key, Art.DECOR[key])
	_record("tiles_crypt", crypt)


# --- Sons et musiques -------------------------------------------------------------------------

func _sounds() -> void:
	var effects := Bank.effects()
	for key: String in effects:
		effects[key].save_wav("res://assets/audio/%s.wav" % key)
	for key: String in Bank.TRACKS:
		Bank.music(Bank.TRACKS[key]).save_wav("res://assets/music/%s.wav" % key)
