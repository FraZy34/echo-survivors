class_name ChargerEnemy
extends Enemy
## Ennemi qui s'arrête, tremble brièvement puis fonce en ligne droite vers le joueur.

enum State { CHASE, WINDUP, DASH }

const WINDUP_TIME := 0.5
const DASH_TIME := 0.55

var _state := State.CHASE
var _timer := 0.0
var _dash_dir := Vector2.ZERO


func _on_activate() -> void:
	_state = State.CHASE
	_timer = data.attack_interval * randf_range(0.5, 1.2)


func _steer(delta: float, to_target: Vector2) -> Vector2:
	_timer -= delta
	match _state:
		State.CHASE:
			if _timer <= 0.0 and to_target.length_squared() < data.attack_range * data.attack_range:
				_state = State.WINDUP
				_timer = WINDUP_TIME
				pose_time = WINDUP_TIME + DASH_TIME
				return Vector2.ZERO
			return to_target.normalized() * speed
		State.WINDUP:
			offset.x = sin(_timer * 90.0) * 1.2
			if _timer <= 0.0:
				_state = State.DASH
				_timer = DASH_TIME
				_dash_dir = to_target.normalized()
				offset.x = 0.0
			return Vector2.ZERO
		_:
			if _timer <= 0.0:
				_state = State.CHASE
				_timer = data.attack_interval
			return _dash_dir * data.attack_speed
