class_name WeaponData
extends Resource
## Définition d'une arme : statistiques de base, progression par niveau et visuels.
## Le comportement est fourni par un script dérivé de Weapon (champ `behavior`).

enum Aim {
	NEAREST,       ## Vise l'ennemi le plus proche.
	RANDOM_ENEMY,  ## Vise un ennemi au hasard autour du joueur.
	FACING,        ## Tire dans la direction de déplacement.
	AROUND,        ## Répartit les tirs en cercle.
}

const BONUS_LABELS := {
	"damage": "Dégâts +%s",
	"amount": "+%s projectile(s)",
	"pierce": "Perforation +%s",
	"area": "Zone +%s%%",
	"speed": "Vitesse +%s",
	"duration": "Durée +%ss",
	"cooldown": "Recharge -%s%%",
}

@export var id: StringName = &""
@export var display_name := ""
@export_multiline var description := ""
@export var icon_sheet: Texture2D
@export var icon_frame := 0
@export var icon_tint := Color.WHITE
## Script de comportement (sous-classe de Weapon).
@export var behavior: Script
@export var max_level := 5

@export_group("Statistiques")
@export var damage := 10.0
@export var cooldown := 1.0
@export var amount := 1
## Vitesse des projectiles (px/s) ou vitesse angulaire (rad/s) pour les armes orbitales.
@export var speed := 200.0
@export var area := 1.0
@export var duration := 1.0
## Nombre d'ennemis touchés avant disparition (-1 = infini).
@export var pierce := 1
@export var knockback := 60.0
@export var hit_radius := 6.0
@export var aim: Aim = Aim.NEAREST
@export var spread_deg := 12.0
@export var max_range := 300.0

@export_group("Projectile")
@export var projectile_sheet: Texture2D
@export var projectile_frame := 0
@export var projectile_tint := Color.WHITE
@export var projectile_scale := 1.0
## Décalage (radians) pour aligner le sprite sur sa direction de vol.
@export var sprite_angle := 0.0
@export var orient_to_direction := true
@export var spin_speed := 0.0

@export_group("Progression")
## Bonus cumulés à chaque niveau (index 0 → niveau 2).
## Clés : damage, amount, pierce, area, speed, duration (additifs), cooldown (facteur multiplicatif).
@export var level_bonuses: Array[Dictionary] = []


## Texte décrivant ce que rapporte le passage au niveau `lv`.
func describe_level(lv: int) -> String:
	if lv <= 1:
		return description
	var index := lv - 2
	if index >= level_bonuses.size():
		return "Niveau maximum."
	var parts: PackedStringArray = []
	var bonus: Dictionary = level_bonuses[index]
	for key in bonus:
		var value: float = bonus[key]
		var shown: String
		match key:
			"area":
				shown = str(roundi(value * 100.0))
			"cooldown":
				shown = str(roundi((1.0 - value) * 100.0))
			_:
				shown = str(snappedf(value, 0.1)).trim_suffix(".0")
		parts.append(BONUS_LABELS.get(key, key + " %s") % shown)
	return ", ".join(parts)
