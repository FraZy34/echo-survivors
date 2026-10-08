class_name Pickup
extends Sprite2D
## Objet ramassable (gemme d'XP, potion, cloche). Données uniquement : le PickupManager
## gère l'attraction et le ramassage dans une boucle unique.

enum Kind { GEM, POTION, BELL }

var kind := Kind.GEM
var value := 1
var attracted := false
var speed := 0.0
