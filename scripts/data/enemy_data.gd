class_name EnemyData
extends Resource
## Définition d'un type d'ennemi. La scène (enemy, charger, ranged, boss) fournit le
## comportement ; cette ressource fournit les visuels et les statistiques.

@export var id: StringName = &""
@export var display_name := ""
## Scène instanciée (racine dérivée de Enemy). Les instances sont recyclées par pool.
@export var scene: PackedScene

@export_group("Visuel")
@export var sheet: Texture2D
## Indices de tuiles (planche 16x16) jouées en boucle.
@export var frames := PackedInt32Array([0])
@export var anim_fps := 4.0
## Image affichée pendant une attaque spéciale (-1 = aucune).
@export var attack_frame := -1
@export var tint := Color.WHITE
@export var sprite_scale := 1.0

@export_group("Statistiques")
@export var max_hp := 10.0
@export var speed := 40.0
@export var damage := 5.0
@export var xp := 1
@export var hit_radius := 6.0
@export_range(0.0, 1.0) var knockback_resist := 0.0
## Amplitude de l'oscillation latérale (vol erratique des chauves-souris, fantômes...).
@export var wobble := 0.0

@export_group("Attaque spéciale")
@export var attack_interval := 2.5
@export var attack_speed := 140.0
@export var attack_range := 160.0
@export var projectile_sheet: Texture2D
@export var projectile_frame := 95
@export var projectile_tint := Color.WHITE

@export_group("Boss")
@export var is_boss := false
## Sbire invoqué par le boss.
@export var minion: EnemyData
