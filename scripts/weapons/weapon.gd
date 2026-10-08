class_name Weapon
extends Node
## Classe de base des armes. Gère la recharge automatique, le niveau et le calcul des stats.
##
## Une attaque est découpée en deux temps pour que l'Écho puisse la rejouer :
##   1. build_attack(source) : décide de la visée et renvoie des paramètres RELATIFS à la source
##      (directions, décalages...) ;
##   2. perform(source, params, power, is_echo) : exécute l'attaque depuis la source.
## Le joueur fait 1 puis 2 ; l'Écho refait 2 avec les mêmes paramètres, deux secondes plus tard.

signal attacked(weapon: Weapon, params: Dictionary)

const ECHO_TINT := Color(0.55, 1.0, 1.0, 0.75)

var data: WeaponData
var level := 1
var player: Player

var _cooldown_left := 0.4
var _bonus := {}


func setup(weapon_data: WeaponData, owner_player: Player) -> void:
	data = weapon_data
	player = owner_player
	name = String(data.id)
	_recompute_bonus()
	_on_setup()


func is_max_level() -> bool:
	return level >= data.max_level


func level_up() -> void:
	level = mini(level + 1, data.max_level)
	_recompute_bonus()
	_on_level_changed()


func _physics_process(delta: float) -> void:
	if player == null or player.dead:
		return
	_cooldown_left -= delta
	if _cooldown_left > 0.0:
		return
	var params := build_attack(player)
	if params.is_empty():
		_cooldown_left = 0.15  # Aucune cible : on réessaie bientôt.
		return
	perform(player, params, 1.0, false)
	attacked.emit(self, params)
	_cooldown_left = get_cooldown()


# --- Statistiques effectives (base + bonus de niveau + stats du joueur) -----------------

func get_damage() -> float:
	return (data.damage + float(_bonus.get("damage", 0.0))) * player.stats.might


func get_amount() -> int:
	return data.amount + int(_bonus.get("amount", 0.0)) + int(player.stats.amount)


func get_area() -> float:
	return (data.area + float(_bonus.get("area", 0.0))) * player.stats.area


func get_speed() -> float:
	return (data.speed + float(_bonus.get("speed", 0.0))) * player.stats.proj_speed


func get_duration() -> float:
	return (data.duration + float(_bonus.get("duration", 0.0))) * player.stats.duration


func get_pierce() -> int:
	if data.pierce < 0:
		return -1
	return data.pierce + int(_bonus.get("pierce", 0.0))


func get_cooldown() -> float:
	return data.cooldown * float(_bonus.get("cooldown", 1.0)) * player.stats.cooldown


# --- À surcharger ---------------------------------------------------------------------

func _on_setup() -> void:
	pass


func _on_level_changed() -> void:
	pass


## Renvoie {} si l'arme n'a pas de cible.
func build_attack(_source: Node2D) -> Dictionary:
	return {}


func perform(_source: Node2D, _params: Dictionary, _power: float, _is_echo: bool) -> void:
	pass


## Version « miroir » d'une attaque (amélioration Reflet de l'Écho) : directions inversées.
func mirror_params(params: Dictionary) -> Dictionary:
	var mirrored := params.duplicate(true)
	for key in ["dirs", "offsets"]:
		if mirrored.has(key):
			var list: Array = mirrored[key]
			for i in list.size():
				list[i] = -(list[i] as Vector2)
	return mirrored


# --- Aides pour les sous-classes ------------------------------------------------------

func _new_projectile(power: float, is_echo: bool) -> Projectile:
	var p := Arena.instance.projectiles.acquire()
	SpriteFx.set_tile(p, data.projectile_sheet, data.projectile_frame)
	p.self_modulate = data.projectile_tint
	p.is_echo = is_echo
	if is_echo:
		p.modulate = ECHO_TINT
	p.damage = get_damage() * power
	p.knockback = data.knockback
	p.radius = data.hit_radius * get_area()
	p.pierce = get_pierce()
	p.scale = Vector2.ONE * data.projectile_scale * sqrt(get_area())
	p.spin = data.spin_speed
	return p


func _recompute_bonus() -> void:
	_bonus.clear()
	for i in mini(level - 1, data.level_bonuses.size()):
		var bonus: Dictionary = data.level_bonuses[i]
		for key: String in bonus:
			if key == "cooldown":
				_bonus[key] = float(_bonus.get(key, 1.0)) * float(bonus[key])
			else:
				_bonus[key] = float(_bonus.get(key, 0.0)) + float(bonus[key])
