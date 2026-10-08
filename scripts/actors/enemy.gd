class_name Enemy
extends Sprite2D
## Classe de base des ennemis. Volontairement légère (un simple Sprite2D, sans physique) :
## l'EnemyManager met à jour tous les ennemis dans une seule boucle, gère les collisions par
## grille spatiale et recycle les instances via un pool.
## Les sous-classes ne surchargent que `_steer()` (et éventuellement `_on_activate()`).

var data: EnemyData
var manager: EnemyManager
var alive := false
var hp := 1.0
var max_hp := 1.0
var damage := 1.0
var speed := 1.0
var hit_radius := 6.0
var knock := Vector2.ZERO
var cell := Vector2i.ZERO
## Durée restante de la pose d'attaque (voir EnemyData.attack_frame).
var pose_time := 0.0

var _base_scale := 1.0
var _flash := 0.0
var _anim_t := 0.0
var _dying_t := 0.0


func activate(enemy_data: EnemyData, hp_mult: float, dmg_mult: float) -> void:
	data = enemy_data
	alive = true
	visible = true
	max_hp = data.max_hp * hp_mult
	hp = max_hp
	damage = data.damage * dmg_mult
	speed = data.speed * randf_range(0.9, 1.1)
	hit_radius = data.hit_radius
	knock = Vector2.ZERO
	_flash = 0.0
	_dying_t = 0.0
	pose_time = 0.0
	_anim_t = randf() * 10.0
	_base_scale = data.sprite_scale
	scale = Vector2.ONE * _base_scale
	rotation = 0.0
	offset = Vector2.ZERO
	modulate = Color.WHITE
	self_modulate = data.tint
	SpriteFx.set_tile(self, data.sheet, data.frames[0])
	_on_activate()


## Appelé par l'EnemyManager à chaque frame physique.
func tick(delta: float, target: Vector2) -> void:
	var to_target := target - position
	var vel := _steer(delta, to_target)
	if data.wobble > 0.0:
		vel += to_target.orthogonal().normalized() * sin(_anim_t * 4.0) * data.wobble
	position += (vel + knock) * delta
	knock = knock.move_toward(Vector2.ZERO, 900.0 * delta)
	if absf(vel.x) > 2.0:
		flip_h = vel.x < 0.0
	_animate(delta, vel != Vector2.ZERO)


## Retourne la vitesse souhaitée. Par défaut : poursuite directe du joueur.
func _steer(_delta: float, to_target: Vector2) -> Vector2:
	return to_target.normalized() * speed


func _on_activate() -> void:
	pass


func _animate(delta: float, moving: bool) -> void:
	_anim_t += delta
	if pose_time > 0.0 and data.attack_frame >= 0:
		pose_time -= delta
		frame = data.attack_frame
	elif data.frames.size() > 1:
		frame = data.frames[int(_anim_t * data.anim_fps) % data.frames.size()]
	scale = SpriteFx.walk_scale(_anim_t, moving, _base_scale)
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			self_modulate = data.tint


## Inflige des dégâts ; renvoie true si l'ennemi meurt.
func take_damage(amount: float, knockback: Vector2) -> bool:
	if not alive:
		return false
	hp -= amount
	_flash = 0.09
	self_modulate = Color(3.0, 3.0, 3.0)
	knock += knockback * (1.0 - data.knockback_resist)
	if hp <= 0.0:
		alive = false
		_on_death()
		return true
	return false


func _on_death() -> void:
	pass


## Animation de disparition ; renvoie false une fois terminée.
func update_dying(delta: float) -> bool:
	_dying_t += delta
	var k := 1.0 - _dying_t / 0.22
	scale = Vector2(_base_scale * (1.0 + (1.0 - k) * 0.6), _base_scale * k)
	modulate.a = k
	return k > 0.0


func deactivate() -> void:
	visible = false
	alive = false
