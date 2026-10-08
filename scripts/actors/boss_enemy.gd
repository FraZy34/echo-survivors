class_name BossEnemy
extends Enemy
## Boss de fin de niveau : enchaîne trois motifs d'attaque (salve circulaire, charge,
## invocation de sbires) et accélère sous 50 % de PV.

enum Pattern { BURST, CHARGE, SUMMON }

var enraged := false
var _pattern_timer := 0.0
var _pattern_index := 0
var _windup := 0.0
var _charge_time := 0.0
var _charge_dir := Vector2.ZERO


func _on_activate() -> void:
	enraged = false
	_pattern_timer = 3.0
	_pattern_index = 0
	_windup = 0.0
	_charge_time = 0.0


func _steer(delta: float, to_target: Vector2) -> Vector2:
	if not enraged and hp < max_hp * 0.5:
		enraged = true
		_on_enrage()
	if _charge_time > 0.0:
		_charge_time -= delta
		return _charge_dir * data.attack_speed * 2.4
	if _windup > 0.0:
		_windup -= delta
		offset.x = sin(_windup * 70.0) * 1.5
		if _windup <= 0.0:
			offset.x = 0.0
			_charge_dir = to_target.normalized()
			_charge_time = 0.7
		return Vector2.ZERO

	_pattern_timer -= delta
	if _pattern_timer <= 0.0:
		_pattern_timer = data.attack_interval * (0.6 if enraged else 1.0)
		pose_time = 0.6
		_run_pattern((_pattern_index % 3) as Pattern)
		_pattern_index += 1
	return to_target.normalized() * speed * (1.3 if enraged else 1.0)


func _run_pattern(pattern: Pattern) -> void:
	var arena := Arena.instance
	match pattern:
		Pattern.BURST:
			var count := 18 if enraged else 12
			var start := randf() * TAU
			for i in count:
				var dir := Vector2.from_angle(start + TAU * i / count)
				arena.projectiles.spawn_hostile(position, dir * data.attack_speed, damage * 0.7,
						data.projectile_sheet, data.projectile_frame, data.projectile_tint, 1.4)
			arena.effects.ring(position, 40.0, Color(1.0, 0.4, 0.3), 0.4, 10.0, 3.0)
			Sfx.play("explosion", 0.05, 0.1, 0.7)
		Pattern.CHARGE:
			_windup = 0.7
		Pattern.SUMMON:
			if data.minion:
				var count := 6 if enraged else 4
				for i in count:
					var pos := position + Vector2.from_angle(TAU * i / count) * 36.0
					manager.spawn(data.minion, pos, Arena.instance.spawner.hp_multiplier(), 1.0)
				arena.effects.ring(position, 36.0, Color(0.7, 0.4, 1.0), 0.5, 8.0, 2.0)


func _on_enrage() -> void:
	Arena.instance.effects.ring(position, 60.0, Color(1.0, 0.2, 0.2), 0.6, 10.0, 4.0)
	Sfx.play("boss", 0.0, 0.5, 0.8)


func _animate(delta: float, moving: bool) -> void:
	super(delta, moving)
	if enraged and _flash <= 0.0:
		self_modulate = data.tint * Color(1.0, 0.6 + 0.4 * absf(sin(_anim_t * 6.0)), 0.6 + 0.4 * absf(sin(_anim_t * 6.0)))
