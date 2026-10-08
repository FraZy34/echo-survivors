class_name PauseMenu
extends CanvasLayer
## Menu pause (Échap / P) : reprendre, recommencer ou quitter vers le menu.

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton
@onready var stats_label: Label = %StatsLabel


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(func() -> void: GameState.start_level(GameState.current_level))
	quit_button.pressed.connect(GameState.goto_menu)


func open() -> void:
	var arena := Arena.instance
	var s := arena.player.stats
	stats_label.text = "Dégâts x%.2f   Vitesse x%.2f   Recharge x%.2f\nZone x%.2f   Armure %d   Régén. %.1f/s   Aimant %d px\nPuissance de l'Écho %d %%%s%s" % [
		s.might, s.move_speed, s.cooldown, s.area, int(s.armor), s.regen, int(s.magnet),
		roundi(s.echo_power * 100.0),
		"   Reflet" if s.echo_mirror > 0.0 else "",
		"   Onde niv. %d" % int(s.echo_pulse) if s.echo_pulse > 0.0 else ""]
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
