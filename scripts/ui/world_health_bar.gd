extends Node2D
## Petite barre de vie dessinée sous le joueur.

const SIZE := Vector2(16, 2)

var _ratio := 1.0


func _ready() -> void:
	var player := get_parent() as Player
	player.hp_changed.connect(_on_hp_changed)


func _on_hp_changed(hp: float, max_hp: float) -> void:
	_ratio = clampf(hp / max_hp, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var origin := -SIZE * 0.5
	draw_rect(Rect2(origin - Vector2.ONE, SIZE + Vector2.ONE * 2), Color(0.1, 0.05, 0.1, 0.8))
	draw_rect(Rect2(origin, Vector2(SIZE.x * _ratio, SIZE.y)), Color(0.9, 0.2, 0.25))
