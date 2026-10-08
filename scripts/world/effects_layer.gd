class_name EffectsLayer
extends Node2D
## Tous les effets éphémères (anneaux, éclairs, particules, nombres de dégâts) sont dessinés
## par ce seul nœud dans un unique _draw(), au lieu de créer des centaines de nœuds.

const MAX_PARTICLES := 300
const MAX_NUMBERS := 40

@export var font: Font

# Chaque effet est un petit tableau pour limiter les allocations : voir les fonctions d'ajout.
var _rings: Array = []      # [pos, from_r, to_r, t, duration, color, width]
var _bolts: Array = []      # [points, t, duration, color]
var _particles: Array = []  # [pos, vel, t, duration, color, size]
var _numbers: Array = []    # [pos, text, t, color]
var _was_active := false


func ring(pos: Vector2, radius: float, color: Color, duration := 0.35, from_radius := 0.0, width := 2.0) -> void:
	_rings.append([pos, from_radius, radius, 0.0, duration, color, width])


func bolt(target: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var start := target + Vector2(randf_range(-20, 20), -140)
	var steps := 7
	for i in steps + 1:
		var k := float(i) / steps
		var p := start.lerp(target, k)
		if i > 0 and i < steps:
			p.x += randf_range(-7, 7)
		points.append(p)
	_bolts.append([points, 0.0, 0.18, color])


func burst(pos: Vector2, color: Color, count := 6) -> void:
	for i in count:
		if _particles.size() >= MAX_PARTICLES:
			return
		var vel := Vector2.from_angle(randf() * TAU) * randf_range(30, 90)
		_particles.append([pos, vel, 0.0, randf_range(0.25, 0.45), color, randf_range(1.0, 2.5)])


func damage_number(pos: Vector2, amount: float, is_echo: bool) -> void:
	if not GameState.show_damage_numbers or _numbers.size() >= MAX_NUMBERS:
		return
	var color := Companion.ECHO_COLOR if is_echo else Color(1.0, 0.95, 0.8)
	_numbers.append([pos + Vector2(randf_range(-4, 4), -10), str(roundi(amount)), 0.0, color])


func _process(delta: float) -> void:
	_age(_rings, 3, 4, delta)
	_age(_bolts, 1, 2, delta)
	_age(_numbers, 2, -1, delta, 0.55)
	var i := 0
	while i < _particles.size():
		var p: Array = _particles[i]
		p[2] += delta
		if p[2] >= p[3]:
			_particles[i] = _particles[_particles.size() - 1]
			_particles.pop_back()
			continue
		p[0] += p[1] * delta
		p[1] *= 0.9
		i += 1
	var active := not (_rings.is_empty() and _bolts.is_empty() and _particles.is_empty() and _numbers.is_empty())
	if active or _was_active:
		queue_redraw()
	_was_active = active


## Fait vieillir une liste d'effets ; t_idx = index du temps, dur_idx = index de la durée.
func _age(list: Array, t_idx: int, dur_idx: int, delta: float, fixed_duration := 0.0) -> void:
	var i := 0
	while i < list.size():
		var e: Array = list[i]
		e[t_idx] += delta
		var duration: float = fixed_duration if dur_idx < 0 else e[dur_idx]
		if e[t_idx] >= duration:
			list[i] = list[list.size() - 1]
			list.pop_back()
		else:
			i += 1


func _draw() -> void:
	for r: Array in _rings:
		var k: float = r[3] / r[4]
		var radius: float = lerpf(r[1], r[2], 1.0 - pow(1.0 - k, 3.0))
		var color: Color = r[5]
		color.a *= 1.0 - k
		draw_arc(r[0], radius, 0.0, TAU, 32, color, r[6])
	for b: Array in _bolts:
		var color: Color = b[3]
		color.a *= 1.0 - b[1] / b[2]
		draw_polyline(b[0], color, 2.0)
		draw_polyline(b[0], Color(1, 1, 1, color.a), 1.0)
	for p: Array in _particles:
		var color: Color = p[4]
		color.a *= 1.0 - p[2] / p[3]
		var s: float = p[5]
		draw_rect(Rect2(p[0] - Vector2(s, s) * 0.5, Vector2(s, s)), color)
	if font:
		for n: Array in _numbers:
			var k: float = n[2] / 0.55
			var color: Color = n[3]
			color.a = 1.0 - k * k
			var pos: Vector2 = n[0] + Vector2(0, -12.0 * k)
			draw_string_outline(font, pos, n[1], HORIZONTAL_ALIGNMENT_CENTER, -1, 8, 3, Color(0, 0, 0, color.a))
			draw_string(font, pos, n[1], HORIZONTAL_ALIGNMENT_CENTER, -1, 8, color)
