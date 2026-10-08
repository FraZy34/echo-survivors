class_name AuraWeapon
extends Weapon
## Zone de dégâts permanente autour du joueur, qui inflige des dégâts par impulsions.
## Chaque impulsion est rejouée par l'Écho sous forme d'onde autour de lui.

const BASE_RADIUS := 36.0

var _visual: AuraVisual


func _on_setup() -> void:
	_visual = AuraVisual.new()
	_visual.color = data.projectile_tint
	player.add_child(_visual)
	player.move_child(_visual, 0)
	_visual.radius = get_radius()


func _on_level_changed() -> void:
	_visual.radius = get_radius()


func get_radius() -> float:
	return BASE_RADIUS * get_area()


func build_attack(_source: Node2D) -> Dictionary:
	return {"pulse": true}


func perform(source: Node2D, _params: Dictionary, power: float, is_echo: bool) -> void:
	var arena := Arena.instance
	var origin := source.global_position
	var radius := get_radius()
	for enemy in arena.enemies.query(origin, radius):
		arena.enemies.hit(enemy, get_damage() * power, origin.direction_to(enemy.position) * data.knockback, is_echo)
	if is_echo:
		arena.effects.ring(origin, radius, ECHO_TINT, 0.3, radius * 0.6, 1.5)
	else:
		_visual.radius = radius
		_visual.pulse()
