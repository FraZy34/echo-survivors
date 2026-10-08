class_name ChunkedFloor
extends Node2D
## Sol infini généré par morceaux (chunks) autour du joueur à partir des tuiles du niveau.
## Le tirage est déterministe (hachage des coordonnées) : revenir sur ses pas redonne le même
## décor. Les chunks sont chargés progressivement (quelques-uns par frame) pour éviter les
## à-coups, et déchargés une fois loin du joueur.

const TILE := 16
const CHUNK := 16                      ## Tuiles par côté de chunk.
const LOAD_RADIUS := 2                 ## Chunks chargés autour du joueur.
const MAX_LOADS_PER_FRAME := 2

var _ground: TileMapLayer
var _decor: TileMapLayer
var _level: LevelData
var _cols := 12
var _loaded := {}
var _queue: Array[Vector2i] = []
var _current := Vector2i(999999, 999999)
var _weight_total := 0.0


func setup(level: LevelData) -> void:
	_level = level
	_cols = level.tileset.get_width() / TILE
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	var source := TileSetAtlasSource.new()
	source.texture = level.tileset
	source.texture_region_size = Vector2i(TILE, TILE)
	var used := {}
	for frame in level.floor_tiles:
		used[frame] = true
	for frame in level.decor_tiles:
		used[frame] = true
	for frame: int in used:
		source.create_tile(_coords(frame))
	tileset.add_source(source, 0)

	_ground = _make_layer(tileset)
	_decor = _make_layer(tileset)

	_weight_total = 0.0
	for w in level.floor_weights:
		_weight_total += w


func _make_layer(tileset: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = tileset
	# Décor purement visuel : ni collisions ni navigation à calculer.
	layer.collision_enabled = false
	layer.navigation_enabled = false
	add_child(layer)
	return layer


## À appeler chaque frame avec la position du joueur.
func update_around(pos: Vector2, immediate := false) -> void:
	var chunk := Vector2i(floori(pos.x / (TILE * CHUNK)), floori(pos.y / (TILE * CHUNK)))
	if chunk != _current:
		_current = chunk
		_queue.clear()
		for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
				var c := chunk + Vector2i(dx, dy)
				if not _loaded.has(c):
					_queue.append(c)
		# Les chunks les plus proches d'abord.
		_queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return (a - chunk).length_squared() < (b - chunk).length_squared())
		_unload_far(chunk)
	var budget := 1000 if immediate else MAX_LOADS_PER_FRAME
	while budget > 0 and not _queue.is_empty():
		_load_chunk(_queue.pop_front())
		budget -= 1


func _load_chunk(chunk: Vector2i) -> void:
	if _loaded.has(chunk):
		return
	_loaded[chunk] = true
	var origin := chunk * CHUNK
	for y in CHUNK:
		for x in CHUNK:
			var cell := origin + Vector2i(x, y)
			_ground.set_cell(cell, 0, _coords(_pick_floor(cell)))
			if not _level.decor_tiles.is_empty() and _rand(cell, 7) < _level.decor_density:
				var index := int(_rand(cell, 13) * _level.decor_tiles.size()) % _level.decor_tiles.size()
				_decor.set_cell(cell, 0, _coords(_level.decor_tiles[index]))


func _unload_far(center: Vector2i) -> void:
	for chunk: Vector2i in _loaded.keys():
		if absi(chunk.x - center.x) > LOAD_RADIUS + 1 or absi(chunk.y - center.y) > LOAD_RADIUS + 1:
			_loaded.erase(chunk)
			var origin := chunk * CHUNK
			for y in CHUNK:
				for x in CHUNK:
					_ground.erase_cell(origin + Vector2i(x, y))
					_decor.erase_cell(origin + Vector2i(x, y))


func _pick_floor(cell: Vector2i) -> int:
	var roll := _rand(cell, 1) * _weight_total
	for i in _level.floor_tiles.size():
		roll -= _level.floor_weights[i] if i < _level.floor_weights.size() else 1.0
		if roll <= 0.0:
			return _level.floor_tiles[i]
	return _level.floor_tiles[0]


## Nombre pseudo-aléatoire déterministe dans [0, 1[ pour une cellule.
func _rand(cell: Vector2i, salt: int) -> float:
	var h := hash(Vector3i(cell.x, cell.y, salt))
	return float(h & 0xFFFF) / 65536.0


func _coords(frame: int) -> Vector2i:
	return Vector2i(frame % _cols, frame / _cols)
