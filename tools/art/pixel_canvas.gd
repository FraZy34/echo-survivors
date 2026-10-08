extends RefCounted
## Planche de sprites 16x16 dessinée à partir de grilles de caractères.
## Chaque caractère est une couleur de la palette ; « . » est transparent.
## Un contour sombre est ajouté automatiquement autour de chaque sprite.

const TILE := 16
const OUTLINE := Color("1a1020")

## Palette commune à tout le jeu (cohérence visuelle).
const PALETTE := {
	"k": Color("1a1020"), "K": Color("3b3346"), "g": Color("6e6680"), "G": Color("a9a3bb"),
	"w": Color("f4f0e8"), "s": Color("f2c49c"), "S": Color("c88c68"), "r": Color("e04850"),
	"R": Color("962c40"), "o": Color("f08c3c"), "y": Color("f6d44c"), "Y": Color("c08c2c"),
	"l": Color("92d65c"), "e": Color("4c9c4a"), "E": Color("2c6440"), "b": Color("4c84dc"),
	"B": Color("2c4894"), "c": Color("84e4f2"), "C": Color("3aa8bc"), "p": Color("a060d4"),
	"P": Color("5c3290"), "v": Color("d4b0f4"), "m": Color("e874b4"), "n": Color("8c5c3a"),
	"N": Color("5a3826"), "t": Color("d4a46c"), "x": Color("ece0c4"), "i": Color("dcecff"),
	"I": Color("9cc0e8"), "z": Color("6c94c4"),
}

var image: Image
var columns: int
var names := {}
var _next := 0


func _init(cols: int, rows: int) -> void:
	columns = cols
	image = Image.create_empty(cols * TILE, rows * TILE, false, Image.FORMAT_RGBA8)


## Ajoute un sprite ; renvoie son indice dans la planche.
## align : "bottom" (personnages posés au sol) ou "center" (objets, projectiles).
## swap : remplacement de couleurs (variantes de palette).
func add(name: String, rows: Array, align := "bottom", swap := {}, outline := true) -> int:
	var index := _next
	_next += 1
	var cell := Vector2i(index % columns, index / columns)
	_blit(cell, rows, align, swap)
	if outline:
		_outline(cell)
	names[name] = index
	return index


## Ajoute une tuile déjà peinte (sol procédural).
func add_image(name: String, tile: Image) -> int:
	var index := _next
	_next += 1
	var cell := Vector2i(index % columns, index / columns)
	image.blit_rect(tile, Rect2i(0, 0, TILE, TILE), cell * TILE)
	names[name] = index
	return index


func save(path: String) -> void:
	var used_rows := ceili(float(_next) / columns)
	var cropped := image.get_region(Rect2i(0, 0, columns * TILE, used_rows * TILE))
	cropped.save_png(path)


func _blit(cell: Vector2i, rows: Array, align: String, swap: Dictionary) -> void:
	var h := rows.size()
	var w := 0
	for row: String in rows:
		w = maxi(w, row.length())
	assert(w <= TILE - 2 and h <= TILE - 2, "Sprite trop grand (%dx%d)" % [w, h])
	var ox := cell.x * TILE + (TILE - w) / 2
	var oy := cell.y * TILE + ((TILE - 1 - h) if align == "bottom" else (TILE - h) / 2)
	for y in h:
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			ch = swap.get(ch, ch)
			image.set_pixel(ox + x, oy + y, PALETTE[ch])


func _outline(cell: Vector2i) -> void:
	var x0 := cell.x * TILE
	var y0 := cell.y * TILE
	var marks: Array[Vector2i] = []
	for y in TILE:
		for x in TILE:
			if image.get_pixel(x0 + x, y0 + y).a > 0.0:
				continue
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nx := x + dx
					var ny := y + dy
					if nx >= 0 and ny >= 0 and nx < TILE and ny < TILE \
							and image.get_pixel(x0 + nx, y0 + ny).a > 0.0:
						marks.append(Vector2i(x0 + x, y0 + y))
	for p in marks:
		image.set_pixelv(p, OUTLINE)
