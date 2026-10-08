class_name WaveSpawner
extends Node
## Fait apparaître les vagues du niveau hors de l'écran, autour du joueur, et invoque le boss
## une fois la durée du niveau écoulée. La difficulté (PV et dégâts) croît avec le temps.

signal boss_warning
signal boss_arrived(boss: Enemy)

const SPAWN_MARGIN := 40.0

var level: LevelData
var enemies: EnemyManager
var player: Player
var elapsed := 0.0
var boss_spawned := false

var _timers := PackedFloat32Array()
var _warned := false


func setup(level_data: LevelData, enemy_manager: EnemyManager, target: Player) -> void:
	level = level_data
	enemies = enemy_manager
	player = target
	_timers.resize(level.waves.size())
	_timers.fill(0.0)


func hp_multiplier() -> float:
	return level.hp_base * (1.0 + elapsed / 60.0 * level.hp_growth_per_minute)


func damage_multiplier() -> float:
	return 1.0 + elapsed / 60.0 * level.damage_growth_per_minute


## Distance d'apparition : juste au-delà du coin de l'écran visible.
func spawn_distance() -> float:
	var size := player.get_viewport_rect().size / player.camera.zoom
	return size.length() * 0.5 + SPAWN_MARGIN


func time_left() -> float:
	return maxf(0.0, level.duration - elapsed)


func _physics_process(delta: float) -> void:
	if level == null or player.dead:
		return
	elapsed += delta
	if not _warned and elapsed >= level.duration - 6.0:
		_warned = true
		boss_warning.emit()
	if not boss_spawned and elapsed >= level.duration:
		_spawn_boss()

	# Pendant le combat de boss, les vagues continuent mais beaucoup moins vite.
	var rate := 0.35 if boss_spawned else 1.0
	for i in level.waves.size():
		var wave := level.waves[i]
		if elapsed < wave.start_time:
			continue
		# Une fois le boss arrivé, seules les vagues qui couraient jusqu'à la fin continuent.
		var limit := level.duration if boss_spawned else elapsed
		if wave.end_time <= limit or (boss_spawned and wave.formation == WaveData.Formation.RING):
			continue
		_timers[i] -= delta * rate
		if _timers[i] <= 0.0:
			_timers[i] = wave.spawn_interval
			_spawn_batch(wave)


func _spawn_batch(wave: WaveData) -> void:
	if wave.enemies.is_empty() or enemies.regular_count() >= wave.max_alive:
		return
	var center := player.global_position
	var dist := spawn_distance()
	var hp_mult := hp_multiplier()
	var dmg_mult := damage_multiplier()
	match wave.formation:
		WaveData.Formation.SCATTER:
			for i in wave.batch_size:
				var pos := center + Vector2.from_angle(randf() * TAU) * dist * randf_range(1.0, 1.15)
				enemies.spawn(wave.enemies.pick_random(), pos, hp_mult, dmg_mult)
		WaveData.Formation.CLUSTER:
			var base := center + Vector2.from_angle(randf() * TAU) * dist
			var data: EnemyData = wave.enemies.pick_random()
			for i in wave.batch_size:
				var pos := base + Vector2(randf_range(-24, 24), randf_range(-24, 24))
				enemies.spawn(data, pos, hp_mult, dmg_mult)
		WaveData.Formation.RING:
			var data: EnemyData = wave.enemies.pick_random()
			var count := wave.batch_size
			for i in count:
				var pos := center + Vector2.from_angle(TAU * i / count) * dist * 0.85
				enemies.spawn(data, pos, hp_mult, dmg_mult)


func _spawn_boss() -> void:
	boss_spawned = true
	if level.boss == null:
		return
	var pos := player.global_position + Vector2.from_angle(randf() * TAU) * spawn_distance() * 0.8
	var boss := enemies.spawn(level.boss, pos, level.hp_base, damage_multiplier())
	boss_arrived.emit(boss)
