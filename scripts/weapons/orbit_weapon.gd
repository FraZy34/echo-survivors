class_name OrbitWeapon
extends Weapon
## Projectiles qui tournent autour de leur lanceur pendant `duration` secondes, puis
## disparaissent jusqu'à la prochaine activation. Rejouées par l'Écho, elles tournent autour de lui.

const BASE_RADIUS := 34.0


func build_attack(_source: Node2D) -> Dictionary:
	return {"phase": randf() * TAU}


func perform(source: Node2D, params: Dictionary, power: float, is_echo: bool) -> void:
	var count := get_amount()
	var phase: float = params["phase"]
	for i in count:
		var p := _new_projectile(power, is_echo)
		p.kind = Projectile.Kind.ORBIT
		p.anchor = source
		p.orbit_angle = phase + TAU * i / count
		p.orbit_radius = BASE_RADIUS * get_area()
		p.orbit_speed = get_speed()
		p.position = source.global_position + Vector2.from_angle(p.orbit_angle) * p.orbit_radius
		p.lifetime = get_duration()
		p.pierce = -1
		p.rehit_interval = 0.45
		Arena.instance.projectiles.launch(p)


func mirror_params(params: Dictionary) -> Dictionary:
	return {"phase": float(params["phase"]) + PI / maxf(1.0, get_amount())}
