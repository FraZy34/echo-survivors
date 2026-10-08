class_name PickupManager
extends Node2D
## Gemmes d'expérience et objets lâchés par les ennemis. Les gemmes entrant dans le rayon
## d'attraction du joueur sont aspirées vers lui. Au-delà de MAX_GEMS, les nouvelles gemmes
## fusionnent avec une gemme existante pour garder un coût constant.

const MAX_GEMS := 260
const COLLECT_DIST := 9.0

@export var sheet: Texture2D
@export var gem_small_frame := 0
@export var gem_mid_frame := 0
@export var gem_big_frame := 0
@export var potion_frame := 0
@export var bell_frame := 0

var _active: Array[Pickup] = []
var _pool: Array[Pickup] = []
var _gem_count := 0


func spawn_gem(pos: Vector2, value: int) -> void:
	if _gem_count >= MAX_GEMS:
		var target := _active[randi() % _active.size()]
		if target.kind == Pickup.Kind.GEM:
			target.value += value
			_style_gem(target)
			return
	var p := _acquire(pos, Pickup.Kind.GEM)
	p.value = value
	_style_gem(p)
	_gem_count += 1


func spawn_item(pos: Vector2, kind: Pickup.Kind) -> void:
	var p := _acquire(pos, kind)
	SpriteFx.set_tile(p, sheet, potion_frame if kind == Pickup.Kind.POTION else bell_frame)


## Attire toutes les gemmes vers le joueur (effet de la cloche).
func attract_all() -> void:
	for p in _active:
		if p.kind == Pickup.Kind.GEM:
			p.attracted = true


func _acquire(pos: Vector2, kind: Pickup.Kind) -> Pickup:
	var p: Pickup
	if _pool.is_empty():
		p = Pickup.new()
		add_child(p)
	else:
		p = _pool.pop_back()
	p.kind = kind
	p.position = pos + Vector2(randf_range(-3, 3), randf_range(-3, 3))
	p.attracted = false
	p.speed = 0.0
	p.visible = true
	p.scale = Vector2.ONE
	p.self_modulate = Color.WHITE
	_active.append(p)
	return p


func _style_gem(p: Pickup) -> void:
	# Petite gemme bleue, moyenne verte, grande rouge (agrandie pour les gemmes fusionnées).
	var frame := gem_small_frame if p.value < 3 else (gem_mid_frame if p.value < 10 else gem_big_frame)
	SpriteFx.set_tile(p, sheet, frame)
	p.scale = Vector2.ONE * (1.35 if p.value >= 40 else 1.0)


func _physics_process(delta: float) -> void:
	var arena := Arena.instance
	if arena == null or arena.player.dead:
		return
	var player := arena.player
	var target := player.global_position
	var magnet := player.stats.magnet
	var magnet2 := magnet * magnet
	var i := 0
	while i < _active.size():
		var p := _active[i]
		var to := target - p.position
		var d2 := to.length_squared()
		if not p.attracted and d2 < magnet2:
			p.attracted = true
			p.speed = -40.0  # Petit recul avant d'être aspirée.
		if p.attracted:
			p.speed = minf(p.speed + 520.0 * delta, 420.0)
			p.position += to.normalized() * p.speed * delta
			if d2 < COLLECT_DIST * COLLECT_DIST:
				_collect(p, player, arena)
				_active[i] = _active[_active.size() - 1]
				_active.pop_back()
				p.visible = false
				_pool.append(p)
				continue
		i += 1


func _collect(p: Pickup, player: Player, arena: Arena) -> void:
	match p.kind:
		Pickup.Kind.GEM:
			_gem_count -= 1
			player.gain_xp(p.value)
			Sfx.play("pickup", 0.15, 0.04, 1.2)
		Pickup.Kind.POTION:
			player.heal(30.0)
			arena.effects.ring(player.global_position, 20.0, Color(1.0, 0.4, 0.4), 0.4, 4.0, 2.0)
			Sfx.play("levelup", 0.0, 0.1, 1.4)
		Pickup.Kind.BELL:
			attract_all()
			arena.effects.ring(player.global_position, 120.0, Color(1.0, 0.9, 0.4), 0.6, 8.0, 2.0)
			Sfx.play("echo", 0.0, 0.1, 0.8)
