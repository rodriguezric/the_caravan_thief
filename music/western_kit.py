"""Western additions to story_kit.py, for midi_maker/recipes/western_ambient.md.

    from western_kit import WSong, WPart, VOICES, KIT, ...

- WPart.note() takes per-note overrides (slide=, vib=, sus=), written into the
  bars as {slide=-1.5} etc.
- WPart.melody() reads 'A4:2' tokens plus suffixes: 'f' = whistle fall
  (slide -1.5), 'F' = long fall (slide -3), 'u' = scoop up (slide .5),
  'r:1' rests.
- strum(), gallop(), echo() and voicing helpers.
- WSong.write() builds the .chipwave with mt; WSong.ship() renders an OGG
  next to it (res://music/<cue>.ogg) through a temp WAV.
"""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from story_kit import Song, Part, mt, notation, pitch, tones, root_in, chord  # noqa: E402,F401

HERE = Path(__file__).resolve().parent
OVERRIDES = ("slide", "vib", "sus", "decay")

VOICES = {
    "whistle":   "wave=sin vol=.10 attack=.05 decay=.1 sus=.9 release=.25 vib=.009 vib_rate=5.2",
    "harmonica": "wave=sq duty=.5 vol=.07 attack=.05 decay=.15 sus=.8 release=.12 vib=.012 vib_rate=6.5",
    "trumpet":   "wave=saw vol=.12 attack=.035 decay=.2 sus=.75 release=.12 vib=.006 vib_rate=6",
    "twang":     "wave=sq duty=.125 vol=.11 attack=.002 decay=.45 sus=.12 release=.35 vib=.004 vib_rate=6",
    "twang_echo": "wave=sq duty=.125 vol=.045 attack=.002 decay=.45 sus=.12 release=.35 vib=.004 vib_rate=6",
    "nylon":     "wave=sq duty=.25 vol=.07 attack=.002 decay=.3 sus=.05 release=.2",
    "choir":     "wave=tri vol=.065 attack=.6 decay=.4 sus=.9 release=.9 vib=.004 vib_rate=4.5",
    "drone":     "wave=saw vol=.05 attack=.8 decay=.5 sus=1 release=1 vib=.002 vib_rate=.4",
    "bell":      "wave=sin vol=.12 attack=.001 decay=1.8 sus=0 release=1.4",
    "bass":      "wave=tri vol=.15 attack=.005 decay=.25 sus=.6 release=.1",
    "cricket":   "wave=sin vol=.15 attack=.001 decay=.04 sus=0 release=.03",
}

KIT = {
    "clop":   "len=.05 tone=.9 wave=tri pitch=[780,620] noise=.25 noise_lp=.5 env=quad gain=.35",
    "clop2":  "len=.06 tone=.9 wave=tri pitch=[560,440] noise=.25 noise_lp=.4 env=quad gain=.35",
    "boom":   "len=.5 tone=1 wave=sin pitch=[90,45] noise=.1 noise_lp=.1 env=quad gain=.6",
    "brush":  "len=.14 noise=1 noise_lp=.45 env=arch gain=.35",
    "rim":    "len=.04 tone=.6 wave=sq pitch=[900,800] noise=.4 noise_lp=.7 env=linear gain=.25",
    "whip":   "len=.12 tone=.3 wave=sq pitch=[2600,900] noise=1 noise_lp=.95 env=quad gain=.4",
    "anvil":  "len=.6 tone=1 wave=sq pitch=[1500,1480] noise=.15 noise_lp=.9 env=quad gain=.22",
    "rattle": "len=.35 noise=1 noise_lp=.85 env=arch gain=.08",
    "tick":   "len=.015 tone=1 wave=sq pitch=[3000,3000] env=linear gain=.12",
    "wind":   "len=1.6 noise=1 noise_lp=.035 env=arch gain=.4",
    "kick":   "preset=kick gain=.5",
    "snare":  "len=.12 noise=1 noise_lp=.7 env=quad gain=.32",
    "hat":    "len=.03 noise=1 env=linear gain=.1",
    "crash":  "len=1.2 noise=1 noise_lp=.7 env=quad gain=.2",
}

SUFFIX = {"f": -1.5, "F": -3.0, "u": .5}


def mtokens(bar):
    """'A4:1 G4:2f r:1' -> (pitch or None, beats, overrides)."""
    for tok in bar.split():
        p, d = tok.split(":")
        ov = {}
        while d and d[-1] in SUFFIX:
            ov["slide"] = SUFFIX[d[-1]]
            d = d[:-1]
        yield (None if p == "r" else pitch(p)), float(d), ov


class WPart(Part):
    def note(self, p, t, d, v=1.0, **ov):
        t = t % (self.song.bars * self.song.beats)   # echoes wrap round the loop
        ev = {"d": round(d, 4), "n": int(p)}
        ev.update(ov)
        self._add(t, ev, v)

    def melody(self, bars, t0, v=1.0, transpose=0, hold=.92, shape=None, **ov):
        t = t0
        for i, bar in enumerate(bars):
            for p, d, nov in mtokens(bar):
                if p is not None:
                    vv = v * (shape(i) if shape else 1.0)
                    o = dict(ov)
                    o.update(nov)
                    self.note(p + transpose, t, d * hold if d < 2 else d - .12, vv, **o)
                t += d
        return t

    def events(self):
        """(absolute t, event) for every event."""
        for b, evs in enumerate(self.bars):
            for e in evs:
                yield b * self.song.beats + e["t"], e


def echo(src, dst, delay=.75, v=1.0, transpose=0, second=0.0):
    """Copy src into dst `delay` beats later (and optionally again at `second` @.5)."""
    for t, e in list(src.events()):
        if "n" not in e:
            continue
        ov = {k: e[k] for k in OVERRIDES if k in e}
        vv = e.get("v", 1.0) * v
        dst.note(e["n"] + transpose, t + delay, e["d"], vv, **ov)
        if second:
            dst.note(e["n"] + transpose, t + second, e["d"], vv * .5, **ov)


def voicing(name, low, n=3):
    """The chord's tones from MIDI `low` upward, n notes (no doubles)."""
    ts = tones(name)
    out, p = [], low
    while len(out) < n:
        if p % 12 in ts:
            out.append(p)
        p += 1
    return out


def fifth(name, low):
    """Root + fifth (open, no third) from `low`."""
    r = root_in(name, low)
    return [r, r + 7]


def strum(part, notes, t, d, v=1.0, up=False, gap=.03):
    seq = sorted(notes, reverse=up)
    for i, p in enumerate(seq):
        part.note(p, t + i * gap, max(.1, d - i * gap), v * (.7 if up else 1.0))


def gallop(drums, t, beats, v=1.0, trot=False):
    """Hooves: 8th + two 16ths per beat (or 8th + 8th for a trot)."""
    for k in range(int(beats)):
        b = t + k
        if trot:
            drums.hit("clop", b, .8 * v)
            drums.hit("clop2", b + .5, .55 * v)
        else:
            drums.hit("clop", b, .9 * v)
            drums.hit("clop2", b + .5, .55 * v)
            drums.hit("clop2", b + .75, .6 * v)


class WSong(Song):
    def part(self, name, inst=None, kit=False):
        return WPart(self, name, inst or name, kit)

    def write(self, out, title, key, notes, voices=None, kit=None, kit_vol=.45, gain=1.6, drive=1.0,
              seed=11, voice_over=None):
        out = str(out)
        voices = dict(voices or {})
        used = {p.inst for p in self.parts if not p.kit}
        for inst in used:
            if inst not in voices:
                voices[inst] = VOICES[inst]
        for k, v in (voice_over or {}).items():
            voices[k] = v
        mt("new", out, "--empty", "--force", "--bpm", str(self.bpm), "--bars", str(self.bars),
           "--beats", str(self.beats), "--title", title, "--key", key)
        mt("set", out, "chords=" + " ".join(self.prog), f"seed={seed}", f"master.gain={gain}",
           f"master.drive={drive}", "notes=" + notes)
        for inst in sorted(used):
            mt("inst", "set", out, inst, *voices[inst].split())
        if any(p.kit for p in self.parts):
            kit = dict(KIT, **(kit or {}))
            used_drums = {e["drum"] for p in self.parts if p.kit for evs in p.bars for e in evs}
            mt("inst", "set", out, "kit", "type=kit", f"vol={kit_vol}")
            for drum in sorted(used_drums):
                mt("drum", "set", out, "kit", drum, *kit[drum].split())
        for part in self.parts:
            mt("track", "add", out, part.name, part.inst)
            text = " | ".join(notation.format_bar(sorted(bar, key=lambda e: e["t"]), self.beats, kit=part.kit,
                                                  names=notation.SHARPS, overrides=OVERRIDES)
                              for bar in part.bars)
            mt("bar", "put", out, part.name, f"1-{self.bars}", text)
        print(mt("check", out))
        return out


def ship(chipwave, quality=4):
    """Render <cue>.chipwave to <cue>.ogg beside it (WAV only in a temp dir)."""
    chipwave = Path(chipwave)
    fd, wav = tempfile.mkstemp(suffix=".wav")
    os.close(fd)
    try:
        mt("render", str(chipwave), "-o", wav)
        ogg = chipwave.with_suffix(".ogg")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis",
                        "-q:a", str(quality), str(ogg)], check=True)
        print(f"shipped {ogg.name}: {ogg.stat().st_size // 1024} KB")
    finally:
        os.unlink(wav)


def main(build, out_name):
    """Shared __main__: python3 <cue>.py [--no-ship]."""
    out = HERE / f"{out_name}.chipwave"
    build(out)
    if "--no-ship" not in sys.argv:
        ship(out)


def under(p, name, gap=3):
    """Highest tone of chord `name` at least `gap` semitones below p (a harmony line)."""
    ts = tones(name)
    q = p - gap
    while q % 12 not in ts:
        q -= 1
    return q


def harmonize(src, dst, v=.8, gap=3):
    """dst = src's notes moved to the chord tone a third-ish below (per bar's chord)."""
    for t, e in list(src.events()):
        if "n" not in e:
            continue
        b = int(t // src.song.beats)
        ov = {k: e[k] for k in OVERRIDES if k in e}
        dst.note(under(e["n"], src.song.prog[b], gap), t, e["d"], e.get("v", 1.0) * v, **ov)


def walk(bass, name, nxt, t, beats=4, low=40, v=.85):
    """Walking bass: root, fifth/third, fifth, then a chromatic step into the next root."""
    r = root_in(name, low)
    n = root_in(nxt, low)
    third = r + (3 if 3 in [(x - r) % 12 for x in tones(name)] else 4)
    line = [r, third, r + 7, n + (1 if n < r + 7 else -1)] if beats == 4 else [r, r + 7, third]
    for i, p in enumerate(line[:beats]):
        bass.note(p, t + i, .9, v if i == 0 else v * .8)
