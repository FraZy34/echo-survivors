extends Node
## Autoload « GameState » : données de jeu, niveau sélectionné, options,
## sauvegarde des meilleurs scores par niveau et configuration des touches.

const DATABASE_PATH := "res://resources/game_database.tres"
const SAVE_PATH := "user://savegame.cfg"

const MAIN_MENU := "res://scenes/menus/main_menu.tscn"
const LEVEL_SELECT := "res://scenes/menus/level_select.tscn"
const GAME := "res://scenes/game/game.tscn"

var db: GameDatabase
var current_level: LevelData
var show_damage_numbers := true
var sfx_volume := 0.8
var music_volume := 0.6

var _save := ConfigFile.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	if not ResourceLoader.exists(DATABASE_PATH):
		push_error("Base de données introuvable : " + DATABASE_PATH)
		return
	db = load(DATABASE_PATH) as GameDatabase
	current_level = db.levels[0]
	_load()


# --- Navigation ------------------------------------------------------------

func start_level(level: LevelData) -> void:
	current_level = level
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME)


func goto_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)


func goto_level_select() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(LEVEL_SELECT)


# --- Sauvegarde -------------------------------------------------------------

## Renvoie {score, time, kills, completed} pour un niveau.
func get_best(level_id: StringName) -> Dictionary:
	var section := "level_" + String(level_id)
	return {
		"score": int(_save.get_value(section, "best_score", 0)),
		"time": float(_save.get_value(section, "best_time", 0.0)),
		"kills": int(_save.get_value(section, "best_kills", 0)),
		"completed": bool(_save.get_value(section, "completed", false)),
	}


## Enregistre une partie ; renvoie true si le score bat le record du niveau.
func record_result(level_id: StringName, score: int, time: float, kills: int, completed: bool) -> bool:
	var section := "level_" + String(level_id)
	var best := get_best(level_id)
	var is_record := score > int(best.score)
	if is_record:
		_save.set_value(section, "best_score", score)
		_save.set_value(section, "best_kills", kills)
	if time > float(best.time):
		_save.set_value(section, "best_time", time)
	if completed:
		_save.set_value(section, "completed", true)
	_write()
	return is_record


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_save.set_value("options", "sfx_volume", sfx_volume)
	_write()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	Sfx.update_music_volume()
	_save.set_value("options", "music_volume", music_volume)
	_write()


func set_damage_numbers(enabled: bool) -> void:
	show_damage_numbers = enabled
	_save.set_value("options", "damage_numbers", enabled)
	_write()


func set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
	_save.set_value("options", "fullscreen", enabled)
	_write()


func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


func _load() -> void:
	_save.load(SAVE_PATH)  # Absent au premier lancement : on garde les valeurs par défaut.
	show_damage_numbers = bool(_save.get_value("options", "damage_numbers", true))
	sfx_volume = float(_save.get_value("options", "sfx_volume", 0.8))
	music_volume = float(_save.get_value("options", "music_volume", 0.6))
	if bool(_save.get_value("options", "fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _write() -> void:
	_save.save(SAVE_PATH)


# --- Entrées -----------------------------------------------------------------

## Touches physiques : la position W/A/S/D correspond à Z/Q/S/D sur un clavier AZERTY.
func _setup_input() -> void:
	_add_action(&"move_up", [KEY_W, KEY_UP], JOY_AXIS_LEFT_Y, -1.0)
	_add_action(&"move_down", [KEY_S, KEY_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_add_action(&"move_left", [KEY_A, KEY_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_add_action(&"move_right", [KEY_D, KEY_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_add_action(&"pause", [KEY_ESCAPE, KEY_P], -1, 0.0)


func _add_action(action: StringName, keys: Array, axis: int, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.25)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
	if axis >= 0:
		var joy := InputEventJoypadMotion.new()
		joy.axis = axis
		joy.axis_value = axis_value
		InputMap.action_add_event(action, joy)
