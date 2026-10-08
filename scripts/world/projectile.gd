class_name Projectile
extends Sprite2D
## Projectile recyclable. Simple conteneur de données : tout le déplacement et les collisions
## sont calculés par le ProjectileManager dans une boucle unique.

enum Kind {
	LINEAR,  ## Ligne droite.
	ORBIT,   ## Tourne autour d'un nœud d'ancrage (joueur ou Écho).
	LOB,     ## Trajectoire en cloche puis explosion à l'arrivée.
}

var kind := Kind.LINEAR
var hostile := false
var is_echo := false
var velocity := Vector2.ZERO
var damage := 0.0
var knockback := 0.0
var radius := 5.0
var pierce := 1
var lifetime := 2.0
## Délai avant de pouvoir retoucher le même ennemi (0 = une seule fois).
var rehit_interval := 0.0
var spin := 0.0
var hit_log := {}

var anchor: Node2D
var orbit_angle := 0.0
var orbit_radius := 30.0
var orbit_speed := 3.0

var lob_from := Vector2.ZERO
var lob_to := Vector2.ZERO
var lob_t := 0.0
var lob_time := 0.6
var explode_radius := 30.0


func reset() -> void:
	kind = Kind.LINEAR
	hostile = false
	is_echo = false
	velocity = Vector2.ZERO
	damage = 0.0
	knockback = 0.0
	radius = 5.0
	pierce = 1
	lifetime = 2.0
	rehit_interval = 0.0
	spin = 0.0
	hit_log.clear()
	anchor = null
	lob_t = 0.0
	rotation = 0.0
	scale = Vector2.ONE
	modulate = Color.WHITE
	self_modulate = Color.WHITE
	visible = true
