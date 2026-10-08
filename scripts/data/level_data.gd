class_name LevelData
extends Resource
## Un niveau jouable : décor généré, vagues d'ennemis, boss final et courbe de difficulté.

@export var id: StringName = &""
@export var display_name := ""
@export_multiline var description := ""

@export_group("Décor")
@export var tileset: Texture2D
@export var floor_tiles := PackedInt32Array([0])
@export var floor_weights := PackedFloat32Array([1.0])
@export var decor_tiles := PackedInt32Array()
@export_range(0.0, 0.5) var decor_density := 0.04
@export var background_color := Color(0.1, 0.1, 0.12)
@export var ambient := Color.WHITE
@export var music: AudioStream

@export_group("Déroulement")
## Durée (s) avant l'arrivée du boss.
@export var duration := 300.0
@export var waves: Array[WaveData] = []
@export var boss: EnemyData
## Multiplicateur de PV ennemis au départ, puis croissance par minute.
@export var hp_base := 1.0
@export var hp_growth_per_minute := 0.35
@export var damage_growth_per_minute := 0.08
