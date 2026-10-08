class_name UpgradeData
extends Resource
## Amélioration passive : modifie une statistique de PlayerStats à chaque prise.

enum Category { STAT, ECHO }

@export var id: StringName = &""
@export var display_name := ""
@export_multiline var description := ""
@export var icon_sheet: Texture2D
@export var icon_frame := 0
@export var icon_tint := Color.WHITE
@export var category: Category = Category.STAT
## Nom de la propriété de PlayerStats modifiée.
@export var stat: StringName = &""
@export var value := 0.1
@export var max_stacks := 5
## Poids relatif lors du tirage des choix.
@export var weight := 1.0
