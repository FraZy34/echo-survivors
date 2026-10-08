class_name ProjectileManager
extends Node2D
## Met à jour tous les projectiles (alliés et ennemis) dans une seule boucle, avec pool.
## Les collisions alliées interrogent la grille de l'EnemyManager ; les projectiles ennemis
## ne testent que la distance au joueur.

const ECHO_TINT := Color(0.55, 1.0, 1.0, 0.8)

var _active: Array[Projectile] = []
var _pool: Array[Projectile] = []
var _hits: Array[Enemy] = []
var _now := 0.0


func acquire() -> Projectile:
	var p: Projectile
	if _pool.is_empty():
		p = Projectile.new()
		add_child(p)
	else:
		p = _pool.pop_back()
	p.reset()
	return p


func launch(p: Projectile) -> void:
	_active.append(p)


func spawn_hostile(pos: Vector2, velocity: Vector2, damage: float, sheet: Texture2D, frame: int,
		tint: Color, size: float) -> void:
	var p := acquire()
	p.hostile = true
	p.position = pos
	p.velocity = velocity
	p.damage = damage
	p.radius = 3.0 * size
	p.lifetime = 4.0
	p.spin = 6.0
	p.scale = Vector2.ONE * size
	p.self_modulate = tint
	SpriteFx.set_tile(p, sheet, frame)
	launch(p)


func clear_hostile() -> void:
	for p in _active:
		if p.hostile:
			p.lifetime = 0.0


func _physics_process(delta: float) -> void:
	var arena := Arena.instance
	if arena == null:
		return
	_now += delta
	var player := arena.player
	var i := 0
	while i < _active.size():
		var p := _active[i]
		if _update(p, delta, player, arena):
			i += 1
		else:
			_active[i] = _active[_active.size() - 1]
			_active.pop_back()
			p.visible = false
			p.anchor = null
			_pool.append(p)


## Renvoie false quand le projectile doit être recyclé.
func _update(p: Projectile, delta: float, player: Player, arena: Arena) -> bool:
	p.lifetime -= delta
	match p.kind:
		Projectile.Kind.LINEAR:
			p.position += p.velocity * delta
		Projectile.Kind.ORBIT:
			if not is_instance_valid(p.anchor):
				return false
			p.orbit_angle += p.orbit_speed * delta
			p.position = p.anchor.global_position + Vector2.from_angle(p.orbit_angle) * p.orbit_radius
			if p.lifetime < 0.25:
				p.modulate.a = p.lifetime / 0.25
		Projectile.Kind.LOB:
			p.lob_t += delta
			var k := minf(1.0, p.lob_t / p.lob_time)
			p.position = p.lob_from.lerp(p.lob_to, k) + Vector2(0.0, -sin(k * PI) * 34.0)
			p.rotation += 9.0 * delta
			if k >= 1.0:
				_explode(p, arena)
				return false
			return true
	if p.spin != 0.0:
		p.rotation += p.spin * delta
	if p.lifetime <= 0.0:
		return false

	if p.hostile:
		var r := p.radius + player.radius
		if p.position.distance_squared_to(player.global_position) < r * r:
			player.take_damage(p.damage)
			return false
		return true

	arena.enemies.query_into(p.position, p.radius, _hits)
	for enemy in _hits:
		var id := enemy.get_instance_id()
		if p.hit_log.has(id) and (p.rehit_interval <= 0.0 or _now < float(p.hit_log[id])):
			continue
		p.hit_log[id] = _now + p.rehit_interval
		var push := p.velocity.normalized() if p.kind == Projectile.Kind.LINEAR \
				else (enemy.position - p.position).normalized()
		arena.enemies.hit(enemy, p.damage, push * p.knockback, p.is_echo)
		if p.pierce > 0:
			p.pierce -= 1
			if p.pierce == 0:
				return false
	return true


func _explode(p: Projectile, arena: Arena) -> void:
	for enemy in arena.enemies.query(p.position, p.explode_radius):
		var dir := (enemy.position - p.position).normalized()
		arena.enemies.hit(enemy, p.damage, dir * p.knockback, p.is_echo)
	var color := ECHO_TINT if p.is_echo else Color(1.0, 0.7, 0.3)
	arena.effects.ring(p.position, p.explode_radius, color, 0.35, 4.0, 3.0)
	arena.effects.burst(p.position, color, 8)
	Sfx.play("explosion", 0.1, 0.08)
