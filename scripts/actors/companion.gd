class_name Companion
extends Node2D
## L'Écho : compagnon spectral qui rejoue les actions du joueur avec DELAY secondes de retard.
##
## - Déplacement : il suit exactement la trajectoire du joueur, décalée de 2 s.
## - Attaques : chaque tir du joueur est enregistré (paramètres relatifs à sa position) puis
##   rejoué 2 s plus tard depuis la position de l'Écho, avec `echo_power` de puissance.
## Comme l'Écho repasse là où était le joueur, ses tirs frappent les ennemis qui pourchassent
## le joueur : se placer intelligemment permet de préparer des frappes différées.
## Toutes les 2 s, un « battement » marque la fin d'une fenêtre rejouée (et déclenche l'onde
## d'écho si l'amélioration est acquise).

const DELAY := 2.0
const TRAIL_STEP := 4  ## Un point de traînée tous les N échantillons.
const ECHO_COLOR := Color(0.45, 0.95, 1.0)

@export var float_frames := PackedInt32Array([5, 6, 7, 8])
@export var float_fps := 6.0

var player: Player
var _time := 0.0
var _times := PackedFloat32Array()
var _positions := PackedVector2Array()
var _head := 0
var _attacks: Array[Dictionary] = []
var _beat := DELAY
var _anim_t := 0.0
var _last_pos := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite
@onready var trail: Line2D = $Trail


func setup(target: Player) -> void:
	player = target
	global_position = player.global_position
	_last_pos = global_position
	player.attacked.connect(_on_player_attacked)


## Fraction écoulée du battement courant (0 → 1), utilisée par le HUD.
func beat_progress() -> float:
	return 1.0 - _beat / DELAY


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_time += delta
	_record(player.global_position)
	var target_time := _time - DELAY
	global_position = _sample(target_time)
	_replay_attacks(target_time)
	_update_beat(delta)
	_animate(delta)
	_update_trail()


func _record(pos: Vector2) -> void:
	_times.append(_time)
	_positions.append(pos)
	# Purge des échantillons trop anciens (on garde une marge pour l'interpolation).
	while _head < _times.size() - 1 and _times[_head + 1] < _time - DELAY - 0.1:
		_head += 1
	if _head > 256:
		_times = _times.slice(_head)
		_positions = _positions.slice(_head)
		_head = 0


func _sample(t: float) -> Vector2:
	if _times.size() == 0 or t <= _times[_head]:
		return _positions[_head] if _positions.size() > 0 else global_position
	for i in range(_head, _times.size() - 1):
		if _times[i + 1] >= t:
			var k := (t - _times[i]) / maxf(0.0001, _times[i + 1] - _times[i])
			return _positions[i].lerp(_positions[i + 1], k)
	return _positions[_positions.size() - 1]


func _on_player_attacked(weapon: Weapon, params: Dictionary) -> void:
	_attacks.append({"t": _time, "weapon": weapon, "params": params})


func _replay_attacks(target_time: float) -> void:
	var replayed := false
	while not _attacks.is_empty() and float(_attacks[0].t) <= target_time:
		var entry: Dictionary = _attacks.pop_front()
		var weapon: Weapon = entry.weapon
		if not is_instance_valid(weapon):
			continue
		var params: Dictionary = entry.params
		weapon.perform(self, params, player.stats.echo_power, true)
		if player.stats.echo_mirror > 0.0:
			weapon.perform(self, weapon.mirror_params(params), player.stats.echo_power * 0.75, true)
		replayed = true
	if replayed:
		sprite.modulate = Color(1.6, 1.6, 1.6, 0.9)
		Sfx.play("echo", 0.1, 0.2)


func _update_beat(delta: float) -> void:
	_beat -= delta
	if _beat > 0.0:
		return
	_beat += DELAY
	var arena := Arena.instance
	var pulse := player.stats.echo_pulse
	if pulse > 0.0:
		var radius := (34.0 + 10.0 * pulse) * player.stats.area
		var damage := (6.0 + 6.0 * pulse) * player.stats.might
		for enemy in arena.enemies.query(global_position, radius):
			var dir := (enemy.position - global_position).normalized()
			arena.enemies.hit(enemy, damage, dir * 120.0, true)
		arena.effects.ring(global_position, radius, ECHO_COLOR, 0.4, 4.0, 2.0)
	else:
		arena.effects.ring(global_position, 18.0, Color(ECHO_COLOR, 0.6), 0.35, 4.0, 1.0)


func _animate(delta: float) -> void:
	_anim_t += delta
	sprite.frame = float_frames[int(_anim_t * float_fps) % float_frames.size()]
	var moved := global_position - _last_pos
	_last_pos = global_position
	if absf(moved.x) > 0.01:
		sprite.flip_h = moved.x < 0.0
	sprite.scale = SpriteFx.walk_scale(_anim_t, moved.length_squared() > 0.0001, 1.0)
	sprite.position.y = -3.0 + sin(_anim_t * 2.5) * 1.5  # Il flotte légèrement.
	sprite.modulate = sprite.modulate.lerp(Color(1, 1, 1, 0.85), 8.0 * delta)


## Traînée lumineuse : le chemin que l'Écho va parcourir dans les 2 prochaines secondes.
func _update_trail() -> void:
	var points := PackedVector2Array()
	var target_time := _time - DELAY
	points.append(global_position)
	var i := _head
	var n := _times.size()
	while i < n:
		if _times[i] > target_time:
			points.append(_positions[i])
		i += TRAIL_STEP
	if n > 0:
		points.append(_positions[n - 1])
	trail.points = points
