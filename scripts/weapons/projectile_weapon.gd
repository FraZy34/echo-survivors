class_name ProjectileWeapon
extends Weapon
## Tire un ou plusieurs projectiles en ligne droite (dague, flèches, orbes...).
## La visée dépend de WeaponData.aim.


func build_attack(source: Node2D) -> Dictionary:
	var origin := source.global_position
	var base_dir: Vector2
	match data.aim:
		WeaponData.Aim.NEAREST:
			var target := Arena.instance.enemies.find_nearest(origin, data.max_range)
			if target == null:
				return {}
			base_dir = origin.direction_to(target.position)
		WeaponData.Aim.RANDOM_ENEMY:
			var target := Arena.instance.enemies.find_random_near(origin, data.max_range)
			if target == null:
				return {}
			base_dir = origin.direction_to(target.position)
		WeaponData.Aim.FACING:
			base_dir = player.facing
		_:
			base_dir = Vector2.from_angle(randf() * TAU)

	var count := get_amount()
	var dirs: Array = []
	if data.aim == WeaponData.Aim.AROUND:
		for i in count:
			dirs.append(base_dir.rotated(TAU * i / count))
	else:
		var spread := deg_to_rad(data.spread_deg)
		for i in count:
			dirs.append(base_dir.rotated((i - (count - 1) * 0.5) * spread))
	return {"dirs": dirs}


func perform(source: Node2D, params: Dictionary, power: float, is_echo: bool) -> void:
	var origin := source.global_position
	var speed := get_speed()
	for dir: Vector2 in params["dirs"]:
		var p := _new_projectile(power, is_echo)
		p.kind = Projectile.Kind.LINEAR
		p.position = origin + dir * 4.0
		p.velocity = dir * speed
		p.lifetime = get_duration()
		if data.orient_to_direction:
			p.rotation = dir.angle() + data.sprite_angle
		Arena.instance.projectiles.launch(p)
	if not is_echo:
		Sfx.play("shoot", 0.1, 0.08)
