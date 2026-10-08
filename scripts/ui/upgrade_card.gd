class_name UpgradeCard
extends Button
## Carte cliquable présentant une amélioration lors de la montée de niveau.

var choice: UpgradeService.Choice

@onready var icon_rect: TextureRect = %Icon
@onready var title_label: Label = %Title
@onready var tag_label: Label = %Tag
@onready var desc_label: Label = %Description
@onready var key_label: Label = %Key


func show_choice(c: UpgradeService.Choice, index: int) -> void:
	choice = c
	icon_rect.texture = SpriteFx.atlas(c.icon_sheet, c.icon_frame)
	icon_rect.modulate = c.icon_tint
	title_label.text = c.title
	tag_label.text = c.tag
	tag_label.visible = c.tag != ""
	desc_label.text = c.description
	key_label.text = str(index + 1)
	var color := Color(1.0, 0.85, 0.35)
	match c.kind:
		UpgradeService.Kind.NEW_WEAPON:
			color = Color(0.5, 1.0, 0.55)
		UpgradeService.Kind.PASSIVE:
			if c.upgrade.category == UpgradeData.Category.ECHO:
				color = Companion.ECHO_COLOR
	tag_label.add_theme_color_override("font_color", color)
