extends RefCounted
## Tuiles de sol procédurales (16x16, raccordables entre elles) pour chaque biome.
## Le bruit est tiré d'un générateur à graine fixe : la génération est reproductible.

const TILE := 16


static func _new_tile(base: Color) -> Image:
	var img := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	return img


static func _speckle(img: Image, rng: RandomNumberGenerator, color: Color, count: int) -> void:
	for i in count:
		img.set_pixel(rng.randi_range(0, TILE - 1), rng.randi_range(0, TILE - 1), color)


# --- Forêt -------------------------------------------------------------------------------------

const GRASS := Color("5aa64e")
const GRASS_DARK := Color("4a9042")
const GRASS_LIGHT := Color("74bf5c")


static func grass(variant: String, seed_value: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var img := _new_tile(GRASS)
	_speckle(img, rng, GRASS_DARK, 22)
	_speckle(img, rng, GRASS_LIGHT, 10)
	match variant:
		"tufts":
			for i in 3:
				var x := rng.randi_range(1, TILE - 3)
				var y := rng.randi_range(2, TILE - 1)
				img.set_pixel(x, y - 1, GRASS_LIGHT)
				img.set_pixel(x + 2, y - 1, GRASS_LIGHT)
				img.set_pixel(x + 1, y, GRASS_DARK)
				img.set_pixel(x, y, GRASS_DARK)
				img.set_pixel(x + 2, y, GRASS_DARK)
		"flowers":
			var colors := [Color("f4f0e8"), Color("f6d44c"), Color("e874b4")]
			for i in 3:
				var x := rng.randi_range(1, TILE - 2)
				var y := rng.randi_range(1, TILE - 2)
				var petal: Color = colors[rng.randi() % colors.size()]
				img.set_pixel(x - 1, y, petal)
				img.set_pixel(x + 1, y, petal)
				img.set_pixel(x, y - 1, petal)
				img.set_pixel(x, y + 1, petal)
				img.set_pixel(x, y, Color("f08c3c"))
		"pebbles":
			for i in 4:
				var x := rng.randi_range(0, TILE - 2)
				var y := rng.randi_range(0, TILE - 2)
				img.set_pixel(x, y, Color("a9a3bb"))
				img.set_pixel(x + 1, y, Color("8e88a0"))
				img.set_pixel(x, y + 1, Color("6e6680"))
	return img


# --- Neige --------------------------------------------------------------------------------------

const SNOW := Color("e6eef9")
const SNOW_SHADE := Color("cfdcee")
const SNOW_DEEP := Color("b8cae2")


static func snow(variant: String, seed_value: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var img := _new_tile(SNOW)
	_speckle(img, rng, SNOW_SHADE, 18)
	match variant:
		"sparkle":
			_speckle(img, rng, Color.WHITE, 8)
			for i in 2:
				var x := rng.randi_range(1, TILE - 2)
				var y := rng.randi_range(1, TILE - 2)
				img.set_pixel(x, y, Color.WHITE)
				img.set_pixel(x - 1, y, Color("f6faff"))
				img.set_pixel(x + 1, y, Color("f6faff"))
		"drift":
			# Petite congère : arc ombré.
			var cx := rng.randi_range(4, TILE - 5)
			var cy := rng.randi_range(5, TILE - 3)
			for dx in range(-4, 5):
				var y := cy + int(absf(dx) * 0.5)
				img.set_pixel(cx + dx, y, SNOW_DEEP)
				img.set_pixel(cx + dx, y - 1, Color.WHITE)
	return img


# --- Crypte -------------------------------------------------------------------------------------

const SLAB := Color("4e3e50")
const SLAB_LIGHT := Color("5e4c60")
const MORTAR := Color("2e2232")


static func crypt(variant: String, seed_value: int) -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var img := _new_tile(SLAB)
	_speckle(img, rng, SLAB_LIGHT, 20)
	_speckle(img, rng, Color("443646"), 14)
	# Joints sur les bords haut et gauche de chaque dalle 8x8 : les tuiles se raccordent.
	for i in TILE:
		img.set_pixel(i, 0, MORTAR)
		img.set_pixel(0, i, MORTAR)
		img.set_pixel(i, 8, MORTAR)
		if i < 8:
			img.set_pixel(8, i, MORTAR)
		else:
			img.set_pixel(4, i, MORTAR)
			img.set_pixel(12, i, MORTAR)
	match variant:
		"cracked":
			var x := rng.randi_range(2, 6)
			var y := 1
			while y < TILE - 1:
				img.set_pixel(x, y, MORTAR)
				x = clampi(x + rng.randi_range(-1, 1), 1, TILE - 2)
				y += 1
		"moss":
			var moss := [Color("3f6a46"), Color("4c7c4e")]
			for i in 16:
				var x := rng.randi_range(0, 9)
				var y := rng.randi_range(6, TILE - 1)
				img.set_pixel(x, y, moss[i % 2])
	return img
