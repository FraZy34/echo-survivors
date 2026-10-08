extends Node
## Autoload « Sfx » : effets sonores (pool de lecteurs avec limitation de fréquence par son,
## pour éviter la cacophonie quand des dizaines d'ennemis sont touchés) et musique en boucle.
## Tous les sons sont synthétisés par tools/generate_assets.gd.

const SOUNDS := {
	"shoot": preload("res://assets/audio/shoot.wav"),
	"hit": preload("res://assets/audio/hit.wav"),
	"kill": preload("res://assets/audio/kill.wav"),
	"pickup": preload("res://assets/audio/pickup.wav"),
	"levelup": preload("res://assets/audio/levelup.wav"),
	"hurt": preload("res://assets/audio/hurt.wav"),
	"explosion": preload("res://assets/audio/explosion.wav"),
	"gameover": preload("res://assets/audio/gameover.wav"),
	"victory": preload("res://assets/audio/victory.wav"),
	"echo": preload("res://assets/audio/echo.wav"),
	"click": preload("res://assets/audio/click.wav"),
	"boss": preload("res://assets/audio/boss.wav"),
}
const VOICES := 14
const BASE_DB := {
	"shoot": -16.0, "hit": -15.0, "kill": -15.0, "pickup": -17.0, "echo": -16.0,
	"explosion": -10.0, "hurt": -6.0, "levelup": -8.0, "click": -12.0, "boss": -6.0,
	"gameover": -6.0, "victory": -6.0,
}
const MUSIC_DB := -12.0

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played := {}
var _music: AudioStreamPlayer
var _music_source: AudioStream


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)


## Joue un son ; ignoré s'il a déjà été joué il y a moins de `min_interval` secondes.
func play(sound: String, pitch_jitter := 0.08, min_interval := 0.06, pitch := 1.0) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(sound, -1.0)) < min_interval:
		return
	_last_played[sound] = now
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = SOUNDS[sound]
	p.volume_db = BASE_DB.get(sound, -8.0) + linear_to_db(maxf(GameState.sfx_volume, 0.0001))
	p.pitch_scale = pitch * randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	p.play()


## Lance une musique en boucle (sans effet si elle joue déjà).
func play_music(stream: AudioStream) -> void:
	if stream == null or (stream == _music_source and _music.playing):
		return
	_music_source = stream
	var looped := stream
	if stream is AudioStreamWAV:
		looped = stream.duplicate()
		looped.loop_mode = AudioStreamWAV.LOOP_FORWARD
		looped.loop_begin = 0
		looped.loop_end = int(stream.get_length() * stream.mix_rate)
	_music.stream = looped
	update_music_volume()
	_music.play()


func stop_music() -> void:
	_music.stop()
	_music_source = null


func update_music_volume() -> void:
	_music.volume_db = MUSIC_DB + linear_to_db(maxf(GameState.music_volume, 0.0001))
