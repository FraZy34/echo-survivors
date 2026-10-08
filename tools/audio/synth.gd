extends RefCounted
## Petit synthétiseur hors ligne : oscillateurs, bruit et enveloppes, rendus dans un tampon
## puis enregistrés en WAV 16 bits. Sert aux effets sonores et aux musiques.

const RATE := 22050

var buffer := PackedFloat32Array()
var _noise_seed := 12345


func _init(seconds: float) -> void:
	buffer.resize(int(seconds * RATE) + 1)
	buffer.fill(0.0)


static func midi_to_hz(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)


## Oscillateur : wave ∈ sine, square, pulse (25 %), triangle, saw.
static func osc(wave: String, phase: float) -> float:
	var p := phase - floorf(phase)
	match wave:
		"sine":
			return sin(p * TAU)
		"square":
			return 1.0 if p < 0.5 else -1.0
		"pulse":
			return 1.0 if p < 0.25 else -1.0
		"triangle":
			return 4.0 * absf(p - 0.5) - 1.0
		_:
			return 2.0 * p - 1.0


## Note avec glissement de fréquence (f0 → f1), attaque courte et décroissance.
## sustain : fraction de la durée maintenue avant la chute (0 = percussive).
func tone(start: float, duration: float, f0: float, f1: float, wave: String, volume: float,
		sustain := 0.0, vibrato := 0.0) -> void:
	var i0 := int(start * RATE)
	var n := int(duration * RATE)
	var phase := 0.0
	var attack := mini(n, int(0.004 * RATE) + 1)
	for i in n:
		var idx := i0 + i
		if idx >= buffer.size():
			break
		var t := float(i) / n
		var freq := f0 * pow(f1 / f0, t)
		if vibrato > 0.0:
			freq *= 1.0 + vibrato * sin(float(i) / RATE * TAU * 6.0)
		phase += freq / RATE
		var env := minf(1.0, float(i) / attack)
		if t > sustain:
			var k := (t - sustain) / maxf(0.0001, 1.0 - sustain)
			env *= (1.0 - k) * (1.0 - k)
		buffer[idx] += osc(wave, phase) * volume * env


## Bruit blanc filtré passe-bas (cutoff 0..1, plus petit = plus sourd), décroissance exponentielle.
func noise(start: float, duration: float, volume: float, cutoff := 1.0, decay := 6.0) -> void:
	var i0 := int(start * RATE)
	var n := int(duration * RATE)
	var low := 0.0
	for i in n:
		var idx := i0 + i
		if idx >= buffer.size():
			break
		_noise_seed = (_noise_seed * 1103515245 + 12345) & 0x7fffffff
		var white := float(_noise_seed) / 0x3fffffff - 1.0
		low += (white - low) * cutoff
		var env := exp(-decay * float(i) / n) * minf(1.0, float(i) / 30.0)
		buffer[idx] += low * volume * env


## Renvoie une copie retardée et atténuée du son (effet d'écho).
func echo(delay: float, feedback: float, repeats: int) -> void:
	var d := int(delay * RATE)
	for r in repeats:
		for i in range(buffer.size() - 1, d - 1, -1):
			buffer[i] += buffer[i - d] * feedback


func normalize(peak := 0.85) -> void:
	var m := 0.0001
	for v in buffer:
		m = maxf(m, absf(v))
	var k := peak / m
	for i in buffer.size():
		buffer[i] *= k


func save_wav(path: String) -> void:
	var bytes := PackedByteArray()
	bytes.resize(buffer.size() * 2)
	for i in buffer.size():
		bytes.encode_s16(i * 2, int(clampf(buffer[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	stream.save_to_wav(path)
