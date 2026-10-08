class_name UpgradeService
extends RefCounted
## Construit les choix proposés à chaque montée de niveau : nouvelles armes, niveaux d'armes,
## améliorations de statistiques et bonus d'Écho, tirés au hasard (pondérés) sans doublon.

const MAX_WEAPONS := 6

enum Kind { NEW_WEAPON, WEAPON_LEVEL, PASSIVE, HEAL, GOLD }


class Choice:
	extends RefCounted
	var kind: Kind
	var title := ""
	var description := ""
	var tag := ""
	var icon_sheet: Texture2D
	var icon_frame := 0
	var icon_tint := Color.WHITE
	var weapon: WeaponData
	var upgrade: UpgradeData


var _db: GameDatabase
var _player: Player
var _stacks := {}


func _init(db: GameDatabase, player: Player) -> void:
	_db = db
	_player = player


func stacks_of(upgrade_id: StringName) -> int:
	return int(_stacks.get(upgrade_id, 0))


func roll_choices(count: int) -> Array[Choice]:
	var pool: Array[Choice] = []
	var weights: Array[float] = []

	for weapon in _player.weapons:
		if not weapon.is_max_level():
			var c := _weapon_choice(weapon.data, Kind.WEAPON_LEVEL)
			c.tag = "Niv. %d" % (weapon.level + 1)
			c.description = weapon.data.describe_level(weapon.level + 1)
			pool.append(c)
			weights.append(3.0)
	if _player.weapons.size() < MAX_WEAPONS:
		for data in _db.weapons:
			if _player.get_weapon(data.id) == null:
				var c := _weapon_choice(data, Kind.NEW_WEAPON)
				c.tag = "Nouveau !"
				c.description = data.description
				pool.append(c)
				weights.append(2.2)
	for upgrade in _db.passives:
		var stacks := stacks_of(upgrade.id)
		if stacks < upgrade.max_stacks:
			var c := Choice.new()
			c.kind = Kind.PASSIVE
			c.upgrade = upgrade
			c.title = upgrade.display_name
			c.description = upgrade.description
			c.tag = ("Écho %d/%d" if upgrade.category == UpgradeData.Category.ECHO else "%d/%d") % [stacks + 1, upgrade.max_stacks]
			c.icon_sheet = upgrade.icon_sheet
			c.icon_frame = upgrade.icon_frame
			c.icon_tint = upgrade.icon_tint
			pool.append(c)
			weights.append(upgrade.weight)

	var picked: Array[Choice] = []
	while picked.size() < count and not pool.is_empty():
		var index := _weighted_index(weights)
		picked.append(pool[index])
		pool.remove_at(index)
		weights.remove_at(index)
	if picked.is_empty():
		picked.append(_fallback(Kind.HEAL))
		picked.append(_fallback(Kind.GOLD))
	return picked


func apply(choice: Choice) -> void:
	match choice.kind:
		Kind.NEW_WEAPON:
			_player.add_weapon(choice.weapon)
		Kind.WEAPON_LEVEL:
			_player.level_up_weapon(choice.weapon.id)
		Kind.PASSIVE:
			_stacks[choice.upgrade.id] = stacks_of(choice.upgrade.id) + 1
			_player.apply_stat(choice.upgrade.stat, choice.upgrade.value)
		Kind.HEAL:
			_player.heal(50.0)
		Kind.GOLD:
			Arena.instance.bonus_score += 250


func _weapon_choice(data: WeaponData, kind: Kind) -> Choice:
	var c := Choice.new()
	c.kind = kind
	c.weapon = data
	c.title = data.display_name
	c.icon_sheet = data.icon_sheet
	c.icon_frame = data.icon_frame
	c.icon_tint = data.icon_tint
	return c


func _fallback(kind: Kind) -> Choice:
	var c := Choice.new()
	c.kind = kind
	c.icon_sheet = _db.items_sheet
	if kind == Kind.HEAL:
		c.title = "Festin du héros"
		c.description = "Restaure 50 PV."
		c.icon_frame = _db.heal_icon_frame
	else:
		c.title = "Trésor oublié"
		c.description = "+250 points de score."
		c.icon_frame = _db.gold_icon_frame
	return c


func _weighted_index(weights: Array[float]) -> int:
	var total := 0.0
	for w in weights:
		total += w
	var roll := randf() * total
	for i in weights.size():
		roll -= weights[i]
		if roll <= 0.0:
			return i
	return weights.size() - 1
