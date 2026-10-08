class_name RangedEnemy
extends Enemy
## Ennemi à distance : garde ses distances et lance des projectiles vers le joueur.

var _timer := 0.0
var _strafe_sign := 1.0


func _on_activate() -> void:
	_timer = data.attack_interval * randf_range(0.6, 1.4)
	_strafe_sign = 1.0 if randf() < 0.5 else -1.0


func _steer(delta: float, to_target: Vector2) -> Vector2:
	_timer -= delta
	var dist := to_target.length()
	if dist < 0.01:
		return Vector2.ZERO
	var dir := to_target / dist
	if _timer <= 0.0 and dist < data.attack_range:
		_timer = data.attack_interval
		Arena.instance.projectiles.spawn_hostile(position, dir * data.attack_speed, damage,
				data.projectile_sheet, data.projectile_frame, data.projectile_tint, 1.0)
	if dist > data.attack_range * 0.8:
		return dir * speed
	if dist < data.attack_range * 0.45:
		return -dir * speed * 0.7
	return dir.orthogonal() * speed * 0.4 * _strafe_sign
