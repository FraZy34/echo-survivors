class_name LobWeapon
extends Weapon
## Lance des bombes en cloche vers des ennemis ; elles explosent en zone à l'impact.


func build_attack(source: Node2D) -> Dictionary:
	var origin := source.global_position
	var offsets: Array = []
	for i in get_amount():
		var target := Arena.instance.enemies.find_random_near(origin, data.max_range)
		if target:
			offsets.append(target.position - origin)
		else:
			offsets.append(Vector2.from_angle(randf() * TAU) * randf_range(40.0, 110.0))
	return {"offsets": offsets}


func perform(source: Node2D, params: Dictionary, power: float, is_echo: bool) -> void:
	var origin := source.global_position
	for offset: Vector2 in params["offsets"]:
		var p := _new_projectile(power, is_echo)
		p.kind = Projectile.Kind.LOB
		p.position = origin
		p.lob_from = origin
		p.lob_to = origin + offset
		p.lob_time = clampf(offset.length() / get_speed(), 0.35, 0.9)
		p.explode_radius = 30.0 * get_area()
		Arena.instance.projectiles.launch(p)
