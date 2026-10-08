class_name Arena
extends Node2D
## Scène de jeu : relie le joueur, l'Écho, les gestionnaires (ennemis, projectiles, gemmes,
## effets), le générateur de vagues et l'interface. Accessible via Arena.instance.

static var instance: Arena

const POTION_CHANCE := 0.012
const BELL_CHANCE := 0.004

var level: LevelData
var upgrades: UpgradeService
var elapsed := 0.0
var kills := 0
var bonus_score := 0
var finished := false

var _pending_level_ups := 0

@onready var floor_layer: ChunkedFloor = $Floor
@onready var pickups: PickupManager = $Pickups
@onready var enemies: EnemyManager = $Actors/Enemies
@onready var player: Player = $Actors/Player
@onready var companion: Companion = $Actors/Companion
@onready var projectiles: ProjectileManager = $Projectiles
@onready var effects: EffectsLayer = $Effects
@onready var spawner: WaveSpawner = $WaveSpawner
@onready var ambient: CanvasModulate = $Ambient
@onready var hud: Hud = $Hud
@onready var level_up_panel: LevelUpPanel = $LevelUpPanel
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var game_over: GameOverScreen = $GameOver


func _enter_tree() -> void:
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


func _ready() -> void:
	get_tree().paused = false
	level = GameState.current_level
	RenderingServer.set_default_clear_color(level.background_color)
	ambient.color = level.ambient
	Sfx.play_music(level.music)
	floor_layer.setup(level)
	floor_layer.update_around(player.global_position, true)

	enemies.player = player
	companion.setup(player)
	spawner.setup(level, enemies, player)
	upgrades = UpgradeService.new(GameState.db, player)

	player.leveled_up.connect(_on_player_leveled_up)
	player.died.connect(_on_player_died)
	enemies.enemy_killed.connect(_on_enemy_killed)
	spawner.boss_warning.connect(hud.show_boss_warning)
	spawner.boss_arrived.connect(_on_boss_arrived)
	level_up_panel.chosen.connect(_on_upgrade_chosen)

	hud.setup(self)
	player.add_weapon(GameState.db.starting_weapon)


func _physics_process(delta: float) -> void:
	if finished:
		return
	elapsed += delta
	floor_layer.update_around(player.global_position)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not finished and not level_up_panel.visible:
		pause_menu.open()
		get_viewport().set_input_as_handled()


func score() -> int:
	return int(elapsed) * 10 + kills * 5 + player.level * 50 + bonus_score


# --- Événements ---------------------------------------------------------------------------

func _on_enemy_killed(enemy: Enemy) -> void:
	kills += 1
	pickups.spawn_gem(enemy.position, enemy.data.xp)
	var roll := randf()
	if roll < BELL_CHANCE:
		pickups.spawn_item(enemy.position, Pickup.Kind.BELL)
	elif roll < BELL_CHANCE + POTION_CHANCE:
		pickups.spawn_item(enemy.position, Pickup.Kind.POTION)
	if enemy.data.is_boss:
		_on_boss_defeated(enemy)


func _on_boss_arrived(boss: Enemy) -> void:
	hud.show_boss(boss)
	Sfx.play("boss", 0.0, 0.5)


func _on_boss_defeated(boss: Enemy) -> void:
	finished = true
	player.invulnerable = true
	bonus_score += 5000
	effects.ring(boss.position, 120.0, Color(1.0, 0.9, 0.5), 1.0, 10.0, 4.0)
	effects.burst(boss.position, Color(1.0, 0.8, 0.3), 40)
	projectiles.clear_hostile()
	Sfx.stop_music()
	Sfx.play("victory", 0.0, 0.5)
	await get_tree().create_timer(1.6).timeout
	_show_results(true)


func _on_player_died() -> void:
	if finished:
		return
	finished = true
	effects.burst(player.global_position, Color(1.0, 0.3, 0.3), 30)
	player.sprite.modulate = Color(1, 1, 1, 0.3)
	Sfx.stop_music()
	Sfx.play("gameover", 0.0, 0.5)
	await get_tree().create_timer(1.2).timeout
	_show_results(false)


func _show_results(victory: bool) -> void:
	get_tree().paused = true
	var final_score := score()
	var best_before: int = GameState.get_best(level.id).score
	var is_record := GameState.record_result(level.id, final_score, elapsed, kills, victory)
	game_over.show_result({
		"victory": victory,
		"level_name": level.display_name,
		"boss_name": level.boss.display_name if level.boss else "Le boss",
		"time": elapsed,
		"kills": kills,
		"player_level": player.level,
		"score": final_score,
		"best": maxi(best_before, final_score),
		"record": is_record,
	})


# --- Montée de niveau ------------------------------------------------------------------

func _on_player_leveled_up(_level: int) -> void:
	_pending_level_ups += 1
	if not level_up_panel.visible and not finished:
		_open_level_up()


func _open_level_up() -> void:
	get_tree().paused = true
	Sfx.play("levelup", 0.0, 0.2)
	level_up_panel.open(upgrades.roll_choices(3), player.level)


func _on_upgrade_chosen(choice: UpgradeService.Choice) -> void:
	upgrades.apply(choice)
	_pending_level_ups -= 1
	if _pending_level_ups > 0:
		_open_level_up()
	else:
		level_up_panel.close()
		get_tree().paused = false
