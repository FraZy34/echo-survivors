class_name PlayerStats
extends RefCounted
## Statistiques du joueur modifiées par les améliorations passives.
## Toutes les valeurs sont des flottants pour pouvoir être cumulées génériquement.

signal changed(stat: StringName)

var might := 1.0          ## Multiplicateur de dégâts.
var move_speed := 1.0     ## Multiplicateur de vitesse de déplacement.
var max_hp := 100.0
var armor := 0.0          ## Réduction plate des dégâts reçus.
var regen := 0.0          ## PV regagnés par seconde.
var cooldown := 1.0       ## Multiplicateur de recharge des armes (plus bas = plus rapide).
var area := 1.0           ## Multiplicateur de zone.
var proj_speed := 1.0     ## Multiplicateur de vitesse des projectiles.
var duration := 1.0       ## Multiplicateur de durée des effets.
var amount := 0.0         ## Projectiles supplémentaires pour toutes les armes.
var magnet := 42.0        ## Rayon d'attraction des gemmes (px).
var growth := 1.0         ## Multiplicateur d'expérience.
var echo_power := 0.6     ## Puissance des attaques rejouées par l'Écho.
var echo_mirror := 0.0    ## > 0 : l'Écho rejoue aussi chaque attaque en miroir.
var echo_pulse := 0.0     ## Niveau de l'onde émise par l'Écho toutes les 2 s.


func apply(stat: StringName, value: float) -> void:
	if stat == &"cooldown":
		cooldown = maxf(0.35, cooldown * (1.0 - value))
	else:
		set(stat, float(get(stat)) + value)
	changed.emit(stat)
