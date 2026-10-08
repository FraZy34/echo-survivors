class_name SpriteFx
## Utilitaires partagés pour afficher des tuiles 16x16 issues des planches Kenney
## et animer les personnages (rebond de marche, écrasement/étirement).

const TILE := 16


## Configure un Sprite2D pour afficher la tuile `frame` d'une planche.
## Toutes les instances partagent la même texture : le moteur peut regrouper les draw calls.
static func set_tile(sprite: Sprite2D, sheet: Texture2D, frame: int) -> void:
	if sprite.texture != sheet:
		sprite.texture = sheet
		sprite.hframes = maxi(1, sheet.get_width() / TILE)
		sprite.vframes = maxi(1, sheet.get_height() / TILE)
	sprite.frame = frame


## Crée une AtlasTexture pour utiliser une tuile dans l'interface (TextureRect, icônes...).
static func atlas(sheet: Texture2D, frame: int) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = sheet
	var cols := maxi(1, sheet.get_width() / TILE)
	tex.region = Rect2((frame % cols) * TILE, (frame / cols) * TILE, TILE, TILE)
	return tex


## Rebond de marche : renvoie l'échelle à appliquer pour un léger squash & stretch.
static func walk_scale(t: float, moving: bool, base: float) -> Vector2:
	if not moving:
		var breathe := sin(t * 3.0) * 0.03
		return Vector2(base * (1.0 - breathe), base * (1.0 + breathe))
	var bob := absf(sin(t * 10.0))
	return Vector2(base * (1.0 + bob * 0.05), base * (1.0 - bob * 0.05))
