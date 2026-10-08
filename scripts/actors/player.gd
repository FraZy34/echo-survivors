class_name Player
extends Node2D
## Héros contrôlé au clavier (ZQSD / flèches). Aucune touche d'attaque :
## chaque arme enfant tire automatiquement selon sa recharge.

signal hp_changed(hp: float, max_hp: float)
signal xp_changed(xp: int, needed: int, level: int)
signal leveled_up(level: int)
signal weapons_changed
## Émis à chaque attaque d'une arme ; l'Écho s'en sert pour rejouer l'action 2 s plus tard.
signal attacked(weapon: Weapon, params: Dictionary)
signal died

const BASE_SPEED := 78.0
const INVULNERABILITY := 0.45

@export var radius := 6.0
@export_group("Animation")
@export var idle_frames := PackedInt32Array([0])
@export var walk_frames := PackedInt32Array([1, 2, 3, 4])
@export var walk_fps := 9.0

var stats := PlayerStats.new()
var hp := 100.0
var level := 1
var xp := 0
var xp_needed := 5
var facing := Vector2.RIGHT
var velocity := Vector2.ZERO
var weapons: Array[Weapon] = []
var invulnerable := false
var dead := false

var _iframes := 0.0
var _anim_t := 0.0
var _hurt_flash := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var weapons_root: Node = $Weapons
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	hp = stats.max_hp
	xp_needed = _xp_for_level(level)


func _physics_process(delta: float) -> void:
	if dead:
		return
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = input * BASE_SPEED * stats.move_speed
	position += velocity * delta
	if input != Vector2.ZERO:
		facing = input.normalized()
		if absf(input.x) > 0.1:
			sprite.flip_h = input.x < 0.0

	if stats.regen > 0.0 and hp < stats.max_hp:
		heal(stats.regen * delta)
	_iframes = maxf(0.0, _iframes - delta)
	_animate(delta)


func _animate(delta: float) -> void:
	_anim_t += delta
	var moving := velocity != Vector2.ZERO
	var frames := walk_frames if moving else idle_frames
	sprite.frame = frames[int(_anim_t * walk_fps) % frames.size()]
	sprite.scale = SpriteFx.walk_scale(_anim_t, moving, 1.0)
	if _hurt_flash > 0.0:
		_hurt_flash -= delta
		sprite.modulate = Color(1.0, 0.35, 0.35) if fmod(_hurt_flash, 0.1) > 0.05 else Color.WHITE
		if _hurt_flash <= 0.0:
			sprite.modulate = Color.WHITE


# --- Combat -------------------------------------------------------------------

func take_damage(amount: float) -> void:
	if dead or invulnerable or _iframes > 0.0:
		return
	var final := maxf(1.0, amount - stats.armor)
	hp = maxf(0.0, hp - final)
	_iframes = INVULNERABILITY
	_hurt_flash = INVULNERABILITY
	Sfx.play("hurt", 0.05, 0.15)
	hp_changed.emit(hp, stats.max_hp)
	if hp <= 0.0:
		dead = true
		died.emit()


func heal(amount: float) -> void:
	hp = minf(stats.max_hp, hp + amount)
	hp_changed.emit(hp, stats.max_hp)


# --- Expérience ----------------------------------------------------------------

func gain_xp(amount: int) -> void:
	xp += maxi(1, roundi(amount * stats.growth))
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = _xp_for_level(level)
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_needed, level)


func _xp_for_level(lv: int) -> int:
	return int(5 + (lv - 1) * 6 + pow(lv - 1, 1.55))


# --- Armes ------------------------------------------------------------------------

func add_weapon(data: WeaponData) -> Weapon:
	var weapon: Weapon = data.behavior.new()
	weapons_root.add_child(weapon)
	weapon.setup(data, self)
	weapon.attacked.connect(func(w: Weapon, params: Dictionary) -> void: attacked.emit(w, params))
	weapons.append(weapon)
	weapons_changed.emit()
	return weapon


func get_weapon(id: StringName) -> Weapon:
	for weapon in weapons:
		if weapon.data.id == id:
			return weapon
	return null


func level_up_weapon(id: StringName) -> void:
	var weapon := get_weapon(id)
	if weapon:
		weapon.level_up()
		weapons_changed.emit()


func apply_stat(stat: StringName, value: float) -> void:
	stats.apply(stat, value)
	if stat == &"max_hp":
		heal(value)
	hp_changed.emit(hp, stats.max_hp)
