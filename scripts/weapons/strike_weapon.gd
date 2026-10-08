class_name StrikeWeapon
extends Weapon
## Foudroie instantanément des ennemis proches. Rejouée par l'Écho, la foudre retombe sur
## les mêmes emplacements relatifs : là où se trouvaient les ennemis deux secondes plus tôt.


func build_attack(source: Node2D) -> Dictionary:
	var origin := source.global_position
	var offsets: Array = []
	var chosen := {}
	for i in get_amount():
		var target := Arena.instance.enemies.find_random_near(origin, data.max_range)
		if target == null or chosen.has(target):
			continue
		chosen[target] = true
		offsets.append(target.position - origin)
	if offsets.is_empty():
		return {}
	return {"offsets": offsets}


func perform(source: Node2D, params: Dictionary, power: float, is_echo: bool) -> void:
	var arena := Arena.instance
	var origin := source.global_position
	var radius := 14.0 * get_area()
	var color := ECHO_TINT if is_echo else data.projectile_tint
	for offset: Vector2 in params["offsets"]:
		var pos := origin + offset
		for enemy in arena.enemies.query(pos, radius):
			arena.enemies.hit(enemy, get_damage() * power, Vector2.ZERO, is_echo)
		arena.effects.bolt(pos, color)
		arena.effects.ring(pos, radius, color, 0.25, 2.0, 1.5)
	if not is_echo:
		Sfx.play("shoot", 0.2, 0.1, 0.6)
