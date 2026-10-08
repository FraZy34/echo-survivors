class_name GameDatabase
extends Resource
## Point d'entrée unique vers toutes les données de jeu (niveaux, armes, améliorations).

@export var levels: Array[LevelData] = []
@export var weapons: Array[WeaponData] = []
@export var passives: Array[UpgradeData] = []
@export var starting_weapon: WeaponData

@export_group("Icônes diverses")
@export var items_sheet: Texture2D
@export var heal_icon_frame := 0
@export var gold_icon_frame := 0


func get_level(level_id: StringName) -> LevelData:
	for level in levels:
		if level.id == level_id:
			return level
	return levels[0] if not levels.is_empty() else null
