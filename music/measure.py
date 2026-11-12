#!/usr/bin/env python3
"""Check a song's levels (recipe §6/§7): python3 measure.py SONG.chipwave "A:0-8,B:8-16" (ranges in bars, any meter)
Prints the full mix stats, each track's --only RMS, and per-section RMS from a WAV render."""
import json, math, struct, subprocess, sys, tempfile, wave, re
MT = "/home/ric/2026_gamedev/CLAUDE/music_tracker/mt"
song = sys.argv[1]
secs = sys.argv[2] if len(sys.argv) > 2 else ""
info = json.load(open(song))
def run(*a):
    return subprocess.run([MT, *a], capture_output=True, text=True).stdout
print("mix:", run("render", song, "--stats").strip().splitlines()[-1])
for t in info.get("tracks", []):
    name = t.get("name")
    out = run("render", song, "--stats", "--only", name)
    m = re.search(r"rms ([-0-9.]+) dBFS", out)
    print(f"  {name:10s} {m.group(1) if m else '?'} dB RMS")
if secs:
    wav = tempfile.mktemp(suffix=".wav")
    run("render", song, "-o", wav)
    w = wave.open(wav); n = w.getnframes(); sr = w.getframerate(); ch = w.getnchannels()
    s = struct.unpack("<%dh" % (n * ch), w.readframes(n))
    bpm = info.get("bpm", 120); beats = info.get("beats_per_bar", info.get("beats", 4))
    bar = beats * 60 / bpm
    for part in secs.split(","):
        nm, rg = part.split(":"); a, b = map(float, rg.split("-"))
        seg = s[int(a * bar * sr) * ch:int(b * bar * sr) * ch]
        r = math.sqrt(sum(x * x for x in seg) / max(1, len(seg))) / 32768
        print(f"  section {nm:6s} {20 * math.log10(max(r, 1e-9)):6.1f} dB RMS")
