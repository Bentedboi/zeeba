extends Node
## Procedural chiptune sound effects and music (autoload "Sfx").
## Everything is synthesized at startup, so the game ships with no audio files.

const RATE := 22050
const MRATE := 16000

const SONGS := {
	"title": {"bpm": 90, "drums": false,
		"lead": "A4 . C5 . E5 . . . D5 . C5 . B4 . . . | A4 . C5 . E5 . A5 . G5 . . . E5 . . . | F5 . E5 . D5 . C5 . B4 . C5 . D5 . . . | C5 . B4 . A4 . . . - . . . - . . .",
		"bass": "A2 . . . E3 . . . A2 . . . E3 . . . | F2 . . . C3 . . . G2 . . . D3 . . . | D2 . . . A2 . . . E2 . . . B2 . . . | A2 . . . E3 . . . A2 . . . . . . ."},
	"rust": {"bpm": 120, "drums": true,
		"lead": "C5 . E5 . G5 . E5 . D5 . C5 . D5 . E5 . | A4 . C5 . E5 . C5 . D5 . . . G4 . . . | F4 . A4 . C5 . A4 . G4 . B4 . D5 . G5 . | E5 . D5 . C5 . . . - . G4 . C5 . . .",
		"bass": "C3 . C3 . G2 . G2 . C3 . C3 . G2 . G2 . | A2 . A2 . E3 . E3 . G2 . G2 . D3 . D3 . | F2 . F2 . C3 . C3 . G2 . G2 . D3 . D3 . | C3 . G2 . C3 . . . G2 . . . C3 . . ."},
	"cave": {"bpm": 100, "drums": false,
		"lead": "D5 . . . A4 . . . F5 . E5 . D5 . . . | C5 . . . A4 . . . E5 . D5 . C5 . . . | Bb4 . . . D5 . . . F5 . G5 . A5 . . . | G5 . F5 . E5 . C#5 . D5 . . . - . . .",
		"bass": "D3 . . . . . . . D3 . . . A2 . . . | C3 . . . . . . . C3 . . . G2 . . . | Bb2 . . . . . . . Bb2 . . . F2 . . . | A2 . . . . . . . D3 . . . A2 . . ."},
	"dusk": {"bpm": 132, "drums": true,
		"lead": "F4 . A4 . C5 . F5 . E5 . C5 . A4 . C5 . | Bb4 . D5 . F5 . Bb5 . A5 . F5 . D5 . F5 . | G5 . . . A5 . G5 . F5 . E5 . D5 . C5 . | F5 . . . C5 . . . F5 . . . - . . .",
		"bass": "F2 . F3 . F2 . F3 . F2 . F3 . F2 . F3 . | Bb2 . Bb3 . Bb2 . Bb3 . Bb2 . Bb3 . Bb2 . Bb3 . | C3 . C4 . C3 . C4 . C3 . C4 . C3 . C4 . | F2 . F3 . C3 . C4 . F2 . . . C3 . . ."},
	"shop": {"bpm": 140, "drums": true,
		"lead": "G4 . B4 . D5 . B4 . C5 . A4 . F#4 . A4 . | G4 . B4 . D5 . G5 . F#5 . D5 . . . . . | E5 . C5 . A4 . C5 . D5 . B4 . G4 . B4 . | A4 . F#4 . D4 . F#4 . G4 . . . - . . .",
		"bass": "G2 . D3 . G2 . D3 . D2 . A2 . D2 . A2 . | G2 . D3 . G2 . D3 . D2 . A2 . D3 . . . | C3 . G2 . C3 . G2 . G2 . D3 . G2 . D3 . | D3 . A2 . D2 . A2 . G2 . . . G2 . . ."},
	"ending": {"bpm": 84, "drums": false,
		"lead": "C5 . E5 . G5 . . . F5 . E5 . D5 . . . | C5 . E5 . G5 . C6 . B5 . . . G5 . . . | A5 . G5 . F5 . E5 . D5 . E5 . F5 . . . | E5 . D5 . C5 . . . - . . . - . . .",
		"bass": "C3 . . . G3 . . . C3 . . . G3 . . . | A2 . . . E3 . . . E2 . . . B2 . . . | F2 . . . C3 . . . G2 . . . D3 . . . | C3 . . . G2 . . . C3 . . . . . . ."},
}

var _cache := {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _songs := {}
var _want_song := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -10.0
	add_child(_music)
	# Render every song in the background so level loads never hitch.
	for name in SONGS:
		var n: String = name
		WorkerThreadPool.add_task(func(): _song_ready.call_deferred(n, _render_song(SONGS[n])))


func play(name: String, pitch := 1.0, vol_db := -8.0) -> void:
	if not _cache.has(name):
		_cache[name] = _make(name)
	var s: AudioStream = _cache[name]
	if s == null:
		return
	var player := _players[0]
	for p in _players:
		if not p.playing:
			player = p
			break
	player.stream = s
	player.pitch_scale = pitch
	player.volume_db = vol_db
	player.play()


func music(name: String) -> void:
	if _want_song == name and _music.playing:
		return
	_want_song = name
	if name == "":
		_music.stop()
	elif _songs.has(name):
		_music.stream = _songs[name]
		_music.play()


func _song_ready(name: String, stream: AudioStreamWAV) -> void:
	_songs[name] = stream
	if _want_song == name and not _music.playing:
		_music.stream = stream
		_music.play()


# --- sound effects -------------------------------------------------------

func _make(name: String) -> AudioStreamWAV:
	match name:
		"blip": return _synth([[520, 520, 0.035]], "square", 0.22)
		"select": return _synth([[880, 880, 0.03]], "square", 0.2)
		"confirm": return _synth([[660, 660, 0.04], [990, 990, 0.06]], "square", 0.22)
		"cancel": return _synth([[440, 330, 0.08]], "square", 0.2)
		"jump": return _synth([[260, 620, 0.12]], "square", 0.18)
		"coin": return _synth([[988, 988, 0.06], [1319, 1319, 0.22]], "square", 0.22)
		"pickup": return _synth([[523, 523, 0.05], [659, 659, 0.05], [784, 784, 0.05], [1047, 1047, 0.1]], "square", 0.2)
		"crunch": return _synth([[180, 90, 0.09]], "noise", 0.35)
		"smash": return _synth([[200, 40, 0.35]], "noise", 0.5)
		"punch": return _synth([[300, 120, 0.07]], "noise", 0.3)
		"hurt": return _synth([[420, 110, 0.25]], "square", 0.25)
		"stomp": return _synth([[240, 70, 0.12]], "square", 0.25)
		"checkpoint": return _synth([[523, 523, 0.07], [659, 659, 0.07], [784, 784, 0.07], [1047, 1047, 0.2]], "tri", 0.4)
		"drink": return _synth([[300, 500, 0.06], [280, 520, 0.06], [320, 560, 0.08]], "sine", 0.35)
		"rover": return _synth([[90, 160, 0.3]], "square", 0.15)
		"launch": return _synth([[60, 30, 2.5]], "noise", 0.45)
		"faint": return _synth([[600, 500, 0.15], [500, 400, 0.15], [400, 200, 0.4]], "tri", 0.4)
	return null


## segs: [[freq_start, freq_end, seconds], ...]
func _synth(segs: Array, wave: String, vol: float) -> AudioStreamWAV:
	var total := 0
	for seg in segs:
		total += int(seg[2] * RATE)
	var data := PackedByteArray()
	data.resize(total * 2)
	var phase := 0.0
	var idx := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(wave + str(segs))
	var noise_v := 0.0
	for seg in segs:
		var n := int(seg[2] * RATE)
		for i in n:
			var t := float(i) / n
			var f := lerpf(seg[0], seg[1], t)
			var prev := phase
			phase = fmod(phase + f / RATE, 1.0)
			var v := 0.0
			match wave:
				"square": v = 1.0 if phase < 0.5 else -1.0
				"tri": v = absf(phase * 4.0 - 2.0) - 1.0
				"sine": v = sin(phase * TAU)
				"noise":
					if phase < prev:
						noise_v = rng.randf() * 2.0 - 1.0
					v = noise_v
			var g := float(idx) / total
			var env := minf(1.0, float(i) / 60.0) * (1.0 - g * 0.85)
			data.encode_s16(idx * 2, int(clampf(v * env * vol, -1.0, 1.0) * 32767.0))
			idx += 1
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s


# --- music ---------------------------------------------------------------

const NOTE := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


## Returns [[midi (-1 = rest), start_step, length_steps], ...]
func _parse(src: String) -> Array:
	var out := []
	var step := 0
	for tok in src.split(" ", false):
		if tok == "|":
			continue
		if tok == ".":
			if not out.is_empty():
				out[-1][2] += 1
		elif tok == "-":
			out.append([-1, step, 1])
		else:
			var m: int = NOTE[tok[0]]
			var rest := tok.substr(1)
			if rest.begins_with("#"):
				m += 1
				rest = rest.substr(1)
			elif rest.begins_with("b"):
				m -= 1
				rest = rest.substr(1)
			out.append([m + (int(rest) + 1) * 12, step, 1])
		step += 1
	return out


func _render_song(song: Dictionary) -> AudioStreamWAV:
	var step_s := 60.0 / float(song.bpm) / 4.0
	var lead := _parse(song.lead)
	var bass := _parse(song.bass)
	var steps := 0
	for n in lead + bass:
		steps = maxi(steps, n[1] + n[2])
	var total := int(steps * step_s * MRATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	_voice(buf, lead, step_s, 0.25, 0.11)
	_voice(buf, bass, step_s, -1.0, 0.2)
	if song.drums:
		var rng := RandomNumberGenerator.new()
		for s in steps:
			if s % 2 == 1:
				continue
			var start := int(s * step_s * MRATE)
			var loud := 0.07 if s % 4 == 0 else 0.035
			for i in int(0.03 * MRATE):
				if start + i < total:
					buf[start + i] += (rng.randf() * 2.0 - 1.0) * loud * (1.0 - i / (0.03 * MRATE))
	var data := PackedByteArray()
	data.resize(total * 2)
	for i in total:
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MRATE
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = total
	return w


## duty < 0 renders a triangle wave (bass), otherwise a pulse wave.
func _voice(buf: PackedFloat32Array, notes: Array, step_s: float, duty: float, vol: float) -> void:
	for n in notes:
		if n[0] < 0:
			continue
		var f := 440.0 * pow(2.0, (n[0] - 69) / 12.0)
		var start := int(n[1] * step_s * MRATE)
		var length := int(n[2] * step_s * MRATE)
		var phase := 0.0
		for i in length:
			var idx := start + i
			if idx >= buf.size():
				break
			phase = fmod(phase + f / MRATE, 1.0)
			var v: float
			if duty < 0.0:
				v = absf(phase * 4.0 - 2.0) - 1.0
			else:
				v = 1.0 if phase < duty else -1.0
			var t := float(i) / length
			var env := minf(1.0, i / 80.0) * (1.0 - 0.4 * t) * minf(1.0, (1.0 - t) * 8.0)
			buf[idx] += v * env * vol
