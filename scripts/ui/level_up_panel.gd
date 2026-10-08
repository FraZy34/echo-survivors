class_name LevelUpPanel
extends CanvasLayer
## Panneau de montée de niveau : le jeu est en pause, le joueur choisit 1 amélioration parmi 3
## (souris, flèches + Entrée, ou touches 1-2-3).

signal chosen(choice: UpgradeService.Choice)

const CARD_SCENE := preload("res://scenes/ui/upgrade_card.tscn")
const INPUT_DELAY := 0.35  ## Évite de valider par erreur en appuyant sur une touche de jeu.

var _cards: Array[UpgradeCard] = []

@onready var cards_box: HBoxContainer = %Cards
@onready var title: Label = %Title


func _ready() -> void:
	visible = false


func open(choices: Array[UpgradeService.Choice], player_level: int) -> void:
	for card in _cards:
		card.queue_free()
	_cards.clear()
	title.text = "Niveau %d !" % player_level
	for i in choices.size():
		var card: UpgradeCard = CARD_SCENE.instantiate()
		cards_box.add_child(card)
		card.show_choice(choices[i], i)
		card.disabled = true
		card.pressed.connect(_on_card_pressed.bind(card))
		_cards.append(card)
	visible = true
	get_tree().create_timer(INPUT_DELAY, true).timeout.connect(_enable_cards)


func close() -> void:
	visible = false


func _enable_cards() -> void:
	for card in _cards:
		if is_instance_valid(card):
			card.disabled = false
	if not _cards.is_empty():
		_cards[0].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed:
		return
	var index := -1
	match (event as InputEventKey).physical_keycode:
		KEY_1, KEY_KP_1:
			index = 0
		KEY_2, KEY_KP_2:
			index = 1
		KEY_3, KEY_KP_3:
			index = 2
	if index >= 0 and index < _cards.size() and not _cards[index].disabled:
		get_viewport().set_input_as_handled()
		_on_card_pressed(_cards[index])


func _on_card_pressed(card: UpgradeCard) -> void:
	for c in _cards:
		c.disabled = true
	Sfx.play("click")
	chosen.emit(card.choice)
