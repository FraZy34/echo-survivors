extends Control
## Menu principal : jouer, comment jouer, options, crédits, quitter.

@export var music: AudioStream

@onready var play_button: Button = %PlayButton
@onready var howto_button: Button = %HowToButton
@onready var options_button: Button = %OptionsButton
@onready var credits_button: Button = %CreditsButton
@onready var quit_button: Button = %QuitButton
@onready var main_box: Control = %MainBox
@onready var howto_panel: Control = %HowToPanel
@onready var options_panel: Control = %OptionsPanel
@onready var credits_panel: Control = %CreditsPanel
@onready var volume_slider: HSlider = %VolumeSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var numbers_check: CheckButton = %NumbersCheck
@onready var fullscreen_check: CheckButton = %FullscreenCheck


func _ready() -> void:
	get_tree().paused = false
	Sfx.play_music(music)
	play_button.pressed.connect(_click.bind(GameState.goto_level_select))
	howto_button.pressed.connect(_click.bind(_show_panel.bind(howto_panel)))
	options_button.pressed.connect(_click.bind(_show_panel.bind(options_panel)))
	credits_button.pressed.connect(_click.bind(_show_panel.bind(credits_panel)))
	quit_button.pressed.connect(get_tree().quit)
	for panel in [howto_panel, options_panel, credits_panel]:
		panel.visible = false
		var back: Button = panel.find_child("BackButton")
		back.pressed.connect(_click.bind(_show_panel.bind(null)))

	volume_slider.value = GameState.sfx_volume
	volume_slider.value_changed.connect(func(v: float) -> void:
		GameState.set_sfx_volume(v)
		Sfx.play("pickup", 0.0, 0.1))
	music_slider.value = GameState.music_volume
	music_slider.value_changed.connect(GameState.set_music_volume)
	numbers_check.button_pressed = GameState.show_damage_numbers
	numbers_check.toggled.connect(GameState.set_damage_numbers)
	fullscreen_check.button_pressed = GameState.is_fullscreen()
	fullscreen_check.toggled.connect(GameState.set_fullscreen)
	play_button.grab_focus()


func _click(action: Callable) -> void:
	Sfx.play("click")
	action.call()


func _show_panel(panel: Control) -> void:
	for p in [howto_panel, options_panel, credits_panel]:
		p.visible = p == panel
	main_box.visible = panel == null
	if panel:
		(panel.find_child("BackButton") as Button).grab_focus()
	else:
		play_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and not main_box.visible:
		_show_panel(null)
