"""Shared helpers for the Brothers in Shadow songs built from
midi_maker/recipes/jrpg_story_theme.md (and the battle recipe's songs).

A song script imports this, sets up a Song(bpm, beats, bars, prog), adds
Parts, writes events in absolute beats, and calls song.write(out, ...).
Never hand-edit .chipwave JSON: everything goes through `mt`.
"""
import subprocess
import sys
from pathlib import Path

MT_DIR = Path("/home/ric/2026_gamedev/CLAUDE/music_tracker")
MT = str(MT_DIR / "mt")
sys.path.insert(0, str(MT_DIR / "cli"))
import notation  # noqa: E402

NAMES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}

# chord name -> (root pitch class, intervals)
QUAL = {"": [0, 4, 7], "m": [0, 3, 7], "sus2": [0, 2, 7], "sus4": [0, 5, 7], "7": [0, 4, 7, 10],
        "m7": [0, 3, 7, 10], "maj7": [0, 4, 7, 11], "dim": [0, 3, 6], "aug": [0, 4, 8], "5": [0, 7],
        "7b9": [0, 4, 7, 10, 13], "add9": [0, 4, 7, 14], "madd9": [0, 3, 7, 14]}


def pitch(s):
    """'A4' / 'Bb3' / 'C#5' -> MIDI (C4 = 60)."""
    n = NAMES[s[0]]
    i = 1
    while s[i] in "#b":
        n += 1 if s[i] == "#" else -1
        i += 1
    return n + 12 * (int(s[i:]) + 1)


def chord(name):
    """'Dm' / 'Bb' / 'Asus4' / 'G7' -> (root pc, intervals)."""
    root = NAMES[name[0]]
    i = 1
    while i < len(name) and name[i] in "#b":
        root += 1 if name[i] == "#" else -1
        i += 1
    return root % 12, QUAL[name[i:]]


def tones(name):
    r, ivs = chord(name)
    return {(r + iv) % 12 for iv in ivs}


def root_in(name, low):
    """The chord's root at or just above MIDI `low`."""
    r = chord(name)[0]
    return low + (r - low) % 12


def tokens(bar):
    """'A4:1.5 G4:.5 r:2' -> (pitch or None, beats)."""
    for tok in bar.split():
        p, d = tok.split(":")
        yield (None if p == "r" else pitch(p)), float(d)


class Part:
    """Collects events in absolute beats; velocities 0-1.5."""

    def __init__(self, song, name, inst, kit=False):
        self.song, self.name, self.inst, self.kit = song, name, inst, kit
        self.bars = [[] for _ in range(song.bars)]
        song.parts.append(self)

    def _add(self, t, ev, v):
        b = int(t // self.song.beats + 1e-9)
        if b >= self.song.bars:
            return
        ev["t"] = round(t - b * self.song.beats, 6)
        if abs(v - 1) > 1e-9:
            ev["v"] = round(max(.05, min(v, 1.5)), 2)
        self.bars[b].append(ev)

    def note(self, p, t, d, v=1.0):
        self._add(t, {"d": round(d, 4), "n": int(p)}, v)

    def hit(self, drum, t, v=1.0):
        self._add(t, {"drum": drum}, v)

    def melody(self, bars, t0, v=1.0, transpose=0, hold=.92, shape=None):
        """Melody bars ('A4:1 G4:.5 ...') from beat t0. Long notes ring to their end."""
        t = t0
        for i, bar in enumerate(bars):
            for p, d in tokens(bar):
                if p is not None:
                    vv = v * (shape(i) if shape else 1.0)
                    self.note(p + transpose, t, d * hold if d < 2 else d - .1, vv)
                t += d
        return t

    def soften(self):
        """Move notes a semitone off their bar's chord tones down to the
        nearest chord tone (canons and harmonies never grind)."""
        for b, events in enumerate(self.bars):
            ts = tones(self.song.prog[b])
            for e in events:
                n = e.get("n")
                if n is None or n % 12 in ts:
                    continue
                if any((n - x) % 12 in (1, 11) for x in ts):
                    while n % 12 not in ts:
                        n -= 1
                    e["n"] = n


class Song:
    def __init__(self, bpm, beats, bars, prog):
        assert len(prog) == bars, f"{len(prog)} chords for {bars} bars"
        self.bpm, self.beats, self.bars, self.prog = bpm, beats, bars, prog
        self.parts = []

    def t(self, bar, beat=0.0):
        return bar * self.beats + beat

    def write(self, out, title, key, notes, voices, kit=None, kit_vol=.5, gain=1.4, drive=1.0, seed=11):
        mt("new", out, "--empty", "--force", "--bpm", str(self.bpm), "--bars", str(self.bars),
           "--beats", str(self.beats), "--title", title, "--key", key)
        mt("set", out, "chords=" + " ".join(self.prog), f"seed={seed}", f"master.gain={gain}",
           f"master.drive={drive}", "notes=" + notes)
        for inst, params in voices.items():
            mt("inst", "set", out, inst, *params.split())
        if kit:
            mt("inst", "set", out, "kit", "type=kit", f"vol={kit_vol}")
            for drum, params in kit.items():
                mt("drum", "set", out, "kit", drum, *params.split())
        for part in self.parts:
            mt("track", "add", out, part.name, part.inst)
            text = " | ".join(notation.format_bar(sorted(bar, key=lambda e: e["t"]), self.beats, kit=part.kit,
                                                  names=notation.SHARPS) for bar in part.bars)
            mt("bar", "put", out, part.name, f"1-{self.bars}", text)
        print(mt("check", out))


def mt(*args):
    r = subprocess.run([MT, *args], capture_output=True, text=True)
    if r.returncode:
        sys.exit(f"mt {' '.join(args[:4])} failed:\n{r.stdout}{r.stderr}")
    return r.stdout


SOFT_KIT = {
    "taiko":  "len=.35 tone=1 wave=tri pitch=[110,55] noise=.25 noise_lp=.15 env=quad gain=.6",
    "rim":    "len=.04 tone=.6 wave=sq pitch=[900,800] noise=.4 noise_lp=.7 env=linear gain=.25",
    "shaker": "len=.06 noise=1 noise_lp=.9 env=arch gain=.1",
    "crash":  "len=1.4 noise=1 noise_lp=.6 env=quad gain=.18",
    "wind":   "len=1.2 noise=1 noise_lp=.04 env=arch gain=.2",
}
