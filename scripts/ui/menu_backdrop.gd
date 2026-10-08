class_name MenuBackdrop
extends Node2D
## Fond animé des menus : le décor d'un niveau défile lentement, parcouru par le héros,
## son Écho et quelques monstres du niveau. Réutilise ChunkedFloor et les données de niveau.

const SCROLL := Vector2(14, 6)

@export var level_index := 0
@export var characters: Texture2D
@export var hero_frames := PackedInt32Array([1, 2, 3, 4])
@export var echo_frames := PackedInt32Array([5, 6, 7, 8])

var _floor: ChunkedFloor
var _walkers: Array[Sprite2D] = []
var _walker_frames: Array[PackedInt32Array] = []
var _t := 0.0
var _offset := Vector2.ZERO


func _ready() -> void:
	var level: LevelData = GameState.db.levels[level_index % GameState.db.levels.size()]
	RenderingServer.set_default_clear_color(level.background_color)
	_floor = ChunkedFloor.new()
	add_child(_floor)
	_floor.setup(level)
	_floor.update_around(Vector2.ZERO, true)

	_add_walker(characters, hero_frames, Vector2(-40, 30))
	_add_walker(characters, echo_frames, Vector2(-70, 40), Color(1, 1, 1, 0.8))
	for wave in level.waves:
		for enemy in wave.enemies:
			if _walkers.size() < 9:
				_add_walker(enemy.sheet, enemy.frames,
						Vector2(randf_range(-320, 320), randf_range(-170, 170)), enemy.tint)


func _add_walker(sheet: Texture2D, frames: PackedInt32Array, pos: Vector2, tint := Color.WHITE) -> void:
	var s := Sprite2D.new()
	SpriteFx.set_tile(s, sheet, frames[0])
	s.position = pos
	s.modulate = tint
	add_child(s)
	_walkers.append(s)
	_walker_frames.append(frames)


func _process(delta: float) -> void:
	_t += delta
	_offset += SCROLL * delta
	var view := get_viewport_rect().size
	position = view * 0.5 - _offset
	_floor.update_around(_offset)
	for i in _walkers.size():
		var s := _walkers[i]
		var frames := _walker_frames[i]
		s.frame = frames[int((_t + i * 0.37) * 7.0) % frames.size()]
		s.position += SCROLL * delta * (1.0 + 0.3 * sin(i * 1.7))
		s.scale = SpriteFx.walk_scale(_t + i, true, 1.0)
		# Les marcheurs sortis de l'écran réapparaissent de l'autre côté.
		var local := s.position - _offset
		if absf(local.x) > view.x * 0.6:
			s.position.x -= signf(local.x) * view.x * 1.2
		if absf(local.y) > view.y * 0.6:
			s.position.y -= signf(local.y) * view.y * 1.2
