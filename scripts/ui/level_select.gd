extends Control
## Écran de sélection de niveau : une carte par niveau de la base de données.

const CARD_SCENE := preload("res://scenes/ui/level_card.tscn")

@export var music: AudioStream

@onready var cards_box: HBoxContainer = %Cards
@onready var back_button: Button = %BackButton


func _ready() -> void:
	get_tree().paused = false
	Sfx.play_music(music)
	back_button.pressed.connect(GameState.goto_menu)
	var levels := GameState.db.levels
	for i in levels.size():
		var card: LevelCard = CARD_SCENE.instantiate()
		cards_box.add_child(card)
		card.show_level(levels[i], i)
		card.play_requested.connect(_on_play)
	var first: LevelCard = cards_box.get_child(0)
	first.play_button.grab_focus()


func _on_play(level: LevelData) -> void:
	Sfx.play("click")
	GameState.start_level(level)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		GameState.goto_menu()
