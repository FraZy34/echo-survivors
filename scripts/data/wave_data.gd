class_name WaveData
extends Resource
## Une vague : pendant [start_time, end_time[, des groupes d'ennemis apparaissent
## régulièrement hors de l'écran. Plusieurs vagues peuvent se chevaucher.

enum Formation {
	SCATTER,  ## Ennemis éparpillés tout autour du joueur.
	CLUSTER,  ## Un groupe compact arrivant d'une direction.
	RING,     ## Un cercle complet qui encercle le joueur.
}

@export var start_time := 0.0
@export var end_time := 60.0
@export var enemies: Array[EnemyData] = []
@export var spawn_interval := 1.0
@export var batch_size := 2
## La vague ne fait plus apparaître d'ennemis au-delà de ce nombre d'ennemis vivants.
@export var max_alive := 60
@export var formation: Formation = Formation.SCATTER
