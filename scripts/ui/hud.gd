class_name Hud
extends CanvasLayer
## Interface en jeu : PV, expérience, chrono, compteur d'ennemis, armes, battement de l'Écho
## et barre de vie du boss.

var _arena: Arena
var _boss: Enemy
var _banner_t := 0.0
var _slot_style := _make_slot_style()

@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var level_label: Label = %LevelLabel
@onready var time_label: Label = %TimeLabel
@onready var boss_timer_label: Label = %BossTimerLabel
@onready var kills_label: Label = %KillsLabel
@onready var weapon_row: HBoxContainer = %WeaponRow
@onready var echo_bar: ProgressBar = %EchoBar
@onready var boss_panel: Control = %BossPanel
@onready var boss_name: Label = %BossName
@onready var boss_bar: ProgressBar = %BossBar
@onready var banner: Label = %Banner


func setup(arena: Arena) -> void:
	_arena = arena
	var player := arena.player
	player.hp_changed.connect(_on_hp_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.weapons_changed.connect(_refresh_weapons)
	_on_hp_changed(player.hp, player.stats.max_hp)
	_on_xp_changed(player.xp, player.xp_needed, player.level)
	boss_panel.visible = false
	show_banner(arena.level.display_name, 3.0)


func _process(delta: float) -> void:
	if _arena == null:
		return
	time_label.text = format_time(_arena.elapsed)
	kills_label.text = str(_arena.kills)
	var left := _arena.spawner.time_left()
	boss_timer_label.text = "Boss dans %s" % format_time(left) if left > 0.0 else "Boss !"
	echo_bar.value = _arena.companion.beat_progress()
	if _boss:
		boss_bar.value = maxf(0.0, _boss.hp / _boss.max_hp)
		if not _boss.alive:
			_boss = null
			boss_panel.visible = false
	if _banner_t > 0.0:
		_banner_t -= delta
		banner.modulate.a = clampf(_banner_t, 0.0, 1.0)
		banner.visible = _banner_t > 0.0


func show_banner(text: String, duration: float) -> void:
	banner.text = text
	banner.visible = true
	banner.modulate.a = 1.0
	_banner_t = duration


func show_boss_warning() -> void:
	show_banner("Un boss approche !", 4.0)
	Sfx.play("boss", 0.0, 0.5, 1.2)


func show_boss(boss: Enemy) -> void:
	_boss = boss
	boss_name.text = boss.data.display_name
	boss_panel.visible = true


static func _make_slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.07, 0.13, 0.85)
	style.border_color = Color(0.4, 0.32, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(2.0)
	return style


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d" % [s / 60, s % 60]


func _on_hp_changed(hp: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_label.text = "%d / %d" % [ceili(hp), int(max_hp)]


func _on_xp_changed(xp: int, needed: int, lv: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = xp
	level_label.text = "Niv. %d" % lv


func _refresh_weapons() -> void:
	for child in weapon_row.get_children():
		child.queue_free()
	for weapon in _arena.player.weapons:
		var slot := PanelContainer.new()
		slot.add_theme_stylebox_override("panel", _slot_style)
		slot.tooltip_text = weapon.data.display_name
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(18, 18)
		icon.texture = SpriteFx.atlas(weapon.data.icon_sheet, weapon.data.icon_frame)
		icon.modulate = weapon.data.icon_tint
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.add_child(icon)
		var lv := Label.new()
		lv.text = str(weapon.level) if not weapon.is_max_level() else "M"
		lv.add_theme_font_size_override("font_size", 8)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lv.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		slot.add_child(lv)
		weapon_row.add_child(slot)
