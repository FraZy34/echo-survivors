class_name LevelCard
extends PanelContainer
## Carte d'un niveau dans l'écran de sélection : aperçu, description, meilleur score.

signal play_requested(level: LevelData)

var level: LevelData

@onready var preview: ColorRect = %Preview
@onready var floor_icons: HBoxContainer = %FloorIcons
@onready var boss_icon: TextureRect = %BossIcon
@onready var name_label: Label = %NameLabel
@onready var desc_label: Label = %DescLabel
@onready var info_label: Label = %InfoLabel
@onready var best_label: Label = %BestLabel
@onready var play_button: Button = %PlayButton


func show_level(data: LevelData, index: int) -> void:
	level = data
	preview.color = data.background_color.lightened(0.15)
	for frame in data.decor_tiles.slice(0, 4):
		var t := TextureRect.new()
		t.texture = SpriteFx.atlas(data.tileset, frame)
		t.custom_minimum_size = Vector2(16, 16)
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		floor_icons.add_child(t)
	if data.boss:
		boss_icon.texture = SpriteFx.atlas(data.boss.sheet, data.boss.frames[0])
		boss_icon.modulate = data.boss.tint
	name_label.text = "%d. %s" % [index + 1, data.display_name]
	desc_label.text = data.description
	info_label.text = "Boss à %s : %s" % [Hud.format_time(data.duration), data.boss.display_name if data.boss else "?"]
	var best := GameState.get_best(data.id)
	if int(best.score) > 0:
		best_label.text = "Record : %d pts  |  %s%s" % [best.score, Hud.format_time(best.time), "  |  Terminé" if best.completed else ""]
	else:
		best_label.text = "Pas encore joué"
	play_button.pressed.connect(func() -> void: play_requested.emit(level))
