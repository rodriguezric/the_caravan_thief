extends Node
## Every sound is synthesized: effects from tones and noise, voices as tiny
## blips, and the music by a small sequencer that writes looping chiptune
## tracks from a few parameters per song (rendered off the main thread where
## threads exist). Audio goes through Music / SFX / Voice buses so the settings
## sliders can drive them.

const RATE := 22050
const MUSIC_DB := -8.0

## Per-speaker typewriter voices: [wave, base pitch, volume db].
const VOICES := {
	"narrator": ["sin", 1.0, -20.0], "rook": ["sq", 1.05, -17.0], "mara": ["tri", 1.0, -13.0],
	"fen": ["sq", 0.72, -17.0], "factor": ["sin", 0.62, -11.0], "wick": ["tri", 1.4, -13.0],
	"bracken": ["saw", 0.55, -18.0], "dosha": ["tri", 1.15, -13.0], "ollo": ["sq", 0.85, -16.0],
	"man": ["sq", 0.8, -16.0], "woman": ["tri", 1.1, -13.0], "kid": ["tri", 1.5, -13.0], "old": ["sq", 0.68, -17.0],
	"hunter": ["saw", 0.75, -19.0], "blade": ["sin", 0.45, -8.0], "beast": ["saw", 0.6, -18.0], "crow": ["sq", 1.6, -18.0],
	"crew": ["sq", 1.0, -18.0],
}

var sounds := {}
var players: Array[AudioStreamPlayer] = []
var voice_player: AudioStreamPlayer
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var current_song := ""
var songs := {}
var _pending := {}
var _music_tween: Tween
var _rng := RandomNumberGenerator.new()
var muted_music := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX", "Voice"]:
		if AudioServer.get_bus_index(bus) == -1:
			# Growing bus_count avoids the web add_bus bug (Godot #119027).
			var i := AudioServer.bus_count
			AudioServer.bus_count = i + 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	for i in 14:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		players.append(p)
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "Voice"
	add_child(voice_player)
	music_a = AudioStreamPlayer.new()
	music_b = AudioStreamPlayer.new()
	for m in [music_a, music_b]:
		m.volume_db = -60.0
		m.bus = "Music"
		add_child(m)
	muted_music = OS.get_environment("CT_MUTE") != ""


func _exit_tree() -> void:
	# never let a music render outlive the game
	for task in _pending.values():
		if task is int:
			WorkerThreadPool.wait_for_task_completion(task)
	_pending.clear()


func set_bus_volume(bus: String, linear: float) -> void:
	## Sliders store 0..1; perceptual mapping so the middle sounds like the middle.
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	AudioServer.set_bus_mute(i, linear <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(pow(clampf(linear, 0.001, 1.0), 1.6)))


func play(name: String, pitch: float = 1.0, vol_db: float = -6.0) -> void:
	if not sounds.has(name):
		sounds[name] = _wav(_make(name), false)
	play_stream(sounds[name], pitch, vol_db)


func play_stream(stream: AudioStream, pitch: float, vol_db: float) -> void:
	var p: AudioStreamPlayer = players[0]
	for cand in players:
		if not cand.playing:
			p = cand
			break
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.play()


func voice(kind: String, variance: int = 0) -> void:
	var v: Array = VOICES.get(kind, VOICES.narrator)
	var key := "v_" + str(v[0])
	if not sounds.has(key):
		sounds[key] = _wav(_tone(520, 520, 0.03, v[0], 0.3), false)
	voice_player.stream = sounds[key]
	voice_player.pitch_scale = v[1] * (1.0 + (variance % 3) * 0.04)
	voice_player.volume_db = v[2]
	voice_player.play()


# ------------------------------------------------------------------ music ---

func music(name: String, fade: float = 1.0, vol: float = MUSIC_DB) -> void:
	if name == current_song:
		return
	current_song = name
	if _music_tween:
		_music_tween.kill()
	var old := music_a if music_a.playing else (music_b if music_b.playing else null)
	if old:
		_music_tween = create_tween()
		_music_tween.tween_property(old, "volume_db", -60.0, fade)
		_music_tween.tween_callback(old.stop)
	if name == "" or muted_music:
		return
	if songs.has(name):
		_start_song(name, fade, vol)
	else:
		_render_song_async(name, fade, vol)


func _start_song(name: String, fade: float, vol: float) -> void:
	if name != current_song:
		return
	var new_p := music_b if music_a.playing else music_a
	new_p.stream = songs[name]
	new_p.volume_db = -40.0
	new_p.play()
	var t := create_tween()
	t.tween_property(new_p, "volume_db", vol, fade * 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _render_song_async(name: String, fade: float, vol: float) -> void:
	if _pending.has(name):
		return
	var def := Songs.get_def(name)
	if def.is_empty():
		return
	_pending[name] = true
	if OS.has_feature("threads") and not OS.has_feature("web"):
		var task := WorkerThreadPool.add_task(func() -> void:
			var data := _render_song(def)
			_song_ready.call_deferred(name, data, fade, vol))
		_pending[name] = task
	else:
		_song_ready(name, _render_song(def), fade, vol)


func _song_ready(name: String, data: PackedFloat32Array, fade: float, vol: float) -> void:
	if not is_inside_tree():
		return
	var task = _pending.get(name, null)
	if task is int:
		WorkerThreadPool.wait_for_task_completion(task)
	_pending.erase(name)
	songs[name] = _wav(data, true)
	_start_song(name, fade, vol)


func prerender(names: Array) -> void:
	## Render songs ahead of time (title boot) so later changes are instant.
	# Without a worker, leave songs available for on-demand rendering in music().
	if not OS.has_feature("threads") or OS.has_feature("web"):
		return
	for n in names:
		if not songs.has(n) and not _pending.has(n):
			var def := Songs.get_def(n)
			if def.is_empty():
				continue
			_pending[n] = true
			if OS.has_feature("threads") and not OS.has_feature("web"):
				var nm: String = n
				var task := WorkerThreadPool.add_task(func() -> void:
					var data := _render_song(def)
					_store_song.call_deferred(nm, data))
				_pending[n] = task


func _store_song(name: String, data: PackedFloat32Array) -> void:
	if not is_inside_tree():
		return
	var task = _pending.get(name, null)
	if task is int:
		WorkerThreadPool.wait_for_task_completion(task)
	_pending.erase(name)
	songs[name] = _wav(data, true)
	# music() asked for it while it was still rendering: start it now
	if name == current_song and not muted_music:
		_start_song(name, 1.0, MUSIC_DB)


func music_volume(db: float, t: float = 0.5) -> void:
	for m in [music_a, music_b]:
		if m.playing:
			create_tween().tween_property(m, "volume_db", db, t)


func stop_music(fade: float = 1.0) -> void:
	music("", fade)


func _render_song(def: Dictionary) -> PackedFloat32Array:
	## A thread-safe pure function: notes in, samples out.
	var notes: Array = Songs.compose(def)
	var spb: float = 60.0 / float(def.bpm)
	var total_beats: float = float(def.get("beats", 4)) * float(def.get("bars", 8))
	var n := int(total_beats * spb * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(def.get("seed", 1))
	for note in notes:
		var start := int(float(note.t) * spb * RATE)
		if note.get("drum", "") != "":
			_add_drum(out, start, note.drum, float(note.v), rng)
			continue
		var dur := int(float(note.d) * spb * RATE)
		var f: float = 440.0 * pow(2.0, (float(note.m) - 69.0) / 12.0)
		var wave: String = note.w
		var vol: float = note.v
		var rel := int(0.06 * RATE)
		var ph := 0.0
		var vib: float = note.get("vib", 0.0)
		# read once per note, not once per sample
		var sus := float(note.get("sus", 0.7))
		var duty := float(note.get("duty", 0.5))
		var decay := 0.18 * RATE
		var step := f / RATE
		for i in dur + rel:
			var idx := start + i
			if idx >= n:
				idx -= n
			var env := minf(1.0, i / 90.0)
			if i > dur:
				env *= 1.0 - float(i - dur) / rel
			else:
				env *= lerpf(1.0, sus, minf(1.0, float(i) / decay))
			if vib > 0.0:
				ph += step * (1.0 + sin(i * 0.0016) * vib)
			else:
				ph += step
			out[idx] += _osc(ph, wave, duty) * vol * env
	return out


func _add_drum(out: PackedFloat32Array, start: int, kind: String, vol: float, rng: RandomNumberGenerator) -> void:
	var n := out.size()
	match kind:
		"kick":
			var len := int(0.16 * RATE)
			var ph := 0.0
			for i in len:
				var t := float(i) / len
				ph += lerpf(130.0, 38.0, sqrt(t)) / RATE
				out[(start + i) % n] += sin(ph * TAU) * vol * (1.0 - t)
		"snare":
			var len := int(0.12 * RATE)
			var lp := 0.0
			for i in len:
				var t := float(i) / len
				lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.7
				out[(start + i) % n] += lp * vol * pow(1.0 - t, 2.0)
		"hat":
			var len := int(0.035 * RATE)
			for i in len:
				var t := float(i) / len
				out[(start + i) % n] += rng.randf_range(-1.0, 1.0) * vol * 0.6 * (1.0 - t)
		"shaker":
			var len := int(0.06 * RATE)
			for i in len:
				var t := float(i) / len
				out[(start + i) % n] += rng.randf_range(-1.0, 1.0) * vol * 0.35 * sin(t * PI)


# ------------------------------------------------------------- synthesis ---

func _make(name: String) -> PackedFloat32Array:
	match name:
		"blip":
			return _tone(880, 880, 0.035, "sq", 0.25)
		"confirm":
			return _cat([_tone(660, 660, 0.04, "sq", 0.25), _tone(990, 990, 0.07, "sq", 0.25)])
		"cancel":
			return _cat([_tone(520, 520, 0.04, "sq", 0.2), _tone(330, 330, 0.07, "sq", 0.2)])
		"miss":
			return _tone(500, 400, 0.1, "tri", 0.2)
		"pop":
			return _tone(500, 1100, 0.07, "sq", 0.15)
		"chime":
			return _mix([_tone(1320, 1320, 0.6, "sin", 0.2), _tone(1980, 1980, 0.5, "sin", 0.1)])
		"tick":
			return _tone(1800, 1800, 0.012, "sq", 0.12)
		"score":
			return _cat([_tone(988, 988, 0.04, "sq", 0.16), _tone(1319, 1319, 0.08, "sq", 0.16)])
		"coin":
			return _cat([_tone(988, 988, 0.05, "sq", 0.18), _tone(1319, 1319, 0.12, "sq", 0.18)])
		"levelup":
			return _cat([_tone(523, 523, 0.06, "sq", 0.2), _tone(659, 659, 0.06, "sq", 0.2), _tone(784, 784, 0.06, "sq", 0.2), _tone(1047, 1047, 0.06, "sq", 0.2), _tone(1319, 1319, 0.25, "sq", 0.2)])
		"fanfare":
			return _cat([_tone(523, 523, 0.1, "sq", 0.2), _tone(523, 523, 0.1, "sq", 0.2), _tone(523, 523, 0.1, "sq", 0.2), _tone(659, 659, 0.3, "sq", 0.2), _tone(587, 587, 0.15, "sq", 0.2), _tone(784, 784, 0.4, "sq", 0.2)])
		"hum":
			return _hum(3.6)
		"whoosh":
			return _noise(0.3, 0.35, 0.2, true, true)
		"step":
			return _mix([_tone(160, 90, 0.04, "sin", 0.4), _noise(0.03, 0.15, 0.5)])
		"squish_step":
			return _mix([_tone(120, 70, 0.05, "sin", 0.3), _noise(0.06, 0.2, 0.15)])
		"door":
			return _noise(0.45, 0.35, 0.7, true, true)
		# --- story ---------------------------------------------------------
		"coins":
			var parts := []
			for i in 6:
				parts.append(_tone(1500 + i * 180, 1600 + i * 150, 0.03, "sq", 0.12))
				parts.append(_noise(0.02, 0.1, 0.95))
			return _cat(parts)
		"lockpin":
			return _mix([_tone(2400, 2200, 0.025, "sq", 0.18), _noise(0.02, 0.2, 0.95)])
		"lock_open":
			return _cat([_mix([_tone(300, 200, 0.06, "sq", 0.3), _noise(0.05, 0.3, 0.6)]), _tone(0, 0, 0.05, "sin", 0.0), _mix([_tone(900, 600, 0.08, "sq", 0.2), _noise(0.08, 0.3, 0.8)])])
		"lock_fail":
			return _mix([_tone(180, 120, 0.15, "saw", 0.3), _noise(0.1, 0.3, 0.4)])
		"chest":
			return _cat([_tone(90, 70, 0.4, "saw", 0.18, true), _mix([_tone(200, 120, 0.1, "sq", 0.2), _noise(0.12, 0.3, 0.4)])])
		"fire":
			var parts := []
			for i in 10:
				parts.append(_noise(0.03 + _rng.randf() * 0.05, 0.15 + _rng.randf() * 0.2, 0.9))
				parts.append(_tone(0, 0, _rng.randf() * 0.08, "sin", 0.0))
			return _cat(parts)
		"wind":
			return _noise(2.2, 0.3, 0.05, true, true)
		"creak":
			return _tone(110, 80, 0.5, "saw", 0.14, true)
		"rope_snap":
			return _mix([_noise(0.18, 0.7, 0.9), _tone(600, 80, 0.2, "sq", 0.3)])
		"splash":
			return _mix([_noise(0.45, 0.5, 0.55, false, false), _tone(300, 120, 0.2, "sin", 0.2)])
		"rumble":
			return _mix([_noise(1.6, 0.6, 0.04, false, true), _tone(50, 35, 1.6, "sin", 0.4, true)])
		"crash":
			return _mix([_noise(0.9, 0.8, 0.2), _tone(120, 30, 0.8, "sin", 0.7)])
		"bell":
			return _mix([_tone(660, 660, 1.4, "sin", 0.3), _tone(1320, 1320, 1.0, "sin", 0.12), _tone(1650, 1650, 0.7, "sin", 0.06)])
		"alert":
			return _cat([_tone(880, 880, 0.06, "sq", 0.25), _tone(1320, 1320, 0.12, "sq", 0.25)])
		"heartbeat":
			return _cat([_tone(60, 40, 0.12, "sin", 0.9), _tone(0, 0, 0.08, "sin", 0.0), _tone(55, 38, 0.14, "sin", 0.7)])
		"whisper":
			return _noise(0.9, 0.25, 0.85, true, true)
		"omen":
			# the blade wakes: a falling glassy tone over a breath
			return _mix([_tone(1760, 440, 1.1, "sin", 0.18, true, true), _tone(220, 110, 1.2, "tri", 0.2, true), _noise(1.0, 0.12, 0.9, false, true)])
		"vision":
			return _mix([_tone(110, 112, 2.0, "sin", 0.35, true), _tone(165, 166, 2.0, "sin", 0.2, true), _tone(1320, 1320, 1.6, "sin", 0.06, true, true)])
		"sword_draw":
			return _mix([_noise(0.4, 0.4, 0.98, true), _tone(3000, 2200, 0.5, "sin", 0.12, false, true), _tone(1500, 1400, 0.6, "sin", 0.08)])
		"crowd":
			var parts := []
			for i in 8:
				parts.append(_tone(200 + _rng.randf() * 200, 180 + _rng.randf() * 200, 0.12 + _rng.randf() * 0.1, "saw", 0.06))
			return _mix([_cat(parts), _noise(1.2, 0.12, 0.3, false, true)])
		"carve":
			return _cat([_noise(0.08, 0.35, 0.95), _tone(0, 0, 0.04, "sin", 0.0), _noise(0.12, 0.3, 0.98, true), _tone(0, 0, 0.03, "sin", 0.0), _noise(0.07, 0.35, 0.95)])
		"howl":
			return _tone(500, 900, 1.1, "tri", 0.2, true, true)
		"caw":
			return _cat([_mix([_tone(700, 500, 0.12, "saw", 0.25), _noise(0.12, 0.2, 0.5)]), _tone(0, 0, 0.06, "sin", 0.0), _mix([_tone(650, 450, 0.14, "saw", 0.22), _noise(0.14, 0.2, 0.5)])])
		"gulp":
			return _cat([_tone(300, 120, 0.12, "sin", 0.5), _tone(250, 100, 0.12, "sin", 0.4)])
		"paper":
			return _noise(0.25, 0.25, 0.97, true, true)
		"thud":
			return _mix([_tone(120, 50, 0.18, "sin", 0.8), _noise(0.1, 0.3, 0.3)])
		"knock":
			return _cat([_mix([_tone(140, 70, 0.08, "sin", 0.8), _noise(0.05, 0.4, 0.3)]), _tone(0, 0, 0.12, "sin", 0.0), _mix([_tone(140, 70, 0.08, "sin", 0.8), _noise(0.05, 0.4, 0.3)])])
		"jingle":
			return _cat([_tone(1319, 1319, 0.05, "tri", 0.15), _tone(1568, 1568, 0.05, "tri", 0.15), _tone(1976, 1976, 0.12, "tri", 0.15)])
		# --- battle ---------------------------------------------------------
		"slash":
			return _mix([_noise(0.14, 0.55, 0.95, true), _tone(1800, 600, 0.1, "saw", 0.12)])
		"slash_heavy":
			return _mix([_noise(0.22, 0.7, 0.9, true), _tone(900, 200, 0.18, "saw", 0.2), _tone(140, 60, 0.2, "sin", 0.5)])
		"stab":
			return _mix([_noise(0.08, 0.5, 0.8), _tone(500, 180, 0.08, "sq", 0.2)])
		"clash":
			return _mix([_tone(2600, 2500, 0.4, "sin", 0.25), _tone(3700, 3600, 0.3, "sin", 0.12), _noise(0.1, 0.5, 0.98)])
		"bonk", "blunt":
			return _mix([_tone(220, 80, 0.12, "sq", 0.35), _noise(0.08, 0.4, 0.4)])
		"hit":
			return _mix([_tone(700, 260, 0.07, "sq", 0.2), _noise(0.05, 0.3, 0.7)])
		"crit":
			return _mix([_noise(0.3, 0.7, 0.9), _tone(1200, 200, 0.3, "sq", 0.25), _tone(80, 40, 0.3, "sin", 0.8)])
		"hurt":
			return _mix([_noise(0.25, 0.6, 0.4), _tone(220, 50, 0.3, "sq", 0.3)])
		"bite":
			return _mix([_noise(0.1, 0.6, 0.6), _tone(400, 150, 0.1, "saw", 0.3)])
		"heal":
			return _cat([_tone(660, 660, 0.06, "tri", 0.2), _tone(880, 880, 0.06, "tri", 0.2), _tone(1320, 1320, 0.2, "tri", 0.18)])
		"buff":
			return _cat([_tone(523, 523, 0.05, "tri", 0.2), _tone(784, 784, 0.05, "tri", 0.2), _tone(1047, 1047, 0.18, "tri", 0.2)])
		"debuff":
			return _cat([_tone(700, 650, 0.08, "saw", 0.15), _tone(500, 450, 0.08, "saw", 0.15), _tone(300, 250, 0.2, "saw", 0.15)])
		"magic":
			return _mix([_tone(300, 1500, 0.35, "tri", 0.18), _noise(0.35, 0.15, 0.8, false, true)])
		"seal":
			# the Factor's ledger magic: a stamp and a ring
			return _cat([_mix([_tone(90, 50, 0.12, "sin", 0.9), _noise(0.08, 0.5, 0.3)]), _mix([_tone(1200, 1200, 0.6, "sin", 0.15), _tone(1800, 1800, 0.4, "sin", 0.06)])])
		"enemy_die":
			return _mix([_noise(0.3, 0.55, 0.3), _tone(320, 50, 0.3, "sin", 0.6)])
		"whiff", "dash":
			return _noise(0.18, 0.3, 0.5, true, true)
		"arrow":
			return _mix([_noise(0.25, 0.25, 0.95, true, true), _tone(1400, 800, 0.2, "sin", 0.06)])
		"bowstring":
			return _mix([_tone(180, 160, 0.18, "tri", 0.4), _noise(0.05, 0.2, 0.5)])
		"smoke":
			return _mix([_noise(0.7, 0.45, 0.25, false, true), _tone(300, 100, 0.3, "sin", 0.15)])
		"steal":
			return _cat([_noise(0.06, 0.3, 0.95, true), _tone(1568, 1568, 0.04, "sq", 0.15), _tone(2093, 2093, 0.1, "sq", 0.15)])
		"turn":
			return _tone(1320, 1320, 0.05, "sq", 0.12)
		"assist":
			return _cat([_tone(784, 784, 0.05, "sq", 0.2), _tone(1175, 1175, 0.05, "sq", 0.2), _tone(1568, 1568, 0.12, "sq", 0.2)])
		"timestop":
			return _mix([_tone(2000, 100, 0.6, "sin", 0.3), _tone(100, 100, 0.8, "sq", 0.08, true), _noise(0.6, 0.2, 0.2, true)])
		"timego":
			return _mix([_tone(100, 2000, 0.4, "sin", 0.25), _noise(0.4, 0.4, 0.9, true, true)])
		"guard":
			return _mix([_tone(1800, 1700, 0.15, "sin", 0.18), _tone(240, 200, 0.12, "sq", 0.2)])
		"miss_swing":
			return _noise(0.2, 0.25, 0.4, true, true)
		"breakdown":
			return _cat([_tone(400, 200, 0.12, "sq", 0.2), _tone(300, 150, 0.12, "sq", 0.2), _tone(200, 60, 0.4, "sq", 0.2)])
		"drumroll":
			var parts := []
			for i in 16:
				parts.append(_noise(0.04, 0.2 + i * 0.01, 0.5))
			return _cat(parts)
		"howl_short":
			return _tone(600, 900, 0.5, "tri", 0.18, true, true)
	return _tone(440, 440, 0.05, "sq", 0.2)


func _osc(phase: float, wave: String, duty: float = 0.5) -> float:
	var f := fmod(phase, 1.0)
	match wave:
		"sq":
			return 1.0 if f < duty else -1.0
		"tri":
			return 4.0 * absf(f - 0.5) - 1.0
		"saw":
			return 2.0 * f - 1.0
	return sin(phase * TAU)


func _tone(f0: float, f1: float, dur: float, wave: String, vol: float, swell: bool = false, vibrato: bool = false) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / n
		var f := lerpf(f0, f1, t)
		if vibrato:
			f *= 1.0 + sin(i * 0.004) * 0.03
		ph += f / RATE
		var env := sin(t * PI) if swell else minf(1.0, i / 60.0) * pow(1.0 - t, 1.4)
		out[i] = _osc(ph, wave) * vol * env
	return out


func _noise(dur: float, vol: float, bright: float, sweep: bool = false, swell: bool = false) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / n
		var k := bright * (0.2 + t * 1.6 if sweep else 1.0)
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * clampf(k, 0.01, 1.0)
		var env := sin(t * PI) if swell else pow(1.0 - t, 2.0)
		out[i] = lp * vol * env
	return out


func _hum(dur: float) -> PackedFloat32Array:
	## A low drone: a root, its fifth and a soft octave, swelling and fading.
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := [0.0, 0.0, 0.0, 0.0]
	var freqs := [55.0, 55.6, 82.4, 110.0]
	var vols := [0.32, 0.22, 0.16, 0.07]
	for i in n:
		var t := float(i) / n
		var env := pow(sin(t * PI), 0.7) * minf(1.0, (1.0 - t) * 4.0)
		var v := 0.0
		for k in 4:
			ph[k] += freqs[k] / RATE
			v += sin(ph[k] * TAU) * vols[k]
		out[i] = v * env
	return out


func _cat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out


func _mix(parts: Array) -> PackedFloat32Array:
	var n := 0
	for p in parts:
		n = maxi(n, p.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for p in parts:
		for i in p.size():
			out[i] += p[i]
	return out


func _wav(s: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(s.size() * 2)
	for i in s.size():
		bytes.encode_s16(i * 2, int(clampf(tanh(s[i] * 1.2), -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = s.size()
	return w
