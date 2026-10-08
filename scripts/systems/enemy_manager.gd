class_name EnemyManager
extends Node2D
## Gère tous les ennemis dans une boucle unique (pas de _process par ennemi, pas de physique) :
## - pool d'instances par scène (aucune allocation en régime établi) ;
## - grille spatiale reconstruite chaque frame pour les requêtes de proximité en O(1) ;
## - séparation entre ennemis calculée une frame sur deux (moitié des ennemis par frame) ;
## - recyclage des ennemis trop éloignés vers l'autre côté du joueur.

signal enemy_killed(enemy: Enemy)
signal boss_spawned(boss: Enemy)

const CELL := 32.0
const MAX_HIT_RADIUS := 32.0
const MAX_ENEMIES := 450
const SEPARATION_NEIGHBORS := 8

var player: Player
var active: Array[Enemy] = []
var boss_count := 0

var _dying: Array[Enemy] = []
var _pools := {}
var _grid := {}
var _frame := 0


func spawn(data: EnemyData, pos: Vector2, hp_mult := 1.0, dmg_mult := 1.0) -> Enemy:
	if active.size() >= MAX_ENEMIES and not data.is_boss:
		return null
	var key := data.scene.resource_path
	if not _pools.has(key):
		_pools[key] = []
	var pool: Array = _pools[key]
	var enemy: Enemy
	if pool.is_empty():
		enemy = data.scene.instantiate()
		enemy.manager = self
		add_child(enemy)
	else:
		enemy = pool.pop_back()
	enemy.position = pos
	enemy.activate(data, hp_mult, dmg_mult)
	active.append(enemy)
	if data.is_boss:
		boss_count += 1
		boss_spawned.emit(enemy)
	return enemy


func regular_count() -> int:
	return active.size() - boss_count


## Inflige des dégâts à un ennemi (point d'entrée unique : effets, sons, mort).
func hit(enemy: Enemy, amount: float, knockback: Vector2, is_echo := false) -> void:
	if not enemy.alive:
		return
	var killed := enemy.take_damage(amount, knockback)
	var arena := Arena.instance
	arena.effects.damage_number(enemy.position, amount, is_echo)
	if killed:
		if enemy.data.is_boss:
			boss_count -= 1
		arena.effects.burst(enemy.position, Color(1, 1, 1) if not is_echo else Companion.ECHO_COLOR, 5)
		Sfx.play("kill", 0.15, 0.05)
		enemy_killed.emit(enemy)
	else:
		Sfx.play("hit", 0.15, 0.05)


# --- Requêtes spatiales -----------------------------------------------------------------

## Ennemis vivants dont le cercle de collision touche le disque (pos, radius).
func query(pos: Vector2, radius: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	query_into(pos, radius, out)
	return out


func query_into(pos: Vector2, radius: float, out: Array[Enemy]) -> void:
	out.clear()
	var reach := radius + MAX_HIT_RADIUS
	var x0 := floori((pos.x - reach) / CELL)
	var x1 := floori((pos.x + reach) / CELL)
	var y0 := floori((pos.y - reach) / CELL)
	var y1 := floori((pos.y + reach) / CELL)
	for cx in range(x0, x1 + 1):
		for cy in range(y0, y1 + 1):
			var key := Vector2i(cx, cy)
			if not _grid.has(key):
				continue
			for enemy: Enemy in _grid[key]:
				if not enemy.alive:
					continue
				var r := radius + enemy.hit_radius
				if pos.distance_squared_to(enemy.position) <= r * r:
					out.append(enemy)


func find_nearest(pos: Vector2, max_dist: float) -> Enemy:
	var best: Enemy = null
	var best_d := max_dist * max_dist
	for enemy in active:
		if not enemy.alive:
			continue
		var d := pos.distance_squared_to(enemy.position)
		if d < best_d:
			best_d = d
			best = enemy
	return best


func find_random_near(pos: Vector2, max_dist: float) -> Enemy:
	if active.is_empty():
		return null
	var max_d2 := max_dist * max_dist
	for attempt in 10:
		var enemy := active[randi() % active.size()]
		if enemy.alive and pos.distance_squared_to(enemy.position) < max_d2:
			return enemy
	return find_nearest(pos, max_dist)


# --- Boucle principale -------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if player == null:
		return
	_frame += 1
	_rebuild_grid()
	var target := player.global_position
	var contact_pad := player.radius
	var recycle_dist := Arena.instance.spawner.spawn_distance() * 1.9
	var recycle_d2 := recycle_dist * recycle_dist
	var i := 0
	while i < active.size():
		var enemy := active[i]
		if not enemy.alive:
			active[i] = active[active.size() - 1]
			active.pop_back()
			_dying.append(enemy)
			continue
		enemy.tick(delta, target)
		if (i + _frame) % 2 == 0:
			_separate(enemy)
		var d2 := enemy.position.distance_squared_to(target)
		var contact := enemy.hit_radius + contact_pad
		if d2 < contact * contact:
			player.take_damage(enemy.damage)
		elif d2 > recycle_d2:
			_recycle(enemy, target)
		i += 1
	_update_dying(delta)


func _rebuild_grid() -> void:
	if _frame % 240 == 0:
		_grid.clear()  # Purge des cellules laissées derrière le joueur.
	else:
		for cell_list: Array in _grid.values():
			cell_list.clear()
	for enemy in active:
		var key := Vector2i(floori(enemy.position.x / CELL), floori(enemy.position.y / CELL))
		enemy.cell = key
		if _grid.has(key):
			_grid[key].append(enemy)
		else:
			_grid[key] = [enemy]


## Repousse doucement l'ennemi hors de ses voisins de cellule pour éviter les empilements.
func _separate(enemy: Enemy) -> void:
	var neighbors: Array = _grid.get(enemy.cell, [])
	var push := Vector2.ZERO
	var checked := 0
	for other: Enemy in neighbors:
		if other == enemy:
			continue
		var d := enemy.position - other.position
		var min_d := (enemy.hit_radius + other.hit_radius) * 0.85
		var l2 := d.length_squared()
		if l2 < min_d * min_d:
			if l2 < 0.0001:
				d = Vector2(randf() - 0.5, randf() - 0.5)
				l2 = d.length_squared()
			var l := sqrt(l2)
			push += d / l * (min_d - l)
		checked += 1
		if checked >= SEPARATION_NEIGHBORS:
			break
	if push != Vector2.ZERO:
		enemy.position += push * 0.5 * (1.0 - enemy.data.knockback_resist * 0.9)


## Un ennemi semé loin derrière réapparaît devant le joueur (comme dans Vampire Survivors).
func _recycle(enemy: Enemy, target: Vector2) -> void:
	var away := (target - enemy.position).normalized()
	var dist := Arena.instance.spawner.spawn_distance()
	enemy.position = target + away.rotated(randf_range(-0.6, 0.6)) * dist


func _update_dying(delta: float) -> void:
	var i := 0
	while i < _dying.size():
		var enemy := _dying[i]
		if enemy.update_dying(delta):
			i += 1
			continue
		enemy.deactivate()
		_pools[enemy.data.scene.resource_path].append(enemy)
		_dying[i] = _dying[_dying.size() - 1]
		_dying.pop_back()


