#!/usr/bin/env python3
"""ending: "The Long Road Home" (recipes/western_ambient.md). The title's
Sword Stories theme turned major: whistle over nylon and an echoing twang,
a soft trot from the second half, two trumpets in thirds in B, the choir and
the mission bell.
D major, 72 BPM, 4/4. Intro 4 | A 16 | B 8 (trumpets) | Tail 8. Ends on D
into the quiet intro. 36 bars = 120 s.
"""
import re
from western_kit import WSong, echo, strum, harmonize, voicing, gallop, main, pitch
from title import THEME

MAJ = [re.sub(r"\bBb", "B", re.sub(r"\b([CF])(\d)", r"\1#\2", bar)) for bar in THEME]
THEME_CH = ["D", "A", "Bm", "G", "G", "Em", "A", "D"]
THEME_BASS = ["D2", "C#2", "B1", "G1", "G1", "E2", "A1", "D2"]
B_CH = ["G", "D", "A", "Bm", "G", "D", "Em", "A"]
TP_B = ["B5:2 D6:1 B5:1", "A5:2 F#5:2", "E5:1 A5:1 C#6:2", "B5:3f r:1",
        "G5:1 B5:1 D6:2", "D6:2 A5:2", "G5:1 E5:1 B5:2", "A5:3 r:1"]
INTRO_CH = ["D", "D", "G", "A"]

PROG = INTRO_CH + THEME_CH * 2 + B_CH + THEME_CH
song = WSong(72, 4, 36, PROG)
whistle = song.part("whistle")
tp1 = song.part("trumpet")
tp2 = song.part("trumpet2", "trumpet")
twang = song.part("twang")
techo = song.part("twang_echo")
nylon = song.part("nylon")
choir = song.part("choir")
bell = song.part("bell")
bass = song.part("bass")
drums = song.part("drums", "kit", kit=True)

A0, B0, T0 = 4, 20, 28


def build(out):
    for k, ch in enumerate(INTRO_CH):
        t = song.t(k)
        r = pitch({"D": "D3", "G": "G2", "A": "A2"}[ch])
        twang.note(r, t, 2, .8)
        twang.note(r + 7, t + 1.5, 1.5, .6)
        twang.note(r + 12, t + 2.5, 1.2, .5)
        bass.note(r - 12, t, 3.8, .6)
    whistle.melody(MAJ, song.t(A0), .95)
    whistle.melody(MAJ[:4] + MAJ[12:15] + ["D5:4"], song.t(T0), .9)
    tp1.melody(TP_B, song.t(B0), .9, hold=.85)
    harmonize(tp1, tp2, .7)
    for b in range(A0, 36):
        ch = PROG[b]
        t = song.t(b)
        in_b = B0 <= b < T0
        bs = pitch(THEME_BASS[(b - A0) % 8]) if not in_b else voicing(ch, 31, 1)[0]
        bass.note(bs, t, 1.8, .85)
        bass.note(bs + 7 if in_b else bs + 12, t + 2, 1.8, .55)
        v = voicing(ch, 50, 4)
        strum(nylon, v, t, 1.8, .6)
        strum(nylon, v, t + 2.5, 1.2, .45, up=True)
        if b >= A0 + 8 and b < T0 + 4:
            gallop(drums, t, 4, .4, trot=True)
        if in_b:
            for p in voicing(ch, 57, 3):
                choir.note(p, t, 3.8, .6)
        elif b % 2 == 0:
            twang.note(voicing(ch, 50, 3)[2], t + 2.5, 1, .45)
    for s in (0, A0 + 8, B0, T0):
        bell.note(pitch("D3"), song.t(s), 4, .9)
        bell.note(pitch("A4"), song.t(s), 4, .25)
    for s in (0, 16, 28):
        drums.hit("wind", song.t(s), .6)
    echo(twang, techo, .75, .9, second=1.5)
    techo.soften()
    return song.write(out, "The Long Road Home", "D major",
                      "Ending (The Caravan Thief), recipes/western_ambient.md. The Sword Stories theme in D major on "
                      "the whistle, trumpets in thirds in B, choir, bell, soft trot. Ends on D into the intro.",
                      gain=1.6, kit_vol=.6)


if __name__ == "__main__":
    main(build, "ending")
