class_name Songs
## The Caravan Thief's soundtrack, as data. Each song is a handful of parameters; compose()
## turns it into notes (deterministically, so a song is the same every time).
## Pure and static so it can run on a worker thread.

const SCALES := {
	"major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10], "dorian": [0, 2, 3, 5, 7, 9, 10],
	"mixolydian": [0, 2, 4, 5, 7, 9, 10], "harmonic": [0, 2, 3, 5, 7, 8, 11], "lydian": [0, 2, 4, 6, 7, 9, 11],
}

const DEFS := {
	"title": {"beats": 3, "bpm": 84, "root": 57, "scale": "harmonic", "prog": [0, 5, 3, 4, 0, 5, 1, 4], "lead": "tri", "bass": "waltz", "drums": "shaker", "density": 0.5, "arp": true, "seed": 7},
	"camp": {"beats": 4, "bpm": 78, "root": 62, "scale": "dorian", "prog": [0, 3, 0, 4, 0, 3, 6, 0], "lead": "tri", "bass": "pulse", "drums": "shaker", "density": 0.45, "arp": true, "seed": 13},
	"road": {"beats": 4, "bpm": 96, "root": 55, "scale": "mixolydian", "prog": [0, 6, 3, 0, 0, 6, 4, 0], "lead": "sq", "duty": 0.25, "bass": "walk", "drums": "swing", "density": 0.55, "seed": 23},
	"heist": {"beats": 4, "bpm": 104, "root": 50, "scale": "minor", "prog": [0, 0, 5, 4, 0, 0, 3, 4], "lead": "sq", "duty": 0.125, "sus": 0.2, "bass": "root8", "drums": "", "density": 0.35, "seed": 29},
	"battle": {"beats": 4, "bpm": 152, "root": 57, "scale": "minor", "prog": [0, 0, 5, 6, 0, 0, 3, 4], "lead": "sq", "bass": "root8", "drums": "basic", "density": 0.72, "seed": 37},
	"boss": {"beats": 4, "bpm": 140, "root": 52, "scale": "harmonic", "prog": [0, 5, 3, 4, 0, 5, 1, 4], "lead": "saw", "bass": "root8", "drums": "march", "density": 0.75, "seed": 43},
	"omen": {"beats": 4, "bpm": 56, "root": 49, "scale": "lydian", "prog": [0, 1, 0, 4, 0, 1, 3, 0], "lead": "sin", "vib": 0.014, "bass": "drone", "drums": "", "density": 0.22, "pad": true, "seed": 53},
	"town": {"beats": 4, "bpm": 112, "root": 60, "scale": "mixolydian", "prog": [0, 3, 4, 0, 5, 3, 4, 0], "lead": "sq", "duty": 0.3, "bass": "alberti", "drums": "shaker", "density": 0.62, "seed": 61},
	"tension": {"beats": 4, "bpm": 72, "root": 53, "scale": "harmonic", "prog": [0, 1, 0, 1, 5, 4, 1, 0], "lead": "tri", "bass": "drone", "drums": "", "density": 0.3, "pad": true, "seed": 67},
	"sad": {"beats": 3, "bpm": 66, "root": 57, "scale": "minor", "prog": [0, 5, 3, 4, 0, 3, 4, 0], "lead": "tri", "bass": "waltz", "drums": "", "density": 0.35, "pad": true, "seed": 71},
	"hope": {"beats": 4, "bpm": 76, "root": 60, "scale": "major", "prog": [0, 5, 3, 4, 0, 5, 3, 0], "lead": "tri", "bass": "pulse", "drums": "", "density": 0.42, "arp": true, "seed": 79},
	"victory": {"beats": 4, "bpm": 124, "root": 60, "scale": "major", "prog": [0, 3, 4, 0, 3, 4, 0, 4], "lead": "sq", "bass": "pulse", "drums": "basic", "density": 0.6, "seed": 131},
	"defeat": {"beats": 4, "bpm": 60, "root": 52, "scale": "minor", "prog": [0, 5, 3, 4, 0, 5, 4, 0], "lead": "tri", "bass": "drone", "drums": "", "density": 0.3, "seed": 89},
	"ending": {"beats": 4, "bpm": 72, "root": 62, "scale": "dorian", "prog": [0, 3, 5, 4, 0, 3, 4, 0], "lead": "tri", "bass": "pulse", "drums": "", "density": 0.42, "arp": true, "pad": true, "seed": 141},
	"legend": {"beats": 4, "bpm": 92, "root": 55, "scale": "harmonic", "prog": [0, 3, 4, 0, 5, 1, 4, 0], "lead": "saw", "sus": 0.4, "bass": "pulse", "drums": "march", "density": 0.55, "seed": 151},
	"minigame": {"beats": 4, "bpm": 126, "root": 52, "scale": "dorian", "prog": [0, 3, 0, 4, 0, 3, 6, 4], "lead": "sq", "duty": 0.25, "bass": "root8", "drums": "", "density": 0.5, "seed": 121},
}


static func get_def(name: String) -> Dictionary:
	return DEFS.get(name, {})


static func _h(a: int, b: int, s: int) -> float:
	return Pal.hash2(a, b, s)


static func compose(d: Dictionary) -> Array:
	var notes := []
	var beats: int = d.get("beats", 4)
	var bars: int = d.get("bars", 8)
	var root: int = d.root
	var scale: Array = SCALES[d.scale]
	var prog: Array = d.prog
	var seed: int = d.get("seed", 1)
	var deg_note := func(deg: int, octave_shift: int) -> int:
		var o := int(floor(deg / 7.0))
		return root + scale[posmod(deg, 7)] + 12 * (o + octave_shift)
	# --- bass and harmony ---------------------------------------------------
	for bar in bars:
		var t0 := float(bar * beats)
		var deg: int = prog[bar % prog.size()]
		var r: int = deg_note.call(deg, -1)
		var third: int = deg_note.call(deg + 2, -1)
		var fifth: int = deg_note.call(deg + 4, -1)
		var bw := "tri"
		var bv := 0.2
		match d.get("bass", "pulse"):
			"pulse":
				for k in beats:
					notes.append({"t": t0 + k, "d": 0.8, "m": r if k % 2 == 0 else fifth, "w": bw, "v": bv, "sus": 0.6})
			"root8":
				for k in beats * 2:
					notes.append({"t": t0 + k * 0.5, "d": 0.4, "m": r - 12 if k % 2 == 0 else r, "w": "sq", "v": bv * 0.6, "sus": 0.5, "duty": 0.25})
			"walk":
				var seq := [r, third, fifth, deg_note.call(deg + 5, -1)]
				for k in beats:
					notes.append({"t": t0 + k, "d": 0.85, "m": seq[k % 4] - 12, "w": bw, "v": bv * 1.1, "sus": 0.5})
			"alberti":
				var seq := [r, fifth, third, fifth]
				for k in beats * 2:
					notes.append({"t": t0 + k * 0.5, "d": 0.45, "m": seq[k % 4], "w": "tri", "v": bv * 0.8, "sus": 0.3})
			"waltz":
				notes.append({"t": t0, "d": 0.9, "m": r - 12, "w": bw, "v": bv * 1.1, "sus": 0.6})
				for k in range(1, beats):
					notes.append({"t": t0 + k, "d": 0.6, "m": third if k % 2 == 1 else fifth, "w": "tri", "v": bv * 0.55, "sus": 0.4})
			"drone":
				notes.append({"t": t0, "d": beats - 0.1, "m": r - 12, "w": "sin", "v": bv * 1.2, "sus": 0.9})
				notes.append({"t": t0, "d": beats - 0.1, "m": fifth - 12, "w": "sin", "v": bv * 0.6, "sus": 0.9})
			"disco":
				for k in beats * 2:
					notes.append({"t": t0 + k * 0.5, "d": 0.35, "m": r - 12 if k % 2 == 0 else r, "w": "sq", "v": bv * 0.7, "sus": 0.4, "duty": 0.3})
		if d.get("pad", false):
			for m in [deg_note.call(deg, 0), deg_note.call(deg + 2, 0), deg_note.call(deg + 4, 0)]:
				notes.append({"t": t0, "d": beats - 0.05, "m": m, "w": "sin", "v": 0.05, "sus": 0.9})
		if d.get("arp", false):
			var tones := [deg_note.call(deg, 1), deg_note.call(deg + 2, 1), deg_note.call(deg + 4, 1), deg_note.call(deg + 7, 1)]
			for k in beats * 2:
				notes.append({"t": t0 + k * 0.5, "d": 0.4, "m": tones[(k if k < 4 else 7 - k) % 4], "w": "sin", "v": 0.06, "sus": 0.3})
	# --- melody: a phrase, its repeat, and a new ending -------------------
	var density: float = d.get("density", 0.5)
	var lead_w: String = d.get("lead", "sq")
	var lv := 0.13 if lead_w in ["sq", "saw"] else 0.2
	var idx := 7
	var phrase := func(bar_from: int, bar_count: int, out_bar: int, s: int, cadence: bool) -> void:
		var cur := idx
		for bi in bar_count:
			var bar := out_bar + bi
			var deg: int = prog[bar % prog.size()]
			var steps := beats * 2
			var k := 0
			while k < steps:
				var strong := k % 2 == 0
				var play := _h(bar_from + bi, k, s) < density + (0.25 if k == 0 else 0.0)
				if not play:
					k += 1
					continue
				if strong:
					# land on a chord tone near where the melody already is
					var best := cur
					var bestd := 99
					for ct in [deg, deg + 2, deg + 4, deg + 7, deg - 3]:
						var dd := absi(ct - cur)
						if dd < bestd:
							bestd = dd
							best = ct
					cur = best
				else:
					cur += [-2, -1, -1, 1, 1, 2][int(_h(k, bar_from + bi, s + 3) * 6.0) % 6]
				cur = clampi(cur, 2, 13)
				var len := 1
				while k + len < steps and _h(bar_from + bi, k + len, s + 9) < 0.35:
					len += 1
				var last := cadence and bi == bar_count - 1 and k + len >= steps - 2
				if last:
					cur = deg + 7 if absi(deg + 7 - cur) < absi(deg - cur) else deg
					len = steps - k
				notes.append({"t": float(bar * beats) + k * 0.5, "d": len * 0.5 - 0.06, "m": deg_note.call(cur, 0), "w": lead_w, "v": lv,
					"sus": d.get("sus", 0.7), "duty": d.get("duty", 0.5), "vib": d.get("vib", 0.0)})
				k += len
	phrase.call(0, 4, 0, seed, false)
	phrase.call(0, 2, 4, seed, false)
	phrase.call(6, 2, 6, seed + 7, true)
	# --- drums ----------------------------------------------------------------
	for bar in bars:
		var t0 := float(bar * beats)
		match d.get("drums", ""):
			"basic":
				for k in beats:
					notes.append({"t": t0 + k, "drum": "kick" if k % 2 == 0 else "snare", "v": 0.35 if k % 2 == 0 else 0.22})
					notes.append({"t": t0 + k + 0.5, "drum": "hat", "v": 0.12})
			"march":
				for k in beats:
					notes.append({"t": t0 + k, "drum": "kick" if k % 2 == 0 else "snare", "v": 0.3})
				notes.append({"t": t0 + beats - 0.25, "drum": "snare", "v": 0.15})
			"swing":
				for k in beats:
					notes.append({"t": t0 + k, "drum": "hat", "v": 0.1})
					notes.append({"t": t0 + k + 0.66, "drum": "hat", "v": 0.07})
					if k % 2 == 1:
						notes.append({"t": t0 + k, "drum": "snare", "v": 0.1})
			"shaker":
				for k in beats * 2:
					notes.append({"t": t0 + k * 0.5, "drum": "shaker", "v": 0.12 if k % 2 == 0 else 0.07})
			"disco":
				for k in beats:
					notes.append({"t": t0 + k, "drum": "kick", "v": 0.35})
					notes.append({"t": t0 + k + 0.5, "drum": "hat", "v": 0.18})
					if k % 2 == 1:
						notes.append({"t": t0 + k, "drum": "snare", "v": 0.2})
	return notes
