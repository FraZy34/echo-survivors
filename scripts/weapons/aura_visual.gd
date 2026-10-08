class_name AuraVisual
extends Node2D
## Cercle translucide affiché sous le joueur pour l'aura ; s'illumine à chaque impulsion.

var radius := 36.0
var color := Color(1.0, 0.6, 0.2)
var _pulse := 0.0


func pulse() -> void:
	_pulse = 1.0


func _process(delta: float) -> void:
	_pulse = maxf(0.0, _pulse - delta * 4.0)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(color, 0.10 + 0.12 * _pulse))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(color, 0.35 + 0.4 * _pulse), 1.0)
