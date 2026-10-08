class_name GameOverScreen
extends CanvasLayer
## Écran de fin de partie : victoire ou défaite, temps de survie, score et meilleur score.

@onready var title: Label = %Title
@onready var subtitle: Label = %Subtitle
@onready var time_value: Label = %TimeValue
@onready var kills_value: Label = %KillsValue
@onready var level_value: Label = %LevelValue
@onready var score_value: Label = %ScoreValue
@onready var best_value: Label = %BestValue
@onready var record_label: Label = %RecordLabel
@onready var retry_button: Button = %RetryButton
@onready var select_button: Button = %SelectButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	visible = false
	retry_button.pressed.connect(func() -> void: GameState.start_level(GameState.current_level))
	select_button.pressed.connect(GameState.goto_level_select)
	menu_button.pressed.connect(GameState.goto_menu)


func show_result(result: Dictionary) -> void:
	var victory: bool = result.victory
	title.text = "Victoire !" if victory else "Défaite..."
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35) if victory else Color(1.0, 0.4, 0.4))
	if victory:
		subtitle.text = "%s est terrassé !" % result.boss_name
	else:
		subtitle.text = "Votre aventure s'arrête ici : %s" % result.level_name
	time_value.text = Hud.format_time(result.time)
	kills_value.text = str(result.kills)
	level_value.text = str(result.player_level)
	score_value.text = str(result.score)
	best_value.text = str(result.best)
	record_label.visible = result.record
	visible = true
	retry_button.grab_focus()
