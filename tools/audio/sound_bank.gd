extends RefCounted
## Recettes des effets sonores et des musiques du jeu.

const Synth := preload("res://tools/audio/synth.gd")


static func effects() -> Dictionary:
	var out := {}
	var s: Synth

	s = Synth.new(0.1)
	s.tone(0.0, 0.08, 900.0, 420.0, "square", 0.35)
	s.noise(0.0, 0.03, 0.15, 0.6, 8.0)
	out["shoot"] = s

	s = Synth.new(0.09)
	s.noise(0.0, 0.07, 0.6, 0.5, 5.0)
	s.tone(0.0, 0.06, 240.0, 110.0, "square", 0.3)
	out["hit"] = s

	s = Synth.new(0.16)
	s.tone(0.0, 0.06, 520.0, 1250.0, "square", 0.3)
	s.tone(0.04, 0.11, 330.0, 140.0, "triangle", 0.5)
	out["kill"] = s

	s = Synth.new(0.14)
	s.tone(0.0, 0.06, 1300.0, 1800.0, "sine", 0.5)
	s.tone(0.05, 0.08, 1800.0, 2500.0, "sine", 0.4)
	out["pickup"] = s

	s = Synth.new(0.75)
	var notes := [72, 76, 79, 84]
	for i in notes.size():
		s.tone(i * 0.07, 0.12, Synth.midi_to_hz(notes[i]), Synth.midi_to_hz(notes[i]), "square", 0.25)
	for n in [72, 76, 79]:
		s.tone(0.3, 0.42, Synth.midi_to_hz(n), Synth.midi_to_hz(n), "triangle", 0.3, 0.3)
	out["levelup"] = s

	s = Synth.new(0.3)
	s.tone(0.0, 0.26, 320.0, 70.0, "saw", 0.5)
	s.noise(0.0, 0.12, 0.3, 0.3, 4.0)
	out["hurt"] = s

	s = Synth.new(0.6)
	s.noise(0.0, 0.55, 0.9, 0.12, 5.0)
	s.tone(0.0, 0.45, 110.0, 35.0, "sine", 0.8)
	out["explosion"] = s

	s = Synth.new(1.3)
	var down := [67, 64, 60, 55]
	for i in down.size():
		s.tone(i * 0.22, 0.3 if i < 3 else 0.6, Synth.midi_to_hz(down[i]), Synth.midi_to_hz(down[i]) * (1.0 if i < 3 else 0.94), "triangle", 0.6, 0.4, 0.01)
	out["gameover"] = s

	s = Synth.new(1.4)
	var fanfare := [60, 64, 67, 72, 76]
	for i in fanfare.size():
		s.tone(i * 0.11, 0.16, Synth.midi_to_hz(fanfare[i]), Synth.midi_to_hz(fanfare[i]), "square", 0.22)
	for n in [72, 76, 79, 84]:
		s.tone(0.58, 0.75, Synth.midi_to_hz(n), Synth.midi_to_hz(n), "pulse", 0.14, 0.5, 0.006)
	out["victory"] = s

	# L'Écho : une note cristalline répétée en s'estompant.
	s = Synth.new(0.55)
	s.tone(0.0, 0.12, 990.0, 880.0, "sine", 0.5, 0.2, 0.01)
	s.tone(0.0, 0.12, 1980.0, 1760.0, "sine", 0.15)
	s.echo(0.085, 0.45, 3)
	out["echo"] = s

	s = Synth.new(0.05)
	s.tone(0.0, 0.035, 1100.0, 900.0, "square", 0.3)
	out["click"] = s

	s = Synth.new(1.2)
	s.tone(0.0, 1.1, 82.0, 70.0, "saw", 0.4, 0.5)
	s.tone(0.0, 1.1, 87.0, 74.0, "saw", 0.4, 0.5)
	s.noise(0.0, 1.0, 0.35, 0.05, 3.0)
	out["boss"] = s

	for key in out:
		(out[key] as Synth).normalize(0.8)
	return out


# --- Musiques -------------------------------------------------------------------------------

## Accords : [fondamentale MIDI, mineur ?]. Une mesure par accord, progression jouée deux fois
## (la seconde avec une mélodie différente).
const TRACKS := {
	"menu": {"bpm": 92, "chords": [[60, false], [57, true], [53, false], [55, false]],
		"lead": "triangle", "arp": "sine", "drums": 0, "seed": 3},
	"forest": {"bpm": 128, "chords": [[60, false], [55, false], [57, true], [53, false]],
		"lead": "pulse", "arp": "square", "drums": 2, "seed": 11},
	"snow": {"bpm": 112, "chords": [[57, true], [53, false], [60, false], [55, false]],
		"lead": "sine", "arp": "triangle", "drums": 1, "seed": 27},
	"crypt": {"bpm": 104, "chords": [[50, true], [46, false], [55, true], [57, false]],
		"lead": "saw", "arp": "square", "drums": 2, "seed": 41},
}


static func music(spec: Dictionary) -> Synth:
	var beat := 60.0 / float(spec.bpm)
	var bars := 8
	var length := bars * 4 * beat
	var s := Synth.new(length + 0.05)
	var rng := RandomNumberGenerator.new()
	rng.seed = spec.seed
	var chords: Array = spec.chords
	var rhythms := [[1.0, 0.5, 0.5, 1.0, 1.0], [0.5, 0.5, 1.0, 0.5, 0.5, 1.0], [1.5, 0.5, 2.0], [1.0, 1.0, 0.5, 0.5, 1.0]]

	for bar in bars:
		var chord: Array = chords[bar % chords.size()]
		var root: int = chord[0]
		var tones := [0, 3 if chord[1] else 4, 7]
		var t0 := bar * 4 * beat

		# Basse : fondamentale et octave.
		for b in 4:
			var note := root - 12 + (12 if b % 2 == 1 else 0)
			s.tone(t0 + b * beat, beat * 0.9, Synth.midi_to_hz(note), Synth.midi_to_hz(note), "triangle", 0.42, 0.6)

		# Arpège en doubles croches, discret.
		for a in 16:
			var note: int = root + 12 + tones[a % 3] + (12 if a % 8 >= 6 else 0)
			s.tone(t0 + a * beat * 0.25, beat * 0.22, Synth.midi_to_hz(note), Synth.midi_to_hz(note), spec.arp, 0.07)

		# Mélodie : notes de l'accord et de passage, rythme tiré d'un motif.
		var rhythm: Array = rhythms[(bar + (2 if bar >= 4 else 0)) % rhythms.size()]
		var t := t0
		var degree := rng.randi_range(0, 2)
		for dur: float in rhythm:
			degree = clampi(degree + rng.randi_range(-1, 1), 0, 4)
			var steps := [0, tones[1], 7, 12, 12 + tones[1]]
			var note: int = root + 12 + steps[degree]
			if rng.randf() < 0.2:
				note += 2  # Note de passage.
			s.tone(t, beat * dur * 0.95, Synth.midi_to_hz(note), Synth.midi_to_hz(note), spec.lead, 0.16, 0.55, 0.004)
			t += beat * dur

		# Percussions.
		var drums: int = spec.drums
		for b in 4:
			var tb := t0 + b * beat
			if drums >= 1:
				s.noise(tb + beat * 0.5, 0.04, 0.12, 0.9, 9.0)
			if drums >= 2:
				if b % 2 == 0:
					s.tone(tb, 0.16, 150.0, 45.0, "sine", 0.7)
				else:
					s.noise(tb, 0.14, 0.35, 0.45, 6.0)
				s.noise(tb, 0.03, 0.08, 0.9, 9.0)
	s.normalize(0.7)
	return s
